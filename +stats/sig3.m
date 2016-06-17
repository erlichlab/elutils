% y=sig4(beta,x)
% y0=beta(1);
% a=beta(2);
% x0=beta(3);
% b=beta(4);

function y=sig3(beta,X)


x0=beta(1);
b=beta(2);
w=beta(3);

dx=X(:,2)-X(:,1);
L=X(:,1);
R=X(:,2);


w=min(max(w,0),1);

y=1./(1+ exp(-(dx-x0)./((1+w*R+(1-w)*L).^b)));