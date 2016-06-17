function [y i] = qbetween2(x, start, finish)
% [y i] = qbetween2(x, start, finish)
% returns values (y) and indices (i)
% works for sorted 1D vectors.
% using find you get o(n) , by assuming that the vector is sorted you get
% 2*o(log(n)).   which is WAY better.


if isempty(x) || (x(end)<start) || x(1)>finish || finish <=start
	y = [];
	i = [];
	return
end

i=qfind(x, [start finish]);

%qfind returns -1 if the target is less than min(x), since we are
%getting 'between', we just take the first relevant x

if i(1)==i(2)
	y=[];
	return
elseif i(1)==-1
	i(1)=1;
end


%this code deals with the fact that if there is no exact match, qfind
%will return the index that is one lower than the target.  since we
%want between, we just double check the end points.  every other point
%will be valid.

y=x(i(1):i(2));
if y(1)<start
	y = y(2:end);
	i(1) = i(1) + 1;
end

if y(end)>finish
	y = y(1:end-1);
	i(2) = i(2) - 1;
end
