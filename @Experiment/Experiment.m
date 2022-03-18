classdef Experiment < handle & matlab.mixin.Copyable
    % Each experiment is performed on multiple realizations of a particular
    % simulation
    
    properties
        param = struct(...              % Experiment parameter structure
            'name','',...               % Name of experiment
            'class','Experiment',...    % Class of experiment (e.g. ThresholdExperiment)
            'server',false...           % Detect if on server
            );
        S                               % Simulation object used for Experiment                      
    end
    
    methods
        % Initialization
        function E = Experiment(ExperimentName)
            %%% Experiement file handling
            E.param.name = ExperimentName;  % Name of experiment
            E.param.vardir = VarDir(E);     % Detect variale directory
            E.param.expdir = ExpDir(E);     % Detect experiment directory
            
            %%% Miscellaneous experiment settings
            E.param.server = Server(E); % Detect if on server
        end
        
    end
    
    methods (Hidden = true)
                
        %%% File handing methods
        % Detect if Experiment running on server
        function server = Server(E)
            server = strcmp(computer,'GLNXA64'); % detect server
        end
        
        % Default variable directory
        %   This is base directory for *all* experiments
        %   Default: home directory on server, Desktop on local
        function vardir = VarDir(E)
            vardir = '~/'; % Def
            if ~Server(E), vardir = [vardir 'Desktop/']; end
        end
        
        % Default experiment directory
        %   This is directory for *particular* experiment
        function expdir = ExpDir(E)
            expdir = [VarDir(E) E.param.name '/'];
        end
        
        % Update variable and experiment directories as needed
        function UpdateDir(E,vardir)
            vardir = ['~/' vardir '/']; % Default
            if ~Server(E), vardir = strrep(vardir,'~/','~/Desktop/'); end
            E.param.vardir = vardir;
            E.param.expdir = [vardir E.param.name '/'];
        end
        
    end
    
end

