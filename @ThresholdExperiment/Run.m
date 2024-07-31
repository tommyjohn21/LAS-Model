function Run(E)
% Run the experiment stored in the Experiment object
%
% Workflow:
% 1. Generate Experiment object:
%       a. E = ThresholdExperiment(ExperimentName)
%       b. manipulate E.param as needed
% 2. Initialize Simulation and Simulation parameters to use in Experiment
%    and Prepare Simulation to generate Network object with network
%    parameters:
%       a. S = Simulation(SimulationTemplate);  % Load simulation parameters
%       b. manipulate S.param as needed
%       c. Prepare(S);                          % Generate network prior to simulation
%       d. manipulate S.O (Network) as needed
% 3. Asign Simulation to Experiment and Run Experiment:
%       a. E.S = S;
%       b. Run(E);

% Reset simulation if needed
if E.S.O.t>0, Reset(E.S); end

% Create ExpDir if doesn't exist
if ~exist(E.param.expdir,'dir'), mkdir(E.param.expdir); end

% Execute Simulations for each level
for i = 1:numel(E.param.inputs.levels), ExecuteSimulations(E,i); end

end

function ExecuteSimulations(E,i)

        % Pull local Simulation handle
        S = E.S;

        % Copy Simulation object to copy after each simulation run
        T = copy(S);
        
        % Identify local run parameters for readability
        param = E.param;
        type = param.inputs.type;
        level = param.inputs.levels(i);
        n = param.n;
        
        % Update input
        UpdateInput(S,type,level);
        
        % Skip Simulation if already performed
        FileName = sprintf([param.expdir 'ThresholdExperiment-Level-%0.3f.mat'],level);
        if exist(FileName,'file'), return, end
        
        % Initialize parallelizable output structures
        detector = cell(1,n); % Empty detector for concatenation
        seed = cell(1,n); % Empty seed container for concatenation

        % Run simulations
        if E.param.server || E.param.flags.parallel
            parfor (j = 1:n), [d,s] = Simulate(S,j,level,n); detector{j} = d; seed{j} = s; end
        else
            for j = 1:n, [d,s] = Simulate(S,j,level,n); detector{j} = d; seed{j} = s; end
        end
        
        % Append completed results
        E.S.detector = [detector{:}];
        E.S.seed = [seed{:}];

        % Save output
        parsave(FileName,E)

        % Reset Simulation object, detector and seed in particular,
        E.S = T;

end

function [detector, seed] = Simulate(S,j,level,n)
    
    % Update user
    fprintf('Level %0.3f, simulation %i of %i\n',level,j,n)

    % Run the simulation
    Run(S); 
    
    % Collect output variables for pass up stack
    detector = S.detector; % Append detector from each simulation
    seed = S.seed; % Retain seeds used in each simulation 

    % Reset for next loop
    Reset(S);  

end

function parsave(FileName,E)
    disp(['Saving ' FileName])
    save(FileName, 'E', '-v7.3')
end
