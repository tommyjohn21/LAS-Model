function Run(E)
% Run the experiment stored in the Experiment object
%
% Workflow:
% 1. Generate Experiment object:
%       a. E = StimulationExperiment(ExperimentName)
%       b. manipulate E.param as needed
% 2. Initialize Simulation and Simulation parameters to use in Experiment
%    and Prepare Simulation to generate Network object with network
%    parameters:
%       a. S = Simulation(SimulationTemplate);  % Load simulation parameters
%       b. manipulate S.param as needed
%       c. Prepare(S);                          % Generate network prior to simulation
%       d. manipulate S.O (Network) as needed
% 3. Asign Simulation to Experiment and Run Experiment:
%       a. E.S = S;
%       b. Run(E);

% Reset simulation if needed
if E.S.O.t>0, Reset(E.S); end

% Create ExpDir if doesn't exist
if ~exist(E.param.expdir,'dir'), mkdir(E.param.expdir); end

%%% Conditional parallel computation %%%
% Grand data concatenation for passage in parfor
inputs = ExpandInputs(E);
SE = cellfun(@(x)copy(E),num2cell(1:numel(inputs)),'un',0);
if E.param.server || E.param.flags.parallel
    parfor (i = 1:numel(inputs)), ExecuteSimulations(SE{i},inputs(i)); end
else
    for i = 1:numel(inputs), ExecuteSimulations(SE{i},inputs(i)); end
end
end

function ExecuteSimulations(SE,input)

        % Pull local Simulation handle
        S = SE.S;
        
        % Substitute local input parameters
        SE.S.O.Ext.Deterministic = @(x,t) EvaluateStimulation(SE,input,x,t);
                
        % Initialize output structures
        detector = []; % Empty detector for concatenation
        seed = []; % Empty seed container for concatenation
        
        % Skip Simulation if already performed
        FileName = sprintf([SE.param.expdir 'StimulationExperiment-Input-'...
            strjoin(compose('%X',floor(100*[input.frequency input.magnitude input.pulsewidth input.pulsenum])),'.')...
            '.mat']); % Filename in composed in hexadecimal for unique file identifier
        if exist(FileName,'file'), return, end
        
        % Run simulations
        for j = 1:SE.param.n
            fprintf('%i pulses, %i pA, %i ms, %i Hz: simulation %i of %i\n',input.pulsenum,input.magnitude,input.pulsewidth,input.frequency,j,SE.param.n)
            Run(S)
            detector = [detector S.detector]; % Append detector from each simulation
            seed = [seed S.seed]; % Retain seeds used in each simulation
            Reset(S)
        end
        
        % Append completed results
        SE.S.detector = detector;
        SE.S.seed = seed;
        
        % Save Stimulation settings
        SE.S.param.input.Stimulation = input;

        % Save output
        parsave(FileName,SE)

end

function parsave(FileName,E)
    disp(['Saving ' FileName])
    save(FileName, 'E', '-v7.3')
end
