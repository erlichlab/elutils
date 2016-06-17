% [L,bic]=loglikelihood(M,y,np)
%
% Input
% M: a vector of probabilities (model predictions)
% y: a vector of binomial outcomes
% np: the number of parameters in the model
%
% Output
% L: the log likelihood
% bic: the bayesian information criteria

function [L,bic]=loglikelihood(M,y,np)

N(y==1)=M(y==1);
N(y==0)=1-M(y==0);
N(isnan(N))=[];
L=sum(log(N));
bic=2*-L+np*log(numel(N));