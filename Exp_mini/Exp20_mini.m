%%% Detemine mini model seizure threshold as a function of TYPE 2 subtype;
%%% Here we do subtype with the *least* central resonance

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
param.stim_location = [0.475 0.525];
param.threshold_reptitions = 40;
param.threshold_stimulations = 1.2:0.1:2;
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;

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
W = zeros(100,size(F,2));
for j = 1:100
    ch = F(:,:,j).*Wn-Wn;
    w = nan(51,numel(diag(ch)));
    for i = 0:50
        w(i+1,i+2:end)=diag(ch,-(i+1));
        W(j,:) = nansum(w);
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

%% Digest "type-2-ness"
R2 = R(:,:,type == 2); % These are the STDP matrices
RF2 = RF(:,:,type == 2);
W2 = W(type == 2,:); % This is the energy landscape
C2 = C(type == 2,:);

l = zeros(size(C2,1),1);
for i = 1:size(C2,1)
   l(i) = find(C2(i,:)>0,1,'last') - find(C2(i,:)>0,1,'first');
end
[~,idx] = sort(l);

% Set dW matrix to most (or least) type-2s
param.dW_matrix = mean(R2(:,:,idx(1:5)),3);

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)