function varargout = test_zmq(varargin)
% results = test.test_zmq(['verbose', tf], ['only', 'substring'])
%
% 'only' runs every case whose name contains the substring, and errors
% if none does -- a mistyped filter must not report a green run.
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
        strjoin(cellfun(@optionname, args(1:2:end), 'UniformOutput', false), ', '));
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
    'recvkv_empty',      @t_recvkv_empty
    'recvkv_simple_empty', @t_recvkv_simple_empty
    'reqrep_msg',        @t_reqrep_msg
    'reqrep_json',       @t_reqrep_json
    'reqrep_bytes',      @t_reqrep_bytes
    'close_idempotent',  @t_close_idempotent
    'close_failure',     @t_close_failure
    'use_after_close',   @t_use_after_close
    'option_validation', @t_option_validation
    'linger_bounded',    @t_linger_bounded
    'close_never_throws', @t_close_never_throws
    'socket_protected',  @t_socket_protected
    'loadconf_urls',     @t_loadconf_urls
    'loadconf_errors',   @t_loadconf_errors
    'jar_in_effect',     @t_jar_in_effect
    'jar_shadow',        @t_jar_shadow
    'jar_plan_is_inert', @t_jar_plan_is_inert
    'only_filter_typo',  @t_only_filter_typo
    };

cases = filtercases(cases, only);
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
[pub, sub, teardown] = pubsub_pair('topic'); %#ok<ASGLU>
[ok, got] = pump(@() pub.sendmsg('topic hello'), @() r_msg(sub));
assert(ok, 'test:zmq:timeout', 'no message arrived within the deadline');
assert(strcmp(got, 'topic hello'), 'test:zmq:mismatch', 'got "%s"', got);
end

function t_pubsub_filter()
% A negative result on pub/sub is meaningless unless the link is known to
% be live, so first prove a subscribed topic gets through, then check that
% an unsubscribed one published on the same live socket does not.
[pub, sub, teardown] = pubsub_pair('alpha'); %#ok<ASGLU>
ok = pump(@() pub.sendmsg('alpha ping'), @() r_msg(sub));
assert(ok, 'test:zmq:timeout', 'subscribed topic never arrived');

nsent = 20;
for k = 1:nsent
    pub.sendmsg('beta nope');
    pub.sendmsg('alpha yes');
end

% Drain to a deadline rather than stopping at the first empty read: a
% leaked 'beta' can still be in flight behind the last 'alpha', and an
% empty read means only that nothing has arrived yet.
nalpha = 0;
t0 = tic;
while toc(t0) < 2
    got = sub.recvmsg();
    if isempty(got)
        pause(0.01);
        continue
    end
    assert(strncmp(got, 'alpha', 5), 'test:zmq:leak', ...
        'unsubscribed topic leaked through: "%s"', got);
    nalpha = nalpha + 1;
end
assert(nalpha == nsent, 'test:zmq:timeout', ...
    'got %d of %d subscribed messages', nalpha, nsent);
end

function t_pubsub_kv()
% sendkv/recvkv go through json.mdumps/mloads, which preserves class and
% shape -- that is the whole reason the repo has its own json codec.
[pub, sub, teardown] = pubsub_pair('kv'); %#ok<ASGLU>
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
[pub, sub, teardown] = pubsub_pair('kvs'); %#ok<ASGLU>
val = struct('a', 1, 'b', 'two');
[ok, got] = pump(@() pub.sendkv_simple('kvs', val), @() r_kv_simple(sub));
assert(ok, 'test:zmq:timeout', 'no key/value arrived');
assert(strcmp(got{1}, 'kvs'), 'test:zmq:mismatch', 'key was "%s"', got{1});
assert(got{2}.a == 1 && strcmp(got{2}.b, 'two'), 'test:zmq:mismatch', 'value wrong');
end

function t_pubsub_json()
[pub, sub, teardown] = pubsub_pair('js'); %#ok<ASGLU>
val = struct('trial', 12, 'correct', true);
[ok, got] = pump(@() pub.sendkv_simple('js', val), @() r_json(sub));
assert(ok, 'test:zmq:timeout', 'no json arrived');
assert(strcmp(got{1}, 'js'), 'test:zmq:mismatch', 'addr was "%s"', got{1});
assert(got{2}.trial == 12 && got{2}.correct, 'test:zmq:mismatch', 'payload wrong');
end

%% ---- push/pull ------------------------------------------------------
% PULL binds and PUSH connects by default, which is the one bind the class
% does on its own; these cases pass no 'bind' option so that default stays
% pinned. PUSH queues rather than drops, so no republish loop is needed.

