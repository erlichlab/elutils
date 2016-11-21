%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeChord2
%		Generate Chord.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage:
% Beep=MakeChord( SRate, Attenuation, BaseFreq, NTones, Duration, [RiseFall] )
% Create a chord with base frequency 'BaseFreq' and with 'NTones' tones.
% 'SRate' is the sample rate in Hz.
% 'Attenuation' is a scalar (0 dB is an amplitude 1 sinusoid.)
% 'BaseFreq' in Hz
% 'Duration' in milliseconds
%
% Unlike MakeChord, MakeChord2 uses key-value pairs for varargin.
% To specify 'RiseFall', for example, you would do:
% MakeChord(srate, att, basefreq, ntones, dur, 'RiseFall', 0.05)
% instead of tacking RiseFall as the fifth parameter.
% 
% Also allows volume to be scaled up or down using a linear factor
% 'volume_factor'


function Beep=MakeChord2( SRate,  Attenuation, BaseFreq, NTones, Duration, varargin )

pairs = { ...
    'RiseFall', 0 ; ...
    'volume_factor', 1 ; ...
    };
parse_knownargs(varargin, pairs);

FilterPath=[GetParam('rpbox','protocol_path') '\PPfilter.mat'];
if ( size(dir(FilterPath),1) == 1 )
    PP=load(FilterPath);
    PP=PP.PP;
    % message(me,'Generating Calibrated Tones');
else
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
if ( RiseFall > 0)
	Edge=MakeEdge( SRate, RiseFall );
	LEdge=length(Edge);
	% Put a cos^2 gate on the leading and trailing edges.
	Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
	Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
end

Beep = Beep.*volume_factor;