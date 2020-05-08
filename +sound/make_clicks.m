function wav = make_clicks(click_rate, duration, varargin)
% make_clicks(click_rate, duration, varargin)
% click_rate      Clicks/second
% duration        Duration of the sound
% click_freq      [8000] in Hz the frequency of each click
% click_dur      [0.003] in seconds, the duration of individual clicks
% smoothed       [0] whether to smooth the edges of the clicks. if not empty use gaussian to smooth.

inpd = @utils.inputordefault;

[SF, varargin] = inpd('SF',44100, varargin);
[click_freq, varargin] = inpd('click_freq',8000, varargin);
[click_dur, varargin] = inpd('click_dur',0.003, varargin);
[smoothed, varargin] = inpd('smooth',0,varargin);
if ~isempty(varargin)
   fprintf(2,'Did not use all optional inputs:\n');
   fprintf(2,'%s, ',varargin{:});
   fprintf(2,'\n');
end

wav = zeros(SF*duration,1);
click = sin((0:(1/SF):click_dur)*2*pi*click_freq);
 
click_length = numel(click);
click_offset = ceil(click_length/2);

if smoothed > 0
   krn = normpdf(linspace(-click_dur/2, click_dur/2, click_length), 0, smoothed);
   click = click .* krn;
end

wav(click_offset:(SF/click_rate):end) = 1;
wav = conv(wav, click);

