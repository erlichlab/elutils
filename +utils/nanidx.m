function out = nanidx(idx, A)

out = nan(size(idx));
out(~isnan(idx)) = A(idx(~isnan(idx)));