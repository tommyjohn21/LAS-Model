%% Use Exp5STDP.m script to generate 100 simulations of weight matrix

if 0
    savedir = '~/dW_converge';
    vardir = '~/dW';
    sim = 5;
    nseizures = 20;
    
    for s = 1:sim
        for i = 1:nseizures
            
            % Annouce entry
            disp(['Beginning seizure ' num2str(i) ' for dW ' num2str(s) '...'])
            
            % Generate and retrieve weight matrices
            o = Exp5STDP_converge(i,savedir,s);
            
            % Save output in parallel fashion
            parsave([savedir '/dW_' num2str(s) '_converge_sim_' num2str(i) '.mat'],o)
            
        end
    end
end

%% Investigate seizures due to different weight matrices
vardir = '~/Desktop/dW_converge/';
sim = 1:5;

for s = sim
    
    load([vardir 'dW_' num2str(s) '_converge_sim_1.mat'])
    
    % Plot initial seizure
    f = figure();
    imagesc(0:0.001:50,1:2000,o.V);
    a = gca;
    a.XLabel.String = 'Time (s)';
    a.YLabel.String = 'Neuron index';
    a.Title.String = ['Seizure simulation ' num2str(s) ' (t_{stim}=1.5s)'];
    % a.Title.String = 'Model seizure t_{stim}=3s';
    c = colorbar;
    if s == 1
        clim = c.Limits;
    else
        caxis(clim);
    end
    c.Label.String = 'Voltage (mV)';
    a.FontSize = 18;
    figname = ['seizure_sim_' num2str(s)];
    saveas(f,['~/Desktop/' figname '.svg'])
    close(f)
    
    % Plot original dW matrix
    f = figure();
    imagesc(1:2000,1:2000,o.dW);
    a = gca;
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.Title.String = ['dW simulation ' num2str(s) ' (t_{stim}=1.5s)'];
    % a.Title.String = 'Model seizure t_{stim}=3s';
    c = colorbar;
    if s == 1
        dWclim = c.Limits;
    else
        caxis(dWclim);
    end
    c.Label.String = 'Arbitrary units';
    a.FontSize = 18;
    figname = ['dW_sim_' num2str(s)];
    saveas(f,['~/Desktop/' figname '.svg'])
    close(f)
    
    load([vardir 'dW_' num2str(s) '_converge_sim_2.mat'])
    
    % Plot 2nd seizure
    f = figure();
    imagesc(0:0.001:50,1:2000,o.V);
    a = gca;
    a.XLabel.String = 'Time (s)';
    a.YLabel.String = 'Neuron index';
    a.Title.String = ['Seizure simulation ' num2str(s) ' after STDP (t_{stim}=1.5s)'];
    % a.Title.String = 'Model seizure t_{stim}=3s';
    c = colorbar;
    caxis(clim);
    c.Label.String = 'Voltage (mV)';
    a.FontSize = 18;
    figname = ['seizure_sim_' num2str(s) '_after_STDP'];
    saveas(f,['~/Desktop/' figname '.svg'])
    close(f)
    
    % Plot 2nd dW matrix
    f = figure();
    imagesc(1:2000,1:2000,o.dW);
    a = gca;
    a.XLabel.String = 'Neuron index';
    a.YLabel.String = 'Neuron index';
    a.Title.String = ['dW simulation ' num2str(s) ' after STDP (t_{stim}=1.5s)'];
    % a.Title.String = 'Model seizure t_{stim}=3s';
    c = colorbar;
    caxis(dWclim);
    c.Label.String = 'Arbitrary units';
    a.FontSize = 18;
    figname = ['dW_sim_' num2str(s) '_after_STDP'];
    saveas(f,['~/Desktop/' figname '.svg'])
    close(f)
    
end


%%% The code below was written to examine convergence of weight matrices
%%% with repeated stimulation; however, pbased on the code above, the
%%% entirety of seizure events was not captured in the 50s in which the
%%% system was stimulated on stimulation number 2. In that case, the dW
%%% matrix generaged by the second stimulation is not accurate (since the
%%% entire event isn't captured). Need to redo with a larger time scale and
%%% larger set of neurons. 

%%% In other words, if the dW matrices do not reflect the actual totality
%%% of stimulation effects in the model, whether or not they converge is
%%% irrelevant

%% Load W matrices and see if they converge
vardir = '~/Desktop/dW_converge_concat/';
sim = 1:5; % go in descending order (built for looping as below)

if 0
    ij = []; % index matrix
    F = [];
    for s = sim
        
        % Load data for trial s
        load([vardir 'dW_' num2str(s) '_converge_concat_W.mat'])
        W1 = W;
        
        for t = s+1:max(sim)
            
            % Load matrix for comparison
            load([vardir 'dW_' num2str(t) '_converge_concat_W.mat'])
            W2 = W;
            
            % Subtract matrices and compute 2-norm for each stimulation each
            % stimulation
            F = [F sqrt(squeeze(sum(sum((W2-W1).^2,1),2)))]; % 2-norm (i.e. Frobenius)
            ij = [ij, [s; t]]; % retain indices
            
        end
        
    end
end

% Plot F
f = figure();
p = plot(0:19,F);
hold on
h = plot([0 19], [100 100],'Color',[1,1,1]);
h.DisplayName = '...and so forth';
a = gca;
a.XLabel.String = 'Stimulation number';
a.YLabel.String = 'Distance (arbitrary units)';
a.YLim = [0 35];
a.Title.String = '2-norm between W matrices (t_{stim}=1.5s)';
a.FontSize = 18;
figname = 'frobenius_across_sims';
l = legend({'Sim 1 vs. Sim 2', 'Sim 1 vs. Sim 3', 'Sim 1 vs. Sim 4'},'Location', 'Northwest');
legend([p(1:3); h])
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% Plot W matrices for specific stimulations
vardir = '~/Desktop/dW_converge_concat/';
sim = 1:5; % go in descending order (built for looping as below)
stimulation = [1 2 10, 20];

if 1
    climits = [];
    for s = sim
        for si = stimulation
        
        % Load data for trial s
        load([vardir 'dW_' num2str(s) '_converge_concat_W.mat'])
        
        % Plot F
        f = figure();
        imagesc(1:2000,1:2000,W(:,:,si));
        a = gca;
        
        if s == 1
            a.YLabel.String = 'Neuron index';
        elseif s == sim(end)
            c = colorbar;
            c.Label.String = 'Connection weight (au)'
        end
        
        if si == stimulation(end)
            a.XLabel.String = 'Neuron index';
        end
        
        if s == 1
            climits = [climits; caxis]; 
        else 
            caxis(climits(find(stimulation==si),:))
        end
        
        a.Title.String = ['Simulation ' num2str(s) ', stimulation ' num2str(si)];
        
        a.FontSize = 18;
        figname = ['sim' num2str(s) 'stim' num2str(si)];
        
        saveas(f,['~/Desktop/' figname '.svg'])
%         close(f)
        
        end
    end
end

%% Look for within-simulation convergence
vardir = '~/Desktop/dW_converge_concat/';
sim = 1:5;

if 1
    for s = sim
        
        % Load data for trial s
        load([vardir 'dW_' num2str(s) '_converge_concat_W.mat'])
        
        % Normalize by matrix power
        W_n=bsxfun(@rdivide,W,sqrt(sum(sum(W.^2))));
        
        % Magnitude of difference vector
        d = sqrt(squeeze(sum(sum(diff(W_n,[],3).^2))));
        
        plot(d)
        hold on
        
    end
end

