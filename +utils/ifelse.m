function out = ifelse(a,t,b,c)
% out = ifelse(a,t,b,c)
% For each element of a, return t(a) ? b(a) : c(a)
%
% e.g. 
% M = 2:10:1000;
% a = [1 5 NaN 8]
% t = @(x)isnan(x);
% b = @(x)nan;
% c = @(x)M(x)
% out = ifelse(a,t,b,c);
%
out = zeros(size(a));
for tx = 1:numel(a)
    if t(a(tx))
        out(tx) = b(a(tx));
    else
        out(tx) = c(a(tx));
    end
end