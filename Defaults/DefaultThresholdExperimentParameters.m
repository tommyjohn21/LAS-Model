% Basic parameters
n = 100;                    % Number of simulations to run at each input level
inputs = struct(...         % Inputs to be used in each simulation 
    'type','Random',...     %   to determine seizure probability
    'levels',5:5:20 ...     % Levels of stimulation to simulate (e.g. sigmas or durations)   
    );                      % Note: Eventually may wish to use deterministic 
                            %   inputs when determining threshold

% Flags                            
flags = struct(...
    'parallel',false...     % Force use of parfor loops even if not on server
    );



