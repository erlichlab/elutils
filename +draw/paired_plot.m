function [h,ax]=paired_plot(x,y,varargin)

clr1='k';
clr2='k';
eclr1='k';
eclr2='k';
mark1='o';
mark2='o';
ax=[];
xlabels={'Control' 'Exp'};
y_lim=[];

overridedefaults(who,varargin);

if isempty(ax)
    ax=gca;
end

num_p=numel(x);

ax_stat=get(ax,'NextPlot');
set(ax,'NextPlot','add');


LL=[x(:) y(:) nan(size(y(:)))];
XX=[ones(num_p,1)  ones(num_p,1)+1 ones(num_p,1)+nan];

LL=LL'; LL=LL(:);
XX=XX'; XX=XX(:);
hline=plot(ax,XX,LL,'k-');

h1=plot(ax,ones(size(x)),x,'Marker',mark1,'Color',clr1,'MarkerFaceColor',clr1,'MarkerEdgeColor',eclr1,'LineStyle','none');
h2=plot(ax,ones(size(x))*2,y,'Marker',mark2,'Color',clr2,'MarkerFaceColor',clr2,'MarkerEdgeColor',eclr2,'LineStyle','none');
h=[h1 h2 hline];
set(ax,'XLim',[0.5 2.5],'Box','Off','TickDir','out','TickLength',[0.025 0.1],'XTick',[1 2],'XTickLabel',xlabels)

if ~isempty(y_lim)
    ylim(ax,y_lim);
end


set(ax,'NextPlot',ax_stat);