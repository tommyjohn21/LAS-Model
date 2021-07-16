function Project(P)
% Project(P)
%
% Project the information saved in P.Value (effective 
% pre-synaptic # of spikes), calculate its projection
% (Method, Topology, WPre, W), and save the projection results 
% to P.Target.Input.Type according to to the Projection.Type
% 
% This function is called by @NeuralNetwork.Project
%
% Jyun-you Liou 2017/05/04

%% Projection
for i = 1:numel(P)
    
    % tw: P(i).Value contains the boolean spiking values for the current
    % time step for the SpikingNetwork and the (fractional) number of spikes
    % for the RateNetwork
    
    % Strength of each pre-synaptic neuron Presumably, this is to make a
    % spiking event in one (or many) neuron(s) stronger than the others; as
    % it stands, each spiking event is given a total "power" of 1, although
    % you could change this with P.WPre (unclear whether you would have to
    % normalize this across the neuron population)
    if ~isempty(P.WPre) && any(P.WPre(:) ~= 1)                 
        % tw: unclear whether you need to normalize P.WPre across the
        % neuron population; may need to look into it before just running
        % this code below
        keyboard
        P(i).Value = P(i).WPre .* P(i).Value; 
    end
    
    % Projection, according it how synaptic projection is
    % distributed, use the correspondent method
    switch lower(P(i).Method)
        case 'convolution'
            % tw: raw number of spikes convolved with Gaussian
            P(i).Value = conv2_field(P(i).Value, ...
                                     P(i).W, ...
                                     P(i).Target.n, ...
                                     P(i).Topology);
        case 'multiplication'
            P(i).Value = P(i).W * P(i).Value(:); 
            P(i).Value = reshape(P(i).Value,P(i).Target.n);
        case 'function'
            P(i).Value = P(i).W(P(i).Value);
    end
    
    % tw: in the case of the SpikingNetwork, P(i).Value now contains the
    % percentage of possible pre-synaptic input; in the case of the
    % RateNework, it seems to contain f_max * percentage of possible input
    
    % Strength of each post-synaptic receptors                
    if ~isempty(P.WPost) && any(P.WPost(:) ~= 1)
        % tw: scale neural output by conductance (WPost)
        P(i).Value = P(i).Value .* P.WPost;
    end
    
    % tw: in the case of the SpikingNetwork, P(i).Value now contains the
    % total presynaptic conductace (in nS); in the case of the
    % RateNework, it seems to contain f_max * total presynaptic
    % conductace (in nS)
    
end

end