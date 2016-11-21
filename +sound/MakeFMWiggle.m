%MakeFMWiggle.m  [monosound]=MakeFMWiggle(SRate, Att, Duration, CarrierFreq, ...
%                         FMFreq, FMAmp, [RiseFall=3] {'volume_factor', 1, 'PPfilter_name', ''})
%
% Makes a sinusoidally wiggling frequency pure tone (i.e., a sinusoidally frequency modulated sine wave):
%
% SRate:        sampling rate, in samples/sec
% Attenuation
% Duration      length of sound, in secs
% CarrierFreq   mean frequency of the sound, in Hz
% FMFreq        frequency at which the Carrier frequency will be modulated, in Hz
% FMAmp         amplitude of the FM modulation, in Hz.
% RiseFall      width of half-cosine squared edge window, in ms
%
% OPTIONAL ARGS:
% --------------
%
%  volume_factor       default 1; How much to multiply the signal amplitude by
%
%  PPfilter_fname      full path and filename, including .mat, of a
%                      file containing filter parameters from speaker
%                      calibration. If this parameter is left empty, the
%                      location is drawn from exper's rpbox protocol_path.
%

% Carlos Brody Aug 07

function [Beep]=MakeFMWiggle(SRate, Att, Duration, CarrierFreq, FMFreq, ...
                                  FMAmp, RiseFall, varargin) 
if nargin<=7, varargin = {}; end;
pairs = { ...
  'volume_factor'        1   ; ...
  'PPfilter_fname'      ''   ; ...
}; parseargs(varargin, pairs);
   
   
if Duration==0, Beep = []; return; end;


if isempty(PPfilter_fname)   FilterPath=['Protocols' filesep 'PPfilter.mat'];
else                         FilterPath = PPfilter_fname;
end;
PP = load(FilterPath); PP=PP.PP;
      
if nargin < 7, RiseFall = 0.003; else RiseFall = RiseFall/1000; end;

% Create a time vector.
t=0:(1/SRate):Duration;
t=t(1:(end-1));

Frequency = CarrierFreq + FMAmp*sin(2*pi*FMFreq*t);
Phi  = 2*pi*cumsum(Frequency)*mean(diff(t));


% Attenuation = Att - ppval(PP, log10(Frequency));
% plot(Frequency, Attenuation);
% Attenuation = 5;

[U, I, J] = unique(Frequency);
% Attenuation = Att - ppval(PP, log10(U));
Attenuation = Att - 30*ones(size(U));
Attenuation(find(Attenuation<0)) = 0;

Beep = 10.^(-Attenuation./20);
Beep = Beep(J).* sin(Phi);
Beep = Beep.*volume_factor;

% Edge ramp
Edge=MakeEdge( SRate, RiseFall );
LEdge=length(Edge);
Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
	
return;


% -------------------------------------------------------------
%
%
%
% -------------------------------------------------------------

    

function [envelope] = MakeEdge(srate, coslen)

    t = (0:(1/srate):coslen)*pi/(2*coslen);
    envelope = (cos(t)).^2;
    return;
    