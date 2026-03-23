/area
	luminosity           = TRUE
	var/dynamic_lighting = DYNAMIC_LIGHTING_ENABLED
	/// Warm/cool temperature shift: positive = warm (↑R ↓B), negative = cool (↓R ↑B). Range: -0.15 to +0.15
	var/light_temperature = 0
	/// Shadow depth multiplier: >1 = deeper shadows, <1 = flatter lighting. Default 1.0
	var/light_contrast = 1
	/// Contact shadow strength multiplier: >1 = deeper wall shadows, <1 = softer. Default 1.0
	var/contact_shadow_multiplier = 1
	/// Ambient light floor: minimum brightness in fully dark areas. 0 = pure black, 0.02 = barely visible textures. Range: 0 to 0.05
	var/ambient_light = AMBIENT_LIGHT_DEFAULT

/area/proc/set_dynamic_lighting(var/new_dynamic_lighting = DYNAMIC_LIGHTING_ENABLED)
	if (new_dynamic_lighting == dynamic_lighting)
		return FALSE

	dynamic_lighting = new_dynamic_lighting

	if (IS_DYNAMIC_LIGHTING(src))
		cut_overlay(/obj/effect/fullbright)
		for (var/turf/T in src)
			if (IS_DYNAMIC_LIGHTING(T))
				T.lighting_build_overlay()

	else
		add_overlay(/obj/effect/fullbright)
		for (var/turf/T in src)
			if (T.lighting_object)
				T.lighting_clear_overlay()

	return TRUE

/area/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, dynamic_lighting))
			set_dynamic_lighting(var_value)
			return TRUE
		if(NAMEOF(src, light_temperature), NAMEOF(src, light_contrast), NAMEOF(src, contact_shadow_multiplier), NAMEOF(src, ambient_light))
			. = ..()
			if(!.)
				return
			// Recalculate blended profiles on all turfs in this area
			for(var/turf/T in src)
				T.recalc_area_blend_region()
			return
	return ..()
