SpikingModel1DStandardTemplate_mini;

% Parameter adjustment
beta = gen_param(2.5,0,n,1); % mV, high beta = low threshold noise
f = @(u) f0+fs.*exp(u./beta); % unit: kHz
