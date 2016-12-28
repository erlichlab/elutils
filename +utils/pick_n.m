function y = pick_n(list, n, varargin)
% y = pick_n(list, n, ['with_replacement', false])
% if the list is a matrix return random rows of the matrix.
%
% Optional inputs
% with_replacement   [false]

with_rep = utils.inputordefault('with_replacement',false,varargin);

if isvector(list)
    if isrow(list)
        list = list(:);
        rowflag = true;
    else
        rowflag = false;
    end
end

num = size(list,1);
if with_rep
    ind = randi(num, [n,1]);
else
    if n > num
        error('utils:pick_n','You cannot select %d elements from a list of size %d without replacement',n,num)
    else
        perm = randperm(num);
        ind = perm(1:n);
    end
end

y = list(ind,:);
if rowflag
    y = y';
end