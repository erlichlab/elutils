function y=get_p(datumM, distM, tails, high)
% p=get_p(datum, dist)
% p=get_p(datum, dist, tails, high)
% p is the prob that datum comes from dist.
% tails is by default 2
% if tails == 1 , then p is the prob that datum
% is higher (if high==1) or lower (if high==0) than dist.
% datum can be a single value or a 1 by n vector
% dist  can be a vector  or an m by n matrix
% p is the probability of datum in dist

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
    closest=qfind(sd_ps,datum);
    if tails==2
        if closest==-1  % datum out of range
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
        if closest==-1 && high
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

