function [cost] = ObjectiveFunction(magnitudeIndex, stimIndex, senseIndex, dWave, stimMagnitudes, stimPositionStart, sensePositionStart)
    % ObjectiveFunction is the objective function for the genetic algorithm
    
    %% Generate dWave
    % % Updated variable directory for PlasticityExperiments
    % PlasticityVarDir = 'PlasticityExperiment';
    % % Directory for specific experiment
    % PlasticityExpName = 'naive';
    % 
    % % Create/update PlasticityExperiment
    % PE = PlasticityExperiment(PlasticityExpName);
    % PE.UpdateDir(PlasticityVarDir);
    % 
    % % Load PlasticityExperimentf
    % Load(PE)
    % 
    % % Parsing runs PCA on data to produce appropriate PCA-space coordinates
    % Parse(PE)
    % 
    % % Pull dWave
    % dWave = PE.dWave;

    %% Prepare ThresholdExperiment
    VarDir = 'ThresholdExperiment/GeneticAlgorithm'; % Updated variable directory for ThresholdExperiments
    
    % Directory for the specific experiment
    %%% Directory composed in hexadecimal for unique directory identifier
    ExpName = sprintf(['GeneticAlgorithm-Input-'...
                strjoin(compose('%X',floor([stimMagnitudes(magnitudeIndex)...
                100*[stimPositionStart(stimIndex)...
                sensePositionStart(senseIndex)]])),'.')]); 
    
    % Generate container for ThresholdExperiment
    TE = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
    TE.UpdateDir(VarDir);

    % Update ThresholdExperiment settings
    TE.param.inputs.levels = 10:2.5:30; % Adjust tested input levels as desired
    TE.param.n = 40; % Number of simulations at each input level

    %% Generate and Prepare Simulation
    % Generate container for Simulation
    S = Simulation('DefaultSimulationParameters');

    % Manipulate S.param as needed
    S.param.dW                              = dWave;    % Give the average weight-updating matrix

    % Prepare Simulation
    Prepare(S);

    %% Generate and Attach Stimulator
    % Generate Stimulator
    %%% Variables you get to play with: stimulator location and
    %%% stimulator magnitude
    St = Stimulator;
    St.param.PulseTrainParam.location = [stimPositionStart(stimIndex) stimPositionStart(stimIndex) + 0.05];
    St.param.PulseTrainParam.magnitude = stimMagnitudes(magnitudeIndex);

    % Turn on event detector
    St.param.EventDetectorParam.eventDetector = true;
    St.param.EventDetectorParam.sensingLocation = [sensePositionStart(senseIndex) sensePositionStart(senseIndex) + 0.05];
    
    % Adjust Stimulator parameters given time contraction
    St.param.EventDetectorParam.stimDuration = 50;
    St.param.PulseTrainParam.frequency = 400;
    
    % Attach Stimulator
    AttachStimulator(S,St)

    %% Add extra variables to track
    % UserVarName = {'I_ext'};
    % S.O.UserData = struct();
    % S.O.UserData.UserVarName = UserVarName;
    
    %% Link Simulation to ThresholdExperiment object and Run
    % Link simulation
    TE.S = S;
    
    % Run ThresholdExperiment
    Run(TE)
    
    %% Load ThresholdExperiment results
    % Recycle TE variable
    clear TE
    TE = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
    TE.UpdateDir(VarDir);

    % Load results
    Load(TE)
    
    % Extract Threshold
    thresholdStimulator = Threshold(TE);

    %% Load the non-Stimulator results for comparison
    %%% Use this to compute the cost function
    
    % Data location variables for STDP_ave
    VarDirAve = 'ThresholdExperiment'; % Updated variable directory for ThresholdExperiments
    ExpNameAve = 'STDP_ave';

    % Generate container for ThresholdExperiment
    TEAve = ThresholdExperiment(ExpNameAve); % Create/update ThresholdExperiment
    TEAve.UpdateDir(VarDirAve);
    
    % Load dWave data
    Load(TEAve)
    
    % Extract Threshold
    thresholdAve = Threshold(TEAve);

    %% Compute cost
    cost = thresholdAve - thresholdStimulator;

end