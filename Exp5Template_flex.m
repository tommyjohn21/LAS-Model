SpikingModel1DStandardTemplate_flex;

%% beta parameter
% beta parameter controls probability of firing
%
% Control:
%   To increase firing prob, decrease beta
%   To decrease firing prob, increase beta
%
% Conversely:
%   Decreasing beta increases firing prob
%   Increasing beta decreases firing prob

beta = gen_param(2.5,0,n,1); % more organized
% offset = gen_param(0,0,n,1); % more organized
% beta = gen_param(1.5,0,n,1); % Fig 5
% beta = gen_param(2.5,0,n,1); % Sup 2A
f = @(u) f0+fs.*exp(u./beta); % unit: kHz
% f = @(u) f0+fs.*(exp((u-offset)./beta)-1).*((u-offset)>=0); % unit: kHz
% f = @(u) (1-1./(1+exp((u-offset)./beta)));
% f = @(u) 2.*(0.5-1./(1+exp((u-offset)./beta))).*((u-offset)>0);

% linear implementation
% a = gen_param(0,0,n,1);
% b = gen_param(10,0,n,1);
% f = @(u) ((1./(b-a).*u) + (0-(1./(b-a)).*a)).*((u>a).*(u<=b)) + double(u>b);

%% g_K_max parameter
% g_K_max controls baseline conductance through E_k channels
%
% Control:
%   To increase excitability, decrease g_K_max
%   To decrease excitability, increase g_K_max
%
% Conversely:
%   Decreasing g_K_max increases excitability
%   Increasing g_K_max decreases excitability

dyn_scale = 1.02;
dyn_scale_Cl = 0.96 * dyn_scale; %0.95
dyn_scale_gK = 1 * dyn_scale;
amp = 1.05;

g_K_max = gen_param(47/dyn_scale_gK*amp,0,n,1);  % 39.5
% g_K_max = gen_param(50,0,n,1); % Fig 5
% g_K_max = gen_param(40,0,n,1); % Sup 2A

% Decreasing tau_Cl allows for improved Cl gradient, and improved
% inhibition; larger values mean unable to inhibit activity
tau_K = gen_param(3150/dyn_scale_gK,0,[n,1],1); % Can also be function
% E_K = gen_param(-90,0,n,0);

tau_syn.I_global = gen_param(15,0,n,0); % Inhibitory synaptic time constant for global inhibition
% tau_syn.I_global = gen_param(15,0,n,0); % Inhibitory synaptic time constant for global inhibition
Vd_Cl = gen_param(0.955./dyn_scale_Cl/amp,0,n,0);
% Vd_Cl = Vd_Cl./dyn_scale;
% Cl_in_eq = gen_param(5.5,0,n,1); % The equilibruim intracellular chloride concentration, 
tau_Cl = gen_param(1850/dyn_scale_Cl,0,n,1); % Chloride clearance time constant
% Cl_in = Cl_in_eq;
