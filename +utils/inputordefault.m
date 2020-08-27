function [out, inps] = inputordefault(keyname, defval, inps)
% [out, leftover] = inputordefault(keyname, defval, inps)
% Parses a cell array (usually varargin) looking for a string which matches 
% the keyname and then assigns out to the value of the next element of the
 % input if it finds it otherwise assignes it to the default value.
 % E.g. sessid = inputordefault('sessid', 0, varargin)
% Can also be called on the leftovers to check that there were no missing arguments.
 if nargin==1
	if ~isempty(keyname)
		warning('You have unused keyword arguments')
		for argx = 1:2:numel(keyname)
			fprintf(2,'%s: %s\n', keyname{argx},keyname{argx+1});
		end
	end
 else
	ind = strcmpi(keyname, inps(1:2:end));
	% is the keyname in the inputs? Look only at the odd elements of inps, since this keyname could be a value of another input.
	if any(ind)
		out = inps{2*find(ind)};
		inps(2*find(ind)-1:2*find(ind)) = [];  % erase these from the list.
	else
		out = defval;
	end
end
