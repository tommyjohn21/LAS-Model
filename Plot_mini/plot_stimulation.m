%% Suite of rough ideas about visualizing StimulationExperiment results

% Initialize StimulationExperiment
E = StimulationExperiment('screen-20');
% Identify variable directory, update variable directory
VarDir = 'StimulationExperiment';
E.UpdateDir(VarDir);
Load(E) % Load results

%% Use slice visualization with corrected parameters

% Anonymous function to calculate pulsenum
pulsenum = @(frequency,duration,magnitude,pulsewidth) floor(duration.*frequency)+((duration.*frequency - floor(duration.*frequency))*1000 >= pulsewidth);

% Pull out stimualation parameters
f = arrayfun(@(s)s.param.input.Stimulation.frequency,E.S);
m = arrayfun(@(s)s.param.input.Stimulation.magnitude,E.S);
pw = arrayfun(@(s)s.param.input.Stimulation.pulsewidth,E.S);
pn = arrayfun(@(s)s.param.input.Stimulation.pulsenum,E.S);
dur = arrayfun(@(s)s.param.input.Stimulation.duration,E.S);

% Compute probabilities
p = arrayfun(@(s)sum([s.detector.Seizure])./numel([s.detector.Seizure]),E.S);

% Create domain volumes
[F,D,M,PW] = ndgrid(unique(f),unique(dur),unique(m),unique(pw));
PR = NaN(size(F));
for i = 1:numel(p)
   ix = find(f(i) == F(:) & dur(i) == D(:) & m(i) == M(:) & pw(i) == PW(:));
   PR(ix) = p(i);
end

% Pulse num in volume space
PN = pulsenum(F,D,M,PW);

% Determine valid space
H = StimulationExperiment('hijack');
H.param.inputs.frequency = unique(f);
H.param.inputs.duration = unique(dur);
H.param.inputs.magnitude = unique(m);
H.param.inputs.pulsewidth = unique(pw);
[StimParams,IsValid] = ExpandInputs(H);
% Reshape to create valid space
I = reshape(IsValid,numel(unique(f)),numel(unique(dur)),numel(unique(m)),numel(unique(pw)));

% Find valid, non-tested inputs that need filling
tofill = I(:)&isnan(PR(:)); % valid inputs that were not filled because they were duplicates
[ff,df,mf,pwf] = deal(F(tofill),D(tofill),M(tofill),PW(tofill));
pnf = pulsenum(ff,df,mf,pwf);
itf = find(tofill); % index of tofill spots

% Replace valid, non-tested inputs by their duplicate counterparts (i.e.
% valid, non-tested inputs were not tested because they were...duplicates,
% so we already know what they would have been)
for i = 1:numel(ff)
    % Grab the candidate that matches all of the tofill parameters but is
    % not in the tofill list
    candidate = setdiff(find(F(:) == ff(i) & M(:) == mf(i) & PW(:) == pwf(i) & PN(:) == pnf(i)),find(tofill));
    assert(numel(candidate) == 1,'There is more than one candidate to fill, would swing back through code')
    % Ensure candidate is valid
    assert(all(I(candidate)),'Candidate(s) is (are) not valid')
    PR(itf(i)) = mean(PR(candidate)); % fill the tofill spot with the identical stimulus
end

% Now, all valid inputs are non-nan PR and all non-valid inputs are PR
assert(all(isnan(PR(~I))) && all(~isnan(PR(I))),'The above comment is not true')

% Replace non-valid points with an imaginary number (for interpolation)
TPR = PR;
TPR(isnan(TPR)) = 1i;

