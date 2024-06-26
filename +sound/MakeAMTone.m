function tone=MakeAMTone(varargin)

% [This function generates amplitude-modulated tones]
%
% function tone = MakeAMTone(varargin)
%   REQUIRED input paramters:
%   varargin{1} - parameters structure (see below)
%   varargin{2} - sampling rate of the resulting sound (in Hz)
%
% The parameter structure MUST have the following fields:
%
% carrier_frequency         -   carrier frequency of the sound (in Hz)
% carrier_phase             -   initial phase of the carrier frequency
% modulation_frequency      -   modulation frequency of the sound (in Hz)
% modulation_phase          -   modulation phase
% modulation_depth          -   depth of modulation (0-1)
% amplitude                 -   amplitude/intensity of the sound (dB)
% duration                  -   duration (in ms)
% ramp                      -   rising/falling edge (in ms)
%
% Example:
% params.carrier_frequency      = 6000;
% params.carrier_phase          = 0;
% params.modulation_frequency	= 50;
% params.modulation_phase       = 0;
% params.modulation_depth       = 0.5;
% params.amplitude              = 70;
% params.duration               = 500;
% params.ramp                   = 5;
%
% samplerate                    = 44100;
%
%
% tone = MakeAMTone(params, samplerate);
%   this creates 500 ms long am-tone with carrier frequency (i.e. centered on) 6000 Hz.
%
%
% The amplitude of the final sound depends on pref.maxSPL defined above, i.e. you MUST know the
% MAXIMUM dB SPL sound pressure level your system/speaker can deliver. Your requested amplitude will
% be adjusted to pref.SPL, i.e. if you say (pref.SPL) that your system is calibrated to 70 dB, and
% request amplitude of 80 dB, your sound wave's amplitude wil be larger than your system can handle
% and the actual sound coming out of the speaker will be distorted....
%
% orig: sAM.m Wang Lab, Johns Hopkins University (Edited on January 13, 2004 by Tom Lu)
pref.maxSPL = 70;   % max. amplitude in dB SPL


tone=[];

if nargin<2 
    return;
end

params          =varargin{1};
samplerate      =varargin{2};
Fc              =params.carrier_frequency;
carrier_phase   =params.carrier_phase;
Fm              =params.modulation_frequency;
modulation_phase=params.modulation_phase;
modulation_depth=params.modulation_depth;
amplitude       =params.amplitude;
duration        =params.duration;
ramp            =params.ramp;

    amplitude=(10.^((amplitude-pref.maxSPL)/20));

    npts=samplerate*(duration/1000);      % stimulus length in samples
    x=(1:npts)/samplerate;                  % 'time' vector

    tone=(1+modulation_depth*cos(2*pi*Fm*x + modulation_phase)).*sin(2*pi*Fc*x + carrier_phase);
    tone=tone./max(abs(tone));
    tone=amplitude.*tone;

    edge=sound.MakeEdge(ramp,samplerate);     % prepare the edges
    ledge=length(edge);
    tone(1:ledge)=tone(1:ledge).*fliplr(edge);
    tone((end-ledge+1):end)=tone((end-ledge+1):end).*edge;

    
% Uncomment the following if you want to how the sounds look like    
%     
% figure
% subplot(211)
% plot((1:length(tone))/samplerate*1000, tone)
% xlabel('Time (ms)')
% ylabel('amplitude')
% 
% subplot(212)
% plot((1:length(fft(tone)))/length(fft(tone))*(samplerate/1000), abs(fft(tone)))
% specgram(tone,[],samplerate/1000)
% ylabel('Frequency (kHz)');
