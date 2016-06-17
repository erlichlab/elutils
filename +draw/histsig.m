

function [ hx]=histsig(x, x_sig, x_lim)
% [ hx]=histsig(x, x_sig,  x_lim)

org=0.1;
wdth=0.2;
hist_h=0.180;
num_bns=17;

gd=~isnan(x);
x=x(gd);
x_sig=x_sig(gd);

	x_lim_b=[min(x)-0.1 max(x)+0.1];

if nargin==2;
	x_lim=x_lim_b;
end
	


figure

hx=axes('Position',[org org wdth hist_h]);

marker_size=zeros(size(x))+12;
marker_size(x_sig==1)=24;

% make the x-axis histogram

axes(hx);
bns=linspace(x_lim_b(1),x_lim_b(2),num_bns);
nsig=histc(x(x_sig==0), bns);
nsig=nsig(1:end-1);
sig=histc(x(x_sig==1), bns);
sig=sig(1:end-1);
maxy=max(nsig(:)+sig(:))*1.3;
cbns=edge2cen(bns);
[hh]=bar(cbns, [sig(:) nsig(:)],'stacked');
xlim(x_lim);
set(gca, 'YAxisLocation','left');
set(hh(1),'FaceColor','k')
set(hh(2),'FaceColor',[1 1 1])
set(gca,'box','off','YLim',[0 maxy])
set(gca,'Color','none')
text(getx,gety,[num2str(round(100*mean(x_sig))) '% p<0.05'])

x_mean=nanmean(x);
[xt_sig,xt_mu,B]=bootmean(x);

[CI]=prctile(B,[2.5 97.5]);

x_se=nanstderr(x);

if xt_sig<0.05
    y_lim=ylim(hx);
    y_lim=y_lim(2);
    hold(hx, 'on')
    plot(hx,[x_mean],[0.9*y_lim],'.k','MarkerSize',6);
    plot(hx,[CI(1) CI(2)], [0.9*y_lim 0.9*y_lim], '-k');
    
end
 

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




