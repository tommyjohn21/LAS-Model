classdef ThresholdExperiment < Experiment
    % Designed to detect threshold in context of particular network in
    % context of specific simulation
    
    properties
        % Inherits properties from Experiment class:
        %   S:        Simulation object used in experiment
        %   param:    Experiment parameters
        
        stim
        
    end
    
    methods
        function E = ThresholdExperiment(ExperimentName,varargin)
            
            % Construct Experiment object with given name/type
            E = E@Experiment(ExperimentName);
            E.param.class = class(E);
            
            % Parse input for optional experiment template
            p = inputParser;
            addParameter(p,'ExperimentTemplate','DefaultThresholdExperimentParameters');
            parse(p,varargin{:});
            E.param.ExperimentTemplate = p.Results.ExperimentTemplate;
            
            % Load experiment parameters from template
            eval(E.param.ExperimentTemplate);
            
            % Parse simulation params
            VarList = who;
            exclude = {'ExperimentName','p','varargin'};
            for i = 1:numel(VarList)
                if isa(eval(VarList{i}),'ThresholdExperiment') || ismember(VarList{i},exclude)
                    continue; % Do not save instance itself in its own param field
                else
                    E.param.(VarList{i}) = eval(VarList{i});
                end
            end
            
        end
        
        function Load(E) % Load results of ThresholdExperiment
            
            % Load contents of expdir associated with E
            f = dir(fullfile(E.param.expdir,'ThresholdExperiment-Level-*.mat'));
            
            % Clear param field in E
            E.param = [];
            E.S = [];
            
            for i = 1:numel(f)
               % Load Experiment file
               TE = load(fullfile(f(i).folder,f(i).name),'E');
               % Concatenate params and Simulations
               E.param = [E.param TE.E.param];
               E.S = [E.S TE.E.S]; 
            end
                        
        end
        
        function varargout = Plot(E,varargin)
            
            % Restructure varargin for possible figure handle
            FigureHandles = cellfun(@(x)isa(x,'matlab.ui.Figure'),varargin);
            assert(sum(FigureHandles)<=1,'More than one figure handle was given for plotting')
            if sum(FigureHandles) == 0
                h = figure('visible','off'); 
                varargin = [{h} varargin];
                FigureHandles = cellfun(@(x)isa(x,'matlab.ui.Figure'),varargin);
            else
                warning('Figure handle provided. Note that existing axes will be overwritten by convention.')
            end
            varargin = [varargin(FigureHandles) varargin(~FigureHandles)];
            
            % Parse inputs
            p = inputParser;
            ValidateS = @(E) isa(E,'ThresholdExperiment');
            ValidateFig = @(h) isa(h,'matlab.ui.Figure');
            addRequired(p,'E',ValidateS);
            addRequired(p,'h',ValidateFig);
            parse(p,E,varargin{:});
            h = p.Results.h;
            
            % Parse input time for plotting
            InputType = unique(cellfun(@(x)x.type,{E.param.inputs},'un',0));
            InputType = InputType{1};
            
            switch InputType
                case 'Deterministic'
                    inputs = arrayfun(@(x)x.param.input.Deterministic.duration,E.S);
                    xstring = 'Stimulus duration (s)';
                case 'Random'
                    % Assert all threshold testing uses deterministic stimuli
                    % assert(all(arrayfun(@(x)strcmp(x{1}.type,'Deterministic'),{E.param.inputs})),...
                    %    ['Plot function has been rewritten for Deterministic inputs. '...
                    %    'The next lines of code should still pull out inputs appropriately, but step '...
                    %    'through it once to make sure.'])
                    inputs = arrayfun(@(x)x.param.input.Random.sigma,E.S);
                    xstring = 'Noise level (\sigma_S, pA)';
            end
            
            % Parse data for plotting
            UniqueInputs = unique(inputs);
            
            % Pull trials, compute success (s) and total number of trials
            % (n)
            s = []; n = [];
            for i = 1:numel(UniqueInputs)
                trials = arrayfun(@(x)x.Seizure,E.S(inputs == UniqueInputs(i)).detector);
                s = [s sum(trials)];
                n = [n numel(trials)];
            end
            pr = s./n; % Percent of seizures
                        
            % Plot in figure
            delete(findobj(h,'type','axes')) % Delete any existing axes
            ax = axes(h);
            plot(UniqueInputs,pr,'o','MarkerEdgeColor','k'); 
            hold on

            % Fit sigmoid
            sig = @(x) (1 + exp(-(UniqueInputs-x(1))./x(2))).^(-1);
            ofn = @(x) sum((sig(x)-pr).^2);
            fit = fminsearch(ofn,[1.5,1]);
            plot(UniqueInputs,sig(fit),'LineWidth',2);
            
            % Plot titles/labels
            title('Probability of seizure')
            ylabel('Probability')
            xlabel(xstring)
    
            % Basic Formatting
            ax.YLim = [0 1]; % Plot probability between 0 and 1
            ax.FontSize = 18;
            
            % Make visible if not yet
            if strcmp(h.Visible,'off'), h.Visible = 'on'; end
            
            % Return figure handle as desired
            if nargout == 1, varargout{1} = p.Results.h; end
            
        end
        
        function threshold = Threshold(E)
            
            % This code is not debugged for deterministic inputs
            assert(all(arrayfun(@(x)strcmp(x{1}.type,'Random'),{E.param.inputs})),...
                ['The below threshold calculations are NOT debugged yet for Deterministic inputs'])
            
            % Pull raw data for sigmoid fitting
            x = arrayfun(@(s)s.param.input.Random.sigma,E.S); % Stimulation inputs used
            p = arrayfun(@(s)sum([s.detector.Seizure]),E.S)./... % Total seizures...
                arrayfun(@(s)numel([s.detector.Seizure]),E.S); % divided by Total trials
            
            % Sort in ascending order of input
            [x,i] = sort(x);
            p = p(i);
            
            % Fit sigmoid
            sig = @(param) (1 + exp(-(x-param(1))./param(2))).^(-1);
            ofn = @(param) sum((sig(param)-p).^2);
            fit = fminsearch(ofn,[1.5,1]);
            
            % Extract threshold
            threshold = fit(1);
            
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
        
    methods (Static = true)
        
        function E = loadobj(e)
            
            % Initiate ThresholdExperiment, add params
            E = ThresholdExperiment(e.param.name);
            E.param = e.param;
            
            % Attach simulation
            E.S = e.S;
            
        end
      
    end
    
    methods
        Run(E)
    end
    
    methods (Access = protected)
        function TE = copyElement(E)
            
            % Create new ThresholdExperiment with associated parameters
            TE = ThresholdExperiment(E.param.name);
            TE.param = E.param;
            
            % Create new Simulation with associated parameters
            Q = Simulation(E.S.param.SimulationTemplate);
            Q.param = E.S.param;
            Prepare(Q) % Prepare Q
            
            % Link new Simulation to new ThresholdExperiment
            TE.S = Q;
            
        end
    end
    
end

