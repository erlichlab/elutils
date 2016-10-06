function [y, x] = cdraster(ref, cdtimes, cdvals, pre, post, bin, isforce)
% [y, x] = cdraster(ref, cdtimes, cdvals, pre, post, bin)
%
% returns a raster of some continuously sampled data relative to events ref
% at intervals of size bin
%
% all times should be in seconds

% forces input times to be smallest integer multiple of bin possible that
% is greater than pre and post
% false by default for backward compatability

if nargin<7, isforce=false; end 


if length(cdtimes) ~= length(cdvals),
    y = [];
    x = [];
    return;
end

if ~isforce
  if abs((post+pre)/bin - round((post+pre)/bin)) > 1e-5,
      y = [];
      x = [];
      warning('window size must be an integer multiple of bin size');
      return;
  end
else
  if abs((post+pre)/bin - round(post+pre)/bin) > 0,
    pre=ceil((pre)/bin)*bin;
    post=ceil((post)/bin)*bin;
  end
end
    
x = -pre+bin/2:bin:post-bin/2;
ssize = median(diff(cdtimes));
if bin > ssize,
    n = floor(bin/ssize)+1;
    ssize = bin/n;
else
    ssize = bin;
	n=1;
end
xs = -pre+ssize/2:ssize:post-ssize/2;
ys = zeros(numel(ref), numel(xs));
y = zeros(numel(ref), numel(x));
for i = 1:numel(ref),
    starting = ref(i) - pre;
    ending   = ref(i) + post;
    
    if isnan(starting) || isnan(ending)
        times=[];
        s=[];
    else
    [times s] = qbetween2(cdtimes, starting, ending);
    end
    if isempty(times),
        ys(i,:) = NaN * ones(size(xs));
    else
        times = times - ref(i);
        vals  = cdvals(s(1):s(2));
		try
	       % ys(i,:) = spline(times, vals, xs); 
            ys(i,:) = interp1(times, vals, xs,'linear'); 
		
		catch
			ys(i,:) = NaN * ones(size(xs));
		end;
    end
    y(i,:) = nanmean(reshape(ys(i,:),n,numel(xs)/n),1);
end