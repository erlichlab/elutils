
function x=sig4inv(beta,y)
%% sig4
y0=beta(1);
a=beta(2);
x0=beta(3);
b=beta(4);



x = -b*log((a./(y-y0))-1)+x0;