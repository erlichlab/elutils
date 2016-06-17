function [y]=auc(stim,nostim)
% computes the area under the curve.
% [y]=auc(stim,nostim)
% stim   is an a x n matrix
% nostim is an b x n matrix
% y      is a  1 x n matrix
%
% y(x) is the auc of the non-nan values of stim(:,x) and  nostim(:,x)

if isvector(stim)
if all(isnan(stim)) || all(isnan(nostim))
    y=nan;
else
stim=stim(~isnan(stim));
nostim=nostim(~isnan(nostim));
labels=[ones(numel(stim),1); zeros(numel(nostim),1)];
values=[stim(:);nostim(:)];

% Count observations by class
nTarget     = numel(stim);
nBackground = numel(nostim);

% Rank data
R = tiedrank(values);  % 'tiedrank' from Statistics Toolbox

% Calculate AUC
y = (sum(R(labels == 1)) - (nTarget^2 + nTarget)/2) / (nTarget * nBackground);
end
else
    for cx=1:size(stim,2)
        y(cx)=auc(stim(:,cx), nostim(:,cx));
    end
end
