
function [mu, se]=cellmean(M,varargin)
% [mu, se]=cellmean(M,varargin)

dim=1;

overridedefaults(who,varargin)

mu=nan(1,numel(M));
se=mu;


for fx=1:numel(M)
    if numel(M{fx})<2
        mu(fx)=nan;
        se(fx)=nan;
    else
        mu(fx)=nanmean(M{fx},dim);
        se(fx)=nanstderr(M{fx},dim);
    end
end