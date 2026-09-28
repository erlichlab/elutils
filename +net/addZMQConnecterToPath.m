function jarpath = addZMQConnecterToPath(varargin)
% jarpath = net.addZMQConnecterToPath(['plan', tf], ['staticpath', c], ['dynamicpath', c])
%
% Makes the bundled jeromq jar the one org.zeromq resolves to, and returns
% the jar that is in effect. That is the bundled one unless another jeromq
% cannot be displaced, in which case it is that jar and an identified
% warning says which one and why.
%
% Pass 'plan', true to get the answer without touching this session's
% class path, optionally with 'staticpath'/'dynamicpath' standing in for
% the real ones; whichever list is not supplied is read from the session.
% That is how the tests drive the shadow branches, because adding a second
% jeromq for real pins its classes for the rest of the session.
%
% The version is in the filename deliberately, and these are the rules it
% exists to make visible. Measured on R2026a with jeromq 0.6.0 and 0.5.2,
% telling them apart by the members of org.zeromq.ZMQ$Socket:
%
%   * The most recently added jar wins, and javaclasspath('-dynamic')
%     lists it first -- adding 0.5.2 then 0.6.0 loads 0.6.0, and the
%     reverse order loads 0.5.2. So the front-most jeromq entry is live.
%   * Re-adding a jar already on the dynamic path moves it to the front
%     and changes which classes load, so being shadowed is fixable here.
%   * A jeromq on the static path (javaclasspath.txt) beats anything
%     added dynamically, and javaaddpath refuses it as already specified
%     (MATLAB:javaclasspath:jarAlreadySpecified). Only a restart fixes
%     that, so this reports it instead of pretending otherwise.
%   * Every jeromq release defines the same org.zeromq.* packages, so
%     whichever jar wins does so in silence.

inpd = @utils.inputordefault;
args = varargin;
[plan, args]        = inpd('plan', false, args);
[staticpath, args]  = inpd('staticpath', [], args);
[dynamicpath, args] = inpd('dynamicpath', [], args);
if ~isempty(args)
    error('net:addZMQConnecterToPath:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@optionname, args(1:2:end), 'UniformOutput', false), ', '));
end
assert((islogical(plan) || isnumeric(plan)) && isscalar(plan), ...
    'net:addZMQConnecterToPath:badoption', '''plan'' must be true or false, got a %s', ...
    class(plan));
plan = logical(plan);

% Whether to touch the JVM is asked for, never inferred from the type of
% something else: a caller passing a class path they meant as hypothetical
% would otherwise get a real javaaddpath, which cannot be undone in the
% session.
given = varargin(1:2:end);
supplied = @(name) any(cellfun(@(x) istext(x) && strcmpi(x, name), given));
assert(plan || ~(supplied('staticpath') || supplied('dynamicpath')), ...
    'net:addZMQConnecterToPath:badoption', ...
    'staticpath/dynamicpath describe a hypothetical, so they need ''plan'', true');

jarpath = fullfile(fileparts(mfilename('fullpath')), 'jeromq-0.6.0.jar');
% Checked before the class path is even read: a missing jar makes
% javaaddpath emit an identifier-less warning that no caller can catch,
% and surfaces much later as an unresolvable org.zeromq.ZMQ.
assert(isfile(jarpath), 'net:addZMQConnecterToPath:missingjar', ...
    'the bundled jeromq jar is not there: %s', jarpath);

% A list that was not supplied comes from the session, so a plan can vary
% one of them and still be asked about the real state of the other.
staticpath  = classpath(staticpath,  supplied('staticpath'),  '-static',  'staticpath');
dynamicpath = classpath(dynamicpath, supplied('dynamicpath'), '-dynamic', 'dynamicpath');

% Our own jar on the static path is a deployment, not a shadow: it is
% already the one in effect, and complaining would tell the user to delete
% the very jar that is working.
fixed  = jeromqs(staticpath);
shadow = setdiff(fixed, {jarpath}, 'stable');
if ~isempty(shadow)
    warning('net:addZMQConnecterToPath:staticjeromq', ...
        ['jeromq is on the static java class path:\n  %s\n' ...
         'Static entries beat anything added at run time, so %s cannot ' ...
         'take effect until that entry is removed from javaclasspath.txt ' ...
         'and MATLAB restarted.'], strjoin(shadow, sprintf('\n  ')), jarpath);
    jarpath = shadow{1};
    return
end

if any(strcmp(fixed, jarpath))
    return   % already in effect, from the static path
end

live = jeromqs(dynamicpath);
if (~isempty(live) && strcmp(live{1}, jarpath)) || plan
    return
end

% Adding ours puts it in front of any other jeromq, including one already
% listed behind it. The exception is classes that are already loaded with
% live objects: MATLAB then keeps them and says so, and this is the only
% cheap way to notice, so it is worth saying plainly.
lastwarn('', '');
javaaddpath(jarpath);
[~, wid] = lastwarn();
if ~isempty(live) && strcmp(wid, 'MATLAB:Java:DuplicateClass')
    warning('net:addZMQConnecterToPath:alreadyloaded', ...
        ['%s is now first on the java class path, but org.zeromq classes ' ...
         'from\n  %s\nare already loaded and still in use, so MATLAB kept ' ...
         'them. Restart MATLAB to pick up the bundled jar.'], ...
        jarpath, strjoin(live, sprintf('\n  ')));
    jarpath = live{1};
end

end

function out = classpath(given, wassupplied, which, name)
% The class path to reason about: the one supplied, or the session's.
if ~wassupplied
    out = javaclasspath(which);
    return
end
assert(iscellstr(given), 'net:addZMQConnecterToPath:badoption', ...
    '''%s'' must be a cell array of paths, got a %s', name, class(given)); %#ok<ISCLSTR>
out = given;
end

function tf = istext(x)
tf = (ischar(x) && isrow(x)) || (isstring(x) && isscalar(x));
end

function out = jeromqs(entries)
% The jeromq jars among class path entries, in the order given -- which,
% for the dynamic path, is most-recently-added first.
if isempty(entries)
    out = {};
    return
end
entries = reshape(cellstr(entries), 1, []);
out = entries(~cellfun('isempty', regexp(entries, 'jeromq[^/\\]*\.jar$', 'once')));
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
