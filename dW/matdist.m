function [o] = matdist(dW1,dW2)
%MATDIST measures the matrix norm between matrices, randomized versions of
%themselves and randomized versions of eachother

% Frobenius norm of the difference between matrices
o.dist = norm(dW1-dW2);

% Randomly permute both matrices
rW1 = reshape(randperm(numel(dW1)),size(dW1));
rW2 = reshape(randperm(numel(dW2)),size(dW2));

% Compute distance between shuffled matrices
o.randdist = norm(rW1-rW2);

end

