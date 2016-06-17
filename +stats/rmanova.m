function [D,Pa]=rmanova(M)
%[D,Pa]=rmanova(M)
% Input 
%   M each row is a subject and each column is a condition
% Output
%   D is a matrix where the rows are Conditions, Subjects, Interaction, Total
%                           cols are Sum^2, DF, MSE, F 
%   Pa is the p value for the conditions subjects effect.

n=size(M,1);
a=size(M,2);

rowMu=mean(M,1);


SSa = n*sum((rowMu-mean(rowMu)).^2);

colMu=mean(M,2);

tt1=(colMu-mean(rowMu)).^2;

SSs = a*sum(tt1(:));

SSt=sum(sum((M-mean(rowMu)).^2));

SSas=SSt-SSa-SSs;

DFa=a-1;
DFs=n-1;
DFas=DFa*DFs;
DFt=a*n;

MSa=SSa/DFa;
MSs=SSs/DFs;
MSas=SSas/DFas;
Fa=double(MSa)/MSas;

Pa  = 1-fcdf(Fa, DFa, DFas);

D=[SSa DFa MSa Fa; SSs DFs MSs nan; SSas DFas MSas nan; SSt DFt nan nan];

fprintf('F(%d,%d)=%.2f, p=%.2f\n', DFa, DFas, Fa, Pa);
