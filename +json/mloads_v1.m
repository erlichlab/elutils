function out = mloads_v1(bigJ)
% out = json.mloads_v1(bigJ)
%
% FROZEN legacy reader for format-1 payloads -- the {"vals":..., "info":...}
% shape written by json.mdumps before 2026. It exists so that rows already
% sitting in the database keep decoding exactly as they always have.
%
% BIGJ is the payload after jsondecode, with .vals and .info.
%
% The reconstruction function below is spliced VERBATIM from the pre-v2
% json/mloads.m. Do not edit it: its job is to reproduce the old behaviour,
% bugs included. New work goes in json.mloads.
%
% json.mloads dispatches here automatically, so you only need to call this
% directly when debugging an old payload.
%
% Known limitations of format 1, all fixed in format 2 (see +json/FORMAT.md):
%   * NaN/Inf/-Inf are not distinguished and usually do not survive
%   * single and the signed integer types do not round-trip
%   * 2-D char arrays come back with the wrong shape
%   * cell-of-cell and equal-length cell-of-matrix raise errors
%   * a struct field named type__ or dim__ collides with the sentinels
%
% See also json.mloads, json.mdumps

out = applyinfo_bi(bigJ.vals, bigJ.info);

end

% =========================================================================
% ---- everything below this line is verbatim pre-v2 code -----------------
% =========================================================================

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
        case {'double','single','logical','uint64','uint8','uint16','uint32'}
            if ~isempty(vals) && prod(tsize)>1
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
            vals.(fnames{fx}) = applyinfo_bi(vals.(fnames{fx}), meta.(fnames{fx}));
        end 
    end
end

