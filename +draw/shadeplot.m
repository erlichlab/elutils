function hout=shadeplot(x,y1,y2,opt)
% function h=shadeplot(x,y1,y2,opt)
% you need x, sorry
% y1, y2 can be for example lower and upper confidence intervals.
% opt={color, axeshandle, alpha}

if nargin <4
    h=axes;
    clr='k';
    alp=0.5;
else
    h=opt{2};
    alp=opt{3};
    clr=opt{1};
end

y1=y1(:);
y2=y2(:)-y1;


Y=[y1, y2];

h1=area(h,x,Y);
set(h1(2),'EdgeColor','none','FaceColor',clr);
%alpha(h1(2),alp);
set(h1(1),'EdgeColor','none','FaceColor','none');
hout=h1(2);