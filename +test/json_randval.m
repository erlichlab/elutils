function v = json_randval(depth)
% v = test.json_randval([depth])
%
% Generate a random MATLAB value drawn from everything json.mdumps supports:
% nested cells, structs and struct arrays down to DEPTH levels, with leaves of
% every supported class, awkward shapes (N-D, empty, 0xN) and non-finite values.
%
% Used by test.test_json for property-based round-trip testing, which is what
% catches the combinations nobody thought to write down. Seed the generator
% yourself so a failure is reproducible:
%
%   rng(1234); s = test.json_randval(3);       % replay exactly this value
%
% See also test.test_json

if nargin < 1
    depth = 3;
end

if depth <= 0
    v = rand_leaf();
    return
end

switch randi(10)
    case {1, 2, 3, 4}
        v = rand_leaf();

    case {5, 6}
        d = rand_dims();
        n = prod(d);
        if n > 1 && rand < 0.35
            c = rand_similar_siblings(n, depth - 1);
        else
            c = cell(1, n);
            for k = 1:n
                c{k} = test.json_randval(depth - 1);
            end
        end
        v = reshape(c, d);

    case {7, 8}
        f = rand_fields();
        v = struct();
        for k = 1:numel(f)
            v.(f{k}) = test.json_randval(depth - 1);
        end

    case 9
        v = make_struct_array(rand_fields(), rand_dims(), depth - 1);

    case 10
        v = rand_leaf();
end

end

% -------------------------------------------------------------------------
function c = rand_similar_siblings(n, depth)
% Siblings drawn from ONE template, because that is what makes jsondecode
% collapse a JSON array of arrays into a single N-D block: equal-length struct
% arrays with matching fields become one struct array, equal-length numeric
% arrays one numeric block. Independent draws produce that shape roughly once
% in a thousand values, which is too rare for a fuzzer to rely on, so generate
% it on purpose.
c    = cell(1, n);
f    = rand_fields();
dd   = rand_dims();
m    = prod(dd);
kind = randi(3);
for k = 1:n
    switch kind
        case 1
            c{k} = make_struct_array(f, dd, depth);
        case 2
            inner = cell(1, m);
            for q = 1:m
                inner{q} = test.json_randval(max(depth - 1, 0));
            end
            c{k} = reshape(inner, dd);
        case 3
            c{k} = reshape(randn(1, m), dd);
    end
end
end

% -------------------------------------------------------------------------
function v = make_struct_array(f, d, depth)
% Every element carries the same fields in the same order, which is what
% [elems{:}] below requires.
n = prod(d);
if n == 0
    if isempty(f)
        v = reshape(struct([]), d);
        return
    end
    args = cell(1, 2 * numel(f));
    for k = 1:numel(f)
        args{2 * k - 1} = f{k};
        args{2 * k}     = {};
    end
    v = reshape(struct(args{:}), d);
    return
end
elems = cell(1, n);
for k = 1:n
    e = struct();
    for fx = 1:numel(f)
        e.(f{fx}) = test.json_randval(depth);
    end
    elems{k} = e;
end
v = reshape([elems{:}], d);
end

% -------------------------------------------------------------------------
function d = rand_dims()
% Shapes worth exercising, including the empty and N-D ones that break naive
% reshape logic.
switch randi(9)
    case 1, d = [1 1];
    case 2, d = [1 randi(4)];
    case 3, d = [randi(4) 1];
    case 4, d = [2 3];
    case 5, d = [3 2];
    case 6, d = [2 2 2];
    case 7, d = [0 0];
    case 8, d = [0 3];
    case 9, d = [1 5];
end
end

% -------------------------------------------------------------------------
function f = rand_fields()
% Mostly a two-name pool, so sibling struct arrays can actually end up with
% the same field set AND the same length -- the shape that makes jsondecode
% collapse them into one N-D struct array. Drawing from ten names instead made
% a collision so unlikely the fuzzer never reached that path.
%
% The wider pool still appears sometimes; it carries type__ and dim__, which
% were metadata sentinels in v1 and must survive as ordinary field names.
if rand < 0.8
    pool = {'a', 'b'};
else
    pool = {'a', 'b', 'c', 'x1', 'value', 'type__', 'dim__', 'data', 'meta', 'n'};
end
k = min(randi(4) - 1, numel(pool));   % 0..3 fields; 0 is the fieldless struct
f = pool(randperm(numel(pool), k));
end

% -------------------------------------------------------------------------
function v = rand_leaf()
classes = {'double', 'single', 'logical', 'char', 'string', ...
           'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
           'int64', 'uint64'};
cls = classes{randi(numel(classes))};
d   = rand_dims();
n   = prod(d);

switch cls
    case 'char'
        pool = ['a':'z' 'A':'Z' '0':'9' ' ' '"' '\' '{' '}' ':'];
        v = reshape(pool(randi(numel(pool), 1, n)), d);

    case 'string'
        words = {'', 'a', 'bb', 'NaN', 'café', 'has space', '{"json":1}'};
        v = reshape(string(words(randi(numel(words), 1, n))), d);

    case 'logical'
        v = reshape(rand(1, n) > 0.5, d);

    case {'double', 'single'}
        x = randn(1, n);
        % sprinkle non-finites: they encode as null and need the nf sidecar
        if n > 0 && rand < 0.4
            nbad = randi(n);
            pick = randperm(n, nbad);
            vals = [NaN Inf -Inf];
            x(pick) = vals(randi(3, 1, nbad));
        end
        v = reshape(cast(x, cls), d);

    otherwise
        % integers: span the class range, and push 64-bit ones past 2^53 where
        % a JSON number read back through a double would lose precision
        lo = double(intmin(cls));
        hi = double(intmax(cls));
        if any(strcmp(cls, {'int64', 'uint64'})) && rand < 0.5
            x = cast(rand(1, n) * hi, cls);
            if strcmp(cls, 'int64')
                x = x + intmax('int64') / 2;   % saturating, deliberately near the top
            end
        else
            x = cast(lo + rand(1, n) * (hi - lo), cls);
        end
        v = reshape(x, d);
end

end
