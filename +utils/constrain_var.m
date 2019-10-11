function var = constrain_var(var, low, high)

assert(high>=low,'In contrain_var the upper limit must be greater than (or equal to) the lower limit');

var(var<low)=low;
var(var>high)=high;