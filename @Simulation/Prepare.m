function Prepare(S)
% Basic function to prepare simulation by creating network and input

    % Lay out network
    PrepareNetwork(S)

    % Generate external inputs
    PrepareInput(S)

end

%% Prepare network
function PrepareNetwork(S) % Lay out network/recurrent connections

% Determine mini vs. full context
if ~S.param.mini
   S.param.SpaceCompression = 1;
   S.param.TimeCompression = 1;
end

% Hack to port space/time compression into SpikingNetwork object
CompressString = sprintf('space_compression=%i;',S.param.SpaceCompression);
CompressString = [CompressString sprintf('time_compression=%i;',S.param.TimeCompression)];

% Generate spiking model according to template
S.O = SpikingModel([CompressString S.param.NetworkTemplate]);

% Parameter adjustment to match Fig5 (default on; cf. Sup2)
if S.param.fig5params
    S.O.param.beta = gen_param(1.5,0,S.O.n,1);
    S.O.param.f = @(u) S.O.param.f0+S.O.param.fs.*exp(u./S.O.param.beta); % unit: kHz
    S.O.param.g_K_max = gen_param(50,0,S.O.n,1);
    S.O.param.dilate = 1; % Reduce dilation in mini/full-model for Fig5 params
end

% Build recurrent connections
DefaultRecurrentConnection(S.O); % output P_E for ease of adjustment

% Update weights with dW if desired
if any(S.param.dW(:) ~= 1), UpdateWeightMatrix(S), end

% Enable STDP if desired
if S.param.flags.realtimeSTDP, EnableSTDP(S), end
    
end

%% Update weight matrix
function UpdateWeightMatrix(S)

% For easy indexing, get handle to excitatory projections
P_E = S.O.Proj.In(1);

% Change to sparse matrix notation instead of convolution
if ~strcmp(P_E.Method,'multiplication')
    KernelToMultiplication(P_E);
end

% Capture total output energy (for renormalization)
output = sum(P_E.W);

% Update weight matrix
P_E.W = P_E.W.*S.param.dW;

% Renomalize dW matrix if desired
if S.param.flags.normalizeSTDP
    P_E.W = P_E.W./sum(P_E.W).*output;
end

end

%% Enable STDP
function EnableSTDP(S)

% For easy indexing, get handle to excitatory projections
P_E = S.O.Proj.In(1);

% Change to sparse matrix notation instead of convolution
if ~strcmp(P_E.Method,'multiplication')
    KernelToMultiplication(P_E);
end

P_E.STDP.Enabled = 1; % Enable STDP

% Compress time constants as appropriate
P_E.STDP.tau_LTD = P_E.STDP.tau_LTD./S.O.param.time_compression;
P_E.STDP.tau_LTP = P_E.STDP.tau_LTP./S.O.param.time_compression;

% Scale STDP strength if desired (default is 1)
P_E.STDP.dLTD = P_E.STDP.dLTD.*S.param.STDPscale;
P_E.STDP.dLTP = P_E.STDP.dLTP.*S.param.STDPscale;

end

%% Prepare input
function PrepareInput(S) % Lay out external inputs
% Basic external input functions
S.O.Ext = ExternalInput;
S.O.Ext.Target = S.O;

% Deterministic external input (default duration 0s, i.e. no input)
Ic = S.param.input.Deterministic.magnitude;
stim_x = S.param.input.Deterministic.location;
stim_t = [2 2+S.param.input.Deterministic.duration]; % Unit: second
S.O.Ext.Deterministic = @(x,t) ((stim_x(2)*S.O.n(1))>x(:,1) & x(:,1)>(stim_x(1)*S.O.n(1))) .* ...
    ((stim_t(2)*1000)>t & t>(stim_t(1)*1000)) .* ...
    Ic; % x: position, t: ms, current unit: pA

if S.param.flags.noise % Add generative background noise by default
    S.O.Ext.Random.sigma = S.param.input.Random.sigma; % unit: pA
    S.O.Ext.Random.tau_x = S.param.input.Random.tau_x./S.O.param.space_compression; % spatial constant unit: neuron index
    S.O.Ext.Random.tau_t = S.param.input.Random.tau_t./S.O.param.time_compression; % time unit: ms
end

end

