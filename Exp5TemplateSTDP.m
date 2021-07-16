SpikingModel1DStandardTemplate;

% Parameter adjustment
% tw: not sure I understand why these parameters were adjusted (may need to
% check in the initial paper)
beta = gen_param(1.5,0,n,1);
f = @(u) f0+fs.*exp(u./beta); % unit: kHz

% gK_max in nS
g_K_max = gen_param(50,0,n,1); 