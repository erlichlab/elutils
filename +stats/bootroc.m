function varargout=bootroc(A,B,BOOTS, CI)
% [auc, auc_p, auc_ci]=bootroc(A,B,BOOTS, CI);
%
% A is a vector of the value of elements from condition A
% B is a vector of the value of elements from condition B
% 
if nargin<3
	BOOTS=1000;
end

if nargin<4
  CI=99.5;
end


A=A(~isnan(A));
B=B(~isnan(B));

if isempty(A) || isempty(B)
    sd=nan;
    sd_p=nan;
    boot_score=nan;
else

sd=auc(A,B);
sA=numel(A);
ALL_DATA=[A(:);B(:)];
boot_score=0.5+zeros(BOOTS,1);
parfor bx=1:BOOTS

	shuff_d=ALL_DATA(randperm(numel(ALL_DATA)));
	A=shuff_d(1:sA);
	B=shuff_d(sA+1:end);

	boot_score(bx)=auc(A,B);
end

sd_p=get_p(sd, boot_score);
end

varargout{1}=sd;
varargout{2}=sd_p;
varargout{3}=prctile(boot_score, [(100-CI)  CI]);