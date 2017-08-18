function [choice, pchoice] = softmax_pick(Q, temperature)
% [choice, pchoice] = softmax_pick(Q, temperature)
% Inputs:
% Q 				should be a vector of values (e.g. values of taking an action)
% temperature [1] 	The softmax temp. As temperature goes to ∞ output becomes random.
%

total = sum(exp(Q/temperature));
pchoice = exp(Q./temperature)./total;

choice = utils.pick_with_prob(1:numel(Q),pchoice);