% function [snd] = MakeSpectrumNoise(SRate, F1, F2, Duration, Kontrast, ...
%                                  CRatio, varargin) 
%
% This function generates a sound whose power spectrum is white except for
% two Gaussian peaks at F1 and F2 (each with std = sigma).  The contrast of
% each peak is defined as C_i = (P_i - b)/b, where P is the height of the peak
% and b (baseline) is the baseline power of every other (non-peak) frequency.
%
% In order to adjust the relative contributions of the peaks at F1 and F2
% in a continuous way along one dimension, we specify the sum of contrasts
%       Kontrast = C1 + C2
% and the log ratio of contrasts
%       CRatio = log(C1/C2).
% In this way, we can keep Kontrast at some constant and adjust CRatio so
% that when CRatio > 0, there is more power around F1 and when CRatio < 0,
% there is more power around F2.
%
% ARGUMENTS
% ---------
% Makes a sound such that:
%
% Srate         sampling rate, in samples/sec
% F1            frequency of first peak above white noise
% F2            frequency of second peak above white noise
% Duration      duration of sound, in milliseconds
% Kontrast      C1 + C2 (see above)
% CRatio        log(C1/C2), as described above

% OPTIONAL ARGUMENTS
% ------------------
% sigma         stdev of Gaussian distributions around F1 and F2 in
%               frequency space of the final sound
% baseline      power of every other frequency not around F1 or F2


% written by Bing, October 2008



function [snd] = MakeSpectrumNoise(SRate, F1, F2, Duration, Kontrast, CRatio, varargin) 

pairs = {
    'stdev'         100     ; ...
    'baseline'      0.01    ; ...
}; parseargs(varargin, pairs);

Duration = Duration/1000;  % to sec

% make white noise
t = linspace(0, Duration, SRate*Duration);
wnoise = randn(size(t));

C1 = Kontrast/(exp(-CRatio)+1);
C2 = Kontrast - C1;

% transform white noise to frequency space
fwnoise = fft(wnoise)/Duration;  % scale magnitude of the fft corresponding to duration ot sound
omega   = SRate*linspace(0, 1, length(fwnoise));  % corresponding frequency dimension

G1 = exp(-(omega - F1) .^2 /(2*stdev^2));
G2 = exp(-(omega - F2) .^2 /(2*stdev^2));

% enhance frequencies around F1 and F2, then recover sound
fsnd = fwnoise .* (G1*baseline*C1+baseline + G2*baseline*C2+baseline);
% normalize the volume so that snd is as loud (psychoacoustics aside) as
% the original generating white noise
fsnd = fsnd * sqrt((sum(fwnoise.*conj(fwnoise)) / sum(fsnd.*conj(fsnd))));
snd = real(ifft(fsnd));

