%%% Find threshold of original model by brute force %%%

stim_durations = fliplr(0:0.01:3); % start with stronger stims for fast detection
n_sims = 100;
sim=randi(100,1,5); % Choose 5 of your STDP matrices to find the threshold
vardir='~/dW';
savedir='~/detector_stdp';

parfor s = 1:numel(sim) % Cycle through STDP matrices
    for i = 1:numel(stim_durations)
        
        d = detector_Exp1_STDP(n_sims,stim_durations(i),50,vardir,sim(s));
        parsave([savedir '/stdp_' num2str(sim(s)) '_stim_dur_' num2str(stim_durations(i)) '.mat'],d)
        
    end
end
