%%% Detemine mini model seizure threshold on edge stimulation

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0 0.05];
param.seizure_threshold = 1.5e5;
param.threshold_reptitions = 100; %40;
param.threshold_stimulations = [1:0.05:3.5];
param.threshold_savedir = '~/Exp2_mini/';
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
% param.flag_kill_if_seizure = false;
% param.flag_kill_if_wave_collapsed = false;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)