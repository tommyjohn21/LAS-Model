%%% Generate images to show efficacy of detector in representative test cases %%%
% Scripts for generating images of detect construction are embedded in the
% detector itself in simulation_bin_mini

%% Load data from center stimulation, naive case
f = dir('~/Desktop/Exp5_mini/');
for i = 1:numel(f)
    if strcmp(f(i).name,'.') || strcmp(f(i).name,'..') || any(strfind(f(i).name,'.DS_Store')) || any(strfind(f(i).name,'.txt')), continue, end
    load([f(i).folder '/' f(i).name])
end

%% Find three seizures and three non-seizures
si = find([d.seizure]==1,3);
ni = find([d.seizure]==0,3);
i = [si; ni];
i = i(:).';

f = figure;
t = tiledlayout(3,4);

for ix = i
    
    % Plot seizure
    nexttile
    imagesc(1:size(d(ix).V,1),[1:size(d(ix).V,2)]./1000,d(ix).V)
    title(['Model seizure (t = ' num2str(d(ix).stim_duration) 's)'])
    ylabel('Neuron index')
    xlabel('Time (s)')
    a.FontSize = 18;
    c = colorbar;
    c.Label.String = 'Voltage (mV)';
    
    % Plot state trace
    nexttile
    imagesc(1:size(d(ix).V,1),[1:size(d(ix).V,2)]./1000,d(ix).detector_metrics.state_trace)
    title('State trace')
    ylabel('Neuron index')
    xlabel('Time (s)')
    c = colorbar;
    c.Label.String = 'State (categorical)';
    a.FontSize = 18;
    
end

figname = 'testcases';
saveas(f,['~/Desktop/' figname '.svg'])

