function Run(S)
% Run simulation

% Pull out handle for network
O = S.O;

%%% Simulation settings
dt = S.param.dt; % ms
R = CreateRecorder(O,round(S.param.duration)); % The 2nd argument is Recorder.Capacity
T_end = R.Capacity - 1; % simulation end time.

%%% Assert that seed for Simulation is correct
CurrentSeed = rng;
assert(isequal(S.seed,CurrentSeed),'CurrentSeed is not equal to S.seed. Try Reset(S) and then Run(S).');

%%% Run simulation
while 1
    
    % Termination criteria
    if O.t >= T_end
        % Run final seizure detection at end of run if no seizure
        % detected prior
        DetectSeizure(S)
        disp(['t = ' num2str(O.t/1000) 's, end'])
        break
    end
    
    WriteToRecorder(O);
    Update(O,dt);
    
    % Detect seizures
    if mod(O.t,5000)==0 && (O.t>((2+S.param.input.Deterministic.duration+0.5)*1000)) % Do not check until after deterministic stimulation
        if S.param.flags.DetectSeizure, DetectSeizure(S), end
        if S.param.flags.kill.IfSeizure && S.detector.Seizure, break, end
        if S.param.flags.kill.IfWaveCollapsed && S.detector.WaveCollapsed, break, end
        disp(['t = ' num2str(O.t/1000) 's, continue'])
    end
    
end

end