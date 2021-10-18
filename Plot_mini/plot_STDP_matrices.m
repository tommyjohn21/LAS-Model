%%% plot_STDP_matrices pairs with Exp_3_mini. Exp_3_mini computes STDP
%%% matrices from edge stimulation of mini model (N=100). This script plots
%%% those results

%%% STDP matrix scripts: Exp3, Exp6, Exp10

%% Load ~10 STDP matrices
f = dir('~/Desktop/Exp14_mini/');
D = [];
for i = 1:15
    if ~any(strfind(f(i).name,'.mat')), continue, end    
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
f = dir('~/Desktop/Exp14_mini/');
dW = [];
i = 0; % which file in the directory
j = 1; % how many files have been loaded
while j <=15
    i = i+1;
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    dW = cat(3,dW,d.dW);
    j = j+1;
end

%% Plot 15 dW matrices
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
f = dir('~/Desktop/Exp14_mini/');
D = [];
C = []; % Length of clonic core
S = []; % Length of seizure
for i = 1:numel(f)
    if ~any(strfind(f(i).name,'.mat')), continue, end
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

%% Create average dW matrix
f = dir('~/Desktop/Exp14_mini/');
D = [];
F = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    F = cat(3,F,lowpass(lowpass(d.dW,10/500,'ImpulseResponse','iir').',10/500,'ImpulseResponse','iir').');  
    D = cat(3,D,d.dW);  
end

dWave = mean(D,3);

%% Net effect of dWave
f = figure;
imagesc(1:500,1:500,dWave.*Wn-Wn)
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
c = colorbar;
c.Label.String = '\DeltaW (au)';
a.FontSize = 18;
axis square;
a.Title.String = 'W_{STDP} - W_{naive}';
figname = 'dWave x Wnaive';
saveas(f,['~/Desktop/' figname '.svg'])

%% Plot 12 dW*Wn-Wn matrices
f = figure;
t = tiledlayout(3,4);

% Plot each dW matrix
for i = 1:12
    
    % load STDP data
    stdp = D(:,:,i).*Wn-Wn;
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    axis square
    title(['\DeltaW_{' num2str(i) '}']);
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = '\DeltaW (au)';
    
end

figname = ['12_deltaW_matrices'];
saveas(f,['~/Desktop/' figname '.svg'])

%% Plot 12 filtered dW*Wn-Wn matrices
f = figure;
t = tiledlayout(3,4);

% Plot each dW matrix
for i = 1:12
    
    % load STDP data
    stdp = F(:,:,i).*Wn-Wn;
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    axis square
    title(['\DeltaW_{' num2str(i) '} (filtered)']);
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = '\DeltaW (au)';
    
end

figname = ['12_deltaW_matrices_filtered'];
saveas(f,['~/Desktop/' figname '.svg'])


%% Compute nodes/types
fprintf('Parsing nodes/types...\n')
fixed_points = @(x) diff(sign(x));

% Pull out fixed points
C = zeros(100,size(F,2)-1);
for j = 1:100
    ch = F(:,:,j).*Wn-Wn;
    w = nan(51,numel(diag(ch)));
    for i = 0:50
        w(i+1,i+2:end)=diag(ch,-(i+1));
    end
    C(j,:) = fixed_points(nansum(w));
end
C(:,1:50) = 0; % Don't count edges (numerically unstable, presumably)
C(:,end-49:end) = 0; % Don't count edges 
type = sum(C>1,2); % Type 1: single node, Type 2: stable node exists

%% Demonstration of types
% Choose examples to show
t1 = find(type==1,6,'first');
t2 = find(type==2,6,'first');
o = [reshape(t1.',[3,2]) reshape(t2.',[3,2])].';
o = o(:);

% Plot types
f = figure;
t = tiledlayout(3,4);

% Plot each Delta W matrix
for i = 1:12
    
    % load STDP data
    stdp = F(:,:,o(i)).*Wn-Wn;
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    axis square
    if ismember(o(i),t1)
       title(['\DeltaW_{' num2str(i) '} (Type 1)']); 
    elseif ismember(o(i),t2)
       title(['\DeltaW_{' num2str(i) '} (Type 2)']); 
    end 
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = '\DeltaW (au)';
    
end

figname = ['types'];
saveas(f,['~/Desktop/' figname '.svg'])

%% Decide which type 1 to flip
flip = zeros(100,1);
for i = 1:100
    if type(i)==1 && find(C(i,:))>250
       flip(i) = -1;
    elseif type(i) == 2
        flip(i) = 0;
    else
       flip(i) = 1; 
    end
    
end

R = D; RF = F;
for i = 1:size(F,3)
    if flip(i)==1 || flip(i)==0
        continue
    else
       R(:,:,i) = rot90(R(:,:,i),2);
       RF(:,:,i) = rot90(RF(:,:,i),2);
    end
    
end

% Parse out two types of STDP matrix
dW1 = mean(R(:,:,type==1),3);
dW2 = mean(R(:,:,type==2),3);

%% Average type matrices
% Plot types
f = figure;
t = tiledlayout(2,2);

for i = 1:2
   
    % Choose appropriate type
    if i == 1
        stdp = dW1;
    elseif i == 2
        stdp = dW2;
    end
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,Wn.*stdp-Wn);
    axis square
    if i == 1
       title(['Average \DeltaW (Type 1)']); 
    elseif i == 2
       title(['Average \DeltaW (Type 2)']); 
    end 
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);
    c.Label.String = '\DeltaW (au)';
   
end

for i = 3:4
   
    % Choose appropriate type
    if i == 3
        stdp = dW1;
    elseif i == 4
        stdp = dW2;
    end
    
    nexttile
    a = gca;
    imagesc(a,1:500,1:500,stdp);
    axis square
    if i == 3
        title('Average dW matrix (Type 1)');
    elseif i == 4
        title('Average dW matrix (Type 2)');
    end
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.FontSize = 18;
    c = colorbar;
%     caxis([0.7 1.3]);  
    c.Label.String = 'dW (au)';
   
end

figname = ['average_type_matrices'];
saveas(f,['~/Desktop/' figname '.svg'])

