%%% Parametrize STDP shapes, run threshold exp as function of shape

%% Access simulation_bin_mini tools
sbm = simulation_bin_mini;

%% Experiment parameters
% Call default params
param = sbm.simulate_mini_model('get_defaults');

% Adjust params
% param.stim_location = [0.475 0.525];
param.threshold_reptitions = 100;
param.threshold_stimulations = 0;
param.threshold_sigmas = [5:2.5:35];
param.flag_deterministic = 0;
% param.flag_return_voltage_trace = true;
% param.flag_return_state_trace = true;
param.flag_kill_if_seizure = true;
param.flag_kill_if_wave_collapsed = false;
param.simulation_duration = 20000;
%%% param.g_K_max = 40; % number of ms per time step (ms)
%%% param.beta_param = 1.5; % number of ms per time step (ms)
param.g_K_max = 50; % number of ms per time step (ms)
param.beta_param = 1.5; % number of ms per time step (ms)
param.flag_add_noise = true;
param.dilate = 1;
param.flag_renormalize_dW_matrix = true;

%% Create and set average dW matrix
% Load average dW matrix
f = dir('~/Desktop/Exp22_mini/');
D = [];
R = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    assert(d.seizure==1)
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    D = cat(3,D,d.dW);
    R = cat(3,R,rot90(d.dW,2));
%     
%     x = ((D(:,:,end)-1).*(Wn>0));
%     
%     X = []; for i = 1:500
%         j = i-50:i+50;
%         X = [X [nan(sum(j<=0),1); x(j(j>0&j<=500),i); nan(sum(j>500),1)]];
%     end
%     
%     F = cat(3,F,full(X).');
end

%% PCA on data data
F = cat(3,D,R);
A = full(Wn~=0).*(F-1);
B = reshape(A,[size(A,1).*size(A,2) size(A,3)]);
[c,s,l]=pca(B);

% Take only first two components
C = c(:,1:2);
S = s(:,1:2);

% Norm so that max of each principle component is unity
s1 = S;
c1 = C;
for i = 1:2
    ts = S(:,i);
    tc = C(:,i);
    mn = min(S(:,i));
    mx = max(S(:,i));
    ts(ts>0) = ts(ts>0)/mx;
    ts(ts<0) = -ts(ts<0)/mn;
    s1(:,i) = ts;
    c1(:,i) = tc.*mean([mx -mn]);
end

% s1 = S./max(abs(S));
% c1 = C.*max(abs(S));

% Create smooth gradation, all with max 1
phi = 0:pi/1000:pi/2;
b = [cos(phi);sin(phi)];
% Non-normalized sims
tmp = s1*b;
sim = zeros(size(tmp));
for i = 1:size(tmp,2)
    ts = tmp(:,i);
    mn = min(ts);
    mx = max(ts);
    ts(ts>0) = ts(ts>0)/mx;
    ts(ts<0) = -ts(ts<0)/mn;
    sim(:,i) = ts;
end
sim = reshape(sim,size(A,1),size(A,2),numel(phi));

% Average amplitude
a = mean(sqrt(sum((c1(c1(:,1)>0,:)).^2,2)));

%% Compose deepness of well metric
W = [];
for i = 1:size(sim,3)
   x = sim(:,:,i);
   X = [];
   for j = 1:size(x,2);
       jj = [j-49:j];
       X = [X [nan(sum(jj<=0),1); x(jj(jj>0&jj<=500),j); nan(sum(jj>500),1)]];
   end
   
   % Rotate and cut out nans in case of fft metric
   X = rot90(X(:,~any(isnan(X))));
   
   W = cat(3,W,-X);
end
% Deepness
d = squeeze(min(min(W))+max(max(W)))+1; % This is 1-cos(phi), more or less

% As an aside, deepness can be calculated on interval from 0 to 1 (this is your knob)
x = [0:1/500:1];
m = @(x)1-sqrt(1-sin(x.*pi/2).^2);

%% Choose slider value to test
slider = 1;

[~,i] = min(abs((d-m(slider)))); % Locate nearest example of such a mixture
dWsim = sim(:,:,i)*a+1;

param.dW_matrix = dWsim;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)
