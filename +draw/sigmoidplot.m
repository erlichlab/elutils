function [ax b]=sigmoidplot(X,Y,varargin)
% 
Color='k';
Marker='o';
LineStyle='-';
ax=gca;
nbins=12;
fit_func=@sig4;
beta0=[0 1 mean(X) 1];
TrialRange=95;

utils.overridedefaults(who,varargin);

ci=(100-TrialRange)/2;

hold_stat=get(ax,'NextPlot');

[b]=nlinfit(X,Y,fit_func,beta0);
xq=prctile(X,[ci]);
bins=linspace(xq,-xq,nbins);
[n,ni]=histc(X,bins);
muY=zeros(numel(bins)-1,1);
seY=zeros(numel(bins)-1,1);

for bx=1:numel(muY)
    muY(bx)=nanmean(Y(ni==bx));
    seY(bx)=stats.nanstderr(Y(ni==bx));
end
binc=(bins(1:end-1)+bins(2:end))/2;

if ~strcmp(Marker,'none')
he=errorplot(ax,binc, muY,seY);
set(he(2),'Color',Color,'Marker',Marker,'LineStyle','none');
set(he(1),'Color',Color);
set(ax,'NextPlot','add');
end
xax=[min(X):0.1:max(X)];
plot(ax, xax, sig4(b,xax) ,'Color',Color,'LineWidth',2,'LineStyle',LineStyle);
set(ax,'NextPlot',hold_stat);


