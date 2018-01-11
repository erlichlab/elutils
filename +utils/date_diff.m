function out = date_diff(date1, date2, interval)
% out = date_diff(date1, date2, interval)
% Inputs
% date1     a date in yyyy-mm-dd or yyyy-mm-dd hh:mm:ss format
% date2     a date in yyyy-mm-dd or yyyy-mm-dd hh:mm:ss format
% interval  one of 'year','day','hour','minute','second'
%
% Note: date1 and date2 can either be date character arrays or cell
% arrays (must be same size or only one should be a cell array) 

% if they are both arrays the diff is taken element-wise. if only one is an
% array then the scalar date is compared to all elements of the array.
%
% Output
% The time passed from date2 to date1 in units of interval

if iscell(date1) && iscell(date2) % two cell arrays
    assert(isequal(size(date1),size(date2)),'date1 and date2 must have same size');
    out = cellfun(@(x,y)date_diff_int(x,y,interval),date1,date2);
elseif iscell(date1) % date1 is a cell
    assert(ischar(date2),'If date2 is not a cell array it must be a char');
    out = cellfun(@(x)date_diff_int(x,date2,interval),date1);
elseif iscell(date2) % date2 is a cell
    assert(ischar(date1),'If date1 is not a cell array it must be a char');
    out = cellfun(@(x)date_diff_int(date1,x,interval),date2);
else
    out = date_diff_int(date1,date2,interval);    
end

end

function out = date_diff_int(date1,date2,interval)
out_in_days = datenum(date1) - datenum(date2);
switch lower(interval(1:2)) % I only take the first 2 char to allow for plural.
    case 'ye' %years
        out = out_in_days / 365;
    case 'da' %days
        out = out_in_days;
    case 'ho' %hours
        out = out_in_days*24;
    case 'mi' %minutes
        out = out_in_days*24*60;
    case 'se' %seconds
        out = out_in_days*24*60*60;
    otherwise
        error('utils:date_diff','Do not know about interval %s',interval);
end

end



