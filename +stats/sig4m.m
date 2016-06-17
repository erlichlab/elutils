% y=sig4(beta,x)
% y0=beta(1);
% a=beta(2);
% x0=beta(3);
% b=beta(4);

function y=sig4m(beta,X)

y0=beta(1);
a=beta(2);
x0=beta(3);
b=beta(4);

dx=X(:,2)-X(:,1);
sx=X(:,2)+X(:,1);


y=y0+a./(1+ exp(-(dx-x0)./(sx.^b)));