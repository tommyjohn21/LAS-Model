classdef PlasticityExperiment < Experiment
    % Experiment to generate updating matrices (i.e. dW matrices) to
    % reweight network connectivity  after a seizure with implementation of
    % STDP
    
    properties
        % Inherits properties from Experiment class:
        %   S:        Simulation object used in experiment
        %   param:    Experiment parameters
        
    end
    
    properties (Hidden = true)
       
        parsed = 0;             %   Boolean that determines whether STDP 
                                %   matrices in PlasticityExperiment have been Parsed
        
        StandardSTDP = false;   %   Asserts that only the first Projection 
                                %   (excitatory in DefaultRecurrentConnection) 
                                %   has STDP enabled; this is to be used as a 
                                %   catch for further development if other 
                                %   Projections (e.g. inhibitory) have STDP enabled)
                                
        pca = struct(...        %   Structure to hold results of PCA across weighting matrices
            'c',[],...          %       c: coeff matrices (see pca documentation: help pca)
            's',[],...          %       s: scores
            'l',[]...           %       l: latent
        );
        
    end
    
    methods
        
        % Constructor method
        function E = PlasticityExperiment(ExperimentName,varargin)
            % Construct Experiment object with given name/type
            E = E@Experiment(ExperimentName);
            E.param.class = class(E);
            
            % Parse input for optional experiment template
            p = inputParser;
            addParameter(p,'ExperimentTemplate','DefaultPlasticityExperimentParameters');
            parse(p,varargin{:});
            E.param.ExperimentTemplate = p.Results.ExperimentTemplate;
            
            % Load experiment parameters from template
            eval(E.param.ExperimentTemplate);
            
            % Parse simulation params
            VarList = who;
            exclude = {'ExperimentName','p','varargin'};
            for i = 1:numel(VarList)
                if isa(eval(VarList{i}),'PlasticityExperiment') || ismember(VarList{i},exclude)
                    continue; % Do not save instance itself in its own param field
                else
                    E.param.(VarList{i}) = eval(VarList{i});
                end
            end
            
        end
        
        function Load(E) % Load results of PlasticityExperiment
            
            % Load contents of expdir associated with E
            f = dir(fullfile(E.param.expdir,'PlasticityExperiment-*.mat'));
            
            % Sort in numerical order (c.f. character/alphabetical order)
            [~,idx] = sort(arrayfun(@(s)str2num(s.name(22:end-4)),f));
            f = f(idx);
            
            % Clear param field in E
            E.param = [];
            E.S = [];
            
            % Loading bar
            fprintf('Loading: [          ]')
            
            for i = 1:numel(f)
                % Update loading bar
                if rem(i./numel(f)*100,10) == 0
                   fprintf([repmat('\b',1,11) repmat('-',1,round(i./numel(f)*100)./10) repmat(' ',1,10-round(i./numel(f)*100)./10) ']'])
                end
                
                % Load Experiment file
                PE = load(fullfile(f(i).folder,f(i).name),'E');
                % Concatenate params and Simulations
                E.param = [E.param PE.E.param];
                E.S = [E.S PE.E.S];
            end
            fprintf('\n')
            
            % Ensure StandardSTDP
            EnsureStandardSTDP(E)
            
        end
        
        % Include Parse method
        Parse(E)
        
        % Ensure StandardSTDP
        function EnsureStandardSTDP(E)
            for i = 1:numel(E.S)
                
               % Assert 3 Projections
               assert(numel(E.S(i).O.Proj.In)==3);
               
               % Assert Projection types and STDP Enabled
               for j = 1:3
                   if j == 1
                       assert(E.S(i).O.Proj.In(j).Type=='E')
                       assert(E.S(i).O.Proj.In(j).STDP.Enabled==1)
                   else
                       assert(E.S(i).O.Proj.In(j).Type=='I')
                       assert(E.S(i).O.Proj.In(j).STDP.Enabled==0)
                   end
               end  
            end
            
            % If the above passed assertion, can rely on Proj(1) being the
            % relevant for STDP; set hidden property StandardSTDP to true
            E.StandardSTDP = true;
        end
        
        % Function to return weight matrix from one instance of
        % PlasticityExperiment
        function dW = Retrieve(E,i,varargin)
            
            % Rotation flag
            rotate = true;
            if numel(varargin)>0
               rotate = varargin{1}; % Pass boolean false into varargin for non-rotated matrices
            end
            
            % Assertions
            assert(E.StandardSTDP,'Code is only written for StandardRecurrentConnection configuration')
            assert(E.parsed,'PlasticityExperiment must be parsed to retrieve dW (e.g. Parse(E))')
            assert(all(sum(E.pca.c(:,1:2)>0)./size(E.pca.c,1) == [0.5 1]),'1st PCA axis must change sign on rotation, and 2nd PCA axis must not. Consider if 1st and 2nd PCA componenets are reversed')
            
            % Patch to retain earlier nomenclature of rotated matrices
            if floor(i./numel(E.S)) == 1
                warning('%d matrices were provided, and matrix %d was requested. Returning matrix %d with rotation applied if requested (default: rotate on).',numel(E.S),i,rem(i,numel(E.S)))
                assert(E.pca.c(i,1)>0); % Check that you are flipping over the right axes
                i = rem(i,numel(E.S));
                assert(E.pca.c(i,1)<0); % Check that you are flipping over the right axes
            end
            if floor(i./numel(E.S)) ~= 0; error('Matrix %d is out of range 1:%d and cannot be retrieved',i,numel(E.S)); end
            
            % Retrieve and rotate matrix if needed
            dW = E.S(i).O.Proj.In(1).STDP.W;
            if E.pca.c(i,1)<0
                if rotate % Enabled by default
                    dW = rot90(dW,2);
                else
                    warning('Rotation is warranted by not applied. Rotate flag set to false.')
                end
            end

        end
        
        % Function to return first two pca coordinates for plotting
        % (rotated as apporpriate)
        function coordinates = Coord(E,varargin)
            
            % Assertions (taken from Retrieve function)
            assert(E.StandardSTDP,'Code is only written for StandardRecurrentConnection configuration')
            assert(E.parsed,'PlasticityExperiment must be parsed to retrieve dW (e.g. Parse(E))')
            assert(all(sum(E.pca.c(:,1:2)>0)./size(E.pca.c,1) == [0.5 1]),'1st PCA axis must change sign on rotation, and 2nd PCA axis must not. Consider if 1st and 2nd PCA componenets are reversed')
            
            % Pull (sign-corrected, i.e. rotated) coordinates
            coordinates = abs(E.pca.c(:,1:2)); % Return sign-corrected entries
            coordinates = coordinates(1:numel(E.S),:); % Return the first 1:N (i.e. number of Simulations)
            
            if ~isempty(varargin)
                % Use varargin for specific coordinates
                assert(all(floor(varargin{1}) == varargin{1}),'Argument to Coord must be integer or array of integers!'); % Assert that varargin{1} is composed of integers
                coordinates = coordinates(varargin{1},:);
            end
            
        end
        
        
    end
    
end