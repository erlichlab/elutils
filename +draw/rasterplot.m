function [yM,xM,h]=rasterplot(r,t,pre,post, varargin)
% [yM,xM,h]=tsraster2(r,t,pre,post, varargin)
% Drows a rasterplot of two point processes, r(ef) and t(arget)
% using a time w(indow) in seconds.
% either provide one window input and it will use +/- w or provide pre and
% post.
% r and t should be vectors of timestamps in seconds
% if would be way faster if i find the smaller of r and t and run through
% r.  but i'm not using this for the bootstrap anyway.



%% SETUP

r=r;
t=t;

if nargin<4
    post=pre;
end

% if either are empty return empty

if isempty(r) 
    yM=[]; xM=[];
     return
end

if isempty(t)
    t=r(1)-pre-1;
end

% if w is zero or negative, complain

if (post+pre)<=0
    y=[];
    display('window is negative in size')
    return
end

% make sure r and t are column vectors.

if isvector(r)
    r=r(:);
else
    % we might have passed in multipl refs. use the first one
r=r(:,1);
end
t=t(:);


% deal with vararin
opts.plotthis=1;
opts.post_mask=+inf;
opts.pre_mask=-inf;
opts.events=[];   % this should be a struct with name, 

parseargs(varargin,opts,{},1);

if isscalar(post_mask)
    post_mask=repmat(post_mask, size(r));
end

if isscalar(pre_mask)
    pre_mask=repmat(pre_mask, size(r));
end



%% The meat of the code.  Really brain dead simple.


spks=zeros(numel(t),2);
spk_ind=1;
for i=1:numel(r)
    s=r(i)-pre;
    f=r(i)+post;
    cc=qbetween(t, s,f)-r(i);
    cc=cc(cc>pre_mask(i));
    cc=cc(cc<post_mask(i));
    
    if isempty(cc)
        cc=nan;
    end
    s_inc=numel(cc);
    %spks=[spks; cc(:), zeros(size(cc(:)))+i];
    spks(spk_ind:spk_ind+s_inc-1,:)=[cc, zeros(s_inc,1)+i];
    spk_ind=spk_ind+s_inc;

end

spks=spks(1:spk_ind-1,:);
    

xM=zeros(size(spks,1)*3,1);
yM=xM;

xM(1:3:end)=spks(:,1);
xM(2:3:end)=spks(:,1);
xM(3:3:end)=nan;

yM(1:3:end)=spks(:,2);
yM(2:3:end)=spks(:,2)+.8;
yM(3:3:end)=nan;

if plotthis
    h=plot(xM,yM,'k');
end




%% it might be worth returning an unbinned vector

