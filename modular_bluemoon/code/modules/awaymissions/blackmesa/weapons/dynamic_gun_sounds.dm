// ============================================================================
// Dynamic Gun Sound System
// ============================================================================
/datum/dynamic_gun_sound
	var/dry_sound = null
	var/tail_sound = null
	var/volume = 50
	var/use_suppressed = FALSE
	var/suppressed_volume = 10
	var/dry_channel
	var/tail_channel

/datum/dynamic_gun_sound/New(dry, tail, vol = 50, suppressed = FALSE, sup_vol = 10)
	if(!dry)
		CRASH("dry_sound cannot be null for dynamic_gun_sound")
	dry_sound = dry
	tail_sound = tail
	volume = vol
	use_suppressed = suppressed
	suppressed_volume = sup_vol
	dry_channel = SSsounds.reserve_sound_channel(src)
	tail_channel = SSsounds.reserve_sound_channel(src)

/datum/dynamic_gun_sound/Destroy()
	SSsounds.free_datum_channels(src)
	return ..()

/datum/dynamic_gun_sound/proc/play_dry(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	if(!dry_sound)
		return

	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1

	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0

	var/sound/dry = sound(pick(dry_sound), repeat = FALSE, wait = FALSE, channel = dry_channel)
	playsound(user, dry, actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = dry_channel)

/datum/dynamic_gun_sound/proc/stop_loop(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1
	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0
	playsound(user, sound(null, repeat = FALSE, wait = FALSE, channel = dry_channel), actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = dry_channel)

/datum/dynamic_gun_sound/proc/play_tail(mob/user, obj/item/gun/gun)
	if(!user || !gun)
		return
	if(!tail_sound)
		return

	var/actual_volume = volume
	var/ignore_walls = TRUE
	var/extrarange = -2
	var/falloff_distance = -1

	if(use_suppressed && gun.suppressed)
		actual_volume = suppressed_volume
		ignore_walls = FALSE
		extrarange = SILENCED_SOUND_EXTRARANGE
		falloff_distance = 0

	var/sound/full_tail = sound(tail_sound, repeat = FALSE, wait = FALSE, channel = tail_channel)
	playsound(user, full_tail, actual_volume, FALSE, ignore_walls = ignore_walls, extrarange = extrarange, falloff_distance = falloff_distance, channel = tail_channel)

#define HAS_DYNAMIC_GUN_SOUNDS (TRUE)

/obj/item/gun
	var/has_dynamic_sounds = FALSE
	var/datum/dynamic_gun_sound/dynamic_sound_datum = null
	var/dynamic_looping = FALSE
	var/mesa_muzzle_flash = FALSE
	var/dynamic_sound_dry = null
	var/dynamic_sound_tail = null
	var/dynamic_sound_volume = 50
	var/dynamic_sound_use_suppressed = TRUE
	var/dynamic_sound_suppressed_volume = 10
	var/mesa_shotgun_bonus = FALSE
	var/mesa_melee_knockback = FALSE
	var/mesa_damage_bonus = 1

/obj/item/gun/Initialize(mapload)
	. = ..()
	if(mesa_damage_bonus != 1)
		projectile_damage_multiplier *= mesa_damage_bonus
	if(dynamic_sound_dry && !dynamic_sound_datum)
		has_dynamic_sounds = TRUE
		dynamic_sound_datum = new /datum/dynamic_gun_sound(
			dynamic_sound_dry,
			dynamic_sound_tail,
			dynamic_sound_volume,
			dynamic_sound_use_suppressed,
			dynamic_sound_suppressed_volume
		)

/obj/item/gun/Destroy()
	QDEL_NULL(dynamic_sound_datum)
	return ..()

/obj/item/gun/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	if(mesa_muzzle_flash && user)
		user.flash_lighting_fx(4, 5, LIGHT_COLOR_ORANGE, 1)
	if(mesa_shotgun_bonus && pointblank && pbtarget)
		var/mob/living/victim
		if(istype(pbtarget, /mob/living))
			victim = pbtarget
		else
			var/turf/target_turf = get_turf(pbtarget)
			if(target_turf)
				for(var/mob/living/L in target_turf)
					if(L != user)
						victim = L
						break
		if(victim)
			var/knockback_dir = get_dir(user, victim)
			if(!knockback_dir)
				knockback_dir = user ? user.dir : dir
			var/throw_target = get_edge_target_turf(victim, knockback_dir)
			victim.safe_throw_at(throw_target, rand(2, 3), 1, user)
	if(mesa_shotgun_bonus && pbtarget && !ismob(pbtarget))
		var/turf/target_turf = get_turf(pbtarget)
		if(target_turf)
			if(istype(pbtarget, /atom/movable))
				var/atom/movable/movable_target = pbtarget
				if(!movable_target.anchored)
					var/throw_dir = get_dir(user, movable_target) || (user ? user.dir : dir)
					movable_target.safe_throw_at(get_edge_target_turf(movable_target, throw_dir), 2, 1, user)
					if(ismob(movable_target))
						var/mob/living/victim = movable_target
						victim.Knockdown(20)
	if(has_dynamic_sounds && dynamic_sound_datum)
		if(recoil && !zoomed && user && pbtarget)
			directional_recoil(user, recoil*dir_recoil_amp, Get_Angle(user, pbtarget))

		if(stam_cost && user)
			var/safe_cost = clamp(stam_cost, 0, user.stamina_buffer)*(firing && burst_size >= 2 ? 1/burst_size : 1)
			user.UseStaminaBuffer(safe_cost)

		if(dynamic_sound_datum && user)
			if(dynamic_looping || burst_size > 1)
				dynamic_sound_datum.play_dry(user, src)
				if(!dynamic_looping)
					addtimer(CALLBACK(src, PROC_REF(finish_dynamic_burst), user), burst_shot_delay + 1, TIMER_UNIQUE | TIMER_OVERRIDE)
			else
				dynamic_sound_datum.play_tail(user, src)

		if(suppressed)
			if(message)
				if(pointblank && pbtarget)
					user.visible_message("<span class='danger'>[user] стреляет из [src] в упор по [pbtarget]!</span>", null, null, COMBAT_MESSAGE_RANGE)
				else
					user.visible_message("<span class='danger'>[user] стреляет из [src]!</span>", null, null, COMBAT_MESSAGE_RANGE)
		else
			if(user?.client)
				ai_broadcast_noise(get_turf(user), AI_NOISE_GUNSHOT_RANGE, user)
			if(message)
				if(pointblank && pbtarget)
					user.visible_message("<span class='danger'>[user] стреляет из [src] в упор по [pbtarget]!</span>", null, null, COMBAT_MESSAGE_RANGE)
				else
					user.visible_message("<span class='danger'>[user] стреляет из [src]!</span>", null, null, COMBAT_MESSAGE_RANGE)
	else
		..()

/obj/item/gun/on_autofire_start(mob/living/shooter)
	. = ..()
	if(. && has_dynamic_sounds && dynamic_sound_datum)
		dynamic_looping = TRUE
		RegisterSignal(shooter.client, COMSIG_CLIENT_MOUSEUP, PROC_REF(stop_dynamic_sound))

/obj/item/gun/proc/finish_dynamic_burst(mob/living/shooter)
	if(dynamic_looping || firing || !dynamic_sound_datum)
		return
	dynamic_sound_datum.stop_loop(shooter, src)
	dynamic_sound_datum.play_tail(shooter, src)
	dynamic_looping = FALSE

/obj/item/gun/proc/stop_dynamic_sound(client/source, atom/object, turf/location, control, params)
	var/mob/living/shooter = source?.mob
	if(!dynamic_looping || !dynamic_sound_datum)
		return
	dynamic_sound_datum.stop_loop(shooter, src)
	dynamic_sound_datum.play_tail(shooter, src)
	dynamic_looping = FALSE
	UnregisterSignal(source, COMSIG_CLIENT_MOUSEUP)

/obj/item/gun/shoot_with_empty_chamber(mob/living/user)
	. = ..()
	if(has_dynamic_sounds)
		stop_dynamic_sound(user?.client)
