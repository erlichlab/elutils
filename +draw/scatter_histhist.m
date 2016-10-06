

function [hm, hx, hy]=scatter_histhist(x, x_sig, y,y_sig, x_lim, y_lim, varargin)
% [hm, hx, hy]=scatter_histhist(x, x_sig, y,y_sig, x_lim, y_lim)
% Optional arguments:
% width, hist_height, num_bins, x_label, y_label
%
% E.g
% x = randn(150,1)*2;
% y = randn(250,1)*4+3;
% y = randn(150,1)*4+3;
% xsig = abs(x)>2;
% ysig = y<0;
% draw.scatter_histhist(x,xsig,y,ysig,'x_label','X','y_label','Y')


iod = @utils.inputordefault;
org=iod('org',0.15, varargin);
wdth=iod('width',0.5,varargin);
hist_h=iod('hist_height',0.2,varargin);
num_bns=iod('num_bins',17,varargin);
x_label=iod('x_label','',varargin);
y_label=iod('y_label','',varargin);

	x_lim_b=[min(x)-0.1 max(x)+0.1];
	y_lim_b=[min(y)-0.1 max(y)+0.1];

if nargin==4;
	x_lim=x_lim_b;
	y_lim=y_lim_b;
end
	


figure
hm=axes('Position',[org org wdth wdth]);
set(hm,'Xlim',[-1 1]);
set(hm,'Ylim',[-1 1]);


hx=axes('Position',[org org+wdth+0.01 wdth hist_h]);
hy=axes('Position',[org+wdth+0.01 org hist_h wdth]);

marker_size=zeros(size(x))+12;
marker_size(x_sig==1)=24;
marker_size(y_sig==1)=24;
marker_size(x_sig+y_sig==2)=36;

% make the scatter plot

scatter(hm,x, y, 36,'k');
xlabel(hm,'');
ylabel(hm,'Anti Trials (r)');
xlim(hm,x_lim);
ylim(hm,y_lim);
xhairs(hm,'k-',0,0);
axes(hm);
text(getx,gety,['n=' num2str(numel(x))])

% make the y-axis histogram
bns=linspace(y_lim_b(1),y_lim_b(2),num_bns);
nsig=histc(y(y_sig==0), bns);
nsig=nsig(1:end-1);
sig=histc(y(y_sig==1), bns);
sig=sig(1:end-1);
cbns=edge2cen(bns);
[hh]=barh(hy,cbns, [sig nsig],'stacked');
set(hy, 'YTick',[]);
ylim(hy,y_lim);
set(hy, 'XAxisLocation','bottom');
set(hh(1),'FaceColor','k')
set(hh(2),'FaceColor',[1 1 1])
set(hy,'box','off')
set(hy,'Color','none')
axes(hy);
text(getx,gety,[num2str(round(100*mean(y_sig))) '% p<0.01'])
y_mean=mean(y);
[~,yt_sig]=ttest(y);

    set(hy,'NextPlot','add');
    xx=get(hy,'XLim');
    plot(hy,[0 xx(2)],[y_mean, y_mean],'-k');


% make the x-axis histogram

bns=linspace(x_lim_b(1),x_lim_b(2),num_bns);
nsig=histc(x(x_sig==0), bns);
nsig=nsig(1:end-1);
sig=histc(x(x_sig==1), bns);
sig=sig(1:end-1);
cbns=edge2cen(bns);
[hh]=bar(hx,cbns, [sig nsig],'stacked');
set(hx, 'XTick',[]);
xlim(hx,x_lim);
set(gca, 'YAxisLocation','left');
set(hh(1),'FaceColor','k')
set(hh(2),'FaceColor',[1 1 1])
set(hx,'box','off')
set(hx,'Color','none')
axes(hx);
text(getx,gety,[num2str(round(100*mean(x_sig))) '% p<0.01'])

x_mean=mean(x);
[~,xt_sig]=ttest(x);
    set(hx,'NextPlot','add');
    yy=get(hx,'YLim');
    plot(hx, [x_mean, x_mean],[0 yy(2)],'-k');
   


function y=edge2cen(x)
b2b_dist=x(2)-x(1);
y=x+0.5*b2b_dist;
y=y(1:end-1);

function y=getx
x=xlim;
y=0.1*(x(2)-x(1))+x(1);

function y=gety
x=ylim;
y=0.9*(x(2)-x(1))+x(1);




