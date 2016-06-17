function y = cWeibull(beta, x)
% cumulative Weibull function for fitting psychometric data
% where the y-intercept is at 0.5
a = beta(1);
b = beta(2);

y = 0.5 + 0.5*(1 - exp(-(x/a).^b));