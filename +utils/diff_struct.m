function diffS = diff_struct(oldS, newS)
% S = apply_struct(S, newS)
% Give a "parent struct" and then apply a new struct that
% overwrites matching elements of the old struct and adds 
% elements missing from the old struct.
% see also diff_struct


if iscell(newS)
	for cx = 1:numel(newS)
		S = utils.apply_struct(S, newS{cx});
	end
else
	fname = fieldnames(newS);
    oldfname = fieldnames(S);
	for fx = 1:numel(fname)
		if isstruct(newS.(fname{fx}))
            if ~any(strcmp(fname{fx}, oldfname))
                S.(fname{fx}) = struct();
            end
			S.(fname{fx}) = utils.apply_struct(S.(fname{fx}), newS.(fname{fx}));
		else
			S.(fname{fx}) = newS.(fname{fx});
		end
	end
end
