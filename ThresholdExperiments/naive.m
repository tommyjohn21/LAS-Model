%% Determine threshold of naive (mini) model
%% ThresholdExperiment preliminaries
% Directories for saving

% Updated variable directory for ThresholdExperiments
VarDir = 'ThresholdExperiment';
% Directory for specific experiment
ExpName = 'naive';
% Generate container for ThresholdExperiment

% Create/update ThresholdExperiment
E = ThresholdExperiment(ExpName);
E.UpdateDir(VarDir);
% Update ThresholdExperiment settings

% Adjust tested input levels as desired
E.param.inputs.levels = 20 : 2.5 : 35;
%% Simulation preliminaries
% Generate container for Simulation

S = Simulation('DefaultSimulationParameters');
% Prepare Simulation

Prepare(S);
% Link ThresholdExperiment to Simulation

E.S = S;
%% Run ThresholdExperiment

Run(E)