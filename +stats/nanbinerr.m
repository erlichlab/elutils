function y=nanbinerr(x)
% y=nanbinerr(x)
% returns the binomial error bars for a vector of 1/0
nnx=x(~isnan(x));

p=mean(nnx);
n=numel(nnx);

y=(1/(1+1.96/n))*(p+1.96/(2*n)+1.96*sqrt(p*(1-p)/n + 1.96/(4*n^2)))-p;
% This is the Wilson Score Interval, from wikipedia
% this is the bad version
% y=1.96*sqrt(mux*(1-mux)/numel(nnx));


