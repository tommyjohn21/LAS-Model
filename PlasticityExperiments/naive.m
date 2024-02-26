%% Create plasticity matrices (i.e. dW matrices) from N=500 seizures in naive (mini) model
%% PlasticityExperiment preliminaries
% Directories for saving

% Updated variable directory for PlasticityExperiments
VarDir = 'PlasticityExperiment';
% Directory for specific experiment
ExpName = 'naive';
% Generate container for PlasticityExperiment

% Create/update PlasticityExperiment
E = PlasticityExperiment(ExpName);
E.UpdateDir(VarDir);
% Update PlasticityExperiment settings

% Adjust number of simulations as desired
E.param.n = 500;
%% Simulation preliminaries
% Generate container for Simulation

S = Simulation('DefaultSimulationParameters');
% Update Simulation param settings for PlasticityExperiment

Plasticize(S);
% Prepare Simulation

Prepare(S);
% Link PlasticityExperiment to Simulation

E.S = S;
%% Run ThresholdExperiment

Run(E)