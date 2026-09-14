/// Produces a mutable appearance glued to the [EMISSIVE_PLANE] dyed white ([EMISSIVE_COLOR]).
/// Uses BlueMoon's single-channel white emissive convention (NOT the NovaSector 3-channel red/green/blue),
/// matching how the rest of the codebase (machinery, gateway, and the legacy emissive_copy helper) renders
/// emissive overlays against the lighting-plane alpha mask.
/// offset_spokesman: atom used for z-level plane offset reference (multiz support). Pass src/owner for body overlays.
/proc/emissive_appearance(icon, icon_state = "", atom/offset_spokesman, layer, alpha = 255, appearance_flags = NONE, offset_const, effect_type = EMISSIVE_BLOOM)
	if(isnull(layer))
		layer = FLOAT_LAYER

	var/mutable_appearance/appearance
	if(offset_spokesman)
		appearance = mutable_appearance(icon, icon_state, layer, offset_spokesman, EMISSIVE_PLANE, alpha, appearance_flags | EMISSIVE_APPEARANCE_FLAGS, offset_const)
	else
		appearance = mutable_appearance(icon, icon_state, layer, EMISSIVE_PLANE, alpha, appearance_flags | EMISSIVE_APPEARANCE_FLAGS)

	appearance.color = GLOB.emissive_color
	return appearance

/// Produces a mutable appearance glued to the [EMISSIVE_PLANE] dyed to be the [EM_BLOCK_COLOR].
/proc/emissive_blocker(icon, icon_state = "", atom/offset_spokesman, layer, alpha = 255, appearance_flags = NONE, offset_const)
	if(isnull(layer))
		layer = FLOAT_LAYER

	var/mutable_appearance/appearance
	if(offset_spokesman)
		appearance = mutable_appearance(icon, icon_state, layer, offset_spokesman, EMISSIVE_PLANE, alpha, appearance_flags | EMISSIVE_APPEARANCE_FLAGS, offset_const)
	else
		appearance = mutable_appearance(icon, icon_state, layer, EMISSIVE_PLANE, alpha, appearance_flags | EMISSIVE_APPEARANCE_FLAGS)

	appearance.color = GLOB.em_block_color
	return appearance

/proc/blend_cutoff_colors(list/first_color, list/second_color)
	ASSERT(first_color?.len == 3)
	ASSERT(second_color?.len == 3)

	var/list/output = new /list(3)

	for(var/i in 1 to 3)
		output[i] = (1 - (1 - first_color[i] / 100) * (1 - second_color[i] / 100)) * 100

	return output
