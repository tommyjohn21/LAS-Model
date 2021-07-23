%%% Find threshold of original model by brute force %%%

stim_durations = fliplr(0:0.05:2); % start with stronger stims for fast detection
n_sims = 40;

for i = 1:numel(stim_durations)
   
    d = detector_Exp1(n_sims,stim_durations(i),20);
    save(['~/detector/stim_dur_' num2str(0) '.mat'],'d')
    
end

%% Make graph
% p is a matrix gathered from simulations with size 1 x numel(stim_durations)
% above; it has in each element the probability of seizure
stim_durations = 0:0.05:2;

%% Voltage plot for 1 neuron (neuron 1000)
f = figure();
plot(stim_durations,p,'.','MarkerSize',14);
a = gca;
a.Title.String = 'Probability of seizure (n=40 simulations)';
a.XLabel.String = 'Stimulation duration (s, 0:0.05:2)';
a.YLabel.String = 'Probability';
a.FontSize = 18;
figname = 'pseizure'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)