function t_pushpull_msg()
[push, pull, teardown] = pushpull_pair(); %#ok<ASGLU>
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
[push, pull, teardown] = pushpull_pair(); %#ok<ASGLU>
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
[push, pull, teardown] = pushpull_pair(); %#ok<ASGLU>
payload = uint8([0 1 65 127 128 254 255]);
push.sendbytes(payload);
[ok, got] = wait_for(@() r_bytes(pull));
assert(ok, 'test:zmq:timeout', 'no bytes arrived');
assert(isa(got, 'int8'), 'test:zmq:mismatch', 'recvbytes gave %s', class(got));
assert(iscolumn(got), 'test:zmq:mismatch', 'recvbytes gave a %s', mat2str(size(got)));
assert(isequal(typecast(got, 'uint8'), payload(:)), 'test:zmq:mismatch', ...
    'bytes differ: %s', mat2str(got));
end

function t_recvkv_empty()
% Nothing has been sent, so this pins the quiet-socket contract directly
% rather than leaving it to whichever poll happens to read an empty
% socket first: an empty char key, matching what recvmsg returns for
% nothing, because callers do ischar(key) and sprintf('%s', key) on it.
[~, pull, teardown] = pushpull_pair(); %#ok<ASGLU>
[key, val] = pull.recvkv();
assert(ischar(key) && isempty(key), 'test:zmq:mismatch', ...
    'empty recvkv gave a %s key, want an empty char', class(key));
assert(isempty(val), 'test:zmq:mismatch', 'empty recvkv gave a non-empty value');
end

function t_recvkv_simple_empty()
[~, pull, teardown] = pushpull_pair(); %#ok<ASGLU>
[key, val] = pull.recvkv_simple();
assert(ischar(key) && isempty(key), 'test:zmq:mismatch', ...
    'empty recvkv_simple gave a %s key, want an empty char', class(key));
assert(isempty(val), 'test:zmq:mismatch', 'empty recvkv_simple gave a non-empty value');
end

%% ---- req/rep --------------------------------------------------------
% REQ/REP is strict lockstep, which single-threaded MATLAB can drive on
% its own: the REQ send returns as soon as it is queued, so the REP end
% can receive, answer, and hand control back without a second process.

function t_reqrep_msg()
[req, rep, teardown] = reqrep_pair(); %#ok<ASGLU>
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
[req, rep, teardown] = reqrep_pair(); %#ok<ASGLU>
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
[req, rep, teardown] = reqrep_pair(); %#ok<ASGLU>
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
% An unclosed helper holds its port and runs a context I/O thread, so
% close() must be safe to call twice and must actually free the port --
% otherwise a re-run of this suite fights itself.
port = freeport();
url  = sprintf('tcp://127.0.0.1:%d', port);

s = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false);
s.close();
s.close();   % must not throw

% Binding the same url a second time is this case's assertion: the
% constructor throws if the first socket still holds the port.
s2 = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false);
c2 = onCleanup(@() s2.close());
end

function t_close_failure()
% A socket that failed to close must keep its handle, and its context must
% NOT be terminated: Context.term() does not return while a socket in that
% context is still open -- measured on jeromq 0.6.0, a bound PULL with
% linger 0 left term() blocked 60 s later, and there is no timeout to
% reach for. Those two invariants are what keeps an unhappy teardown
% bounded, so they are what this case asserts; asserting "close() returns"
% directly is not possible in-process, because the failure mode is a hang.
[s, realsock] = lone_pull(@test.zmqhelper_probe);
realsock.close();   % so nothing in the context is open: this case cannot
                    % hang even if the guard below is removed
s.replacesocket(struct('not', 'a socket'));   % close() on this throws

[~, id] = with_warnings_off(@() s.close(), 'net:zmqhelper:closefailed');
assert(strcmp(id, 'net:zmqhelper:closefailed'), 'test:zmq:lifecycle', ...
    'a failed socket close was not reported (last warning id "%s")', id);
assert(~isempty(s.socket), 'test:zmq:lifecycle', ...
    'the handle to a socket that failed to close was discarded');
assert(~isempty(s.context), 'test:zmq:lifecycle', ...
    'the context was terminated while its socket was still open');

s.replacesocket(realsock);   % already closed, so this tears down cleanly
s.close();
end

function t_use_after_close()
% getPublisher/getPusher hand every caller the same object, so one holder
% closing it leaves the others with a live handle to a dead socket. Every
% send/receive must name that, not fail somewhere inside the java bridge.
[s, ~] = lone_pull();
s.close();

