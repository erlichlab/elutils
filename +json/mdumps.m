function out = mdumps(obj, varargin)
% out = mdumps(obj, ['compress'])
% function that takes a matlab object (cell array, struct, vector) and converts it into json. 
% It also creates a "sister" json object that describes the type and dimension of the "leaf" elements.  
% Warning: Simple cell arrays (e.g. cell-arrays of strings or scalar numbers) are supported. However, cell arrays of more complex types (cell-arrays, structs, matrices)
% Note: complex numbers should be converted into 2-vectors 

if isempty(obj)
    out = [];
    return;
end

compress = false; 
thorough = true;

utils.overridedefaults(who, varargin);

if thorough
    [meta, obj] = get_info_flatten_thorough(obj);
else
    [meta, obj] = get_info_flatten(obj);
end

TO.vals = obj;
TO.info = meta;

try
    out = jsonencode(TO);
catch
    out = json.tojson(TO);
end


if compress
    out = utils.zlibencode(out);
end

end



function [M, S] = get_info_flatten(S)
    if isnumeric(S) || ischar(S) || islogical(S) || iscell(S)
        [M.type__, M.dim__] = getleafinfo(S);
        S = S(:);
    elseif isstruct(S) && numel(S)==1
        fnames = fieldnames(S);
        for fx = 1:numel(fnames)
            [M.(fnames{fx}), S.(fnames{fx})] = get_info_flatten(S.(fnames{fx}));
        end
    elseif isstruct(S) % and numel is > 1, this is a struct array
        [M.type__, M.dim__] = getleafinfo(S);
        S = arrayfun(@(x){x},S); % Convert to cell array of struct
        S = S(:);

    elseif isobject(S)
        S = struct(S);
        [M.type__, M.dim__] = getleafinfo(S);
        S = arrayfun(@(x){x},S); % Convert to cell array of struct
        S = S(:);
    else
        [M.type__, M.dim__] = getleafinfo(S);
        error('json:mdumps','Do not know how to handle data of type %s', M.type)
    end
end


function [M, S] = get_info_flatten_thorough(S)
    if isnumeric(S) || ischar(S) || islogical(S) 
        [M.type__, M.dim__] = getleafinfo(S);
        S = S(:);
    elseif isstruct(S) && numel(S)==1
        fnames = fieldnames(S);
        for fx = 1:numel(fnames)
            [M.(fnames{fx}), S.(fnames{fx})] = get_info_flatten_thorough(S.(fnames{fx}));
        end
    elseif iscell(S) || isstruct(S)
        [M.type__, M.dim__] = getleafinfo(S);
        if isstruct(S)
            S = arrayfun(@(x){x},S);
        end
        S = S(:);
        for cx = 1:numel(S)
            [M.cell__{cx}, S{cx}] =  get_info_flatten_thorough(S{cx});
        end
    else
        [M.type__, M.dim__] = getleafinfo(S);
        error('json:mdumps','Do not know how to handle data of type %s', M.type)
    end
end



function [ttype, tsize] = getleafinfo(leaf)
    ttype = class(leaf);
    tsize = size(leaf);
end

