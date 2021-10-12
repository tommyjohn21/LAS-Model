%%% Detemine mini model seizure threshold on central stimulation *after* one
%%% round of STDP; dWave is now upweighted by scalar value

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Local vs. server setings
vardir = '~/';
server = strcmp(computer,'GLNXA64'); % if server

if ~server
    vardir = [vardir 'Desktop/']; % on local, host on desktop
end


%% Create average dW matrix
f = dir([vardir 'Exp6_mini/']);
D = [];
for i = 1:numel(f)
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')) || any(strfind(f(i).name,'Wn')), continue, end
    load([f(i).folder '/' f(i).name])
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    D = cat(3,D,d.dW);
end
% Change of variable for consistency with code below
dWave = mean(D,3);

%% Upweight dWave
fprintf('Adjusting dWave...\n')
scalar = 4;
% error('This adjustment does not make sense as multiplying by scalar also undoes depression')
% dWave = scalar.*dWave;

%%% Would instead have to be:
%%% dWave = scalar.*(dWave-1)+1
dWave = scalar.*(dWave-1)+1;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0.475 0.525];
param.threshold_reptitions = 3;
param.threshold_stimulations = [1:0.05:3];
param.threshold_savedir = [vardir 'Exp8_mini/'];
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
% param.flag_kill_if_seizure = true;
% param.flag_kill_if_wave_collapsed = true;
param.dW_matrix = dWave;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)