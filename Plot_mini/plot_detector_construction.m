%%% Generate images to show contruction of detector in representative test cases %%%
h = Exp1_mini;

%% Simulate with stimulus durations as below
if 1
%% Stim dur of 3s
output = h.simulate_mini_by_stim_dur(3,3);

%% Stim dur of 0.5s
output = [output h.simulate_mini_by_stim_dur(3,0.5)];

%% Stim dur of 1.5s
output = [output h.simulate_mini_by_stim_dur(3,1.6)];

end
return

%% Build figures to illustrate detector

%% For first model seizure, export image of voltage
f = figure();
imagesc(0.001:0.001:25,1:500,output(1).V);
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

%% Voltage plot for 1 neuron
f = figure();
plot(0.001:0.001:24.999,output(1).V(250,:));
a = gca;
a.Title.String = 'Neuron 250';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20;]
a.YLabel.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'neuron250'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% dV/dt for 1 neuron
f = figure();
plot(0.001:0.001:24.998,diff(output(1).V(250,:),1,2));
a = gca;
a.Title.String = 'Neuron 250';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20;]
a.YLabel.String = 'dV/dt (mV/ms)';
a.FontSize = 18;
figname = 'neuron250dvdt'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for 1 neuron
f = figure();
x = diff(output(1).V(250,:),1,2).^2
plot(0.001:0.001:24.998,x);
a = gca;
a.Title.String = 'Neuron 250';
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = '(dV/dt)^2 (mV/ms)^2';
a.FontSize = 18;
figname = 'neuron250dvdt_pow'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for all neurons
f = figure();
x = diff(output(1).V,1,2).^2;
imagesc(0.001:0.001:25,1:500,x);
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
% imagesc(0.001:0.001:25,1:500,output(1).V);
% (dV/dt)^2
x = diff(output(1).V,1,2).^2;
imagesc(0.001:0.001:24.999,1:500,x);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.XLim = [1.5 7.5];
a.YLim = [230 270];
a.Title.String = 'Model seizure';
c = colorbar;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
% figname = 'modelseizure_stim';
figname = 'modelseizure_stim_diff';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% summed power of dV/dt for across all neurons
f = figure();
x = output(1).dP;
y = output(1).fdP;
plot(0.002:0.001:24.999,x);
hold on
plot(0.002:0.001:24.999,y,'LineWidth',3);
a = gca;
a.Title.String = '\Sigma (dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.XLim = [0 25];
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
ylim = a.YLim;
legend('\Sigma (dV/dt)^2','\Sigma (dV/dt)^2 filtered at 0.001 Hz')
figname = 'seizure_pow';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% threshold demo
f = figure();
plot([0.001 25],[1e4 1e4],'Color','k');
hold on
x = output(1).fdP;
plot(0.002:0.001:24.999,x,'LineWidth',3,'Color',[0 0.4470 0.7410]);
a = gca;
a.Title.String = '\Sigma (dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
a.YLim = ylim;
legend('Threshold (1e4)','\Sigma (dV/dt)^2 filtered at 0.001 Hz')
figname = 'seizure_pow_thresh';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% plot fdP with each of the simulations
f = figure();
plot([0.001 25],[1e4 1e4],'Color','k','HandleVisibility','off');
hold on
p = [];
colors = [[0 0.4470 0.7410]; [0.8500 0.3250 0.0980]; [ 0.9290 0.6940 0.1250]];

plotorder = [1:3 7:9 4:6];

for i = 1:9
p = [p plot(0.001:0.001:size(output(plotorder(i)).dP,2)/1000,output(plotorder(i)).fdP,'Color',colors(floor((plotorder(i)-1)/3)+1,:),'HandleVisibility','off','LineWidth',2)];
end

for i = 1:3:numel(p), p(i).HandleVisibility='on'; end
a = gca;
a.Children(2:3:end).HandleVisibility = 'on';
a.Title.String = 'Seizure detection by stim duration';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
a.YLim = [0 1.4e4];
a.XLim = [0 25];
legend('t_{stim}=3s','t_{stim}=1.6s','t_{stim}=0.5s','Location','NorthWest')
figname = 'seizure_pow_thresh';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% plot seizures for each stim condition -- t = 0.5s
f = figure();
imagesc(0:0.001:size(output(4).dP,2)/1000,1:500,output(4).V);
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
imagesc(0:0.001:size(output(7).dP,2)/1000,1:500,output(7).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.6s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_161';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)

f = figure();
imagesc(0:0.001:size(output(8).dP,2)/1000,1:500,output(8).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.6s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_162';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)

f = figure();
imagesc(0:0.001:size(output(9).dP,2)/1000,1:500,output(9).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.XLim = [0 20];
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=1.6s';
c = colorbar;
caxis(clim);
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_163';
saveas(f,['~/Desktop/' figname '.svg'])
% close(f)


