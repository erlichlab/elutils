function r = untiedrank(x)
% function r = untiedrank(x)
%
% Similar to tiedrank, but arbitrarily breaks ties (with consistency each
% time called)

% reset random number generator to same start
% RandStream.setDefaultStream(RandStream('mrg32k3a','Seed',10));
RandStream.setGlobalStream(RandStream('mrg32k3a','Seed',10));



if isvector(x)
   r = tr(x);
else
   if isa(x,'single')
      outclass = 'single';
   else
      outclass = 'double';
   end

   % Operate on each column vector of the input (possibly > 2 dimensional)
   sz = size(x);
   ncols = sz(2:end);  % for 2x3x4, ncols will be [3 4]
   r = zeros(sz,outclass);
   for j=1:prod(ncols)
      r(:,j)= tr(x(:,j));
   end
end

% --------------------------------
function r = tr(x)
%TR Local untiedrank function to compute results for one column

% Sort, then leave the NaNs (which are sorted to the end) alone
[sx, rowidx] = sort(x(:));
numNaNs = sum(isnan(x));
xLen = numel(x) - numNaNs;

% Use ranks counting from low end
ranks = [1:xLen NaN(1,numNaNs)]';

if isa(x,'single')
   ranks = single(ranks);
end

% "randomly" break ties.  Avoid using diff(sx) here in case there are infs.
ties = (sx(1:xLen-1) == sx(2:xLen));
tieloc = [find(ties); xLen+2];
maxTies = numel(tieloc);

tiecount = 1;
while (tiecount < maxTies)
    tiestart = tieloc(tiecount);
    ntied = 2;
    while(tieloc(tiecount+1) == tieloc(tiecount)+1)
        tiecount = tiecount+1;
        ntied = ntied+1;
    end
    
    % Compute mean of tied ranks
%     ranks(tiestart:tiestart+ntied-1) = sum(ranks(tiestart:tiestart+ntied-1)) / ntied;

    % "randomly" reassign ties
    temp = ranks(tiestart:tiestart+ntied-1);
    ranks(tiestart:tiestart+ntied-1) = temp(randperm(ntied));
              
    tiecount = tiecount + 1;
end

% Broadcast the ranks back out, including NaN where required.
r(rowidx) = ranks;
r = reshape(r,size(x));
