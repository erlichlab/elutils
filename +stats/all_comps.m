function [p,ps]=all_comps(M,varargin)
% [p,ps]=all_comps(M,varargin)
% 
% Does series of ttests or permutation tests between N groups of samples using
% Bonferroni-Holm correction for multiple comparisons.
% 
% Input
% M         A matrix or a cell array of vectors.  Comparisons are between
%           colums or between elements of the cell array
%
% Optional Inputs
% 
% adjust_p=true;    If false does not correct for multiple comparisons
% use_ttest=true;   If false uses permutation tests (slower)
% nboots=2500;      The number of permutations to use if not using ttests
% do_median=false;  If true does a permutation test comparing medians.
%                   Overides use_ttest
% Output
% p                 The p-values for each comparison
% ps                An (n choose 2) x 2 matrix which describes which p
%                   values correspond to which comparison. Always 
%                   in numerical order, so this is just for convenience.

adjust_p=true;
use_ttest=true;
nboots=2500;
do_median=false;
overridedefaults(who,varargin);

if isnumeric(M)
    
    n_cols=size(M,2);
    ps=nchoosek(1:n_cols,2);
    p=nan(1,size(ps,1));

    for px=1:size(ps,1)
        V=M(:,ps(px,1))-M(:,ps(px,2));
        
        if do_median
            p(px)=bootmedian(V,'boots',nboots);
        else
            if use_ttest
                [~,p(px)]=ttest(V);
            else
                p(px)=bootmean(V,'boots',nboots);
            end
        end
    end
    
else
    
    % M is a cell array
    n_cols=numel(M);
    ps=nchoosek(1:n_cols,2);
    p=nan(1,size(ps,1));
    if do_median
        for px=1:size(ps,1)
            p(px)=bootmedian(M{ps(px,1)},M{ps(px,2)});
        end
    else
        for px=1:size(ps,1)
            p(px)=bootmean(M{ps(px,1)},M{ps(px,2)});
        end
        
    end
end 

if adjust_p
   p=bonf_holm(p);
end 