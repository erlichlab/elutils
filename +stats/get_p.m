function y= get_p(datumM, distM, tails, high)
% get_p - Empirical p-value(s) from a permutation or bootstrap distribution
%
% Syntax:
%   p = stats.get_p(datumM, distM)
%   p = stats.get_p(datumM, distM, tails, high)
%
% Inputs:
%   datumM - Scalar or vector of observed values.
%   distM  - Vector or matrix of null distribution samples.
%             If distM is m×n, then datumM must be 1×n.
%   tails  - Number of tails for the test (default = 2).
%             1 = one-tailed; 2 = two-tailed.
%   high   - For one-tailed tests, test direction:
%             1 = upper tail (datum > null)
%             0 = lower tail (datum < null)
%
% Output:
%   p      - Empirical p-values, same size as datumM.
%
% Notes:
%   - Computes the empirical probability that 'datumM' is as or more
%     extreme than samples in 'distM', optionally two-tailed.
%   - For two-tailed tests, p-values are doubled and capped at a minimum
%     of 2/N, where N = number of samples in distM.
%   - For one-tailed tests, p-values reflect the proportion of the null
%     distribution more extreme in the specified direction.
%
% References:
%   Nichols & Holmes (2002), Human Brain Mapping 15(1): 1–25.
%   Maris & Oostenveld (2007), J. Neurosci. Methods 164(1): 177–190.

% check that inputs are the right size
if nargin<3
    tails=2;
end

if nargin<4
    high=1;
end
reuse_flag=0;
if numel(datumM)==1 && isvector(distM)
	distM=distM(:);
elseif numel(datumM)>1 && isvector(distM);
    reuse_flag=1;
elseif isscalar(datumM) && ~isvector(distM)
    datumM=repmat(datumM,1,size(distM,2));
elseif numel(datumM)~=size(distM,2)
    error('GET_P:BADINPUTS','Number of columns of distM must equal lenght of datumM or distM must be a vector')
end


y=ones(size(datumM));

for dx=1:numel(datumM)

    datum=datumM(dx);
    if reuse_flag
    dist=distM(:);
    else
    dist=distM(:,dx);
    end
    
    if isnan(datum) || all(isnan(dist))
        y(dx)=nan;
        continue;
    end
    dist=dist(~isnan(dist));
    ps=linspace(0,100,numel(dist));  % this limits the lowest p value it is possible to return. Maybe this should be relative to the size of dist
    sd_ps=prctile(dist,ps);
    closest= stats.qfind(sd_ps,datum);
    if tails==2
        if closest<=0  % datum out of range
            others=1; 
        else
            others=find(sd_ps==sd_ps(closest));
        end
        if ps(others(1))<50 && ps(others(end))>50
            % if the datum stradles the mean.
            sd_p=1;
        elseif datum<sd_ps(1)||datum>sd_ps(end)
            % if the datum is outside the range of the bootstrapped distro
            sd_p=2/size(distM,1);
        elseif ps(others(1))>50
            sd_p=ps(others(1))/100;
            sd_p=max(2*(1-sd_p),2/size(distM,1));
        else
            sd_p=ps(others(end))/100;
            sd_p=2*sd_p;
        end
        y(dx)=sd_p;
    elseif tails==1
        % if there are repeat values in sd_ps, closest returns the max of the indices
        % of these.  But we actually want the min of these indices so we find the
        % others which have the same value and take the min of these.
        if closest<=0
            if high
                y(dx)=1;
            else
                y(dx)=1/size(distM,1);
            end
        else
            others=find(sd_ps==sd_ps(closest));
            y(dx)=abs(high-ps(others(1))/100);
        end
    else


    end
end

