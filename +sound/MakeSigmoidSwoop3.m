%MakeSigmoidSwoop3.m  [monosound]=MakeSigmoidSwoop3(SRate, Att, StartFreq, ...
%                         EndFreq, BeforeBreakDuration, AfterBreakDuration,...
%                         Breaklen, Tau, [RiseFall=3] )
%
% Makes a sound:
%
% SRate:        sampling rate, in samples/sec
% Attenuation   
% StartFreq     starting frequency of the sound, in Hz
% EndFreq       ending   frequency of the sound, in Hz
% BeforeBreakDuration    duration of the first nonzero amplitude
%                          parts of the sound (excluding breaks), in ms 
% AfterBreakDuration     duration of the second nonzero amplitude
%                          parts of the sound (excluding breaks), in ms 
% Breaklen      number of ms of silence inserted into the middle of the tone
% Tau           Tau of frequency sigmoid, in ms
% RiseFall      width of half-cosine squared edge window, in ms
%
% OPTIONAL ARGS:
% --------------
%
%  F1_volume_factor    default 1; How much to multiply StartFreq part
%                      of signal by.
%
%  F2_volume_factor    default 1; How much to multiply EndFreq part
%                      of signal by.
%
%  PPfilter_fname      full path and filename, including .mat, of a
%                      file containing filter parameters from speaker
%                      calibration. If this parameter is left empty, the
%                      location is drawn from exper's rpbox protocol_path.
%
% The transition from F1_volume_factor to F2_volume_factor follows the
% sigmoid used for everything else.
%

% Carlos Brody 28 Mar 06

function [Beep]=MakeSigmoidSwoop3(SRate, Att, StartFreq, EndFreq, ...
                                  BeforeDuration, AfterDuration, Breaklen, ...
                                  Tau, RiseFall, varargin) 
if nargin<=9, varargin = {}; end;
pairs = { ...
  'F1_volume_factor'     1   ; ...
  'F2_volume_factor'     1   ; ...
  'PPfilter_fname'      ''   ; ...
}; parseargs(varargin, pairs);
   
   
if BeforeDuration==0 & AfterDuration==0, Beep = []; return; end;


if isempty(PPfilter_fname)
   FilterPath=['Protocols' filesep 'PPfilter.mat'];
else
   FilterPath = PPfilter_fname;
end;
PP = load(FilterPath);
PP=PP.PP;
   
   
BeforeDuration = BeforeDuration/1000;      % Turn everything into seconds
AfterDuration  = AfterDuration/1000;       
Duration       = BeforeDuration + AfterDuration;
BreakFraction  = BeforeDuration/Duration;
Breaklen       = Breaklen/1000;
if nargin < 9, RiseFall = 0.003; else RiseFall = RiseFall/1000; end;

Tau      = Tau/(1000*Duration); % This is in relative units of zero2one vector

% Create a time vector.
t=0:(1/SRate):Duration;
t=t(1:(end-1));

zero2one  = (0:length(t)-1) / (length(t)-1); 
zero2one = tanh((zero2one - BreakFraction)/Tau);
volume_factor = (F2_volume_factor - F1_volume_factor)*(zero2one+1)/2 + ...
    F1_volume_factor;
zero2one = zero2one - min(zero2one); zero2one = zero2one/max(zero2one); 
logFrequency = log(StartFreq) + zero2one*(log(EndFreq) - log(StartFreq));
Frequency = exp(logFrequency);
Phi  = 2*pi*cumsum(Frequency)*mean(diff(t));


% Attenuation = Att - ppval(PP, log10(Frequency));
% plot(Frequency, Attenuation);
% Attenuation = 5;

[U, I, J] = unique(Frequency);
Attenuation = Att - ppval(PP, log10(U));
Attenuation(Attenuation<0) = 0;

Beep = 10.^(-Attenuation./20);
Beep = Beep(row(J)).* sin(Phi);
Beep = Beep.*volume_factor;

% Edge ramp
Edge=MakeEdge( SRate, RiseFall );
LEdge=length(Edge);
Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
	
% Is there a break in the middle of the swoop?
Breaklen = round(Breaklen*SRate);
if Breaklen>0,
    [trash, u] = min(abs(zero2one-BreakFraction));
    Beep1 = Beep(1:u);
    Beep2 = Beep(u+1:end);
    if length(Beep1) > LEdge;
       Beep1(end-LEdge+1:end) = Beep1(end-LEdge+1:end) .* Edge;
    end;
    if length(Beep2) > LEdge,
       Beep2(1:LEdge) = Beep2(1:LEdge) .* fliplr(Edge);
    end;
    
    Beep = [Beep1 ones(1, Breaklen)*Beep1(end) Beep2];
end;
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
    
    function x=row(x)
        x=x(:)';
        