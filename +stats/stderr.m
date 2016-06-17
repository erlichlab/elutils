
function y=stderr(x,dim)

if ~exist('dim','var')
    dim=1;
end

y=std(x,0,dim)/sqrt(size(x,dim)-1);