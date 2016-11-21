%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeChord
%		Generate Chord.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage:
% Beep=MakeChord( SRate, Attenuation, BaseFreq, NTones, Duration, [RiseFall] )
% Create a chord with base frequency 'BaseFreq' and with 'NTones' tones.
% 'SRate' is the sample rate in Hz.
% 'Attenuation' is a scalar (0 dB is an amplitude 1 sinusoid.)
% 'BaseFreq' in Hz
% 'Duration' in milliseconds
% A fifth optional parameter 'RiseFall' specifies the 10%-90%
% rise and fall times in milliseconds using a cos^2 edge.

% added try-catch so that this would work in dispatcher. JCE July 2007
% 

function Beep=MakeChord( SRate,  Attenuation, BaseFreq, NTones, Duration, varargin )

try
FilterPath=[GetParam('rpbox','protocol_path') '\PPfilter.mat'];
if  ( size(dir(FilterPath),1) == 1 )
    PP=load(FilterPath);
    PP=PP.PP;
else
    PP=[];
end
    % message(me,'Generating Calibrated Tones');
catch
    PP=[];
    % message(me,'Generating Non-calibrated Tones');
end

% Create a time vector.
t=0:(1/(SRate)):(Duration/1000);
t=t(1:(end-1));

finterv = sqrt(sqrt(2)); %this stepping yields a diminished minor chord + 13
freq = BaseFreq;
snd = zeros(1,length(t));
for k=1:NTones
    if isempty(PP)
    	ToneAttenuation_adj(k) = Attenuation;
    else
    	ToneAttenuation_adj(k) = Attenuation - ppval(PP, log10( freq ));
    	% Remove any negative attenuations and replace with zero attenuation.
    	ToneAttenuation_adj(k) = ToneAttenuation_adj(k) .* (ToneAttenuation_adj(k) > 0);
    end
    snd = snd + 10^(-ToneAttenuation_adj(k)/20) * ( sin( 2*pi*freq.*t )/NTones ); %IS THIS CORRECT???
    freq = freq * finterv;
end
Beep = snd;

% If the user specifies, add edge smoothing.
% This was changed to >=6 to correspond with the actual input variable list
% JCE, July 2007
if ( nargin >= 6 )
	RiseFall=varargin{1};
	Edge=MakeEdge( SRate, RiseFall );
	LEdge=length(Edge);
	% Put a cos^2 gate on the leading and trailing edges.
	Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
	Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
end
