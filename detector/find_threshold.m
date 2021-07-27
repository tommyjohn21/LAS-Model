%%% Find threshold of original model by brute force %%%

stim_durations = fliplr(0:0.01:3); % start with stronger stims for fast detectio
n_sims = 100;

parfor i = 1:numel(stim_durations)
   
    d = detector_Exp1(n_sims,stim_durations(i),20);
    parsave(['~/detector/stim_dur_' num2str(stim_durations(i)) '.mat'],d)
    
end
