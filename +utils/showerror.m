
function showerror(le)
if nargin==0
    le=lasterror;
end

fprintf(1,'\n%s \n%s\n',le.identifier, le.message);
for xi=1:numel(le.stack)
	fprintf(1,'On line %i of %s\n',le.stack(xi).line, le.stack(xi).file);
end