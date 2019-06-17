function [Y, bin_time] = qcount_binned(ts,ref,bins,varargin)
% [Y] = qcount_binned(ts,from_t,to_t,bins,varargin)
% Counts spikes in a fixed number of bins between two events.
% This can be used to "warp" different nunmber of trials to be the same length.
% Inputs
% ts 		spike times (or any other sorted vector)
% ref       A matrix of times. At least 2 columns.
% bins 		How many bins do you want to divide up the time into? A scalar
%           or a vector with as many elements as columns of ref-1;
% Optional Input
% normalize 	[true] If true instead of counts/bin the function returns counts/second.
% e.g.
% You have a list of spike times:
% ts = sort([normrnd(1,1,[1,100]) normrnd(3,2,[1,200]) normrnd(10,1,[1,100]) normrnd(12,2,[1,200])]);
% % It's like two trials.
% % You want to take 10 bins between 0-2 and from 9-11 and 5 bins between 2-5 and 11-14;
% ref = [0 2 5; 9 11 14]; bins = [10, 5];

iod = @utils.inputordefault;
normalize = iod('normalize',true,varargin);

num_chunks = size(ref,2)-1;
num_trials = size(ref,1);
if numel(bins)==1
    bins = repmat(bins, 1, num_chunks);
end

Y = nan(num_trials,sum(bins));
bin_time = nan(num_trials,num_chunks);
cbins = cumsum(bins);
for sx = 1:num_trials
    for rx = 1:num_chunks
        if rx==1
            chunk_ind = 1:cbins(rx);
        else
            chunk_ind = cbins(rx-1)+1:cbins(rx);
        end
        bin_edges = linspace(ref(sx,rx), ref(sx,rx+1), bins(rx)+1);
        bin_time(sx,rx) = (ref(sx,rx+1)-ref(sx,rx)) / bins(rx);
        Y(sx,chunk_ind) = arrayfun(@(a,b)stats.qcount(ts,a,b),bin_edges(1:end-1),bin_edges(2:end));
        if normalize
            Y(sx,chunk_ind) = Y(sx,chunk_ind)/bin_time(sx,rx);
        end
    end
    
end

end
