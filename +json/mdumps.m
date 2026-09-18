function out = mdumps(obj, varargin)
% out = json.mdumps(obj, ['compress', true])
%
% Serialise a MATLAB value (struct, cell, array, char, string, ...) to a JSON
% string that json.mloads can turn back into the *identical* MATLAB value,
% including class, dimensionality and non-finite values.
%
%   A.foo = 1;
%   A.bar.t = rand(10);
%   A.nerf = 1:10;
%   s = json.mdumps(A);          % valid JSON
%   B = json.mloads(s);
%   isequaln(A, B)               % true
%
% The emitted JSON has the shape
%
%   {"fmt":2, "order":"F", "base":1, "vals": <data>, "info": [<entry>, ...]}
%
% "vals" is plain, idiomatic JSON -- a reader in Python/R/Julia can ignore
% "info" entirely and still get sensible data out.  "info" is a *flat* list
% of {path, class, dims} records that lets a reader rebuild the exact MATLAB
% value.  See +json/FORMAT.md for the full specification and
% +json/readers/ for reference decoders in Python, Julia and R.
%
% OPTIONS
%   compress   (false) zlib-compress the output via utils.zlibencode.  The
%              result is a uint8 vector, NOT text -- base64 it before putting
%              it in a TEXT column.
%
% SUPPORTED CLASSES
%   double single int8..int64 uint8..uint64 logical char string cell struct
%   Other classdef objects are stored as their struct() contents with the
%   original class name recorded; they come back as plain structs.
%
% NOT SUPPORTED (raises an error rather than silently corrupting data)
%   complex, sparse, function_handle, datetime, duration, categorical,
%   table, timetable, containers.Map, dictionary, <missing> strings.
%
% See also json.mloads, json.mloads_v1

inpd = @utils.inputordefault;
args = varargin;
[compress, args] = inpd('compress', false, args);
[~, args]        = inpd('thorough', true, args);   % v1 option, now always on
if ~isempty(args)
    % A mistyped option that silently does nothing is how you end up trusting
    % an uncompressed blob you thought was compressed.
    error('json:mdumps:unknownoption', 'Unknown option(s): %s', ...
        strjoin(cellfun(@(x) char(string(x)), args(1:2:end), 'UniformOutput', false), ', '));
end

[vals, info] = enc_node(obj, {});

TO = struct();
TO.fmt   = 2;
TO.order = 'F';   % leaves are flattened column-major
TO.base  = 1;     % info paths use 1-based indices
TO.vals  = vals;
TO.info  = info;

out = jsonencode(TO);

if compress
    out = utils.zlibencode(out);
end

end

% =========================================================================
function [v, info] = enc_node(S, path)
% Encode one node. Returns the JSON-ready MATLAB value V and a 1xN cell of
% info entries in pre-order (this node first, then its descendants).

cls = class(S);
d   = size(S);

if isnumeric(S) && ~isreal(S)
    error('json:mdumps:complex', ...
        'Complex values are not supported (at %s). Split into real/imag parts.', pstr(path));
end
if issparse(S)
    error('json:mdumps:sparse', ...
        'Sparse arrays are not supported (at %s). Use full().', pstr(path));
end

