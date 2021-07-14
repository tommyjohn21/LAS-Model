%% STDP precipitate the next seizure and cause herald spikes
%
% Final update: Jyun-you Liou, 2017/04/29
if ~exist('n_trial','var')
    n_trial = 1;
    % tw: not sure exactly what this variable represents
end

%% Lay out the model and build recurrent connection
if n_trial == 1 % If it is the first seizure
    % Lay out the field 
    
    % tw: initializes an n-neuron model with 1. neuron number and model
    % parameters inherited from SpikingModel1DStandard and Exp5Template; 2.
    % dynamical variables from the same sources; 3. a container named O.S
    % to track spiking; and 4. a container named O.Input to track
    % excitatory/inhibitory input to each neuron
    O = SpikingModel('Exp5TemplateSTP');
    
    % Build recurrent connection
    % tw: WPost appears to be conductance of excitatory/inhibitory
    % channels, respectively (P_I1.WPost + P_I2.WPost = g_I); W appears to
    % be related to the actual distribution (can hold explicit
    % convolutional values or an actual function)
    [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection( O );
end

%% External input
if n_trial == 1 
    Ic = 200; % tw: stim strength in pA
    stim_x = [0.475 0.525]; % tw: where on the line you are stimulating
    % tw: length of time to stimulate
    stim_t = [2 5]; % Unit: second
    O.Ext = ExternalInput;
    O.Ext.Target = O;
    % tw: this is clearly a way to create an anonymous function to
    % stimulation within the parameters above (stim_x/stim_t), but I'm not
    % sure why it's coded in this manner
    O.Ext.Deterministic = @(x,t) ((stim_x(2)*O.n(1))>x(:,1) & x(:,1)>(stim_x(1)*O.n(1))) .* ...
                                  ((stim_t(2)*1000)> t & t > (stim_t(1)*1000)) .* ...
                                  Ic; % x: position, t: ms, current unit: pA      
else
    keyboard % tw: have not scoped this loop; including keyboard 7/8/21
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
    % tw: recorder capacity is by def the end of the simulation
    R = CreateRecorder(O,50000); % The 2nd argument is Recorder.Capacity 
    T_end = R.Capacity - 1; % simulation end time.  
    AddVar(R,'EPSC');
    AddVar(R,'IPSC'); % To simulate LFP, you need to record PSCs.
end

%% Realtime plot setting
% tw: this is for seeing plot in real time (I have turned off for now
% 7/9/21)
flag_realtime_plot = 0; % whether you want to see simulation result real time or not
% tw: presumably the simulation runs until T_end, but the plot only
% refreshes every 1000 steps
T_plot_cycle = 1000; % How often updating the figures
if flag_realtime_plot 
    % tw: AttachHotKey contains definitions for how the actual GUI can be
    % used (not sure this matters so much to me) but it's nice that it's
    % there
    AttachHotKey(O);
    f = plot(O);drawnow;        
    % tw: just sets scaling limits for each of the axes
    ylim(f.Children(1),[-80 0]); % V
    ylim(f.Children(2),[-80 0]); % phi
    ylim(f.Children(3),[0 40]); % Cl_in
    ylim(f.Children(4),[0 mean(O.param.g_K_max .*O.param.f_max)]); % g_K
    ylabel(f.Children(4),['X ' num2str(1/mean(O.param.f_max(:)))]);
    % tw: x-axis in these images is neuron number (this is, I suppose, the
    % benefit of having them in a linear array (as opposed to order-2 or
    % greater tensor)
    set(f.Children,'YLimMode','manual','XLim',[0 max(O.n)]);        
end

while 1 
    
    % Termination criteria tw: q is the hotkey for termination of
    % simulation tw: added flag_realtime_plot flag; otherwise logical break
    % on O.Graph.UserData.Active if no graph is created when
    % flag_realtime_plot = 0
    if (flag_realtime_plot && ~O.Graph.UserData.Active) || O.t >= T_end
        break;
    end        
    
    WriteToRecorder(O); 
    Update(O,dt);
    
    % Real time plotting
    % use mod < dt instead of == 0 can deal with floating number errors
    if mod(O.t,T_plot_cycle) < dt && flag_realtime_plot 
        f=plot(O);drawnow
    end   

end