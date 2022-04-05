%% Transfer Unit Test
% This test is designed to ensure that mappings between:
%
%   Exp_mini    =>  ThresholdExperiment/STDP
%   Exp22_mini  =>  PlasticityExperiment/naive
%
% are appropriate. Prerequisites are the above directories.

%% PlasticityExperiment Preliminaries
%%% Updated variable directory/name for PlasticityExperiment
PlasticityVarDir = 'PlasticityExperiment';
PlasticityExpName = 'naive';

%%% Create/update PlasticityExperiment container
PE = PlasticityExperiment(PlasticityExpName);
PE.UpdateDir(PlasticityVarDir);

%%% Load/Parse PlasticityExperiment
Load(PE)
Parse(PE)

%% Load STDP matrices from Exp22_mini
% Code cut from explore_threshold.m

% Load dW matrices, append rotated versions
f = dir('~/Desktop/Exp22_mini/');
D = [];
R = [];
for i = 1:numel(f)
    if any(strfind(f(i).name,'Wn')), load([f(i).folder '/' f(i).name]), continue, end
    if ~any(strfind(f(i).name,'.mat')), continue, end
    load([f(i).folder '/' f(i).name])
    assert(d.seizure==1)
    fprintf(['Loading ' f(i).folder '/' f(i).name '...\n'])
    D = cat(3,D,d.dW);
    R = cat(3,R,rot90(d.dW,2));
end
F = cat(3,D,R);

% Key to matrices as sorted in Exp_mini
%   e.g. Thresold to F(:,:,495) is found in Exp32_mini
%
% Note that key1 contains values >500, signifying a rotated matrix mod 500
key1 = [495 613 200 358 619 246 681 750 216 70  334 999 583 637 90  210 898 42  963 738 538 575 368 450 53  360 626 760 169 693 771 645 599 566 731 576 797 296 375 840 354 726 657 691 426 628 69  938 864 686 657 77  905 4   195 912 136 530 880 784 782 751 622 481 487 684 805 345 682 435 872 866 265 610 589 549 887 268 314 139 924 633 996 623 541 630 536 705 523 948 222 118 124 61  373 440 338 730 597 736 893; ...
        32  33  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99  100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140];

%% String ordering
% for F(:,:,1:500), filenames are given by idx(1:500); the same is true for
% F(:,:,501:1000), which are given by idx(1:500)
%
%   e.g. F(:,:,3) is loaded from file stim_dur_3_rep_100 (i.e. idx(3))