calls = {
    'sendmsg',        @() s.sendmsg('x')
    'sendkv',         @() s.sendkv('k', 1)
    'sendkv_simple',  @() s.sendkv_simple('k', 1)
    'sendbytes',      @() s.sendbytes(uint8(1))
    'recvmsg',        @() s.recvmsg()
    'recvbytes',      @() s.recvbytes()
    'recvkv',         @() s.recvkv()
    'recvkv_simple',  @() s.recvkv_simple()
    'recvjson',       @() s.recvjson()
    'waitformsg',     @() s.waitformsg()
    'waitforjson',    @() s.waitforjson()
    'waitfordata',    @() s.waitfordata()
    };
for k = 1:size(calls, 1)
    id = '';
    try
        calls{k, 2}();
    catch me
        id = me.identifier;
    end
    assert(strcmp(id, 'net:zmqhelper:closed'), 'test:zmq:lifecycle', ...
        '%s after close raised "%s", want net:zmqhelper:closed', calls{k, 1}, id);
end
end

function t_option_validation()
% A mistyped or ill-typed option has to be an error, and it has to say
% which option: a 'verbos' typo is ignored in silence otherwise. Every row
% must fail before any socket exists, or it leaks one.
url = sprintf('tcp://127.0.0.1:%d', freeport());
base   = {'type', 'pull', 'url', url, 'verbose', false};
quiet  = {'type', 'pull', 'url', url};   % rows that set 'verbose' themselves

bad = {
    'net:zmqhelper:unknownoption', [base,  {'verbos', false}]
    'net:zmqhelper:unknownoption', [base,  {struct('a', 1), 7}]
    'net:zmqhelper:badtype',       [{'type', 'frob'}, {'url', url, 'verbose', false}]
    'net:zmqhelper:badbind',       [base,  {'bind', 'yes'}]
    'net:zmqhelper:badlinger',     [base,  {'linger', [10 20]}]
    'net:zmqhelper:badverbose',    [quiet, {'verbose', 'quiet'}]
    };
for k = 1:size(bad, 1)
    id = '';
    try
        s = net.zmqhelper(bad{k, 2}{:});
        s.close();
    catch me
        id = me.identifier;
    end
    assert(strcmp(id, bad{k, 1}), 'test:zmq:options', ...
        'option set %d raised "%s", want "%s"', k, id, bad{k, 1});
end
end

function t_linger_bounded()
% Every linger this class accepts has to keep close() bounded, and zmq
% reads any negative linger as "wait forever". Two ways in:
%   * -1 directly, which is zmq's own spelling of forever;
%   * anything above intmax('int32'), because setLinger takes a java int
%     and MATLAB truncates a double into it with wraparound -- measured by
%     reading the value back, 3e9 lands as -1294967296 and 1e12 as
%     -727379968, both negative, both forever.
% The linger is spent inside term() (2.008 s at 2000, 0.003 s at 0, none
% of it in socket.close()), so a wrapped value hangs close(), and close()
% runs from delete(). Being finite is not the same as being bounded.
url = sprintf('tcp://127.0.0.1:%d', freeport());
for linger = [-1 -1000 3e9 1e12]
    id = '';
    try
        s = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false, 'linger', linger);
        s.close();
    catch me
        id = me.identifier;
    end
    assert(strcmp(id, 'net:zmqhelper:badlinger'), 'test:zmq:options', ...
        'linger %g raised "%s", want net:zmqhelper:badlinger', linger, id);
end

% The largest accepted value must survive the trip into java intact --
% reading it back is the check, since closing at that linger would hang
% exactly as the wrapped values do.
top = double(intmax('int32'));
s = net.zmqhelper('type', 'pull', 'url', url, 'verbose', false, 'linger', top);
guard = onCleanup(@() s.close());
got = double(s.socket.getLinger());
assert(got == top, 'test:zmq:options', ...
    'linger %g came back from the socket as %d', top, got);
end

function t_socket_protected()
% The socket handle reads but does not assign from outside. `h.socket = []`
% was a one-line route to a helper holding a socket it could neither close
% nor prove closed, and there is no legitimate reason for a caller to swap
% the handle of a live java socket.
[s, ~] = lone_pull();
guard = onCleanup(@() s.close());
id = '';
try
    s.socket = [];
catch me
    id = me.identifier;
end
assert(strcmp(id, 'MATLAB:class:SetProhibited'), 'test:zmq:lifecycle', ...
    'assigning to socket from outside raised "%s", want MATLAB:class:SetProhibited', id);
assert(~isempty(s.socket), 'test:zmq:lifecycle', 'the socket handle was replaced anyway');
end

