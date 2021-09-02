function [ P_E, P_I1, P_I2 ] = StandardRecurrentConnection_flex( O, varargin )
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
p = inputParser;
addParameter(p,'Adjust',false);
parse(p,varargin{:});
Adj = p.Results.Adjust;

% Scale parameter for width of Gaussians
scale = 1;
adjust = 1.20;
synaptic_inhibition = adjust*245;
global_inhibition = 4*50;
synaptic_excitation = adjust * 120;
hat_scale = 1.2;

% Build recurrent excitation & configure it
P_E = Projection(O,O,'Type','E','Topology','linear');
% Change sigma calculation here as was going to be 2% regardless of line
% size
% Sigma_E = scale.*diag(O.n) * 0.02 .* diag([2000./2400 1]); % percentage of the field 
Sigma_E = diag(O.n) * 0.02 * hat_scale; % percentage of the field 
Kernelize(P_E, @(x) mvnpdf(x,[0 0],Sigma_E.^2), 'KerSize', ceil(2.5*diag(Sigma_E)));
if Adj;AdjustWeight(P_E);end % Adjust strength at space border; 
P_E.WPost = P_E.WPost * synaptic_excitation; % Projection strength 

% Build recurrent inhibition & configure it
P_I1 = Projection(O,O,'Type','I','Topology','linear');
% Change sigma calculation here as was going to be 2% regardless of line
% size
% Sigma_I = scale.*diag(O.n) * 0.03 .* diag([2000./2400 1]); % percentage of the field  
Sigma_I = diag(O.n) * 0.03 * hat_scale; % percentage of the field  
Kernelize(P_I1, @(x) mvnpdf(x,[0 0],Sigma_I.^2), 'KerSize', ceil(2.5*diag(Sigma_I)));
if Adj;AdjustWeight(P_I1);end % Adjust strength at space border; 
P_I1.WPost = P_I1.WPost * synaptic_inhibition; % Projection strength

% Build the global recurrent inhibition & configure it
P_I2 = Projection(O,O,'Type','I_global','Method','function');
% Scale uniform distribution to keep same parameters (although area under
% curve will no longer be 1... (maybe scale WPost instead??)
% P_I2.W = @(x) scale.*sum(x(:))/(prod(O.n).*prod([2000./2400 1])); % uniform distribution
P_I2.W = @(x) scale.*sum(x(:))/prod(O.n); % uniform distribution
if Adj;AdjustWeight(P_I2);end % Adjust strength at space border; 
P_I2.WPost = P_I2.WPost * global_inhibition; % Projection strength

end

