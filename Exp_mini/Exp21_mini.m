%%% Generate 100 STDP weighting matrices from mini model stimulated on
%%% inteverval [0.475 0.525] with g_K_max and beta as in Exp5_legacy)

%% Access simulation_bin_mini tools
smb = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = smb.simulate_mini_model('get_defaults');

% Adjust params
param.flag_kill_if_seizure = false;
param.flag_realtime_STDP = true;
param.STDP_scale = 1;
param.threshold_reptitions = 1;
param.stim_duration = 3;
param.stim_location = [0.475 0.525];
param.flag_return_voltage_trace = true;
param.flag_return_state_trace = true;
param.simulation_duration = 50000;
%%% param.g_K_max = 40; % number of ms per time step (ms)
%%% param.beta_param = 1.5; % number of ms per time step (ms)
param.g_K_max = 50; % number of ms per time step (ms)
param.beta_param = 1.5; % number of ms per time step (ms)


%% Run experiment with parameters
no_sims = 100; % number of simulations to run

if strcmp(computer,'GLNXA64') % if server
    parfor i = 1:no_sims
        
        % Update stimulation in way that can be parsed by parfor
        q = setfield(param,'stim_duration',param.stim_duration)
        
        % Function as below
        d = smb.simulate_mini_model(q);
        parsave([q.fullpath(q) 'stim_dur_3_rep_' num2str(i) '.mat'],d)
        
    end
else % local
    for i = 1:no_sims
        
        % Update stimulation in a way that can be parsed by parfor
        q = setfield(param,'stim_duration',param.stim_duration);
        
        % Function as below
        d = smb.simulate_mini_model(q);
        parsave([q.fullpath(q) 'stim_dur_3_rep_' num2str(i) '.mat'],d)
        
    end
end