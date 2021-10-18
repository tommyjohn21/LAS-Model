%% Header
% simualtion_bin contains local functions used repeatedly in testing mini
% seizure simulation and threshold detection

%% Allow access to local functions
%%% Functions not listed in this block are private by default
function sbm = simulation_bin_mini

% Simulate mini model
sbm.simulate_mini_model = @simulate_mini_model;

% Find mini model threshold
sbm.find_mini_model_threshold = @find_mini_model_threshold;

end

%% Simulate mini network
function output = simulate_mini_model(p)
% p contains simulation parameter settings

% Format simulation settings
p = simulation_settings(p);
if p.flag_get_defaults, p.flag_get_defaults = false; output = p; return, end % return output, kill script

for i = 1:p.no_simulations
    
    disp(['Stim dur ' num2str(p.stim_duration) 's, sim ' num2str(i) ' of ' num2str(p.no_simulations)])
    
    %%% Preliminaries
    % Generate mini model
    O = generate_mini_network;
    
    % Generate external input
    O = generate_external_input(O,p.stim_location,p.stim_duration);
    
    % Enable STDP
    O = enable_STDP(O,p);
    
    % Adjust matrix weights post-STDP
    O = adjust_weight_matrix(O,p);
        
    %%% Simulation settings
    dt = p.dt; % ms
    R = CreateRecorder(O,round(p.simulation_duration)); % The 2nd argument is Recorder.Capacity
    T_end = R.Capacity - 1; % simulation end time.
    
    %%% Run simulation
    while 1
        
        % Termination criteria
        if O.t >= T_end
            % Run final seizure detection at end of run if no seizure
            % detected prior
            [seizure,detector_metrics] = wavelet_detector(O,p);
            disp(['t = ' num2str(O.t/1000) 's, end'])
            break
        end
        
        WriteToRecorder(O);
        Update(O,dt);
        
        % Detect seizures
        if mod(O.t,5000)==0 && O.t>((2+p.stim_duration+0.5)*1000) % no need to look until end of stim
            [seizure,detector_metrics] = wavelet_detector(O,p);
            if p.flag_kill_if_seizure
                if seizure, break, end
            end
            if p.flag_kill_if_wave_collapsed
                if detector_metrics.wave_collapsed, break, end               
            end
            disp(['t = ' num2str(O.t/1000) 's, continue'])
        end
        
    end
    
    
    %%% Format output
    output(i).detector_metrics = detector_metrics;
    output(i).seizure = seizure;
    output(i).stim_duration = p.stim_duration;
    output(i).stim_location = p.stim_location;
        
    if p.flag_return_voltage_trace
        output(i).V = O.Recorder.Var.V(:,1:O.t);
    end
    
    if p.flag_realtime_STDP
        output(i).dW = O.Proj.In(1).STDP.W;
    end
    
    %%% Clear workspace
    clearvars('-except','output','p')
    
end

end

%% Find mini model threshold
function output = find_mini_model_threshold(p)

% Format settings
p = simulation_settings(p);
if p.flag_get_defaults, p.flag_get_defaults = false; output = p; return, end % return output, kill script
p.no_simulations = p.threshold_reptitions; % update how many simulations per stim strength

%%% Conditional parallel computation %%%
if p.server || p.flag_use_parallel % if server or if forced to use parallel
    parfor i = 1:numel(p.threshold_stimulations)
        
        % Update stimulation in way that can be parsed by parfor
        q = setfield(p,'stim_duration',p.threshold_stimulations(i))
        
        if ~exist([q.fullpath(q) 'stim_dur_' num2str(q.stim_duration) '.mat'],'file')   
            
            % Function as below
            d = simulate_mini_model(q);
            parsave([q.fullpath(q) 'stim_dur_' num2str(q.stim_duration) '.mat'],d)
            
        end
        
    end
else % local
    for i = p.threshold_stimulations
        
        % Update stimulation in a way that can be parsed by parfor
        q = setfield(p,'stim_duration',i);
        
        if ~exist([q.fullpath(q) 'stim_dur_' num2str(q.stim_duration) '.mat'],'file')
            
            % Function as below
            d = simulate_mini_model(q);
            parsave([q.fullpath(q) 'stim_dur_' num2str(i) '.mat'],d)
            
        end
        
    end
end

end