function t_close_never_throws()
% close() runs from delete() and from onCleanup while an assertion is
% unwinding, so it must not throw even when its own warning is promoted to
% an error -- warning('error', id) is a legitimate thing for a caller or a
% CI runner to set.
[s, realsock] = lone_pull(@test.zmqhelper_probe);
realsock.close();
s.replacesocket(struct('not', 'a socket'));

state = warning('error', 'net:zmqhelper:closefailed');
restore = onCleanup(@() warning(state));
id = '';
try
    evalc('s.close()');   % swallow the fallback report, assert on behaviour
catch me
    id = me.identifier;
end
assert(isempty(id), 'test:zmq:lifecycle', ...
    'close() threw "%s" with its warning promoted to an error', id);

clear restore
s.replacesocket(realsock);
s.close();
end

%% ---- loadconf -------------------------------------------------------

function t_loadconf_urls()
fname = write_ini();
c = onCleanup(@() delete(fname));

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
% Check identifiers, not just that something threw: an unreadable temp
% file or a typo in the call would satisfy a bare catch.
fname = write_ini();
c = onCleanup(@() delete(fname));

want = {
    'net:zmqhelper:unknownservice',  @() net.zmqhelper.loadconf('pub', 'fname', fname, 'service', 'nosuchservice')
    'net:zmqhelper:unknownsocktype', @() net.zmqhelper.loadconf('rep', 'fname', fname)
    };
for k = 1:size(want, 1)
    id = '';
    try
        want{k, 2}();
    catch me
        id = me.identifier;
    end
    assert(strcmp(id, want{k, 1}), 'test:zmq:conf', ...
        'raised "%s", want "%s"', id, want{k, 1});
end
end

%% ---- harness ---------------------------------------------------------

function t_jar_in_effect()
% The suite is evidence about one jar, so it has to check which jar it
% actually ran against -- by full path, not by directory: an older
% jeromq-*.jar left in +net by a branch switch would otherwise pass green
% while it is the one in effect.
want = bundledjar();
got  = net.addZMQConnecterToPath();
assert(strcmp(got, want), 'test:zmq:jar', ...
    'the jeromq in effect is %s, want the bundled %s', got, want);
end

function t_jar_shadow()
% What the function has to get right when it is not the only jeromq
% around, and the measurements behind each row (R2026a, jeromq 0.6.0 and
% 0.5.2, told apart by the members of org.zeromq.ZMQ$Socket):
%   * the most recently added jar wins, javaclasspath('-dynamic') lists it
%     first, and re-adding a jar already on the dynamic path moves it to
%     the front -- so a jeromq ahead of ours can be displaced, and the
%     bundled jar is still the honest answer;
%   * a jeromq on the static path beats anything added at run time and
%     javaaddpath refuses it, so that one is reported rather than fought --
%     unless it is our own jar, deployed through javaclasspath.txt, which
%     is already exactly what we want and must not be complained about.

% Class paths are injected: adding a second jeromq for real would pin its
% classes for every case after this one.
[bundled, netdir] = bundledjar();
other = fullfile(netdir, 'jeromq-0.0.1.jar');   % named, never added

%     static     dynamic            in effect  warning
want = {
    {},         {},                 bundled,   ''
    {},         {other},            bundled,   ''
    {},         {other, bundled},   bundled,   ''
    {other},    {bundled},          other,     'net:addZMQConnecterToPath:staticjeromq'
    {bundled},  {},                 bundled,   ''
    };

% The shadow row warns by design; silencing still updates lastwarn, so the
% case can assert that it reported rather than print it.
state = warning('off', 'net:addZMQConnecterToPath:staticjeromq');
restore = onCleanup(@() warning(state));

for k = 1:size(want, 1)
    lastwarn('', '');
    jarpath = net.addZMQConnecterToPath('plan', true, ...
        'staticpath', want{k, 1}, 'dynamicpath', want{k, 2});
    assert(strcmp(jarpath, want{k, 3}), 'test:zmq:jar', ...
        'row %d: reported %s as in effect, want %s', k, jarpath, want{k, 3});
    [~, wid] = lastwarn();
    assert(strcmp(wid, want{k, 4}), 'test:zmq:jar', ...
        'row %d: warned "%s", want "%s"', k, wid, want{k, 4});
end
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

function cases = filtercases(cases, only)
% Keep every case whose name contains the substring. A name that matches
% nothing is an error: a filtered CI run must not go green just because a
% case was renamed.
if isempty(only)
    return
end
cases = cases(contains(cases(:, 1), only), :);
assert(~isempty(cases), 'test:zmq:nomatch', 'no case name contains "%s"', only);
end

