% Gut check on detector; try with different stim params

% Data from the below simualtions can  be found on server in
% ~/simulate_detection

if 0
%% Stim dur of 3s
output = detector_Exp1(3,3,50);

%% Stim dur of 0.5s
output = [output detector_Exp1(3,0.5,50)];

%% Stim dur of 1.5s
output = [output detector_Exp1(3,1.5,50)];

end
return
%% Build figures to illustrate detector

%% For first model seizure, export image of voltage
f = figure();
imagesc(0:0.001:27,1:2400,output(1).V);
a = gca;
a.XLim = [0 20];
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
% a.Title.String = 'Model seizure';
a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
clim = caxis;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% Voltage plot for 1 neuron (neuron 1000)
f = figure();
plot(0.001:0.001:27,output(1).V(1200,:));
a = gca;
a.Title.String = 'Neuron 1200';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20;]
a.YLabel.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'neuron1200'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% dV/dt for 1 neuron
f = figure();
plot(0.001:0.001:26.999,diff(output(1).V(1200,:),1,2));
a = gca;
a.Title.String = 'Neuron 1200';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20;]
a.YLabel.String = 'dV/dt (mV/ms)';
a.FontSize = 18;
figname = 'neuron1200dvdt'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for 1 neuron
f = figure();
x = diff(output(1).V(1200,:),1,2).^2
plot(0.001:0.001:26.999,x);
a = gca;
a.Title.String = 'Neuron 1200';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = '(dV/dt)^2 (mV/ms)^2';
a.FontSize = 18;
figname = 'neuron1200dvdt_pow'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for all neurons
f = figure();
x = diff(output(1).V,1,2).^2;
imagesc(0.001:0.001:26.999,1:2400,x);
a = gca;
a.Title.String = '(dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.FontSize = 18;
c = colorbar;
c.Label.String = '(dV/dt)^2 (mV/ms)^2';
figname = 'neurondvdt_pow';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% Look specifically at stimulation of voltage
f = figure();
% Original voltage
imagesc(0.001:0.001:27,1:2400,output(1).V);
% (dV/dt)^2
% x = diff(output(1).V,1,2).^2;
% imagesc(0.001:0.001:26.999,1:2400,x);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.XLim = [1.5 7.5];
a.YLim = [900 1500];
a.Title.String = 'Model seizure';
c = colorbar;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_stim';
% figname = 'modelseizure_stim_diff';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% summed power of dV/dt for across all neurons
f = figure();
x = output(1).dP;
y = output(1).fdP;
plot(0.001:0.001:26.999,x);
hold on
plot(0.001:0.001:26.999,y,'LineWidth',3);
a = gca;
a.Title.String = '\Sigma (dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.XLim = [0 27];
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
ylim = a.YLim;
legend('\Sigma (dV/dt)^2','\Sigma (dV/dt)^2 filtered at 0.001 Hz')
figname = 'seizure_pow';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% threshold demo
f = figure();
plot([0.001 27],[2e4 2e4],'Color','k');
hold on
x = output(1).fdP;
plot(0.001:0.001:26.999,x,'LineWidth',3);
a = gca;
a.Title.String = '\Sigma (dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
a.YLim = ylim;
legend('Threshold (2e4)','\Sigma (dV/dt)^2 filtered at 0.001 Hz')
figname = 'seizure_pow_thresh';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% plot fdP with each of the simulations
f = figure();
plot([0.001 50],[2e4 2e4],'Color','k','HandleVisibility','off');
hold on
p = [];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [ 0.9290 0.6940 0.1250]];

plotorder = [1:3 7:9 4:6];

for i = 1:9
p = [p plot(0.001:0.001:size(output(plotorder(i)).dP,2)/1000,output(plotorder(i)).fdP,'Color',colors(floor((plotorder(i)-1)/3)+1,:),'HandleVisibility','off')];
end

for i = 1:3:numel(p), p(i).HandleVisibility='on'; end
a = gca;
a.Children(2:3:end).HandleVisibility = 'on';
a.Title.String = 'Seizure detection by stim duration';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
a.YLim = [0 2.25e4];
a.XLim = [0 30];
legend('t_{stim}=3s','t_{stim}=1.5s','t_{stim}=0.5s','Location','NorthWest')
figname = 'seizure_pow_thresh';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% plot seizures for each stim condition -- t = 0.5s
f = figure();
imagesc(0:0.001:size(output(4).dP,2)/1000,1:2400,output(4).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=0.5s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_05';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)


%% plot seizures for each stim condition
% Plot of interest: 7:9
f = figure();
imagesc(0:0.001:size(output(7).dP,2)/1000,1:2400,output(7).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.5s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_151';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)

f = figure();
imagesc(0:0.001:size(output(8).dP,2)/1000,1:2400,output(8).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.5s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_152';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)

f = figure();
imagesc(0:0.001:size(output(9).dP,2)/1000,1:2400,output(9).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.5s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_153';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)
