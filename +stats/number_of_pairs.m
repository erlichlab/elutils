% [n] = number_of_pairs(sh, p)   Compute number of expected simultaneously-recorded pairs of "interesting" neurons
%
% Given a histogram of (# of sessions) versus (# of single-units recorded
% per session), and given a probability of a neuron being an "interesting"
% neuron (i.e., having a high enough firing rate, task-related
% activity, etc), produces an estimate of number of pairs of interesting,
% simultaneously recorded neurons.
%
% PARAMETERS:
% -----------
%
% sh       A vector. The ith element in this vector should contain the
%          number of sessions in which there were i single units recorded.
%
% p        The probability that a recorded neuron is "interesting" (however
%          you want to define it).
%
% RETURNS:
% --------
%
% n        Expected number of simultaneously recorded "interesting" pairs
%
%
%
% EXAMPLE CALL:
% -------------
%
% >> number_of_pairs([4 5 3], 0.3)
%
%       1.7460
%
% gives the number of expected interesting pairs if in 4 sessions you
% recorded only one single unit (those produce no pairs, of course), in 5
% sessions you recorded two single units, and in 3 sessions you recorded
% three single units; and the probability of an "interesting" cell is 0.3.
% 

% CDB 15-June-2012



function [n] = number_of_pairs(sh, p)

n=0;
for i=2:numel(sh),  % i is going to be the # of singles recorded
   for k=2:i        % k is going to be the number of "interesting" neurons
      pk = nchoosek(i,k)*p.^k*(1-p).^(i-k);  % probability of k "interesting" neurons in i recorded neurons, assuming independence 
      ek = sh(i)*pk;                         % expected number of sessions in which we got k "interesting" neurons
      n  = n + ek*nchoosek(k,2);             % number of pairs we get out of k neurons (e.g., when k=3 that's three different pairs)
   end
end;
