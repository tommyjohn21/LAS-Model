%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%=== Explore effects of stimulation on plasticity ===%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Preliminaries: Load stimulation parameters that will be used in this experiment

% Initialize StimulationExperiment
SE = StimulationExperiment('screen-20');
% Identify variable directory, update variable directory
VarDir = 'StimulationExperiment';
SE.UpdateDir(VarDir);
Load(SE) % Load results

%% Preliminaries: Determine which stimulation parameters to use

% Set seed to default
rng('default')

% Pull out stimualation parameters
f = arrayfun(@(s)s.param.input.Stimulation.frequency,SE.S);
m = arrayfun(@(s)s.param.input.Stimulation.magnitude,SE.S);
pw = arrayfun(@(s)s.param.input.Stimulation.pulsewidth,SE.S);
pn = arrayfun(@(s)s.param.input.Stimulation.pulsenum,SE.S);
dur = arrayfun(@(s)s.param.input.Stimulation.duration,SE.S);

% Compute probabilities
p = arrayfun(@(s)sum([s.detector.Seizure])./numel([s.detector.Seizure]),SE.S);

% Find zero-probability parameters 
i = find(p==0);

% Shuffle and take first 10
j = i(randperm(numel(i)));
j = j(1:10);

% For posterity
assert(all(j == [268   224   424   811   754   588   678   100   853   130]),'Something is amiss stimulation selection!');

%% Implement stimulation in experiment

% Initialize StimulationExperiment
E = StimulationExperiment('stimulation-plasticity');

% Identify variable directory, update variable directory
VarDir = 'StimulationExperiment';
E.UpdateDir(VarDir)

% Adjust parameters
E.param.n = 20;

% Input to screen
inputs = cellfun(@(i)SE.S(j(i)).param.input.Stimulation,num2cell(1:numel(j))); % Use j=1 for initial set up

% Set inputs for experiment
E.param.inputs = inputs;

% Prepare Simulation apparatus
S = Simulation('DefaultSimulationParameters'); % Generate container for Simulation
Plasticize(S); % Update Simulation param settings for PlasticityExperiment
Prepare(S); % Prepare Simulation

% Link StimulationExperiment to Simulation
E.S = S;

%% Run simulation
Run(E); 