%% Hijack StimulationExperiment architecture
H = StimulationExperiment('hijack');
H.param.inputs.frequency = unique([min(f(:)):10:max(f(:)) f]);
H.param.inputs.duration = unique([min(dur(:)):0.25:max(dur(:)),dur]);
H.param.inputs.magnitude = unique([min(m(:)):30:max(m(:))]);
H.param.inputs.pulsewidth = unique([min(pw(:)):10:max(pw(:)),pw]);
[StimParams,IsValid] = ExpandInputs(H);
IDX = reshape(IsValid,numel(H.param.inputs.frequency),...
    numel(H.param.inputs.duration),...
    numel(H.param.inputs.magnitude),...
    numel(H.param.inputs.pulsewidth));

sp = cell2mat(arrayfun(@(i)[i.frequency i.duration i.magnitude i.pulsewidth],StimParams,'un',0));

% Create 4D meshgrid
[Fq,Dq,Mq,PWq] = ndgrid(...
    unique(sp(:,1)),...
    unique(sp(:,2)),...
    unique(sp(:,3)),...
    unique(sp(:,4))...
    );

% Identify valid meshgrid
% x = [Fq(:) PNq(:) PWq(:) Mq(:)];
% idx = ismember(x,sp,'rows');
% IDX = reshape(idx,size(Fq));

%% Interpolate and remove
PRq = interpn(F,D,M,PW,TPR,Fq,Dq,Mq,PWq);

IDXq = (imag(PRq)==0).*IDX; % In principle, this knocks out *all* points where a NaN was used heavily in interpretation (?strictest possible criteria)

% Check that interpolation retains points that were not interpolated (i.e.
% ground truth)

[x1,x2,x3,x4] = deal(...
    find(ismember(unique(Fq(:)),unique(F(:)))),...
    find(ismember(unique(Dq(:)),unique(D(:)))),...
    find(ismember(unique(Mq(:)),unique(M(:)))),...
    find(ismember(unique(PWq(:)),unique(PW(:))))...
    );

[y1,y2,y3,y4] = deal(...
    find(ismember(unique(F(:)),unique(Fq(:)))),...
    find(ismember(unique(D(:)),unique(Dq(:)))),...
    find(ismember(unique(M(:)),unique(Mq(:)))),...
    find(ismember(unique(PW(:)),unique(PWq(:))))...
    );

assert(max(abs(reshape(real(TPR(y1,y2,y3,y4))-real(PRq(x1,x2,x3,x4)),[],1)))<1e-10,'Original and interpolated data disagree')

%% Create figure

fg = figure;
fg.Units = 'inches';
fg.Position = [fg.Position(1:2) 20 11.79];
% f.Color = 'none';
t = tiledlayout(2,3);

