
%%% Access local functions %%%

function Exp2_mini
    %%% Exp2_mini computes threshold of mini model by brute force but stimulates on edge %%%
    h = Exp1_mini; % Access local functions in Exp1_mini

    %%% Settings %%%
    stim_durations = fliplr(2:0.02:5); % start with stronger stims for fast detection
    n_sims = 50;
    location = [0 0.05];

    %%% Conditional parallel computation %%%
    if strcmp(computer,'GLNXA64') % if server
        parfor i = 1:numel(stim_durations)

            % Save dir
            savedir = '~/detector_Exp2_mini/';

            % Function as below
            d = h.simulate_mini_by_stim_dur(n_sims,stim_durations(i),location);
            parsave([savedir 'stim_dur_' num2str(stim_durations(i)) '.mat'],d)

        end
    else % local
        for i = 1:numel(stim_durations)

            % Save dir
            savedir = '~/Desktop/detector_Exp2_mini/';

            % Function as below
            d = h.simulate_mini_by_stim_dur(n_sims,stim_durations(i),location);
            parsave([savedir 'stim_dur_' num2str(stim_durations(i)) '.mat'],d)

        end
    end

end