classdef (Sealed) labdb < handle
    
    
    properties (SetAccess=public,GetAccess=protected)
        config = [];
    end
    
    properties (SetAccess=public,GetAccess=public)
        dbconn = [];
        autocheck = true;% Normally this class checks for DB connectivity before queries. If you are running many you can skip the autocheck.
    end
    
    methods (Access=private)
        function obj = labdb
        end
    end

    methods (Access=public)

        function setConfig(obj, config)
            obj.config = config;
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
        
        function cur = execute(obj, sqlstr, args)
            if nargin<3
                args = {};
            end
            if obj.autocheck 
                checkConnection(obj);
            end
            sqlquery = sprintf(sqlstr, args{:});
            cur = exec(obj.dbconn, sqlquery);
            if cur.Message
                % There was an error
                fprintf(2,'SQL ERROR: %s \n',cur.Message);
            end
        end
        
        function use(obj, schema)
            cur = execute(obj,sprintf('use %s', schema));
            if cur.Message
                error('Failed to switch schemas')
            end
        end

        function out = explain(obj, table)
            out = query(obj,sprintf('explain %s', table));
        end

        function out = last_insert_id(obj)
            out = query(obj,'select last_insert_id() as id');
            out = out.id;
        end

        function varargout = get(obj, sqlstr, args)
        % if you are trying to get some numbers from the database 
        % and you want to get the value rather than a table, use this function.
            
            if nargin < 3
                args = {};
            end
            out = query(obj,sqlstr,args);
            varargout = cell(1,nargout);
            if isempty(out)
                return;
            end
                
            for vx = 1:nargout
                varargout{vx} = out.(out.Properties.VariableNames{vx});
            end

        end

        
        function call(obj, sqlstr)
            execute(obj,sprintf('call %s', sqlstr));
        end
        
        function out = query(obj, sqlstr, args)
            
            if obj.autocheck 
                checkConnection(obj);
            end
            
            if nargin < 3
                args = {};
            end
            
            sqlquery = sprintf(sqlstr, args{:});
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
        
        function saveData(obj, tablename, data, varargin)
         % saveData(obj, tablename, data, colnames)
            if obj.autocheck
                checkConnection(obj);
            end
            if nargin < 4
                if isstruct(data)
                    colnames = fields(data);
                    data = struct2table(data,'AsArray',true);
                elseif istable(data)
                    colnames = data.Properties.VariableNames;
                else
                    error('labdb:saveData','Must specify column names if not using table or struct type')
                end
            end
            
            datainsert(obj.dbconn, tablename, colnames, data);
            
        end
        
        function checkConnection(obj)
             

            

            try
                getId(obj.dbconn.Handle);
                cur = obj.dbconn.exec('select 1 from dual');
                assert(isempty(cur.Message));
            catch
                obj.dbconn = [];
            end

            if isempty(obj.dbconn) || ~obj.dbconn.isopen
                obj.dbconn = database(obj.config.db,obj.config.user,obj.config.passwd,'Vendor','MySQL',...
                    'Server',obj.config.host);
            end
            
            
            if ~isempty(obj.dbconn.Message)
                    fprintf(2,'%s\n',obj.dbconn.Message);
                    obj.dbconn = [];
            end
        end
        
        function close(obj)
            close(obj.dbconn);
            obj.dbconn = [];
        end
        
    end
    
    methods (Static)
        function so = getConnection(varargin)
            setdbprefs('DataReturnFormat','table')
            addMysqlConnecterToPath();
            
            persistent localObj;

            if nargin == 1
                configsec = varargin{1};
            else
                configsec = utils.inputordefault('config','client',varargin);
            end

            % Check if we have a connection with the right name.

            try
                so = localObj.(configsec);
                return;
            catch ME
                if ~strcmp(ME.identifier, {'MATLAB:nonExistentField', 'MATLAB:structRefFromNonStruct'})
                    rethrow(ME)
                end 
            end

            % No connection exists
            localObj.(configsec) = [];

            if nargin < 3
                config = readDBconf(configsec);
            else
                config.host = varargin{1};
                config.user = varargin{2};
                config.passwd = varargin{3};
                if nargin > 3
                    config.db = varargin{4};
                else
                    config.db = 'met';
                end
               
            end
            


            localObj.(configsec) = db.labdb;
            setConfig(localObj.(configsec), config);
            checkConnection(localObj.(configsec));
            so = localObj.(configsec);
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
        if numel(tline)==0 
            % Starting another section.
            continue
        end

        if tline(1) == '['
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

function addMysqlConnecterToPath()
    jcp = javaclasspath('-all');
    
    jarfile = 'mysql-connector-java-5.1.39-bin.jar';
    
    if isempty(cell2mat(regexp(jcp,jarfile)))
        % Mysql is not on the path
        this_file = mfilename('fullpath');
        [this_path] = fileparts(this_file);
        javaaddpath(fullfile(this_path, jarfile));
    end
     
end

