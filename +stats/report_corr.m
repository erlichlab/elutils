function report_corr(r, p, col_names)

if nargin == 2
    col_names = arrayfun(@(x){sprintf('Col %d', x)},1:size(r,1));
end

pairs = nchoosek(1:numel(col_names),2);
for px = 1:size(pairs,1)
    x1 = pairs(px,1);
    x2 = pairs(px,2);
    fprintf(1,'For %s vs. %s: r=%.3f, p=%.3g\n',col_names{x1},col_names{x2},r(x1,x2),p(x1,x2));
end    