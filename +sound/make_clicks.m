function wav = make_clicks(click_rate, duration, varargin)
% make_clicks(click_rate, duration, varargin)
% click_rate      Clicks/second
% duration        Duration of the sound
% click_freq      [8000] in Hz the frequency of each click
% click_dur      [0.003] in seconds, the duration of individual clicks
% smoothed       [0] whether to smooth the edges of the clicks. if not empty use gaussian to smooth.
% click_times     [1*n_ClickTimes(index in given SF)] a train of Click Times, can be
% generated from bpod internal functions/GenreatePossionClicks

inpd = @utils.inputordefault;

[SF, varargin] = inpd('SF',44100, varargin);
[click_freq, varargin] = inpd('click_freq',8000, varargin);
[click_dur, varargin] = inpd('click_dur',0.003, varargin);
[smoothed, varargin] = inpd('smooth',0,varargin);
[click_times, varargin] = inpd('click_times',[],varargin);

if ~isempty(varargin)
   fprintf(2,'Did not use all optional inputs:\n');
   fprintf(2,'%s, ',varargin{:});
   fprintf(2,'\n');
end

wav = zeros(1,round(SF*duration));
click = sin((0:(1/SF):click_dur)*2*pi*click_freq);
 
click_length = numel(click);
click_offset = ceil(click_length/2);

click_dur_in_index = round(click_dur*SF);

if smoothed > 0
   krn = normpdf(linspace(-click_dur/2, click_dur/2, click_length), 0, smoothed);
   click = click .* krn;
end

if isempty(click_times)
    wav(click_offset:(SF/click_rate):end) = 1;
else
    for i = 1:3 %give a little bit more space for some very close clicks
        click_times_diff = click_times - [0, click_times(1:end-1)];
        idx = find(click_times_diff<click_dur_in_index);
        click_times(idx) = click_times(idx) + 1*click_dur_in_index;
    end
    click_times(click_times>length(wav)) = length(wav);
    wav(round(click_times))=1;
end
wav = conv(wav, click);
wav(wav>1) = 1;%for insurance
wav(wav<-1) = -1;

