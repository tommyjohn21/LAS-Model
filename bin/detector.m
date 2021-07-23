function [seizure,dP,fdP] = detector(O,dt)
%DETECTOR is a simple device to detect model seizures in Neural network O
%   INPUTS
%       O:  Neural network with voltages stored in O.Recorder.Var.V
%       dt: sampling length (ms)

%% Power in first derivative
% Extract voltage traces from window start up to current timestep
V = O.Recorder.Var.V(:,1:O.t);

% Numerically compute signal power in first derivative, sum across neurons
dP = diff(V,1,2).^2;
dP = sum(dP,1);

%% Low pass filter
fs = 1000*(1./dt); % Compute sampling frequency (Hz)
freq_cutoff = 0.001; % Cutoff frequency (Hz)
[b,a] = butter(1,(1./fs/2)); % First order, low-pass butterworth filter
fdP = filtfilt(b,a,dP); % Filtered power

%% Arbitrary cutoff
% Seizure threshold
% Note: we will set the seizure threshold very high, as we care more about
% detecting (binary) vs. not (as opposed to on-the-fly detection where
% timing matters)
thr = 2e4; % Arbitrary threshold
seizure = any(fdP>thr);

end