idx = cellfun(@(a) str2num(a),sort(cellfun(@(a)num2str(a),num2cell(1:500),'UniformOutput',false)).');
    
%% List of STDP matrices in PlasticityExperiment
%%% NOTE: key2 (below) is intended for use when ordered 1:500, as opposed
%%% to [1 10 100 101 102...99] (i.e. string ordering)

key2 = [ 4    32    53    95   130   146   166   186   208   218   250   270   288   306   332   365   404   426   440   480
        18    34    65    98   132   153   167   188   209   220   261   272   293   310   337   366   409   428   447   482
        20    43    81   101   135   158   168   198   211   221   262   274   299   312   342   373   417   433   452   490
        21    47    87   119   136   160   173   204   213   223   264   279   301   323   352   381   420   434   457   493
        24    51    94   125   142   161   179   205   215   229   266   283   305   324   354   402   422   436   463   495];

%% Mapping between F (Exp22_mini) and PlasticityExperiment (naive)
key1mod = [rem(key1(1,:),500); key1(2,:)]; % Cut key1 down to modulo 500 (ignore rotational component of F)
map = [key1(1,:); idx(key1mod(1,:))'; key1mod(2,:)]; % Convert from key1 nomenclature to key2 nomenclature

% Unfortunately, Exp82_mini and Exp90_mini both test F(:,:,657); we will
% remove this redundancy
[~,iu] = unique(map(1,:));
repel = setdiff(1:numel(map(1,:)),iu); % Find repeated element
mapu = map; % Generate local map copy
mapu(:,repel) = []; % Erase repeated element to create map unique

% So, each column of mapu is composed of [a; b; c], where
%   a: F(:,:,a)         index of dW matrix in F
%   b: PE.Retrieve(b)   index of (rotated) dW matrix in PE
%   c: Exp(c)_mini      index of stored threshold values for dW matrix
%
%   Note: b is also index to ThresholdExperiment for PE.Retrieve(b)
%     i.e. VarDir/ThresholdExperiment/STDP/PlasticityExperiment-naive-(b)/

%% Unit Test 1
% Make sure mapping from F to PE.Retrieve is appropriate
%   => Cycle through dW matrices and assure identity up to rotation

% Identity check container
id = zeros(1,size(mapu,2));

for i = 1:numel(mapu(1,:))
    
    % Check for raw/rot equality between F and PE.Retrieve
    raw = (F(:,:,mapu(1,i)) == PE.Retrieve(mapu(2,i)));
    rot = (F(:,:,mapu(1,i)) == rot90(PE.Retrieve(mapu(2,i)),2));
    
    % Condition for identify
    id(1,i) = (all(raw(:)) || all(rot(:))); % Either raw or rot must be true
    
end

% Unit Test 1
assert(all(id),'Failed Unit Test 1: Mapping between F and PE.Retrieve is not correct!')

%% Cut down mapu
% Having passed Unit Test 1, F indexing and PE.Retrieve indexing are
% redundant; shave these indices off of mapu to create reduced map
mapr = mapu(2:3,:); % map reduced

%% Unit Tests 2 and 3
% Compare ThresholdExperiment files to Exp_mini files

for i = 1:size(mapr,2)
    
    %%% Choose appropriate index
    n = mapr(1,i);
    
    %%% ThresholdExperiment preliminaries
    % Directories for saving
    VarDir = 'ThresholdExperiment/STDP'; % Updated variable directory for ThresholdExperiments
    
    % Directory for specific experiment
    ExpName = sprintf([PlasticityVarDir '-' PlasticityExpName '-%d'],n);
    
    % Generate container for ThresholdExperiment
    E = ThresholdExperiment(ExpName); % Create/update ThresholdExperiment
    E.UpdateDir(VarDir);
    
    % Load ThresholdExperiment
    Load(E)
    
    %%% Compare dW in PE.Retrieve to those stored in ThresholdExperiment E
    % Pull dW stored in PE.Retrieve
    dW1 = PE.Retrieve(n);
    
    % Find unique dW used in E
    %   Note: this step implicity confirms that each dW matrix in each E.S
    %   is identical; if there is an error, likely source is that one (or
    %   more) Simulations in E have different dW matrices (e.g.
    %   E.S(a).param.dW ~= E.S(b).param.dW for some a,b)
    dW2 = reshape(...
            cellfun(@(n)unique(n),...
                mat2cell(...
                    cell2mat(...
                        arrayfun(@(e)e.param.dW(:),E.S,'UniformOutput',false)...
                    ),...
                ones(1,numel(E.S(1).param.dW)),numel(E.S))...
            ),...
          size(E.S(1).param.dW));
        
    %%% Unit Test 2
    % Ensure identity up to rotation bewteen dW1 and dW2
    % If Unit Test 2 passed, can consider PE.Retrieve(n) to be appropriate
    % dW matrix for ThresholdExperiment in E
    raw = (dW1 == dW2);
    rot = (dW1 == rot90(dW2,2));
    assert(all(raw(:))||all(rot(:)),'dW1 and dW2 are not identical up to rotation')
    
    %%% Load Exp_mini threshold data associated with ThresholdExperiment E
    %%% and (therefore, by Unit Test 2) dW1
    % Code adapted from explore_threshold.m
    
    % Load appropriate Exp_mini
    fx = ['~/Desktop/Exp_mini/Exp' num2str(mapr(2,i)) '_mini/'];
    fx = dir(fx);
    [x,p] = deal([],[]); % Initialize output variables
    for j = 1:numel(fx)
        if ~any(strfind(fx(j).name,'.mat')), continue, end
        t = load([fx(j).folder '/' fx(j).name]); % Load apporpriate file
        x = [x str2double(fx(j).name((strfind(fx(j).name,'dur_')+4:strfind(fx(j).name,'.mat')-1)))]; % Level of stimulation
        p = [p sum(arrayfun(@(d)d.seizure,t.d))./numel(t.d)]; % Probability of seizure
    end
    [xs,is] = sort(x); % Sort inputs in numeric order
    ps = p(is); % Sort probabilities in same manner
    
    % Pull inputs/probabilities from ThresholdExperiment E
    pe = cellfun(@(c)sum([c.Seizure]),arrayfun(@(e)e.detector,E.S,'UniformOutput',false))./... % Number of seizures
            cellfun(@(c)numel([c.Seizure]),arrayfun(@(e)e.detector,E.S,'UniformOutput',false)); % Number of trials
    
    pidet = arrayfun(@(e)e.param.input.Deterministic.duration,E.S); % Deterministic input for each simulation
    pisig = arrayfun(@(e)e.param.input.Random.sigma,E.S); % Noise input for each simulation
    
    % Sort inputs in numeric order
    [xse,ie] = sort(pisig);
    pse = pe(ie);
    
    %%% Unit Test 3
    % Ensure that Exp(n)_mini and ThresholdExperiment E have the same data
    assert(all([xs ps] == [xse pse]),'Data in Exp(n)_mini and ThresholdExperiment E do not match!')
    assert(~any(pidet), 'At least one Simulation in ThresholdExperiment E has non-zero deterministic input!')
    
end

%% Conclusions
% If the above Unit Tests are passed, we have appropriately established:
%
% 1. dW matrices in Exp22_mini are equivalent (up to rotation) in
%    PlasticityExperiment PE, albeit with different indexing (i.e. numeric vs.
%    string indexing). (i.e. there exists an bijective map: Exp22_mini <=> PE)
% 2. Indices of ThresholdExperiments in E are matched 1:1 with those in
%    PlasticityExperiment PE (up to rotation). (i.e. there exists an
%    bijective map: PE <=> E)
% 3. (There already exists a bijective map: Exp22_mini <=> Exp(n)_mini
%    threshold data)
%
% The by composition, there exists a bijective map: 
%  Exp(n)_mini  <=>  Exp22_mini  <=>  PE  <=>  E
%
% For example (per variable mapu):
%  Exp32_mini <=> F(:,:,495) (i.e. Exp22_mini/...rep_94.mat)
%    <=> PE.Retrieve(94) (i.e. .../PlasticityExperiment/naive/...ment-94.mat) 
%      <=> .../ThresholdExperiment/STDP/...naive-94/;
%  
% We subsequently verified that data stored in ThresholdExperiment E and
% threshold data in Exp(n)_mini are the same through this mapping for all
% n. As a result, the mapping that existed from F(:,:,n) into Exp(n)_mini
% is preserved by mapping bewteen PE.Retrieve and ThresholdExperiment E,
% where the latter of these mappings is identity (A<=>A, for all A)

display('Passed Unit Tests in Transfer.m') % Alert user
    
