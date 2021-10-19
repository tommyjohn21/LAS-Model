%%% Generate 100 STDP weighting matrices from mini model stimulated on
%%% inteverval [0.475 0.525] with STDP strength increased AFTER Type 2
%%% seizure on round 1

%% Access simulation_bin_mini tools
smb = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = smb.simulate_mini_model('get_defaults');

% Adjust params
param.flag_kill_if_seizure = false;
param.flag_realtime_STDP = true;
param.STDP_scale = 4;
param.threshold_reptitions = 1;
param.stim_duration = 3;
param.stim_location = [0.475 0.525];
param.flag_return_voltage_trace = true;
param.flag_return_state_trace = true;
param.simulation_duration = 50000;

%% Create and set average dW matrix
% Load average dW matrix
f = dir('~/Desktop/Exp10_mini/');
D = [];
F = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    F = cat(3,F,lowpass(lowpass(d.dW,10/500,'ImpulseResponse','iir').',10/500,'ImpulseResponse','iir').');  
    D = cat(3,D,d.dW);  
end

%% Compute nodes/types
fprintf('Parsing nodes/types...')
fixed_points = @(x) diff(sign(x));

% Pull out fixed points
C = zeros(100,size(F,2)-1);
for j = 1:100
    ch = F(:,:,j).*Wn-Wn;
    w = nan(51,numel(diag(ch)));
    for i = 0:50
        w(i+1,i+2:end)=diag(ch,-(i+1));
    end
    C(j,:) = fixed_points(nansum(w));
end
C(:,1:50) = 0; % Don't count edges (numerically unstable, presumably)
C(:,end-49:end) = 0; % Don't count edges
type = sum(C>1,2); % Type 1: single node, Type 2: stable node exists

% Decide which type 1 to flip
flip = zeros(100,1);
for i = 1:100
    if type(i)==1 && find(C(i,:))>250
        flip(i) = -1;
    elseif type(i) == 2
        flip(i) = 0;
    else
        flip(i) = 1;
    end
    
end

R = D; RF = F;
for i = 1:size(F,3)
    if flip(i)==1 || flip(i)==0
        continue
    else
        R(:,:,i) = rot90(R(:,:,i),2);
        RF(:,:,i) = rot90(RF(:,:,i),2);
    end
    
end

% Parse out two types of STDP matrix
dW1 = mean(R(:,:,type==1),3);
dW2 = mean(R(:,:,type==2),3);
  
% Set dW matrix to type 1
param.dW_matrix = dW2;

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