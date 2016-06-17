function varargout=bootvar(varargin)
% [p,ci]=bootvar(A,B,['boots'])
% When passed in a single vector, tests whether the variance is different from 1
% When passed in two vectors does a permutation test to see whether the variances
%	are significantly different
% Optional inputs:
%   'boots'  the number of shuffles to perform (5000)


if isnumeric(varargin{2})
    A=varargin{1};
    B=varargin{2};
    one_dist=false;
    if nargin>2
        varargin=varargin(3:end);
    else
        varargin={};
    end
else
    A=varargin{1};
    one_dist=true;
    if nargin>1
        varargin=varargin(2:end);
    else
        varargin={};
    end
end


boots=5000;


overridedefaults(who,varargin);
	

if one_dist
	% assume test whether variance of the population is differenct from one.
    dist=A;
    if isvector(dist)
        dist=dist(:);
    end
	n=size(dist,1);
    
	[B]=bootstrp(boots, @nanvar, varargin{1});
	
	ps=[0:0.01:100];
	sd_ps=prctile(B,ps);

    sd_p=get_p(1,B);
	
	varargout{1}=sd_p;
	varargout{2}=prctile(B,[2.5 97.5]);
    varargout{3}=B;
	
elseif ~one_dist
	sA=size(A,1);
	sB=size(B,1);
	sd=nanvar(A)-nanvar(B);
    
    if min(sA,sB)<=7
        warning('Not meaningful to compute 5000 bootstraps when n=<7');
        boots=factorial(min(sA,sB));
    end
    
	ALL_DATA=[A;B];
	boot_score=zeros(boots,size(ALL_DATA,2));
	for bx=1:boots
		shuff_d=ALL_DATA(randperm(sA+sB),:);
		A=shuff_d(1:sA,:);
		B=shuff_d(sA+1:end,:);
		boot_score(bx,:)=nanvar(A)-nanvar(B);
	end
	
	sd_p=get_p(sd, boot_score);   
end
	varargout{1}=sd_p;
	varargout{2}=prctile(B,[2.5 97.5]);
	