%% Default simulation settings
function p_out = simulation_settings(p_in)
   
    %%% Create input scheme
    p_out = inputParser;

    %%% Add parameters with default settings
    % SIMulation settings
    addParameter(p_out,'no_simulations',1) % number of simulations performed
    addParameter(p_out,'simulation_duration',25000) % number of time-steps simulated
    addParameter(p_out,'dt',1) % number of ms per time step (ms)

    % STIMulation settings
    addParameter(p_out,'stim_location',[0.475 0.525]) % where on line to stimulate (from 0 to 1)
    addParameter(p_out,'stim_duration',3) % duration of stimulation (s)
    
    % Optional flags
    addParameter(p_out,'flag_realtime_STDP',false) % Perform real time STDP
    addParameter(p_out,'flag_kill_if_seizure',true) % Kill simulation early if seizure detected
    addParameter(p_out,'flag_kill_if_wave_collapsed',true) % Kill simulation early if seizure detected
    addParameter(p_out,'flag_return_voltage_trace',false) % Return voltage trace if desired
    addParameter(p_out,'flag_return_state_trace',false) % Return state trace if desired
    addParameter(p_out,'flag_get_defaults',false) % Return voltage trace if desired
    addParameter(p_out,'flag_use_parallel',false) % Force usage of parfor loop
        
    % Seizure threshold settings
    addParameter(p_out,'threshold_stimulations',[0:0.05:2]) % Stimulation durations to use for threshold detection
    addParameter(p_out,'threshold_reptitions',40) % Number of repititions at each stimulation duration for threshold detection
    
    % Adjust weight matrix with custom weight matrix
    addParameter(p_out,'dW_matrix',[]) % if non-empty, W_updated = W_naive.*dW_matrix
    
    % STDP strength
    addParameter(p_out,'STDP_scale',1) % scale the strength of STDP
    
    % File settings
    addParameter(p_out,'server',isserver) % Decide if on server
    addParameter(p_out,'vardir',vardir) % Adjust vardir pending server
    addParameter(p_out,'expdir',expdir) % Adjust expdir pending Exp
    addParameter(p_out,'fullpath',@fullpath) % recall full file path
    
    %%% Parse input and return
    if strcmp(p_in,'get_defaults') || strcmp(p_in,'use_defaults')
            % Return/use defaults if asked
            parse(p_out,'no_simulations',1); % use first parameter as arbitrary choice
            p_out = p_out.Results; % print output for inspection            
            if strcmp(p_in,'get_defaults')
                p_out.flag_get_defaults = true; % reset show defaults flag to kill simulation before run
            end
    elseif isstruct(p_in)
            % Parse input without print
            parse(p_out,p_in)
            p_out = p_out.Results;
    else
        error('Input p must be either be ''get_defaults'', ''use_defaults'', or structure with desired non-default settings')
    end
    
end

%% Generate mini network
function [O, P_E, P_I1, P_I2] = generate_mini_network
% Lay out the field
O = SpikingModel('Exp5Template_mini');
% Build recurrent connection
[ P_E, P_I1, P_I2 ] = StandardRecurrentConnection_mini( O );
end

%% Generate external input
function O = generate_external_input(O,stim_location,stim_duration)
% External input
Ic = 200;
stim_x = stim_location;
stim_t = [2 2+stim_duration]; % Unit: second
O.Ext = ExternalInput;
O.Ext.Target = O;
O.Ext.Deterministic = @(x,t) ((stim_x(2)*O.n(1))>x(:,1) & x(:,1)>(stim_x(1)*O.n(1))) .* ...
    ((stim_t(2)*1000)> t & t > (stim_t(1)*1000)) .* ...
    Ic; % x: position, t: ms, current unit: pA
end

%% Enable STDP
function O = enable_STDP(O, p)

% Change STDP flags if deisred
if p.flag_realtime_STDP
    O.Proj.In(1).STDP.Enabled = 1;
    KernelToMultiplication(O.Proj.In(1));
    O.Proj.In(1).STDP.tau_LTD = O.Proj.In(1).STDP.tau_LTD./O.param.time_compression;
    O.Proj.In(1).STDP.tau_LTP = O.Proj.In(1).STDP.tau_LTP./O.param.time_compression;
    
    % Scale STDP strength (default is 1)
    O.Proj.In(1).STDP.dLTD = O.Proj.In(1).STDP.dLTD.*p.STDP_scale;
    O.Proj.In(1).STDP.dLTP = O.Proj.In(1).STDP.dLTP.*p.STDP_scale;
end

end

%% Adjust Weight Matrix
function O = adjust_weight_matrix(O, p)

%%% Default p.dW_matrix is empty; update weights if non-empty
if ~isempty(p.dW_matrix)
    % Change to sparse matrix notation instead of convolution
    KernelToMultiplication(O.Proj.In(1));
    % Update weight matrix
    O.Proj.In(1).W = O.Proj.In(1).W.*p.dW_matrix;
end

end

%% Parsave
function parsave(fname,d)
 disp(['Saving ' fname])
 save(fname, 'd', '-v7.3')
end

%% File Handling - utility suite to handle save directories
% Isserver
function server = isserver()
    server = strcmp(computer,'GLNXA64'); % if server
end

% Vardir - directory where variables are saved
function str = vardir()
    if isserver
       str = '~/';
    else
        str = '~/Desktop/';
    end
