function out = remove_nan_struct_fields(struct_input)
    names = fieldnames(struct_input);
    for ii = 1:numel(names)
        if isnan(struct_input.(names{ii}))
            struct_input = rmfield(struct_input,names{ii});
        end
    end
    out = struct_input;
end


