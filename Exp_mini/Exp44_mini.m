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
param.threshold_sigmas = [5:2.5:20]; %[5:2.5:35];
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
[c,s,l]=pca(zscore(B));

% Take only first two components
C = c(:,1:2);
S = s(:,1:2);

%% Reconstruct matrices from PCA projections
X = (S*C.'.*std(B))+mean(B);
d = (sum(B.*X)./sqrt(sum(B.^2).*sum(X.^2))).'; % dot product
i = C(:,1)>0;
vi = d>0.95; % Take only those that are reconstructed to dot product >0.95;

%% Parse matrices into theta bins
cc = C(i.*vi==1,:);
r = sqrt(sum(C(i.*vi==1,1:2).^2,2));
th = atan(C(i.*vi==1,2)./C(i.*vi==1,1));
[y,b] = discretize(th,0:pi/20:pi/2);

% Choose random matrices to test (2 from each bin and a few radial
% variants)
% cell2mat(cellfun(@(x) x(randperm(numel(x),2)),cellfun(@(x) find(y==x),num2cell(1:numel(unique(y))),'un',0),'un',0))
ix = [73 141 233 93 254 285 80 27 132 396 215 242 33 77 348 14 381 280 200 212]; % Randomly generated
n = find(i.*vi);
j = n(ix); % These are the orderings in F (vs. y)

jx = 3; % Run through each random matrix
dWsim = F(:,:,j(jx));

param.dW_matrix = dWsim;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)
