function out = mloads(jstr, varargin)
% out = mdumps(obj, ['compress'])
% function that takes a matlab object (cell array, struct, vector) and converts it into json. 
% It also creates a "sister" json object that describes the type and dimension of the "leaf" elements.  
    if ischar(jstr)
        decompress = false;
    else
        decompress = true;
    end

    utils.overridedefaults(who, varargin);

    if decompress
        jstr = char(utils.zlibdecode(jstr));
    end

    if which('json.fromjson')
        bigJ = json.fromjson(jstr);
    else
        bigJ = loadjson('',jstr);
    end

    out = bigJ.vals;
    meta = bigJ.info;

    out = applyinfo(out, meta);

end

function vals = applyinfo(vals, meta)
    
    if isfield(meta,'type__')
        % Then we are a leaf node
        tsize = cell2mat(meta.dim__)';
        tnumel = prod(tsize);
        switch(meta.type__)
        case 'cell'
            for cx = 1:tnumel
                vals{cx} = applyinfo(vals{cx}, meta.cell__{cx});
            end
            vals = reshape(vals, tsize);
        otherwise
            if tnumel > 1 && ~ischar(vals)
                vals = cell2mat(vals);
            end
            vals = cast(vals, meta.type__);
            vals = reshape(vals, tsize);
        end
    else
        fnames = fieldnames(meta);
        for fx = 1:numel(fnames)
            vals.(fnames{fx}) = applyinfo(vals.(fnames{fx}), meta.(fnames{fx}));
        end 
    end
end


