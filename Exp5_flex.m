%% STDP precipitate the next seizure and cause herald spikes
%
% Final update: Jyun-you Liou, 2017/04/29
if ~exist('n_trial','var')
    n_trial = 1;
end

%% Set random number generator
% rng default

%% Lay out the model and build recurrent connection
if n_trial == 1 % If it is the first seizure
    % Lay out the field
    O = SpikingModel_flex('Exp5Template_flex');
    % Build recurrent connection
    [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection_flex( O );
end

%% External input
if n_trial == 1 
    Ic = 200;
    stim_x = [0.475 0.525];
%     stim_x = [0 0.05];
%     stim_x = [0.1 0.15]; % normalized spatial unit
    
    % If initial model was 2000 units, 5% is 100 neurons; let us stimulate
    % the same number of neurons here
%     stim_x = [0 0.05].*O.param.grain;
    
    stim_t = [2 5]; % Unit: second
    O.Ext = ExternalInput;
    O.Ext.Target = O;       
    O.Ext.Deterministic = @(x,t) ((stim_x(2)*O.n(1))>x(:,1) & x(:,1)>(stim_x(1)*O.n(1))) .* ...
                                  ((stim_t(2)*1000)> t & t > (stim_t(1)*1000)) .* ...
                                  Ic; % x: position, t: ms, current unit: pA
else
    delete(O.Ext);
    O.Ext = ExternalInput;
    O.Ext.Target = O;
    O.Ext.Random.sigma = 10; % unit: pA
    O.Ext.Random.tau_x = 200; % spatial constant unit: neuron index
    O.Ext.Random.tau_t = 15; % time unit: ms
end

%% Simulation settings 
dt = 1; % ms
if n_trial == 1
    R = CreateRecorder(O,20000); % The 2nd argument is Recorder.Capacity 
    T_end = R.Capacity - 1; % simulation end time.  
    AddVar(R,'EPSC');
    AddVar(R,'IPSC'); % To simulate LFP, you need to record PSCs.
%     AddVar(R,'global_inhibition')
%     AddVar(R,'inhibitory_current')
%     AddVar(R,'excitatory_current')
end

%% Realtime plot setting
flag_realtime_plot = 0; % whether you want to see simulation result real time or not
T_plot_cycle = 1000; % How often updating the figures
if flag_realtime_plot 
    AttachHotKey(O);
    f = plot(O);drawnow;        
    ylim(f.Children(1),[-80 0]); % V
    ylim(f.Children(2),[-80 0]); % phi
    ylim(f.Children(3),[0 40]); % Cl_in
    ylim(f.Children(4),[0 mean(O.param.g_K_max .*O.param.f_max)]); % g_K
    ylabel(f.Children(4),['X ' num2str(1/mean(O.param.f_max(:)))]);
    set(f.Children,'YLimMode','manual','XLim',[0 max(O.n)]);        
end

while 1 
    
    % Termination criteria 
    if flag_realtime_plot && ~O.Graph.UserData.Active || O.t >= T_end
        break;
    end        
    
    WriteToRecorder(O); 
    Update(O,dt);
    
    if mod(O.t,10000)==0
%         keyboard
    end
    
    % Real time plotting
    % use mod < dt instead of == 0 can deal with floating number errors
    if mod(O.t,T_plot_cycle) < dt && flag_realtime_plot 
        f=plot(O);drawnow
    end

end