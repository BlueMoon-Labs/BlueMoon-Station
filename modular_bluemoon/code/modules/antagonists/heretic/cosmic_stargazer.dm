#define HERETIC_STARGAZER_FOLLOW_DISTANCE 2
#define HERETIC_STARGAZER_LEASH 12
#define HERETIC_STARGAZER_MOVE_DELAY (0.2 SECONDS)
#define HERETIC_STARGAZER_REPATH_DELAY (1 SECONDS)
#define HERETIC_STARGAZER_FADE_TIME (1.5 SECONDS)
#define HERETIC_STARGAZER_RAY_FLASH (0.5 SECONDS)

/mob/living/simple_animal/heretic_stargazer
	name = "stargazer"
	real_name = "stargazer"
	desc = "Пустая парящая мантия, внутри которой вместо тела ночное небо; из-под куколя смотрит один глаз. Раз в 3 секунды бьёт лучом в 20 ожогов ближайшего врага своего хозяина в семи клетках; стены, окна и закрытые двери закрывают линию. Это крупная отдельная цель: 400 здоровья, выносливости у него нет, поэтому свалить его можно только летальным оружием. Новый Звездочёт откликнется хозяину лишь через 3 минуты после гибели этого."
	icon = 'modular_bluemoon/icons/mob/heretic_stargazer.dmi'
	icon_state = "stargazer"
	icon_living = "stargazer"
	icon_dead = "stargazer_dead"
	pixel_x = -32
	base_pixel_x = -32
	maxHealth = HERETIC_STARGAZER_HEALTH
	health = HERETIC_STARGAZER_HEALTH
	mob_biotypes = NONE
	mob_size = MOB_SIZE_LARGE
	movement_type = FLYING
	move_resist = MOVE_FORCE_OVERPOWERING
	faction = list("heretics")
	speak_emote = list("гудит")
	response_help_continuous = "проводит рукой сквозь"
	response_help_simple = "провести рукой сквозь"
	response_disarm_continuous = "отталкивает"
	response_disarm_simple = "оттолкнуть"
	response_harm_continuous = "бьёт"
	response_harm_simple = "ударить"
	wander = FALSE
	stop_automated_movement = TRUE
	AIStatus = AI_OFF
	can_have_ai = FALSE
	sentience_type = SENTIENCE_BOSS
	del_on_death = FALSE
	deathmessage = "гаснет и медленно растворяется звёздной пылью."
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	healable = FALSE
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	light_range = 3
	light_power = 1
	light_color = "#c9a6ff"
	vore_active = FALSE
	vore_flags = NONE
	var/datum/weakref/finale_ref
	COOLDOWN_DECLARE(beam_cooldown)

/mob/living/simple_animal/heretic_stargazer/Initialize(mapload, datum/eldritch_knowledge/final_eldritch/cosmic_final/finale)
	. = ..()
	if(QDELETED(finale))
		return INITIALIZE_HINT_QDEL
	finale_ref = WEAKREF(finale)
	ADD_TRAIT(src, TRAIT_SPACEWALK, INNATE_TRAIT)
	START_PROCESSING(SSprocessing, src)

/mob/living/simple_animal/heretic_stargazer/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	deltimer(charge_timer)
	QDEL_NULL(hand_glow)
	report_loss()
	finale_ref = null
	if(mind && !mind.key)
		QDEL_NULL(mind)
	return ..()

/mob/living/simple_animal/heretic_stargazer/proc/report_loss()
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = finale_ref?.resolve()
	finale?.stargazer_lost(src)

/mob/living/simple_animal/heretic_stargazer/death(gibbed)
	if(stat == DEAD)
		return ..()
	STOP_PROCESSING(SSprocessing, src)
	SSmove_manager.stop_looping(src)
	. = ..()
	report_loss()
	if(QDELETED(src))
		return
	playsound(src, 'modular_bluemoon/sound/heretic/cosmic_expansion.ogg', 50, TRUE)
	QDEL_IN(src, HERETIC_STARGAZER_FADE_TIME)
	collapse(HERETIC_STARGAZER_FADE_TIME)

/mob/living/simple_animal/heretic_stargazer/proc/dissolve()
	if(QDELETED(src))
		return
	var/turf/place = get_turf(src)
	if(place)
		new /obj/effect/temp_visual/heretic_path_feedback(place, "cosmic_cloud", "#7fabc9", 10)
		visible_message(span_warning("[src] рассыпается звёздной пылью."))
	var/look = appearance
	qdel(src)
	if(place)
		new /obj/effect/temp_visual/heretic_stargazer_remnant(place, look, HERETIC_STARGAZER_FADE_TIME)

/mob/living/simple_animal/heretic_stargazer/process(delta_time)
	var/datum/eldritch_knowledge/final_eldritch/cosmic_final/finale = finale_ref?.resolve()
	var/mob/living/master = finale?.applied_body
	if(finale?.stargazer != src || QDELETED(master) || master.stat == DEAD)
		dissolve()
		return
	if(client || stat != CONSCIOUS)
		return
	keep_up(master)
	if(!try_fire(master))
		plan_charge()

