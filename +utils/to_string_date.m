% [str] = to_string_date(din, ['format', {'dashes'|'nodashes'})   
% 
% Takes a din that stands for a date and turns it into a string format that
% can be used to look for data files or that can be used with the SQL
% database.
%
% PARAMETERS:
% -----------
%
% din     An integer. If it is an integer of magnitude less than 1000, it
%         is interpreted as the difference, in days, between today and the
%         desired date. For example, -3 means "three days before today" and
%         5 means "five days after today".
%            If din is an integer with magnitude greater than 1000, then it
%         is interpreted as a number whose last two digits are the day of 
%         the month, last two digits but two are the number of the month,
%         and the last four digits but four are the year-2000. E.g., 80411
%         means the 11th of April of 2008.
%
%         If din is passed in as a vector, a cell of the same size is
%         returned, with each element of the cell being the result of
%         to_string_date applied to each element of din. (Note that f din
%         is a vector of length one, the return will not be a cell but a
%         string.)
%
%         If din is a string, then it is returned as is, with no changes.
%
% str     A string representing the date. If the optional parameter
%         'format' is not passed, i.e., it is left at its default value,
%         then the format will be 'yyyy-mm-dd'.  If format is 'nodashes',
%         then the returned string will be in the format 'yyyymmdd'.
%

% written by Carlos Brody April 2009


function [str] = to_string_date(din, varargin)

format = [];
pairs = { ...
  'format'   'dashes'  ; ...
}; parseargs(varargin, pairs);

if ischar(din), str = din; return; end;

if numel(din)>1,
  str = cell(size(din));
  for i=1:numel(din),
    str{i} = to_string_date(din(i), 'format', format);
  end;
  
  return;
end;

if abs(din)>1000,
  day = rem(din, 100);   din = round((din-day)/100);
  month = rem(din,100);  din = round((din-day)/100);
  if abs(din<1000),
    year  = din + 2000;
  else
    year  = din;
  end;
  
  day = num2str(day);
  day = ['0'*ones(1, 2-length(day)) day];
  
  month = num2str(month);
  month = ['0'*ones(1, 2-length(month)) month];

  year = num2str(year);
  
  if strcmp(format, 'nodashes'),
    str = [year month day];
  else
    str = [year '-' month '-' day];
  end;
else
  str = datestr(now+din, 29);
  if strcmp(format, 'nodashes'),
    str = str(str~='-');
  end;
end;