end

% Expdir - directory for this particular experiment
function str = expdir()
    st = dbstack;
    str = {st.name};
    str = [str{end} '/'];
end

% Fullpath - path to actual save directory
function str = fullpath(p)
    str = [p.vardir p.expdir];
end

%% Wavelet detector
function [seizure,detector_metrics] = wavelet_detector(O,p)

% Stimulated neurons (sn)
st_neu = find(1:prod(O.n)>prod(O.n).*p.stim_location(1) & 1:prod(O.n)<prod(O.n).*p.stim_location(2));

% Extract voltage traces from neighbors
% V = O.Recorder.Var.V(neighbors,1:O.t);
V = O.Recorder.Var.V(setdiff(1:prod(O.n),st_neu),1:O.t);

% Extract g_K and Cl_in from all non-stimulated neurons
g_K = O.Recorder.Var.g_K(setdiff(1:prod(O.n),st_neu),1:O.t);
Cl_in = O.Recorder.Var.Cl_in(setdiff(1:prod(O.n),st_neu),1:O.t);

% Kernel for Gaussian convoluation
g = normpdf(-4:6/1000:4,0,1); % gaussian for filtering
g = g./sum(g); % normalize AUC

% Compute tonic wavefront
tonic = zscore(Cl_in,[],'all') - zscore(g_K,[],'all');
tonic = imgaussfilt(tonic,10); % Gaussian blur for smoothing
tonic_baseline = tonic(:,1:2000);
tonic_baseline_mean = mean(tonic_baseline(:));
tonic_baseline_std = std(tonic_baseline(:));
z = @(x,m,sd) (x-m)./sd;
tonic = z(tonic,tonic_baseline_mean,tonic_baseline_std);

% Time course of alpha power
a = [];
for n = 1:size(V,1)
   [wt,f] = cwt(V(n,:),1000./p.dt); 
   a = [a; abs(mean(wt(f>5&f<15,:),1))];
   % s = zscore(real(wt(f>300,:)),[],2)>1; % spike train
   % fr = [fr; mean(cell2mat(cellfun(@(ss)conv(ss,g,'same'),num2cell(s,2),'UniformOutput',false)))]; % firing rate
end

% Find clonic core
clonic = conv2(lowpass(a,0.05),g,'same');
clonic_baseline = clonic(:,1:2000);
clonic_baseline_mean = mean(clonic_baseline(:));
clonic_baseline_std = std(clonic_baseline(:));
clonic = z(clonic,clonic_baseline_mean,clonic_baseline_std);

% Cutoff to define tonic/clonic
cutoff_tonic = 30; % in SD
cutoff_clonic = 20;

