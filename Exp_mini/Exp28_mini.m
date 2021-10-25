%%% Detemine mini model seizure threshold for the naive eLife model (Suppl
%%% 2A)

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
% param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = 0;
param.threshold_sigmas = 80:5:120; %5:5:40;
param.flag_deterministic = 0;
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
param.flag_kill_if_seizure = true;
param.flag_kill_if_wave_collapsed = false;
param.simulation_duration = 20000;
%%% param.g_K_max = 40; % number of ms per time step (ms)
%%% param.beta_param = 1.5; % number of ms per time step (ms)
% param.g_K_max = 50; % number of ms per time step (ms)
% param.beta_param = 1.5; % number of ms per time step (ms)
param.flag_add_noise = true;
param.dilate = 1;

%% Create and set average dW matrix
% Load average dW matrix
% f = dir('~/Desktop/Exp24_mini/');
% D = [];
% F = [];
% for i = 1:numel(f)
%     if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
%     if ~any(strfind(f(i).name,'.mat')), continue, end
%     load([f(i).folder '/' f(i).name])
%     fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
%     F = cat(3,F,lowpass(lowpass(d.dW,10/500,'ImpulseResponse','iir').',10/500,'ImpulseResponse','iir').');  
%     D = cat(3,D,d.dW);  
% end
% 
% param.dW_matrix = mean(D,3);

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)