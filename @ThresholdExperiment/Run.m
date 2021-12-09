function Run(E)
% Run the experiment stored in the Experiment object
%
% Workflow:
% 1. Generate Experiment object:
%       a. E = ThresholdExperiment(ExperimentName)
%       b. manipulate E.param as needed
% 2. Initialize Simulation and Simulation parameters to use in Experiment
%    and Prepare Simulation to generate Network object with newtork
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

% Assert that inputs are Random (i.e. not Deterministic)
%   In this case, ThresholdExperiment is done with different levels of
%   noise as stimulation (vs. varying duration of deterministic
%   stimulation)
assert(strcmp(E.param.inputs.type,'Random'),['You have only written for '...
    'detection of threshold in response to noise.'])

% Create ExpDir if doesn't exist
if ~exist(E.param.expdir,'dir'), mkdir(E.param.expdir); end

%%% Conditional parallel computation %%%
% Grand data concatenation for passage in parfor
levels = E.param.inputs.levels;
TE = cellfun(@(x)copy(E),num2cell(1:numel(levels)),'un',0);
if E.param.server || E.param.flags.parallel
    parfor (i = 1:numel(levels)), ExecuteSimulations(TE{i},i); end
else
    for i = 1:numel(levels), ExecuteSimulations(TE{i},i); end
end
end

function ExecuteSimulations(TE,i)

        % Pull local Simulation handle
        S = TE.S;
        
        % Identify local level/type for ThresholdExperiment for readability
        param = TE.param;
        type = param.inputs.type;
        level = param.inputs.levels(i);
        
        % Update input
        UpdateInput(S,type,level);
        
        % Initialize output structure
        detector = []; % Empty detector for concatenation
        
        % Skip Simulation if already performed
        FileName = sprintf([param.expdir 'ThresholdExperiment-Level-%0.1f.mat'],level);
        if exist(FileName,'file'), return, end
        
        % Run simulations
        for j = 1:param.n
            fprintf('Level %0.1f, simulation %i of %i\n',level,j,param.n)
            Run(S)
            detector = [detector S.detector]; % Append detector from each simulation
            Reset(S)
        end
        
        % Append completed results
        TE.S.detector = detector;

        % Save output
        parsave(FileName,TE)

end

function parsave(FileName,E)
    disp(['Saving ' FileName])
    save(FileName, 'E', '-v7.3')
end
