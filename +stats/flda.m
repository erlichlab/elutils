
function v=flda(varargin)
% v = flda(G1,G2)
% v = flda(mean1,mean2,cov1,cov2,n1,n2)
%
% v is fisher's linear discriminant between the two "groups" of data
% Using syntax 1
% G1 is an n x d matrix
% G2 is an m x d matrix
% Using syntax 2
% Group1 has mean mu1, covariance cov1, and n1 number of samples
% Group2 has mean mu2, covariance cov2, and n2 number of samples
% v is a d x 1 vector
%
% http://www.csd.uwo.ca/~olga/Courses//CS434a_541a//Lecture8.pdf

if nargin==2
    X=varargin{1};
    Y=varargin{2};
    
    
    [x_n, xdim]=size(X);
    [y_n, ydim]=size(Y);
    
    if xdim~=ydim
        error
    end
    
    muX=nanmean(X,1);
    muY=nanmean(Y,1);
    
    nX=X-repmat(muX,x_n,1);
    nY=Y-repmat(muY,y_n,1);
    
    nX(isnan(nX))=0;
    nY(isnan(nY))=0;
    
    
    S1 = nX'*nX;  % This is an estimate of the covariance matrix -> divide by x_n to get COV(X)
    S2 = nY'*nY;
elseif nargin==6
    muX=varargin{1};
    muY=varargin{2};
    cx=varargin{3};
    cy=varargin{4};
    nx=varargin{5};
    ny=varargin{6};
    S1 = cx*(nx-1);
    S2 = cy*(ny-1);
    
end

Sw=S1+S2;
% Solve eigenproblem Sb*V = Lambda*Sw*V

v=Sw\(muX-muY)';

