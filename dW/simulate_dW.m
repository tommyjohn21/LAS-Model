%% Use Exp5STDP.m script to generate 100 simulations of weight matrix

fname = '~/dW/dW_sim_';

for i = 1:100
   
    % Generate and retrieve weight matrices
    o = Exp5STDP(i);
    
    % Save output in parallel fashion
    parsave([fname num2str(i) '.mat'])
    
end