% y=sig4(beta,x)
% y0=beta(1);
% a=beta(2);
% x0=beta(3);
% b=beta(4);

function y=sig5(beta,X)

y0=beta(1);
a=beta(2);
x0=beta(3);
b=beta(4);
w=beta(5);

dx=X(:,2)-X(:,1);
rx=X(:,2);
lx=X(:,1);

w=min(max(0,w),1);

y=y0+a./(1+ exp(-(dx-x0)./((w*rx+(1-w)*lx).^b)));