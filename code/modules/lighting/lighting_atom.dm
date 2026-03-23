
/atom
	var/light_power = 1 // Intensity of the light.
	var/light_range = 0 // Range in tiles of the light.
	var/light_color     // Hexadecimal RGB string representing the colour of the light.
	var/light_height = LIGHTING_HEIGHT // Height off the ground on the pseudo-z-axis.
	var/light_cone_angle = 0 // Full cone width in degrees. 0 = omnidirectional.
	var/light_cone_dir = 0   // BYOND dir for the cone. 0 = follow top_atom.dir (rotates with holder). Non-zero = FIXED direction (ignores holder rotation).
	/// Contact shadow contribution weight (0-1). 0 = no shadow, 1 = full opaque shadow.
	/// Only used for non-opaque atoms that should still cast partial contact shadows.
	/// Opaque atoms (opacity=TRUE) always contribute weight 1.0 implicitly.
	var/shadow_weight = 0

	var/tmp/datum/light_source/light // Our light source. Don't fuck with this directly unless you have a good reason!
	var/tmp/list/light_sources       // Any light sources that are "inside" of us, for example, if src here was a mob that's carrying a flashlight, that flashlight's light source would be part of this list.

// The proc you should always use to set the light of this atom.
// Nonesensical value for l_color default, so we can detect if it gets set to null.
#define NONSENSICAL_VALUE -99999
/atom/proc/set_light(var/l_range, var/l_power, var/l_color = NONSENSICAL_VALUE, var/l_height, var/l_cone_angle, var/l_cone_dir)
	if(l_range > 0 && l_range < MINIMUM_USEFUL_LIGHT_RANGE)
		l_range = MINIMUM_USEFUL_LIGHT_RANGE	//Brings the range up to 1.4, which is just barely brighter than the soft lighting that surrounds players.
	if (l_power != null)
		light_power = l_power

	if (l_range != null)
		light_range = min(l_range, LIGHTING_MAX_RANGE)

	if (l_color != NONSENSICAL_VALUE)
		light_color = l_color

	if (!isnull(l_height))
		set_light_height(l_height)

	if (!isnull(l_cone_angle))
		light_cone_angle = l_cone_angle

	if (!isnull(l_cone_dir))
		light_cone_dir = l_cone_dir

	SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT, l_range, l_power, l_color)

	update_light()

#undef NONSENSICAL_VALUE

// Will update the light (duh).
// Creates or destroys it if needed, makes it update values, makes sure it's got the correct source turf...
/atom/proc/update_light()
	set waitfor = FALSE
	if (QDELETED(src))
		return

	if (!light_power || !light_range) // We won't emit light anyways, destroy the light source.
		QDEL_NULL(light)
	else
		if (!ismovable(loc)) // We choose what atom should be the top atom of the light here.
			. = src
		else
			. = loc

		if (light) // Update the light or create it if it does not exist.
			light.update(.)
		else
			// Defer source creation for mining/reserved z-levels whose lighting objects don't exist yet.
			// Trait check needed during early init (before SSlighting) when ALL z-levels have lighting_initialized=FALSE.
			// The lighting_initialized check covers post-SSlighting-init period (bg init not yet complete).
			if(SSmapping?.initialized)
				var/turf/T = get_turf(src)
				if(T)
					var/datum/space_level/level = SSmapping.z_list.len >= T.z ? SSmapping.z_list[T.z] : null
					if(level && !level.lighting_initialized && (level.traits[ZTRAIT_MINING] || level.traits[ZTRAIT_RESERVED]))
						GLOB.lighting_deferred_atoms |= src
						return
			light = new/datum/light_source(src, .)

// If we have opacity, make sure to tell (potentially) affected light sources.
/atom/movable/Destroy()
	var/turf/T = loc
	. = ..()
	if (opacity && istype(T))
		var/old_has_opaque_atom = T.has_opaque_atom
		T.recalc_atom_opacity()
		if (old_has_opaque_atom != T.has_opaque_atom)
			T.reconsider_lights()

// Should always be used to change the opacity of an atom.
// It notifies (potentially) affected light sources so they can update (if needed).
/atom/proc/set_opacity(var/new_opacity)
	if (new_opacity == opacity)
		return

	opacity = new_opacity
	var/turf/T = loc
	if (!isturf(T))
		return

	if (new_opacity == TRUE)
		T.has_opaque_atom = TRUE
		T.reconsider_lights()
	else
		var/old_has_opaque_atom = T.has_opaque_atom
		T.recalc_atom_opacity()
		if (old_has_opaque_atom != T.has_opaque_atom)
			T.reconsider_lights()


