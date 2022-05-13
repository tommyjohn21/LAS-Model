%% Suite of rough ideas about visualizing StimulationExperiment results

% Initialize StimulationExperiment
E = StimulationExperiment('screen-20');
% Identify variable directory, update variable directory
VarDir = 'StimulationExperiment';
E.UpdateDir(VarDir);
Load(E) % Load results

%% Extract pertinent coordinates and output values
coord = [arrayfun(@(s)s.param.input.Stimulation.frequency,E.S);...
    arrayfun(@(s)s.param.input.Stimulation.magnitude,E.S);...
    arrayfun(@(s)s.param.input.Stimulation.pulsewidth,E.S);...
    arrayfun(@(s)s.param.input.Stimulation.pulsenum,E.S)]';

p = arrayfun(@(s)sum([s.detector.Seizure])./numel([s.detector.Seizure]),E.S);

%% Reformat into volumes
[f,m,pw,pn] = ndgrid(unique(coord(:,1)),unique(coord(:,2)),unique(coord(:,3)),unique(coord(:,4)));
pr = NaN(size(f));

for i = 1:numel(p)
   ix = find(f == coord(i,1) & m == coord(i,2) & pw == coord(i,3) & pn == coord(i,4));
   pr(ix) = p(i);
end

%% Scatter plot in 3D
f = figure; a = gca;
c = parula(21);
s = scatter3(coord(:,1),coord(:,3),coord(:,2),40*coord(:,4),c(dsearchn([0:0.05:1].',p.')),'filled');
% coord(:,2),c(dsearchn([0:0.05:1].',p.'),:),'filled');
% s.AlphaData = 1-p;
% s.MarkerFaceAlpha = 'flat';
a.XScale = 'log';
% a.YScale = 'log';
% a.ZScale = 'log';

a.XLabel.String = 'Frequency (Hz)';
a.YLabel.String = 'Pulse Width (ms)';
a.ZLabel.String = 'Magnitude (pA)';
a.FontSize = 18;
axis square


