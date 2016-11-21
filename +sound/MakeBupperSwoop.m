%MakeBupperSwoop.m  [monosound]=MakeBupperSwoop(SRate, Att, StartFreq, ...
%                         EndFreq, BeforeBreakDuration, AfterBreakDuration,...
%                         Breaklen, Tau)
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
%  Stereo              default 0; returns a mono sound. If 1, returns a
%                      a stereo sound
%
%  F1_loc_factor       Only relevant if Stereo==1. Default is 0,
%                      meaning no bias to Left or Right. A value of 1
%                      means bias completely to the left; a value of -1
%                      means bias completely to the right.
%
%  F2_loc_factor       As F1_loc_factor, but for sound F2.
%
%  F1_lead_time        Only relevant if Stereo==1. This is a time
%                      advance, in ms, with which the Left signal is generated
%                      compared to the Right signal. For a rat's head
%                      size, 0.1 ms should be good. If this is left
%                      empty, then it will be set equal to 0.1*F1_loc_factor.
%
%  F2_lead_time        As F1_lead_time, but for sound F1. If this is left
%                      empty, then it will be set equal to 0.1*F2_loc_factor.
%
% The transitions from F1 to F2 in _volume_factor, _loc_factor, and
% _lead_time all follow the sigmoid used for everything else.
%


% Carlos Brody Apr 06; _loc_factor and _lead_time added May 06

function [Beep]=MakeBupperSwoop(SRate, Att, StartFreq, EndFreq, ...
                                  BeforeDuration, AfterDuration, Breaklen, ...
                                  Tau, varargin) 

if nargin<=8, varargin = {}; end;
pairs = { ...
  'F1_volume_factor'     1   ; ...
  'F2_volume_factor'     1   ; ...
  'Stereo'               0   ; ...
  'F1_loc_factor'        0   ; ...
  'F2_loc_factor'        0   ; ...
  'F1_lead_time'        []   ; ...
  'F2_lead_time'        []   ; ...
  'PPfilter_fname'      ''   ; ...
  'bup_width'            5   ; ...
}; parseargs(varargin, pairs);

if isempty(F1_lead_time), F1_lead_time = -0.1*F1_loc_factor; end;
if isempty(F2_lead_time), F2_lead_time = -0.1*F2_loc_factor; end;

if BeforeDuration==0 & AfterDuration==0, Beep = []; return; end;
   
   
BeforeDuration = BeforeDuration/1000;      % Turn everything into seconds
AfterDuration  = AfterDuration/1000;       
Duration       = BeforeDuration + AfterDuration;
BreakFraction  = BeforeDuration/Duration;
Breaklen       = Breaklen/1000;
F1_lead_time   = F1_lead_time/1000;
F2_lead_time   = F2_lead_time/1000;

Tau      = Tau/(1000*Duration); % This is in relative units of zero2one vector

% Create a time vector.
t=0:(1/SRate):Duration;
t=t(1:(end-1));

zero2one  = (0:length(t)-1) / (length(t)-1); 
zero2one = tanh((zero2one - BreakFraction)/Tau);
volume_factor = (F2_volume_factor - F1_volume_factor)*(zero2one+1)/2 + ...
    F1_volume_factor;
loc_factor    = (F2_loc_factor    - F1_loc_factor)   *(zero2one+1)/2 + ...
    F1_loc_factor;
lead_time     = (F2_lead_time     - F1_lead_time)    *(zero2one+1)/2 + ...
    F1_lead_time;
zero2one = zero2one - min(zero2one); zero2one = zero2one/max(zero2one); 
logFrequency = log(StartFreq) + zero2one*(log(EndFreq) - log(StartFreq));
Frequency = exp(logFrequency);
Phi  = 2*pi*(cumsum(Frequency)-Frequency(1))*mean(diff(t));
if Stereo,
   Left_Phi  = 2*pi*cumsum(Frequency)*mean(diff(t+lead_time));
   Right_Phi = Phi;

   left_loc_factor  = min(1+loc_factor, 1);
   right_loc_factor = min(1-loc_factor, 1);
   
   Left_Beep = MakeSound(Left_Phi, SRate, Att, Breaklen, BreakFraction, ...
                         left_loc_factor.*volume_factor, PPfilter_fname, ...
                         zero2one);  
   Right_Beep = MakeSound(Right_Phi, SRate, Att, Breaklen, BreakFraction, ...
                         right_loc_factor.*volume_factor, PPfilter_fname, ...
                         zero2one);  

   ldiff = length(Left_Beep) - length(Right_Beep);
   if     ldiff < 0, Left_Beep  = [Left_Beep  zeros(1, -ldiff)];
   elseif ldiff > 0, Right_Beep = [Right_Beep zeros(1,  ldiff)];
   end;
   
   Beep = [Left_Beep ; Right_Beep];
else
   Beep = MakeSound(Phi, SRate, Att, Breaklen, BreakFraction, ...
                    volume_factor, PPfilter_fname, ...
                         zero2one, bup_width);  
end;



return;

% -------------------------------------------------------------
%
%
%
% -------------------------------------------------------------

function [Beep] = MakeSound(Phi, SRate, Att, Breaklen, BreakFraction, ...
                            volume_factor, PPfilter_fname, zero2one, bup_width)

Timer = sin(Phi);
Beep = zeros(size(Phi));

u = find(diff(sign(Timer)) > 0); u = [1 u];
bup = singlebup(SRate, Att, 'PPfilter_fname', PPfilter_fname, 'width', bup_width); 
lbup = length(bup);
for i=1:length(u),
   Beep(u(i):u(i)+lbup-1) = bup;
end;
Beep(1:length(volume_factor)) = Beep(1:length(volume_factor)).*volume_factor;
if length(Beep)>length(volume_factor),
   Beep(length(volume_factor)+1:end) = ...
       Beep(length(volume_factor)+1:end).*volume_factor(end);
end;

Edge=MakeEdge(SRate, 0.003);
LEdge=length(Edge);

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
    