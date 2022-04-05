%% Script to transfer Exp_mini disaster into new @ThresholdExperiment objects
% Key for STDP/Threshold Link (Exp no. and dW no.)
key = [495 613 200 358 619 246 681 750 216 70  334 999 583 637 90  210 898 42  963 738 538 575 368 450 53  360 626 760 169 693 771 645 599 566 731 576 797 296 375 840 354 726 657 691 426 628 69  938 864 686 657 77  905 4   195 912 136 530 880 784 782 751 622 481 487 684 805 345 682 435 872 866 265 610 589 549 887 268 314 139 924 633 996 623 541 630 536 705 523 948 222 118 124 61  373 440 338 730 597 736 893; ...
       32  33  42  43  44  45  46  47  48  49  50  51  52  53  54  55  56  57  58  59  60  61  62  63  64  65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80  81  82  83  84  85  86  87  88  89  90  91  92  93  94  95  96  97  98  99  100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140];

% Break key into mod 500
keymod = [rem(key(1,:),500); key(2,:)];

% dW map
idx = sort(cellfun(@(a)num2str(a),num2cell(1:500),'UniformOutput',false)).';

for i = 1:numel(key(1,:)) % will cycle through all of keymod
    
    d = sprintf(['~/Desktop/Exp_mini/Exp%d_mini'],key(2,i));
    d = dir(d);
    for j = 1:numel(d)
        if ~contains(d(j).name,'.mat'), continue, end
        data = load(fullfile(d(j).folder,d(j).name));
        
        % load new structure
        load('~/Desktop/ThresholdExperiment/STDP/PlasticityExperiment-naive-4/ThresholdExperiment-Level-10.0.mat');
        
        % Update new structure
        E.param.name = sprintf('PlasticityExperiment-naive-%i',str2num(idx{keymod(1,i)}));
        E.param.expdir = strrep(E.param.expdir,'-naive-4',sprintf('-naive-%i',str2num(idx{keymod(1,i)})));
        E.param.inputs.levels = sort(cell2mat(arrayfun(@(d)str2num(d.name(10:end-4)),d,'UniformOutput',false))).';
        E.param.n = numel(data.d);
        
        % Load appropriate dW matrix
        dW = load(['~/Desktop/Exp22_mini/stim_dur_3_rep_' idx{keymod(1,i)} '.mat']);
        E.S.param.dW = dW.d.dW;
        
        % Put correct noise level for Simulation
        E.S.param.input.Random.sigma = str2double(d(j).name(10:end-4));
        
        % fold in detector
        for k = 1:numel(data.d)
            E.S.detector(k) = struct('Seizure',data.d(k).seizure,...
                'WaveCollapsed',data.d(k).detector_metrics.wave_collapsed,...
                'State',[],'V',[]);
        end
        
        % O.param differs in fields V_reset, delta_phi, f and template;
        % difference is driven by inequality of anonymous functions
        % (same/equivalent character representations but differing
        % handles), as well as hacking required for @Simulation model (e.g.
        % O -> S.O and template -> template hack:
        % space_compression=4;time...); O.W/Enabled fields saved in
        % @Simulation are appropriately handled

        % Save
        FileName = sprintf([E.param.expdir 'ThresholdExperiment-Level-%0.1f.mat'],str2double(d(j).name(10:end-4)));
        if ~exist(E.param.expdir,'dir'), mkdir(E.param.expdir); end
        if ~exist(FileName,'file'), save(FileName, 'E', '-v7.3'); end
        
        clear E data dW
        
    end
    
end