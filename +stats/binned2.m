function [xbinc, ybinc, mu, se, n]=binned2(x,y,z, varargin)
%  [binc, mu, se, n]=binned2(x,y,z,bin_e)
% Takes a vector x and a vector y and returns mean and standard error of
% values of z for bins of x and y.
%
% Input:
% x     1xn vector of x values to bin
% y     1xn vector of y values to bin
% z     1xn vector of z values to average in each bin
%
% Optional Input [=default]: 
%
% n_bins=10         Optional # of bins. 
% n_x_bins=n_bins   Specify # of x bins. Overrides n_bins 
% n_y_bins=n_bins   Specify # of y bins. Overrides n_bins
% even_bins=false   By default bins have equal # of data points. If this is
%                   true then bins are evenly spaced and have uneven sample
%                   sizes
%
% xbin_e=[]         Optional bin edges for the x-axis.  Overrides all
%                   earlier options
% 
% ybin_e=[];        Optional bin edges for the y-axis.  Overrides all
%                   earlier options
% plot_it=false;
% ax=[];            if plot_it=true, plot to this axis
%
% Output:
% binc      1xm bin centers
% mu        1xm The average value of y at that bin
% se        1xm The standard error of y at that bin
% n         1xm The number of values of y in this bin


check_inputs(x,y,z)
    
xbin_e=[];
ybin_e=[];
ax=[];
plot_it=false;
n_bins=7;
n_x_bins=n_bins;
n_y_bins=n_bins;
even_bins=false;
func=@nanmean;

overridedefaults(who,varargin);


if isempty(ax) && plot_it
    ax=gca;
end

if isempty(xbin_e)
    if even_bins
        xbin_e=linspace(min(x),max(x),n_x_bins+1);
    else
        pbins=linspace(0,100,n_x_bins+1);
        xbin_e=unique(prctile(x,pbins));
    end
end

if isempty(ybin_e)
    if even_bins
        ybin_e=linspace(min(y),max(y),n_y_bins+1);
    else
        pbins=linspace(0,100,n_y_bins+1);
        ybin_e=unique(prctile(y,pbins));
    end
end


clr=cool(numel(ybin_e)-1);

xbinc=(xbin_e(2:end)+xbin_e(1:end-1))/2;
ybinc=(ybin_e(2:end)+ybin_e(1:end-1))/2;
mu=repmat(nan,numel(ybinc),numel(xbinc));
se=mu;

x=x(:);
y=y(:);
z=z(:);

% split the data up by y

[~,yind]=histc(y,ybin_e);
[~,xind]=histc(x,xbin_e);

if all(z==1 | z==0)
    binomial_data = true;
else
    binomial_data = false;
end
    

for ny=1:numel(ybinc)
    for nx=1:numel(xbinc)
        tmp = func(z(xind==nx & yind==ny));
        if isempty(tmp)
            tmp=nan;
        end
        mu(ny,nx)=tmp;
        if binomial_data
            sigma = sum(z(xind==nx & yind==ny));
            count = sum(xind==nx & yind==ny);
            [~,ci]= binofit(sigma,count);
            
            se(ny,nx)=max(abs(ci-mu(ny,nx)));
        else
        se(ny,nx)=nanstderr(z(xind==nx & yind==ny));
        end
        n(ny,nx)=sum(~isnan(z(xind==nx & yind==ny)));
    end
    
end

if plot_it
    for ny=1:numel(ybinc)
        hh(ny,:)=errorplot(ax,xbinc, mu(ny,:), se(ny,:),'Marker','o','Color',clr(ny,:));
        set(hh(ny,2),'LineStyle','-','LineWidth',2)
    end
end

function check_inputs(x,y,z)

if ~iscolumn(x) || ~iscolumn(y) || ~iscolumn(z)
    error('x,y & z must all be column vectors');
end

if ~isequal(size(x), size(y)) || ~isequal(size(x), size(z)) || ~isequal(size(y), size(z))
    error('x, y & z must all be column vectors of equal length');
end



