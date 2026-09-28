classdef zmqhelper < handle
    % The ZMQHandler class is a wrapper for the jeromq java class.
    %
    %
    properties
        url
        socktype
        socket
        subscriptions
        service
        context
    end
    
    methods
        
        function obj = zmqhelper(varargin)
            
            if nargin == 0
                help(mfilename)
            end
            
            inpd = @utils.inputordefault;
            obj.socktype = inpd('type', 'pub', varargin);
            obj.url = inpd('url', [], varargin);
            obj.subscriptions = inpd('subscriptions', [], varargin);
            obj.service = inpd('service', 'zmq', varargin);
            dobind  = inpd('bind', [], varargin);
            linger  = inpd('linger', 1000, varargin);
            verbose = inpd('verbose', true, varargin);

            configsocktype = obj.socktype;
            
            if isempty(obj.url)
                obj.url = net.zmqhelper.loadconf(configsocktype, 'service' ,obj.service);
            end

            if isempty(dobind)
                % Only pull has ever bound: the other types talk to a broker
                % that binds on our behalf. Pass 'bind', true to serve
                % directly instead -- a pub with no broker, or the rep end of
                % a req/rep pair.
                dobind = strcmpi(obj.socktype, 'pull');
            end
            if dobind
                action = 'binding';
            else
                action = 'connecting';
            end

            if verbose
                fprintf('Creating a %s socket %s to %s\n', obj.socktype, action, obj.url);
            end

            import org.zeromq.ZMQ;
            obj.context = ZMQ.context(1);
            obj.socket = obj.context.socket(ZMQ.(upper(obj.socktype)));
            %obj.socket.HEARTBEAT_INTERVAL = 60000; % seems not available in jeromq

            % zmq lingers forever by default, so a close() with an
            % undelivered message would hang MATLAB rather than return.
            obj.socket.setLinger(linger);

            if dobind
                obj.socket.bind(obj.url);
            else
                obj.socket.connect(obj.url);
            end
            if ~isempty(obj.subscriptions)
                for sx = 1:numel(obj.subscriptions)
                    obj.socket.subscribe(uint8(obj.subscriptions{sx}));
                end
            end
            
            
        end

        function out = sendkv_simple(obj, key, value)
            % just encode the value as json and send it with the key
            value_json = jsonencode(value);
            msg = uint8(sprintf('%s %s', key, value_json));
            out = send(obj.socket, msg);
        end
        
        function out = sendkv(obj, key, value)
            msg = uint8(sprintf('%s %s',key, json.mdumps(value)));
            out = send(obj.socket, msg);
        end
        
        function out = sendmsg(obj, msg)
            out = send(obj.socket, uint8(msg));
        end
        
        function out = sendbytes(obj, msg)
            out = obj.socket.send(msg);
        end

        function [key,val] = recvkv_simple(obj)
            % receive a key value pair where the value is a json encoded string
            % Empty means nothing was queued, as with recvmsg/recvjson -- a
            % quiet socket is not an error.
            key = [];
            val = [];
            out = char(obj.socket.recvStr(1)); % The one gets msg without blocking
            if isempty(out)
                return
            end
            [key, tval] = strtok(out, ' ');
            val = jsondecode(tval(2:end));
        end
        
        function [key, val] = recvkv(obj)
            key = [];
            val = [];
            out = char(obj.socket.recvStr(1)); % The one gets msg without blocking
            if isempty(out)
                return
            end
            [key, tval] = strtok(out, ' ');
            val = json.mloads(tval(2:end));
        end
        
        function out = recvmsg(obj)
            out = char(obj.socket.recvStr(1)); % The one gets msg without blocking
        end
        
        function out = recvbytes(obj)
            out = obj.socket.recv(1); % The one gets msg without blocking
        end
        
        function [addr, out] = recvjson(obj)
            msg = recvmsg(obj); % get msg with nonblocking and convert from java string to char
            if isempty(msg)
                addr = [];
                out = [];
            else
                [addr, out] = parsejson(msg);
            end
        end

        function out = waitformsg(obj)
            out = char(obj.socket.recvStr()); % The one gets msg with blocking
        end

        

        function [addr, out] = waitforjson(obj)
            
                msg = waitformsg(obj); % get msg with blocking
                if isempty(msg)
                    addr = [];
                    out = [];
                else
                    [addr, out] = parsejson(msg);
                end
            
        end
        
        function out = waitfordata(obj)
            out = obj.socket.recv(); % The one gets msg with blocking
        end

        function close(obj)
            % Close the socket and terminate its context. Idempotent.
            % Nothing used to call this, so every zmqhelper left behind a
            % socket holding its port and a context running an I/O thread.
            if ~isempty(obj.socket)
                try %#ok<TRYNC>
                    obj.socket.close();
                end
                obj.socket = [];
            end
            if ~isempty(obj.context)
                try %#ok<TRYNC>
                    obj.context.term();
                end
                obj.context = [];
            end
        end

        function delete(obj)
            obj.close();
        end
        
    end
    
    methods (Static)
        
        function zmqconf = loadconf(prop, varargin)
            inpd = @utils.inputordefault;
            fname = inpd('fname', '~/.dbconf', varargin);
            service = inpd('service', 'zmq', varargin);

            ini = utils.ini2struct(fname);

            if isfield(ini, service)
                zmqconf = ini.(service);
            else
                error('Service "%s" not found in configuration file "%s"', service, fname);
            end
            
            switch prop
                case 'pub'
                    zmqconf = sprintf('%s:%d', zmqconf.url, zmqconf.pubport);
                case  'sub'
                    zmqconf = sprintf('%s:%d', zmqconf.url, zmqconf.subport);
                case  'push'
                    zmqconf = sprintf('%s:%d', zmqconf.url, zmqconf.pushport);
                case 'pull'
                    zmqconf = sprintf('tcp://*:%d', zmqconf.pullport);               
                otherwise
                    error('If not using pub or sub you must specify the URL to use.')
            end
            
        end

        
        
        function zpub = getPublisher()
            % all publishers can share one publisher.
            persistent localpub;
            if isempty(localpub) || ~isvalid(localpub) || isempty(localpub.socket)
                localpub = net.zmqhelper('type','pub');
            end
            zpub = localpub;
            
        end

        
        
        function zpub = getPusher(varargin)
            % all publishers can share one publisher
            persistent localpush;
            if isempty(localpush) || ~isvalid(localpush) || isempty(localpush.socket)
                localpush = net.zmqhelper('type','push');
            end
            zpub = localpush;
            
        end 

        function zsub = getSubscriber(subscriptions)
            if ischar(subscriptions)
                subscriptions = {subscriptions};
            end
            zsub = net.zmqhelper('type','sub', 'subscriptions',subscriptions);
            
        end
        
        
    end % methods
    
    
end % classdef

function [addr, out] = parsejson(msg)
    try
        json_start = find(msg=='{',1,"first");
        json_end = find(msg=='}',1,"last");
        jstr = msg(json_start:json_end);
        addr = strtrim(msg(1:json_start-1));
        %out = json.fromjson(jstr);   % decode the json string and return the address and the json object
        out = jsondecode(jstr);
    catch me
        utils.showerror(me)
        display(msg)
        addr = [];
        out = [];  
    end
end
