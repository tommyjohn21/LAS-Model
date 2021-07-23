% Gut check on detector; try with different stim params

if 0
%% Stim dur of 3s
output = detector_Exp1(10,3,20);

%% Stim dur of 0.5s
output = [output detector_Exp1(10,0.5,20)];

%% Stim dur of 0.8s
output = [output detector_Exp1(10,0.78,20)];

save('/Users/tommyjohn21/OneDrive - cumc.columbia.edu/Data/detector/output.mat','output','-v7.3')

else
    load('/Users/tommyjohn21/OneDrive - cumc.columbia.edu/Data/detector/output.mat','output','-v7.3')
end

%% Build figures to illustrate detector

%% For first model seizure, export image of voltage
f = figure();
imagesc(0:0.001:20,1:2000,output(1).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure';
% a.Title.String = 'Model seizure t_{stim}=3s';
c = colorbar;
clim = c.Limits;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% Voltage plot for 1 neuron (neuron 1000)
f = figure();
plot(0:0.001:20,output(1).V(1000,:));
a = gca;
a.Title.String = 'Neuron 1000';
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'neuron1000'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% dV/dt for 1 neuron
f = figure();
plot(0.001:0.001:20,diff(output(1).V(1000,:),1,2));
a = gca;
a.Title.String = 'Neuron 1000';
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'dV/dt (mV/ms)';
a.FontSize = 18;
figname = 'neuron1000dvdt'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for 1 neuron
f = figure();
x = diff(output(1).V(1000,:),1,2).^2
plot(0.001:0.001:20,x);
a = gca;
a.Title.String = 'Neuron 1000';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '(dV/dt)^2 (mV/ms)^2';
a.FontSize = 18;
figname = 'neuron1000dvdt_pow'
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% power of dV/dt for all neurons
f = figure();
x = diff(output(1).V,1,2).^2;
imagesc(0:0.001:20,1:2000,x);
a = gca;
a.Title.String = '(dV/dt)^2';
a.XLabel.String = 'Time (s)';
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
imagesc(0:0.001:20,1:2000,output(1).V);
% (dV/dt)^2
% x = diff(output(1).V,1,2).^2;
% imagesc(0:0.001:20,1:2000,x);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.XLim = [1.5 7.5];
a.YLim = [750 1250];
a.Title.String = 'Model seizure';
c = colorbar;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_stim';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% summed power of dV/dt for across all neurons
f = figure();
x = output(1).dP;
y = output(1).fdP;
plot(0.001:0.001:20,x);
hold on
plot(0.001:0.001:20,y,'LineWidth',3);
a = gca;
a.Title.String = '\Sigma (dV/dt)^2';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
ylim = a.YLim;
legend('\Sigma (dV/dt)^2','\Sigma (dV/dt)^2 filtered at 0.001 Hz')
figname = 'seizure_pow';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% threshold demo
f = figure();
plot([0.001 20],[1e4 1e4],'Color','k');
hold on
x = output(1).fdP;
plot(0.001:0.001:20,x,'LineWidth',3);
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
x = reshape([output.fdP],[20000 30]); % grab data from fdP for each simulation
f = figure();
plot([0.001 20],[1e4 1e4],'Color','k','HandleVisibility','off');
hold on
p = plot(0.001:0.001:20,x(:,1:10),'Color',[0 0.4470 0.7410],'HandleVisibility','off');
p = [p; plot(0.001:0.001:20,x(:,21:30),'Color',[0.8500 0.3250 0.0980],'HandleVisibility','off')];
p = [p; plot(0.001:0.001:20,x(:,11:20),'Color',[ 0.9290 0.6940 0.1250],'HandleVisibility','off')];
for i = 1:10:numel(p), p(i).HandleVisibility='on'; end
a = gca;
a.Children(2:10:end).HandleVisibility = 'on';
a.Title.String = 'Seizure detection by stim duration';
a.XLabel.String = 'Time (s)';
a.YLabel.String = '\Sigma (dV/dt)^2';
a.FontSize = 18;
a.YLim = [0 1.5e4];
a.XLim = [0 7];
legend('t_{stim}=3s','t_{stim}=0.78s','t_{stim}=0.5s')
figname = 'seizure_pow_thresh';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

%% plot seizures for each stim condition -- t = 0.5s
f = figure();
imagesc(0:0.001:20,1:2000,output(11).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=0.5s';
c = colorbar;
c.Limits = clim;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_05';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)


%% plot seizures for each stim condition
% Plot of interest: 29, 30, 21
f = figure();
imagesc(0:0.001:20,1:2000,output(29).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=0.78s';
c = colorbar;
c.Limits = clim;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_0781';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
imagesc(0:0.001:20,1:2000,output(30).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=0.78s';
c = colorbar;
c.Limits = clim;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_0782';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)

f = figure();
imagesc(0:0.001:20,1:2000,output(21).V);
a = gca;
a.XLabel.String = 'Time (s)';
a.YLabel.String = 'Neuron index';
a.Title.String = 'Model seizure t_{stim}=0.78s';
c = colorbar;
c.Limits = clim;
c.Label.String = 'Voltage (mV)';
a.FontSize = 18;
figname = 'modelseizure_0783';
saveas(f,['~/Desktop/' figname '.svg'])
close(f)



