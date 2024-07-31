classdef Stimulator < ExternalInput
    % A subclass of ExternalInput designed to give stimulation in the style
    % of the RNS device to a particular location

properties
    % Inherits properties from ExternalInput class:
    % Target:           An instance of NeuralNetwork where Stimulator is to
    %                   be applied
    % Random:           Structure that contains information about the
    %                   random part of the Stimulator
    % Deterministic:    Contains information about the deterministic part of the Stimulator
    % Tmax:             The expiration time of this instance of a
    %                   Stimulator
    % UserData:         Custom field for user-defined functions
    
end

properties (Dependent, Hidden)
    % isValid:          Determines whether stimulation is valid
    isValid

    % pulseNum:         How many total pulses are given with stimulation
    %                   parameters as given in param.PulseTrainParam
    pulseNum

end

properties (Hidden)
    % eventDetected:    Boolean that indicates whether an event has been
    %                   detected. This is for use with the EventDetector 
    %                   method.
    eventDetected       = false;

    % eventTimer:       Integer that indicates how far into an event you
    %                   are. This is for use with the EventDetector method.
    eventTimer          = 0;
    
    % eventStimTimer:   Integer that indicates how far into Stimulation 
    %                   you are after event onset. This is for use with the 
    %                   EventDetector method.
    eventStimTimer      = 0;

    % eventStimPending: Boolean that determines whether stimulation event 
    %                   has been triggered. This is for use with the 
    %                   EventDetector method.
    eventStimTriggered  = 0;

end

properties
    % param:            Experiment parameters
    param
end

% Included functions
methods
    EventDetector(St,x,t) % For detecting events (e.g. bursts, etc.)
end

methods
    function St = Stimulator(varargin) % Custom constructor function
        
        % Stimulator parameters (use UserData attribute)
        % .StimulatorTemplate       - Template used to create Stimulator
        % .ExternalInputType        - Used to define the type of ExternalInput
        % .PulseTrainParam          - Parameters used to create pulse train
        % .CalledFromConstructor    - Temporary field used to pass
        %                             construction of param through the
        %                             set.param function below
        St.param        =   struct('ExternalInputType','stimulator',...
                            'PulseTrainParam',struct(),...
                            'CalledFromConstructor',true...
                            );

        % Parse input for optional stimulator template
        p = inputParser;
        addParameter(p,'StimulatorTemplate','DefaultStimulatorParameters');
        parse(p,varargin{:});
        Template = p.Results.StimulatorTemplate;

        % Load stimulator parameters from template
        eval(Template);

        % Parse simulation params
        VarList = who;
        exclude = {'p','varargin','Template'};
        for i = 1:numel(VarList)
            if isa(eval(VarList{i}),'Stimulator') || ismember(VarList{i},exclude)
                continue; % Do not save instance itself in its own param field
            else
                St.param.(VarList{i}) = eval(VarList{i});
            end
        end

        % Tie St.Deterministic function to EvaluateStimulator method
        %%% The call to @(x,t) is a patch into the evaluation of the
        %%% Deterministic part of an ExternalInput; see
        %%% ExternalInput.Evaluate(Ext,t,dt)
        St.Deterministic = @(x,t) EvaluateStimulator(St,x,t);

        % Remove temporary param.CalledFromConstructor field
        St.param = rmfield(St.param,'CalledFromConstructor');

        % Clear out default UserData field inherited from ExternalInput
        St.UserData = [];

    end
end

