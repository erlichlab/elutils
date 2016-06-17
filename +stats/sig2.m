% y=sig2(beta,x)
% x0=beta(3);
% b=beta(4);

function y=sig2(beta,x)

x0=beta(1);
b=beta(2);

y=1./(1+ exp(-(x-x0)./b));