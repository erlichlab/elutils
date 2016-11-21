%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeEdge
%		Generate the rising/falling edge as an accessory to MakeBeep.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Edge=MakeEdge( SRate, RiseFall )

% Usage:
% Edge=MakeEdge( SRate, RiseFall )
% Calculate a cos^2 gate for the trailing edge that has a 10%-90%
% fall time of RiseFall in milliseconds given sample rate SRate in Hz.

omega=(1e3/RiseFall)*(acos(sqrt(0.1))-acos(sqrt(0.9)));
t=0 : (1/SRate) : pi/2/omega;
t=t(1:(end-1));
Edge= ( cos(omega*t) ).^2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MakeEdge : End of function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
