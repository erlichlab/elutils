function var = constrain_var(var, low, high)

if var < low
	var = low;
end

if var > high
	var = high;
end