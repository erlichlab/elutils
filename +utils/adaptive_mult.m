% [val] = adaptive_mult(val, hit, {'hit_frac', 0}, {'stableperf', 0.75}, ...
%                         {'mx', 1}, {'mn', 0}, {'do_callback', 0})
% 
% Implements multiplicative staircase adaptation of a variable. 
%
% PARAMETERS:
% -----------
%
% val       The value to be adapted. 
%
% hit       Pass this as 1 if latest trial was in the positive adaptation
%           direction; passit as 0 if it was in the negative direction
%
% OPTIONAL PARAMETERS
% -------------------
%
% hit_frac    How much to add to the parameter when hit==1. Default value
%             is 0, meaning no adaptation whatsoever.
%
% stableperf  The percentage of positive trials that would lead to no
%             movement on average. stableperf is used to calculate the
%             size of how much is substracted from the SPH when
%             hit==0. Default value is 75%. Performance below this will
%             (on average) lead to motion in the -hit_frac direction;
%             performance above this will lead to motion in the hit_frac
%             direction. 
%
% mx          Maximum bound on the value: value cannot go above this
%
% mn          Minimum bound on the value: value cannot go below this
%
%
%
% RETURNS:
% --------
%
% val         return the updated, post-adaptation value.
%
%
% EXAMPLE CALL:
% -------------
%
%  >> block_length = adaptive_step(block_length, hit, 'hit_frac', -0.1, 'stableperf', 0.75, 'mx, ...
%                   50, 'mn', 2)
%
% Will increase my_sph by 1 every time hit==1, and will decrease it
% by 3 every time hit==0. my_sph will be bounded within 90 and 100.
%

function [val] = adaptive_mult(val, hit, varargin)
   
inpd = @utils.inputordefault;

hit_frac = inpd('hit_frac',0 ,varargin);
stableperf = inpd('stableperf',   0.75, varargin);
mx = inpd('mx', 1, varargin); 
mn = inpd('mn', 0, varargin);


log_hit_step  = log10(1 + hit_frac);
log_miss_step = stableperf*log_hit_step/(1-stableperf); 

if hit==1,      
	val = val * (10.^log_hit_step);
elseif hit==0
    val = val / (10.^log_miss_step);
end
% if hit is nan don't adapt


if val > mx
  val = mx; 
end
if val < mn
  val = mn
end
