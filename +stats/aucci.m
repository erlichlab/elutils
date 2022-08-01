function varargout=aucci(A,B,BOOTS, CI)
% [auc, auc_p, auc_ci]=aucci(A,B,BOOTS, CI);
%
% A is a vector of the value of elements from condition A
% B is a vector of the value of elements from condition B
% 
if nargin<3
	BOOTS=1000;
end

if nargin<4
  CI=97.5;
end


A=A(~isnan(A));
B=B(~isnan(B));
num_A = numel(A);
num_B = numel(B);

if isempty(A) || isempty(B)
    sd=nan;
    sd_p=nan;
    boot_score=nan;
else

sd=stats.auc(A,B);
boot_score=nan(BOOTS,1);
for bx=1:BOOTS

	bA=utils.pick_n(A, num_A, 'with_replacement',1);
	bB=utils.pick_n(B, num_B, 'with_replacement',1);

	boot_score(bx)=stats.auc(bA,bB);
end

sd_p= stats.get_p(0.5, boot_score);
end

varargout{1}=sd;
varargout{2}=sd_p;
varargout{3}=prctile(boot_score, [(100-CI)  CI]);