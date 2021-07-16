classdef SpikingModel < SpikingNetwork
    % Class definition for a spiking model 
    % 
    % Model = SpikingModel(template)
    %
    % Input: template - a filepath that leads to a .m script file which
    %                   specifies parameters of the model
    %
    % Default setting for properties inherited from NeuralNetwork
    % Input: 'I' & 'E'
    % S: 'S', 'dT', 'x', 'u'
    % 
    % Author: Jyun-you Liou
    % Final update: 2016/12/22
    
    properties
        % The model inherit from NeuralNetwork with the following
        % properties: n,t,Input,Proj,Ext,Recorder,UserData
        
        % The model's intrinsic parameters
        param     
        
        % The 4 dynamical variables - if you want to change the name or #
        % of dynamical variables, please remember to update the Constant 
        % property 'VarName' 
        V % averaged membrane potential
        phi % spiking threshold
        Cl_in % intracellular chloride concentration 
        g_K % slow AHP conductance  
    end
    
    properties (Constant)
        VarName = {'V','phi','Cl_in','g_K'}
    end
    
    methods % Simulation functions
        function IndividualModelUpdate(O,dt) 
            % IndividualModelUpdate(Model,dt)
            %
            % Perform the first section of dt-step simulation. This 
            % internal function is called by Update(Model,dt).
            %
            % Jyun-you Liou 2016/12/30
     
            % Collect input from 'ExternalInput'
            I_ext = 0;
            for i = numel(O.Ext):-1:1 
                % You need to evaluate from the back because ExternalInput
                % may be destroyed after expiration time. (.Tmax)
                I_ext = Evaluate(O.Ext(i),O.t,dt) + I_ext;
            end
            
            % Collect input from 'Projection'
            for i = 1:numel(O.Proj.In) % So the maximum of O.Input is W0 * f_max
                % tw: why is Value divided by tau_syn? this is apparently
                % related to synaptic filtering...
                
                % tw: when you are in SpikingModel, and you enter here, you
                % Input is in units of nS (i.e. total excitatory and
                % inhibitory conductances)
                O.Input.(O.Proj.In(i).Type) = O.Input.(O.Proj.In(i).Type) + ...
                                              O.Proj.In(i).Value ./ O.param.tau_syn.(O.Proj.In(i).Type);
            end
            
            % ----- Update equation 1 (membrane potential) -----
            % tw: total conductance at this exact moment during update; see
            % Larry's book, Appendix 5.11
            % tw: not clear why some are divided by f_max and some are not?
            g_sum = O.param.g_L + ...
                    O.Input.E ./ O.param.f_max + ...
                    O.Input.I ./ O.param.f_max + ...
                    O.g_K ./ O.param.f_max; % from outside

            % V_inf - this equation still needs 'I'
            E_Cl = 26.7*log(O.Cl_in./O.param.Cl_ex); % Calculate E_Cl (inhibition effectiveness) 
            V_inf = (O.param.g_L .* O.param.E_L  + ...
                     O.Input.E ./ O.param.f_max .* O.param.E_Esyn + ...
                     O.Input.I ./ O.param.f_max .* E_Cl + ...  
                     O.g_K ./ O.param.f_max .* O.param.E_K + ...
                     I_ext) ./ g_sum;  
            
            % tw: this is the effective time constant for a *tiny* slice of
            % time; i.e. if nothing changes and conductances were held the
            % same, the membrane would try to relax to V_inf; this value
            % describes the time to relaxaton
            tau_V_eff = O.param.C./g_sum;
            
            % tw: this is in the infinity notation that I can't understand;
            % that said, the equation clearly says that, from V_inf plus
            % perturbation, you quickly (per tau_V_eff) back to V_inf; this
            % is only a first order equation over *very* short time scales;
            % see Abbott Theoretical neuroscience book equation 5.48
            % (assuming time scale short enough that conductances and
            % injective current are constant)
            O.V = V_inf + (O.V - V_inf).*(exp(-dt./tau_V_eff));   
            
            % ----- Update equation 2 (threshold dynamics) -----
            % tw: threshold decays exponentially, but suddenly shoots up by
            % delta_phi_0 when action potential detected on last update
            O.phi = O.param.phi_0 + (O.phi - O.param.phi_0).*(exp(-dt./O.param.tau_phi)) + ... % Exponential decay part
                    O.param.delta_phi(O.phi-O.param.phi_0) .* O.S.S; % Dirac pulse part

            % ----- Update equation 3 (chloride dynamics) ------ 
            % tw: for neurons that spiked last round, O.S.dT is 0 and T_AP
            % is 0.5 (i.e. O.param.dt_AP); T_AP for all other neurons is <0
            T_AP = O.param.dt_AP - O.S.dT; % How much time spent for action potential
            % tw: T_AP>0 retrieves indices of neurons that spiked on last
            % round; after next line, T_AP has 0 for all neurons that did
            % not spike on last round and 0.5 for all that did--the time
            % required for the AP
            T_AP = T_AP .* (T_AP>0);
            % tw: T_non_AP computes time in dt not taken up by AP
            T_non_AP = dt - T_AP; % How much time not spent for action potential
            % tw: Veff is the average membrane potential across the dt
            % interval, were membrane potential is clamped at O.param.V_AP
            % for duration for AP and then returns to prior value
            Veff = T_AP.*O.param.V_AP./dt + ...
                   T_non_AP.*O.V./dt; % effective membrane potential 
            Faraday = 96500;
            % tw: two things: 1. appears to be a sign issue -- it's
            % beecause E_Cl-Veff was replaced with Veff-E_Cl and 2.
            % O.Input.I appears to be used wholesale as conductance, which
            % doesn't necessarily make sense? It's true from a unit
            % analysis point of view: Input.I is in nS
            Cl_in_inf = (O.param.tau_Cl./O.param.Vd_Cl./Faraday.*(O.Input.I./O.param.f_max).*(Veff-E_Cl) + O.param.Cl_in_eq);
            % tw: Cl again decays in linear fasion
            O.Cl_in = Cl_in_inf + (O.Cl_in - Cl_in_inf).*(exp(-dt./O.param.tau_Cl));   
           
            % ----- Update equation 4 (sAHP dynamics) ----------
            % tw: this clearly mimics the mean field model, although even
            % in the mean field model, I'm not sure that I understand how
            % this is working...
            
            % tw: units--O.param.g_K_max (nS), O.S.S (no. spikes),
            % O.param.tau_K (ms); 
            
            % tw: be aware that the unit here is not nS! 
            % g_K variable actually tracks g_K (in nS) * f_max
            
            O.g_K = O.g_K .* exp(-dt ./ O.param.tau_K) + O.param.g_K_max.*O.S.S./O.param.tau_K;    
                           
            % ######### Generate spikes #########
            % Notice in numeric simulation, dirac function should take a value so that delta * dt = 1
            % tw: first line uses the O.param.f function to determine spike
            % probability; if O.param.f > 1 kHz, will always generate spike
            % in 1ms as rand is uniform distribution on interval [0,1]; at
            % the end of the day p(Spike) is f (kHz) * t (ms)
            Spike = O.param.f(O.V - O.phi)*dt > rand(O.n); % Spike generation
            % tw: look at time since last spike, if less than refractory
            % period, need to wait prior to spike generation, even if
            % otherwise would have generated a spike
            Spike(O.S.dT < O.param.T_refractory) = 0; % Remove the spike if still refractory
            % tw: membraine potential drops/resets after spiking event
            % during this round; in particular, drops by 20 mV
            O.V(Spike) = O.param.V_reset(O.V(Spike)); % Reset membrane potential
            % tw: save who spikes this round
            O.S.S = Spike; % Save it
            
            % tw: catch only when spikes are here
            if sum(O.S.S)>0
                keyboard
            end
            
            % ######### Calculate all S-derived variables ######### 
            % The reason why update of S-derived variables needs to happen 
            % in the same cycle is because Dirac function cause step from 
            % the right limit, not the left limit. 
            % Refractory period: .dT - when the neurons spike last time
            % tw: every neuron has another second since prior spike
            O.S.dT = O.S.dT + dt;
            % tw: second, if you just spiked, time since last spike
            % (O.S.dT) is reset to zero
            O.S.dT(O.S.S) = 0;
  
            % Short-term plasticity variables: .x & .u can affect effective
            % output strength
            %
            % Save the effective firing rate into its projections 
            if O.param.flag_STP && all(O.param.tau_D(:)) && all(O.param.U(:))
                % Within the parenthesis now becomes the RATIO compare the strength to a fresh spike
                % tw: essentially plasticity changes the "weight" of a
                % spike; so instead of Boolean, it becomes fractional...
                [O.Proj.Out.Value] = deal(((O.S.x.*O.S.u)./O.param.U) .* O.S.S); % divided by dt to preserve .Proj.Value 's unit as rate
                if all(O.param.tau_F(:)) % Short-term facilitation
                    O.S.x = 1 - (1-O.S.x).*exp(-dt./O.param.tau_D) - O.S.u.* O.S.x .* O.S.S; % x:percentage of synaptic vesicle reserve
                    O.S.u = O.param.U - (O.param.U-O.S.u).*exp(-dt./O.param.tau_F) + O.param.U.*(1-O.S.u).*O.S.S; % u:percentage of synaptic vesicles to be used 
                else
                    O.S.x = 1 - (1-O.S.x).*exp(-dt./O.param.tau_D) - O.param.U.*O.S.x.*O.S.S;
                end
            else
                % tw: output value here is boolean: spike or not
                [O.Proj.Out.Value] = deal(O.S.S); % Send to .Proj.Value 'rate'
            end
            
            % Filter the synaptic input (required for spiking network)
            % tw: appears to just be exponential decay of current input
            % back to 0 (prior to next round when more input is added)
            O.Input.E = O.Input.E.*exp(-dt./O.param.tau_syn.E);
            O.Input.I = O.Input.I.*exp(-dt./O.param.tau_syn.I);
            
            % Update time
            O.t = O.t + dt;
        end
    end
   
    %% Construct the object
    methods (Static)
        function O = SpikingModel(template)
            % Model = SpikingModel(template)
            %
            % Final update: 2016/12/12
            % Load parameters & initial conditions    
            
            % tw: load and adjust all parameters for network
            eval(template);
            
            % tw: the next line is where the instance is actually created;
            % the instance inherits all properties from SpikingNetwork and
            % NeuralNetwork
            VarList = who;
            
            % tw: this code takes all of the variables generated by
            % "template" above and divvies them into subfields of O
            for i = 1:numel(VarList)
                if any(strcmp(VarList{i},O.VarName)) % Initial conditions of dynamical variables
                    % tw: assigns dynamical variable to their own fields
                    O.(VarList{i}) = eval(VarList{i});
                elseif strcmp(VarList{i},'n') % Size of the network
                    % tw: carries forward n
                    O.n = eval(VarList{i});                    
                else % Parameters
                    % tw: assigns non-dynamical variables (aka model
                    % parameters) to O.param
                    O.param.(VarList{i}) = eval(VarList{i}); 
                end              
            end
            
            %% Set firing-associated dynamical variables 
            % tw: S is the container for spike associated data; S is
            % inherited from class SpikingNetwork
            O.S.S = false(O.n); % Logical value, decide whether there is a spike or not
            O.S.dT = zeros(O.n); % The previous spike            
            % tw: x is related to output from Misha's/Larry's models
            O.S.x = ones(O.n); % short-term plasticity variables
            % tw: U is related to calcium concentration/influx
            O.S.u = O.param.U; % short-term plasticity variables
            
            %% Set acceptable input types 
            % tw: Input field is defined in and inherited from class
            % NeuralNetwork; appears to reflect input to each neuron
            % (excitatory, inhibitory, etc.) with each model update cycle
            O.Input.E = zeros(O.n);
            O.Input.I = zeros(O.n);
        end
    end
    
    
end

