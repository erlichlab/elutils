function [S, extra_args]=getSessData(varargin)
% [S, extra_args]=get_sessdata(varargin)
% [S, extra_args]=get_sessdata(sessid)
% [S, extra_args]=get_sessdata(subjname, date)
% [S, extra_args]=get_sessdata(subjname, daterange)
%
% A frontend to get data from the sessions table that does some nice input
% parsing.   Useful to use in other functions to avoid having to parse
% inputs.  If you pass it all the args from a parent function the leftover
% args are returned as extra_args.  For a good example of this see
% psychoplot_delori.m (in ExperPort/Analysis/SameDifferent)
%
% S by default contains fields: sessid, sessiondate,protocol_data and peh
%
% sessid can be a single sessid or a vector of sessids
% date should be of the form "YYYY-MM-DD" or a relative date like -5
% daterange should be a numeric vector in relative form like -10:-1 or a
% cell array of date string of the from "YYYY-MM-DD"
%
% pairs={'do_tracking' false;...
% 	   'fetch_peh' true...
% 	   };
%
%


if nargin==0 || isempty(varargin{1})
    S.sessid=[];
    S.data={};
    S.peh={};
    S.subjname={};
    S.sessiondate={};
    S.protocol={};
    return;
end

dbc = db.labdb.getConnection;

if iscell(varargin{1})
    varargin=varargin{1};
    nargs=numel(varargin);
else
    nargs=nargin;
end

%% parse inputs
use_sessid=0;
if isnumeric(varargin{1})
    % Case 1, we've got a vector of sessids
    sessid=varargin{1};
    sessid=sessid(~isnan(sessid));
    use_sessid=1;
    %[subjname, experimenter]=bdata('select subjname, experimenter from sessions where sessid="{S}"',sessid(1));
    varargin=varargin(2:end);
elseif nargs>=2
    % Case 2, we've got a subjname and experimenter
    subjname=varargin{1};
    datein=varargin{2};
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
    varargin=varargin(3:end);
else
    S=[];
    warning('Failed to parse inputs.');
    extra_args=varargin;
    return
end

extra_args=varargin;

do_tracking=false;
fetch_peh=true;
utils.overridedefaults({'fetch_peh'}, extra_args);

%% get data from sql

if ~use_sessid
    % If we are not in Case 1 (see above)
    % then transform the cell array of strings into a long comma separated
    % string.
    datestr='';
    for dx=1:numel(dates)
        datestr=[datestr ',"'  dates{dx}  '"'];
    end
    % Use the datestr for a select ... where sessiondate in (datestr) type sql command to get all the relevant sessions.
    sqlquery = sprintf('select sessid from beh.sessions b, met.subjects m where m.subjid=b.subjid and subjname=%d and sessiondate in ( %s ) order by sessiondate',subjname, datestr(2:end));
    sqlout = dbc.query(sqlquery);
    sessid = slqout.sessid;
    
end



% We have a list of sessids.  Transform that into a comma separated string
sessstr='';
for sx=1:numel(sessid)
    sessstr=[sessstr, ',' num2str(sessid(sx))];
end
sessstr = sessstr(2:end);
if fetch_peh
    
    sqlquery = 	['select sessid, trialnum, data, parsed_events from beh.trials where sessid in (' sessstr ') order by sessid, trialnum'];
    
    trialsout = dbc.query(sqlquery);
    
else
    sqlquery = 	['select sessid, trialnum, data from beh.trials where sessid in (' sessstr ') order by sessid, trialnum'];
    
    trialsout = dbc.query(sqlquery);
    
end

sqlquery = sprintf('select sessid, sessiondate, starttime, hostip, protocol from beh.sessions where sessid in ( %s ) order by sessid', sessstr);
sessout = dbc.query(sqlquery);

S = combineData(sessout, trialsout, fetch_peh);


if false && do_tracking % This is not implemented yet.
    S.a=cell(numel(S.sessid),1);
    
    [T.sessid, T.ts, T.theta]=bdata(['select sessid, ts, theta from tracking where sessid in (' sessstr ')']);
    
    for sx=1:numel(S.sessid)
        
        tx=find(T.sessid==S.sessid(sx));
        if ~isempty(tx)
            a.ts=T.ts{tx};
            a.theta=T.theta{tx};
            
            S.a{sx}=a(:);
        end
    end
    
    
    
end
end

function S = combineData(sessout, trialsout, fetch_peh)


if which('utils.fromjson')
	ljson = @utils.fromjson;
else
    ljson = @loadjson;
end
% This let's people with the faster json code use it while the slow pokes are stuck with the other one.

	
tic
S = table2struct(sessout);
for sx = 1:numel(S)
    these_trial_ind = trialsout.sessid == S(sx).sessid;
    num_trials = sum(these_trial_ind);
    
    %% First handle the trial data.
    these_json_data = trialsout.data(these_trial_ind);
    last_data = ljson(these_json_data{num_trials});
    clear sessdata
    sessdata(num_trials) = last_data.data;
    sessdata = sessdata(:); 
    % The above two lines help allocate memory for the struct at once to
    % save time. And then make sure it is a column vector (e.g. tall).
    
    for tx = 1:(num_trials-1)
        this_data = ljson(these_json_data{tx});
        sessdata(tx) = this_data.data;      
    end

    S(sx).data = sessdata;

    %% Then handle the parsed events if we got it.

    if fetch_peh
	    these_json_pe = trialsout.parsed_events(these_trial_ind);
    	last_data = loadjson(these_json_pe{num_trials});
	    clear sessdata;
	    sessdata(num_trials) = last_data.parsed_events;
	    sessdata = sessdata(:); 
	    % The above two lines help allocate memory for the struct at once to
	    % save time. And then make sure it is a column vector (e.g. tall).
	    
	    for tx = 1:(num_trials-1)
	        this_data = loadjson(these_json_pe{tx});
	        sessdata(tx) = this_data.parsed_events;      
	    end

	    S(sx).peh = sessdata;

    end



end
toc
end





