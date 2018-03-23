function out = mloads(jstr, varargin)
% out = mdumps(obj, ['compress'])
% function that takes a matlab object (cell array, struct, vector) and converts it into json. 
% It also creates a "sister" json object that describes the type and dimension of the "leaf" elements.  
    
    if isempty(jstr)
        out = {};
        return;
    end

    if ischar(jstr)
        decompress = false;    
    elseif char(jstr(1))=='{'
        decompress = false;
        jstr = char(jstr(:))';
    else
        decompress = true;
    end

    decompress = utils.inputordefault('decompress',decompress,varargin);

    if decompress
        jstr = char(utils.zlibdecode(jstr));
    end

    jstr = regexprep(jstr, '\<NaN\>', 'null');
    try 
        bigJ = jsondecode(jstr);
        builtin_flag = true;
    catch
        bigJ = json.fromjson(jstr);
        builtin_flag = false;
    end

    out = bigJ.vals;
    meta = bigJ.info;

    if builtin_flag
        out = applyinfo_bi(out, meta);
    else
        out = applyinfo(out, meta);
    end
end

function vals = applyinfo(vals, meta)
    
    if isfield(meta,'type__')
        % Then we are a leaf node
        tsize =double([meta.dim__{1} meta.dim__{2}]);
        tnumel = prod(tsize);
        switch(meta.type__)
        case {'cell', 'struct'}
            for cx = 1:tnumel
                vals{cx} = applyinfo(vals{cx}, meta.cell__{cx});
            end
            if strcmp(meta.type__, 'struct') % This is a struct array
                vals = [vals{:}];
            end
            vals = reshape(vals, tsize);
            
        case 'char'
            vals = char(vals);
        case 'double'
            if tnumel == 1
                vals = double(vals);
            else
                vals = double([vals{:}]);
                vals = reshape(vals, tsize);
            end
        otherwise
            f = @(x) cast(x, meta.type__);
            if tnumel == 1 || strcmp(meta.type__, 'char')
                vals = f(vals);
            else
                 vals = cellfun(f, vals);
              %  vals = cell2mat(vals);
                 vals = reshape(vals, tsize);
            end

        end
    else
        fnames = fieldnames(meta);
        for fx = 1:numel(fnames)
            vals.(fnames{fx}) = applyinfo(vals.(fnames{fx}), meta.(fnames{fx}));
        end 
    end
end


function vals = applyinfo_bi(vals, meta)
    if iscell(meta)
        meta = meta{1};
    end
    if isfield(meta,'type__')
        % Then we are a leaf node
        tsize =meta.dim__(:)';
        tnumel = prod(tsize);
        switch(meta.type__)
        case {'cell', 'struct'}
            newvals=cell(tnumel,1);
            for cx = 1:tnumel
                if iscell(vals)
                    newvals{cx} = applyinfo_bi(vals{cx}, meta.cell__(cx));
                else
                    newvals{cx} = applyinfo_bi(vals(cx), meta.cell__(cx));
                end
            end
            
            if strcmp(meta.type__, 'struct') % This is a struct array
                newvals = [newvals{:}];
            end
            vals = reshape(newvals, tsize);
            
        case 'char'
            vals = char(vals);
        case 'double'
              vals = reshape(vals, tsize);  
        otherwise
            f = @(x) cast(x, meta.type__);
            if tnumel == 1 || strcmp(meta.type__, 'char')
                vals = f(vals);
            else
                 vals = cellfun(f, vals);
              %  vals = cell2mat(vals);
                 vals = reshape(vals, tsize);
            end

        end
    else
        fnames = fieldnames(meta);
        for fx = 1:numel(fnames)
            vals.(fnames{fx}) = applyinfo_bi(vals.(fnames{fx}), meta.(fnames{fx}));
        end 
    end
end

