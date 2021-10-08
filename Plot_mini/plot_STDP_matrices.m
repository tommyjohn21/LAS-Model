%%% plot_STDP_matrices pairs with Exp_3_mini. Exp_3_mini computes STDP
%%% matrices from edge stimulation of mini model (N=100). This script plots
%%% those results

%% Load ~10 STDP matrices
f = dir('~/Desktop/Exp6_mini/');
D = [];
for i = 1:10
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')), continue, end
    load([f(i).folder '/' f(i).name])
    D = [D d];
end
% Change of variable for consistency with code below
d = D;

%% Plot a set of matrices
numplots = 3;
start = 5;
f = figure;
t = tiledlayout(2,numplots);
for i = start:start+numplots-1 % simulations to cycle through
    
    % Load data from simulation
    V = d(i).V;
    
    % Switch tile and plot
    nexttile
    a = gca;
    imagesc(a,0.001:0.001:size(V,2)./1000,1:500,V);
    title(['Voltage trace ' num2str(i)]);
    a.XLabel.String = 'Time (s)';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
    caxis([-85 -35]);
    c.Label.String = 'Voltage (mV)';    
end

for i = start:start+numplots-1 % simulations to cycle through
    
    % Load data from simulation
    stdp = d(i).dW;
    
    % Switch tile and plot
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    title(['dW matrix ' num2str(i)]);
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = 'dW (au)';
end
    
figname = ['dW_matrices'];
saveas(f,['~/Desktop/' figname '.svg'])

%% Load only dW matrices
f = dir('~/Desktop/Exp6_mini/');
dW = [];
i = 0; % which file in the directory
j = 1; % how many files have been loaded
while j <=15
    i = i+1;
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')), continue, end
    load([f(i).folder '/' f(i).name])
    dW = cat(3,dW,d.dW);
    j = j+1;
end

%% Plot 10 dW matrices
f = figure;
t = tiledlayout(3,5);

% Plot each dW matrix
for i = 1:15
    
    % load STDP data
    stdp = dW(:,:,i);
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    axis square
    title(['dW matrix ' num2str(i)]);
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = 'dW (au)';
    
end

figname = ['15_dW_matrices'];
saveas(f,['~/Desktop/' figname '.svg'])

%% Create average dW matrix
f = dir('~/Desktop/Exp6_mini/');
D = [];
C = []; % Length of clonic core
S = []; % Length of seizure
for i = 1:numel(f)
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')), continue, end
    load([f(i).folder '/' f(i).name])
    D = cat(3,D,d.dW);
    C = [C sum(d.detector_metrics.states==2)./1000]; % natively written in s (instead of ms)
    S = [S sum(d.detector_metrics.states>0)./1000]; % natively written in s (instead of ms)
end
% Change of variable for consistency with code below
dWave = mean(D,3);

%% Plot average dW matrix
f = figure;
a = gca;
imagesc(a,1:500,1:500,dWave);
axis square
title(['Average dW matrix (n=100)']);
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.FontSize = 18;
c = colorbar;
%     caxis([0.7 1.3]);
c.Label.String = 'dW (au)';

figname = ['dWave'];
saveas(f,['~/Desktop/' figname '.svg'])

%% Relate individual dW matrices to seizure characteristics
D_unwrapped = reshape(D,[size(D,1).*size(D,2),size(D,3)]);
D_std = std(D_unwrapped);
fig = figure;
a = gca;
plot(C,D_std,'.','MarkerSize',10)
a.XLabel.String = 'Duration of detected clonic core (s)';
a.YLabel.String = '\sigma_{dW} (au)';
a.FontSize = 18;

% Curve fit
f = fit(C.',D_std.','power2');
hold on
x = [min(C):0.01:max(C)];
y = f(x);
plot(x,y,'LineWidth',2)
legend('Data',['y = (' sprintf('%0.1e',f.a) ')*x^{' sprintf('%0.2f',f.b) '} + ' sprintf('%0.1e',f.c)],...
    'Location','NorthWest')
a.Title.String = ['\sigma_{dW} vs. Duration of clonic core'];

figname = ['std_vs_core'];
saveas(fig,['~/Desktop/' figname '.svg'])


%% Connect std_dW to seizure length
fig = figure;
a = gca;
plot(S,D_std,'.','MarkerSize',10)
a.XLabel.String = 'Duration of detected seizure (s)';
a.YLabel.String = '\sigma_{dW} (au)';
a.FontSize = 18;

% Curve fit
f = fit(S.',D_std.','power2');
hold on
x = [min(S):0.01:max(S)];
y = f(x);
plot(x,y,'LineWidth',2)
legend('Data',['y = (' sprintf('%0.1e',f.a) ')*x^{' sprintf('%0.2f',f.b) '} + ' sprintf('%0.1e',f.c)],...
    'Location','NorthWest')
a.Title.String = ['\sigma_{dW} vs. Duration of seizure'];

figname = ['std_vs_seizure'];
saveas(fig,['~/Desktop/' figname '.svg'])

%% Compare length of seizure to length of clonic core
fig = figure;
a = gca;
plot(S,C,'.','MarkerSize',10)
a.XLabel.String = 'Duration of detected seizure (s)';
a.YLabel.String = 'Duration of clonic core (s)';
a.FontSize = 18;

% Curve fit
f = fit(S.',C.','poly1');
hold on
x = [min(S):0.01:max(S)];
y = f(x);
plot(x,y,'LineWidth',2)
legend('Data',['y = (' sprintf('%0.1f',f.p1) ')*x' strrep(sprintf('%0.1f',f.p2),'-',' - ')],...
    'Location','NorthWest')
a.Title.String = ['Duration of clonic core vs. Duration of seizure'];

figname = ['clonic_vs_seizure'];
saveas(fig,['~/Desktop/' figname '.svg'])

%% Extract off diagonal
length = numel(diag(dWave));

x = [];
for i = -60:-10
    x = [x, [diag(dWave,i); nan(abs(i),1)]];
end
y = smooth(nanmean(x,2),10);



