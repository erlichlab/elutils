function [binc, mu, se, n, ytob]=binned(x,y, varargin)
%  [binc, mu, se, n]=binned(x,y,bin_e)
% Takes a vector x and a vector y and returns mean and standard error of
% values of y for bins of x.
%
% Input:
% x     1xn vector of x values to bin
% y     1xn vector of y values to average 
%
% Optional Input:
% 
% n_bins Optional # of bins. Default 10
% bin_e Optional bin edges.  Otherwise will return n_bins bins with equal # of samples from
%       min(x) to max(x)
%
% Output:
% binc      1xm bin centers
% mu        1xm The average value of y at that bin 
% se        1xm The standard error of y at that bin
% n         1xm The number of values of y in this bin


bin_e=[];
plot_it=false;
plot_fit='';
plot_fit_x0=[0 1 0 10];
n_bins=10;
clr='k';
func=@nanmean;

overridedefaults(who,varargin);
x=x(:);
y=y(:);
ytob=nan+y;
if isempty(bin_e)
    pbins=linspace(0,100,n_bins+1);
    bin_e=prctile(x,pbins);
end

binc=(bin_e(2:end)+bin_e(1:end-1))/2;
mu=nan(size(binc));
se=nan(size(binc));

if all(y==0 | y==1 | isnan(y))
    binomial_data=true;
else
        binomial_data=false;
end

[n,yx]=histc(x,bin_e);

for nx=1:(numel(n)-1)
    tmp=func(y(yx==nx));
    if isempty(tmp)
        tmp=nan;
    end
    mu(nx)=tmp;
    
    ytob(yx==nx)=nx;
    if binomial_data
       [~,ci]=binofit(nansum(y(yx==nx)),sum(yx==nx));         
        se(nx)=max(abs(mu(nx)-ci));  
    % this is bad for low n.  
    else
    se(nx)=nanstderr(y(yx==nx));
    end
end

n=n(1:end-1);

if plot_it
    
    errorplot(gca,binc, mu, se,'Marker','o','Color',clr);
    if ~isempty(plot_fit)
        beta=nlinfit(x,y,plot_fit,plot_fit_x0);
        xx=linspace(binc(1),binc(end),1000);
        yy=plot_fit(beta,xx);
        hold on;
        plot(xx,yy,'-','Color',clr);
    end
    
    if binomial_data
        ylim([0 1]);
    end
    
    
end

    
    
