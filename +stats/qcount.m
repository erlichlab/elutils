function y=qcount(x, start, finish)
% y=between(x, start, finish)
% works for sorted 1D vectors.
% using find you get o(n) , by assuming that the vector is sorted you get
% 2*o(log(n)).   which is WAY better.

if numel(start)~=numel(finish)
    y=[]; return;
end

y=zeros(size(start));

if numel(start)>1
    for sx=1:numel(start)
        y(sx)=numel(qbetween(x,start(sx), finish(sx)));
    end
else
    y=numel(qbetween(x,start,finish));
end
