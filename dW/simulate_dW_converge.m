%% Use Exp5STDP.m script to generate 100 simulations of weight matrix

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
