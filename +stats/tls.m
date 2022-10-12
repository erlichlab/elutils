function [out] = tls(X, varargin)
% s = tls(X,['ax'])
% Fit a total-least-squares line to the data in X
% X should have two columns. Each row is a pair of data points
%
% 'ax' is an axes handle. If it is passed in draw a line on the axis.
%
% s is a structure with the following fields:
% s.slope slope of the line
% s.int y-intercept of the line
% s.linehandle handle to the line drawn on the axis (if 'ax' is passed in, otherwise [])


if nargin==0
    %DEMO MODE
    X = randn(100,1)*10 + 35;
    X(:,2) = X(:,1) + randn(100,1)*5 - 20;
    figure()
    ax = draw.jaxes;
    plot(ax,X(:,1),X(:,2),'o')
    out  = stats.tls(X,'ax',ax); 
    out.eig1  
  return
end
%%
args = varargin;
[ax, args] = utils.inputordefault('ax',[],args);
utils.inputordefault(args);

meanX = mean(X,1);
nX = X - meanX;
[V,~] = eig(nX'*nX);
out.eig1 = V(:,1);
out.slope = -(out.eig1(1))/(out.eig1(2));
out.intercept = meanX(2) - out.slope*meanX(1);

if ~isempty(ax)
    a = get(ax,'xlim');
    b = out.slope*a + out.intercept;
    out.linehandle = plot(ax,a,b,'r');
else
    out.linehandle = [];
end



end

