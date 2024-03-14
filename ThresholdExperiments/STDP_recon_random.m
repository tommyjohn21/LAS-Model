%%% Now that you have validated the PlasticityExperiment/Reconstruct
%%% technique in STDP_recon_validation, you are ready to Reconstruct
%%% arbitray combinations of PCA components and Simulate their thresholds.
%%% The approach is to generate random combinations of [c1;c2] matrices by
%%% drawing from PCA space. You'll then Reconstruct the associated dW
%%% matrices and compute thresholds.

%% Load data from PlasticityExperiment
% Updated variable directory for PlasticityExperiments
PlasticityVarDir = 'PlasticityExperiment';

% Directory for specific experiment
PlasticityExpName = 'naive';

% Generate container for PlasticityExperiment
PE = PlasticityExperiment(PlasticityExpName);

% Update PlasticityExperiment
PE.UpdateDir(PlasticityVarDir);

% Load PlasticityExperiment
Load(PE)

% Parsing runs PCA on data to produce appropriate PCA-space coordinates
Parse(PE)

% Retrieve PCA coordinates
coords = PE.Coord;

%% Generate grid-like sampling near origin in first-quadrant
% The strategy here is to comput your best fit plane and find a criterion
% to select for reconstructed matrices that live near the origin in the
% first quadrant. You essentially want to check that your plane model works
% in that region

%%% Load the threshold data and generate best-fit plane
% Preliminaries
ThresholdVarDir = 'ThresholdExperiment/STDP';

% List of all ThresholdExperiments for PlastcitiyExperiment STDP data
ExpNames = dir([ThresholdExperiment('').param.vardir,ThresholdVarDir]);
ExpNames = ExpNames(arrayfun(@(f)contains(f.name,'PlasticityExperiment-naive'),ExpNames));

% Sort in numerical order (c.f. character/alphabetical order)
[ExpNums,idx] = sort(arrayfun(@(s)str2num(s.name(28:end)),ExpNames));
ExpNames = ExpNames(idx);

% Create array of ThresholdExperiments
TE = arrayfun(@(f)ThresholdExperiment(f.name),ExpNames);
arrayfun(@(te)te.UpdateDir(ThresholdVarDir),TE);

% Load and trim array (keep experiments with >0 Simulations)
arrayfun(@(te)Load(te),TE);
idx = arrayfun(@(te)~isempty(te.S),TE);
TE = TE(idx);
ExpNums = ExpNums(idx);

% Extract thresholds
thresholds = arrayfun(@(te)Threshold(te),TE);

%%% Best fit threshold plane
% Pair down coordinates to only those with defined threshold values
[cX,cY] = deal(coords(ExpNums,1),coords(ExpNums,2));

% Define a linear plane fit
f = fittype('poly11');

% Curve-fitting
[F,gof] = fit([cX,cY],thresholds,f);

%%% Meshgrid for prediction sites
[mX,mY] = meshgrid([0:0.01:0.07],[0:0.01:0.07]);

% Predicted thresholds
mZ = F(mX,mY);

% Heuristic to find the points you'd like
%   This is purely arbitrary; see commented code below
cutoff = 12.9;
[c1,c2] = deal(mX(mZ(:)>cutoff),mY(mZ(:)>cutoff));
assert(sum(mZ(:)>cutoff)==24,'Likely a new plane fit has changed your heuristic cutoff. Use the visualization code below to examine how many points your heuristic is sampling')

% Discard the origin, since this will likely be part of your
% STDP_recon_validation.m
origin = find(c1 == 0 & c2 == 0);
c1(origin) = [];
c2(origin) = [];

% Code to visualize the heuristic
%{
figure
contour(mX,mY,mZ,0:5:30,'ShowText','on')
xlim([0 0.07])
ylim([0 0.07])
axis square
hold on
scatter(mX(mZ>12.9),mY(mZ>12.9),'o')
%}

% Compute coordinate matrix to fold into ThresholdExperiment code below
c = [c1 c2];

%% Give starting index and increment to run on 2 nodes (if needed)
start = 1;
increment = 1;

%% Cycle through ThresholdExperiments for Reconstructed weighting matrices given in key

for i = start:increment:size(c,1)

    % Choose particular weighting matrix
    fprintf(['Loop %i\n'],i) % For logging purposes on server

    %%% ThresholdExperiment preliminaries
    % Directories for saving
    VarDir = 'ThresholdExperiment/STDP_recon_random'; % Updated variable directory for ThresholdExperiments
    
    % Directory for specific experiment
    ExpName = sprintf('ReconRandom-%0.3f-%0.3f',c(i,1),c(i,2));

    % Generate container for ThresholdExperiment
    E = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
    E.UpdateDir(VarDir);

    % Update ThresholdExperiment settings
    E.param.inputs.levels = 5:2.5:20; % Adjust tested input levels as desired

    %%% Simulation preliminaries
    % Generate container for Simulation
    S = Simulation('DefaultSimulationParameters');

    % Generate your reconstructed matrix
    ci = c(i,:).'; % Use arbitrary grid site defined earlier
    S.param.dW = PE.Reconstruct(ci); % Reconstruct the dW matrix

    % Prepare Simulation
    Prepare(S);

    % Link ThresholdExperiment to Simulation
    E.S = S;
    
    %%% Run ThresholdExperiment
    Run(E)

end