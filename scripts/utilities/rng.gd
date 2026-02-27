class_name RNG

## Returns a normally-distributed random integer between [min] and [max],
## biased by [percent_bias] (-1.0 = guaranteed min, 0.0 = centered, 1.0 = guaranteed max).
static func curve_with_bias(min: int, max: int, percent_bias: float = 0.0) -> int:
	percent_bias = clampf(percent_bias, -1.0, 1.0)
	var midpoint := (min + max) / 2.0
	var spread := (max - min) / 6.0
	var mean := lerpf(midpoint, float(max), percent_bias)
	var deviation := lerpf(spread, 0.0, absf(percent_bias))
	return clampi(roundi(randfn(mean, deviation)), min, max)
