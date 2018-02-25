function ci = binoci(x,lowhigh, cirange)
% ci = binoci(x)
% x is a boolean vector
% lowhigh is 'low','high' or 'both' ['both'] 
% ci is the binomial confidence 
%

if nargin<2
    lowhigh = 'both';
end

if nargin<3
    cirange = 0.05;
end


[~,ci] = binofit(sum(x),numel(x),cirange);

switch lowhigh
    case 'low'
        ci = ci(1);
    case 'high'
        ci = ci(2);
end

        
