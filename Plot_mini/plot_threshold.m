%%% Plot threshold generated by Exp1_mini %%%

%% Load data
f = dir('~/Desktop/Exp23_mini/');
o = []; ii=[];
for i = 1:numel(f)
    if ~any(strfind(f(i).name,'.mat')), continue, end    
    load([f(i).folder '/' f(i).name])
    ixb = strfind(f(i).name,'_'); ixe = strfind(f(i).name,'.mat'); ia = str2num(f(i).name(ixb(end)+1:ixe-1)); %if ia>10, ia=ia./10; end
    ii=[ii ia];
    o = [o [d.seizure].'];
end

[~,i] = sort(ii);
o = o(:,i);
p1 = sum(o)./size(o,1);
st1 = ii(i);

%% Fit threshold data to sigmoid function
sig = @(x) (1 + exp(-(st1-x(1))./x(2))).^(-1);
ofn = @(x) sum((sig(x)-p1).^2);
fit = fminsearch(ofn,[1.5,1]);

%% Make graph
% p is a matrix gathered from simulations with size 1 x numel(stim_durations)
% above; it has in each element the probability of seizure
if exist('h','var') && isvalid(h) && isa(h,'matlab.ui.Figure'), h = gcf; else h = figure(); end
if ~exist('cl','var'), cl = get(gca,'ColorOrder'); xi = 1; end
a = gca;
hold on
plot(st1,p1,'o','MarkerEdgeColor','k','MarkerFaceColor',cl(xi,:),'MarkerSize',6); 
% plot(st1,p1,'o','MarkerSize',14);
plot(st1,sig(fit),'LineWidth',2,'Color',[cl(xi,:) 0.25]);
xi = xi+1;
a.Title.String = 'Probability of seizure';
% a.XLabel.String = 'Stimulation duration (s)';
a.XLabel.String = '\sigma_{S} (noise level, pA)';
a.YLabel.String = 'Probability';
a.FontSize = 18;
% a.XLim = [2 4];
a.YLim = [0 1];
legend({'p(seizure)','Sigmoid fit'},'Location','NorthWest')
figname = 'pseizure';
% saveas(f,['~/Desktop/' figname '.svg'])
% close(f)

%% Compare thresholds statistically
f = dir('~/Desktop/Exp37_mini/');
o = []; ii=[];
for i = 1:numel(f)
    if ~any(strfind(f(i).name,'.mat')), continue, end    
    load([f(i).folder '/' f(i).name])
    ixb = strfind(f(i).name,'_'); ixe = strfind(f(i).name,'.mat'); ia = str2num(f(i).name(ixb(end)+1:ixe-1)); %if ia>10, ia=ia./10; end
    ii=[ii ia];
    o = [o [d.seizure].'];
end

[~,i] = sort(ii);
o = o(:,i);
o1 = o;
p1 = sum(o)./size(o,1);
st1 = ii(i);

f = dir('~/Desktop/Exp38_mini/');
o = []; ii=[];
for i = 1:numel(f)
    if ~any(strfind(f(i).name,'.mat')), continue, end    
    load([f(i).folder '/' f(i).name])
    ixb = strfind(f(i).name,'_'); ixe = strfind(f(i).name,'.mat'); ia = str2num(f(i).name(ixb(end)+1:ixe-1)); %if ia>10, ia=ia./10; end
    ii=[ii ia];
    o = [o [d.seizure].'];
end

[~,i] = sort(ii);
o = o(:,i);
o2 = o;
p2 = sum(o)./size(o,1);
st2 = ii(i);

%% Plot procedure to determine significance for power analysis
f = figure();
a = gca();
title('Probability of seizure (N = 100 simulations)');
a.XLabel.String = 'Stimulation duration (s)';
a.YLabel.String = 'Probability';
hold on;
plot(st1,p1,'x-','LineWidth',2);
plot(st2,p2,'x-','LineWidth',2);
a.FontSize = 18;
legend({'Naive model' 'One round of STDP'},'Location','NorthWest')
% xlim([1.2 2.2])
figname = 'power1';
% saveas(f,['~/Desktop/' figname '.svg'])

%% Common domain
% Keep only shared points
st = intersect(st1,st2);
p1 = p1(ismember(st1,st));
o1 = o1(:,ismember(st1,st));
p2 = p2(ismember(st2,st));
o2 = o2(:,ismember(st2,st));

% Discard if both == 1 or both == 0
ix = ~(p1 == 0 & p2 == 0) & ~(p1 == 1 & p2 == 1);
st = st(ix);
p1 = p1(ix);
o1 = o1(:,ix);
p2 = p2(ix);
o2 = o2(:,ix);

%% Add boundaries to graph, toss non-shared domain
f = figure();
a = gca();
title('Probability of seizure (N = 100 simulations)');
a.XLabel.String = 'Stimulation duration (s)';
a.YLabel.String = 'Probability';
hold on;
plot(st,p1,'x-','LineWidth',2);
plot(st,p2,'x-','LineWidth',2);
a.FontSize = 18;
% xlim([1.2 2.2])
plot([st(1) st(1)], [0 1],'k','LineWidth',2)
plot([st(end) st(end)], [0 1],'k','LineWidth',2)
legend({'Naive model' 'One round of STDP' '' ''},'Location','NorthWest')


figname = 'power2';
% saveas(f,['~/Desktop/' figname '.svg'])

%% Plot residuals
med = median(p2-p1);
p = signrank(p2,p1);

f = figure;
a = gca;
hold on
title('Residuals: p_{naive} - p_{STDP}')
histogram(p2-p1,[-0.1:0.01:.1])
a.XLabel.String = 'p_{naive} - p_{STDP}';
a.YLabel.String = 'Counts';
ylim([0 3]);
t = text(0.1,2.5,{'Wilcoxon signed-rank:' ['Median ' num2str(med)] ['p = ' sprintf('%.3f',p)]},'HorizontalAlignment','right','FontSize',18);
a.FontSize = 18;

figname = 'power3';
% saveas(f,['~/Desktop/' figname '.svg'])

%% Wilcoxon signed rank
n = 1000; % number of repeated simulations
k = 30:100; % number of repetitions within a single test

P = nan(n,numel(k));

for ki = 1:numel(k)
    for i = 1:n
        id1 = randperm(100);
        id2 = randperm(100);
        id1 = id1(1:k(ki));
        id2 = id2(1:k(ki));
        
        t1 = sum(o1(id1,:))./numel(id1);
        t2 = sum(o2(id2,:))./numel(id2);
        
        pr = signrank(t1,t2);
        P(i,ki) = pr;
    end
end

%% Plot alpha simulation
f = figure;
hold on
plot(k,mean(P<0.05),'LineWidth',2);
a = gca;
title('Power analysis');
a.XLabel.String = 'Number of trials (k)';
a.YLabel.String = 'Percent significant (p < 0.05)';
a.FontSize = 18;
a.XGrid = 'on';
a.YGrid = 'on';
figname = 'power4';
% saveas(f,['~/Desktop/' figname '.svg'])

%% Draw seizure threshold by type

