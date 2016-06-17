function y=get_prctile(datumM, distM)
% p=get_p(datum, dist)
% p=get_p(datum, dist, tails, high)
% p is the percentile of datum in the distribution dist.
% datum can be a single value or a 1 by n vector
% dist  can be a vector  or an m by n matrix
% 
%  e.g. p=get_prctile(2,randn(1000,1));
%	 	   
%		p = 0.9799
%       


% check that inputs are the right size

if numel(datumM)~=size(distM,2)
	error('GET_P:BADINPUTS','Number of columns of distM must equal lenght of datumM')
end


y=ones(size(datumM));

for dx=1:numel(datumM)

	datum=datumM(dx);
	dist=distM(:,dx);


	ps=[0.001:0.001:10 10.1:0.1:90 90.001:0.001:99.999];
	sd_ps=prctile(dist,ps);
	closest=qfind(sd_ps,datum);
	if isnan(datum)
		% Then the value of from_uni was lower than any value in the
		% distribution.
		y(dx)=nan;
	else
		if closest==-1  % datum out of range
			others=1;
		else
			others=find(sd_ps==sd_ps(closest));
		end
		if ps(others(1))<50 && ps(others(end))>50
			% if the datum stradles the mean.
			sd_p=0.5;
		elseif ps(others(1))>50
			sd_p=ps(others(1))/100;
		else
			sd_p=ps(others(end))/100;
		end
		y(dx)=sd_p;
	end
end