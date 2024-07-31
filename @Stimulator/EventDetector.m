function EventDetector(St,x,t)
    % Function built for detecting events (e.g. bursts) to time stimulation
    % to event detection
    
    % Object handles/variables for convenience
    O = St.Target;
    R = O.Recorder;
    PulseTrainParam = St.param.PulseTrainParam;

    % Pull voltage trace for event analysis
    V = R.Var.V(:,1:R.Idx-1);
    
    % Determine active stimulation/sensing neurons for stimulator
    %%% This is set up to use each row of PulseTrainParam.location as
    %%% defining a set of stimulated neurons
    if sum(any(~[PulseTrainParam.location == repmat(St.param.EventDetectorParam.sensingLocation,size(PulseTrainParam.location,1),1)]))>0 && (t == (PulseTrainParam.delay*1000)+1) % Only warn on the first time through
        warning('eventDetector sensing and Stimulator location are different.')
    end

    if size(St.param.EventDetectorParam.sensingLocation,1)>1
        warning('More than one sensingLocation is used. Code is not written for this contingency.')
        % You need to debug eventDetector code to make sure events are
        % properly detected with more than one sensing location
        keyboard
    end
    
    
    loc = [];
    for i = 1:size(St.param.EventDetectorParam.sensingLocation,1)
        loc = [loc ((St.param.EventDetectorParam.sensingLocation(i,2)*St.Target.n(1))>x(:,1) & x(:,1)>(St.param.EventDetectorParam.sensingLocation(i,1)*St.Target.n(1)))];
    end
    
    % Detect event separately for each contiguous Stimulator site
    for i = 1:size(loc,2)
        
        % If more than one sensing location desired, you'll have to figure
        % out how to handle it
        if size(loc,2) > 1
            error('Loop is not yet written for more than one contiguous sensing site')
        end

        if ~St.eventStimTriggered % Only search for events if not already triggered
            
            sn = loc(:,i) ==1 ; % sensing neurons

            % Reconstruct Spike matrix
            timeWindow = 40; % Look over the last n timesteps to find a burst
            sp = zeros(size(R.Var.V(:,1:R.Idx-1),1),timeWindow);
            Sp = R.SBuffer(R.Idx-timeWindow+1:R.Idx);
            for j = 1:numel(Sp)
                if ~isempty(Sp{j})
                    sp(Sp{j},j) = 1;
                end
            end
            
            % Spike coordinates
            % sp1 = cell2mat(cellfun(@(sp,n) [sp,ones(size(sp))*n] ,Sp,num2cell(1:numel(Sp)),'un',0).');
            % c1 = cell2mat(cellfun(@(n)circshift(sp(n,:),timeWindow-prod([max(sp1(sp1(:,1)==n,2)) ~isempty(max(sp1(sp1(:,1)==n,2)))])),num2cell(find(sn)),'UniformOutput',false));
            % c2 = courseGrain(c1(:,1:end-1),true(1,size(c1,1)),size(c1,2)-1,5,3);

            % Mask for n timesteps after Spike
            maskWindow = 30;
            sp = sp(sn,:); % reduced Spike matrix
            [ix,jx] = find(sp);
            for j = 1:numel(ix)
                sp(ix(j),jx(j):min([jx(j)+maskWindow,size(sp,2)])) = 1;
            end

            % Edit small voltage trace
            Vn = V(sn,end-timeWindow+1:end); % voltage trace in sensing neurons
            Vn(sp == 1) = NaN;

            % Event detection (burst)
            % In = hanning(timeWindow).*(nanmean(Vn)-mean(nanmean(Vn))).';
            % In = abs(fft(In-mean(In)));
            % event = sum(In(2:5)) > 150 && sum(In(2:5)) < 155;

            In = imgaussfilt(double(isnan(Vn)),5)>0.5;
            %%% This is your first burst detection algorithm
            % event = any(sum(In)>10);
            %%% This is your second burst detection algorithm
            % event = sum(In,"all") > 50 && sum(In,"all") < 300;
            %%% This is your third burst detection algorithm
            event = any(sum(In)>15) && sum(In,"all") < 250;
            % event = event && ((([1:size(In,1)] - size(In,1)./2)>0)-0.5)./0.5*sum(In,2)>0; % Hold if traveling wave is moving away from focus

            % Event detection 2.0
            % Vcg_on = courseGrain(V,sn,800,3,20); % Course graining to capture resonant activity buildup 
            % Vcg_off = courseGrain(V,sn,100,3,10); % Course graining to capture moments of (relative) quiesence
            % event = detectEvent(Vcg_on,Vcg_off);

        end
                   
        if (exist('event','var') && event) || ((St.eventStimTimer > 0 || St.eventStimTriggered) &&...
                (St.eventStimTimer <= St.param.EventDetectorParam.stimDuration || rem(St.eventStimTimer,round(1./St.param.PulseTrainParam.frequency.*1000))~=0))...
            St.eventDetected = true;
            St.eventStimTriggered = true;
            if (St.eventTimer < St.param.EventDetectorParam.stimDelay)
                St.eventDetected = false;
                St.eventStimTimer = -1;
            end
            St.eventTimer = St.eventTimer + 1; % Time how long you are into an event
            St.eventStimTimer = St.eventStimTimer + 1;
        else
            St.eventDetected = false;
            St.eventStimTriggered = false;
            if St.eventTimer > 0
                St.eventTimer = 0; % Reset event timer
            end
            if St.eventStimTimer > 0
                St.eventStimTimer = 0; % Reset stimulation timer
            end
        end

    end

    function Vcg = courseGrain(V,sn,timeWindow,neuronGrain,timeGrain)
        
        % Default course graining parameters
        % timeWindow = 800; % look over last 800 ms
        % neuronGrain = 3; % number of neurons to grain over
        % timeGrain = 20; % number of time points to grain over
        assert(mod(timeWindow,timeGrain)==0,'timeWindow must be an integer multiple of timeGrain')
        assert(mod(sum(sn),neuronGrain)==0,'Number of sensing neurons must be an integer multiple of neuronGrain')
        
        % Cut out pertinent range from V
        Vn = V(sn,end-timeWindow+1:end);

        % Create course-graining matrices
        %%% Generate Toeplitz matrices
        neuronMat = toeplitz([ones(1,neuronGrain) zeros(1,sum(sn)-neuronGrain)]);
        timeMat = toeplitz([ones(timeGrain,1); zeros(timeWindow-timeGrain,1)]);
        %%% Cut out grains
        neuronMat = neuronMat(neuronGrain:neuronGrain:end-neuronGrain,:);
        timeMat = timeMat(:,timeGrain:timeGrain:end-timeGrain);
        
        % Do the course-graining
        Vcg = (neuronMat./(unique(sum(neuronMat,2))))*Vn*(timeMat./unique(sum(timeMat,1)));

    end

    function event = detectEvent(Vcg_on,Vcg_off)
        
        % Threshold values for event detection in ON state
        lowThresholdOn = 1e3;
        highThresholdOn = 1.5e3;
        highThresholdOff = 15;
        freqRange = 5; % first n frequencies of power spectrum (EXCLUDING DC component)
        
        % Compute frequency spectrum, INCLUDING DC component
        freqSpectrumOn = mean(abs(fft((Vcg_on-mean(Vcg_on,2)).*hann(size(Vcg_on,2)).'+mean(Vcg_on,2),[],2)).^2);
        freqSpectrumOff = mean(abs(fft((Vcg_off-mean(Vcg_off,2)).*hann(size(Vcg_off,2)).'+mean(Vcg_off,2),[],2)).^2);

        % Cut out non-redundant pieces, EXCLUDING DC component
        freqSpectrumOn = freqSpectrumOn(2:end); % exclude DC component
        freqSpectrumOn = freqSpectrumOn(1:numel(freqSpectrumOn)./2); % exclude last (redundant) half of power spectrum
        freqSpectrumOff = freqSpectrumOff(2:((numel(freqSpectrumOff)-1)./2)+1);
    
        % Event detection
        eventOn = (sum(freqSpectrumOn(1:freqRange)) > lowThresholdOn && ...
            sum(freqSpectrumOn(1:freqRange)) < highThresholdOn);
        eventOff = sum(freqSpectrumOff) < highThresholdOff && mean(Vcg_off,"all")<-60;

        event = eventOn && ~eventOff;

    end

end