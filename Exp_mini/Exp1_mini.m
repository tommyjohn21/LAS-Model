
%%% Allow access to local function handles %%%
function fh = Exp1_mini

fh.simulate_mini_by_stim_dur = @simulate_mini_by_stim_dur;
fh.run_Exp1_mini = @run_Exp1_mini;

end


function run_Exp1_mini
    %%% Exp1_mini computes threshold of mini model by brute force %%%

    %%% Settings %%%
    stim_durations = fliplr(0:0.01:3); % start with stronger stims for fast detection
    n_sims = 100;
    location = [0.475 0.525];

    %%% Conditional parallel computation %%%
    if strcmp(computer,'GLNXA64') % if server
        parfor i = 1:numel(stim_durations)

            % Save dir
            savedir = '~/detector_mini/';

            % Function as below
            d = simulate_mini_by_stim_dur(n_sims,stim_durations(i),location);
            parsave([savedir 'stim_dur_' num2str(stim_durations(i)) '.mat'],d)

        end
    else % local
        for i = 1:numel(stim_durations)

            % Save dir
            savedir = '~Desktop/detector_mini/';

            % Function as below
            d = simulate_mini_by_stim_dur(n_sims,stim_durations(i),location);
            parsave([savedir 'stim_dur_' num2str(stim_durations(i)) '.mat'],d)

        end
    end

end

%% Simulate detection, save output

function output = simulate_mini_by_stim_dur(n,stim_dur,location)
% Repeat Exp5_mini n times for a given stim_dur to create threshold curve

for i = 1:n
    
    disp(['Stim dur ' num2str(stim_dur) 's, sim ' num2str(i) ' of ' num2str(n)])
    
    %% Set random number generator
    % rng default
    
    %% Lay out the model and build recurrent connection
    % Lay out the field
    O = SpikingModel('Exp5Template_mini');
    % Build recurrent connection
    [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection_mini( O );
    
    
    %% External input
    Ic = 200;
    stim_x = location;
    stim_t = [2 2+stim_dur]; % Unit: second
    O.Ext = ExternalInput;
    O.Ext.Target = O;
    O.Ext.Deterministic = @(x,t) ((stim_x(2)*O.n(1))>x(:,1) & x(:,1)>(stim_x(1)*O.n(1))) .* ...
        ((stim_t(2)*1000)> t & t > (stim_t(1)*1000)) .* ...
        Ic; % x: position, t: ms, current unit: pA
    
    %% Simulation settings
    dt = 1; % ms
    R = CreateRecorder(O,25000); % The 2nd argument is Recorder.Capacity
    T_end = R.Capacity - 1; % simulation end time.
    
    %% STDP settings
    % O.Proj.In(1).STDP.Enabled = 1;
    % KernelToMultiplication(O.Proj.In(1));
    % O.Proj.In(1).STDP.tau_LTD = O.Proj.In(1).STDP.tau_LTD./O.param.time_compression;
    % O.Proj.In(1).STDP.tau_LTP = O.Proj.In(1).STDP.tau_LTP./O.param.time_compression;
    
    %% Simulation
    while 1
        
        % Termination criteria
        if O.t >= T_end
            % Run final seizure detection at end of run if no seizure
            % detected prior
            [seizure,dP,fdP] = detector(O,dt);
            disp(['No seizure by t = ' num2str(O.t/1000) 's, end'])
            break
        end
        
        WriteToRecorder(O);
        Update(O,dt);
        
        % Detect seizures
        if mod(O.t,5000)==0 && O.t>(stim_t(end)*1000) % no need to look until end of stim
            [seizure,dP,fdP] = detector(O,dt);
            if seizure, break, end
            disp(['No seizure by t = ' num2str(O.t/1000) 's, continue'])
        end
        
    end
    
    
    %% Format output
    %     output(i).V = O.Recorder.Var.V(:,1:O.t);
    output(i).dP = dP;
    output(i).fdP = fdP;
    output(i).seizure = seizure;
    %     output.O = O;
    
    %% Clear workspace
    clearvars('-except','output','n','stim_dur','location')
    
end

end
