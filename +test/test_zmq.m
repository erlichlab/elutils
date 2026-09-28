function varargout = test_zmq(varargin)
% results = test.test_zmq(['verbose', tf], ['only', 'name'])
%
% Exercises net.zmqhelper over real loopback sockets, covering the three
% patterns the class is used for: pub/sub, req/rep and push/pull.
%
% Every case binds one end to an OS-assigned free port and connects the
% other, so the suite is self-contained -- no broker, no ~/.dbconf, no
% network beyond 127.0.0.1. Blocking receives get a socket timeout so a
% broken build fails instead of hanging a CI runner forever.
%
% The point of the suite is to pin down the jeromq surface the class
% depends on (context/socket/bind/connect/subscribe/send/recv/recvStr)
% so the jar can be upgraded with evidence rather than hope.
%
% Errors at the end if anything failed, so `matlab -batch "test.test_zmq"`
% is usable as a CI gate.

inpd = @utils.inputordefault;
args = varargin;
[verbose, args] = inpd('verbose', false, args);
[only, args]    = inpd('only', '', args);
if ~isempty(args)
    error('test:zmq:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@(x) char(string(x)), args(1:2:end), 'UniformOutput', false), ', '));
end

net.addZMQConnecterToPath();

cases = {
    'pubsub_msg',        @t_pubsub_msg
    'pubsub_filter',     @t_pubsub_filter
    'pubsub_kv',         @t_pubsub_kv
    'pubsub_kv_simple',  @t_pubsub_kv_simple
    'pubsub_json',       @t_pubsub_json
    'pushpull_msg',      @t_pushpull_msg
    'pushpull_kv',       @t_pushpull_kv
    'pushpull_bytes',    @t_pushpull_bytes
    'reqrep_msg',        @t_reqrep_msg
    'reqrep_json',       @t_reqrep_json
    'reqrep_bytes',      @t_reqrep_bytes
    'close_idempotent',  @t_close_idempotent
    'loadconf_urls',     @t_loadconf_urls
    'loadconf_errors',   @t_loadconf_errors
    };

if ~isempty(only)
    cases = cases(contains(cases(:, 1), only), :);
end
n = size(cases, 1);

R = repmat(struct('name', '', 'ok', false, 'why', '', 'secs', 0), 1, n);
nfail = 0;

fprintf('\n=== zmq: %d cases ===\n', n);
for k = 1:n
    name = cases{k, 1};
    fn   = cases{k, 2};
    why  = '';
    t0   = tic;
    try
        fn();
        ok = true;
    catch me
        ok  = false;
        why = sprintf('%s: %s', me.identifier, me.message);
    end
    secs = toc(t0);
    if ~ok
        nfail = nfail + 1;
        fprintf(2, '  FAIL %-18s %s\n', name, why);
    elseif verbose
        fprintf('  ok   %-18s (%.2fs)\n', name, secs);
    end
    R(k) = struct('name', name, 'ok', ok, 'why', why, 'secs', secs);
end
fprintf('zmq: %d/%d passed\n', n - nfail, n);

if nargout > 0
    varargout{1} = R;
end
if nfail > 0
    error('test:zmq:failed', '%d of %d zmq cases failed', nfail, n);
end
end

%% ---- pub/sub --------------------------------------------------------
% PUB drops anything published before the subscriber's subscription has
% reached it, and the subscription travels asynchronously, so a single
% send is a coin flip. Every pub/sub case therefore republishes until the
% message lands or the deadline passes (the "slow joiner" problem).

function t_pubsub_msg()
[pub, sub, g] = pubsub_pair('topic'); %#ok<ASGLU>
[ok, got] = pump(@() pub.sendmsg('topic hello'), @() r_msg(sub));
assert(ok, 'test:zmq:timeout', 'no message arrived within the deadline');
assert(strcmp(got, 'topic hello'), 'test:zmq:mismatch', 'got "%s"', got);
end

function t_pubsub_filter()
% A negative result on pub/sub is meaningless unless the link is known to
% be live, so first prove a subscribed topic gets through, then check that
% an unsubscribed one published on the same live socket does not.
[pub, sub, g] = pubsub_pair('alpha'); %#ok<ASGLU>
ok = pump(@() pub.sendmsg('alpha ping'), @() r_msg(sub));
assert(ok, 'test:zmq:timeout', 'subscribed topic never arrived');

for k = 1:20
    pub.sendmsg('beta nope');
    pub.sendmsg('alpha yes');
end
pause(0.3);

nalpha = 0;
while true
    got = sub.recvmsg();
    if isempty(got)
        break
    end
    assert(strncmp(got, 'alpha', 5), 'test:zmq:leak', ...
        'unsubscribed topic leaked through: "%s"', got);
    nalpha = nalpha + 1;
end
assert(nalpha > 0, 'test:zmq:timeout', 'no subscribed messages in the burst');
end

function t_pubsub_kv()
% sendkv/recvkv go through json.mdumps/mloads, which preserves class and
% shape -- that is the whole reason the repo has its own json codec.
[pub, sub, g] = pubsub_pair('kv'); %#ok<ASGLU>
val = struct('name', 'rat042', 'n', int32(7), 'hits', [1 0 1 1], 'ok', true);
[ok, got] = pump(@() pub.sendkv('kv', val), @() r_kv(sub));
assert(ok, 'test:zmq:timeout', 'no key/value arrived');
assert(strcmp(got{1}, 'kv'), 'test:zmq:mismatch', 'key was "%s"', got{1});
assert(isequaln(got{2}, val), 'test:zmq:mismatch', 'value did not round-trip');
assert(isa(got{2}.n, 'int32'), 'test:zmq:mismatch', 'int32 came back as %s', class(got{2}.n));
end

function t_pubsub_kv_simple()
% The _simple pair uses stock jsonencode/jsondecode, so numbers come back
% as doubles. Assert the values, not the classes.
[pub, sub, g] = pubsub_pair('kvs'); %#ok<ASGLU>
val = struct('a', 1, 'b', 'two');
[ok, got] = pump(@() pub.sendkv_simple('kvs', val), @() r_kv_simple(sub));
assert(ok, 'test:zmq:timeout', 'no key/value arrived');
assert(strcmp(got{1}, 'kvs'), 'test:zmq:mismatch', 'key was "%s"', got{1});
assert(got{2}.a == 1 && strcmp(got{2}.b, 'two'), 'test:zmq:mismatch', 'value wrong');
end

function t_pubsub_json()
[pub, sub, g] = pubsub_pair('js'); %#ok<ASGLU>
val = struct('trial', 12, 'correct', true);
[ok, got] = pump(@() pub.sendkv_simple('js', val), @() r_json(sub));
assert(ok, 'test:zmq:timeout', 'no json arrived');
assert(strcmp(got{1}, 'js'), 'test:zmq:mismatch', 'addr was "%s"', got{1});
assert(got{2}.trial == 12 && got{2}.correct, 'test:zmq:mismatch', 'payload wrong');
end

%% ---- push/pull ------------------------------------------------------
% PULL binds and PUSH connects by default, which is the one bind the class
% has always done; these cases pass no 'bind' option so that default stays
% pinned. PUSH queues rather than drops, so no republish loop is needed.

function t_pushpull_msg()
[push, pull, g] = pushpull_pair(); %#ok<ASGLU>
sent = {'one', 'two', 'three', 'four', 'five'};
for k = 1:numel(sent)
    push.sendmsg(sent{k});
end
got = drain(@() r_msg(pull), numel(sent));
assert(numel(got) == numel(sent), 'test:zmq:timeout', ...
    'got %d of %d messages', numel(got), numel(sent));
assert(isequal(got(:), sent(:)), 'test:zmq:mismatch', 'order or content differs');
end

function t_pushpull_kv()
[push, pull, g] = pushpull_pair(); %#ok<ASGLU>
val = struct('ts', 1.25, 'vec', int16([3 4 5]));
push.sendkv('ev', val);
[ok, got] = wait_for(@() r_kv(pull));
assert(ok, 'test:zmq:timeout', 'no key/value arrived');
assert(strcmp(got{1}, 'ev'), 'test:zmq:mismatch', 'key was "%s"', got{1});
assert(isequaln(got{2}, val), 'test:zmq:mismatch', 'value did not round-trip');
end

function t_pushpull_bytes()
% recv hands back a Java byte[], which MATLAB surfaces as a *column* of
% signed int8, so callers need both a typecast and an orientation fix to
% get their row of uint8 back. Pin both -- they are the whole contract of
% sendbytes/recvbytes.
[push, pull, g] = pushpull_pair(); %#ok<ASGLU>
payload = uint8([0 1 65 127 128 254 255]);
push.sendbytes(payload);
[ok, got] = wait_for(@() r_bytes(pull));
assert(ok, 'test:zmq:timeout', 'no bytes arrived');
assert(isa(got, 'int8'), 'test:zmq:mismatch', 'recvbytes gave %s', class(got));
assert(iscolumn(got), 'test:zmq:mismatch', 'recvbytes gave a %s', mat2str(size(got)));
assert(isequal(typecast(got, 'uint8'), payload(:)), 'test:zmq:mismatch', ...
    'bytes differ: %s', mat2str(got));
end

%% ---- req/rep --------------------------------------------------------
% REQ/REP is strict lockstep, which single-threaded MATLAB can drive on
% its own: the REQ send returns as soon as it is queued, so the REP end
% can receive, answer, and hand control back without a second process.

function t_reqrep_msg()
[req, rep, g] = reqrep_pair(); %#ok<ASGLU>
for k = 1:3
    ask = sprintf('ping %d', k);
    req.sendmsg(ask);

    got = rep.waitformsg();
    assert(strcmp(got, ask), 'test:zmq:mismatch', ...
        'round %d: server saw "%s"', k, got);

    rep.sendmsg(sprintf('pong %d', k));
    back = req.waitformsg();
    assert(strcmp(back, sprintf('pong %d', k)), 'test:zmq:mismatch', ...
        'round %d: client saw "%s"', k, back);
end
end

function t_reqrep_json()
[req, rep, g] = reqrep_pair(); %#ok<ASGLU>
req.sendkv_simple('cmd', struct('op', 'status'));

[addr, body] = rep.waitforjson();
assert(strcmp(addr, 'cmd'), 'test:zmq:mismatch', 'addr was "%s"', addr);
assert(strcmp(body.op, 'status'), 'test:zmq:mismatch', 'op was "%s"', body.op);

rep.sendkv('reply', struct('busy', false, 'queue', uint8(3)));
% The class has no blocking key/value receive, so drive the blocking string
% receive and split it the same way recvkv does.
raw = req.waitformsg();
[rkey, rest] = strtok(raw, ' ');
rval = json.mloads(rest(2:end));
assert(strcmp(rkey, 'reply'), 'test:zmq:mismatch', 'reply key was "%s"', rkey);
assert(rval.busy == false && rval.queue == 3, 'test:zmq:mismatch', 'reply body wrong');
assert(isa(rval.queue, 'uint8'), 'test:zmq:mismatch', 'uint8 came back as %s', class(rval.queue));
end

function t_reqrep_bytes()
[req, rep, g] = reqrep_pair(); %#ok<ASGLU>
payload = uint8([10 200 30]);
req.sendbytes(payload);

got = rep.waitfordata();
assert(isequal(typecast(got, 'uint8'), payload(:)), 'test:zmq:mismatch', ...
    'server saw %s', mat2str(got));

rep.sendbytes(uint8([9 9]));
back = req.waitfordata();
assert(isequal(typecast(back, 'uint8'), uint8([9; 9])), 'test:zmq:mismatch', ...
    'client saw %s', mat2str(back));
end

%% ---- lifecycle ------------------------------------------------------

function t_close_idempotent()
% Nothing used to close these, so every construction leaked a socket and a
% context with its own I/O thread. close() must be safe to call twice and
% must free the port, or a re-run of this suite would fight itself.
port = freeport();
url  = sprintf('tcp://127.0.0.1:%d', port);

s = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false);
s.close();
s.close();   % must not throw

