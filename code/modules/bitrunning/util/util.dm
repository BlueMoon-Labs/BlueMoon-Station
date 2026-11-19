// Обрыв: падение, вращение и урон при приземлении.
/turf/open/cliff
	icon_state = "cliff"
	icon = 'icons/turf/cliff/cliff.dmi'
	density = TRUE
	var/can_fall_from_direction = NORTH
	var/fall_direction = SOUTH
	var/valid_move_dirs = SOUTH | WEST | EAST | SOUTHWEST | SOUTHEAST
	var/fall_speed = 0.2 SECONDS
	var/list/protected_types = list(/obj/item/projectile, /obj/effect, /mob/dead)

/turf/open/cliff/Initialize(mapload)
	. = ..()

/turf/open/cliff/CanPass(atom/movable/mover, turf/target)
	..()

	var/entry_dir = get_dir(src, mover)
	if(entry_dir & can_fall_from_direction || !can_fall(mover))
		return TRUE

	return FALSE

/turf/open/cliff/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()

	try_fall(arrived, old_loc)

/turf/open/cliff/proc/try_fall(atom/movable/arrived, atom/old_loc)
	if(can_fall(arrived, old_loc))
		fall(arrived)

/turf/open/cliff/proc/can_fall(atom/movable/arrived, atom/old_loc)
	if(is_type_in_list(arrived, protected_types))
		return FALSE

	if(arrived.throwing || HAS_TRAIT(arrived, TRAIT_CLIFF_WALKER) || HAS_TRAIT(arrived, TRAIT_MOVE_FLYING))
		return FALSE

	if(arrived.anchored || (arrived in SScliff_falling.cliff_grinders))
		return FALSE

	var/entry_dir = old_loc ? get_dir(src, old_loc) : get_dir(src, arrived)
	if(!iscliffturf(get_step(src, fall_direction)) && !(entry_dir & can_fall_from_direction))
		return FALSE

	if(!arrived.has_gravity(src))
		return FALSE

	return TRUE

/turf/open/cliff/proc/fall(atom/movable/arrived)
	SScliff_falling.start_falling(arrived, src)
	on_fall(arrived)

/turf/open/cliff/proc/on_fall(atom/movable/faller)
	if(!isliving(faller))
		return
	var/mob/living/living = faller
	living.Knockdown(fall_speed)

/turf/open/cliff/proc/can_move(atom/movable/mover, turf/target)
	if(!(valid_move_dirs & get_dir(src, target)))
		return FALSE

	if(!iscliffturf(target) && get_dir(src, target) != fall_direction)
		return FALSE

	return TRUE

/turf/open/cliff/snowrock
	icon_state = "icerock_wall-0"
	icon = 'icons/turf/cliff/icerock_cliff.dmi'
	layer = EDGED_TURF_LAYER
	plane = WALL_PLANE
	transform = matrix(1, 0, -4, 0, 1, -4)
	initial_gas_mix = ICEMOON_DEFAULT_ATMOS
	planetary_atmos = TRUE

/turf/open/cliff/snowrock/Initialize(mapload)
	. = ..()
	var/image/underlay = image(icon = 'icons/turf/snow.dmi', icon_state = "snow")
	underlay.pixel_x = 4
	underlay.pixel_y = 4
	SET_PLANE(underlay, FLOOR_PLANE, src)
	underlays += underlay

	var/mask = 0
	if(iscliffturf(get_step(src, NORTH)))
		mask |= NORTH
	if(iscliffturf(get_step(src, SOUTH)))
		mask |= SOUTH
	if(iscliffturf(get_step(src, EAST)))
		mask |= EAST
	if(iscliffturf(get_step(src, WEST)))
		mask |= WEST
	icon_state = "icerock_wall-[mask]"

/proc/iscliffturf(atom/A)
	return istype(A, /turf/open/cliff)

/atom/proc/create_digital_aura()
	var/list/overlays = get_digital_overlays()
	if(!length(overlays))
		return

	add_overlay(overlays)
	alpha = 210
	set_light(2, l_color = LIGHT_COLOR_BUBBLEGUM, l_on = TRUE)
	update_appearance()

/atom/proc/remove_digital_aura()
	var/list/overlays = get_digital_overlays()
	if(!length(overlays))
		return

	cut_overlay(overlays)
	alpha = 255
	set_light(0, l_color = null, l_on = FALSE)
	update_appearance()

/atom/proc/get_digital_overlays()
	var/base_icon
	var/dimensions = get_icon_dimensions(icon)
	if(!length(dimensions))
		return

	switch(dimensions["width"])
		if(32)
			base_icon = 'icons/effects/bitrunning.dmi'
		if(48)
			base_icon = 'icons/effects/bitrunning_48.dmi'
		if(64)
			base_icon = 'icons/effects/bitrunning_64.dmi'

	var/mutable_appearance/redshift = mutable_appearance(base_icon, "redshift")
	redshift.blend_mode = BLEND_MULTIPLY

	var/mutable_appearance/glitch_effect = mutable_appearance(base_icon, "glitch", MUTATIONS_LAYER, alpha = 150)

	return list(glitch_effect, redshift)

/mob/living/carbon/human/proc/set_service_style()
	var/static/list/approved_hair_colors = list(
		"#4B3D28",
		COLOR_BLACK,
		"#8D4A43",
		"#D2B48C",
	)

	var/static/list/approved_hairstyles = list(
		/datum/sprite_accessory/hair/business,
		/datum/sprite_accessory/hair/business2,
		/datum/sprite_accessory/hair/business3,
		/datum/sprite_accessory/hair/business4,
		/datum/sprite_accessory/hair/mulder,
	)

	var/datum/sprite_accessory/hair/picked_hair = pick(approved_hairstyles)
	var/picked_color = pick(approved_hair_colors)

	facial_hair_style = "Shaved"
	hair_color = picked_color
	hair_style = initial(picked_hair.name)
	update_hair()

// Боссы виртуальных доменов ослаблены для отладки.
/proc/is_bitrunning_objective(atom/movable/thing)
	return istype(thing, /obj/structure/closet/crate) || \
		istype(thing, /obj/item/storage/lockbox) || \
		istype(thing, /obj/item/card/id) || \
		istype(thing, /obj/item/key)

/mob/living/simple_animal/hostile/megafauna/proc/make_virtual_megafauna()
	var/new_max = clamp(round(maxHealth * 0.25), 250, 650)
	maxHealth = new_max
	health = new_max

	true_spawn = FALSE

	loot = list(/obj/structure/closet/crate/secure/bitrunning/encrypted)

/mob/living/carbon/proc/make_virtual_mob()
	add_traits(list(
		TRAIT_NO_AUGMENTS,
		TRAIT_NO_DNA_COPY,
		TRAIT_NOBLOOD,
		TRAIT_NOBREATH,
		TRAIT_NOHUNGER,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_WEATHER_IMMUNE,
		), TRAIT_GENERIC,
	)
