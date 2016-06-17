%drawgaussian	Draw the 1-sigma lines for a 2d gaussian
%
% 	[h] = drawgaussian(mean, [sigmax, sigmay, r | C], ...
%                 {'angstart', 0}, {'angend', 360}, {'useC', 0})
%
% Draws the nth-sigma lines for a gaussian in the current
% figure. Since it uses LINE to do this, it returns a handle to
% that line. 
%
% 'mean' must be a 2 element vector, first component <x>, second
% <y>. 
%
% sigmax is the standard deviation of x; sigma y the standard
% deviation of y; and r is defined as
% <(x-<x>)*(y-<y>)>/(sigmax*sigmay) and thus lies in [0,1). If
% only two arguments are passed, the second is assumed to be a
% two-by-two covariance matrix.
%


function [hout] = drawgaussian(mean, sigmax, sigmay, r, varargin)
   
   pairs = { ...
       'angstart'      0   ; ...
       'angend'      360   ; ...
       'useC'          0   ; ...
	   'filled'        0   ; ...
	   'alph'          1   ; ...
	   'nth_sigma'     1   ; ...
	   'drawline'      0   ; ...
   }; parseargs(varargin, pairs);
      
   if ~isempty(find(isnan(sigmax(:))))  ||  ...
	  (nargin>2 && ~isempty(find(isnan(sigmay(:))))),
      hout = [];
      return;
   end;
   npoints = 100;
   X = zeros(2, npoints+1);
   p = zeros(2,1);
   
   if nargin <= 2 || useC,
      covar = sigmax;
   else
      covar = [sigmax^2, r*sigmax*sigmay; ...
	 r*sigmax*sigmay, sigmay^2];
   end;
   
   [E, D] = eig(covar);
   
   D = nth_sigma * sqrt(D);   % sigma, not sigma^2
   
   for i=1:npoints
      theta = (angend - angstart)*(i-1)/(npoints-1) + angstart;
      theta = pi*theta/180;
      p(1) = D(1,1) * cos(theta);
      p(2) = D(2,2) * sin(theta);
      X(:,i) = E*p;
   end;
   if rem(angend,360) == rem(angstart,360), 
      X(:,end) = X(:,1);
   else
      X = X(:,1:end-1);
   end;
   
   if drawline, edgecolor = 'k'; else edgecolor = 'none'; end;
   
   if filled,
	   h = patch(X(1,:)+mean(1), X(2,:)+mean(2), 'r', 'FaceAlpha', min(1, alph), 'EdgeColor', edgecolor);
   else
	   h = line(X(1,:)+mean(1), X(2,:)+mean(2));
   end;
   
   if nargout > 0,
      hout = h;
   end;
   