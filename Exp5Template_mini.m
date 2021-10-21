SpikingModel1DStandardTemplate_mini;

% Parameter adjustment
g_K_max = gen_param(40,0,n,1); 
beta = gen_param(2.5,0,n,1); % mV, high beta = low threshold noise
f = @(u) f0+fs.*exp(u./beta); % unit: kHz


