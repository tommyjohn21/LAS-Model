SpikingModel1DStandardTemplate_edge;

% Parameter adjustment
% beta = gen_param(1.5,0,n,1);
beta = gen_param(2.5,0,n,1);
f = @(u) f0+fs.*exp(u./beta); % unit: kHz

% g_K_max = gen_param(50,0,n,1); 
g_K_max = gen_param(40,0,n,1); 