#define PAINTED_LAMP_GLOW_CONTRAST_MULTIPLIER 0.82
#define PAINTED_LAMP_EXPOSURE_CONTRAST_MULTIPLIER 0.88

/atom
	var/light_power = 1 // Intensity of the light.
	var/light_range = 0 // Range in tiles of the light.
	var/light_color     // Hexadecimal RGB string representing the colour of the light.
	var/light_height = LIGHTING_HEIGHT // Height off the ground on the pseudo-z-axis.
	// Конус света и вес контактной тени переехали на /atom/movable (ниже в этом файле): их
	// ставят только светильники и мебель, а слот на каждом из 1.2 млн турфов мира стоит мегабайты.

	/// Какая система света обслуживает атом: COMPLEX_LIGHT (корнер-движок) или OVERLAY_*
	/// (компонент overlay_lighting, вешается в /atom/movable/Initialize). Менять только в определении типа.
	var/light_system = COMPLEX_LIGHT
	/// Тумблер света. COMPLEX-путь учитывает его в update_light(), OVERLAY-путь реагирует через set_light_on().
	var/light_on = TRUE
	/// Битфлаги света (LIGHT_ATTACHED и далее).
	var/light_flags = NONE

	var/tmp/datum/light_source/light // Our light source. Don't fuck with this directly unless you have a good reason!
	var/tmp/list/light_sources       // Any light sources that are "inside" of us, for example, if src here was a mob that's carrying a flashlight, that flashlight's light source would be part of this list.

	var/glow_icon = 'icons/obj/lamps.dmi'
	var/exposure_icon = 'icons/effects/exposures.dmi'
	var/glow_icon_state
	var/glow_colored = TRUE
	var/exposure_icon_state
	var/exposure_colored = TRUE
	var/image/glow_overlay
	var/image/exposure_overlay
	var/list/bloom_parameters

/atom/movable
	var/light_cone_angle = 0 // Full cone width in degrees. 0 = omnidirectional.
	var/light_cone_dir = 0   // BYOND dir for the cone. 0 = follow top_atom.dir (rotates with holder). Non-zero = FIXED direction (ignores holder rotation).
	/// Contact shadow contribution weight (0-1). 0 = no shadow, 1 = full opaque shadow.
	/// Only used for non-opaque atoms that should still cast partial contact shadows.
	/// Opaque atoms (opacity=TRUE) always contribute weight 1.0 implicitly.
	var/shadow_weight = 0

// The proc you should always use to set the light of this atom.
// Nonesensical value for l_color default, so we can detect if it gets set to null.
#define NONSENSICAL_VALUE -99999
/atom/proc/set_light(var/l_range, var/l_power, var/l_color = NONSENSICAL_VALUE, var/l_height, var/l_cone_angle, var/l_cone_dir, var/l_on)
	if(light_system != COMPLEX_LIGHT)
		// Легаси-вызов на атоме с оверлейным светом: шумим в CI, но не роняем раунд -
		// маршрутизируем базовые параметры в гранулярные сеттеры (конусы/высота оверлею неприменимы).
		// Легаси-контракт тумблера сохраняем: set_light(0) = погасить, set_light(N) без l_on = зажечь.
		// Иначе range-ноль давал односторонний тумблер: компонент гас, light_on оставался TRUE,
		// и set_light_on(TRUE) no-op'ал по гарду "значение не изменилось".
		stack_trace("set_light() on overlay-light atom [type]; use set_light_range/power/color/on")
		if(!isnull(l_range))
			if(l_range <= 0)
				set_light_on(FALSE)
			else
				set_light_range(l_range)
		if(!isnull(l_power))
			set_light_power(l_power)
		if(l_color != NONSENSICAL_VALUE)
			set_light_color(l_color)
		if(!isnull(l_on))
			set_light_on(l_on)
		else if(!isnull(l_range) && l_range > 0)
			set_light_on(TRUE)
		return
	if(l_range > 0 && l_range < MINIMUM_USEFUL_LIGHT_RANGE)
		l_range = MINIMUM_USEFUL_LIGHT_RANGE	//Brings the range up to 1.4, which is just barely brighter than the soft lighting that surrounds players.
	if (l_power != null)
		light_power = l_power

	if (l_range != null)
		light_range = min(l_range, LIGHT_RANGE_CAP_FOR(src))

	if (l_color != NONSENSICAL_VALUE)
		light_color = l_color

	if (!isnull(l_height))
		set_light_height(l_height)

	if (!isnull(l_cone_angle) || !isnull(l_cone_dir))
		// Конус живёт на движимом: set_light() зовут и турфы (лава), у них конуса не бывает.
		var/atom/movable/cone_holder = ismovable(src) ? src : null
		if (isnull(cone_holder))
			stack_trace("set_light() с конусом на неподвижном [type]: конусы бывают только у движимого")
		else
			if (!isnull(l_cone_angle))
				cone_holder.light_cone_angle = l_cone_angle
			if (!isnull(l_cone_dir))
				cone_holder.light_cone_dir = l_cone_dir

	if (!isnull(l_on))
		light_on = l_on

	SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT, l_range, l_power, l_color, l_on)

	update_light()

