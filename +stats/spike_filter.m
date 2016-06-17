function [y x] = spike_filter(ref, ts, kernel, varargin)
% function [y x] = spike_filter(ref, ts, kernel, varargin)
%
% produces smoothed single-trial peth's in a window [-pre post] from each
% element of the reference (ref) vector.
% all times are assumed to be in seconds
%
%
% Inputs:
%	ref					vector of times of reference events
%	ts					time stamps of spikes
%	kernel				kernel used for filtering
%
% Varargin:
%	kernel_bin_size		size of a kernel bin (sec)
%	pre					sec before each ref event in window
%	post				sec after each ref event in window
%
% Outputs:
%	x					a vector of time steps, [-pre:kernel_bin_size:post]
%	y					a M x N matrix, where M is the length of ref and N
%						is the length of x.
%						each row is the smoothed spike raster for one trial
%
% if there are nans in ref, that row of y is nans
%
% Vetted by B. Brunton and J. Erlich 2009/10/5

pairs = {'kernel_bin_size'			5e-4	; ...
    'pre'						2		; ...
    'post'						3		; ...
    'normalize_krn'             1       ; ...
    }; parseargs(varargin, pairs);

if normalize_krn
    kernel = kernel/sum(abs(kernel))/kernel_bin_size; % normalize
end
offset = ceil(length(kernel)/2);
buffered_pre=pre+offset*kernel_bin_size;
x = -buffered_pre:kernel_bin_size:post;
y = zeros(length(ref), numel(x)-1); 
ts=ts(:)';   % make ts a row vector;
for rx = 1:length(ref),
    if isnan(ref(rx))
        y(rx,:)=y(rx,:)+nan;
    else
        start = ref(rx) - buffered_pre;
        fin   = ref(rx) + post;
        
        spks = qbetween(ts, start, fin) - ref(rx); % spike times relative to ref
        
        if ~isempty(spks),
            ty = histc(spks,x);
            y(rx, :) = ty(1:end-1);
        end;
    end
end;

y=[y zeros(numel(ref), offset)];  % pad with extra zeros

y = filter(kernel, 1, y, [], 2);
y = y(:, 2*offset:end-1); % trim extra columns
x=x(offset+1:end-1);
