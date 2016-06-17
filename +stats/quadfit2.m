function [H, d, c, e] = quadfit2(xs, Fs, at_ori)
% function [H, d, c, e] = quadfit2(xs, Fs, [at_ori])

if nargin<3,
    at_ori = 0;
end;

n = size(xs, 2);

if at_ori, % if (0,0) is the extremum, then fit quadratic terms only
    X = zeros(n, 3);
    for p = 1:n,
        x = xs(:,p);
        X(p,:) = [x(1)^2/2 x(1)*x(2) x(2)^2/2];
    end;
else
    X = zeros(n, 6);
    for p = 1:n,
        x = xs(:,p);
        X(p,:) = [x(1)^2/2 x(1)*x(2) x(2)^2/2 x(1) x(2) 1];
    end;
end;


% solve for A in X*A = Fs, 
A = pinv(X)*Fs(:);

H = zeros(2,2);
d = zeros(1,2);
c = 0;

H(1,1) = A(1);
H(1,2) = A(2); H(2,1) = H(1,2);
H(2,2) = A(3);
if ~at_ori,
    d(1)   = A(4);
    d(2)   = A(5);
    c      = A(6);
end;
e = Fs - (diag(xs'*H*xs*0.5)' + d*xs + c);