for mi = 1:numel(unique(Mq))
    
    nexttile
    
    % X Slices
    sx = slice(squeeze(Dq(:,:,mi,:)),squeeze(Fq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),squeeze(real(PRq(:,:,mi,:))),...
        min(Dq(:)):(max(Dq(:))-min(Dq(:)))./1000:max(Dq(:)),[],[]);
    %     min(Fq(:)):(max(Fq(:))-min(Fq(:)))./100:max(Fq(:)),...
    %     min(PWq(:)):(max(PWq(:))-min(PWq(:)))./100:max(PWq(:)));
    
    % Create 4D meshgrid for alpha interpolation
    [Fqx,Dqx,PWqx] = ndgrid(...
        unique(sp(:,1)),...%,[],[]);
        min(Dq(:)):(max(Dq(:))-min(Dq(:)))./1000:max(Dq(:)),...
        unique(sp(:,4)));
    
    IDXqi = interpn(squeeze(Fq(:,:,mi,:)),squeeze(Dq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),...
        squeeze(IDXq(:,:,mi,:)),...
        Fqx,Dqx,PWqx,...
        'nearest');
    
    for si = 1:numel(sx)
        ss = sx(si);
        AData = squeeze(IDXqi(:,si,:));
        CData = ss.CData;
        ss.AlphaData = ((1 - CData.*0.9).*AData);
    end
    arrayfun(@(ss)set(ss,'EdgeColor','none','FaceColor','interp','FaceAlpha','interp'),sx)
    
    % Y Slices
    sy = slice(squeeze(Dq(:,:,mi,:)),squeeze(Fq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),squeeze(real(PRq(:,:,mi,:))),...
        [],exp(log(min(Fq(:))):(log(max(Fq(:)))-log(min(Fq(:))))/1000:log(max(Fq(:)))),[]);
    
    % Create 4D meshgrid for alpha interpolation
    [Fqx,Dqx,PWqx] = ndgrid(...
        exp(log(min(Fq(:))):(log(max(Fq(:)))-log(min(Fq(:))))/1000:log(max(Fq(:)))),...%,[],[]);
        unique(sp(:,2)),...
        unique(sp(:,4)));
    
    IDXqi = interpn(squeeze(Fq(:,:,mi,:)),squeeze(Dq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),...
        squeeze(IDXq(:,:,mi,:)),...
        Fqx,Dqx,PWqx,...
        'nearest');
    
    for si = 1:numel(sy)
        ss = sy(si);
        AData = squeeze(IDXqi(si,:,:));
        CData = ss.CData;
        ss.AlphaData = ((1 - CData.*0.9).*AData);
    end
    arrayfun(@(ss)set(ss,'EdgeColor','none','FaceColor','interp','FaceAlpha','interp'),sy)
    
    % Z Slices
    sz = slice(squeeze(Dq(:,:,mi,:)),squeeze(Fq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),squeeze(real(PRq(:,:,mi,:))),...
        [],[],exp(log(min(PWq(:))):(log(max(PWq(:)))-log(min(PWq(:))))/1000:log(max(PWq(:)))));
    
    % Create 4D meshgrid for alpha interpolation
    [Fqx,Dqx,PWqx] = ndgrid(...
        unique(sp(:,1)),...%,[],[]);
        unique(sp(:,2)),...
        exp(log(min(PWq(:))):(log(max(PWq(:)))-log(min(PWq(:))))/1000:log(max(PWq(:)))));
    
    IDXqi = interpn(squeeze(Fq(:,:,mi,:)),squeeze(Dq(:,:,mi,:)),squeeze(PWq(:,:,mi,:)),...
        squeeze(IDXq(:,:,mi,:)),...
        Fqx,Dqx,PWqx,...
        'nearest');
    
    for si = 1:numel(sz)
        ss = sz(si);
        AData = squeeze(IDXqi(:,:,si));
        CData = ss.CData;
        ss.AlphaData = ((1 - CData.*0.9).*AData);
    end
    arrayfun(@(ss)set(ss,'EdgeColor','none','FaceColor','interp','FaceAlpha','interp'),sz)
    
    % Window dressing
    fg = gcf;
    a = gca;
    a.XLabel.String = 'Duration (s)';
    a.YLabel.String = 'Frequency (Hz)';
    a.ZLabel.String = 'Pulse Width (ms)';
    a.FontSize = 16;
    a.XScale = 'linear';
    a.YScale = 'log';
    a.ZScale = 'log';
    axis square
    a.Title.String = ['I = ' num2str(unique(Mq(:,:,mi,:))) ' pA'];
    a.XLim = [0.5 3];
    a.View = [-250 10]; % Change the first of these numbers to rotate image
    
end

% Create gif? With colorbar? We need to do something, probs, so that we can
% demonstrate why we know the chosen parameters won't cause a seizure...

% Can we narrow to I = 200, dur = 3s and use that plane to sample a few
% places (is this reasonable)? Feels like for simplicity, we can at least
% narrow down to I = 200 to be in accordance with initial paper...

%% Various other figure settings
cb  = colorbar;
assert(all((abs(fg.Children.Children(2).Position(3:4) - fg.Children.Children(end).Position(3:4))<1e-10)),'Plot for 200 pA is smaller than the plot for 50 pA')

% Adjust colorbar size/location
cb.Position(2) = 0.50 - cb.Position(4)/2;
cb.Position(3) = cb.Position(3).*1.75;
cb.Label.String = 'Probability of Seizure';
cb.FontSize = 16;

