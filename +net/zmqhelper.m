classdef zmqhelper < handle
    % The ZMQHandler class is a wrapper for the jeromq java class.
    %
    %
    properties
        url
        socktype
        socket
        subscriptions
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
            
            if isempty(obj.url)
                obj.url = net.zmqhelper.loadconf(obj.socktype);
            end
            import org.zeromq.ZMQ;
            context = ZMQ.context(1);
            obj.socket = context.socket(ZMQ.(upper(obj.socktype)));
            %obj.socket.HEARTBEAT_INTERVAL = 60000; % seems not available in jeromq
            obj.socket.connect(obj.url);
            % This assumes you want to use connect. if you want to bind... you are an advanced user. Do it yourself.
            if ~isempty(obj.subscriptions)
                for sx = 1:numel(obj.subscriptions)
                    obj.socket.subscribe(uint8(obj.subscriptions{sx}));
                end
            end
            
            
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
        
        function [key, val] = recvkv(obj)
            out = char(obj.socket.recvStr(1)); % The one gets msg without blocking
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
        
    end
    
    methods (Static)
        
        function zmqconf = loadconf(prop, fname)
            if nargin == 1
                fname = '~/.dbconf';
            end
            ini = utils.ini2struct(fname);
            
            switch prop
                case 'pub'
                    zmqconf = sprintf('%s:%d', ini.zmq.url, ini.zmq.pubport);
                case  'sub'
                    zmqconf = sprintf('%s:%d', ini.zmq.url, ini.zmq.subport);
                otherwise
                    error('If not using pub or sub you must specify the URL to use.')
            end
            
        end
        
        function zpub = getPublisher()
            % all publishers can share one publisher.
            persistent localpub;
            if isempty(localpub)
                localpub = net.zmqhelper('type','pub');
            end
            zpub = localpub;
            
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
