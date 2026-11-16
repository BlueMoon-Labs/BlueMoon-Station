/turf/open/space/ihategordon
	name = "Ihategordon Void"
	desc = "Странное космическое пространство. Здесь есть воздух и нормальная температура, но гравитации нет."

	initial_temperature = T20C

	temperature = T20C
	thermal_conductivity = 0
	heat_capacity = 700000
	wave_explosion_multiply = EXPLOSION_DAMPEN_SPACE
	wave_explosion_block = EXPLOSION_BLOCK_SPACE

	plane = PLANE_SPACE
	layer = SPACE_LAYER
	light_power = STARLIGHT_POWER_NIGHT
	light_color = COLOR_STARLIGHT
	light_height = LIGHTING_HEIGHT_SPACE
	bullet_bounce_sound = null
	vis_flags = VIS_INHERIT_ID

	var/static/datum/gas_mixture/immutable/ihategordon/ihategordon_atmos

	var/list/mobs_on_turf = list()

/datum/gas_mixture/immutable/ihategordon
	initial_temperature = T20C

/datum/gas_mixture/immutable/ihategordon/populate()
	set_moles(GAS_O2, MOLES_O2STANDARD)
	set_moles(GAS_N2, MOLES_N2STANDARD)
	temperature = T20C

/turf/open/proc/remove_air_from_immutable(amount, proportional = FALSE)
	RETURN_TYPE(/datum/gas_mixture)
	var/datum/gas_mixture/source_air = return_air()
	if(!source_air || amount <= 0)
		return null

	var/datum/gas_mixture/working_air = new /datum/gas_mixture(source_air.return_volume())
	if(!working_air.copy_from(source_air))
		qdel(working_air)
		return null

	var/datum/gas_mixture/removed_air
	if(proportional)
		removed_air = working_air.remove_ratio(amount)
	else
		removed_air = working_air.remove(amount)
	qdel(working_air)
	return removed_air

/turf/open/chasm/ihategordon_invisible
	name = "Ihategordon Void"
	desc = "Странное космическое пространство. Здесь есть воздух и нормальная температура, но гравитации нет."
	icon = 'icons/turf/space.dmi'
	icon_state = "0"
	baseturfs = /turf/open/chasm/ihategordon_invisible
	plane = PLANE_SPACE
	layer = SPACE_LAYER
	light_power = STARLIGHT_POWER_NIGHT
	light_color = COLOR_STARLIGHT
	light_height = LIGHTING_HEIGHT_SPACE
	bullet_bounce_sound = null
	vis_flags = VIS_INHERIT_ID
	initial_temperature = T20C
	thermal_conductivity = 0
	heat_capacity = 700000

	var/static/datum/gas_mixture/immutable/ihategordon/ihategordon_atmos

/turf/open/chasm/ihategordon_invisible/Initialize(mapload)
	. = ..()
	icon_state = SPACE_ICON_STATE
	vis_contents.Cut()
	visibilityChanged()

	if(SSmapping.max_plane_offset)
		SET_PLANE_W_SCALAR(src, PLANE_TO_TRUE(plane), GET_Z_PLANE_OFFSET(z))

	var/area/A = loc
	if(!TURF_IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)

	if (light_power && light_range)
		update_light()

	if (opacity)
		lighting_flags |= TURF_HAS_OPAQUE_ATOM

	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)

	if(!ihategordon_atmos)
		ihategordon_atmos = new /datum/gas_mixture/immutable/ihategordon

		ihategordon_atmos.populate()

		ihategordon_atmos.temperature = T20C

	air = ihategordon_atmos
	update_air_ref(0)

	RegisterSignal(src, COMSIG_ATOM_INTERCEPT_TELEPORT, PROC_REF(block_teleport))

	ComponentInitialize()

	return INITIALIZE_HINT_NORMAL

/turf/open/chasm/ihategordon_invisible/process()
	STOP_PROCESSING(SSobj, src)
	return

/turf/open/chasm/ihategordon_invisible/proc/block_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_TELEPORT

/turf/open/chasm/ihategordon_invisible/Initalize_Atmos(times_fired)

	return

/turf/open/chasm/ihategordon_invisible/TakeTemperature(temp)

	return

/turf/open/chasm/ihategordon_invisible/Assimilate_Air()

	return

/turf/open/chasm/ihategordon_invisible/remove_air(amount)
	RETURN_TYPE(/datum/gas_mixture)
	return remove_air_from_immutable(amount)

