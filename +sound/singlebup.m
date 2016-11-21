% [snd] = singlebup(srate, att, { 'width', 5}, {'ramp', 2}, {'basefreq', 2000}, ...
%                   {'ntones' 5}, {'PPfilter_fname', ''});  ...
     

function [snd] = singlebup(srate, att, varargin)
   
   width=5    ;  
   ramp,        =  2    ;  
   basefreq     =  2000 ;  
   ntones       =  5    ;  
   PPfilter_fname= ''    ; 

   utils.overridedefaults(who, varargin);

   
   width = width/1000;
   ramp = ramp/1000;
   
   if isempty(PPfilter_fname)
      FilterPath=['Protocols' filesep 'PPfilter.mat'];
   else
      FilterPath = PPfilter_fname;
   end;
   PP = load(FilterPath);
   PP=PP.PP;

   
   t = 0:(1/srate):width;

   snd = zeros(size(t));
   for i=1:ntones,
      f = basefreq*(2.^(i-1));
      attenuation = att - ppval(PP, log10(f));
      snd = snd + (10.^(-attenuation./20)) .* sin(2*pi*f*t);
   end;

   if max(abs(snd)) >= 1, snd = snd/(1.01*max(abs(snd))); end;
   
   rampedge=MakeEdge(srate, ramp); ramplen = length(rampedge);
   snd(1:ramplen) = snd(1:ramplen) .* fliplr(rampedge);
   snd(end-ramplen+1:end) = snd(end-ramplen+1:end) .* rampedge;

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
       