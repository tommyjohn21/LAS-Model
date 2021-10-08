%%% Generate 100 STDP weighting matrices from mini model stimulated on
%%% inteverval [0 0.05]

%% Access simulation_bin_mini tools
smb = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = smb.simulate_mini_model('get_defaults');

% Adjust params
param.flag_kill_if_seizure = false;
param.flag_realtime_STDP = true;
param.threshold_reptitions = 1;
param.stim_duration = 3.5;
param.stim_location = [0 0.05];
param.flag_return_voltage_trace = true;
param.flag_return_state_trace = true;
param.simulation_duration = 50000;
param.threshold_savedir = '~/Exp3_mini/';

%% Run experiment with parameters
no_sims = 100; % number of simulations to run

if strcmp(computer,'GLNXA64') % if server
    parfor i = 1:no_sims
        
        % Update stimulation in way that can be parsed by parfor
        q = setfield(param,'stim_duration',param.stim_duration)
        
        % Function as below
        d = smb.simulate_mini_model(q);
        parsave([q.threshold_savedir 'stim_dur_3.5_rep_' num2str(i) '.mat'],d)
        
    end
else % local
    for i = 1:no_sims
        
        % Update stimulation in a way that can be parsed by parfor
        q = setfield(param,'stim_duration',param.stim_duration);
        
        % Save to desktop per local
        q.threshold_savedir = strrep(q.threshold_savedir,'~/','~/Desktop/');
        
        % Function as below
        d = smb.simulate_mini_model(q);
        parsave([q.threshold_savedir 'stim_dur_3.5_rep_' num2str(i) '.mat'],d)
        
    end
end