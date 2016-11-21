% [snd] = cosyne_ramp(snd, srate, ramp_ms)
%
% Takes a sound in the 1-dimensional vector snd, and assuming that the
% samplerate for it is srate samples/sec, multiplies it by a cosyne ramp of
% ramp_ms milliseconds (i.e., the cosyne function goes from min to max in
% ramp_ms, meaning it has a whole-cycle a period of 2*ramp_ms)
%

function [snd] = cosyne_ramp(snd, srate, ramp_ms)

   if isempty(snd), return; end;
   
   len = ceil(srate*ramp_ms/1000)+1;

   if ~isvector(snd), 
     error('COSYNE_RAMP:Invalid', 'snd must be an n-by-1 or 1-by-n vector'); 
   end;
   if length(snd) < len,
     error('COSYNE_RAMP:Invalid', 'snd must be at least ramp_ms plus one sample long');
   end;
   
   cos_period = 2*ramp_ms/1000;
   cosyne = cos(2*pi*(1/cos_period)*(0:len-1)/srate);
   
   snd(1:len) = snd(1:len).*cosyne(end:-1:1);
   snd(end-len+1:end) = snd(end-len+1:end).*cosyne;
   
   