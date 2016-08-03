function S = apply_struct(S, newS)
% S = apply_struct(S, newS)
% Give a "parent struct" and then apply a new struct that
% overwrites matching elements of the old struct and adds 
% elements missing from the old struct.
% see also diff_struct

if isempty(newS)
	return;
end


if iscell(newS)
	for cx = 1:numel(newS)
		S = utils.apply_struct(S, newS{cx});
	end
elseif isstruct(newS) && numel(newS)==1
	fname = fieldnames(newS);
    oldfname = fieldnames(S);
	for fx = 1:numel(fname)
		if isstruct(newS.(fname{fx}))
			if numel(newS.(fname{fx}))>1
				error('Cannot apply struct arrays')
			end
            if ~any(strcmp(fname{fx}, oldfname))
                S.(fname{fx}) = struct();
            end
			S.(fname{fx}) = utils.apply_struct(S.(fname{fx}), newS.(fname{fx}));
		else
			S.(fname{fx}) = newS.(fname{fx});
		end
	end
elseif isstruct(newS) && numel(newS) > 1
	fprintf(2,'Cannot process struct arrays type %s ', class(newS));
else
	fprintf(2,'Cannot process this type %s ', class(newS));
end
