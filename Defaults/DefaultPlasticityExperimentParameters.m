% Basic parameters
n = 1;                          % Number of simulations to run at each input level
inputs = struct(...             % Inputs to be used in each simulation 
    'type','Deterministic',...  %   to determine seizure probability
    'levels',3 ...              % Levels of stimulation to simulate (e.g. sigmas or durations)   
    );

% Flags                            
flags = struct(...
    'parallel',false...         % Force use of parfor loops even if not on server
    );
