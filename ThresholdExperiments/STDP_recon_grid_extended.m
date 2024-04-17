%%% Now that you have validated the PlasticityExperiment/Reconstruct
%%% technique in STDP_recon_validation, you are ready to Reconstruct
%%% arbitray combinations of PCA components and Simulate their thresholds.
%%% The approach is to generate combinations of [c1;c2] matrices by
%%% drawing from PCA space. You'll then Reconstruct the associated dW
%%% matrices and compute thresholds.

%%% Here, you want to see if your model extrapolates to off-grid (i.e. PAST
%%% the point of the naive network)

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

%% Generate grid-like sampling near origin
% The strategy here is to compute your best fit model and find a criterion
% to select for reconstructed matrices that live in a particular
% neighborhood of interest. You essentially want to check
% that your best fit model works in that region.

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

%%% Best fit threshold surface
% Pair down coordinates to only those with defined threshold values
[sX,sY,sZ] = deal(coords(ExpNums,1),coords(ExpNums,2),coords(ExpNums,3));

% Define a linear plane fit
f = fittype( 'a+b*x^2+c*y', 'independent', {'x', 'y'}, 'dependent', 'z' );

% Curve-fitting
[F,gof] = fit([sX,sY],thresholds,f);

%%% Meshgrid for prediction sites
[mX,mY] = meshgrid([-0.65:0.1625:0.65],[-0.475:0.075:0.4]);

% Predicted thresholds
mZ = F(mX,mY);

% Heuristic to find the points you'd like
%   This is purely arbitrary; see commented code below
valid = mZ>0 & mZ>5 & mY<-0.25;
valid = ([(-1).^(1:size(valid,1)).'*(-1).^(1:size(valid,2)) == 1].*valid)>0;
assert(sum(valid(:))==14,'You not sampling 14 points in your grid. Please inspect your valid heuristic.')
[s1,s2] = deal(mX(valid),mY(valid));

% Code to visualize the heuristic
%{
figure
contour(mX,mY,mZ,0:5:30,'ShowText','on')
axis square
hold on
scatter(mX(valid),mY(valid),'o')
%}

% Compute coordinate matrix to fold into ThresholdExperiment code below
s = [s1 s2];

%% Give starting index and increment to run on 2 nodes (if needed)
start = 1;
increment = 1;

%% Cycle through ThresholdExperiments for Reconstructed weighting matrices given in key

for i = start:increment:size(s,1)

    % Choose particular weighting matrix
    fprintf(['Loop %i\n'],i) % For logging purposes on server

    %%% ThresholdExperiment preliminaries
    % Directories for saving
    VarDir = 'ThresholdExperiment/STDP_recon_grid'; % Updated variable directory for ThresholdExperiments
    
    % Directory for specific experiment
    ExpName = sprintf('ReconRandom_%0.3f_%0.3f',s(i,1),s(i,2));

    % Generate container for ThresholdExperiment
    E = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
    E.UpdateDir(VarDir);

    % Update ThresholdExperiment settings
    E.param.inputs.levels = 5:2.5:30; % Adjust tested input levels as desired
    
    %%% Simulation preliminaries
    % Generate container for Simulation
    S = Simulation('DefaultSimulationParameters');

    % Generate your reconstructed matrix
    si = s(i,:).'; % Use arbitrary grid site defined earlier
    S.param.dW = PE.Reconstruct(si); % Reconstruct the dW matrix

    % Prepare Simulation
    Prepare(S);

    % Link ThresholdExperiment to Simulation
    E.S = S;
    
    %%% Run ThresholdExperiment
    Run(E)

end