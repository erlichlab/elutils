function diffS = diff_struct(oldS, newS)
% S = apply_struct(S, newS)
% Give a "parent struct" and then apply a new struct that
% overwrites matching elements of the old struct and adds 
% elements missing from the old struct.
% see also diff_struct


diffS = struct();
fname = fieldnames(newS);
oldfname = fieldnames(oldS);
if ~isequaln(oldS, newS)
	for fx = 1:numel(fname)
		thisfield = fname{fx};
		if ~any(strcmp(thisfield,oldfname))
			% This is a new field
			diffS.(thisfield) = newS.(thisfield);
		elseif ~isequaln(newS.(thisfield), oldS.(thisfield))
			% They are not equal
				if isstruct(newS.(thisfield)) && numel(newS.(thisfield))==1
					diffS.(thisfield) = utils.diff_struct(oldS.(thisfield), newS.(thisfield));
				elseif isstruct(newS.(thisfield)) % numel > 1
					error('Cannot diff struct arrays.')
				else
					diffS.(thisfield) = newS.(thisfield);
				end
			else
				
			end
		end
	end
end