% The port is free again, so the same url binds a second time.
s2 = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false);
c2 = onCleanup(@() s2.close()); %#ok<NASGU>
assert(isvalid(s2), 'test:zmq:lifecycle', 'rebind produced a dead object');
end

%% ---- loadconf -------------------------------------------------------

function t_loadconf_urls()
fname = write_ini();
c = onCleanup(@() delete(fname)); %#ok<NASGU>

want = {
    'pub',  'tcp://127.0.0.1:5001'
    'sub',  'tcp://127.0.0.1:5002'
    'push', 'tcp://127.0.0.1:5003'
    'pull', 'tcp://*:5004'
    };
for k = 1:size(want, 1)
    got = net.zmqhelper.loadconf(want{k, 1}, 'fname', fname);
    assert(strcmp(got, want{k, 2}), 'test:zmq:conf', ...
        '%s: got "%s", want "%s"', want{k, 1}, got, want{k, 2});
end

% A non-default service reads its own section.
got = net.zmqhelper.loadconf('pub', 'fname', fname, 'service', 'gameserver');
assert(strcmp(got, 'tcp://10.0.0.9:6001'), 'test:zmq:conf', 'service section: got "%s"', got);
end

function t_loadconf_errors()
fname = write_ini();
c = onCleanup(@() delete(fname)); %#ok<NASGU>

