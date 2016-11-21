% [click] = MakeClick({'sigma', 0.0001}, {'power', 1.2})
%
% Makes a single, sharp, brief, broad-band "click!" of amplitude 0.7. 
% 
% Gets the sampling rate from protocolobj; then makes a
% Gaussian-like function, exp(-|t|^power / (2*sigma^power)) : a
% Guassian would have power=2; then takes the derivative of this
% function. This is returned, with a length from -5*sigma to +5*sigma.
%
% If you want two settings that are different, clearly discriminable to
% the human ear, audible to the rat ear, most likely clearly discriminable
% to the rat ear, and playable at a 50KHz sampling rate, try: sigma=0.0002
% and power=1.5; versus sigma=0.00004, power=1.5. (That is, power 1.5 for
% both cases, and sigma 200 microseconds in case one, 40 microseconds in
% case two.) Case one has peak power at 1KHz and 2KHz; case two has peak
% power at 5kHz and 10kHz.
%
% 
% OBLIGATORY PARAMETERS:
% ----------------------
%
% None
%
% OPTIONAL PARAMETERS:
% --------------------
%
%  sigma, in milliseconds
%
%  power
%

% CDB Feb 06


function [click] = MakeClick(varargin)
   
   sigma = [];
   power = [];
   pairs = { ...
     'sigma'       0.0001  ; ...
     'power'        1.2    ; ...
  }; parseargs(varargin, pairs);

srate = get_generic('sampling_rate');

t = 0:(1/srate):10*sigma; 
click = diff(exp(-abs(t-5*sigma).^power / (2*sigma.^power)));
click = 0.7*click/max(abs(click));

        