function [out, inps] = inputordefault(keyname, defval, inps)
% [out, leftover] = inputordefault(keyname, defval, inps)
% Parses a cell array (usually varargin) looking for a string which matches 
% the keyname and then assigns out to the value of the next element of the
 % input if it finds it otherwise assignes it to the default value.
 % E.g. sessid = inputordefault('sessid', 0, varargin)
% Can also be called on the leftovers to check that there were no missing arguments.
% Can also be called to convert a struct into a list of 
 if nargin==1
	if isstruct(keyname)
		% convert to name, value
		fn = fieldnames(keyname);
		out = cell(1,2*numel(fn));
		for fx = 1:numel(fn)
			out{2*fx-1} = fn{fx};
			out{2*fx} = keyname.(fn{fx});
		end

		return
	end
	if ~isempty(keyname)
		warning('You have unused keyword arguments')
		for argx = 1:2:numel(keyname)
			fprintf(2,'%s: %s\n', keyname{argx},keyname{argx+1});
		end
	end
 else
    out = defval;
    for ox = 1:2:numel(inps)
        if strcmpi(keyname, inps{ox})
            out = inps{ox+1};
    		inps(ox:ox+1) = [];  % erase these from the list.
	        break
        end
    end
end
