function out = rm_from_list(carr, target)
% list = rm_from_list(list, item)
% Finds the string item in the list and removes it.
    if isempty(target)
        out = carr;
        return
    end
    cind = strcmp(target, carr);
    out = carr;
    out(cind) = [];
end