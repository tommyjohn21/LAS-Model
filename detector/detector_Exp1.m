function output = detector_Exp1(n,stim_dur,t)
% Repear detector n times Exp1; run for t seconds; in each simulation,
% stimulate at 200 pA for stim_dur seconds

disp(['Stim duration ' num2str(stim_dur) 's'])

for i = 1:n
    
    disp(['Simulation ' num2str(i) ' of ' num2str(n)])
    
    %% STDP precipitate the next seizure and cause herald spikes
    %
    % Final update: Jyun-you Liou, 2017/04/29
    if ~exist('n_trial','var')
        n_trial = 1;
    end
    
    %% Lay out the model and build recurrent connection
    if n_trial == 1 % If it is the first seizure
        % Lay out the field
        O = SpikingModel('Exp5Template_edge');
        % Build recurrent connection
        [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection_edge( O );
    end
    
    %% External input
    if n_trial == 1
        Ic = 200;
        % stim_x = [0.475 0.525];
        stim_x = [0 0.05]; % Restrict domain of activation
        stim_t = [2 2+stim_dur]; % Unit: second
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
        R = CreateRecorder(O,75000); % The 2nd argument is Recorder.Capacity
        T_end = R.Capacity - 1; % simulation end time.
        AddVar(R,'EPSC');
        AddVar(R,'IPSC'); % To simulate LFP, you need to record PSCs.
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
        if (flag_realtime_plot && ~O.Graph.UserData.Active) || O.t >= T_end
            break;
        end
        
        WriteToRecorder(O);
        Update(O,dt);
        
        % Detect seizures
        if mod(O.t,3000)==0 && O.t>(stim_t(end)*1000) % no need to look until end of stim
            [seizure,dP,fdP] = detector(O,dt);
            if seizure, break, end
%             disp(['t = ' num2str(O.t/1000) 's; no seizure'])
            disp(['t = ' num2str(O.t/1000) 's'])
        elseif O.t>t*1000
            % determin if seizure
            [seizure,dP,fdP] = detector(O,dt);
            break
        end
        
        % Real time plotting
        % use mod < dt instead of == 0 can deal with floating number errors
        if mod(O.t,T_plot_cycle) < dt && flag_realtime_plot
            f=plot(O);drawnow
        end
        
    end
    
        %% Format output
%     output(i).V = O.Recorder.Var.V(:,1:O.t);
    output(i).dP = dP;
    output(i).fdP = fdP;
    output(i).seizure = seizure;
%     output.O = O;
    
    %% Clear workspace
    clearvars('-except','output','n','stim_dur','t')
      
end

end
