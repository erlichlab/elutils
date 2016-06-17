function [roc_p,roc_v,D]=roc_post_regress(Y, X, G, varargin)
% [roc_p,roc_v,D]=roc_post_regress(Y, X, G, varargin)
% Performs a sliding ROC analysis on the residuals of the regression of Y
% with X after excluding non-significant regressors [at p<0.01 by default].
% Y     an M x N data matrix
% X     a cell array of M x N data matrices.  
% G     an M x 1 binary array, describing which rows of Y belong to which
%       category
% 
% Note: the evaluation of the significance of regressors assumes that the
% bins of Y are independent.  If the bins of Y are not independent because 
% of smoothing, the regressors are more likely to be significant.


pairs={'alph' 0.01;
    'quick', 0;
    };
parseargs(varargin, pairs);

[m,n]=size(Y);

Y=Y(:);



if iscell(X)
Xp=ones(numel(X{1}), numel(X)+1);
    for cx=1:numel(X)
        Xp(:,cx)=X{cx}(:);
    end
else
    Xp=X;
end

clear X
        
% do the regression with p<0.01 for each coefficient

[B,BINT,R,RINT,STATS] = regress(Y,Xp,alph);

% remove parameters that are not significant 

keeps=prod(BINT,2)>0;
keeps(end)=true;  % This is probably not necessary, but just in case, we don't want to break the regression.


if all(keeps==false)
    fprintf('No regressors are significant.  Performing ROC on Y\n');
    R=Y;
elseif any(keeps==false)    
    Xpr=Xp(:,keeps);
    [B,BINT,R,RINT,STATS] = regress(Y,Xpr,alph);
end

Rm=reshape(R,m,n);

aM=Rm(G==0,:);
bM=Rm(G==1,:);



if quick
% This is MUCH faster, but less accurate.
 roc_v=auc(aM,bM);
 [~,roc_p]=ttest2(aM,bM);
else
[roc_v,roc_p]=slidingROC(aM,bM);
end

D.keeps=keeps;
D.B=B;
D.BINT=BINT;
D.Rm=Rm;
D.RINT=RINT;
D.STATS=STATS;
D.roc_v=roc_v;
D.roc_p=roc_p;

[roc_p,pi]=min(roc_p);
roc_v=roc_v(pi);


