function DetectSeizure(S)
% Detect seizure in current simulation

% Pull out handle for network
O = S.O;

% Extract voltage traces
V = O.Recorder.Var.V(:,1:O.t);

%%% Port up metrics
% Cycle through all 'Trace' possibilities
fn = fieldnames(S.param.flags.return);
for i = find([cellfun(@(s)contains(s,'Trace'),fn)]).'
    if S.param.flags.return.(fn{i}) && ~strcmp(fn{i},'StateTrace'), PortUp(S,fn{i}); end
end

% Detect only if desired
if ~S.param.flags.DetectSeizure
    if S.param.flags.return.StateTrace, warning('Seizure detection is disabled, but StateTrace is requested. StateTrace will not be computed.'), end
    return
end

% Kernel for Gaussian convoluation
g = normpdf(-4:6/1000:4,0,1); % gaussian for filtering
g = g./sum(g); % normalize AUC

% Compute tonic wavefront
tonic = lowpass(V.',0.125,1000./S.param.dt,'ImpulseResponse','iir').';

% Compute alpha content of gamma envelope
W = abs(hilbert(bandpass(V.',[175 325],1000./S.param.dt,'ImpulseResponse','iir'))).';
a = [];
for n = 1:size(V,1)
   [wt,f] = cwt(W(n,:),1000./S.param.dt); 
   a = [a; abs(mean(wt(f>5&f<15,:),1))];
end

% Find clonic core
clonic = conv2(lowpass(a,0.05),g,'same');

% Heuristic cutoffs
cutoff_tonic = -40;
cutoff_clonic = 1;
if ~S.param.mini, error('Heuristics have not been evaluated for full model!'), end

% Embedded code to see scoring
state_trace = (tonic>cutoff_tonic)+2*(clonic>cutoff_clonic);

% Actual seizure detection
d_tonic = sum(tonic>cutoff_tonic)>1;
d_clonic = sum(clonic>cutoff_clonic)>1;
states = [d_tonic; d_clonic]; % [0;0] is null state, [1;0] is tonic wave, [0;1] is clonic core, [1;1] is both 

% Ensure that both tonic and clonic are detected
all_states = any(states(1,:)) && any(states(2,:)); % Make sure at least some tonic AND clonic

% Ensure that clonic activity follows at least some point of isolated tonic
% activity
start_of_tonic = find(d_tonic & ~d_clonic,1,'first'); % Find beginning of tonic wavefront (without clonic)
correct_order = any(sum(states(2,start_of_tonic:end))); % Make sure that clonic activity is found at some point after isolated tonic wave

% Ensure clonic phase lasts for at least some duration of time
clonic_duration = 0.3e3; % 1e3 for at least one second of clonic activity
appropriate_clonic_duration = sum(d_clonic)>clonic_duration;

% Detect seizure
seizure = 0; % Default
if all_states && correct_order && ...
        appropriate_clonic_duration
    seizure = 1;
end

% Port up metrics
if S.param.flags.return.StateTrace, S.detector.State = state_trace; end
S.detector.WaveCollapsed = sum(states(:))>0 & all(states(1,end-100:end)==0);
S.detector.Seizure = seizure;

end

function PortUp(S,fs)
   
    % Choose appropriate metric to port up
    switch fs
        case 'VoltageTrace', s = 'V';
        case 'ThresholdTrace', s = 'phi';
        case 'ChlorideTrace', s = 'Cl_in';
        case 'gKTrace', s = 'g_K';
    end

    % Choose which neurons to port up
    if isnan(S.param.flags.return.Neurons)
        N = 1:S.O.n;
    else
        N = S.param.flags.return.Neurons;
    end

    % Retrieve metric
    X = S.O.Recorder.Var.(s); % Retreive appropriate data
    if S.param.flags.return.Trim % Trim if requested
        % Assume a sampling/simulation time step of 1 ms
        assert(~isnan(S.param.flags.return.TrimDuration),'You may have asked to Trim and not provided a TrimDuration')
        S.detector.(s) = X(N,end-S.param.flags.return.TrimDuration.*1000:end-1);
    else % If not Trim, return full Trace
        S.detector.(s) = X(N,:);
    end

end

