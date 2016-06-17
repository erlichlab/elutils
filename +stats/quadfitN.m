function [H, d, c, e, fit] = quadfitN(xs, Fs, at_ori)
% function [H, d, c, e] = quadfitN(xs, Fs, [at_ori])
%
% least-square fit of a quadratic function to points in N dimensions
%
%
% INPUTS:
%
%   xs      N x M matrix, where N is the number of dimensions and M is the
%           number of data points
%
%   Fs      1 x M vector, the functional values corresponding to each
%           column in xs
%
%   at_ori  optional parameter, 0 by default
%           if at_ori = 1, then [xs = 0, Fs = 0] is assumed to be the extremum 
%           of the quadratic function
%
% OUTPUTS:
%
%   H       N x N matrix, the hessian matrix of second derivatives of the
%           fit
%
%   d       1 x N vector, linear terms
%
%   c       a scalar, the constant term
%
%   e       1 x M vector, the error of the computed fit



if nargin<3,
    at_ori = 0;
end;

[N M] = size(xs); % N dimensions, M points


if at_ori,
    X = zeros(M, sum(1:N)); % there are sum(1:N) quadratic terms
    for m = 1:M,
        myx = xs(:,m)'; % this data point
        myterms = [];
        for i = 1:N,
            for j = i:N,
                if i==j, scale = 2; else scale = 1; end;
                myterms = [myterms myx(i)*myx(j)/scale]; %#ok<AGROW>
            end;
        end;
        X(m,:) = myterms;
    end;
else
    X = zeros(M, sum(1:N)+N+1); % there are sum(1:N) quadratic terms, N linear terms, and 1 constant term
    for m = 1:M,
        myx = xs(:,m)'; % this data point
        myterms = [];
        for i = 1:N, % the quadratic terms
            for j = i:N,
                if i==j, scale = 2; else scale = 1; end;
                myterms = [myterms myx(i)*myx(j)/scale]; %#ok<AGROW>
            end;
        end;
        myterms = [myterms myx 1]; %#ok<AGROW> % the linear and constant terms
        X(m,:) = myterms;
    end;    
end;


% solve for A in X*A = Fs, 
A = pinv(X)*Fs(:);


% unpack A into H, d, and c
H = zeros(N,N);
d = zeros(1,N);
c = 0;
mark = 1;
for i = 1:N,
    for j = i:N,
        H(i, j) = A(mark);
        H(j, i) = H(i, j); % symmetry
        mark = mark+1;
    end;
end;
if ~at_ori,
    for i = 1:N,
        d(i) = A(mark);
        mark = mark+1;
    end;
    c = A(mark);
end;

e = Fs - (diag(xs'*H*xs*0.5)' + d*xs + c);
fit = @(ns)(diag(ns'*H*ns*0.5)' + d*ns + c);