function y=nanzscore(x)

mu=nanmean(x);
sd=nanstd(x);
y=(x-mu)./sd;