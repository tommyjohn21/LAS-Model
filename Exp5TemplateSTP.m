SpikingModel1DStandardTemplate;

% Parameter adjustment
% tw: not sure I understand why these parameters were adjusted (may need to
% check in the initial paper)
beta = gen_param(1.5,0,n,1);
f = @(u) f0+fs.*exp(u./beta); % unit: kHz

% gK_max in nS
g_K_max = gen_param(50,0,n,1); 

% tw: turn on short-term plasticity - copied from
% SpikingModel1DStandardTemplate

% ######### STP #########

% Supplementary dynamics - short-term plasticity

% Short-term plasticity variables, reference: Science 2008, Mongillo et. al.
% Larry & Misha's models are actually equivalent if you set u constant in Misha's model
% It's just Larry's output is x, but Misha's output is u*x, for detailed explanation, 
% please read the word file 
flag_STP = false; % Whether STP is allowed or not
tau_D = gen_param(0,0,n,1); % ms, put it 0 to disable depression
tau_F = gen_param(0,0,n,1); % ms, put it 0 to disable faciliation
U = gen_param(0.2,0,n,1); % 1-U is actually f_D in Larry's model if u is constant
    % U stands for portion of calcium influx, set tau_F = 0 to terminate
    % facilitation process
    % The model actually requires you to think about u-(left limit) & u+(right limit) 
    % u stands for calcium concentration, and it has upper limit 1
    % the amount of vesicle release depends on u+ (limit from the right)
    % but the equation, u' = -u + U(1-u)dirac, actually describes u- (limit from the left)
    % so in their paper, the equation u is actually u+, which u+ = u-+U(1-u-) 