% Grab axes array handles
ax = fg.Children.Children(2:end);

% Turn off appropriate labels
for ai = 4:numel(ax),  ax(ai).XLabel.Visible = 0; ax(ai).YLabel.Visible = 0; end
for ai = [1 2 4 5],  ax(ai).ZLabel.Visible = 0; end
for ai = 1:numel(ax),  ax(ai).Title.FontWeight = 'normal'; ax(ai).Title.FontSize = 20; end

% Title the tileplot
fg.Children.Title.String = 'Probability of seizure by pulse train parameters';
fg.Children.Title.FontSize = 24;
fg.Children.Title.FontWeight = 'bold';

% Assert all plots are the same size
assert(max(max(dist(cell2mat(arrayfun(@(a)a.Position(3:4),ax,'UniformOutput',false)).')))<1e-10,'One plot is not the same size as another')

% Readjust colorbar positioning
cb.Ticks =[0 1];
cb.Title.Units = 'data';
cb.Position(1) = 0.945;

%% Need to: make gif
gn = '~/Desktop/Stimulus_test.gif'; % gif name
ax = fg.Children.Children(2:end); % Grab children
delaytime = 1/12; % one second per 12 degrees of rotation; gives 360 degrees in 30 seconds
nframes = 360; % one frame per degree

xstate = arrayfun(@(a)a.XLabel.Visible,ax); % Grab default x-axis visibility
xs = 0;
ystate = arrayfun(@(a)a.YLabel.Visible,ax); % Grab default y-axis visibility
ys = 0;

xtick = ax(1).XTick;
ytick = ax(1).YTick;

for i = 1:360
    
    % Mute vertical labels
    if any(arrayfun(@(a)a.XLabel.Rotation,ax))
        for ii = 1:numel(ax), ax(ii).XLabel.Visible = 0; end
    end
    if any(arrayfun(@(a)a.YLabel.Rotation,ax))
        for ii = 1:numel(ax), ax(ii).YLabel.Visible = 0; end
    end
    
    % Set axis ticks to be unchanged
    arrayfun(@(a)set(a,'XTick',xtick),ax)
    arrayfun(@(a)set(a,'YTick',ytick),ax)
    
    frame = getframe(fg);
    im = frame2im(frame); % Capture current frame
    [imind,cm] = rgb2ind(im,256);
    if i == 1 % intialization
        imwrite(imind,cm,gn,'gif', 'Loopcount',inf);
    else % continuation
        imwrite(imind,cm,gn,'gif','WriteMode','append','DelayTime',delaytime)
    end
    
    % Rotate by 1 degree
    arrayfun(@(a)view(a,a.View(1)-1,a.View(2)),ax)
    
    % Reset axes labels
    for ii = 1:numel(ax), ax(ii).XLabel.Visible = xstate(ii); end
    for ii = 1:numel(ax), ax(ii).YLabel.Visible = ystate(ii); end
    
end

%% Choose which parameters to use for further stimulation
% Set seed to default
rng('default')

% Pull out stimualation parameters
f = arrayfun(@(s)s.param.input.Stimulation.frequency,E.S);
m = arrayfun(@(s)s.param.input.Stimulation.magnitude,E.S);
pw = arrayfun(@(s)s.param.input.Stimulation.pulsewidth,E.S);
pn = arrayfun(@(s)s.param.input.Stimulation.pulsenum,E.S);
dur = arrayfun(@(s)s.param.input.Stimulation.duration,E.S);

% Compute probabilities
p = arrayfun(@(s)sum([s.detector.Seizure])./numel([s.detector.Seizure]),E.S);

% Find zero-probability parameters 
i = find(p==0);

% Shuffle and take first 10
j = i(randperm(numel(i)));
j = j(1:10);

% For posterity
% j = [268   224   424   811   754   588   678   100   853   130];
