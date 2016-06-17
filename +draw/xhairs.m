function h=xhairs(ax,s,x0,y0,top)
% h=xhairs(ax,s,x0,y0)
% ax is the axis to plot the axis in. default = gca
% s  is the style of th line.  default = ':k'
% x0, y0 are the x and y places to plot.  default =[ 0,0];


if nargin<3
    x0=0;
    y0=0;
end

if nargin<5
    top=false;
end

if nargin<2
s=':k';
end

if nargin<1
    ax=gca;
end
bax=ax;
for axx=1:numel(bax)
ax=bax(axx);
oldhold=get(ax,'NextPlot');
xlim=get(ax, 'XLim');
ylim=get(ax, 'YLim');

hold(ax,'on')
h(1)=plot(ax,[x0 x0],[ylim(1) ylim(2)],s);
h(2)=plot(ax,[xlim(1) xlim(2)],[ y0 y0 ],s);
if ~top
ch=get(ax,'Children');
set(ax,'Children',[ch(3:end); ch(1:2)])
end
set(ax,'NextPlot',oldhold);
end




