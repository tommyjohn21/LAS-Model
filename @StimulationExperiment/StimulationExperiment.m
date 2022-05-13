classdef StimulationExperiment < Experiment
    % StimulationExperiment is a subclass of Experiment designed to perform
    % subthreshold stimulation on a SpikingModel 
    
    properties
        % Inherits properties from Experiment class:
        %   S:        Simulation object used in experiment
        %   param:    Experiment parameters
        
    end
    
    methods
        
        % Constructor method
        function E = StimulationExperiment(ExperimentName,varargin)
            
            % Construct Experiment object with given name/type
            E = E@Experiment(ExperimentName);
            E.param.class = class(E);
            
            % Parse input for optional experiment template
            p = inputParser;
            addParameter(p,'ExperimentTemplate','DefaultStimulationExperimentParameters');
            parse(p,varargin{:});
            E.param.ExperimentTemplate = p.Results.ExperimentTemplate;
            
            % Load experiment parameters from template
            eval(E.param.ExperimentTemplate);
            
            % Parse simulation params
            VarList = who;
            exclude = {'ExperimentName','p','varargin'};
            for i = 1:numel(VarList)
                if isa(eval(VarList{i}),'StimulationExperiment') || ismember(VarList{i},exclude)
                    continue; % Do not save instance itself in its own param field
                else
                    E.param.(VarList{i}) = eval(VarList{i});
                end
            end
            
        end
        
        % Include Run method
        Run(E)
        
        % Load results of StimulationExperiment
        function Load(E) 
            
            % Load contents of expdir associated with E
            f = dir(fullfile(E.param.expdir,'StimulationExperiment-Input-*.mat'));
            
            % Clear param field in E
            E.param = [];
            E.S = [];
            
            for i = 1:numel(f)
                % Load Experiment file
                SE = load(fullfile(f(i).folder,f(i).name),'E');
                % Concatenate params and Simulations
                E.param = [E.param SE.E.param];
                E.S = [E.S SE.E.S];
            end
            
        end
        
    end
    
    methods (Hidden = true)
        
        % Returns value of Stimulation with given StimParams for position x and time t
        function current = EvaluateStimulation(E,StimParam,x,t)
            
            % Check time parameters; return nothing if outside of
            % stimulation window/stimulation location
            if t < StimParam.delay.*1000, current = 0.*x(:,1); return,
            elseif t > (StimParam.delay.*1000 + StimParam.duration.*1000), current = 0.*x(:,1); return,
            end 
            
            % Ensure that location of stimulation is [0.4750 0.5250]
            assert(all(StimParam.location == [0.4750 0.5250]),...
                'Non-default stimulus location is used! Function ExpandInputs(E) is not debugged for this scenario--please debug.')
            
            % Determine active stimulation neurons
            loc = ((StimParam.location(2)*E.S.O.n(1))>x(:,1) & x(:,1)>(StimParam.location(1)*E.S.O.n(1)));
            
            % Determine point in burst cycle
            tb = rem(t-(StimParam.delay*1000),(1./StimParam.frequency).*1000); % Time in burst
            if tb < StimParam.pulsewidth % Within the active pulse window
                current = loc .* StimParam.magnitude;
            else
                current = 0.*x(:,1);
            end
            
        end
        
        function StimParams = ExpandInputs(E)
            % Take E.param (which may have multiple frequencies, durations,
            % etc. and convert to structure array for each combination of
            % frequency, duration, etc.
            
            % Pull parameters from E
            inputs = E.param.inputs;
            
            % Ensure that location of stimulation is [0.4750 0.5250]
            assert(all(inputs.location == [0.4750 0.5250]),...
                'Non-default stimulus location is used! Function ExpandInputs(E) is not debugged for this scenario--please debug.')
            
            % Generate indices for all combinations of stimulation parameters
            [ifreq,idur,imag,ipw,idel] = ndgrid(...
                1:numel(inputs.frequency),...
                1:numel(inputs.duration),...
                1:numel(inputs.magnitude),...
                1:numel(inputs.pulsewidth),...
                1:numel(inputs.delay));
            
            % Linearize index vectors
            [ifreq,idur,imag,ipw,idel] = deal(ifreq(:),idur(:),imag(:),ipw(:),idel(:));
            idx = [ifreq,idur,imag,ipw,idel]; % Concatenate all combinations
            idx = mat2cell(idx,ones(1,size(idx,1)),size(idx,2)); % Turn matrix to cell
            
            % GenerateStimParam for index array
            StimParams = cellfun(@(i)GenerateStimParam(inputs,i),idx);
            
            % CheckStimValidity to discard non-valid stimulation parameters
            [IsValid,PulseNum,PulseWidth] = arrayfun(@(s)CheckStimValidity(s),StimParams);
            
            % Discard non-valid simulation parameters/pulse numbers
            [StimParams,PulseNum,PulseWidth] = deal(StimParams(IsValid),PulseNum(IsValid),PulseWidth(IsValid));
            
            % Fold in PulseNumbers to StimParams
            for i = 1:numel(PulseWidth), StimParams(i).pulsenum = PulseNum(i); end
            
            % Create matrix of individual pulse durations/numbers and pull
            % out unique values
            PulseTrains = [arrayfun(@(s)s.frequency,StimParams)...
                    arrayfun(@(s)s.magnitude,StimParams)...
                    arrayfun(@(s)s.pulsewidth,StimParams)...
                    arrayfun(@(s)s.pulsenum,StimParams)];
            UniquePulseTrains = unique(PulseTrains,'rows');
            UniquePulseIndices = cellfun(@(t)find(all(ismember(PulseTrains,t,'rows'),2),1,'first'),mat2cell(UniquePulseTrains,ones(1,size(UniquePulseTrains,1)),4));
            
            % Return only stimulations that produce UniquePulseTrains
            StimParams = StimParams(UniquePulseIndices);
            
            % Subfunction to generate structure array from index cell
            function StimParam = GenerateStimParam(skeleton,ParamArray)
                             
                % Update skeleton
                skeleton.frequency  =   skeleton.frequency(ParamArray(1));
                skeleton.duration   =   skeleton.duration(ParamArray(2));
                skeleton.magnitude  =   skeleton.magnitude(ParamArray(3));
                skeleton.pulsewidth =   skeleton.pulsewidth(ParamArray(4));
                skeleton.delay      =   skeleton.delay(ParamArray(5));
                
                % Use skeleton structure for output
                StimParam = skeleton;
                
            end
            
            % Subfunction to check stimulus validity
            function [valid,pulsenum,pulsewidth] = CheckStimValidity(ParamArray)
                
                % Extract parameters
                [frequency,duration,magnitude,pulsewidth] = deal(ParamArray.frequency,ParamArray.duration,ParamArray.magnitude,ParamArray.pulsewidth);
                
                % For stimulation to be valid (and meaningful), the
                % following must be true
                valid = ...
                    (duration > 0) && ... % Check basic nontriviality of stimulation parameters
                    (magnitude > 0) && ...
                    (frequency > 0) && ...
                    (pulsewidth > 0) && ...
                    (pulsewidth <= (1./frequency*1000)) && ... % pulsewidth cannot be longer than period of stimulation
                    (pulsewidth <= duration*1000) && ... % pulsewidth cannot be longer than duration of stimulation (note: this ensures at least 1 pulse)
                    (floor(duration.*frequency) >= 1) && ... % Ensure at least one pulse
                    (((duration.*frequency - floor(duration.*frequency))*1000 >= pulsewidth) || ((duration.*frequency - floor(duration.*frequency))*1000 == 0)); % Ensure an integer number of pulses fit into the duration (avoid partial pulses; note this guarantees a second full pulse for all stimulations)
                
                % Return number of pulses in ParamArray
                pulsenum = floor(duration.*frequency)+((duration.*frequency - floor(duration.*frequency))*1000 >= pulsewidth);
                      
            end
            
        end
            
        function e = saveobj(E)
            
            % Initialize output structure
            e = struct();
            
            % Transition to structure for saving
            fn = fieldnames(E);
            for i = 1:numel(fn)
                e.(fn{i}) = E.(fn{i});
            end
            
        end
        
    end
    
    methods (Access = protected)
        function SE = copyElement(E)
            
            % Create new StimulationExperiment with associated parameters
            SE = StimulationExperiment(E.param.name);
            SE.param = E.param;
            
            % Create new Simulation with associated parameters
            Q = Simulation(E.S.param.SimulationTemplate);
            Q.param = E.S.param;
            Prepare(Q) % Prepare Q
            
            % Link new Simulation to new ThresholdExperiment
            SE.S = Q;
            
        end
    end
    
    methods (Static = true)
        function E = loadobj(e)
            
            % Initiate ThresholdExperiment, add params
            E = StimulationExperiment(e.param.name);
            E.param = e.param;
            
            % Attach simulation
            E.S = e.S; 
            
            % Reconstructe Stimulation function handle
            E.S.O.Ext.Deterministic = @(x,t) EvaluateStimulation(E,E.S.param.input.Stimulation,x,t);
        
        end
    end
    
end

