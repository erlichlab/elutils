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
% Current jsondecode accepts bare NaN / Infinity / -Infinity as an extension,
% so the oldest rows -- written by json.tojson before jsondecode existed --
% read natively with Inf still distinct from NaN. A rewrite of those literals
% is kept as a fallback for stricter parsers, but it runs only when the text
% fails to parse, so a string value that merely *contains* the word NaN is no
% longer corrupted.
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
elseif isstring(jstr) && isscalar(jstr)
    jstr = char(jstr);
    decompress = false;
elseif char(jstr(1)) == '{'
    decompress = false;
    jstr = char(jstr(:))';
else
    decompress = true;
end

[decompress, args] = utils.inputordefault('decompress', decompress, varargin);
if ~isempty(args)
    error('json:mloads:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@(x) char(string(x)), args(1:2:end), 'UniformOutput', false), ', '));
end

if decompress
    jstr = char(utils.zlibdecode(jstr));
end
jstr = reshape(jstr, 1, numel(jstr));

[J, builtin_flag] = decode_any(jstr);

if isstruct(J) && isscalar(J) && isfield(J, 'fmt') && isfield(J, 'vals') && isfield(J, 'info')
    fmt = double(J.fmt);
    if fmt ~= 2
        error('json:mloads:version', ...
            'Payload declares format %g, which this json.mloads does not understand.', fmt);
    end
    out = build_v2(J);
elseif isstruct(J) && isfield(J, 'vals') && isfield(J, 'info')
    out = json.mloads_v1(J, builtin_flag);
else
    error('json:mloads:unrecognised', ...
        ['Not a json.mdumps payload (decoded to a %s with no vals/info). ', ...
         'Use jsondecode directly for plain JSON.'], class(J));
end

end

% =========================================================================
function [J, builtin_flag] = decode_any(jstr)
% Decode, preferring the built-in. Only if the text is not valid JSON do we
% rewrite non-standard NaN/Infinity literals, then fall back to the mex
% decoder. Doing the rewrite last is what keeps string payloads intact.

builtin_flag = true;

try
    J = jsondecode(jstr);
    return
catch strict_err
end

% Non-standard literals, for producers jsondecode will not take. Current
% releases accept bare NaN/Infinity/Inf (though not lowercase nan/inf), so this
% rarely fires; it is a fallback for older MATLAB and for other writers.
%
% Two reasons it runs only after a parse failure rather than up front, which is
% what v1 did: a string value containing the word NaN stays intact, and a bare
% Infinity that jsondecode would have read as Inf is not flattened to null.
fixed = regexprep(jstr, '(-?)\<Infinity\>', 'null');
fixed = regexprep(fixed, '\<NaN\>', 'null');
try
    J = jsondecode(fixed);
    return
catch
end

try
    J = json.fromjson(jstr);
    builtin_flag = false;
catch mex_err
    if strcmp(mex_err.identifier, 'MATLAB:undefinedVarOrClass')
        % No mexmaca64 is shipped, so on Apple Silicon there is no fallback.
        % Report the actual problem instead of a missing-function error.
        error('json:mloads:invalidjson', ...
            ['Cannot parse this payload as JSON, and the json.fromjson mex ' ...
             'fallback is not built for %s (this repo ships mexa64, mexmaci64, ' ...
             'mexw32 and mexw64 only).\n  jsondecode said: %s\n  payload starts: %s'], ...
            mexext, strict_err.message, snippet(jstr));
    end
    rethrow(mex_err)
end

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
    warning('json:mloads:info', ...
        'Consumed %d of %d info entries; the payload may be malformed.', ix - 1, numel(info));
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
        if numel(x) < n
            x = [x repmat(' ', 1, n - numel(x))];
        end
        v = reshape(x(1:n), d);

    case 'string'
        if n == 0
            v = reshape(strings(0, 0), d);
        else
            c = tocellstr(raw);
            if numel(c) < n
                c(numel(c) + 1:n) = {''};
            end
            v = reshape(string(c(1:n)), d);
        end

    case {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
          'int32', 'uint32', 'int64', 'uint64', 'logical'}
        if isfield(e, 's') && ~isempty(e.s)
            % Exact decimal strings for 64-bit integers beyond 2^53.
            ss = tocellstr(e.s);
            v = zeros(n, 1, t);
            for q = 1:min(n, numel(ss))
                v(q) = str2int(ss{q}, t);
            end
            v = reshape(v, d);
        else
            x = tonum(raw);
            if numel(x) < n
                x = [x; nan(n - numel(x), 1)];
            end
            x = x(1:n);
            x = restore_nonfinite(x, e);
            v = reshape(cast(x, t), d);
        end

    otherwise
        error('json:mloads:unknownclass', ...
            'Unknown class "%s" in info entry %d.', t, ix - 1);
end

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
for q = 1:min(numel(ii), numel(kk))
    if ii(q) < 1 || ii(q) > numel(x)
        continue
    end
    switch kk{q}
        case 'NaN'
            x(ii(q)) = NaN;
        case 'Inf'
            x(ii(q)) = Inf;
        case '-Inf'
            x(ii(q)) = -Inf;
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
elseif isnumeric(raw) || islogical(raw)
    flat = jsonorder(raw);
    if isempty(flat)
        kids = repmat({[]}, 1, n);
    else
        per = numel(flat) / n;
        if per ~= fix(per)
            error('json:mloads:shape', ...
                'Cannot split %d decoded values across %d elements.', numel(flat), n);
        end
        kids = reshape(num2cell(reshape(flat, per, n), 1), 1, n);
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
        if ~isempty(rk) && (isnumeric(rk) || islogical(rk))
            x(k) = double(rk(1));
        end
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
function y = str2int(s, cls)
% Parse a decimal string into cls without going through double, so that
% 64-bit integers above 2^53 (and intmin) survive exactly.
s = strtrim(s);
neg = false;
if ~isempty(s) && s(1) == '-'
    neg = true;
    s = s(2:end);
elseif ~isempty(s) && s(1) == '+'
    s = s(2:end);
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
