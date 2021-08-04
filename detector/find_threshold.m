%%% Find threshold of original model by brute force %%%
savedir = '~/Desktop/detector/';
stim_durations = fliplr(0:0.01:3); % start with stronger stims for fast detection
n_sims = 40;

for i = 1:numel(stim_durations)
   
    d = detector_Exp1(n_sims,stim_durations(i),50);
    parsave([savedir 'stim_dur_' num2str(stim_durations(i)) '.mat'],d)
    
end

% %% Load data
% % data is detector_100 and detector_40 files stored on saturn in the
% % detector folder; just copied them to desktop for the following extraction
% f = dir('~/Desktop/detector_40/');
% o = []; ii=[];
% for i = 1:numel(f)
%     if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.txt')), continue, end
%     load([f(i).folder '/' f(i).name])
%     ixb = strfind(f(i).name,'_'); ixe = strfind(f(i).name,'.mat'); ia = str2num(f(i).name(ixb(end)+1:ixe-1)); if ia>10, ia=ia./10; end
%     ii=[ii ia];
%     o = [o [d.seizure].'];
% end
% 
% [~,i] = sort(ii)
% o = o(:,i);
% p1 = sum(o)./size(o,1);
% 
% f = dir('~/Desktop/detector_100/');
% o = []; ii=[];
% for i = 1:numel(f)
%     if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.txt')), continue, end
%     load([f(i).folder '/' f(i).name])
%     ixb = strfind(f(i).name,'_'); ixe = strfind(f(i).name,'.mat'); ia = str2num(f(i).name(ixb(end)+1:ixe-1)); if ia>10, ia=ia./10; end
%     ii=[ii ia];
%     o = [o [d.seizure].'];
% end
% 
% [~,i] = sort(ii)
% o = o(:,i);
% p2 = sum(o)./size(o,1);
% 
% %% Make graph
% % p is a matrix gathered from simulations with size 1 x numel(stim_durations)
% % above; it has in each element the probability of seizure
% stim_durations1 = 0:0.05:2;
% stim_durations2 = 0:0.01:3;
% 
% %% Voltage plot for 1 neuron (neuron 1000)
% f = figure();
% hold on
% plot(stim_durations2,p2,'.','MarkerSize',14);
% plot(stim_durations1,p1,'o','MarkerSize',14);
% a = gca;
% a.Title.String = 'Probability of seizure';
% a.XLabel.String = 'Stimulation duration';
% a.YLabel.String = 'Probability';
% a.FontSize = 18;
% a.XLim = [0 2];git c
% legend('100 simulations','40 simulations')
% figname = 'pseizure';
% saveas(f,['~/Desktop/' figname '.svg'])
% close(f)