% Embedded code to see scoring
[~,order] = sort([setdiff(1:prod(O.n),st_neu),st_neu]);
state_trace = (tonic>cutoff_tonic)+2*(clonic>cutoff_clonic);
state_trace = [state_trace; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
state_trace = state_trace(order,:); % reorder with placeholders for st_neu

% Actual seizure detection
d_tonic = sum(tonic>cutoff_tonic)>1;
d_clonic = sum(clonic>cutoff_clonic)>1;
states = d_tonic + d_clonic; % 0 is null state, 1 is tonic wave, 2 is both tonic and clonic

% Find state transitions
no_unexpected_states = all(ismember(states,0:2)); % Make sure all states in state vector are in 0:2
all_states = ((all(ismember(0:2,states)))); % Make sure all states are included
first_two_transitions = find(diff(states)~=0,2,'first');

% Ensure correct ordering of first two transitions
correct_order = 0; % automatic failure if no more than one transition detected
if numel(first_two_transitions) == 2
    correct_order = all(states(1:first_two_transitions(1))==0) & ...
        all(states(first_two_transitions(1)+1:first_two_transitions(2))==1) & ...
        states(first_two_transitions(2)+1) == 2;
end

% Ensure coexistence of states
coexistence = any(states == 2);

% Ensure clonic phase lasts for at least some duration of time
clonic_duration = 0.3e3; % 1e3 for at least one second of clonic activity
appropriate_clonic_duration = sum(d_clonic)>clonic_duration;

% Detect seizure
seizure = 0; % Default
if all_states && no_unexpected_states && correct_order && ...
        coexistence && appropriate_clonic_duration
    seizure = 1;
end

% Port up metrics
detector_metrics.states = states;
detector_metrics.wave_collapsed = sum(states>0)>0 & all(states(end-100:end)==0);

if p.flag_return_state_trace
   detector_metrics.state_trace = state_trace; 
end

%% Plotting scripts if needed
% Plotting scripts to show effectiveness of detector on a real world
% example (included to generate plots as needed, but default off)
if 0
    
    % Plot seizure    
    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),O.Recorder.Var.V(:,1:O.t))
    title(['Model seizure (t = ' num2str(p.stim_duration) 's)'])
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'Voltage (mV)';
    a.FontSize = 18;
    figname = 'modelseizure';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Extract voltage traces from neighbors
    % V = O.Recorder.Var.V(neighbors,1:O.t);
    V = O.Recorder.Var.V(setdiff(1:prod(O.n),st_neu),1:O.t);
    
    % Extract g_K and Cl_in from all non-stimulated neurons
    g_K = O.Recorder.Var.g_K(setdiff(1:prod(O.n),st_neu),1:O.t);
    Cl_in = O.Recorder.Var.Cl_in(setdiff(1:prod(O.n),st_neu),1:O.t);
    
    % Kernel for Gaussian convoluation
    g = normpdf(-4:6/1000:4,0,1); % gaussian for filtering
    g = g./sum(g); % normalize AUC
    
    % Compute tonic wavefront
    tonic = zscore(Cl_in,[],'all') - zscore(g_K,[],'all');

    % Plot tonic wavefront (reorder first)
    [~,order] = sort([setdiff(1:prod(O.n),st_neu),st_neu]); % reorder rows
    x = [tonic; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
    x = x(order,:); % reorder with placeholders for st_neu

    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x)
    title('z(Cl_{in}) - z(g_K)')
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'z-score (au)'
    a.FontSize = 18;
    figname = 'tonic-1';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Continue with detector generation
    tonic = imgaussfilt(tonic,10); % Gaussian blur for smoothing
    tonic_baseline = tonic(:,1:2000);
    tonic_baseline_mean = mean(tonic_baseline(:));
    tonic_baseline_std = std(tonic_baseline(:));
    z = @(x,m,sd) (x-m)./sd;
    tonic = z(tonic,tonic_baseline_mean,tonic_baseline_std);
    
    % Plot tonic wavefront (reorder first)
    [~,order] = sort([setdiff(1:prod(O.n),st_neu),st_neu]); % reorder rows
    x = [tonic; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
    x = x(order,:); % reorder with placeholders for st_neu

    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x)
    title('z(Cl_{in}) - z(g_K), smoothed and normalized')
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'z-score (au)'
    a.FontSize = 18;
    figname = 'tonic-2';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Continue with detector generation
    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x>cutoff_tonic)
    title(['z(Cl_{in}) - z(g_K), thresholded at \sigma = ' num2str(cutoff_tonic)])
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'State (binary)'
    a.FontSize = 18;
    figname = 'tonic-3';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Compute clonic wavefront
    % Time course of alpha power
    ab = [];
    for n = 1:size(V,1)
        [wt,f] = cwt(V(n,:),1000./p.dt);
        ab = [ab; abs(mean(wt(f>5&f<15,:),1))];
        % s = zscore(real(wt(f>300,:)),[],2)>1; % spike train
        % fr = [fr; mean(cell2mat(cellfun(@(ss)conv(ss,g,'same'),num2cell(s,2),'UniformOutput',false)))]; % firing rate
    end
    
    % Plot clonic core (reorder first)
    x = [ab; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
    x = x(order,:); % reorder with placeholders for st_neu
    
    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x)
    title('Average oscillatory power (5-15 Hz)')
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'Power (au)';
    figname = 'clonic-1';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Smooth clonic core, normalize
    clonic = conv2(lowpass(ab,0.05),g,'same');
    clonic_baseline = clonic(:,1:2000);
    clonic_baseline_mean = mean(clonic_baseline(:));
    clonic_baseline_std = std(clonic_baseline(:));
    clonic = z(clonic,clonic_baseline_mean,clonic_baseline_std);

    % Plot clonic core (reorder first)
    x = [clonic; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
    x = x(order,:); % reorder with placeholders for st_neu

    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x)
    title('Average oscillatory power (5-15 Hz), smoothed and normalized')
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'z-score (au)';
    figname = 'clonic-2';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Continue with detector generation
    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),x>cutoff_clonic)
    title(['Power (5-15 Hz), thresholded at \sigma = ' num2str(cutoff_clonic)])
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'State (binary)';
    figname = 'clonic-3';
    saveas(f,['~/Desktop/' figname '.svg'])
    
    % Construct state trace
    state_trace = (tonic>cutoff_tonic)+2*(clonic>cutoff_clonic);
    state_trace = [state_trace; zeros(numel(st_neu),size(V,2))]; % Add stimulated neurons for visualization
    state_trace = state_trace(order,:); % reorder with placeholders for st_neu
    
    f = figure();
    a = gca();
    imagesc([1:O.t]./1000,1:prod(O.n),state_trace)
    title('State trace')
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'State (categorical)';
    figname = 'state';
    saveas(f,['~/Desktop/' figname '.svg'])
    
end

end
