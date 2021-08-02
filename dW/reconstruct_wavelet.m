function [w] = reconstruct_wavelet(x,data)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Expand x
shift = x(1);
scale = x(2);
sigma = x(3);
freq = x(4);
amp = x(5);
amph = x(6);

if amp<0
   data=data';
end

n = size(data,1);

% Create meshgrid
[x,y]=meshgrid(1:n,1:n);

% Build you sigmoidal boundary
sigmoid = @(x,scale,shift) 1./(1+exp(-(x-shift)./scale));
sigsheet = @(scale,shift) sigmoid(x,scale,shift).*(1-sigmoid(x,scale,n-shift)).*sigmoid(y,scale,shift).*(1-sigmoid(y,scale,n-shift));
sg = sigsheet(scale,shift);
sg = sg./max(sg(:)); % Normalize

% Build gaussian
g = normpdf((x*cos(-pi/4)+y*sin(-pi/4)),0,sigma)./normpdf(0,0,sigma);

% Create scaled/shifted sine waves
s = (2*sigmoid(amp,0.1,0)-1).*sin((-(cos(-pi/4).*x + sin(-pi/4).*y).*(2*pi*freq)));
sh = (2*sigmoid(amph,0.1,0)-1).*sin((-(cos(-pi/4).*x + sin(-pi/4).*y).*(4*pi*freq)));

% Wavelet matrix
w = sg.*g.*(s+sh) + 1;

% Compute sum-squared error
sse = sum((data(:)-w(:)).^2);

end

