function Parse(E)
% Method to take results of PlasticityExperiment and perform rotation and
% PCA
%
% Workflow:
% 1. Generate Experiment object and plug in VarDir:
%       a. E = PlasticityExperiment(ExperimentName)
%       b. E.UpdateDir(VarDir);
% 2. Load Experiment results
%       a. Load(E)
% 3. Parse results
%       a. Parse(E)

% Return if already parsed
if E.parsed, return, end

% Ensure only the first projection has STDP Enabled
for i = 1:numel(E.S(1).O.Proj.In)
    if i == 1
        assert(all(arrayfun(@(x)x.O.Proj.In(i).STDP.Enabled,E.S)),'First projection does not have STDP Enabled');
    else
        assert(all(~arrayfun(@(x)x.O.Proj.In(i).STDP.Enabled,E.S)),'Projection other than the first has STDP Enabled');
    end
end

% Pull all STDP matrices for concatenation
W = arrayfun(@(x)x.O.Proj.In(1).STDP.W,E.S,'UniformOutput',false);

% Rotate and concatenate (i.e. employ symmetry embedded in model)
fprintf('(1/3) Concatenating STDP matrices...')
W = [W cellfun(@(w)rot90(w,2),W,'un',0)];
W = cat(3,W{:});
fprintf('done\n')

% Pull naive weight matrix
Wn = E.S(1).O.Proj.In(1).W;

% Shift to weights mean 0, include only those weights that are used in update 
A = full(Wn).*(W-1); 
B = reshape(A,[size(A,1).*size(A,2) size(A,3)]); % Reshape to columns

% Perform PCA on variance-normalized data
fprintf('(2/3) Performing PCA...')
[c,s,l]=pca(B);
fprintf('done\n')

% Save dWave and PCA to Experiment object
fprintf('(3/3) Saving output...')
E.dWave = mean(W,3);
E.pca.c = c;
E.pca.s = reshape(s,size(W));
E.pca.l = l;
fprintf('done\n')

% Tag data as parsed
E.parsed = true;

end
