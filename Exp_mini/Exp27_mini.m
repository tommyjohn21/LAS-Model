%%% Detemine mini model seizure threshold for the stabilized eLife model
%%% after application of dWave (in Exp5), parsed by *type*, to the extent
%%% that such a thing exists in the stablized model

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
% param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = 0;
param.threshold_sigmas = [5:5:10 15:2.5:35 40];
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
F = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    assert(d.seizure==1)
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    F = cat(3,F,lowpass(lowpass(d.dW,10/500,'ImpulseResponse','iir').',10/500,'ImpulseResponse','iir').');
    D = cat(3,D,d.dW);
end

%% Compute nodes/types
fprintf('Parsing nodes/types...\n')
fixed_points = @(x) diff(sign(x))./2;

% Pull out fixed points
C = zeros(100,size(F,2)-2);
W = zeros(100,size(F,2)-1);
E = zeros(100,1);
for j = 1:100
    ch = F(:,:,j).*Wn-Wn;
    w = nan(50,numel(diag(ch))-1);
    for i = 1:50
        w(i,i:end)=diag(ch,-i);
    end
    W(j,:) = nanmean(w);
       
    C(j,:) = fixed_points(W(j,:));
end

S = sum(W,2);
[m,i] = sort(S);

% Parse out types of STDP matrix
dW1 = mean(D(:,:,i(1:10)),3);
dW2 = mean(D(:,:,i(46:55)),3);
dW3 = mean(D(:,:,i(end-9:end)),3);
  
% Set dW matrix to type 1
param.dW_matrix = dW2;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)