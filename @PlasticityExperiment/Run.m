function Run(E)
% Run the experiment stored in the Experiment object
%
% Workflow:
% 1. Generate Experiment object:
%       a. E = PlasticityExperiment(ExperimentName)
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

% Override to activate realtimeSTDP, deactivate kill.IfSeizure
if ~E.S.param.flags.realtimeSTDP || ...
        E.S.param.flags.kill.IfSeizure || ...
        ~E.S.param.flags.kill.IfWaveCollapsed
    warning('Simulation flags (realtimeSTDP, kill.IfSeizure, kill.IfWaveCollapsed) are incompatible with PlasticityExperiment. Overriding...')
    E.S.param.flags.realtimeSTDP = true; % Set realtimeSTDP flag
    E.S.param.flags.kill.IfSeizure = false;
    E.S.param.flags.kill.IfWaveCollapsed = true;
    Prepare(E.S); % Regenerate network with updated flag settings
end

% Assert that inputs are Deterministic (i.e. not Random)
%   In this case, PlasticityExperiment is done with different durations of
%   deterministic input as stimulation (vs. varying levels of random noise)
assert(strcmp(E.param.inputs.type,'Deterministic'),['You have only written '...
    'PlasticityExperiment to use deterministic input.'])

% Create ExpDir if doesn't exist
if ~exist(E.param.expdir,'dir'), mkdir(E.param.expdir); end

%%% Conditional parallel computation %%%
% Grand data concatenation for passage in parfor
n = E.param.n;
PE = cellfun(@(x)copy(E),num2cell(1:n),'un',0);
if E.param.server || E.param.flags.parallel
    parfor (i = 1:n), ExecuteSimulations(PE{i},i); end
else
    for i = 1:n, ExecuteSimulations(PE{i},i); end
end
end

function ExecuteSimulations(PE,i)

        % Pull local Simulation handle
        S = PE.S;
        
        % Identify local level/type for PlasticityExperiment for readability
        param = PE.param;
        type = param.inputs.type;
        % If you want multiple levels of input, you need a secondary loop
        % to cycle through levels (in addition to number of stimulations)
        assert(numel(param.inputs.levels)==1,...
            'As written, PlasticityExperiment can only accomodate one duration (level) of stimulation (e.g. default: t=3s)')
        level = param.inputs.levels;
        
        % Update input
        UpdateInput(S,type,level);
        
        % Skip Simulation if already performed
        FileName = sprintf([param.expdir 'PlasticityExperiment-%d.mat'],i);
        if exist(FileName,'file'), return, end
        
        % Run simulation
        fprintf('Simulation %i of %i\n',i,param.n)
        Run(S)
                
        % Save output
        parsave(FileName,PE)
        
        % Reset simulation
        Reset(S)

end

function parsave(FileName,E)
    disp(['Saving ' FileName])
    save(FileName, 'E', '-v7.3')
end
