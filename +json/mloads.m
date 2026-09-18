function out = mloads(jstr, varargin)
% out = json.mloads(jstr, ['decompress', tf])
%
% Rebuild a MATLAB value from JSON written by json.mdumps.
%
%   s = json.mdumps(A);
%   B = json.mloads(s);
%   isequaln(A, B)     % true
%
% Reads both format 2 (current, see +json/FORMAT.md) and format 1 (the
% legacy {"vals":...,"info":...} payloads already in the database), choosing
% automatically. Legacy payloads are handed to json.mloads_v1 unchanged, so
% historical rows decode exactly as they always have.
%
% Decoding is jsondecode only. It accepts bare NaN / Infinity / -Infinity as
% an extension, so even the oldest rows -- written by the json.tojson mex
% before jsondecode existed -- read natively, with Inf still distinct from
% NaN. A rewrite of those literals is kept for a MATLAB old enough to reject
% them; it must stay behind the parse attempt so that a string value merely
% containing the word NaN is never rewritten.
%
% OPTIONS
%   decompress   force zlib decompression on/off. By default it is inferred:
%                char input is treated as text, a uint8 vector starting with
%                '{' as text, anything else as compressed.
%
% See also json.mdumps, json.mloads_v1

if isempty(jstr)
    out = {};
    return;
end

if ischar(jstr)
    decompress = false;
elseif isstring(jstr)
    if ~isscalar(jstr)
        error('json:mloads:input', ...
            'Expected one payload; got a %s string array.', mat2str(size(jstr)));
    end
    jstr = char(jstr);
    decompress = false;
elseif isnumeric(jstr) || islogical(jstr)
    % A byte vector is either text or a zlib blob; JSON always opens with '{'.
    decompress = char(jstr(1)) ~= '{';
    if ~decompress
        jstr = char(jstr(:))';
    end
else
    error('json:mloads:input', 'Cannot read a payload from a %s.', class(jstr));
end

