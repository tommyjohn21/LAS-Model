% Basic parameters
n = 100;                            % Number of simulations to run at each input level

inputs = struct(...                 % Structure for Stimulation parameters
    'type','Deterministic',...      % Type of input for stimulation
    'frequency',50,...              % Frequency of pulses: Hz
    'duration',3,...                % Duration of each burst of stimulation: s
    'magnitude',200,...             % Magnitude of current: pA
    'pulsewidth',5,...              % Width of each pulse: ms
    'location',[0.475 0.525],...    % Spatial constant unit: neuron index
    'delay',2,...                   % Delay to start of Stimulation: s
    'phaseType','biphasic');        % phaseTime can be biphasic or monophasic                     

% Flags                            
flags = struct(...
    'parallel',false,...            % Force use of parfor loops even if not on server
    'SpecifyInputs',true...         % Set to false if you wish to provide parameter 
    );                              %   ranges (and compute specific, valid inputs on 
                                    %   the fly; c.f. using exact input
                                    %   with prespecified parameters)



