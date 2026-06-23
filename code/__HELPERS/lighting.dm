/// Produces a mutable appearance glued to the [EMISSIVE_PLANE] dyed to be the [EMISSIVE_COLOR].
/proc/emissive_appearance(icon, icon_state = "", layer = FLOAT_LAYER, alpha = 255, appearance_flags = NONE)
	var/mutable_appearance/appearance = mutable_appearance(icon, icon_state, layer, EMISSIVE_PLANE, alpha, appearance_flags)
	appearance.color = GLOB.emissive_color
	return appearance

/proc/blend_cutoff_colors(list/first_color, list/second_color)
	ASSERT(first_color?.len == 3)
	ASSERT(second_color?.len == 3)

	var/list/output = new /list(3)

	for(var/i in 1 to 3)
		output[i] = (1 - (1 - first_color[i] / 100) * (1 - second_color[i] / 100)) * 100

	return output
