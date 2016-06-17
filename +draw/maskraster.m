function [maskM,x]=maskraster(x,y,pre,post,varargin)
% [y,x]=maskraster(x,y,pre,post,[null_value])
%
opts.null_value=nan;

parseargs(varargin,opts,{},1);

% x is a row vector of length s
% y is a matrix with s columns and t rows
% pre is a vector of length t (or scalar)
% post is a vector of length t (or scalar)
%
% The function turns any elements of y that are before pre or after post
% into NaNs.  If pre or post falls into the middle of a bin that bin is set
% to NaN



%% Check that everything is the right length
maskM=[];
if numel(x) ~= size(y,2)
    fprintf(1,'numel(x) must equal size(y,2)');
    return;
end

if isscalar(pre)
    pre=zeros(1,size(y,1))+pre;
elseif numel(pre)~=size(y,1)
    fprintf(1,'numel(pre) must equal size(y,2) or be scalar');
    return;
end    


if isscalar(post)
    post=zeros(1,size(y,1))+post;
elseif numel(post)~=size(y,1)
    fprintf(1,'numel(post) must equal size(y,2) or be scalar');
    return;
end

%% now loop through the trials
    maxx=numel(x);
    prex=qfind(x,pre); 
    postx=qfind(x,post);
    maskM=y;
    
    for tx=1:numel(prex)
        
        if ismember(prex(tx),x)
            prex(tx)=prex(tx)-1;
        end
        % if prex is in the range of x
        if prex(tx)>0 && prex(tx)<=maxx;
        maskM(tx,1:prex(tx))=null_value;
        elseif isinf(pre(tx)) && pre(tx)>0
            maskM(tx,:)=null_value;
        end
        
        if postx(tx)>0 && post(tx)<=x(end)
            maskM(tx,postx(tx):end)=null_value;
        elseif isinf(post(tx)) && post(tx)<0
            maskM(tx,:)=null_value;
        end
    end
    
        
    
    
    



