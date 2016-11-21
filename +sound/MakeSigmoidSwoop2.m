%MakeSigmoidSwoop2.m   [Beep]=MakeSigmoidSwoop(SRate, SPL, StartFreq, EndFreq, Duration, Tau, Breaklen, [RiseFall=5] )
%
% Makes a sound:
%
% SRate:        sampling rate, in samples/sec
% Attenuation   
% StartFreq     starting frequency of the sound, in Hz
% EndFreq       ending   frequency of the sound, in Hz
% Duration      duration of the nonzero amplitude parts of the sound (excluding breaks), in ms
% Tau           Tau of frequency sigmoid, in ms
% Breaklen      number of ms of silence inserted into the middle of the tone
% RiseFall      width of half-cosine squared edge window, in ms
%
% Carlos Brody 25 Apr 05

function [Beep]=MakeSigmoidSwoop2(SRate, Att, StartFreq, EndFreq, Duration, Tau, Breaklen, RiseFall )

if Duration==0, Beep = []; return; end;


FilterPath=[GetParam('rpbox','protocol_path') filesep 'PPfilter.mat'];
PP = load(FilterPath);
PP=PP.PP;
   
   
Tau      = Tau/Duration;       % This is in relative units for zero2one vector below
Duration = Duration/1000;      % Turn everything into seconds
Breaklen = Breaklen/1000;
if nargin < 8, RiseFall = 0.005; else RiseFall = RiseFall/1000; end;

% Create a time vector.
t=0:(1/SRate):Duration;
t=t(1:(end-1));

zero2one  = (0:length(t)-1) / (length(t)-1); zero2one = tanh((zero2one - 0.5)/Tau);
zero2one = zero2one - min(zero2one); zero2one = zero2one/max(zero2one); 
logFrequency = log(StartFreq) + zero2one*(log(EndFreq) - log(StartFreq));
Frequency = exp(logFrequency);
Phi  = 2*pi*cumsum(Frequency)*mean(diff(t));

Attenuation = Att - ppval(PP, log10(Frequency));
Attenuation(find(Attenuation<0)) = 0;
% plot(Frequency, Attenuation);
% Attenuation = 5;

Beep = 1*(10.^(-Attenuation./20) .* sin(Phi));

% Edge ramp
Edge=MakeEdge( SRate, RiseFall );
LEdge=length(Edge);
Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
	
% Is there a break in the middle of the swoop?
Breaklen = round(Breaklen*SRate);
if Breaklen>0,
    [trash, u] = min(abs(zero2one-0.5));
    Beep1 = Beep(1:u);
    Beep2 = Beep(u+1:end);
    Beep1(end-LEdge+1:end) = Beep1(end-LEdge+1:end) .* Edge;
    Beep2(1:LEdge) = Beep2(1:LEdge) .* fliplr(Edge);
    
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
    