/turf/open/chasm/ihategordon_invisible/remove_air_ratio(amount)
	RETURN_TYPE(/datum/gas_mixture)
	return remove_air_from_immutable(amount, TRUE)

/turf/open/chasm/ihategordon_invisible/return_air()
	RETURN_TYPE(/datum/gas_mixture)

	if(ihategordon_void_z(z))
		return ihategordon_void_air()
	return air

/turf/open/chasm/ihategordon_invisible/return_analyzable_air()
	RETURN_TYPE(/datum/gas_mixture)

	if(ihategordon_void_z(z))
		return ihategordon_void_air()
	return air

/turf/open/chasm/ihategordon_invisible/assume_air(datum/gas_mixture/giver)

	return

/turf/open/chasm/ihategordon_invisible/update_air_ref()

	return

/turf/open/chasm/ihategordon_invisible/air_update_turf()
	return

/turf/open/space/ihategordon/Initialize(mapload)
	SHOULD_CALL_PARENT(FALSE)
	icon_state = SPACE_ICON_STATE

	if(!ihategordon_atmos)
		ihategordon_atmos = new /datum/gas_mixture/immutable/ihategordon

		ihategordon_atmos.populate()

		ihategordon_atmos.temperature = T20C

	air = ihategordon_atmos
	update_air_ref(0)
	vis_contents.Cut()
	visibilityChanged()

	if(flags_1 & INITIALIZED_1)
		stack_trace("Warning: [src]([type]) initialized multiple times!")
	flags_1 |= INITIALIZED_1

	if(SSmapping.max_plane_offset)
		SET_PLANE_W_SCALAR(src, PLANE_TO_TRUE(plane), GET_Z_PLANE_OFFSET(z))

	var/area/A = loc
	if(!TURF_IS_DYNAMIC_LIGHTING(src) && IS_DYNAMIC_LIGHTING(A))
		add_overlay(/obj/effect/fullbright)

	if (light_power && light_range)
		update_light()

	if (opacity)
		lighting_flags |= TURF_HAS_OPAQUE_ATOM

	var/turf/T = SSmapping.get_turf_above(src)
	if(T)
		T.multiz_turf_new(src, DOWN)
	T = SSmapping.get_turf_below(src)
	if(T)
		T.multiz_turf_new(src, UP)

	if(SSmapping.level_trait(z, ZTRAIT_TRANSPARENT_SPACE))
		make_space_transparent()

	RegisterSignal(src, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))
	RegisterSignal(src, COMSIG_MOVABLE_CROSSED, PROC_REF(on_entered))

	RegisterSignal(src, COMSIG_ATOM_INTERCEPT_TELEPORT, PROC_REF(block_teleport))

	ComponentInitialize()

	return INITIALIZE_HINT_NORMAL

/turf/open/space/ihategordon/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER

	if(!istype(src, /turf/open/space/ihategordon))
		return
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(!L)
		return

	mobs_on_turf |= L

	if(!(datum_flags & DF_ISPROCESSING))
		START_PROCESSING(SSobj, src)

	L.inertia_dir = 0

	if(has_jetpack(L))
		return

	L.adjustStaminaLoss(30)

	if(IS_STAMCRIT(L))

		to_chat(L, "<span class='userdanger'>Ваши силы покинули вас! Вы проваливаетесь в бездну!</span>")
		INVOKE_ASYNC(src, PROC_REF(drop_into_chasm), L)

/turf/open/space/ihategordon/proc/drop_into_chasm(mob/living/L)

	STOP_PROCESSING(SSobj, src)
	if(istype(src, /turf/open/space/ihategordon))
		mobs_on_turf.Cut()
	var/turf/open/chasm/ihategordon_invisible/C = ChangeTurf(/turf/open/chasm/ihategordon_invisible, flags = CHANGETURF_INHERIT_AIR)
	if(istype(C))
		C.drop(L)

/turf/open/space/ihategordon/proc/teleport_to_safe(mob/living/L)

	var/turf/safe_turf = null
	var/min_dist = 100
	for(var/turf/T in range(10, src))
		if(!istype(T, /turf/open/space) && !istype(T, /turf/open/chasm))
			var/dist = get_dist(src, T)
			if(dist < min_dist)
				min_dist = dist
				safe_turf = T
	if(safe_turf)
		L.forceMove(safe_turf)
		L.adjustStaminaLoss(-50)
		to_chat(L, "<span class='notice'>Вы телепортировались в безопасное место.</span>")
	else

		for(var/area/awaymission/ihategordon/entrance/E in world)
			var/list/turfs = get_area_turfs(E)
			if(turfs.len)
				L.forceMove(pick(turfs))
				L.adjustStaminaLoss(-50)
				to_chat(L, "<span class='notice'>Вы телепортировались в точку входа.</span>")
				break

