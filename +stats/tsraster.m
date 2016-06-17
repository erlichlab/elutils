function [y,varargout]=tsraster(r,t,varargin)
% [y,x]=tsraster(r,t,['pre',2,'post',2,'bin_size',0.01)
% Computes the cross-correlation of 2 point processes, r(ef) and t(arget)
% using a time w(indow) in sec.
% either provide one window input and it will use +/- w or provide pre and
% post.
% r and t should be vectors of timestamps in sec
%
% bins are LEFT-ALIGNED.  Meaning the bin at x==0 are the spikes from 0 to
% bin_size
%
% note: instead of a list of option one can pass options as a struct:
% opt.pre=2; opt.post=4; .....


%% SETUP

pairs={ 'post'      2;...
        'pre'       2;...
        'bin_size'       0.01;...
        };

parseargs(varargin,  pairs,{},1);  
    
% if either are empty return empty

if isempty(r) 
    y=[];
    varargout{1}=[];
    return
end

if isempty(t)
    t=r(1)-pre-bin_size-1;
end

% if w is zero or negative, complain

if (post+pre)<=0
    y=[];
    error('window is negative in size')
    return
end

% make sure r and t are column vectors.

r=r(:);
t=t(:);


%% The meat of the code.  Really brain dead simple.
y=zeros(length(r),length(-pre:bin_size:post)-1);
for i=1:length(r)
    % old slow way
    %    cc=t-r(i);
    %    cc=cc((cc>-pre)&(cc<post));
    s=r(i)-pre;
    f=r(i)+post;
    if isnan(s)
        y(i,:)=nan;
    else
    cc=qbetween(t, s,f)-r(i);
    if ~isempty(cc)
    cc=histc(cc,-pre:bin_size:post);
    cc=cc(:)';
    y(i,:)=cc(1:end-1);
    end
    end
end
if nargout==2;
x=-pre:bin_size:post;
varargout{1}=x(1:end-1);
end

%% it might be worth returning an unbinned vector