threw = false;
try
    net.zmqhelper.loadconf('pub', 'fname', fname, 'service', 'nosuchservice');
catch
    threw = true;
end
assert(threw, 'test:zmq:conf', 'missing service did not raise');

threw = false;
try
    net.zmqhelper.loadconf('rep', 'fname', fname);
catch
    threw = true;
end
assert(threw, 'test:zmq:conf', 'socket type with no configured port did not raise');
end

%% ---- socket pairs ---------------------------------------------------

function [pub, sub, guard] = pubsub_pair(topic)
[pub, url] = bind_retry('pub');
sub = net.zmqhelper('type', 'sub', 'url', url, 'subscriptions', {topic}, 'verbose', false);
guard = onCleanup(@() close_all(pub, sub));
end

function [push, pull, guard] = pushpull_pair()
% No 'bind' option anywhere here: pull binding and push connecting is the
% class's own default and this case exists to keep it that way.
[pull, url] = bind_retry('pull');
push = net.zmqhelper('type', 'push', 'url', url, 'verbose', false);
guard = onCleanup(@() close_all(pull, push));
end

function [req, rep, guard] = reqrep_pair()
[rep, url] = bind_retry('rep');
req = net.zmqhelper('type', 'req', 'url', url, 'verbose', false);
% Both ends block in this pattern; without a timeout a regression hangs
% the runner instead of failing it.
rep.socket.setReceiveTimeOut(5000);
req.socket.setReceiveTimeOut(5000);
guard = onCleanup(@() close_all(rep, req));
end