/turf/open/space/ihategordon/proc/has_jetpack(mob/living/L)
	if(!L)
		return FALSE
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		if(C.back)
			if(istype(C.back, /obj/item/tank/jetpack))
				var/obj/item/tank/jetpack/J = C.back
				if(J.on)
					return TRUE
		for(var/obj/item/organ/cyberimp/chest/thrusters/T in C.internal_organs)
			if(T && T.on)
				return TRUE
	return FALSE

/turf/open/space/ihategordon/proc/block_teleport(datum/source, channel, turf/origin, turf/destination)
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_TELEPORT

/turf/open/space/ihategordon/process()

	if(!istype(src, /turf/open/space/ihategordon) || !mobs_on_turf || !mobs_on_turf.len)
		STOP_PROCESSING(SSobj, src)
		return
	var/list/departed = list()
	for(var/mob/living/L in mobs_on_turf)
		if(!L || QDELETED(L) || L.stat == DEAD || get_turf(L) != src)
			departed += L
			continue

		L.inertia_dir = 0

		if(has_jetpack(L))
			continue

		L.adjustStaminaLoss(15)

		if(IS_STAMCRIT(L))

			to_chat(L, "<span class='userdanger'>Ваши силы покинули вас! Вы проваливаетесь в бездну!</span>")
			INVOKE_ASYNC(src, PROC_REF(drop_into_chasm), L)
			departed += L
	for(var/mob/living/L in departed)
		mobs_on_turf -= L
	if(!mobs_on_turf.len)
		STOP_PROCESSING(SSobj, src)

GLOBAL_VAR_INIT(ihategordon_zlevels, alist())
GLOBAL_VAR_INIT(ihategordon_void_atmos, null)
GLOBAL_VAR_INIT(ihategordon_starlight_done, alist())

#define IHATEGORDON_STARLIGHT_GRID 4
#define IHATEGORDON_STARLIGHT_RANGE 6

/proc/ihategordon_void_z(z)
	if(!GLOB.ihategordon_zlevels)
		return FALSE
	return GLOB.ihategordon_zlevels["[z]"]

/proc/ihategordon_void_air()
	RETURN_TYPE(/datum/gas_mixture/immutable/ihategordon)
	var/datum/gas_mixture/immutable/ihategordon/A = GLOB.ihategordon_void_atmos
	if(!A)
		A = new /datum/gas_mixture/immutable/ihategordon
		A.populate()
		GLOB.ihategordon_void_atmos = A
	return A

/datum/map_template/on_map_loaded(z, list/bounds)
	. = ..()
	if(findtext(src.mappath || "", "ihategordon"))
		for(var/zz in z to z + max(src.zdepth, 1) - 1)
			GLOB.ihategordon_zlevels["[zz]"] = TRUE

/turf/open/space/return_air()
	RETURN_TYPE(/datum/gas_mixture)
	if(ihategordon_void_z(z))
		return ihategordon_void_air()
	return ..()

/turf/open/space/assume_air(datum/gas_mixture/giver)

	if(ihategordon_void_z(z))
		return
	return ..()

/turf/open/space/basic/remove_air(amount)
	RETURN_TYPE(/datum/gas_mixture)
	if(ihategordon_void_z(z))
		return remove_air_from_immutable(amount)
	return ..()

/turf/open/space/basic/remove_air_ratio(amount)
	RETURN_TYPE(/datum/gas_mixture)
	if(ihategordon_void_z(z))
		return remove_air_from_immutable(amount, TRUE)
	return ..()

/proc/ihategordon_void_queue_starlight(z)
	if(GLOB.ihategordon_starlight_done["[z]"])
		return
	GLOB.ihategordon_starlight_done["[z]"] = TRUE
	for(var/turf/open/space/T as anything in Z_TURFS(z))
		if(QDELETED(T))
			continue
		if(!(T.x % IHATEGORDON_STARLIGHT_GRID) && !(T.y % IHATEGORDON_STARLIGHT_GRID))
			T.queue_starlight()
		CHECK_TICK

