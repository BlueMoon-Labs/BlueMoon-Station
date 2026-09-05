/// Produces a mutable appearance glued to the [EMISSIVE_PLANE] dyed to be the [EMISSIVE_COLOR].
/proc/emissive_appearance(icon, icon_state = "", layer = FLOAT_LAYER, alpha = 255, appearance_flags = NONE, atom/offset_spokesman)
	var/mutable_appearance/appearance = mutable_appearance(icon, icon_state, layer, EMISSIVE_PLANE, alpha, appearance_flags)
	appearance.color = GLOB.emissive_color
	if(offset_spokesman)
		SET_PLANE_EXPLICIT(appearance, EMISSIVE_PLANE, offset_spokesman)
	else if(SSmapping.max_plane_offset)
		stack_trace("emissive_appearance([icon], \"[icon_state]\") без offset_spokesman на карте со стопкой этажей: свечение ляжет на этаж 0 и прорежет его маску света")
	return appearance

/proc/blend_cutoff_colors(list/first_color, list/second_color)
	ASSERT(first_color?.len == 3)
	ASSERT(second_color?.len == 3)

	var/list/output = new /list(3)

	for(var/i in 1 to 3)
		output[i] = (1 - (1 - first_color[i] / 100) * (1 - second_color[i] / 100)) * 100

	return output