[decompress, args] = utils.inputordefault('decompress', decompress, varargin);
if ~isempty(args)
    error('json:mloads:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@(x) char(string(x)), args(1:2:end), 'UniformOutput', false), ', '));
end

if decompress
    jstr = native2unicode(utils.zlibdecode(jstr), 'UTF-8');
end
jstr = reshape(jstr, 1, numel(jstr));

J = decode_json(jstr);

if isstruct(J) && isscalar(J) && isfield(J, 'fmt') && isfield(J, 'vals') && isfield(J, 'info')
    if ~isnumeric(J.fmt) || ~isscalar(J.fmt)
        error('json:mloads:version', 'Payload has a non-numeric fmt field.');
    end
    if double(J.fmt) ~= 2
        error('json:mloads:version', ...
            'Payload declares format %g, which this json.mloads does not understand.', ...
            double(J.fmt));
    end
    check_order_base(J);
    out = build_v2(J);
elseif isstruct(J) && isscalar(J) && isfield(J, 'vals') && isfield(J, 'info')
    out = json.mloads_v1(J);
else
    error('json:mloads:unrecognised', ...
        ['Not a json.mdumps payload (decoded to a %s with no vals/info). ', ...
         'Use jsondecode directly for plain JSON.'], class(J));
end

end

% -------------------------------------------------------------------------
function check_order_base(J)
% A payload states its own flattening order and index base. Reading an
% "order":"C" payload as column-major would transpose every array in it
% without a word, so refuse anything this reader does not implement.
if isfield(J, 'order')
    ord = J.order;
    if ~ischar(ord) || ~strcmp(reshape(ord, 1, []), 'F')
        error('json:mloads:order', ...
            ['Payload declares order "%s"; this json.mloads only implements ', ...
             'column-major "F".'], char(string(ord)));
    end
end
if isfield(J, 'base')
    if ~isnumeric(J.base) || ~isscalar(J.base) || double(J.base) ~= 1
        error('json:mloads:base', ...
            ['Payload declares base %s; this json.mloads only implements ', ...
             '1-based info paths.'], char(string(J.base)));
    end
end
end

% =========================================================================
function J = decode_json(jstr)

try
    J = jsondecode(jstr);
    return
catch strict_err
end

% Rescue for the non-standard NaN / Infinity literals the pre-jsondecode mex
% encoder wrote. Current releases parse those natively, keeping Inf distinct
% from NaN, so this only fires on a MATLAB old enough to reject them.
%
% It must stay behind the strict parse. Rewriting up front would corrupt any
% string value containing the word NaN, and would flatten to null a bare
% Infinity that jsondecode can read perfectly well.
fixed = regexprep(jstr, '(-?)\<Infinity\>', 'null');
fixed = regexprep(fixed, '\<NaN\>', 'null');
try
    J = jsondecode(fixed);
    return
catch
end

error('json:mloads:invalidjson', ...
    'Cannot parse this payload as JSON.\n  jsondecode said: %s\n  payload starts: %s', ...
    strict_err.message, snippet(jstr));

end

% -------------------------------------------------------------------------
function s = snippet(jstr)
n = min(numel(jstr), 80);
s = jstr(1:n);
if numel(jstr) > n
    s = [s '...'];
end
end

% =========================================================================
function out = build_v2(J)

info = norm_info(J.info);
[out, ix] = build_node(J.vals, info, 1);

if ix ~= numel(info) + 1
    error('json:mloads:info', ...
        ['Consumed %d of %d info entries: the info list does not describe the ', ...
         'same structure as vals.'], ix - 1, numel(info));
end

end

% -------------------------------------------------------------------------
function c = norm_info(x)
% jsondecode returns the info array as a struct array when every entry has
% the same keys and as a cell of structs when they differ. This is the one
% place that difference is allowed to matter.
if iscell(x)
    c = reshape(x, 1, numel(x));
elseif isstruct(x)
    c = reshape(num2cell(x), 1, numel(x));
else
    error('json:mloads:info', 'Expected an info array, got a %s.', class(x));
end
end

% -------------------------------------------------------------------------
function [v, ix] = build_node(raw, info, ix)

if ix > numel(info)
    error('json:mloads:info', 'Ran out of info entries while rebuilding.');
end
e = info{ix};
ix = ix + 1;

d = double(e.d(:))';
if numel(d) < 2
    d = [d ones(1, 2 - numel(d))];
end
n = prod(d);

t = e.t;
if ischar(t) == 0
    error('json:mloads:info', 'info entry %d has a non-string class.', ix - 1);
end
if isfield(e, 'as') && ischar(e.as) && strcmp(e.as, 'struct')
    t = 'struct';   % a classdef object stored as its struct() contents
end

switch t
    case 'cell'
        kids = unpack(raw, n);
        v = cell(1, n);
        for k = 1:n
            [v{k}, ix] = build_node(kids{k}, info, ix);
        end
        v = reshape(v, d);

    case 'struct'
        f = tocellstr(getdef(e, 'f', {}));
        if n == 1
            v = struct();
            for fx = 1:numel(f)
                [fv, ix] = build_node(subfield(raw, f{fx}), info, ix);
                v.(f{fx}) = fv;
            end
        elseif n == 0
            if isempty(f)
                v = reshape(struct([]), d);
            else
                args = cell(1, 2 * numel(f));
                for fx = 1:numel(f)
                    args{2 * fx - 1} = f{fx};
                    args{2 * fx}     = {};
                end
                v = reshape(struct(args{:}), d);
            end
        else
            kids  = unpack(raw, n);
            elems = cell(1, n);
            for k = 1:n
                ek = struct();
                for fx = 1:numel(f)
                    [fv, ix] = build_node(subfield(kids{k}, f{fx}), info, ix);
                    ek.(f{fx}) = fv;
                end
                elems{k} = ek;
            end
            v = reshape([elems{:}], d);
        end

    case 'char'
        x = tochars(raw);
        x = reshape(x, 1, numel(x));
        check_count(numel(x), n, e, 'characters');
        v = reshape(x, d);

    case 'string'
        if n == 0
            v = reshape(strings(0, 0), d);
        else
            c = tocellstr(raw);
            check_count(numel(c), n, e, 'strings');
            v = reshape(string(c), d);
        end

    case {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
          'int32', 'uint32', 'int64', 'uint64', 'logical'}
        if isfield(e, 's') && ~isempty(e.s)
            % Exact decimal strings for 64-bit integers beyond 2^53.
            ss = tocellstr(e.s);
            check_count(numel(ss), n, e, 'info.s entries');
            v = zeros(n, 1, t);
            for q = 1:n
                v(q) = str2int(ss{q}, t, e);
            end
            v = reshape(v, d);
        else
            x = pad_nonfinite(tonum(raw), n, e);
            x = restore_nonfinite(x, e);
            v = reshape(cast(x, t), d);
        end

    otherwise
        error('json:mloads:unknownclass', ...
            'Unknown class "%s" in info entry %d.', t, ix - 1);
end

end

% -------------------------------------------------------------------------
function check_count(got, want, e, what)
if got ~= want
    error('json:mloads:shape', ...
        'Leaf at %s carries %d %s for a %d-element array.', wstr(e), got, what, want);
end
end

% -------------------------------------------------------------------------
function x = pad_nonfinite(x, n, e)
% jsonencode writes NaN, Inf and -Inf all as null, and a bare scalar null
% decodes to no elements at all -- so a numeric leaf may legitimately arrive
% short. Every missing slot must be accounted for by an nf record; anything
% else is a malformed payload rather than something to quietly pad.
if numel(x) == n
    return
end
if numel(x) > n
    error('json:mloads:shape', ...
        'Leaf at %s carries %d values for a %d-element array.', wstr(e), numel(x), n);
end
missing = (numel(x) + 1):n;
if ~all(ismember(missing, nf_index(e)))
    error('json:mloads:shape', ...
        ['Leaf at %s carries %d values for a %d-element array, and the rest are ', ...
         'not listed as non-finite.'], wstr(e), numel(x), n);
end
x = [x; nan(n - numel(x), 1)];
end

% -------------------------------------------------------------------------
function ii = nf_index(e)
ii = [];
if ~isfield(e, 'nf') || isempty(e.nf)
    return
end
nf = e.nf;
if iscell(nf)
    nf = nf{1};
end
if isstruct(nf) && isfield(nf, 'i')
    ii = double(nf.i(:))';
end
end

% -------------------------------------------------------------------------
function s = wstr(e)
% Readable node path, for error messages.
if ~isfield(e, 'p') || isempty(e.p)
    s = '<root>';
    return
end
segs = e.p;
if ~iscell(segs)
    segs = num2cell(segs);
end
parts = cell(1, numel(segs));
for k = 1:numel(segs)
    if ischar(segs{k})
        parts{k} = ['.' segs{k}];
    else
        parts{k} = sprintf('{%d}', double(segs{k}));
    end
end
s = ['<root>' strjoin(parts, '')];
end

% -------------------------------------------------------------------------
function x = restore_nonfinite(x, e)
if ~isfield(e, 'nf') || isempty(e.nf)
    return
end
nf = e.nf;
if iscell(nf)
    nf = nf{1};
end
if ~isstruct(nf) || ~isfield(nf, 'i') || ~isfield(nf, 'k')
    return
end
ii = double(nf.i(:));
kk = tocellstr(nf.k);
if numel(ii) ~= numel(kk)
    error('json:mloads:nf', ...
        'info.nf at %s has %d indices but %d kinds.', wstr(e), numel(ii), numel(kk));
end
for q = 1:numel(ii)
    if ii(q) < 1 || ii(q) > numel(x)
        error('json:mloads:nf', ...
            'info.nf at %s indexes element %g of a %d-element leaf.', ...
            wstr(e), ii(q), numel(x));
    end
    switch kk{q}
        case 'NaN'
            x(ii(q)) = NaN;
        case 'Inf'
            x(ii(q)) = Inf;
        case '-Inf'
            x(ii(q)) = -Inf;
        otherwise
            error('json:mloads:nf', ...
                'info.nf at %s has unknown kind "%s".', wstr(e), kk{q});
    end
end
end

% -------------------------------------------------------------------------
function kids = unpack(raw, n)
% Return a 1xN cell of the raw decoded blocks for a container's N elements.
%
% This is the only function that has to know about jsondecode's collapsing.
% A JSON array of N like-shaped things comes back as a struct array, a cell,
% or an N-D numeric block depending on the *data*; N comes from info, so the
% ambiguity is resolvable here rather than guessed at every level.

if n == 0
    kids = {};
    return
end

if iscell(raw) && numel(raw) == n
    kids = reshape(raw, 1, n);
elseif isstruct(raw) && numel(raw) == n
    kids = reshape(num2cell(raw), 1, n);
elseif n == 1
    kids = {raw};
elseif isnumeric(raw) || islogical(raw) || isstruct(raw)
    % jsondecode collapses a JSON array of like-shaped arrays into one N-D
    % block: a numeric block for arrays of numbers, and a struct ARRAY for
    % arrays of objects that happen to share a field set and a length. Either
    % way the outermost JSON array became dimension 1, so restoring element
    % order and splitting evenly handles both. Arrays of arrays of strings
    % never collapse, so cells need no equivalent.
    flat = jsonorder(raw);
    if isempty(flat)
        kids = repmat({[]}, 1, n);
    else
        per = numel(flat) / n;
        if per ~= fix(per)
            error('json:mloads:shape', ...
                'Cannot split %d decoded values across %d elements.', numel(flat), n);
        end
        kids = cell(1, n);
        for k = 1:n
            kids{k} = flat((k - 1) * per + 1:k * per);
        end
    end
else
    error('json:mloads:shape', ...
        'Cannot unpack %d elements from a %s of %d.', n, class(raw), numel(raw));
end

end

% -------------------------------------------------------------------------
function x = jsonorder(v)
% Flatten a decoded numeric block into JSON element order.
%
% jsondecode maps nested JSON arrays onto N-D arrays with the OUTERMOST JSON
% array as dimension 1, i.e. row-major, while MATLAB's linear index is
% column-major. Reversing the dimensions first puts the values back in the
% order they appeared in the text.
if isempty(v)
    x = reshape(v, [], 1);
    return
end
nd = max(ndims(v), 2);
x = reshape(permute(v, nd:-1:1), [], 1);
end

% -------------------------------------------------------------------------
function x = tonum(raw)
if isnumeric(raw) || islogical(raw)
    x = double(jsonorder(raw));
elseif iscell(raw)
    x = nan(numel(raw), 1);
    for k = 1:numel(raw)
        rk = raw{k};
        if isempty(rk)
            continue        % a null slot; restore_nonfinite fills it in
        end
        if ~(isnumeric(rk) || islogical(rk)) || ~isscalar(rk)
            error('json:mloads:leaf', ...
                'Numeric leaf element %d decoded to a %s of %d, not a number.', ...
                k, class(rk), numel(rk));
        end
        x(k) = double(rk);
    end
elseif isempty(raw)
    x = zeros(0, 1);
else
    error('json:mloads:leaf', 'Expected numeric leaf data, got a %s.', class(raw));
end
end

% -------------------------------------------------------------------------
function x = tochars(raw)
if ischar(raw)
    x = raw;
elseif isstring(raw) && isscalar(raw)
    x = char(raw);
elseif isempty(raw)
    x = '';
elseif iscell(raw)
    x = '';
    for k = 1:numel(raw)
        if ischar(raw{k})
            x = [x raw{k}]; %#ok<AGROW>
        end
    end
else
    error('json:mloads:leaf', 'Expected char leaf data, got a %s.', class(raw));
end
end

% -------------------------------------------------------------------------
function c = tocellstr(x)
if ischar(x)
    c = {x};
elseif iscell(x)
    c = reshape(x, 1, numel(x));
elseif isstring(x)
    c = reshape(cellstr(x), 1, numel(x));
elseif isempty(x)
    c = {};
else
    error('json:mloads:str', 'Expected a list of strings, got a %s.', class(x));
end
end

% -------------------------------------------------------------------------
function v = getdef(s, name, dflt)
if isfield(s, name)
    v = s.(name);
else
    v = dflt;
end
end

% -------------------------------------------------------------------------
function s = subfield(raw, name)
if isstruct(raw) && ~isempty(raw) && isfield(raw, name)
    s = raw(1).(name);
else
    s = [];
end
end

% -------------------------------------------------------------------------
function y = str2int(s, cls, e)
% Parse a decimal string into cls without going through double, so that
% 64-bit integers above 2^53 (and intmin) survive exactly.
raw = s;
s = strtrim(s);
neg = false;
if ~isempty(s) && s(1) == '-'
    neg = true;
    s = s(2:end);
elseif ~isempty(s) && s(1) == '+'
    s = s(2:end);
end
if isempty(s) || ~all(s >= '0' & s <= '9')
    error('json:mloads:int', ...
        'info.s at %s has "%s", which is not a decimal integer.', wstr(e), raw);
end
y   = zeros(1, 1, cls);
ten = cast(10, cls);
for k = 1:numel(s)
    dg = cast(double(s(k)) - 48, cls);
    if neg
        y = y * ten - dg;   % accumulate negatively so intmin does not overflow
    else
        y = y * ten + dg;
    end
end
end
