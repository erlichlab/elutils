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

% if isnumeric(M)

    N = nan+M;
    N(y==1)=M(y==1);
    N(y==0)=1-M(y==0);
    N(isnan(N) | isnan(M) | isnan(y))=[];
    L=sum(log(N));
    bic=2*-L+np*log(numel(N));
    

% not implemented yet
% else
    
%     modeltype = class(M);
%     nobs = M.NumObservations;
%     resp = M.Variables.(M.ResponseName);
%     fit = fitted(M);
%     llpt = log(fitted(M)*resp + (1-fitted(M))*(1-resp));
%     llpt(isnan(resp))=[];
%     switch modeltype
%         case 'GeneralizedLinearMixedModel'
%         case {'GeneralizedLinearModel','NonLinearModel'}
%             nparams = M.NumPredictors;
            
%     end
    
    
    