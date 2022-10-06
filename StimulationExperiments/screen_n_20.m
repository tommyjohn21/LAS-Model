%% Determine stimulation threshold of (mini) model
%% Create StimulationExperiment Object

% Initialize StimulationExperiment
E = StimulationExperiment('screen-20');

% Identify variable directory, update variable directory
VarDir = 'StimulationExperiment';
E.UpdateDir(VarDir)

% Adjust parameters
E.param.n = 20; % Perform quick screen of stim param space with fewer trial numbers

% Set to parameter scan
E.param.flags.SpecifyInputs = false;

% Inputs to screen
E.param.inputs.frequency = 10.^(0:1/3:3); % Examine frequency logarithmically
E.param.inputs.duration = 0.5:2.5/4:3; % 3 s is used for default model
E.param.inputs.magnitude = 50:50:200; % 200 pA is used for default model
E.param.inputs.pulsewidth = 10.^(0:1/3:3); % Maximum screening pulsewidth is set by frequency: max pulsewidth = (1./freqeuncy)*1000
%% Create Simulation Object

% Generate container for Simulation and Prepare
S = Simulation('DefaultSimulationParameters');
Prepare(S);

% Link to Experiment object
E.S = S;
%% Run StimulationExperiment

% Run StimulationExperiment
Run(E)