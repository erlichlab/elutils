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
        c = cell(1, n);
        for k = 1:n
            c{k} = test.json_randval(depth - 1);
        end
        v = reshape(c, d);

    case {7, 8}
        f = rand_fields();
        v = struct();
        for k = 1:numel(f)
            v.(f{k}) = test.json_randval(depth - 1);
        end

    case 9
        % struct array: every element must carry the same fields in the same
        % order, which is exactly what [elems{:}] requires below
        f = rand_fields();
        d = rand_dims();
        n = prod(d);
        if n == 0
            args = cell(1, 2 * numel(f));
            for k = 1:numel(f)
                args{2 * k - 1} = f{k};
                args{2 * k}     = {};
            end
            if isempty(f)
                v = reshape(struct([]), d);
            else
                v = reshape(struct(args{:}), d);
            end
        else
            elems = cell(1, n);
            for k = 1:n
                e = struct();
                for fx = 1:numel(f)
                    e.(f{fx}) = test.json_randval(depth - 1);
                end
                elems{k} = e;
            end
            v = reshape([elems{:}], d);
        end

    case 10
        v = rand_leaf();
end

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
% Includes type__ and dim__ on purpose: they were metadata sentinels in v1 and
% a field with either name must survive.
pool = {'a', 'b', 'c', 'x1', 'value', 'type__', 'dim__', 'data', 'meta', 'n'};
k = randi(4) - 1;              % 0..3 fields; 0 exercises the fieldless struct
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
