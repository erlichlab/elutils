% This function draws an unity line on the plot.
%h=unity(ax,s)
% ax (optional) plot to this axis, default gca
% s  (optional) use this linestyle, default ':k'

function h=unity(ax,s)
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
ll=min([xlim ylim]);
ul=max([xlim ylim]);
h=plot(ax,[ll ul],[ll ul],s);
set(ax,'NextPlot',oldhold);
end