function [s, url] = bind_retry(socktype)
% freeport() closes its probe socket before zmq binds, so another process
% can take the port in between. Rare, but cheap to retry.
for attempt = 1:10
    url = sprintf('tcp://127.0.0.1:%d', freeport());
    try
        args = {'type', socktype, 'url', url, 'verbose', false};
        if ~strcmpi(socktype, 'pull')
            args = [args, {'bind', true}]; %#ok<AGROW>
        end
        s = net.zmqhelper(args{:});
        return
    catch me
        if attempt == 10
            rethrow(me);
        end
    end
end
end

function close_all(varargin)
for k = 1:numel(varargin)
    try
        varargin{k}.close();
    catch
        % a close failure must not mask the assertion that is unwinding
    end
end
end

function p = freeport()
ss = java.net.ServerSocket(0);
p = double(ss.getLocalPort());
ss.close();
end

%% ---- receive helpers ------------------------------------------------
% Each returns [ok, payload] so pump/wait_for/drain can treat them alike.

function [ok, out] = r_msg(s)
out = s.recvmsg();
ok  = ~isempty(out);
end

function [ok, out] = r_kv(s)
[key, val] = s.recvkv();
ok  = ~isempty(key);
out = {key, val};
end

function [ok, out] = r_kv_simple(s)
[key, val] = s.recvkv_simple();
ok  = ~isempty(key);
out = {key, val};
end

function [ok, out] = r_json(s)
[addr, body] = s.recvjson();
ok  = ~isempty(addr);
out = {addr, body};
end

function [ok, out] = r_bytes(s)
out = s.recvbytes();
ok  = ~isempty(out);
end

%% ---- polling --------------------------------------------------------

function [ok, out] = pump(sendfun, recvfun, timeout)
% Republish until it lands. Only pub/sub needs this.
if nargin < 3
    timeout = 5;
end
ok  = false;
out = [];
t0  = tic;
while toc(t0) < timeout
    sendfun();
    for k = 1:25
        [ok, out] = recvfun();
        if ok
            return
        end
        pause(0.01);
    end
end
end

function [ok, out] = wait_for(recvfun, timeout)
% Poll a non-blocking receive for something already sent.
if nargin < 2
    timeout = 5;
end
ok  = false;
out = [];
t0  = tic;
while toc(t0) < timeout
    [ok, out] = recvfun();
    if ok
        return
    end
    pause(0.01);
end
end

function got = drain(recvfun, nwant, timeout)
if nargin < 3
    timeout = 5;
end
got = {};
t0  = tic;
while numel(got) < nwant && toc(t0) < timeout
    [ok, out] = recvfun();
    if ok
        got{end+1} = out; %#ok<AGROW>
    else
        pause(0.01);
    end
end
end

%% ---- fixtures -------------------------------------------------------

function fname = write_ini()
fname = [tempname '.dbconf'];
f = fopen(fname, 'w');
c = onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f, '[zmq]\n');
fprintf(f, 'url = tcp://127.0.0.1\n');
fprintf(f, 'pubport = 5001\n');
fprintf(f, 'subport = 5002\n');
fprintf(f, 'pushport = 5003\n');
fprintf(f, 'pullport = 5004\n');
fprintf(f, '\n');
fprintf(f, '[gameserver]\n');
fprintf(f, 'url = tcp://10.0.0.9\n');
fprintf(f, 'pubport = 6001\n');
fprintf(f, 'subport = 6002\n');
end