/mob/living/simple_animal/heretic_stargazer/proc/keep_up(mob/living/master)
	var/turf/master_turf = get_turf(master)
	if(!master_turf)
		return
	if(z != master_turf.z || get_dist(src, master_turf) > HERETIC_STARGAZER_LEASH)
		SSmove_manager.stop_looping(src)
		var/turf/from = get_turf(src)
		var/look = appearance
		new /obj/effect/temp_visual/heretic_path_feedback(from, "cosmic_cloud", "#7fabc9", 8)
		forceMove(master_turf)
		new /obj/effect/temp_visual/heretic_path_feedback(master_turf, "cosmic_ring", "#b7e4ff", 8)
		leap(from, look)
		return
	if(get_dist(src, master_turf) <= HERETIC_STARGAZER_FOLLOW_DISTANCE)
		SSmove_manager.stop_looping(src)
		return
	SSmove_manager.jps_move(src, master, HERETIC_STARGAZER_MOVE_DELAY, repath_delay = HERETIC_STARGAZER_REPATH_DELAY, max_path_length = HERETIC_STARGAZER_LEASH * 2, minimum_distance = HERETIC_STARGAZER_FOLLOW_DISTANCE)

/mob/living/simple_animal/heretic_stargazer/proc/line_clear(atom/target)
	var/turf/previous
	for(var/turf/tile as anything in get_line(get_turf(src), get_turf(target)))
		if(!heretic_line_tile_open(tile))
			return FALSE
		if(previous && previous.x != tile.x && previous.y != tile.y)
			if(!heretic_line_tile_open(locate(previous.x, tile.y, tile.z)) || !heretic_line_tile_open(locate(tile.x, previous.y, tile.z)))
				return FALSE
		previous = tile
	return TRUE

/mob/living/simple_animal/heretic_stargazer/proc/pick_target(mob/living/master)
	var/mob/living/chosen
	var/best_distance
	for(var/mob/living/candidate in range(HERETIC_STARGAZER_RANGE, src))
		// range() - квадрат, луч летит по кругу: углы квадрата ему недоступны.
		var/distance = get_dist_euclidian(src, candidate)
		if(distance > HERETIC_STARGAZER_RANGE || (chosen && distance >= best_distance) || candidate.stat != CONSCIOUS || !(iscarbon(candidate) || issilicon(candidate) || candidate.client || (ishostile(candidate) && !master.faction_check_mob(candidate))))
			continue
		if(!heretic_can_affect(master, candidate, chargecost = 0) || !line_clear(candidate))
			continue
		chosen = candidate
		best_distance = distance
	return chosen

/mob/living/simple_animal/heretic_stargazer/proc/try_fire(mob/living/master)
	if(stat != CONSCIOUS || !isturf(loc) || !COOLDOWN_FINISHED(src, beam_cooldown))
		return FALSE
	var/mob/living/victim = pick_target(master)
	if(!victim)
		return FALSE
	COOLDOWN_START(src, beam_cooldown, HERETIC_STARGAZER_BEAM_COOLDOWN)
	var/obj/item/projectile/heretic_stargazer_ray/ray = new(get_turf(src))
	ray.firer = src
	ray.fired_from = src
	ray.preparePixelProjectile(victim, src)
	ray.fire()
	playsound(src, 'modular_bluemoon/sound/heretic/cosmic_energy.ogg', 40, TRUE)
	discharge()
	return TRUE

/obj/item/projectile/heretic_stargazer_ray
	name = "starlight ray"
	icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi'
	icon_state = "cosmic_beam"
	hitscan = TRUE
	damage = HERETIC_STARGAZER_BEAM_DAMAGE
	damage_type = BURN
	flag = LASER
	range = HERETIC_STARGAZER_RANGE + 1
	hitsound = 'modular_bluemoon/sound/heretic/cosmic_energy.ogg'
	hitscan_light_color_override = "#c9a6ff"

/obj/item/projectile/heretic_stargazer_ray/prehit_pierce(atom/target)
	if(!isliving(target))
		return ..()
	var/mob/living/victim = target
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		return PROJECTILE_PIERCE_PHASE
	if(victim.check_magic_resistance(tinfoil = TRUE, chargecost = 1))
		victim.visible_message(span_warning("Звёздный луч гаснет, едва коснувшись [victim]."))
		return PROJECTILE_DELETE_WITHOUT_HITTING
	return ..()

/obj/item/projectile/heretic_stargazer_ray/on_hit(atom/target, blocked = FALSE, pierce_hit)
	firer?.Beam(target, icon_state = "cosmic_beam", icon = 'modular_bluemoon/icons/obj/heretic_effects.dmi', time = HERETIC_STARGAZER_RAY_FLASH, maxdistance = HERETIC_STARGAZER_RANGE + 2)
	if(isliving(target))
		new /obj/effect/temp_visual/heretic_path_feedback(get_turf(target), "cosmic_ring", "#b7e4ff", 6)
	. = ..()
	heretic_stargazer_beam_fx(firer, target)

#undef HERETIC_STARGAZER_FOLLOW_DISTANCE
#undef HERETIC_STARGAZER_LEASH
#undef HERETIC_STARGAZER_MOVE_DELAY
#undef HERETIC_STARGAZER_REPATH_DELAY
#undef HERETIC_STARGAZER_FADE_TIME
#undef HERETIC_STARGAZER_RAY_FLASH
