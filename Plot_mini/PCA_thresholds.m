%% PCA thresholds
% Script intended to plot both ThresholdExperiment and PlasticityExperiment
% data in the same PCA space

%% Load PlasticityExperiment
% Preliminaries
PlasticityVarDir = 'PlasticityExperiment';
PlasticityExpName = 'naive';

% Create/update PlasticityExperiment
PE = PlasticityExperiment(PlasticityExpName);
PE.UpdateDir(PlasticityVarDir);

% Load/Parse PlasticityExperiment
Load(PE)
Parse(PE)

% Retrieve PCA coordinates
c = PE.Coord;

%% Load ThresholdExperiment array
% Gather names of all ThresholdExperiments in STDP
f = '~/Desktop/ThresholdExperiment/STDP';
f = dir(f);

% Extract ExpNames
ExpNames = f(arrayfun(@(f)contains(f.name,'PlasticityExperiment-naive'),f));

% Sort in numerical order (c.f. character/alphabetical order)
[ExpNums,idx] = sort(arrayfun(@(s)str2num(s.name(28:end)),ExpNames));
ExpNames = ExpNames(idx);

% Directory for ThresholdExperiment data
ThresholdVarDir = 'ThresholdExperiment/STDP';

% Create array of ThresholdExperiments
TE = arrayfun(@(f)ThresholdExperiment(f.name),ExpNames);
arrayfun(@(te)te.UpdateDir(ThresholdVarDir),TE);

% Load and trim array
arrayfun(@(te)Load(te),TE);
idx = arrayfun(@(te)~isempty(te.S),TE);
TE = TE(idx);
ExpNums = ExpNums(idx);

% Extract thresholds
t = arrayfun(@(te)Threshold(te),TE);

%% Plot threshold overlay on PCA component plot
% Generate figure and background
f = figure;
plot(c(:,1),c(:,2),'k.')
hold on

% Grid limits
a = gca;
% a.XLim = [0 0.066];
% a.XTick = 0:0.02:0.06
% a.YLim = [0 0.066];
% a.YTick = 0:0.02:0.06
grid on
grid(a,'minor')
axis square

% Labels
a.XLabel.String = 'Component 1';
a.YLabel.String = 'Component 2';
a.Title.String = 'PCA Coordinates';
a.FontSize = 18;

% Compute colors for thresholds
cb = parula(256); % colorbar of interest
cbi = [5:15/255:20].'; % digitize colorbar by threshold
tc = cb(dsearchn(cbi,t),:); % threshold colors

% Plot color markers
scatter(c(ExpNums,1),c(ExpNums,2),100,tc,'filled')

% Colorbar
cbr = colorbar;
caxis([5 20])
cbr.Label.String = 'Seizure threshold (pA)';