function t_jar_plan_is_inert()
% Asking what the function would do must never change what is loaded.
% Plan mode has to be asked for explicitly: inferring it from the type of
% a class-path argument means a caller who passes a string, or "", gets a
% real javaaddpath against the live JVM instead of an answer -- and that
% cannot be undone within the session.
before = javaclasspath('-dynamic');

id = '';
try
    net.addZMQConnecterToPath('staticpath', "");
catch me
    id = me.identifier;
end
assert(strcmp(id, 'net:addZMQConnecterToPath:badoption'), 'test:zmq:jar', ...
    'a non-cell staticpath raised "%s", want net:addZMQConnecterToPath:badoption', id);

% Class paths without 'plan' would mean "pretend these, then really add",
% which is not a thing this function should do.
id = '';
try
    net.addZMQConnecterToPath('dynamicpath', {});
catch me
    id = me.identifier;
end
assert(strcmp(id, 'net:addZMQConnecterToPath:badoption'), 'test:zmq:jar', ...
    'class paths without plan raised "%s", want net:addZMQConnecterToPath:badoption', id);

after = javaclasspath('-dynamic');
assert(isequal(before, after), 'test:zmq:jar', ...
    'the java class path changed while being asked a hypothetical');
end

function [jarpath, netdir] = bundledjar()
% The one jeromq jar that ships in +net. Two of them means a stale jar was
% left behind, and every claim the suite makes about "the" jar is then a
% coin flip.
netdir = fileparts(which('net.addZMQConnecterToPath'));
found  = dir(fullfile(netdir, 'jeromq*.jar'));
assert(isscalar(found), 'test:zmq:jar', ...
    'expected exactly one bundled jeromq jar in %s, found %d: %s', ...
    netdir, numel(found), strjoin({found.name}, ', '));
jarpath = fullfile(netdir, found.name);
end

function t_only_filter_typo()
% A mistyped 'only' must fail, not report a green run over zero cases.
% This drives the filter directly on a synthetic list rather than calling
% the suite again: a case that re-runs its own suite is a recursion
% waiting to happen, and this one would be unbounded the moment the guard
% it tests stopped working.
synthetic = {'alpha', @() []; 'beta', @() []; 'alphabet', @() []};

id = '';
try
    filtercases(synthetic, 'nosuchcasename');
catch me
    id = me.identifier;
end
assert(strcmp(id, 'test:zmq:nomatch'), 'test:zmq:harness', ...
    'an unmatched "only" raised "%s", want test:zmq:nomatch', id);

% 'only' is a substring match, which is what the help promises.
kept = filtercases(synthetic, 'alpha');
assert(isequal(kept(:, 1), {'alpha'; 'alphabet'}), 'test:zmq:harness', ...
    'substring filter kept [%s]', strjoin(kept(:, 1)', ', '));
end

%% ---- socket pairs ---------------------------------------------------

% Each pair returns its teardown as the third output. The caller must keep
% it in a live variable -- an onCleanup fires the moment it goes out of
% scope, so assigning it to ~ would silently strip teardown from the case.

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

function [s, jsocket] = lone_pull(ctor)
% A bound pull socket with nothing connected to it, for the lifecycle
% cases. It hands back the underlying java socket too, so a case can drive
% teardown itself; the caller owns closing the helper. Pass
% @test.zmqhelper_probe to get one whose socket handle can be swapped.
if nargin < 1
    ctor = @net.zmqhelper;
end
[s, ~] = bind_retry('pull', ctor);
jsocket = s.socket;
end

function [msg, id] = with_warnings_off(fn, varargin)
% Run fn with the named warnings silenced, and hand back the last warning
% it raised. Silencing still updates lastwarn, so the assertion sees the
% identifier while a passing run stays quiet.
state = warning();
restore = onCleanup(@() warning(state));
for k = 1:numel(varargin)
    warning('off', varargin{k});
end
lastwarn('', '');
fn();
[msg, id] = lastwarn();
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

function [s, url] = bind_retry(socktype, ctor)
% freeport() closes its probe socket before zmq binds, so another process
% can take the port in between. Rare, but cheap to retry.
if nargin < 2
    ctor = @net.zmqhelper;
end
for attempt = 1:10
    url = sprintf('tcp://127.0.0.1:%d', freeport());
    try
        args = {'type', socktype, 'url', url, 'verbose', false};
        if ~strcmpi(socktype, 'pull')
            args = [args, {'bind', true}]; %#ok<AGROW>
        end
        s = ctor(args{:});
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
c = onCleanup(@() fclose(f));
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
