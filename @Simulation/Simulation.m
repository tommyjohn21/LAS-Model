classdef Simulation < handle & matlab.mixin.Copyable
    
    properties
        
        % Intrinsic simulation parameters
        param
        
        % Network to simulate
        O   % generate simulation network with Prepare(S)
        
        % Record DetectSeizure output
        detector = struct(...
            'Seizure',0,...         % Boolean for seizure detected
            'WaveCollapsed',0,...   % Boolean to determine if tonic wave collapsed (deprecated)
            'State',[],...          % State trace
            'V',[]...               % Voltage trace
            );

        % Record rng settings for Simulation
        % Note: if prefer to use preset seed, do the following:
        %   S.param.flags.UsePresetSeed = true;
        %   S.seed = PresetSeed; (e.g. your desired seed)
        %   Prepare(S)
        seed = rng;

    end
    
    %% Constuct the object
    methods
        function S = Simulation(SimulationTemplate)
            
            % Load simulation settings
            eval(SimulationTemplate);
            
            % Parse simulation params
            VarList = who;
            for i = 1:numel(VarList)
                if isa(eval(VarList{i}),'Simulation')
                    continue; % Do not save instance itself in its own param field
                else
                    S.param.(VarList{i}) = eval(VarList{i});
                end
            end
        end
    end
    
    %% Included functions
    methods
        Prepare(S) % Prepare network and input
        Run(S) % Run simulation
        DetectSeizure(S) % Detect seizure in current simulation
    end
    
    %% Miscellaneous methods
    methods
        
        % Reset simulation to beginning;
        function Reset(S)
            % Pull handle for network/recorder
            O = S.O; R = S.O.Recorder;
            
            % Restore initial conditions
            O.V = R.Var.V(:,1);
            O.phi = R.Var.phi(:,1);
            O.Cl_in = R.Var.Cl_in(:,1);
            O.g_K = R.Var.g_K(:,1);
            
            % Restore initial inputs
            O.Input.E = 0;
            O.Input.I = 0;
            O.Ext.Random.Iz = 0;
            
            % Reset spiking-related variables
            O.S.S = false(O.n); % Logical value, decide whether there is a spike or not
            O.S.dT = zeros(O.n); % The previous spike            
            O.S.x = ones(O.n); % short-term plasticity variables
            O.S.u = O.param.U; % short-term plasticity variables

            % Reset time counter
            S.O.t = 0;
            
            % Reset plasticity matrix
            for i = 1:numel(O.Proj.In)
                if O.Proj.In(i).STDP.Enabled
                    O.Proj.In(i).STDP.W = ones(size(O.Proj.In(i).STDP.W));
                end
            end
            
            % Adjust random seed if desired
            if isfield(S.param.flags,'UsePresetSeed'), AdjustSeed(S), end

        end
        
        function AdjustSeed(S)
            
            % Set/Save RandomSeed
            if S.param.flags.UsePresetSeed
                try
                    % Try to use seed present in S.seed
                    rng(S.seed)
                catch % If no seed present, create new
                    warning('Unable to UsePresetSeed. Creating new RandomSeed instead.')
                    S.seed = rng;
                end
            elseif ~S.param.flags.UsePresetSeed
                % Save new seed if do not wish to use PresetSeed
                S.seed = rng;
            end
            
        end
        
        function Plasticize(S)
            % Ready Simulation for PlasticityExperiment
            S.param.flags.realtimeSTDP = true;
            S.param.flags.kill.IfSeizure = false;
            S.param.flags.kill.IfWaveCollapsed = true;
        end
        
        function UpdateInput(S,InputType,level)
            
            % Assert that there is a Network to update
            assert(isa(S.O,'SpikingNetwork'),'Simulation must have associated Network for method UpdateInput')
                        
            % Determine parameter for level (default: sigma)
            if strcmp(InputType,'Random')
                LevelString = 'sigma'; 
            elseif strcmp(InputType,'Deterministic')
                LevelString = 'duration';
            end
            
            % Update Simulation AND Network
            S.param.input.(InputType).(LevelString) = level; % Update Simulation input
            Prepare(S); % Update deterministic input by regenerating network
            
        end
        
        function varargout = Plot(S,varargin)
            
            % Check that Network is present in Simulation
            assert(isa(S.O,'SpikingNetwork'),'Network is not found for Simulation. Associated results cannot be plotted.')
            
            % Restructure varargin for possible figure handle
            FigureHandles = cellfun(@(x)isa(x,'matlab.ui.Figure'),varargin);
            assert(sum(FigureHandles)<=1,'More than one figure handle was given for plotting')
            if sum(FigureHandles) == 0
                h = figure('visible','off'); 
                varargin = [{h} varargin];
                FigureHandles = cellfun(@(x)isa(x,'matlab.ui.Figure'),varargin);
            end
            varargin = [varargin(FigureHandles) varargin(~FigureHandles)];
            
            % Parse inputs
            p = inputParser;
            ValidateS = @(S) isa(S,'Simulation');
            ValidateFig = @(h) isa(h,'matlab.ui.Figure');
            addRequired(p,'S',ValidateS);
            addRequired(p,'h',ValidateFig);
            addParameter(p,'Var','V');
            parse(p,S,varargin{:});
            h = p.Results.h;
            
            % Load data for plotting
            if strcmp(p.Results.Var,'V')
                data = S.V;
                TitleString = 'Voltage';
                UnitString = [TitleString ' (mV)'];
            else
                data = S.O.Recorder.Var.(p.Results.Var)(:,1:S.O.t/S.param.dt);
                switch p.Results.Var
                    case 'phi', TitleString = 'Threshold'; UnitString = [TitleString ' (mV)'];
                    case 'Cl_in', TitleString = '[Cl]_{in}'; UnitString = [TitleString ' (mM)'];
                    case 'g_K', TitleString = 'g_K'; UnitString = [TitleString ' (nS)'];
                end
            end
            
            % Plot in figure
            delete(findobj(h,'type','axes')) % Delete any existing axes
            ax = axes(h);
            imagesc([1:S.O.t]./1000,1:prod(S.O.n),data)
            
            % Plot titles/labels
            title([TitleString ' Trace '...
                '(\Deltat_{stim} = ' num2str(S.param.input.Deterministic.duration) 's, '...
                '\sigma_S = ' num2str(S.param.input.Random.sigma) 'pA)'])
            ylabel('Neuron index')
            xlabel('Time (s)')
    
            % Basic Formatting
            ax.FontSize = 18;
            c = colorbar;
            c.Label.String = UnitString;
            
            % Make visible if not yet
            if strcmp(h.Visible,'off'), h.Visible = 'on'; end
            
            % Return figure handle as desired
            if nargout == 1, varargout{1} = p.Results.h; end
            
        end
        
        
    end
    
    methods (Hidden = true)
        
        % Return voltage trace
        function VoltageTrace = V(S), VoltageTrace = S.O.Recorder.Var.V(:,1:S.O.t/S.param.dt); end
        
        % Return updated weight matrix
        function dW = dW(S), dW = S.O.Proj.In(1).STDP.W; end
        
        % Save function (transition to struct)
        function s = saveobj(S)
            
            % Initialize output structure
            s = struct();

            % Transition to structure for saving
            fn = fieldnames(S);
            for i = 1:numel(fn)
                if strcmp(fn{i},'O')
                    
                    % Save network parameters
                    s.(fn{i}) = struct('param',S.O.param);
                    
                    % Pull all STDP weighting matrices
                    s.(fn{i}).Enabled = arrayfun(@(x)x.STDP.Enabled==1,S.O.Proj.In);
                    s.(fn{i}).W = arrayfun(@(x)x.STDP.W,S.O.Proj.In,'un',0);
                    
                    % Retain only those Projections with STDP Enabled
                    s.(fn{i}).W(~(s.(fn{i}).Enabled)) = [];
                    s.(fn{i}).Enabled = find(s.(fn{i}).Enabled);
                   
                else
                    s.(fn{i}) = S.(fn{i});
                end
            end
            
        end
        
    end
       
    methods (Static)
        % Load function (transition from struct)
        function S = loadobj(s)
            
            % Reconstruct Simulations
            %   Note that this does not reconstruct Voltage or State traces
            S = Simulation(s.param.SimulationTemplate);
            S.param = s.param;
            Prepare(S) % Generate network as dictated in e.S.param
            
            % Compare prepared SpikingModel to loaded parameters
            fn1 = fieldnames(s.O.param);
            fn2 = fieldnames(S.O.param);
            assert(isempty(setdiff(fn1,fn2)) && isempty(setdiff(fn2,fn1)),...
                ['Prepared SpikingModel and loaded SpikingModel parameters have '...
                'non-shared fields!'])
            % First, check equality among numeric parameters
            for i = 1:numel(fn1)
               if ~(isa(S.O.param.(fn1{i}),'function_handle') && isa(s.O.param.(fn1{i}),'function_handle'))
                   assert(isequal(S.O.param.(fn1{i}),s.O.param.(fn1{i})),['Loaded and Prepared SpikingModels '...
                       'differ in parameter ' fn1{i} '!'])
               end
            end
            % Regenerate anonymous functions
            for i = 1:numel(fn1)
                if isa(S.O.param.(fn1{i}),'function_handle') && isa(s.O.param.(fn1{i}),'function_handle')
                    assert(isequal(func2str(S.O.param.(fn1{i})),func2str(s.O.param.(fn1{i}))),['Function strings differ '...
                        'between Prepared and loaded SpikingModel!'])
                    
                    % True equality in anonymous functions cannot be
                    % gauranteed, although we can regenerate here in
                    % accordance with values in loaded SpikingModel
                    str = (['S.O.param.' fn1{i} ' = ' func2str(s.O.param.(fn1{i})) ';']);
                    vars = fn1(cellfun(@(x)contains(func2str(s.O.param.(fn1{i})),x),fn1));
                    VarStr = cellfun(@(x) [x ' = s.O.param.' x '; '],vars,'un',0);
                    VarStr = [VarStr{:}];
                    eval([VarStr str])
                    
                end
            end
            
            % Reattach detector
            S.detector = s.detector;
            
            % Try to reattach seed(s) if one exists
            try S.seed = s.seed;
            catch
                % If unable to load seed, create empty seed structure
                % This is mostly for legacy/backwards-compatibility
                S.seed = arrayfun(@(n)...
                    struct('Type','none',...
                    'Seed',NaN,...
                    'State',NaN),...
                    1:numel(S.detector));
            end
            
            % Reattach STDP if Enabled
            if isfield(s.O,'Enabled') && ~isempty(s.O.Enabled)
               S.O.Proj.In(s.O.Enabled).STDP.Enabled = 1;
               if numel(s.O.Enabled)>1, error('The following line is not debugged for STDP enabled for more than 1 Projection'); end
               S.O.Proj.In(s.O.Enabled).STDP.W = s.O.W{:};
            end
            
        end
        
        
    end
    
end