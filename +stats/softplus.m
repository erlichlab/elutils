
function y=softplus(beta,x)
%  y=softplus(beta,x)
% a=beta(1);
% x0=beta(2);
% b=beta(3);

a=beta(1);
x0=beta(2);
b=beta(3);

y = a.*(log(1 + exp((x - x0).*b)));

y/a = log(1 + exp(x-x0)*b)

exp(y/a) = 1 + exp(x-x0)*b
exp(y/a) - 1  = exp(x-x0)*b

b*(exp(y/a) - 1 = exp(x-x0)
log(b*exp(y) - a - 1) = x - x0

y = log(b*(exp(x) - a)) + x0;