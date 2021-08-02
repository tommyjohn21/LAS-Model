%% Use Exp5STDP.m script to generate 100 simulations of weight matrix

if 0 % turn off
    fname = '~/dW/dW_sim_';
    
    parfor i = 1:100
        
        % Annouce entry
        disp(['Beginning simulation ' num2str(i) '...'])
        
        % Generate and retrieve weight matrices
        o = Exp5STDP(i);
        
        % Save output in parallel fashion
        parsave([fname num2str(i) '.mat'],o)
        
    end
end

%% Generate images from a select few matrices
f = dir('~/Desktop/dW/');
load([f(3).folder '/' f(3).name]);
W = o.W;
dW = o.dW;

f = figure();
imagesc(1:2000,1:2000,W);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Naive weighting matrix (baseline)';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
clim = c.Limits;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'baselineconnectivitymatrix';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
imagesc(1:2000,1:2000,dW);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Weighting adjustment matrix (dW)';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
dWclim = c.Limits;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'dWmatrix';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
imagesc(1:2000,1:2000,dW.*W);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Adjusted weighting matrix';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
c.Limits = clim;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'adjustedmatrix';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
dW = dW-1;
dWmax = max(abs(dW(:)));
eta_adjustment_factor = 0.2 / dWmax; % Let's force it approximately 20% by the first learning
eta_adjustment_factor = round(eta_adjustment_factor*100)/100;
dW = dW * eta_adjustment_factor;
imagesc(1:2000,1:2000,dW*eta_adjustment_factor);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'eLife figure (dW-1), adjusted by eta';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
colormap(jet(360));
c.Limits = [-0.05 0.05];
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'elifefig';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% Generate additional dW matrices
f = dir('~/Desktop/dW/');
% i = randi(100)+4;
i = 59;
load([f(i).folder '/' f(i).name]);
dW = o.dW;

f = figure();
imagesc(1:2000,1:2000,dW);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Weighting adjustment matrix (dW)';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
c.Limits = dWclim;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = ['dW' num2str(i)];
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

% Residual from matrix
figure, imagesc(dW-dW1)

%% Fit using wavelet function
if 0
    f = dir('~/Desktop/dW/');
    load([f(3).folder '/' f(3).name]);
    dW = o.dW;
    
    x = [50;100;300;1/350;0;0]; % Initialize fitting parameters
    fun=@(x)wavelet(x,dW);
    param = fminsearch(fun,x);
    param = fminsearch(fun,param); % second param search as the first typically times out
end

f = figure();
imagesc(1:2000,1:2000,dW);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Weighting adjustment matrix (dW)';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
dWclim = c.Limits;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'dWmatrix';
saveas(f,['~/Desktop/' figname '.svg'])

f = figure();
imagesc(1:2000,1:2000,reconstruct_wavelet(param,dW));
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model reconstruction (6 parameters)';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
c.Limits = dWclim;
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'waveletmatrix';
saveas(f,['~/Desktop/' figname '.svg'])

%% Generate additional dW matrices
% i = randi(100)+2;
i = [3,98,68,21,30];

for ii = i
    f = dir('~/Desktop/dW/');
    load([f(ii).folder '/' f(ii).name]);
    dW = o.dW;
    
    f = figure();
    imagesc(1:2000,1:2000,dW);
    a = gca;
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.Title.String = 'Weighting adjustment matrix (dW)';
    % a.Title.String = 'Model seizure t_{stim}=3s';
    c = colorbar;
    caxis(dWclim);
    c.Label.String = 'Arbitrary units';
    a.FontSize = 18;
    figname = ['dW' num2str(ii)];
    saveas(f,['~/Desktop/' figname '.svg'])
%     close(f)
end

%% Generate average dW
% Results of the above are stored on the Desktop in dir called dW
if 0
s = zeros(2000,2000);
f = dir('~/Desktop/dW/');
for i = 1:numel(f) % cycle through dW matrices
    % skip text files, etc.
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.txt')), continue, end
    load([f(i).folder '/' f(i).name])
    s = s+o.dW;
end

% Compute mean
m=s./100;
end

f = figure();
imagesc(1:2000,1:2000,m);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Average weighting adjustment matrix (dW_{ave})';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
caxis(dWclim);
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = ['dW_ave_scaled'];
saveas(f,['~/Desktop/' figname '.svg'])
close(f)
    

f = figure();
imagesc(1:2000,1:2000,m);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Average weighting adjustment matrix (dW_{ave})';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
% caxis(dWclim);
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = ['dW_ave'];
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
dW = m-1;
dWmax = max(abs(dW(:)));
eta_adjustment_factor = 0.2 / dWmax; % Let's force it approximately 20% by the first learning
eta_adjustment_factor = round(eta_adjustment_factor*100)/100;
dW = dW * eta_adjustment_factor;
imagesc(1:2000,1:2000,dW*eta_adjustment_factor);
a = gca;
a.XLabel.String = 'Neuron index';
a.YLabel.String = 'Neuron index';
a.Title.String = 'eLife figure (dW_{ave}-1), adjusted by eta';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
colormap(jet(360));
caxis([-0.15 0.15]);
c.Label.String = 'Arbitrary units';
a.FontSize = 18;
figname = 'elifefig_mean';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)