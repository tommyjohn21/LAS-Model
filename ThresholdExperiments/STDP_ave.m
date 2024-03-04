%% Determine threshold of the averaged, updated (mini) model (i.e. after one round of STDP on average)

%% Load data from PlasticityExperiment
% PlasticityExperiment directory
PlasticityVarDir = 'PlasticityExperiment';

% Directory for specific experiment
PlasticityExpName = 'naive';

% Create/update PlasticityExperiment
PE = PlasticityExperiment(PlasticityExpName);
PE.UpdateDir(PlasticityVarDir);

% Load PlasticityExperiment
Load(PE)

% Parsing runs PCA on data to produce appropriate PCA-space coordinates
Parse(PE)

%% Perform ThresholdExperiment
%%% ThresholdExperiment preliminaries
% Directories for saving
VarDir = 'ThresholdExperiment'; % Updated variable directory for ThresholdExperiments

% Directory for specific experiment
ExpName = 'STDP_ave';

% Generate container for ThresholdExperiment
E = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
E.UpdateDir(VarDir);

% Update ThresholdExperiment settings
E.param.inputs.levels = 5:2.5:30; % Adjust tested input levels as desired

%%% Simulation preliminaries
% Generate container for Simulation
S = Simulation('DefaultSimulationParameters');

%%% Retrieve average weight updating matrix from PlasticityExperiment
% Note that this is the average across *unrotated* AND *rotated* matrices.
% Symmetry considerations HAVE been included.
S.param.dW = PE.dWave; 

% Prepare Simulation
Prepare(S);

% Link ThresholdExperiment to Simulation
E.S = S;

%%% Run ThresholdExperiment
Run(E)
