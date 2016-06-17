function [val, valci, pval, cx]=slidingStat(func, stim, nostim, varargin)
% [auc]=slidingROC(stim, nostim, wndw, step)
% takes 2 matrices , stim & nostim, of equal number of columns.
% uses window and step to generate two distributions that are compared
% using ROC analysis (see dprime.m)
% returns a vector whose length is the  column width of stim

% # of columns must be equal

if size(stim,2) ~= size(nostim,2)
	error('must be equal # of columns')
end
wndw=0;
pairs={'wndw', 3;...
	'step_z', 1;...
	};
parseargs(varargin,pairs,{},1);

cx=1:step_z:(size(stim,2)-wndw+1);
val=zeros(length(cx),1);
pval=val+1;
valci=[val val];


	for k = 1:length(cx)
		t_stim=sum(stim(:,cx(k):cx(k)+wndw-1),2);
		t_nostim=sum(nostim(:,cx(k):cx(k)+wndw-1),2);
        t_stim=t_stim(~isnan(t_stim));
        t_nostim=t_nostim(~isnan(t_nostim));
		[val(k),pval(k),valci(k,:)]=feval(func,t_stim, t_nostim);
	end



