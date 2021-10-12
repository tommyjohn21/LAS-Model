%%% Detemine mini model seizure threshold after carefully selected dW
%%% matrix from round one (i.e. cherry picked)

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
F = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')), continue, end
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

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = [1:0.05:3];
param.threshold_savedir = [vardir 'Exp9_mini/Type1'];
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
% param.flag_kill_if_seizure = true;
% param.flag_kill_if_wave_collapsed = true;
param.dW_matrix = dW1;

%% Run type 1 experiment with parameters
sbm.find_mini_model_threshold(param)

%% Run type 2 experiment with parameters
param.dW_matrix = dW2;
param.threshold_savedir = [vardir 'Exp9_mini/Type2'];

sbm.find_mini_model_threshold(param)


