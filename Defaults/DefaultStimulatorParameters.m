% Basic parameters

PulseTrainParam = struct(...        % Structure for PulseTrain parameters
    'frequency',200,...             % Frequency of pulses: Hz
    'duration',5,...                % Duration of each burst of stimulation: s
    'magnitude',200,...             % Magnitude of current: pA
    'pulsewidth',1,...              % Width of each pulse: ms
    'location',[0.475 0.525],...    % Spatial constant unit: neuron index (can have multiple locations given as rows)
    'delay',2,...                   % Delay to start of stimulation: s
    'phaseType','biphasic');        % phaseType can be biphasic or monophasic                     
    
EventDetectorParam = struct(...     % Structure for EventDetector parameters
    'eventDetector',false,...       % eventDetector controls whether events must be detected prior to stimulation
    'stimDuration',100,...          % Duration of stimulation after eventDetected: ms
    'stimDelay',0,...               % Delay of stimulator onset after eventDetected: ms
    'sensingLocation',[0.475 0.525]);   % Which location(s) to use for sensing events
