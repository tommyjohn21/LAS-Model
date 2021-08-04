% This script is meant to generate two scenarios with the same stimulation:
% seizures and not; the plan is to look at the variable generated by each
% scenario to look for stigmata of transition into seizure state

if ~exist('s','var')
    s.seizure = 0;
    while ~s.seizure
        s=detector_Exp1(1,0.78,20);
    end
end

if ~exist('ns','var')
    ns.seizure=1;
    while ns.seizure
        ns=detector_Exp1(1,0.78,20);
    end
end

t = 20001;

%% Investigate dynamics at bifucation point