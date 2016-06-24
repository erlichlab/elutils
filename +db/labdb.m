classdef labdb < handle
    
    
    properties (SetAccess=public,GetAccess=public)
        dbconn = [];
        config = [];
    end
    
    methods
        function obj = labdb(host, user, passwd, db)
            if nargin == 0
                obj.config = readDBconf();
            elseif naragin == 1
                obj.config = readDBconf(host);
            else
                obj.config.host = host;
                obj.config.user = user;
                obj.config.passwd = passwd;
                if nargin > 3
                    obj.config.db = db;
                else
                    obj.config.db = 'met';
                end
                
                
            end
            
            checkConnection(obj);
            
        end
        
        function host = getHost(obj)
            host = obj.config.host;
        end
        
        function user = getUser(obj)
            user = obj.config.user;
        end

        function out = getConnectionInfo(obj)
        	out = ping(obj.dbconn);
        end
        
        function execute(obj, sqlstr, args)
            checkConnection(obj);
	    	sqlquery = sqlstr;
            cur = exec(obj.dbconn, sqlquery);
            if cur.Message
                % There was an error
                fprintf(2,'SQL ERROR: %s \n',cur.Message);
            end
        end

        function use(obj, schema)
			execute(obj,sprintf('use %s', sqlstr));
        end

        function call(obj, sqlstr)
        	execute(obj,sprintf('call %s', sqlstr));
        end

        function out = query(obj, sqlstr, args) 
        	checkConnection(obj);
	    	sqlquery = sqlstr;
            cur = exec(obj.dbconn, sqlquery);
            if cur.Message
                % There was an error
                fprintf(2,'SQL ERROR: %s \n',cur.Message);
                out = [];
            else
                data = fetch(cur);
                if cur.rows <= 0
                    out = {};
                else
                    out = data.Data;
                end
            end
            close(cur);
           
        end
        
        function out = saveData(obj, tablename, data, colnames)
        	checkConnection(obj);
        	if ~exist(colnames,'var')
        		if isstruct(data)
        			colnames = fields(data);
        		elseif istable(data)
        			colnames = data.Properties.VariableNames;
        		else
        			error('labdb:saveData','Must specify column names if not using table or struct type')
        		end
        	end

        	datainsert(obj.dbconn, tablename, colnames, data);
        	
		end

        function checkConnection(obj)
            if isempty(obj.dbconn)
                obj.dbconn = database(obj.config.db,obj.config.user,obj.config.passwd,'Vendor','MySQL',...
                'Server',obj.config.host);
            elseif ~obj.dbconn.isopen
                obj.dbconn = database(obj.config.db,obj.config.user,obj.config.passwd,'Vendor','MySQL',...
                'Server',obj.config.host);
            end
        end
        
        function close(obj)
            close(obj.dbconn);
        end
        
               
    end
end


function cfg = readDBconf(cfgname)
% A private function to help the labdb class read credentials from the
% .dbconf file in the user's home directory.

cfg.db = ''; % In case db is not passed in set it by default to nothing.
if nargin == 0
    
    cfgname = 'client';
end
import java.lang.*;
cusr=System.getProperty('user.home');
cfgfile = fullfile(char(cusr), '.dbconf');

if ~exist(cfgfile,'file')
    error('labdb:dbconf','.dbconf file not found in home directory');
end

fid = fopen(cfgfile);
start = false;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    
    
    if start
        if numel(tline)==0 || tline(1) == '['
            % Starting another section.
            break
        end
        [field, value] = strtok(tline,'=');
        
        cfg.(strtrim(field)) = strtrim(value(2:end));
    end
    
    if strcmpi(tline, ['[' cfgname ']'])
        start = true;
    end
end
fclose(fid);
end


