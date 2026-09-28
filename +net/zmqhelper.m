classdef zmqhelper < handle
    % A wrapper for the jeromq java class.
    %
    % h = net.zmqhelper(['type', 'pub'], ['url', ''], ['subscriptions', {}], ...
    %                   ['service', 'zmq'], ['bind', []], ['linger', 1000], ...
    %                   ['verbose', true])
    %
    %   type           pub | sub | push | pull | req | rep, matched
    %                  case-insensitively.
    %   url            where to bind or connect. Read from the 'service'
    %                  section of ~/.dbconf when empty.
    %   subscriptions  cell of topic prefixes; sub sockets only.
    %   bind           true binds, false connects. Defaults to binding only
    %                  for pull, because every other type talks to a broker
    %                  that binds on its behalf.
    %   linger         milliseconds close() may spend on messages that have
    %                  not been delivered yet; 0 drops them at once. Must be
    %                  between 0 and intmax('int32'): zmq reads any negative
    %                  linger as "wait forever", and setLinger takes a java
    %                  int, so a larger value wraps round to a negative one
    %                  and close() would never return. The default is not
    %                  free -- closing a push socket with an undeliverable
    %                  message costs the full second, and delete() calls
    %                  close() when the helper goes out of scope, so a
    %                  helper built inside a function pays it on every
    %                  call.
    %   verbose        print a line naming the socket, action and url.
    %
    % Callers must close(). Until they do, the socket holds its port and the
    % context runs an I/O thread.
    %
    properties
        url
        socktype
        subscriptions
        service
        context
    end

    properties (SetAccess = protected)
        % Readable, but only this class (and a subclass, which is how the
        % tests install a socket that fails to close) may swap it. A
        % publicly assignable handle to a live java socket let a caller
        % leave close() holding a socket it could neither close nor prove
        % closed, and nothing legitimate needs to write it.
        socket
    end

    properties (Access = private)
        % True while obj.socket is a socket this class opened and has not
        % closed -- false both before the constructor makes one and after
        % close() closes it. isopen() is the single guard built on it; see
        % close() for why term() may not run while it is true.
        socketopen = false
    end

    methods
        
        function obj = zmqhelper(varargin)
            
            if nargin == 0
                help(mfilename)
            end
            
            % Each inpd call removes what it consumed, so whatever is left
            % is a typo: 'verbos', false would otherwise print the banner
            % and be ignored.
            inpd = @utils.inputordefault;
            args = varargin;
            [obj.socktype, args]      = inpd('type', 'pub', args);
            [obj.url, args]           = inpd('url', [], args);
            [obj.subscriptions, args] = inpd('subscriptions', [], args);
            [obj.service, args]       = inpd('service', 'zmq', args);
            [dobind, args]            = inpd('bind', [], args);
            [linger, args]            = inpd('linger', 1000, args);
            [verbose, args]           = inpd('verbose', true, args);
            if ~isempty(args)
                error('net:zmqhelper:unknownoption', 'Unknown option(s): %s', ...
                    strjoin(cellfun(@optionname, args(1:2:end), ...
                    'UniformOutput', false), ', '));
            end

            % Validate before anything is created, so a rejected option
            % cannot leave a context and its I/O thread behind.
            socktypes = {'pub', 'sub', 'push', 'pull', 'req', 'rep'};
            assert(istext(obj.socktype) && any(strcmpi(obj.socktype, socktypes)), ...
                'net:zmqhelper:badtype', '''type'' must be one of %s, got %s', ...
                strjoin(socktypes, '/'), optionname(obj.socktype));

            if isempty(dobind)
                % Only pull binds: the other types talk to a broker that
                % binds on our behalf. Pass 'bind', true to serve directly
                % instead -- a pub with no broker, or the rep end of a
                % req/rep pair.
                dobind = strcmpi(obj.socktype, 'pull');
            else
                dobind = astoggle(dobind, 'bind');
            end
            verbose = astoggle(verbose, 'verbose');

            % Milliseconds close() may spend on undelivered messages, and
            % the upper bound is as load-bearing as the lower one. zmq
            % reads any negative linger as "forever", and setLinger takes a
            % java int that MATLAB fills by truncation: read back through
            % getLinger(), 3e9 arrives as -1294967296 and 1e12 as
            % -727379968. Since the linger is spent inside term() (measured
            % on jeromq 0.6.0: 2.008 s at 2000, 0.003 s at 0, none of it in
            % socket.close()), either end of that range leaves close()
            % blocking for ever -- from delete() too.
            lingermax = double(intmax('int32'));
            assert(isnumeric(linger) && isscalar(linger) && isreal(linger), ...
                'net:zmqhelper:badlinger', ...
                '''linger'' must be a number of milliseconds, got a %s', class(linger));
            assert(mod(linger, 1) == 0 && linger >= 0 && linger <= lingermax, ...
                'net:zmqhelper:badlinger', ...
                ['''linger'' must be a whole number of milliseconds between 0 and %d, ' ...
                 'got %g: outside that range zmq lingers for ever and close() never ' ...
                 'returns.'], lingermax, linger);

            configsocktype = obj.socktype;
            
            if isempty(obj.url)
                obj.url = net.zmqhelper.loadconf(configsocktype, 'service' ,obj.service);
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
            obj.socketopen = true;   % set before bind/connect: those can
                                     % throw, and close() must still close
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
            out = send(obj.livesocket(), msg);
        end
        
        function out = sendkv(obj, key, value)
            msg = uint8(sprintf('%s %s',key, json.mdumps(value)));
            out = send(obj.livesocket(), msg);
        end
        
        function out = sendmsg(obj, msg)
            out = send(obj.livesocket(), uint8(msg));
        end
        
        function out = sendbytes(obj, msg)
            out = obj.livesocket().send(msg);
        end

        function [key,val] = recvkv_simple(obj)
            % receive a key value pair where the value is a json encoded string
            % A quiet socket is not an error: with nothing queued the key is
            % '' -- the same empty char recvmsg returns for nothing, and what
            % callers doing ischar(key) or sprintf('%s', key) expect.
            key = '';
            val = [];
            out = char(obj.livesocket().recvStr(1)); % The one gets msg without blocking
            if isempty(out)
                return
            end
            [key, tval] = strtok(out, ' ');
            val = jsondecode(tval(2:end));
        end
        
        function [key, val] = recvkv(obj)
            % As recvkv_simple, but the value goes through json.mloads, which
            % preserves class and shape. An empty queue gives key = '', val = [].
            key = '';
            val = [];
            out = char(obj.livesocket().recvStr(1)); % The one gets msg without blocking
            if isempty(out)
                return
            end
            [key, tval] = strtok(out, ' ');
            val = json.mloads(tval(2:end));
        end
        
        function out = recvmsg(obj)
            out = char(obj.livesocket().recvStr(1)); % The one gets msg without blocking
        end
        
        function out = recvbytes(obj)
            out = obj.livesocket().recv(1); % The one gets msg without blocking
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
            out = char(obj.livesocket().recvStr()); % The one gets msg with blocking
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
            out = obj.livesocket().recv(); % The one gets msg with blocking
        end

        function close(obj)
            % Close the socket, then terminate its context. Idempotent.
            % Callers must close: until they do, the socket holds its port
            % and the context runs an I/O thread.
            %
            % The order and the guards come from two things measured on
            % jeromq 0.6.0 (R2026a, macOS):
            %   * term() does not return while a socket in its context is
            %     still open. A bound PULL with nothing ever sent and
            %     linger 0 was still blocked 60 s later, and there is no
            %     timeout to reach for.
            %   * once the socket is closed, term() spends that socket's
            %     linger on whatever it could not deliver: 2.008 s at
            %     linger 2000 against 0.003 s at 0, all of it inside
            %     term() and none inside socket.close().
            % So term() runs only behind a socket this class closed itself,
            % and the constructor refuses an infinite linger.
            %
            % Teardown never throws -- close() runs from delete() and from
            % onCleanup guards, where an error would mask the one already
            % unwinding -- and never fails silently either: every failure
            % is reported by warnquietly below.
            if obj.isopen()
                try
                    obj.socket.close();
                catch me
                    % Keep the handle: the socket is still open, so
                    % isopen() must go on saying so, and term() must not
                    % run behind it.
                    warnquietly('net:zmqhelper:closefailed', ...
                        'closing the %s socket at %s failed (%s), so its context is left running: %s', ...
                        obj.socktype, obj.url, me.identifier, me.message);
                    return
                end
                obj.socketopen = false;
                obj.socket = [];
            end
            if ~isempty(obj.context)
                try
                    obj.context.term();
                catch me
                    warnquietly('net:zmqhelper:termfailed', ...
                        'terminating the context for %s failed (%s): %s', ...
                        obj.url, me.identifier, me.message);
                    return
                end
                obj.context = [];
            end
        end

        function delete(obj)
            obj.close();
        end
        
    end

    methods (Access = private)

        function tf = isopen(obj)
            % The one definition of "this helper has a socket", shared by
            % livesocket(), close() and the getPublisher/getPusher
            % singletons -- three guards that disagreed would each be right
            % about a different object. A socket close() failed to close
            % counts as open, because it is.
            tf = obj.socketopen;
        end

        function jsocket = livesocket(obj)
            % Every send and receive goes through here. getPublisher and
            % getPusher hand one object to every caller, so a helper that
            % some other holder closed is a live MATLAB handle over a dead
            % socket; unguarded, the java call fails as
            % MATLAB:UndefinedFunction ("Undefined function 'send' for
            % input arguments of type 'uint8'") on a send and as
            % MATLAB:structRefFromNonStruct on a receive, neither of which
            % names the problem.
            assert(obj.isopen(), 'net:zmqhelper:closed', ...
                'this %s socket (%s) is closed; ask for a new net.zmqhelper', ...
                obj.socktype, obj.url);
            jsocket = obj.socket;
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
                error('net:zmqhelper:unknownservice', ...
                    'Service "%s" not found in configuration file "%s"', service, fname);
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
                    error('net:zmqhelper:unknownsocktype', ...
                        ['no port is configured for a "%s" socket; ' ...
                         'pass an explicit url for anything but pub/sub/push/pull'], prop)
            end
            
        end

        
        
        function zpub = getPublisher()
            % all publishers can share one publisher.
            persistent localpub;
            if isempty(localpub) || ~isvalid(localpub) || ~localpub.isopen()
                localpub = net.zmqhelper('type','pub');
            end
            zpub = localpub;
            
        end

        
        
        function zpub = getPusher(varargin)
            % all publishers can share one publisher
            persistent localpush;
            if isempty(localpush) || ~isvalid(localpush) || ~localpush.isopen()
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

function warnquietly(id, fmt, varargin)
% Report a teardown failure without ever throwing. warning('error', id) --
% which a caller or a CI runner may well have set -- turns that warning
% into an error, and close() runs from delete() and from onCleanup guards
% where throwing would mask the error already unwinding. Falling back to
% stderr keeps the report loud without that risk.
try
    warning(id, fmt, varargin{:});
catch
    fprintf(2, ['Warning (%s): ' fmt '\n'], id, varargin{:});
end
end

function tf = istext(x)
tf = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
end

function tf = astoggle(value, name)
% Accept a scalar logical, or the 0/1 that callers pass just as often.
assert((islogical(value) || isnumeric(value)) && isscalar(value) ...
    && ismember(value, [0 1]), ['net:zmqhelper:bad' name], ...
    '''%s'' must be true or false, got a %s', name, class(value));
tf = logical(value);
end

function s = optionname(x)
% An option name for an error message. char(string(x)) throws on a struct,
% and a diagnostic that dies takes the diagnosis with it.
if ischar(x) || isstring(x)
    s = char(x);
else
    s = class(x);
end
end

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
