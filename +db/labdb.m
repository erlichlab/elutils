classdef (Sealed) labdb < handle
% Class labdb
% This is a wrapper class for the JDBC MySQL driver.
% It has several features which are generally useful
% 1. It reads credentials configurations from ~/.dbconf so that you don't have to type in credentials or store them in code.
% 2. It maintains a single connection per configuration (a configuration is a user/hostname pair) for memory efficiency.
% 3. It has several useful functions for getting and saving data to MySQL
% 4. By default, automatically checks that the connection is alive and well before trying to communicate with the database.
%    This incurs a small overhead, and can be turned off with `obj.autocheck = false`
%
% To see a list of the functions for the class type db.labdb.help
% To get help for a specific function call db.labdb.help(function_name), e.g. db.labdb.help('query')

    
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
            % Manually set the user, passwd, host. 
            % input should be a struct with those fields
            obj.config = config;
        end        
        
        function host = getHost(obj)
            % host = getHost()
            % output: the hostname from the current config
            host = obj.config.host;
        end
        
        function user = getUser(obj)
            % host = getUser()
            % output: the user from the current config

            user = obj.config.user;
        end
        
        function out = getConnectionInfo(obj)
            % out = getConnectionInfo
            % returns a struct with connection information (driver version, connection URL, etc)
            out = ping(obj.dbconn);
        end
        
        function list = list_enums(obj, tablename, column)
            out = obj.query('show columns from %s where field="%s"',{tablename, column});
            enums = out.COLUMN_TYPE{1}(6:end-1);
            done = false;
            list = {};
            while ~done
                [this_one, enums] = strtok(enums, ',');
                list = [list, {strtrim(replace(this_one,'''',''))}];
                if isempty(enums)
                    done = true;
                else
                    enums = enums(2:end);
                end

            end

        end
        
        function list = column_names(obj,tablename)
            out = obj.query('show columns from %s',{tablename});
            list = out.COLUMN_NAME;
            

        end

        function cur = execute(obj, sqlstr, args)
            % cur = execute(sql_command, [input arguments])
            % executes the sql_command and returns a cursor object.
            % Place holders can be used using sprintf style syntax.
            % e.g. execute('insert into foo (a,b) values (%.3f,"%s")',{3.1441241, 'some text goes here'})
            
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
            % use(schema)
            % sets the default schema
            cur = execute(obj,sprintf('use %s', schema));
            if cur.Message
                error('Failed to switch schemas')
            end
        end

        function out = explain(obj, table)
            % explain(something)
            % a shortcut for 'explain ...'
            out = query(obj,sprintf('explain %s', table));
        end

        function out = last_insert_id(obj)
            % out = last_insert_id
            % returns the last_insert_id
            out = query(obj,'select last_insert_id() as id');
            out = out.id;
        end

        function varargout = get(obj, sqlstr, args)
        % varargout = get(sql_command, [input arguments])
        % Like query, this command uses sprintf style parsing to execute a MySQL SELECT command.
        % However, get is special in that it returns one variable for each column in the SELECT
        % whereas query returns a single table for the entire query.
        %
        % e.g. sessid = obj.get('select sessid from sessions limit 1') % sessid will be a float
        %  [sessdate, sessid] = obj.get('select sessiondate, sessid from sessions') % sessdate will be a cell array and sessid will be a vector of float
            
            if nargin < 3
                args = {};
            end
            out = query(obj,sqlstr,args);
            varargout = cell(1,nargout);
            if isempty(out) || strcmp(out{1,1},'No Data')
                return;
            end
                
            for vx = 1:nargout
                varargout{vx} = out.(out.Properties.VariableNames{vx});
            end

        end

        
        function call(obj, sqlstr, args)
        % call('storedProcedure(2456)')
        % call('storedProcedure(%d,"%s")',{1234,'stuff'})
        % Calls the stored procedure with the passed arguments.
        
            if nargin<3
                args={};
            end
            execute(obj,sprintf('call %s', sprintf(sqlstr, args{:})));
        end
        
        function out = query(obj, sqlstr, args)
        % tableout = query(sql_command, [input arguments])
        % Like execute, this command uses sprintf style parsing. But instead of returning a cursor,
        % query returns a `table` object. 
        %
        % e.g. sessid = obj.query('select sessid from sessions limit 1') % sessid will be a table with a sessid column.
        %  [sessdate, sessid] = obj.get('select sessiondate, sessid from sessions') % sessdate will be a cell array and sessid will be a vector of float
            
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
                %if cur.rows <= 0
                %cur.rows have been removed for the lastest version of MATLAB
                if isempty(cur.Data)
                    out = {};
                elseif iscell(cur.Data) && strcmp(cur.Data{1},'No Data')
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
        
        function ok = isopen(obj)
            try
                cur = obj.dbconn.exec('select 1 from dual');
                assert(isempty(cur.Message));
                ok = true;
            catch me
                ok = false;
            end
            
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
                    'Server',obj.config.host,'PortNumber',obj.config.port);
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
    % We use a static method to give the matlab client a database object
    % for each configuration (IP, username) we only make one connection and then re-use it.
    % This is ok for MATLAB since it is single threaded. 
    % It could potentially cause strange behavior if a user was doing inserts in a timer and also in the main 
    % thread and using `last_insert_id`
        function help(fname)
            if nargin == 0 
                help('db.labdb')
                methods('db.labdb')
            else
                help(sprintf('db.labdb.%s',fname))
            end
        end

        function so = getConnection(varargin)
            setdbprefs('DataReturnFormat','table')
            
            persistent localObj; % This is where we store existing connections.

            if nargin == 1
                % The user provided a config name, so use that.
                configsec = varargin{1};
            elseif nargin ==0
                % The user provided nothing. Use the default config.
                configsec = 'client';
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
            addMysqlConnecterToPath();  % Make sure the driver is on the path.

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

def.db = ''; % In case db is not passed in set it by default to nothing.
def.port = 3306;
if nargin == 0
    
    cfgname = 'client';
end
if ispc
    cfgpath = getenv('USERPROFILE');
else
    cfgpath = getenv('HOME');
end

cfgfile = fullfile(cfgpath,'.dbconf');

if ~exist(cfgfile,'file')
    error('labdb:dbconf','.dbconf file not found in home directory');
end

allcfg = utils.ini2struct(cfgfile);
fopts = allcfg.(cfgname);
cfg = utils.apply_struct(def, fopts);

end

function addMysqlConnecterToPath()
    jcp = javaclasspath('-all');
    
    jarfile = 'mysql-connector-java-5.1.42-bin.jar';
    
    if isempty(cell2mat(regexp(jcp,jarfile)))
        % Mysql is not on the path
        this_file = mfilename('fullpath');
        [this_path] = fileparts(this_file);
        javaaddpath(fullfile(this_path, jarfile));
    end
     
end

