%% Determine threshold of naive (mini) model when stimulated
% Expose the naive (mini) model to deterministic stimulation to see what
% stimulation duration is required to cause a seizure

%% ThresholdExperiment preliminaries
% Directories for saving

% Updated variable directory for ThresholdExperiments
VarDir = 'ThresholdExperiment';
% Directory for specific experiment
ExpName = 'naive_to_stimulation';
% Generate container for ThresholdExperiment

% Create/update ThresholdExperiment
E = ThresholdExperiment(ExpName);
E.UpdateDir(VarDir);
% Update ThresholdExperiment settings

% Adjust tested input levels as desired
E.param.inputs.type = 'Deterministic';
E.param.inputs.levels = 0:0.1:1;

%% Simulation preliminaries
% Generate container for Simulation

S = Simulation('DefaultSimulationParameters');
% Prepare Simulation

Prepare(S);
% Link ThresholdExperiment to Simulation

E.S = S;
%% Run ThresholdExperiment

Run(E)