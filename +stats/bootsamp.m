function [Y]=bootsamp(X,nboots,varargin)

Nmu=0;
Nsig=0;

n_samp=size(X,1);

overridedefaults(who,varargin);


indx=randInts([nboots 1],1,n_samp);

if Nsig>0
    Y=X(indx,:)+randn(nboots,size(X,2))*Nsig+Nmu;
else
    Y=X(indx,:);
end