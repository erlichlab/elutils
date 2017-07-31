function y=invsoftplus(beta,x)
% y=invsoftplus(beta,x)
% a = beta(1);
% b = beta(2);
% c = beta(3);
% y  = log(exp(a*y)-1)*b + c; 



a = beta(1);
b = beta(2);
c = beta(3);
y  = log(exp(a*x)-1)*b + c; 

