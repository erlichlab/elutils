function val = enforce_range(val ,minval, maxval)
% val = enfore_range(val, minval, maxval)
% ensures that the value of x is in between minval and maxval
% val, minval, maxval can be vectors or the same length or some can be scalar
	nanidx = isnan(val);
	val = min(maxval, max(minval, val));
	val(nanidx) = nan;