function [ theta, phi ] = torusreject(n)
%generate sampled angles [0,2PI) 
%from method detailed in Sampling From A Manifold by Persi Diaconis, Susan Holmes and Mehrdad Shahshahani
%R=.5 r=.25

x=2*pi*rand(4*n,1); 
y=(1/pi)*rand(4*n,1); 
fx=(1+(.25/.5)*cos(x))/(2*pi); 

theta=x(y<fx); 
theta=theta(1:n,1); 
phi=2*pi*rand(n,1); 
end
