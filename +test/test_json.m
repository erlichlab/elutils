function varargout = test_json(varargin)
% results = test.test_json(['verbose', tf], ['only', 'name'])
%
% Round-trip test for json.mdumps / json.mloads.
%
% For every value in test.json_cases it asserts
%
%   isequaln(s, json.mloads(json.mdumps(s)))
%
% and, because isequaln is too weak on its own to catch the bugs this format
% exists to prevent -- isequaln(1,true) and isequaln(int8(1),1) are both
% true, and it ignores struct field order -- it also asserts a strict
% comparison of class, size and field order at every level.
%
% Finally it replays golden format-1 payloads captured from the old
% implementation, so legacy rows in the database stay readable.
%
% Errors at the end if anything failed, so `matlab -batch "test.test_json"`
% is usable as a CI gate.

inpd = @utils.inputordefault;
args = varargin;
[verbose, args] = inpd('verbose', false, args);
[only, args]    = inpd('only', '', args);
[nseeds, args]  = inpd('nseeds', 200, args);
[depth, args]   = inpd('depth', 3, args);
if ~isempty(args)
    error('test:json:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@(x) char(string(x)), args(1:2:end), 'UniformOutput', false), ', '));
end

cases = test.json_cases();
if ~isempty(only)
    cases = cases(contains(cases(:, 1), only), :);
end
n = size(cases, 1);

R = repmat(struct('name', '', 'ok', false, 'why', '', 'bytes', 0), 1, n);
nfail = 0;

fprintf('\n=== json round-trip: %d cases ===\n', n);
for k = 1:n
    name = cases{k, 1};
    s    = cases{k, 2};
    ok   = false;
    nb   = 0;
    try
        j  = json.mdumps(s);
        nb = numel(j);
        b  = json.mloads(j);

        if ~isequaln(s, b)
            why = 'isequaln false';
        else
            [ok, why] = strict_equal(s, b, '');
        end
    catch me
        why = sprintf('%s: %s', me.identifier, me.message);
    end

    if ~ok
        nfail = nfail + 1;
        fprintf(2, '  FAIL %-22s %s\n', name, why);
    elseif verbose
        fprintf('  ok   %-22s (%d bytes)\n', name, nb);
    end
    R(k) = struct('name', name, 'ok', ok, 'why', why, 'bytes', nb);
end
fprintf('round-trip: %d/%d passed\n', n - nfail, n);

%% ---- property-based round-trip over random values -------------------
% The curated cases above cover what we thought of; this covers the
% combinations we did not. A failure prints its seed so it can be replayed
% exactly with rng(seed); test.json_randval(depth).
fprintf('\n=== property-based round-trip: %d random values ===\n', nseeds);
nfuzz = 0;
for seed = 1:nseeds
    rng(seed);
    s = test.json_randval(depth);
    ok = false;
    try
        b = json.mloads(json.mdumps(s));
        if ~isequaln(s, b)
            why = 'isequaln false';
        else
            [ok, why] = strict_equal(s, b, '');
        end
    catch me
        why = sprintf('%s: %s', me.identifier, me.message);
    end
    if ~ok
        nfuzz = nfuzz + 1;
        fprintf(2, '  FAIL seed %d: %s\n', seed, why);
        fprintf(2, '       replay: rng(%d); s = test.json_randval(%d);\n', seed, depth);
    end
end
fprintf('property-based: %d/%d passed\n', nseeds - nfuzz, nseeds);
nfail = nfail + nfuzz;

%% ---- the JSON we emit must be valid, plain JSON ----------------------
nfmt = 0;
fprintf('\n=== format sanity ===\n');
for k = 1:n
    try
        j = json.mdumps(cases{k, 2});
        D = jsondecode(j);   % must parse with the stock decoder, no rescue
        assert(isfield(D, 'fmt') && D.fmt == 2, 'missing/incorrect fmt');
        assert(isfield(D, 'vals') && isfield(D, 'info'), 'missing vals/info');
        assert(isfield(D, 'order') && strcmp(D.order, 'F'), 'missing order');
        assert(isfield(D, 'base') && D.base == 1, 'missing base');
    catch me
        nfmt = nfmt + 1;
        fprintf(2, '  FAIL %-22s %s\n', cases{k, 1}, me.message);
    end
end
fprintf('format sanity: %d/%d passed\n', n - nfmt, n);
nfail = nfail + nfmt;

%% ---- legacy format-1 payloads must still decode ---------------------
fprintf('\n=== format-1 (legacy) regression ===\n');
nv1 = 0; nv1fail = 0;
fix = fullfile(fileparts(mfilename('fullpath')), 'fixtures', 'json_v1_golden.mat');
if ~exist(fix, 'file')
    nv1fail = nv1fail + 1;
    fprintf(2, ['  FAIL fixture %s not found. It holds payloads captured from the ', ...
                'pre-v2 writer, which no longer exists in the tree, so it cannot be ', ...
                'regenerated -- restore it from git rather than deleting it.\n'], fix);
else
    F = load(fix);
    G = F.G;
    all_cases = test.json_cases();
    for g = 1:numel(G)
        if ~G(g).v1_ok
            continue    % v1 could not round-trip it in the first place
        end
        idx = find(strcmp(all_cases(:, 1), G(g).name), 1);
        if isempty(idx)
            % Renaming a case must not quietly shrink legacy coverage.
            nv1fail = nv1fail + 1;
            fprintf(2, ['  FAIL golden payload "%s" has no matching case in ', ...
                        'test.json_cases\n'], G(g).name);
            continue
        end
        nv1 = nv1 + 1;
        want = all_cases{idx, 2};
        try
            got = json.mloads(G(g).jstr);
            if ~isequaln(want, got)
                nv1fail = nv1fail + 1;
                fprintf(2, '  FAIL %-22s legacy payload no longer decodes equal\n', G(g).name);
            end
        catch me
            nv1fail = nv1fail + 1;
            fprintf(2, '  FAIL %-22s %s\n', G(g).name, me.message);
        end
    end
    fprintf('format-1 regression: %d/%d passed\n', nv1 - nv1fail, nv1);
end
nfail = nfail + nv1fail;

%% ---- non-standard JSON literals in legacy rows ----------------------
% The pre-R2016b json.tojson mex wrote bare NaN/Infinity. Current jsondecode
% accepts those as an extension, so such rows must read natively and keep Inf
% distinct from NaN; rewriting those literals to null would lose that.
fprintf('\n=== legacy NaN/Infinity literals ===\n');
nlit = 0;
lit = { 'bare_nan', ...
        '{"vals":{"t":[1,NaN,3]},"info":{"t":{"type__":"double","dim__":[1,3]}}}', ...
        [1 NaN 3]; ...
        'bare_infinity', ...
        '{"vals":{"t":[Infinity,-Infinity]},"info":{"t":{"type__":"double","dim__":[1,2]}}}', ...
        [Inf -Inf] };  % parsed natively, so Inf and -Inf survive intact
for k = 1:size(lit, 1)
    try
        got = json.mloads(lit{k, 2});
        if ~isequaln(got.t, lit{k, 3})
            nlit = nlit + 1;
            fprintf(2, '  FAIL %-16s got %s\n', lit{k, 1}, mat2str(got.t));
        end
    catch me
        nlit = nlit + 1;
        fprintf(2, '  FAIL %-16s %s\n', lit{k, 1}, me.message);
    end
end

% A char field containing the word NaN must survive untouched, which is why
% the literal rewrite only runs after a failed parse.
try
    s = 'the value is NaN and Infinity';
    if ~strcmp(json.mloads(json.mdumps(s)), s)
        nlit = nlit + 1;
        fprintf(2, '  FAIL literal NaN inside a string was rewritten\n');
    end
catch me
    nlit = nlit + 1;
    fprintf(2, '  FAIL string-with-NaN: %s\n', me.message);
end
fprintf('legacy literals: %d/%d passed\n', 3 - nlit, 3);
nfail = nfail + nlit;

%% ---- things that must fail loudly rather than silently corrupt ------
fprintf('\n=== rejected inputs ===\n');
bad = { 'complex',       1 + 2i; ...
        'complex_field', struct('z', 1 + 2i); ...
        'sparse',        sparse([1 0 2]); ...
        'fhandle',       @sin; ...
        'missing_str',   string(missing) };
nbad = 0;
for k = 1:size(bad, 1)
    threw = false;
    try
        json.mdumps(bad{k, 2});
    catch
        threw = true;
    end
    if ~threw
        nbad = nbad + 1;
        fprintf(2, '  FAIL %-22s was accepted but should have errored\n', bad{k, 1});
    end
end

% Unreadable input must name the real problem. There is no mex fallback any
% more, so the only thing to report is that the text is not JSON.
badtext = { 'not_json',      '{"vals":[1,2,  not json at all', 'json:mloads:invalidjson'; ...
            'plain_json',    '{"a":1,"b":2}',                  'json:mloads:unrecognised'; ...
            'future_format', '{"fmt":9,"vals":1,"info":[]}',    'json:mloads:version' };
for k = 1:size(badtext, 1)
    got = '';
    try
        json.mloads(badtext{k, 2});
    catch me
        got = me.identifier;
    end
    if ~strcmp(got, badtext{k, 3})
        nbad = nbad + 1;
        fprintf(2, '  FAIL %-22s expected %s, got "%s"\n', ...
            badtext{k, 1}, badtext{k, 3}, got);
    end
end
ntot = size(bad, 1) + size(badtext, 1);
fprintf('rejected inputs: %d/%d passed\n', ntot - nbad, ntot);
nfail = nfail + nbad;

%% ---- classdef objects are stored as their struct contents -----------
% They deliberately come back as plain structs, so this cannot be a
% round-trip case in test.json_cases.
fprintf('\n=== classdef objects ===\n');
nobj = 0;
try
    o = test.json_testobj(7);
    j = json.mdumps(o);
    D = jsondecode(j);
    root = D.info(1);
    if iscell(root), root = root{1}; end
    assert(strcmp(root.t, 'test.json_testobj'), 'root class not recorded, got %s', root.t);
    assert(strcmp(root.as, 'struct'), 'root missing as:struct');
    b = json.mloads(j);
    assert(isstruct(b), 'expected a struct back, got %s', class(b));
    assert(isequal(fieldnames(b), {'alpha'; 'beta'; 'gamma'}), 'fields/order wrong');
    assert(isequaln(b.alpha, 7) && strcmp(b.beta, 'two'), 'values wrong');
    assert(isequaln(b.gamma, {3, [4 5]}), 'nested cell property wrong');
catch me
    nobj = nobj + 1;
    fprintf(2, '  FAIL classdef object: %s\n', me.message);
end
fprintf('classdef objects: %d/1 passed\n', 1 - nobj);
nfail = nfail + nobj;

%% ---- malformed payloads must not decode to plausible data -----------
% None of these can come from json.mdumps, but mloads reads whatever is in
% the database -- a future writer, or a truncated MEDIUMTEXT column.
fprintf('\n=== malformed payloads ===\n');
bad2 = { ...
  'order_C',        '{"fmt":2,"order":"C","base":1,"vals":[1,2,3,4,5,6],"info":[{"p":[],"t":"double","d":[2,3]}]}', 'json:mloads:order'; ...
  'base_0',         '{"fmt":2,"order":"F","base":0,"vals":1,"info":[{"p":[],"t":"double","d":[1,1]}]}',            'json:mloads:base'; ...
  'fmt_string',     '{"fmt":"2","vals":1,"info":[{"p":[],"t":"double","d":[1,1]}]}',                               'json:mloads:version'; ...
  'leaf_too_short', '{"fmt":2,"vals":[1,2,3,4],"info":[{"p":[],"t":"double","d":[7,1]}]}',                         'json:mloads:shape'; ...
  'leaf_too_long',  '{"fmt":2,"vals":[1,2,3],"info":[{"p":[],"t":"double","d":[1,2]}]}',                           'json:mloads:shape'; ...
  'char_too_short', '{"fmt":2,"vals":"ab","info":[{"p":[],"t":"char","d":[2,3]}]}',                                'json:mloads:shape'; ...
  'nf_out_of_range','{"fmt":2,"vals":[1,2],"info":[{"p":[],"t":"double","d":[1,2],"nf":{"i":[9],"k":["Inf"]}}]}',   'json:mloads:nf'; ...
  'nf_bad_kind',    '{"fmt":2,"vals":[null],"info":[{"p":[],"t":"double","d":[1,1],"nf":{"i":[1],"k":["Bogus"]}}]}','json:mloads:nf'; ...
  's_not_integer',  '{"fmt":2,"vals":[1500],"info":[{"p":[],"t":"int64","d":[1,1],"s":["1.5e3"]}]}',               'json:mloads:int'; ...
  'info_too_long',  '{"fmt":2,"vals":1,"info":[{"p":[],"t":"double","d":[1,1]},{"p":[],"t":"double","d":[1,1]}]}',  'json:mloads:info'; ...
  'array_of_v1',    '[{"vals":1,"info":{}},{"vals":2,"info":{}}]',                                                 'json:mloads:unrecognised'; ...
  'string_array_in', string(["{}" "x"]),                                                                           'json:mloads:input' };
nbad2 = 0;
for k = 1:size(bad2, 1)
    got = '';
    try
        json.mloads(bad2{k, 2});
    catch me
        got = me.identifier;
    end
    if ~strcmp(got, bad2{k, 3})
        nbad2 = nbad2 + 1;
        fprintf(2, '  FAIL %-18s expected %s, got "%s"\n', bad2{k, 1}, bad2{k, 3}, got);
    end
end

% An ignored option must say so rather than silently doing nothing.
warnstate = warning('off', 'json:mdumps:thorough');
[~] = lastwarn('');
json.mdumps(1, 'thorough', false);
[~, wid] = lastwarn;
warning(warnstate);
if ~strcmp(wid, 'json:mdumps:thorough')
    nbad2 = nbad2 + 1;
    fprintf(2, '  FAIL thorough=false did not warn (got "%s")\n', wid);
end

fprintf('malformed payloads: %d/%d passed\n', size(bad2, 1) + 1 - nbad2, size(bad2, 1) + 1);
nfail = nfail + nbad2;

%% ---- compression path ------------------------------------------------
fprintf('\n=== compression ===\n');
ncomp = 0;
% Every case, not a sample: zlibencode casts char with a saturating uint8(),
% so the compressed path needs the same coverage as the plain one or a
% non-ASCII field can be clamped without anyone noticing.
ztot = 0;
for k = 1:n
    try
        v = cases{k, 2};
        z = json.mdumps(v, 'compress', true);
        assert(isa(z, 'uint8'), 'compressed output should be bytes, not text');
        ztot = ztot + numel(z);
        w = json.mloads(z);
        assert(isequaln(v, w), 'compressed round-trip mismatch');
        [ok, why] = strict_equal(v, w, '');
        assert(ok, '%s', why);
    catch me
        ncomp = ncomp + 1;
        fprintf(2, '  FAIL compression %-22s %s\n', cases{k, 1}, me.message);
    end
end
fprintf('compression: %d/%d passed (%d bytes compressed)\n', n - ncomp, n, ztot);
nfail = nfail + ncomp;

%% ---- report ---------------------------------------------------------
tot = sum([R.bytes]);
fprintf('\n=== summary ===\n');
fprintf('%d payload bytes across %d cases\n', tot, n);
if nargout > 0
    varargout{1} = R;
end
if nfail > 0
    error('test:json:failed', '%d json test failure(s)', nfail);
end
fprintf('ALL JSON TESTS PASSED\n');

end

% =========================================================================
function [tf, why] = strict_equal(a, b, path)
% Recursive class + size + field-order + value comparison. Stricter than
% isequaln, which happily equates 1 with true and int8(1) with 1, and which
% ignores the order of struct fields.

tf = false;

if ~strcmp(class(a), class(b))
    why = sprintf('%s class %s vs %s', loc(path), class(a), class(b));
    return
end
if ~isequal(size(a), size(b))
    why = sprintf('%s size %s vs %s', loc(path), mat2str(size(a)), mat2str(size(b)));
    return
end

if iscell(a)
    for k = 1:numel(a)
        [tf, why] = strict_equal(a{k}, b{k}, sprintf('%s{%d}', path, k));
        if ~tf
            return
        end
    end
    tf = true; why = '';

elseif isstruct(a)
    fa = fieldnames(a);
    fb = fieldnames(b);
    if numel(fa) ~= numel(fb) || ~all(strcmp(fa, fb))
        why = sprintf('%s field order/names [%s] vs [%s]', loc(path), ...
            strjoin(reshape(fa, 1, []), ','), strjoin(reshape(fb, 1, []), ','));
        return
    end
    for e = 1:numel(a)
        for fx = 1:numel(fa)
            [tf, why] = strict_equal(a(e).(fa{fx}), b(e).(fa{fx}), ...
                sprintf('%s(%d).%s', path, e, fa{fx}));
            if ~tf
                return
            end
        end
    end
    tf = true; why = '';

else
    % char, string, numeric, logical: same class and size already checked
    if isequaln(a, b)
        tf = true; why = '';
    else
        why = sprintf('%s values differ', loc(path));
    end
end

end

% -------------------------------------------------------------------------
function s = loc(path)
if isempty(path)
    s = '<root>';
else
    s = path;
end
end
