function [mu,se]=withinstderr(M)

col_mean=nanmean(M,2);
row_mean=nanmean(M,1);
grand_mean=mean(M(:));
nM=bsxfun(@minus,M,col_mean)+grand_mean;
mu = nanmean(nM,1);
se=nanstderr(nM,1);