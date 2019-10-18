function y = inhomopoissrnd(intens, varargin)
% y = inhomopoissrnd(intens,T,binsize)
% Inputs:
% ===========
% intens        an intesity function. Should take an input (or vector of
%               inputs) and return lambda (in events/second) of the process at that time.
% 'pre'         [ 0] The time at which to start the interval of simulation
% 'post'        [ 1] The time at which to end the interval of simulation
% 'binsize'     [0.01] The binsize to sample at (only really important for 
%               non-monotonic processes, where the estimate of the max rate
%               is influences by resolution.
% 'offset'     If you are using this function to generate multiple
%               "trials", then pass list of offsets. The simulation will be run 
%               numel(offset) times, each time the offset will be added to
%               the events.
% 'noise'       a function that takes a size input and will be added to the
%               intens function.
% 'refract_dur' [0] if >0 will shift events so that there are no events
%               closer than this value (in seconds)
%
% intens should be in units of events / second
%
% lambda = @(x)10 + 5*sin(x/5);
% post = 100;
% events = stats.inhomopoissrnd(lambda, 'post',post);
% hist(events, post)
% set(gca,'NextPlot','add');
% plot(0:0.1:post, lambda(0:0.1:post),'r-','LineWidth',2)
%
% stats.inhomopoissrnd() % a demo. see code for more details.

if nargin==0
    %%
    fprintf(1,'A demo of stat.inhomopoissrnd.m\nSee code for details.\n')
    clf;
    lambda = @(x)utils.constrain_var(50*x/10,20,50);
    % Simulate a ramp from 20Hz to 50Hz over 10 seconds
    post = 20;
    offset = [0:40:2222];
    noise = @(x)randn(x)*5;
    events = stats.inhomopoissrnd(lambda, 'pre',-5,'post',post,'offset',offset,'noise',noise,'refract_dur',0.001);
    krn = normpdf(-3:0.001:3, 0,1);
    kbs = 0.001;
    draw.exampleraster(offset(:), events,'pre',1,'post',20,'errorbars',0);
    return
    
end


inpd = @utils.inputordefault;

[pre, args]  =      inpd('pre',  0,varargin);
[post, args] =      inpd('post', 1,args);
[binsize, args] =   inpd('binsize',0.01,args);
[offset, args] =    inpd('offset',0,args);
[noise, args] =     inpd('noise',@zeros,args);
[refract_dur, args] =     inpd('refract_dur',0,args); % Highly discouraged

if ~isempty(args)
    fprintf(2,'Unused arguments in inhomopoissrnd:')
    disp(args)
end
    


if any(offset(2:end) < (post-pre))
    warning('STATS:overlapping_intervals','Some offsets smaller than simulation duration. Event count may be inaccurate in those intervals');
end

timex = pre:binsize:post; % 
T = post-pre;
maxlambda = max(intens(timex)); % generate homogeneouos poisson process
max_events = ceil(1.5*T*maxlambda);
u = rand(max_events, numel(offset));
y = cumsum(-(1/maxlambda)*log(u) + refract_dur+rand(size(u))*refract_dur*2)+pre; %points of homogeneous pp
%y = y(y<T); n=length(y); % select those points less than T
y(y>=post)=NaN;
m = intens(y) + noise(size(y)); % evaluates intensity function
y(rand(size(y))>m/maxlambda) = NaN; % filter out some points
y = bsxfun(@plus,y,reshape(offset,1,numel(offset)));
y = sort(y(:));
y(isnan(y))=[];