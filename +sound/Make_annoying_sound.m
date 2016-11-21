function [snd] = Make_annoying_sound(Duration, varargin)

% Makes an annoying sound to be played at the beginning of the time-out
% penalty consisting of 10 superimposed pure tones of dissonant frequencies.
% This sound is meant to signal "You did something wrong RIGHT NOW!" to be
% followed by the regular white noise time-out period.
%
% Input params:
% Duration:  duration in sec of annoying sound
% 
% varargin:
% volume_factor:  multiplicative in [0, 10] by which sound is scaled to adjust volume
%                 '1' is meant to be a reasonable volume (pretty loud)
%
% Bing, Aug 2007

pairs = { ...
     'volume_factor'     1   ; ...
  }; parseargs(varargin, pairs);

srate = get_generic('sampling_rate');
amp = 0.15;

% make time vector
t = 0:1/srate:Duration;
t = t(1:(end-1));

snd = zeros(size(t));
freq = log2([3 7 11 13 23 29 53 73 97 131])+5; % frequencies in KHz

% construct sound by superimposing pure tones
for i = 1:10,
    snd = snd + sin(t * srate / (2*pi) * freq(i));
end;

% adjust volume
snd = snd * amp * volume_factor;