function [kernel, event_weights, S] = kernel_regress_spikes(event_ts, spktimes, varargin)
% [kernel, event_weights, S] = kernel_regress_spikes(event_ts, spktimes, [krn_pre, krn_post, krn_bin_size])
%
% Inputs:
% event_ts      An N x M matrix, where N is the number of trials, and M is
%               the number of distinct events in that trial. Each element is the time of
%               the event relative to the beginning of the session.
% spktimes      The times (in seconds) of the spikes of a cell relative to
%               the start of the session.
% krn_pre       [0] Either a scalar or a vector of length M. This is the
%               beginning of the kernel relative to the event time.
% krn_post      [2] Either a scalar or a vector of length M. This is the
%               end of the kernel relative to the event time.
% krn_bin_size  [0.2] This is the resolution of the kernel. The size of the
%               kernel is krn_pre:krn_bin_size:krn_post

if nargin==0
    fprintf(1,'Running test code.\n');
    krn_bin_size = 0.1;
    kernel = {gampdf(0:krn_bin_size:2,3,0.1), gampdf(0:0.1:6,5,0.4)};
    kernel{1} = [zeros(size(kernel{1})), kernel{1}./max(kernel{1})*7];
    kernel{2} = [zeros(size(kernel{2})),kernel{2}./max(kernel{2})*2];
    n_trials = 100;
    trial_starts = linspace(0,500, n_trials )';
    event_ts = [trial_starts trial_starts + rand(size(trial_starts))+0.1];
    event_weights = randi([-1 5], n_trials, numel(kernel))*3;
    [spktimes] = stats.simulate_spikes(event_ts, kernel, event_weights,'krn_bin_size',krn_bin_size,'baseline',20);
    [est_krn, est_weights]= kernel_regress_spikes(event_ts, spktimes);
    figure(1); clf;
    ax(1) = draw.jaxes([0.15 0.2 0.3 0.3]);
    ax(2) = draw.jaxes([0.55 0.2 0.3 0.3]);
    plot(ax(1), event_weights(:), est_weights(:),'o');
    draw.unity(ax(1));
    xlabel(ax(1), 'True Weights');
    ylabel(ax(1), 'Estimated Weights');
    
    for kx = 1:numel(kernel)
        ktime = numel(kernel{kx})/krn_bin_size;
        kax = linspace(-ktime/2, ktime/2, numel(kernel{kx}));
        h = plot(ax(2),kax,kernel{kx},'LineWidth',2);
        
        ktime = numel(est_krn{kx})/krn_bin_size;
        kax = linspace(-ktime/2, ktime/2, numel(est_krn{kx}));
        plot(ax(2),kax,est_krn{kx},'--','Color',h.Color,'LineWidth',2);
        
    end
end % End Demo

inpd = @utils.inputordefault;

[krn_pre, args]=inpd('krn_pre',0,varargin);
[krn_post, args]=inpd('krn_post',2,args);
[krn_bin_size, args]=inpd('krn_bin_size',0.2,args);
if ~isempty(args)
    warning('Unused argmuments in kernel_regress_spike.');
    disp(args);
end

% First, set all the co





end