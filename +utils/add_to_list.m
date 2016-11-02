function out = add_to_list(carr, target, pos)
% list = add_to_list(list, item, pos)
% Adds the string item to the input list (cell array of strings) at position pos

    % Check if item is in array
    cind = strcmp(target, carr);
    out = carr;
    if any(cind)
        out(cind) = [];
    end 
    out = [carr(1:pos-1) target carr(pos+1:end)];
    
end