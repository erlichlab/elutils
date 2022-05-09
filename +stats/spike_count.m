function [y] = spike_count(ref, ts, varargin)
%y = spike_count(ref, ts, kernel, varargin)
%   count number of spikes between for each trial in a window [-pre post]
%   from each element of the reference (ref) vector. or window [pre duration]
%   or window [post-duration, post]
%
% all times are assumed to be in seconds
%
%
% Inputs:
%	ref					vector of times of reference events
%	ts					time stamps of spikes
%
% Varargin: (must have 2 in 3)
%	pre					sec before each ref event in window
%	post				sec after each ref event in window
%   duration            duration before/after each ref event in window
%
% Outputs:
%	y					a Nx1 length vector.
%						each row is the spike count for one trial
%
% if there are nans in ref, that row of y is nans
%
% Vetted by Jingjie Li 2022/01/25

iod = @utils.inputordefault;

pre = iod('pre',[],varargin);
post = iod('post',[],varargin);
duration = iod('duration',[],varargin);

if isempty(pre) && ~isempty(post) && ~isempty(duration)
    pre = -1*(post-duration);
elseif ~isempty(pre) && isempty(post) && ~isempty(duration)
    post = -1*pre + duration;
elseif ~isempty(pre) && ~isempty(post) && isempty(duration)
    % not do anything
else
    error('not enough input varargin, please see help doc');
end

y = zeros(numel(ref),1);
ts=ts(:)';   % make ts a row vector;

for rx = 1:length(ref)
    if isnan(ref(rx))
        y(rx)=y(rx)+nan;
    else
        start = ref(rx) - pre;
        fin   = ref(rx) + post;
        
        spks = stats.qbetween(ts, start, fin);
        y(rx) = numel(spks);%get spike count between diven period
    end
end


end

