function spike_matrix = buffer2_cell(O)
% Computes spiking matrix for SpikingModel
% Input: O - SpikingModel with Recorder called O.Recorder; O.Recorder
%            should have field O.Recorder.Sbuffer with index of spiking
%            neuron at each time step
%
% Output: spike_matrix, an O.n x O.t matrix with boolean spiking values
%
% Author: Tommy Wilson
% Final update: 2021/07/19 

%% Assertions
% Assert only one SpikingNetwork and one Recorder
assert(numel(O)==1,'Failed assertion: buffer2_cell was not written for more than one SpikingModel at a time')
assert(numel(O.Recorder)==1,'Failed assertion: buffer2_cell was not written for more than one O.Recorder at a time')

% Assert appropriate classes: SpikingModel and Recorder
assert(isa(O,'SpikingModel'),'Failed assertion: Input O is not of class SpikingModel')
assert(isa(O.Recorder,'Recorder'), 'Failed assertion: Recorder for input O is not found or not of class Recorder')

% Assert existence of field SBuffer
assert(...
    sum(cellfun(@(s)strcmp(s,'SBuffer'),fieldnames(O.Recorder)))==1,...
    'Failed assertion: SBuffer field for O.Recorder is not found')

% Assert O is arranged in a line; this function has not been extended for
% other cases
assert(sum(O.n~=1)==1,'Failed assertion: buffer2_cell is not designed for network topologies other than a line')

%% Create spike_matrix

% Convert SBuffer cells into linear index array
%   Note: this is only designed for line topology
spike_indices = find_spike_indices(O.Recorder.SBuffer(1:O.t));
    
% Create dummy spike_matrix
spike_matrix = false(prod(O.n),O.t);

% Fill in spikes
spike_matrix(spike_indices)=true;

%% Subfunctions

function spike_indices = find_spike_indices(SBuffer)
% Subfunction that finds spike indices at returns them in matrix array

    % Compute adjustment to convert to linear indices
    index_adjustment = num2cell(((1:O.t)-1).*prod(O.n)+1);
    
    % Compute linear indices
    spike_indices = cellfun(@(s,i) s+i, SBuffer, index_adjustment, 'UniformOutput', false);

    % Concatenate linear indices into matrix
    spike_indices = cell2mat(spike_indices.');
    
end

end