/proc/ihategordon_void_starlight(turf/open/space/T)
	if(!CONFIG_GET(flag/starlight))
		return
	var/is_source = !(T.x % IHATEGORDON_STARLIGHT_GRID) && !(T.y % IHATEGORDON_STARLIGHT_GRID)
	if(!is_source)
		if(T.lighting_flags & TURF_STARLIT)
			T.lighting_flags &= ~TURF_STARLIT
			GLOB.starlight -= T
		if(T.light_range)
			T.set_light(l_range = 0)
		return
	var/use_color = GLOB.current_starlight_color || T.light_color
	var/use_power = GLOB.current_starlight_power || T.light_power
	if(T.light_range != IHATEGORDON_STARLIGHT_RANGE || T.light_power != use_power || T.light_color != use_color)
		T.set_light(l_range = IHATEGORDON_STARLIGHT_RANGE, l_power = use_power, l_color = use_color)
	if(!(T.lighting_flags & TURF_STARLIT))
		T.lighting_flags |= TURF_STARLIT
		GLOB.starlight |= T

/turf/open/space/ihategordon/update_starlight()
	ihategordon_void_starlight(src)

/turf/open/space/basic/update_starlight()
	if(ihategordon_void_z(z))
		ihategordon_void_starlight(src)
	else
		..()

/turf/open/space/ihategordon/Destroy()
	STOP_PROCESSING(SSobj, src)
	mobs_on_turf.Cut()
	return ..()

/turf/open/space/ihategordon/Initalize_Atmos(times_fired)

	return

/turf/open/space/ihategordon/TakeTemperature(temp)

	return

/turf/open/space/ihategordon/Assimilate_Air()

	return

/turf/open/space/ihategordon/remove_air(amount)
	RETURN_TYPE(/datum/gas_mixture)
	return remove_air_from_immutable(amount)

/turf/open/space/ihategordon/remove_air_ratio(amount)
	RETURN_TYPE(/datum/gas_mixture)
	return remove_air_from_immutable(amount, TRUE)

/turf/open/space/ihategordon/return_air()
	RETURN_TYPE(/datum/gas_mixture)

	return air

/turf/open/space/ihategordon/return_analyzable_air()
	RETURN_TYPE(/datum/gas_mixture)

	return air

/turf/open/space/ihategordon/assume_air(datum/gas_mixture/giver)

	return

/turf/open/space/ihategordon/update_air_ref()

	return

/turf/open/space/ihategordon/air_update_turf()
	return

/atom/movable/screen/parallax_layer/ihategordon
	icon = 'modular_bluemoon/icons/effects/mesaparallax.dmi'

/atom/movable/screen/parallax_layer/ihategordon/layer_1
	icon_state = "layer1"
	speed = 0.6
	layer = 1
	parallax_intensity = PARALLAX_LOW
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_2
	icon_state = "layer2"
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED
	layer_mode = PARALLAX_MODE_TILED

/atom/movable/screen/parallax_layer/ihategordon/layer_3
	icon_state = "layer3"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH
	layer_mode = PARALLAX_MODE_STATIC
	center_x = 3872
	center_y = 6848
	environment_flags = PARALLAX_ENV_SPACE_RUINS

/atom/movable/screen/parallax_layer/ihategordon/random/space_gas
	icon_state = "space_gas"
	blend_mode = BLEND_OVERLAY
	speed = 2
	layer = 3
	parallax_intensity = PARALLAX_INSANE
	layer_mode = PARALLAX_MODE_TILED
	palette_tinted = TRUE

/datum/parallax_profile/ihategordon
	id = "ihategordon"
	name = "Ihategordon Void"
	environment_flags = PARALLAX_ENV_SPACE_RUINS
	base_layers = list(
		/atom/movable/screen/parallax_layer/ihategordon/layer_1,
		/atom/movable/screen/parallax_layer/ihategordon/layer_2,
		/atom/movable/screen/parallax_layer/ihategordon/layer_3,
	)
	variant_sets = list(
		list(70, /atom/movable/screen/parallax_layer/ihategordon/random/space_gas),
		list(30),
	)
	palette = list(COLOR_TEAL, COLOR_GREEN, COLOR_YELLOW, COLOR_CYAN, COLOR_ORANGE, COLOR_PURPLE)
	min_quality = PARALLAX_LOW
	weight = 0
	source = "BlueMoon Station - Mesa Mission"

/datum/controller/subsystem/parallax/proc/check_ihategordon_z(z)

	return ihategordon_void_z(z)

/datum/controller/subsystem/parallax/pick_profile_for_z(z)
	. = ..()

	if(check_ihategordon_z(z))

		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ihategordon_void_queue_starlight), z), 0)
		var/datum/parallax_profile/ihategordon/ihategordon_profile = resolve_profile("ihategordon")
		if(ihategordon_profile)
			return ihategordon_profile
