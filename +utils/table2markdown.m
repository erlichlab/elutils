function out = table2markdown(tab)

if ~istable(tab)
   error('Input needs to be a table') 
end

head = tab.Properties.VariableNames;
if isempty(tab.Properties.RowNames)
    out{1} = sprintf('%s |', sprintf('| %s ',head{:}));
else
    out{1} = sprintf('%s |', sprintf('| %s ',head{:}));    
end

out{2} = repmat('-',1,20);
col_type = cell(1,width(tab));

for hx = 1:height(tab)

    for cx = 1:width(tab)
    if hx == 1
        col_type{cx} = class(tab{hx,cx});
    end

    switch col_type{cx}
        case '
end