function [hm]=scattersig(x, y,sig, varargin)
% [hm, hx, hy]=scattersig(x, sig, y, x_lim, y_lim)
% Optional arguments:
% width, hist_height, num_bins, x_label, y_label
%
% E.g
% x = randn(150,1)*2;
% y = randn(250,1)*4+3;
% y = randn(150,1)*4+3;
% xsig = abs(x)>2;
% ysig = y<0;
% draw.scatter_histhist(x,y,sig,'x_label','X','y_label','Y')


iod = @utils.inputordefault;
hm=iod('ax',[], varargin);
fh=iod('fh',[], varargin);
marker_size = iod('marker_size',24,varargin);
x_label=iod('x_label','',varargin);
y_label=iod('y_label','',varargin);
text_display = iod('text',sprintf('n=%d',sum(isfinite(x))),varargin);%empty for default, off for skip, others for user defined text

x_lim_b=[min(x)-0.1 max(x)+0.1];
y_lim_b=[min(y)-0.1 max(y)+0.1];

x_lim = iod('x_lim',x_lim_b,varargin);
y_lim = iod('y_lim',y_lim_b,varargin);

if isempty(fh)
    figure
else
    figure(fh);
end
if isempty(hm)
    hm=draw.jaxes;
end
set(hm,'Xlim',[-1 1]);
set(hm,'Ylim',[-1 1]);

% make the scatter plot

scatter(hm,x(sig==0), y(sig==0), marker_size,'k');
scatter(hm,x(sig==1), y(sig==1), marker_size,'k','filled');
xlabel(hm,x_label);
ylabel(hm,y_label);
xlim(hm,x_lim);
ylim(hm,y_lim);
draw.xhairs(hm,'k:',0,0);
axes(hm);
if ~isempty(text_display)
    text(getx,gety,text_display)
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
