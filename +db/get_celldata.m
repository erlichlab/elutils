function [S, extra_args]=get_celldata(varargin)
% [S, extra_args]=get_celldata(cellid)
% [S, extra_args]=get_celldata(ratname,experimenter, date)
% [S, extra_args]=get_celldata(ratname,experimenter, daterange)
%
% A frontend to get timestamps and waveforms from the spktimes table that does some nice input
% parsing.   Useful to use in other functions to avoid having to parse
% inputs.
%
% S by default contains fields: cellid, sessiondate, and protocol_data
%
% needs more documentation!  
%
% cellid can be a single cellid or a vector of cellids
% date should be of the form "YYYY-MM-DD" or a relative date like -5
% daterange should be a numeric vector in relative form like -10:-1 or a
% cell array of date string of the from "YYYY-MM-DD"
%
if iscell(varargin{1})
	varargin=varargin{1};
	nargs=numel(varargin);
else
	nargs=nargin;
end

%% parse inputs
use_cellid=0;
if nargs==1 && isnumeric(varargin{1})
	% Case 1, we've got a vector of cellids
	cellid=varargin{1};
	use_cellid=1;
	varargin=varargin(2:end);
elseif nargs>=3
	% Case 2, we've got a ratname and experimenter
	ratname=varargin{1};
	experimenter=varargin{2};
	datein=varargin{3};
	if isnumeric(datein)
		%Case 2a, we've got relative dates (e.g. -10:0)
		for dx=1:numel(datein)
			dates{dx}=to_string_date(datein(dx));
		end
	elseif ischar(datein)
		%Case 2b, we've got a single date (e.g. '2009-05-01')
		dates{1}=datein;
	else
		%Case 2c, we've got a cell array of dates
		dates=datein;
	end
	% In future we might allow in extra parameters
	varargin=varargin(4:end);
else
	S=[];
	warning('Failed to parse inputs.');
	extra_args=varargin;
	return
end

extra_args=varargin;
  
%% get data from sql

if ~use_cellid
	% If we are not in Case 1 (see above)
	% then transform the cell array of strings into a long comma separated
	% string.
	datestr='';
	for dx=1:numel(dates)
		datestr=[datestr ',"'  dates{dx}  '"'];
	end
	% Use the datestr for a select ... where sessiondate in (datestr) type sql command to get all the relevant sessions. 
	
	sqlstr=['select c.cellid, recorded_on_right, region,ts, wave, c.sessid, single from cells k, spktimes as c, ratinfo.eibs e, sessions as s '...
		    ' where s.sessid=c.sessid and k.cellid=c.cellid and c.eibid=e.eibid and s.ratname="{S}" and experimenter="{S}" and '...
		   ' sessiondate in (' datestr(2:end) ') order by sessiondate'];
	
	[S.cellid, S.rr ,S.region, S.ts, S.wave, S.sessid, S.single]=bdata(sqlstr,ratname, experimenter);
else
	% We have a list of cellids.  Transform that into a comman seperated string
	cellstr='';
	for cx=1:numel(cellid)
		cellstr=[cellstr, ',' num2str(cellid(cx))];
	end
	[S.cellid, S.rr, S.region, S.ts, S.wave, S.sessid, S.single]=bdata(['select s.cellid, recorded_on_right, region, ts, wave, s.sessid, single from spktimes s, cells c, ratinfo.eibs e where s.cellid=c.cellid and  c.eibid=e.eibid and s.cellid in (' cellstr(2:end) ') order by sessid']);

end

%% get some metadata