#undef NONSENSICAL_VALUE

// Will update the light (duh).
// Creates or destroys it if needed, makes it update values, makes sure it's got the correct source turf...
/atom/proc/update_light()
	set waitfor = FALSE
	if (QDELETED(src))
		return
	if (light_system != COMPLEX_LIGHT) // Оверлейный свет обслуживает компонент, корнер-источник не создаём
		return

	if (!light_power || !light_range || !light_on) // We won't emit light anyways, destroy the light source.
		QDEL_NULL(light)
		delete_lights()
	else
		if (!ismovable(loc)) // We choose what atom should be the top atom of the light here.
			. = src
		else
			. = loc

		if (light) // Update the light or create it if it does not exist.
			light.update(.)
			update_bloom()
		else
			// Defer source creation for z-levels whose lighting objects don't exist yet
			// (see zlevel_lighting_deferred() — one predicate shared with create_all_lighting_objects).
			// Trait check needed during early init (before SSlighting) when ALL z-levels have lighting_initialized=FALSE.
			// The lighting_initialized check covers post-SSlighting-init period (bg init not yet complete).
			if(SSmapping?.initialized)
				var/turf/T = get_turf(src)
				if(T)
					var/datum/space_level/level = SSmapping.z_list.len >= T.z ? SSmapping.z_list[T.z] : null
					if(level && !level.lighting_initialized && zlevel_lighting_deferred(level))
						GLOB.lighting_deferred_atoms |= src
						note_deferred_lighting_z(T.z)
						return
			light = new/datum/light_source(src, .)
			update_bloom()

// If we have opacity, make sure to tell (potentially) affected light sources.
/atom/movable/Destroy()
	var/turf/T = loc
	. = ..()
	if (opacity && istype(T))
		var/old_has_opaque_atom = T.lighting_flags & TURF_HAS_OPAQUE_ATOM
		T.recalc_atom_opacity()
		if (old_has_opaque_atom != (T.lighting_flags & TURF_HAS_OPAQUE_ATOM))
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
		T.lighting_flags |= TURF_HAS_OPAQUE_ATOM
		T.reconsider_lights()
	else
		var/old_has_opaque_atom = T.lighting_flags & TURF_HAS_OPAQUE_ATOM
		T.recalc_atom_opacity()
		if (old_has_opaque_atom != (T.lighting_flags & TURF_HAS_OPAQUE_ATOM))
			T.reconsider_lights()


/atom/movable/Moved(atom/OldLoc, Dir)
	. = ..()
	if(light_range && light_power && !light) // Create deferred light source if we moved to an initialized z-level
		update_light()
	var/list/orphans
	for (var/datum/light_source/L as anything in light_sources) // Cycle through the light sources on this atom and tell them to update.
		if(!L.source_atom)
			LAZYADD(orphans, L)
			continue
		L.source_atom.update_light()
	for(var/datum/light_source/orphan as anything in orphans)
		LAZYREMOVE(light_sources, orphan)

/atom/vv_edit_var(var_name, var_value)
	switch (var_name)
		if (NAMEOF(src, light_range))
			if(light_system == COMPLEX_LIGHT)
				set_light(l_range=var_value)
			else
				set_light_range(var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_power))
			if(light_system == COMPLEX_LIGHT)
				set_light(l_power=var_value)
			else
				set_light_power(var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_color))
			if(light_system == COMPLEX_LIGHT)
				set_light(l_color=var_value)
			else
				set_light_color(var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_height))
			set_light(l_height=var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_on))
			if(light_system == COMPLEX_LIGHT)
				set_light(l_on=var_value)
			else
				set_light_on(var_value)
			datum_flags |= DF_VAR_EDITED
			return TRUE

		if (NAMEOF(src, light_flags))
			set_light_flags(var_value)
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
	new_range = min(new_range, LIGHT_RANGE_CAP_FOR(src))
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

/// Setter for whether or not this atom's light is on.
/atom/proc/set_light_on(new_value)
	if(new_value == light_on)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_ON, new_value) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_on
	light_on = new_value
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_ON, .)
	if(light_system == COMPLEX_LIGHT)
		update_light()

/// Setter for the light flags of this atom.
/atom/proc/set_light_flags(new_value)
	if(new_value == light_flags)
		return
	if(SEND_SIGNAL(src, COMSIG_ATOM_SET_LIGHT_FLAGS, new_value) & COMPONENT_BLOCK_LIGHT_UPDATE)
		return
	. = light_flags
	light_flags = new_value
	SEND_SIGNAL(src, COMSIG_ATOM_UPDATE_LIGHT_FLAGS, .)

