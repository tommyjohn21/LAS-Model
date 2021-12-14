%%% Exp62_mini is a major workhorse. It will cycle through half of 40
%%% dW matrices (Exp 62:101) to compute thresholds

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
% param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = 0;
param.threshold_sigmas = [5:2.5:20]; %[5:2.5:35];
param.flag_deterministic = 0;
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
param.flag_kill_if_seizure = true;
param.flag_kill_if_wave_collapsed = false;
param.simulation_duration = 20000;
%%% param.g_K_max = 40; % number of ms per time step (ms)
%%% param.beta_param = 1.5; % number of ms per time step (ms)
param.g_K_max = 50; % number of ms per time step (ms)
param.beta_param = 1.5; % number of ms per time step (ms)
param.flag_add_noise = true;
param.dilate = 1;
param.flag_renormalize_dW_matrix = true;

%% Create and set average dW matrix
% Load average dW matrix
f = dir('~/Desktop/Exp22_mini/');
D = [];
R = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    assert(d.seizure==1)
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    D = cat(3,D,d.dW);
    R = cat(3,R,rot90(d.dW,2));
    %
    %     x = ((D(:,:,end)-1).*(Wn>0));
    %
    %     X = []; for i = 1:500
    %         j = i-50:i+50;
    %         X = [X [nan(sum(j<=0),1); x(j(j>0&j<=500),i); nan(sum(j>500),1)]];
    %     end
    %
    %     F = cat(3,F,full(X).');
end

%% PCA on data data
F = cat(3,D,R);
A = full(Wn~=0).*(F-1);
B = reshape(A,[size(A,1).*size(A,2) size(A,3)]);
[c,s,l]=pca(zscore(B));

% Individual dW matrices selected by hand to sample PCA space in 3
% components
j = [368 450 53 360 626 760 169 693 771 645 599 566 731 576 797 296 375 840 354 726];

% 20 randomly selected dW matrices (of the remaining that have yet to be
% tested)
j = [j 657 691 426 628  69 938 864 686 657 77 905 4 195 912 136 530 880 784 782 751];

%% Run experiment
% Map dW matrix to Exp Dir
fdir = 62:62+numel(j)-1;
if ~contains(param.vardir,'Exp_mini'), param.vardir = [param.vardir 'Exp_mini/']; end
if ~exist(param.vardir), mkdir(param.vardir); end

for jx = 1:2:numel(j)
    
    % Update save directory
    param.expdir = ['Exp' num2str(fdir(jx)) '_mini/'];
    
    % Create directory if needed
    if ~exist(param.fullpath(param)), mkdir(param.fullpath(param)); end
    
    % Choose weighting matrix
    dWsim = F(:,:,j(jx));
    param.dW_matrix = dWsim;
    
    % Run experiment with parameters
    sbm.find_mini_model_threshold(param)
    
end