function [timeseries,loadings,explained] = dimensionality_reduction(O,n)
%dimensionality_reduction takes in a neural network with recorder and
%dynamic variables given in O.VarName returns each dynamic variable
%projected on its first n principle components
%   Output: timeseries (number of variables in O.VarName x O.t matrix)

% Initialize output array
timeseries = NaN(numel(O.VarName),O.t.*n);
loadings = NaN(numel(O.VarName),prod(O.n).*n);
explained = NaN(numel(O.VarName),n);

% Cycle through dynamic variables
for i = 1:numel(O.VarName)
    
    % PCA decomposition
    [x,s,~,~,e] = pca(O.Recorder.Var.(O.VarName{i})(:,1:O.t),'NumComponents',n);
    
    % Take the first n components of PCA decomposition
    timeseries(i,:) = reshape(x,[O.t.*n 1]).';
    loadings(i,:) = reshape(s,[prod(O.n).*n 1]).';
    
    % Record variance explained
    explained(i,:) = (e(1:n)./100).';
    
end

% Reshape to have dim dynamic variable x time x no. of components
% Note: explained already comes with dynamic variable x no. of components;
% no need to reshape
timeseries = reshape(timeseries,[numel(O.VarName),O.t,n]);
loadings = reshape(loadings,[numel(O.VarName),prod(O.n),n]);

end