/atom/proc/update_bloom()
	if(!(glow_icon && glow_icon_state) && !(exposure_icon && exposure_icon_state) && !glow_overlay && !exposure_overlay)
		return
	if(!light_range || !light_power || !light_on)
		delete_lights()
		return
	var/safe_color = light_color
	var/obj/machinery/light/lamp = istype(src, /obj/machinery/light) ? src : null
	if(isnull(safe_color) || length(safe_color) < 7 || copytext(safe_color, 1, 2) != "#")
		safe_color = lamp?.bulb_colour || LIGHT_COLOR_WARM_BLOOM
	var/is_painted_lamp = !!lamp?.color
	var/glow_contrast = (CONFIG_GET(number/glow_contrast_base) + CONFIG_GET(number/glow_contrast_power) * light_power) * (is_painted_lamp ? PAINTED_LAMP_GLOW_CONTRAST_MULTIPLIER : 1)
	var/glow_brightness = CONFIG_GET(number/glow_brightness_base) + CONFIG_GET(number/glow_brightness_power) * light_power
	var/exposure_contrast = (CONFIG_GET(number/exposure_contrast_base) + CONFIG_GET(number/exposure_contrast_power) * light_power) * (is_painted_lamp ? PAINTED_LAMP_EXPOSURE_CONTRAST_MULTIPLIER : 1)
	var/exposure_brightness = CONFIG_GET(number/exposure_brightness_base) + CONFIG_GET(number/exposure_brightness_power) * light_power
	var/glow_plane = layer <= LOW_OBJ_LAYER ? FLOOR_LIGHTING_LAMPS_PLANE : LIGHTING_LAMPS_PLANE
	var/list/current_parameters = list(glow_icon, glow_icon_state, glow_colored, exposure_icon, exposure_icon_state, exposure_colored, dir, glow_plane, safe_color, glow_contrast, glow_brightness, exposure_contrast, exposure_brightness)
	var/unchanged = length(bloom_parameters) == length(current_parameters)
	if(unchanged)
		for(var/index in 1 to length(current_parameters))
			if(bloom_parameters[index] != current_parameters[index])
				unchanged = FALSE
				break
	if(unchanged)
		// Общая очистка overlays не обязана удалять сохранённые изображения bloom.
		if(glow_overlay && !(glow_overlay.appearance in overlays))
			add_overlay(glow_overlay)
		if(exposure_overlay && !(exposure_overlay.appearance in overlays))
			add_overlay(exposure_overlay)
		return
	cut_overlay(glow_overlay)
	cut_overlay(exposure_overlay)
	glow_overlay = null
	exposure_overlay = null
	bloom_parameters = current_parameters
	var/static/list/exposure_icon_size_cache = list()
	if(glow_icon && glow_icon_state)
		glow_overlay = image(icon = glow_icon, icon_state = glow_icon_state, dir = dir, layer = -2)
		glow_overlay.plane = glow_plane
		glow_overlay.blend_mode = BLEND_ADD
		if(glow_colored)
			var/datum/color_matrix/matrix = new(safe_color, glow_contrast, glow_brightness)
			glow_overlay.color = matrix.get()
		add_overlay(glow_overlay)
	if(exposure_icon && exposure_icon_state)
		exposure_overlay = image(icon = exposure_icon, icon_state = exposure_icon_state, dir = dir, layer = -1)
		exposure_overlay.plane = LIGHTING_EXPOSURE_PLANE
		exposure_overlay.blend_mode = BLEND_ADD
		exposure_overlay.appearance_flags = RESET_ALPHA | RESET_COLOR | KEEP_APART
		var/datum/color_matrix/matrix = new(exposure_colored ? safe_color : 1, exposure_contrast, exposure_brightness)
		exposure_overlay.color = matrix.get()
		var/cache_key = "[exposure_icon]-[exposure_icon_state]"
		var/list/cached_size = exposure_icon_size_cache[cache_key]
		if(isnull(cached_size))
			var/icon/exposure = icon(icon = exposure_icon, icon_state = exposure_icon_state)
			cached_size = list(exposure.Width(), exposure.Height())
			exposure_icon_size_cache[cache_key] = cached_size
		exposure_overlay.pixel_x = 16 - cached_size[1] / 2
		exposure_overlay.pixel_y = 16 - cached_size[2] / 2
		add_overlay(exposure_overlay)

/atom/proc/delete_lights()
	cut_overlay(glow_overlay)
	cut_overlay(exposure_overlay)
	QDEL_NULL(glow_overlay)
	QDEL_NULL(exposure_overlay)
	if(bloom_parameters)
		bloom_parameters = null

/atom/proc/extinguish_light(force = FALSE)
	return

#undef PAINTED_LAMP_GLOW_CONTRAST_MULTIPLIER
#undef PAINTED_LAMP_EXPOSURE_CONTRAST_MULTIPLIER
