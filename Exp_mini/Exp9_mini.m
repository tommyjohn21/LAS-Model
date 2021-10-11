%%% Detemine mini model seizure threshold after carefully selected dW
%%% matrix from round one (i.e. cherry picked)

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Create average dW matrix
f = dir('~/Desktop/Exp6_mini/');
D = [];
for i = 1:numel(f)
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')) || any(strfind(f(i).name,'Wn')), continue, end
    load([f(i).folder '/' f(i).name])
    D = cat(3,D,d.dW);
end
% Change of variable for consistency with code below
dWave = mean(D,3);

%% Upweight dWave
scalar = 1.1; % produces max value in central stim that is the same as max value in edge stim

dWave = scalar.*dWave;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = [1:0.05:3];
param.threshold_savedir = '~/Exp7_mini/';
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
% param.flag_kill_if_seizure = true;
% param.flag_kill_if_wave_collapsed = true;
param.dW_matrix = dWave;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)