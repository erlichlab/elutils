function [y, x] = cdraster(ref, cdtimes, cdvals, varargin)
% [y, x] = cdraster(ref, cdtimes, cdvals, pre, post, bin)
%
% returns a raster of some continuously sampled data relative to events ref
% at intervals of size bin
%
% all times should be in seconds

% forces input times to be smallest integer multiple of bin possible that
% is greater than pre and post
% false by default for backward compatability

inpd = @utils.inputordefault;

pre = inpd('pre',0.5, varargin);
post = inpd('post',1, varargin);
bin = inpd('bin',0.1, varargin);
isforce = inpd('coerce',true,varargin);

if nargin<7, isforce=false; end

if numel(cdtimes)~=numel(cdvals)
    %assume that the ts refer to equally spaced samples
    samples_per_ts = numel(cdvals)./numel(cdtimes);
    if  rem(numel(cdvals),numel(cdtimes))==0
        samples_per_ts = numel(cdvals)./numel(cdtimes);
    else
        error("Not an even # of samples per timestep")
        return
    end
else
    samples_per_ts = 1;
end


if ~isforce
    if abs((post+pre)/bin - round((post+pre)/bin)) > 1e-5,
        y = [];
        x = [];
        warning('window size must be an integer multiple of bin size');
        return;
    end
else
    if abs((post+pre)/bin - round(post+pre)/bin) > 0
        pre=ceil((pre)/bin)*bin;
        post=ceil((post)/bin)*bin;
    end
end

x = (-pre+bin/2):bin:(post-bin/2);
ssize = median(diff(cdtimes));
if bin > ssize
    n = floor(bin/ssize)+1;
    ssize = bin/n;
else
    ssize = bin;
    n=1;
end
xs = -pre+ssize/2:ssize:post-ssize/2;
ys = zeros(numel(ref), numel(xs));
y = zeros(numel(ref), numel(x));
for i = 1:numel(ref)
    starting = ref(i) - pre;
    ending   = ref(i) + post;
    
    if isnan(starting) || isnan(ending)
        ftimes=[];
        s = [];
    else
        
        [ftimes, s] = stats.qbetween2(cdtimes, starting, ending);
    end
    if isempty(ftimes)
        ys(i,:) = NaN * ones(size(xs));
    else
        stepsize = median(diff(ftimes));
        times = bsxfun(@plus, repmat(ftimes(:),1,samples_per_ts), (stepsize/samples_per_ts).*(0:(samples_per_ts-1)))' - ref(i);
        times = times(:);
        start_val = samples_per_ts * (s(1)-1)+1;
        end_val = samples_per_ts*s(2);
        try
            vals  = cdvals(start_val:end_val);
            ys(i,:) = interp1(times, vals, xs,'linear',nan);
            
        catch
            ys(i,:) = NaN * ones(size(xs));
        end
    end
    y(i,:) = nanmean(reshape(ys(i,:),n,numel(xs)/n),1);
end