%% Scrape_converge
% This script takes dW matrices stored in dW_converge and extracts W and dW
% matrices for converge estimation across multiple realizations of
% repetitive stimulation

%% Set vardir and savedir
vardir = '~/Desktop/dW_converge/';
savedir = '~/Desktop/dW_converge_concat/';

%% Comb through dW_converge files
f = dir(vardir); % set vardir
vars = {'W','dW'}; % which variables to scrape

% Determine how many sims
sims = cellfun(@(fx)str2num(fx(strfind(fx,'dW_')+3:strfind(fx,'_converge')-1)),{f.name},'UniformOutput',false);
sims = unique([sims{:}]); % condense to find unique sims

for v = 1:numel(vars) % Cycle through vars
   
    for i = sims
        disp(['Processing ' vars{v} ' for simulation ' num2str(i)])
        
        % Find trials from sim number i
        trials = f(cellfun(@(fx) contains(fx,['dW_' num2str(i) '_converge']),{f.name}));
        
        % Ensure appropriate order
        [~,ix] = sort(cellfun(@(tx)str2num(tx(strfind(tx,'sim_')+4:strfind(tx,'.mat')-1)),{trials.name}));
        trials = trials(ix);
        
        for j = 1:numel(trials)
            
            % Load trial record
            disp(['...loading ' trials(j).name ])
            load([vardir trials(j).name])
            
            if j == 1 % Overwrite output variable on first pass
                eval([vars{v} '=zeros([size(o.(vars{v})) numel(trials)]);']);
            end
            
            % Write out variable of interest on this cycle
            eval([vars{v} '(:,:,' num2str(j) ') = o.' vars{v} ';']);
            
        end
        
        % Write out accumulated variable
        save([savedir 'dW_' num2str(i) '_converge_concat_' vars{v} '.mat'],vars{v},'-v7.3')
        
        % Clear workspace
        eval(['clearvars ' vars{v}])
        
    end
    
end