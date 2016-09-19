function out = pick_with_prob(items, probs, varargin)
% out = pick_with_prob(items, probabilities, ['out_size', 1])
% Inputs:
% items: a list (cell-array or numeric array) of items that you would like to sample from
% probabilities : A numeric vector that describes the ratios of how often you would like each item.
% out_size (optional) : how many time you would like to sample from items.
%
% Example:
% poke = pick_with_prob({'MidR', 'BotC', 'MidL'},[5 1 1]);
% This will return a cell array of size (1,1) and 5/7 times it will be MidR, 1/7 it will be BotC and 1/7 it will be MidL.

	out_size = utils.inputordefault('out_size', [1,1], varargin);
	numel_out = prod(out_size);
	if nargin==1
		probs = ones(size(items));
	end



	cumprob = cumsum(probs/sum(probs));
	
	ind = stats.qfind(cumprob, rand(1,numel_out));
	out = reshape(items(ind+1),out_size);

