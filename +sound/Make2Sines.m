%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make2Sines

%		Generate two sine tones with delay.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Usage:

% Beep=Make2Sines( SRate, Attenuation, F1, F2, ToneDuration, Delay, [RiseFall] )

% Create sine tone with frequency f1, delay, and sine tone with freq f2

% 'SRate' is the sample rate in Hz.

% 'Attenuation' is a scalar (0 dB is an amplitude 1 sinusoid.)

% 'F1' and 'F2' in Hz

% 'ToneDuration' and 'Delay' in milliseconds

% A fifth optional parameter 'RiseFall' specifies the 10%-90%

% rise and fall times in milliseconds using a cos^2 edge.



function Beep=Make2Sines( SRate,  Attenuation, F1, F2, ToneDuration, Delay, varargin )



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

t = 0:(1/SRate):(ToneDuration/1000);

t = t(1:end-1);



%Create F1

if isempty(PP)

	ToneAttenuation_adj = Attenuation;

else

	ToneAttenuation_adj = Attenuation - ppval(PP, log10( F1 ));

	% Remove any negative attenuations and replace with zero attenuation.

	ToneAttenuation_adj = ToneAttenuation_adj * (ToneAttenuation_adj > 0);

end

snd = 10^(-ToneAttenuation_adj/20) * sin( 2*pi*F1*t );

% If the user specifies, add edge smoothing.

if ( nargin >= 5 )

	RiseFall=varargin{1};

	Edge=MakeEdge( SRate, RiseFall );

	LEdge=length(Edge);

	% Put a cos^2 gate on the leading and trailing edges.

	snd(1:LEdge)=snd(1:LEdge) .* fliplr(Edge);

	snd((end-LEdge+1):end)=snd((end-LEdge+1):end) .* Edge;

end



%Create Delay

tmp = 0:(1/SRate):(Delay/1000);

snd2 = zeros(1,length(tmp)-1);



%Create F2

if isempty(PP)

	ToneAttenuation_adj = Attenuation;

else

	ToneAttenuation_adj = Attenuation - ppval(PP, log10( F2 ));

	% Remove any negative attenuations and replace with zero attenuation.

	ToneAttenuation_adj = ToneAttenuation_adj * (ToneAttenuation_adj > 0);

end

snd3 = 10^(-ToneAttenuation_adj/20) * sin( 2*pi*F2*t );

% If the user specifies, add edge smoothing.

if ( nargin >= 5 )

	RiseFall=varargin{1};

	Edge=MakeEdge( SRate, RiseFall );

	LEdge=length(Edge);

	% Put a cos^2 gate on the leading and trailing edges.

	snd3(1:LEdge)=snd3(1:LEdge) .* fliplr(Edge);

	snd3((end-LEdge+1):end)=snd3((end-LEdge+1):end) .* Edge;

end



Beep = [snd, snd2, snd3];

