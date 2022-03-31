% Simulation timing settings
dt = 1;                             % Duration of each time step
duration = 20000;                   % Number of time steps to simulate

% Network to use for simulation, default is mini-model
NetworkTemplate = 'DefaultSpikingModel';    % Template for SpikingNetwork
fig5params = true;                          % Use g_k_max and beta from Fig5 (cf. Sup2)
mini = true;                                % Use mini-model
SpaceCompression = 4;                       % Multiplicative factor for space compression
TimeCompression = 2;                        % Multiplicative factor for time compression

% Default input settings
input = struct();                   % Setting for default deterministic noise inputs
input.Deterministic = struct(...    %%% Deterministic input
    'magnitude',200,...             %%%     Magnitude of current: pA    
    'location',[0.475 0.525],...    %%%     Spatial constant unit: neuron index
    'duration',0 ...                %%%     Time unit: s
    );
input.Random = struct(...           %%% Background noise
    'sigma',20,...                  %%%     Magnitude of noise: pA
    'tau_x',200,...                 %%%     Spatial constant unit: neuron index
    'tau_t',15 ...                  %%%     Time unit: s
    );

% STDP settings
STDPscale = 1;                      % Multiplier for realtime STDP learning
dW = 1;                             % Updating matrix for weights (default scalar of 1)

% Flags
flags = struct(...
    'noise',true,...                % Include background noise
    'realtimeSTDP',false,...        % Perform realtime STDP
    'kill',struct(...               % Kill simulation early if:
        'IfSeizure',true,...        %   Seizure is detected
        'IfWaveCollapsed',false...  %   Collapse of tonic wavefront (deprecated)
        ),...
    'return',struct(...             % Parameters to return for saving
        'VoltageTrace',false,...    %   Return raw voltage trace from simulation
        'StateTrace',false...       %   Return detected state trace
        ),...
    'normalizeSTDP',true,...        % Normalize neuron output after updating weights
    'DetectSeizure',true,...        % Detect seizures during simulation
    'UsePresetSeed',false...        % Create new random seed when (re-)running simulation
    );

% Miscellaneous settings
server = strcmp(computer,'GLNXA64');    % Use method Server to detect if simulation running on server
RandomSeed = rng;                       % Generate RandomSeed to be used on simulation run