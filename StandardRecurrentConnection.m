function [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection( O, varargin )
% [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection( O, varargin )
%
% This is for building standard recurrent connection.  
%
% Input: O: needs to be a NeuralNetwork 
%        varargin:  'Adjust' - default: false
%                              If the simulation space has aperiodic
%                              boundary, cells at the boundary will have
%                              different maximal amount of synaptic inputs
%                              than other cells.  If you turn this on, it
%                              will address this problem by amplifying 
%                              their synaptic inputs.
%
% P_E: Spatially localized recurrent excitation 
% P_I1: Spatially localized recurrent inhibition
% P_I2: Non-localized recurrent inhibition
%
% PS: I don't want to put this function into NeuralNetwork folder because
% this function is just commonly called for this epilepsy study.
% 
% Jyun-you Liou, 2017/04/30

% tw: this appears to simply be a way to handle the 'Adjust' input; the
% parameter Adjust with default value False is added to the input; the
% value of the param is then taken from either varargin if supplied or the
% default
p = inputParser;
addParameter(p,'Adjust',false);
% tw: parse command creates a structure from inputs to the function
parse(p,varargin{:});
Adj = p.Results.Adjust;

% Build recurrent excitation & configure it
P_E = Projection(O,O,'Type','E','Topology','linear');
% tw: sigma reflects how far out in the field the projections go
Sigma_E = diag(O.n) * 0.02; % percentage of the field 
% tw: you can call class methods with Method(instance, other args) or
% instance.Method(args); 2.5 on ceil below demonstrates +/- 2.5 SD to
% compute size of entire kernel
Kernelize(P_E, @(x) mvnpdf(x,[0 0],Sigma_E.^2), 'KerSize', ceil(2.5*diag(Sigma_E)));
% tw: again calling the method AdjustWeight in class Projection
if Adj;AdjustWeight(P_E);end % Adjust strength at space border; 
P_E.WPost = P_E.WPost * 100; % Projection strength

% tw: so at this point, you have a Projection with a convolution kernel whose values sum to 1, a
% projection strength matrix (WPre) indexed by network sending projections,
% and a post-synaptic strength matrix indexed by network receiving
% projections; unclear how these pieces go together

% Build recurrent inhibition & configure it
P_I1 = Projection(O,O,'Type','I','Topology','linear');
% tw: default is that width of recurrent inhibition is larger than width of
% recurrent excitation (so to make the hat function)
Sigma_I = diag(O.n) * 0.03; % percentage of the field  
Kernelize(P_I1, @(x) mvnpdf(x,[0 0],Sigma_I.^2), 'KerSize', ceil(2.5*diag(Sigma_I)));
if Adj;AdjustWeight(P_I1);end % Adjust strength at space border; 
% tw: projection strength of recurrent inhibition is stronger than
% recurrent excitation; not that projection strength of PI1 + PI2 = total
% projection strenght of 300 *i.e. g_I in Table 2)
P_I1.WPost = P_I1.WPost * 250; % Projection strength

% Build the global recurrent inhibition & configure it
P_I2 = Projection(O,O,'Type','I','Method','function');
% tw: it's not clear to me why the weighting matrix should be written like
% this, but we'll have to play it out -- looks like the weight of the I2
% component is computed each round as the fraction of neurons firing times
% projection strength (i.e. the more neurons fire, the more quenched this
% situation becomes)
P_I2.W = @(x) sum(x(:))/prod(O.n); % uniform distribution
if Adj;AdjustWeight(P_I2);end % Adjust strength at space border; 
% tw: this is the 1/6 projection strength that is tonic background
% inhibition
P_I2.WPost = P_I2.WPost * 50; % Projection strength

end

