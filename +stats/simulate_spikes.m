function [spktimes, rate_function] = simulate_spikes(event_ts, kernel, event_weights, varargin)
%[spktimes, rate_function] = simulate_spikes(event_ts, kernel, event_weights, [krn_bin_size, krn_offset, baseline])
% Inputs:
% event_ts      An N x M matrix, where N is the number of trials, and M is
%               the number of distinct events in that trial. Each element is the time of
%               the event relative to the beginning of the session.
% kernel        A cell array of length M. Each kernel is convolved with the
%               respective event in event_ts.
% event_weights A matrix the same size as event_ts. These weights scale the
%               kernel for each event on each trial.
%               
%
% krn_bin_size [0.2 s] This is the resolution of the kernels. 
% krn_offset   [0] By default each krn is center-aligned to the respective event
%              To shift this (e.g. to have the kernel follow or
%              preceed the event) pass in either a single offset, which
%              will be applied to all kernels or a list of M offsets to
%              apply to the M specified kernels. The offset should be in 
%              bins.
% 
%
% E.g.
if nargin==0 % Part of help!
    fprintf(1,'Running demo....\n');
    krn_bin_size = 0.1;
    kernel = {gampdf(0:krn_bin_size:2,3,0.1), gampdf(0:0.1:6,5,0.4)};
    kernel{1} = [zeros(size(kernel{1})), kernel{1}./max(kernel{1})*7];
    kernel{2} = [zeros(size(kernel{2})),kernel{2}./max(kernel{2})*2];
    n_trials = 100;
    trial_starts = linspace(0,500, n_trials )';
    event_ts = [trial_starts trial_starts + rand(size(trial_starts))+0.1];
    event_weights = randi([-1 5], n_trials, numel(kernel))*3;
    [spktimes, rate_function] = stats.simulate_spikes(event_ts, kernel, event_weights,'krn_bin_size',krn_bin_size,'baseline',20);
    figure; draw.exampleraster(event_ts(:,1), spktimes,'cnd',event_weights(:,1),'errorbars',0)
    figure; draw.exampleraster(event_ts(:,2), spktimes,'cnd',event_weights(:,2),'errorbars',0)

    return
    
end


%%

inpd = @utils.inputordefault;
[krn_bin_size, args] = inpd('krn_bin_size',0.2, varargin);
[krn_offset, args] = inpd('krn_offset',0, args);
[baseline, args] = inpd('baseline',0, args);
if ~isempty(args)
    warning('Did not process some inputs in simulate_spikes. Did you make some typos?')
    disp(args)
end

if isscalar(krn_offset)
    krn_offset = zeros(size(kernel))+krn_offset;
end

% Shift the kernels by the offset by padding with zeros
for kx = 1:numel(kernel)
    if krn_offset(kx)<0
        kernel{kx} = [kernel{kx}(:); zeros(abs(krn_offset),1)];
    elseif krn_offset(kx)>0
        kernel{kx} = [zeros(krn_offset,1); kernel{kx}(:)];
    end
end

%% Check args
assert(all(size(event_ts) == size(event_weights)), 'event_ts and event_weight must have the same size');
assert(numel(kernel) == size(event_ts,2), 'kernel should be a cell array with number of elements equal to columns of event_ts');
assert(isscalar(baseline),'baseline must be a scalar')
assert(numel(krn_offset)==1 || numel(krn_offset)==numel(kernel), 'krn_offset must be 1 or the number of kernels.')

%% Generate delta functions
start_time = min(event_ts(:)) - min(krn_offset)*krn_bin_size;
stop_time = max(event_ts(:)) + max(cellfun(@(x)numel(x), kernel))*krn_bin_size;
timeax = start_time:krn_bin_size:stop_time;
deltas = zeros(numel(timeax), numel(kernel));
cdeltas = deltas;
for kx = 1:numel(kernel)
    this_ind = stats.qfind(timeax, event_ts(:,kx));
    deltas(this_ind,kx) = event_weights(:,kx);
    cdeltas(:,kx) = conv(deltas(:,kx), kernel{kx}, 'same');
end

rate_function = sum(cdeltas,2) + baseline;
f = @(x)utils.nanidx(stats.qfind(timeax,x),rate_function);
spktimes = stats.inhomopoissrnd(f, 'pre',start_time,'post',stop_time,'binsize',krn_bin_size);
