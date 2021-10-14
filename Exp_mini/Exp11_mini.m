%%% Detemine mini model seizure threshold on central stimulation *after* one
%%% round of jacked up STDP

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = 1.2:0.1:2;
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;

%% Create and set average dW matrix
% Load average dW matrix
if ~exist('dWave','var')
    f = dir('~/Desktop/Exp10_mini/');
    D = [];
    for i = 1:numel(f)
        if ~any(strfind(f(i).name,'.mat')) || any(strfind(f(i).name,'Wn')), continue, end
        fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
        load([f(i).folder '/' f(i).name])
        D = cat(3,D,d.dW);
    end
    % Change of variable for consistency with code below
    dWave = mean(D,3);
end

% Set dW matrix
param.dW_matrix = dWave;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)