/atom/movable/Moved(atom/OldLoc, Dir)
	. = ..()
	if(light_range && light_power && !light) // Create deferred light source if we moved to an initialized z-level
		update_light()
	var/datum/light_source/L
	var/thing
	for (thing in light_sources) // Cycle through the light sources on this atom and tell them to update.
		L = thing
		L.source_atom.update_light()

/atom/vv_edit_var(var_name, var_value)
	switch (var_name)
		if (NAMEOF(src, light_range))
			set_light(l_range=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_power))
			set_light(l_power=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_color))
			set_light(l_color=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_height))
			set_light(l_height=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_cone_angle))
			set_light(l_cone_angle=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_cone_dir))
			set_light(l_cone_dir=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

	return ..()


/atom/proc/flash_lighting_fx(_range = FLASH_LIGHT_RANGE, _power = FLASH_LIGHT_POWER, _color = LIGHT_COLOR_WHITE, _duration = FLASH_LIGHT_DURATION, _reset_lighting = TRUE)
	return

/turf/flash_lighting_fx(_range = FLASH_LIGHT_RANGE, _power = FLASH_LIGHT_POWER, _color = LIGHT_COLOR_WHITE, _duration = FLASH_LIGHT_DURATION, _reset_lighting = TRUE)
	if(!_duration)
		stack_trace("Lighting FX obj created on a turf without a duration")
	new /obj/effect/dummy/lighting_obj (src, _color, _range, _power, _duration)

/obj/flash_lighting_fx(_range = FLASH_LIGHT_RANGE, _power = FLASH_LIGHT_POWER, _color = LIGHT_COLOR_WHITE, _duration = FLASH_LIGHT_DURATION, _reset_lighting = TRUE)
	var/temp_color
	var/temp_power
	var/temp_range
	if(!_reset_lighting) //incase the obj already has a lighting color that you don't want cleared out after, ie computer monitors.
		temp_color = light_color
		temp_power = light_power
		temp_range = light_range
	set_light(_range, _power, _color)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, set_light), _reset_lighting ? initial(light_range) : temp_range, _reset_lighting ? initial(light_power) : temp_power, _reset_lighting ? initial(light_color) : temp_color), _duration, TIMER_OVERRIDE|TIMER_UNIQUE)

/mob/living/flash_lighting_fx(_range = FLASH_LIGHT_RANGE, _power = FLASH_LIGHT_POWER, _color = LIGHT_COLOR_WHITE, _duration = FLASH_LIGHT_DURATION, _reset_lighting = TRUE)
	mob_light(_color, _range, _power, _duration)

/mob/living/proc/mob_light(_color, _range, _power, _duration)
	var/obj/effect/dummy/lighting_obj/moblight/mob_light_obj = new (src, _color, _range, _power, _duration)
	return mob_light_obj

// Setter for the light power of this atom.
/atom/proc/set_light_power(new_power)
	if(new_power == light_power)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_POWER, new_power) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_power
	light_power = new_power
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_POWER, .)

/// Setter for the light range of this atom.
/atom/proc/set_light_range(new_range)
	new_range = min(new_range, LIGHTING_MAX_RANGE)
	if(new_range == light_range)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_RANGE, new_range) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_range
	light_range = new_range
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_RANGE, .)

/// Setter for the light color of this atom.
/atom/proc/set_light_color(new_color)
	if(new_color == light_color)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_COLOR, new_color) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_color
	light_color = new_color
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_COLOR, .)

/// Setter for the light height of this atom.
/atom/proc/set_light_height(new_height)
	if(new_height == light_height)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_HEIGHT, new_height) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_height
	light_height = new_height
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_HEIGHT, .)

/*
/// Setter for whether or not this atom's light is on.
/atom/proc/set_light_on(new_value)
	if(new_value ==  )
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_ON, new_value) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_on
	light_on = new_value
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_ON, .)

/// Setter for the light flags of this atom.
/atom/proc/set_light_flags(new_value)
	if(new_value == light_flags)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_FLAGS, new_value) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_flags
	light_flags = new_value
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_FLAGS, .)
*/
