function [auc_val, auc_p,varargout]=slidingROC(stim, nostim, varargin)
% [auc_val, auc_p,varargout]=slidingROC(stim, nostim, [boots, alph])
% takes 2 matrices , stim & nostim, of equal number of columns.
% using ROC analysis (see auc.m)
% returns a vector whose length is the  column width of stim

% # of columns must be equal

if size(stim,2) ~= size(nostim,2)
    error('must be equal # of columns')
end
pairs={
    'boots', 2000;...
    'alph',99;...
    };
parseargs(varargin,pairs,{},1);

auc_val=auc(stim,nostim);
M=[stim; nostim];
num_stim=size(stim,1);
num_all=num_stim+size(nostim,1);
auc_b=zeros(boots,size(stim,2))+0.5;

parfor bx = 1:boots
    rind=randperm(num_all);
    stim=M(rind(1:num_stim),:);
    nostim=M(rind(num_stim+1:num_all),:);
    [auc_b(bx,:)]=auc(stim,nostim);
end

auc_p=get_p(auc_val, auc_b);

if nargout==3
    varargout{1}=auc_b;
end