methods
    function current = EvaluateStimulator(St,x,t) % Evaluate Stimulator output
        
        % Extract PulseTrainParam structure
        PulseTrainParam = St.param.PulseTrainParam;
        EventDetectorParam = St.param.EventDetectorParam;

        % Check time parameters; return nothing if outside of
        % stimulation window/stimulation location
        if t <= PulseTrainParam.delay.*1000, current = 0.*x(:,1); return,
        elseif (t >= (PulseTrainParam.delay.*1000 + PulseTrainParam.duration.*1000) && ~EventDetectorParam.eventDetector), current = 0.*x(:,1); return,
            % If EventDetector is on, continue stimulating after duration
            % in PulseTrainParam
        end

        % If event detection is activated and no event detected, return
        % nothing
        if EventDetectorParam.eventDetector
            EventDetector(St,x,t); % See if there is an event
            if ~St.eventDetected, current = 0.*x(:,1); return, end
        end

        % If phaseType of biphasic, include pulse modifier to double
        % pulse width
        assert(ismember(PulseTrainParam.phaseType,{'biphasic','monophasic'}),'Only biphasic and monophasic phaseTypes are allowed')
        pulseModifier = 1; % pulseModifier under the assumption of monophasic stimulation
        if strcmp(PulseTrainParam.phaseType,'biphasic'), pulseModifier = 2; end

        % Determine active stimulation neurons
        %%% This is set up to use each row of PulseTrainParam.location as
        %%% defining a set of stimulated neurons 
        loc = zeros(St.Target.n);
        for i = 1:size(PulseTrainParam.location,1)
            loc = loc | ((PulseTrainParam.location(i,2)*St.Target.n(1))>x(:,1) & x(:,1)>(PulseTrainParam.location(i,1)*St.Target.n(1)));
        end

        % Determine how far into stimulation
        ts = t - (PulseTrainParam.delay.*1000);
        
        % Adjust time into stim if eventDetector is on
        if EventDetectorParam.eventDetector && St.eventDetected % The latter condition should already be met
            ts = St.eventStimTimer;
        end

        % Determine point in burst cycle
        tb = mod(ts-1,round(1./PulseTrainParam.frequency.*1000))+1; % Time in burst
        %%% This way of computing has been phased out
        % tb = rem(ts-1,PulseTrainParam.pulsewidth.*pulseModifier)+1; % Time in burst


        % Kill current delivery if not yet ready for the next pulse
        if mod(ts-1,round(1./PulseTrainParam.frequency.*1000))+1 > PulseTrainParam.pulsewidth.*pulseModifier;
            current = 0.*x(:,1);
            return
        end
        
        % Return no current if there is not enough time left in the
        % Stimulation duration to fit another (full) pulse
        if ~EventDetectorParam.eventDetector && ((((PulseTrainParam.duration+PulseTrainParam.delay).*1000) - t) < floor(PulseTrainParam.pulsewidth*pulseModifier - tb))
            current = 0.*x(:,1);
            warning('A non-integer number of pulses was detected for this input. The last (partial) pulse will not be delivered')
            return
        end

        % Determine pulse output
        if tb > 0 && tb <= PulseTrainParam.pulsewidth*pulseModifier % Within the active pulse window
            if tb <= PulseTrainParam.pulsewidth % You are within the positive half of the pulse
                current = loc .* PulseTrainParam.magnitude;
            elseif tb > PulseTrainParam.pulsewidth % You are within the negative half of the pulse
                %%% Note that if the pulseModifier is 0, this
                %%% conditional is never met
                current = -1 .* loc .* PulseTrainParam.magnitude;
            end
        else
            current = 0.*x(:,1);
        end

    end

    function isValid = get.isValid(St)
        
        % Extract pulse train parameters
        PulseTrainParam = St.param.PulseTrainParam;
        [frequency,duration,magnitude,pulsewidth] = deal(PulseTrainParam.frequency,PulseTrainParam.duration,PulseTrainParam.magnitude,PulseTrainParam.pulsewidth);
        
        % Double pulse width for validity check if biphasic (to
        % include *both* phases)
        if strcmp(PulseTrainParam.phaseType,'biphasic'), pulsewidth = pulsewidth*2;
        elseif ~strcmp(PulseTrainParam.phaseType,'monophasic'), error('Only biphasic and monophasic pulseTypes are allowed.'), end
        
        % For stimulation to be valid (and meaningful), the
        % following must be true
        isValid = ...
            (duration > 0) && ... % Check basic nontriviality of stimulation parameters
            (magnitude >= 0) && ...
            (frequency > 0) && ...
            (pulsewidth > 0) && ...
            (pulsewidth <= (1./frequency*1000)) && ... % pulsewidth cannot be longer than period of stimulation
            (pulsewidth <= duration*1000) && ... % pulsewidth cannot be longer than duration of stimulation (note: this ensures at least 1 pulse)
            (floor(duration.*frequency) >= 1) && ... % Ensure at least one pulse
            (((duration.*frequency - floor(duration.*frequency))./frequency*1000 >= pulsewidth) || ((duration.*frequency - floor(duration.*frequency))./frequency*1000 == 0)); % Ensure an integer number of pulses fit into the duration (avoid partial pulses; note this guarantees a second full pulse for all stimulations)

        % Throw warning if magnitude 0
        if magnitude == 0, warning('Current stimulation magnitude is set at 0'), end

    end

    function pulseNum = get.pulseNum(St)
        
        % Extract pulse train parameters
        PulseTrainParam = St.param.PulseTrainParam;
        [frequency,duration,pulsewidth] = deal(PulseTrainParam.frequency,PulseTrainParam.duration,PulseTrainParam.pulsewidth);

        % Double pulse width for validity check if biphasic (to
        % include *both* phases)
        if strcmp(PulseTrainParam.phaseType,'biphasic'), pulsewidth = pulsewidth*2;
        elseif ~strcmp(PulseTrainParam.phaseType,'monophasic'), error('Only biphasic and monophasic pulseTypes are allowed.'), end

        % Return number of pulses in ParamArray
        pulseNum = floor(duration.*frequency)+((duration.*frequency - floor(duration.*frequency))./frequency*1000 >= pulsewidth);

    end

    function set.param(St,param)
        
        if isempty(St.param) || (isfield(param,'CalledFromConstructor') && param.CalledFromConstructor)
            St.param = param;
            return
        end

        % Create a copy of the Stimulator
        Tmp = copy(St);
        Tmp.Target = NeuralNetwork; % Add a temporary target to avoid warning messages on Tmp deletion

        % Add updated parameters
        Tmp.param = param;
        
        % Check validity of new parameters
        if Tmp.isValid
            % If isValid, change the St.param field as instructed
            St.param = param;
        else
            
            % Catch if the issue is default PulseTrainParams or updated
            % PulseTrainParams
            if isfield(St.param,'CalledFromConstructor') && St.param.CalledFromConstructor
                str = 'Default Stimulator.param field results';
            else
                str = 'Updating the Stimulator.param field would result';
            end

            % If not isValid, reject the change
            error('%s in invalid stimulation.',str)

        end

    end

end

methods (Hidden = true)

    function Ext = ConvertToExternalInput(St)
        
        % Create ExternalInput for folding
        Ext = ExternalInput;

        % Fold in properties of Stimulator to StExt
        fn = fieldnames(St);
        for i = 1:numel(fn)
            
            if strcmp(fn{i},'param')
                % param field must be handled separately, since Ext has no
                % such property
                Ext.UserData = St.param;
            elseif ~strcmp(fn{i},'UserData')
                Ext.(fn{i}) = St.(fn{i});
            end

        end

    end

end

end