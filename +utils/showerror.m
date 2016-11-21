
function out = showerror(le)
if nargin==0
    le=lasterror;
end

if nargout > 0
    out = sprintf('\n%s \n%s\n',le.identifier, le.message);
    for xi=1:numel(le.stack)
        out = sprintf('%s On line %i of %s\n',out, le.stack(xi).line, le.stack(xi).file);
    end
else
    fprintf(1,'\n%s \n%s\n',le.identifier, le.message);
    for xi=1:numel(le.stack)
        fprintf(1,'On line %i of %s\n',le.stack(xi).line, le.stack(xi).file);
    end
end
