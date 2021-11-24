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

%% Reconstruct matrices frothxm PCA projections
X = (S*C.'.*std(B))+mean(B);
d = (sum(B.*X)./sqrt(sum(B.^2).*sum(X.^2))).'; % dot product
i = C(:,1)>0;
vi = d>0.95; % Take only those that are reconstructed to dot product >0.95;

%% Contstruct rolling average
% r = sqrt(sum(C(:,1:2).^2,2));
% th = atan(C(:,2)./C(:,1));
% 
% T = [];
% thi = [0:pi/300:pi/2];
% for j = 1:numel(thi)
%    % take sections of pi/40, in first quadrant, with accuracy of vi (0.95)
%    tp = th<(thi(j)+pi/40) & th>(thi(j)-pi/40) & i & vi;
%    T(:,:,j) = mean(F(:,:,tp),3);
% end
% Q = reshape(T,[size(T,1).*size(T,2) size(T,3)]);
% X = cellfun(@(x)rot90(fliplr(tril(F(:,:,x)-1))) + triu(F(:,:,x)-1),num2cell(1:size(F,3)),'un',0);
% X = cat(3,X{:});
% 
% N = nan(500,100,size(X,3));
% for ix = 1:size(X,3);
%     n = nan(500,100);
%     for jx = 1:100
%         n(jx:jx-1+numel(diag(X(:,:,ix),jx)),jx) = diag(X(:,:,ix),jx);
%     end
%     N(:,:,ix) = n;
% end
% 
% 
% 
% % Z = reshape((zscore(Q)/10)+1,size(T,1),size(T,2),size(T,3));
% 
%% Parse matrices into theta bins
r = sqrt(sum(C(i.*vi==1,1:2).^2,2));
th = atan(C(i.*vi==1,2)./C(i.*vi==1,1));
cc = C(i.*vi==1,:);
[y,b] = discretize(th,0:pi/20:pi/2);

j = 1; % Pick sub-population of matrix based on bin
dWsim = mean(F(:,:,cellfun(@(x)find(cumsum(i.*vi)==x,1,'first'),num2cell(find(y == j)))),3);
dWsim = dWsim - (triu(dWsim-1)+rot90(fliplr(tril(dWsim-1))));

param.dW_matrix = dWsim;

%% Run experiment with parameters
sbm.find_mini_model_threshold(param)
