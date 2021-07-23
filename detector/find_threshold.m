%%% Find threshold of original model by brute force %%%

stim_durations = fliplr(0:0.05:2); % start with stronger stims for fast detection
n_sims = 40;

for i = 1:numel(stim_durations)
   
    d = detector_Exp1(n_sims,stim_durations(i),20);
    save(['~/detector/stim_dur_' num2str(0) '.mat'],'d')
    
end