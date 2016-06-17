function p=norm2d(b,x)

mu(1) = b(1);
mu(2) = b(2);
sig(1,1) = b(3);
sig(1,2) = b(4);
sig(2,1) = b(4);
sig(2,2) = b(5);
try
p = mvnpdf(x, mu, sig);
catch me
    p = zeros(size(x(:,1)));
end