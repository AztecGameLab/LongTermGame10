class_name RNG

## Returns a normally-distributed random integer between [min] and [max],
## biased by [percent_bias] (-1.0 = guaranteed min, 0.0 = centered, 1.0 = guaranteed max).
static func curve_with_bias(minimum: int, maximum: int, bias: float = 0.0) -> int:
	bias = clampf(bias, -1.0, 1.0)
	var midpoint := (minimum + maximum) / 2.0
	var spread := (maximum - minimum) / 6.0
	var mean := lerpf(midpoint, float(maximum), bias)
	var deviation := lerpf(spread, 0.0, absf(bias))
	return clampi(roundi(randfn(mean, deviation)), minimum, maximum)


## Returns true with the given probability, which can be modified by status effects.[br]
## [bias] is a value between -1.0 and 1.0 that biases the roll towards false or true, respectively.
static func binary_with_bias(bias: float = 0.0) -> bool:
	return curve_with_bias(0, 1, bias) == 1
