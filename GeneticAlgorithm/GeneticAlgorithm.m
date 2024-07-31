%% Define algorithm parameter space
%%% We will create genetic recombinations across this space by indexing
%%% each of these matrices with integers
stimMagnitudes = [100:75:2000];
stimPositionStart = [0:0.025:0.475];
sensePositionStart = [0:0.025:0.95]; 

%% Generate dWave
% Updated variable directory for PlasticityExperiments
PlasticityVarDir = 'PlasticityExperiment';

% Directory for specific experiment
PlasticityExpName = 'naive';

% Create/update PlasticityExperiment
PE = PlasticityExperiment(PlasticityExpName);
PE.UpdateDir(PlasticityVarDir);

% Load PlasticityExperimentf
Load(PE)

% Parsing runs PCA on data to produce appropriate PCA-space coordinates
Parse(PE)

% Pull dWave
dWave = PE.dWave;

%% Define parameters for GeneticAlgorithm

% Cost function
%%% X = [index, locationStart, locationEnd]
fun = @(X) ObjectiveFunction(X(1),X(2),X(3),dWave,stimMagnitudes,stimPositionStart,sensePositionStart);

% Number of variables
nvars = 3;

% Constraints
%%% Inequality constraints
%%% None--see lower and upper bounds given below
A = [];
b = [];

%%% Equality constraints None--constraints around location of Stimulation
%%% and EventDetection are folded into the ObjectiveFunction
Aeq = [];
beq = [];

%%% Lower bounds
%%% Each index must be at least 1 (the first element)
lb = [1; 1; 1];

%%% Upper bounds
%%% Each index cannot be larger than the list of elements
ub = [numel(stimMagnitudes); numel(stimPositionStart); numel(sensePositionStart)];

%%% Non-linear constraints
%%% None
nonlcon = [];

%%% Integer constraints
%%% Restrict all variables to integers (for vector indexing)
intcon = 1:nvars;

%% Run the GeneticAlgorithm
optimizedParameters = ga(fun,nvars,A,b,Aeq,beq,lb,ub,nonlcon,intcon);
