function outfile = gen_reader_testdata(varargin)
% outfile = test.gen_reader_testdata(['outfile', path])
%
% Write the payloads that the Python/Julia/R readers in +json/readers are
% tested against. Run this after any change to the wire format:
%
%   >> test.gen_reader_testdata
%
% Emits one record per value in test.json_cases with the format-2 payload and
% the root node's class and dims, so a reader in another language can check
% what it rebuilt without needing MATLAB. The payloads are generated rather
% than committed by hand so they can never drift from json.mdumps.

inpd = @utils.inputordefault;
args = varargin;
here = fileparts(fileparts(mfilename('fullpath')));
[outfile, args] = inpd('outfile', fullfile(here, '+json', 'readers', 'testdata.json'), args);
if ~isempty(args)
    error('test:gen_reader_testdata:unknownoption', 'Unknown option(s)');
end

cases = test.json_cases();
recs  = cell(1, size(cases, 1));

for k = 1:size(cases, 1)
    v = cases{k, 2};
    recs{k} = struct( ...
        'name',    cases{k, 1}, ...
        'class',   class(v), ...
        'dims',    reshape(double(size(v)), 1, []), ...
        'payload', json.mdumps(v));
end

doc = struct('generated_by', 'test.gen_reader_testdata', 'fmt', 2, 'cases', {recs});
fid = fopen(outfile, 'w');
if fid < 0
    error('test:gen_reader_testdata:io', 'Cannot write %s', outfile);
end
fprintf(fid, '%s\n', jsonencode(doc));
fclose(fid);

fprintf('wrote %d payloads to %s\n', numel(recs), outfile);

end
