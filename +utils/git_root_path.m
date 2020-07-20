function p = git_root_path()
% path = git_root_path()
% returns the path to the root of the git repository where this is run.

[stat,out]=system('git rev-parse --show-toplevel');
if stat==0
    p = strtrim(out);
else
    error(out);
end

