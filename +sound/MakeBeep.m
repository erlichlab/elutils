%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeBeep
%		Generate the individual tone pips as an accessory to PrepareSweep.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeBeep
% Usage:
% Beep=MakeBeep( SRate, Attenuation, Frequency, Duration, [RiseFall] )
% Create a sinusoidal beep at frequency Frequency in Hz of duration
% SRate is the sample rate in Hz.
% Attenuation is a scalar (0 dB is an amplitude 1 sinusoid.)
% If a Attenuation is a vector, a harmonic stack is created with these attenuations.
% Frequency in Hz
% Duration in milliseconds
% A fifth optional parameter RiseFall specifies the 10%-90%
% rise and fall times in milliseconds using a cos^2 edge.
function Beep=MakeBeep( SRate,  Attenuation, Frequency, Duration, varargin )

% Create a time vector.
t=0:(1/SRate):(Duration/1000);
t=t(1:(end-1));

% Make harmonic frequencies.
Freqs=Frequency*(1:length(Attenuation));

Attens=meshgrid(Attenuation,t);
Attens=Attens';

[Freqs,t]=meshgrid(Freqs,t);
Freqs=Freqs';
t=t';

% Create the frequencies in the beep.
%Beep = 10 * 10.^(-Attens./20) .* sin( 2*pi* Freqs .* t );
if  Frequency < 0 
    Beep = 1*(10.^(-Attens./20)) .* randn(size(t));
else
    Beep = 1*(10.^(-Attens./20)) .* sin( 2*pi* Freqs .* t );
end

% Add harmonic components together.
Beep=sum(Beep,1);

% If the user specifies, add edge smoothing.
if ( nargin >= 5 )
	
	RiseFall=varargin{1};
	Edge=MakeEdge( SRate, RiseFall );
	LEdge=length(Edge);
	
	% Put a cos^2 gate on the leading and trailing edges.
	Beep(1:LEdge)=Beep(1:LEdge) .* fliplr(Edge);
	Beep((end-LEdge+1):end)=Beep((end-LEdge+1):end) .* Edge;
	
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeBeep : End of function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