switch cls
    case 'cell'
        e = entry(path, 'cell', d);
        n = numel(S);
        Sc = reshape(S, 1, max(n, 0));
        kids = cell(1, n);
        kidinfo = cell(1, n);
        for k = 1:n
            [kids{k}, kidinfo{k}] = enc_node(Sc{k}, [path, {k}]);
        end
        if n == 0
            v = [];
        else
            v = kids;
        end
        info = [{e}, kidinfo{:}];

    case 'struct'
        f = reshape(fieldnames(S), 1, []);
        e = entry(path, 'struct', d);
        e.f = f;                      % pins field order, and recovers fields of 0x0 structs
        n = numel(S);
        if n == 1
            v = struct();
            kidinfo = cell(1, numel(f));
            for fx = 1:numel(f)
                [fv, kidinfo{fx}] = enc_node(S.(f{fx}), [path, f(fx)]);
                v.(f{fx}) = fv;
            end
            info = [{e}, kidinfo{:}];
        else
            Sc = reshape(S, 1, max(n, 0));
            kids = cell(1, n);
            kidinfo = cell(1, n * numel(f));
            c = 0;
            for k = 1:n
                vk = struct();
                for fx = 1:numel(f)
                    [fv, ci] = enc_node(Sc(k).(f{fx}), [path, {k}, f(fx)]);
                    vk.(f{fx}) = fv;
                    c = c + 1;
                    kidinfo{c} = ci;
                end
                kids{k} = vk;
            end
            if n == 0
                v = [];
            else
                v = kids;
            end
            info = [{e}, kidinfo{1:c}];
        end

    case 'char'
        e = entry(path, 'char', d);
        % Column-major flatten, emitted as a single JSON string. For the
        % common 1xN case this is just "the string".
        v = reshape(S, 1, numel(S));
        if isempty(S)
            v = '';
        end
        info = {e};

    case 'string'
        if any(ismissing(S(:)))
            error('json:mdumps:missing', ...
                '<missing> string values are not supported (at %s).', pstr(path));
        end
        e = entry(path, 'string', d);
        if isempty(S)
            v = [];
        else
            v = reshape(cellstr(S(:)), 1, []);   % cell of char -> JSON array of strings
        end
        info = {e};

    case {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
          'int32', 'uint32', 'int64', 'uint64', 'logical'}
        e = entry(path, cls, d);
        x = S(:);

        if isfloat(S)
            bad = find(~isfinite(x));
            if ~isempty(bad)
                % jsonencode writes null for NaN, Inf and -Inf alike, so record
                % which is which. Index is 1-based linear, column-major.
                kinds = cell(1, numel(bad));
                for k = 1:numel(bad)
                    xv = x(bad(k));
                    if isnan(xv)
                        kinds{k} = 'NaN';
                    elseif xv > 0
                        kinds{k} = 'Inf';
                    else
                        kinds{k} = '-Inf';
                    end
                end
                e.nf = struct('i', reshape(double(bad), 1, []), 'k', {kinds});
            end
        end

        if any(strcmp(cls, {'int64', 'uint64'})) && ~isempty(x)
            % A JSON number is read back through double by jsondecode, which
            % loses integers above 2^53. Carry exact decimal strings too.
            if any(x > 9007199254740992) || any(x < -9007199254740992)
                % '%d' silently degrades to '%e' for uint64 values above
                % flintmax, so pick the specifier that stays exact.
                if isa(S, 'uint64')
                    fs = '%u';
                else
                    fs = '%d';
                end
                e.s = reshape(arrayfun(@(y) sprintf(fs, y), x, ...
                    'UniformOutput', false), 1, []);
            end
        end

        if isempty(x)
            v = [];
        else
            v = x;
        end
        info = {e};

    otherwise
        deny = {'function_handle', 'datetime', 'duration', 'calendarDuration', ...
                'categorical', 'table', 'timetable', 'containers.Map', 'dictionary'};
        if any(cellfun(@(c) isa(S, c), deny))
            error('json:mdumps:unsupported', ...
                'Class %s is not supported by json.mdumps (at %s).', cls, pstr(path));
        end
        if isobject(S)
            w = warning('off', 'MATLAB:structOnObject');
            try
                W = struct(S);
            catch me
                warning(w);
                error('json:mdumps:unsupported', ...
                    'Cannot convert object of class %s to a struct (at %s): %s', ...
                    cls, pstr(path), me.message);
            end
            warning(w);
            [v, info] = enc_node(W, path);
            info{1}.t  = cls;        % remember what it really was
            info{1}.as = 'struct';   % ... and how it is stored
            return
        end
        error('json:mdumps:unsupported', ...
            'Do not know how to handle data of class %s (at %s).', cls, pstr(path));
end

end

% =========================================================================
function e = entry(path, t, d)
e = struct();
e.p = path;                            % cell of char (field) / double (index)
e.t = t;
e.d = reshape(double(d), 1, []);
if isempty(path)
    e.p = {};
end
end

% -------------------------------------------------------------------------
function s = pstr(path)
% Human-readable path, for error messages.
if isempty(path)
    s = '<root>';
    return
end
parts = cell(1, numel(path));
for k = 1:numel(path)
    if ischar(path{k})
        parts{k} = ['.' path{k}];
    else
        parts{k} = sprintf('{%d}', path{k});
    end
end
s = ['<root>' strjoin(parts, '')];
end
