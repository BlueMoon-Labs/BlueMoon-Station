
#define LUM_R 0.3086
#define LUM_G 0.6094
#define LUM_B 0.0820

/datum/color_matrix
	var/list/matrix

/datum/color_matrix/New(value, contrast = 1, brightness = null)
	..()
	if(istext(value))
		set_color(value, contrast, brightness)
	else if(isnum(value))
		set_saturation(value, contrast, brightness)
	else
		matrix = value

/datum/color_matrix/proc/reset()
	matrix = list(1, 0, 0,
				0, 1, 0,
				0, 0, 1)

/datum/color_matrix/proc/get(contrast = 1)
	var/list/mat = matrix
	mat = mat.Copy()
	for(var/i = 1 to min(length(mat), 12))
		mat[i] *= contrast
	return mat

/datum/color_matrix/proc/set_saturation(saturation, contrast = 1, brightness = null)
	var/r_adjustment = (1 - saturation) * LUM_R
	var/g_adjustment = (1 - saturation) * LUM_G
	var/b_adjustment = (1 - saturation) * LUM_B
	matrix = list(contrast * (r_adjustment + saturation),	contrast * (r_adjustment),				contrast * (r_adjustment),
				contrast * (g_adjustment),				contrast * (g_adjustment + saturation),	contrast * (g_adjustment),
				contrast * (b_adjustment),				contrast * (b_adjustment),				contrast * (b_adjustment + saturation))
	set_brightness(brightness)

/datum/color_matrix/proc/set_brightness(brightness)
	if(isnull(brightness))
		return
	if(!matrix)
		reset()
	var/matrix_length = length(matrix)
	if(matrix_length == 9)
		matrix += list(brightness, brightness, brightness)
		return
	if(matrix_length == 16)
		matrix += list(brightness, brightness, brightness, 0)
		return
	if(matrix_length == 12)
		for(var/i = matrix_length to matrix_length - 2 step -1)
			matrix[i] = brightness
		return
	if(matrix_length == 3)
		for(var/i = 1 to matrix_length)
			matrix[i] = brightness
		return
	CRASH("Couldn't figure out how to apply brightness to a matrix of length: [matrix_length]")

/datum/color_matrix/proc/hex2value(hex)
	var/const/radix = 16
	var/num1 = text2num(hex[1], radix)
	var/num2 = text2num(hex[2], radix)
	if(!isnum(num1) || !isnum(num2))
		CRASH("Invalid hex value: [hex]")
	return num1 * radix + num2

/datum/color_matrix/proc/set_color(color_hex, contrast = 1, brightness = null)
	var/rr = hex2value(copytext(color_hex, 2, 4)) / 255
	var/gg = hex2value(copytext(color_hex, 4, 6)) / 255
	var/bb = hex2value(copytext(color_hex, 6, 8)) / 255
	rr = round(rr * 1000) / 1000 * contrast
	gg = round(gg * 1000) / 1000 * contrast
	bb = round(bb * 1000) / 1000 * contrast
	matrix = list(rr, gg, bb,
				rr, gg, bb,
				rr, gg, bb)
	set_brightness(brightness)

#undef LUM_R
#undef LUM_G
#undef LUM_B
