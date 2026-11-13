#define SWARMER_ACP_RANGE_DAMAGE_MODIFIER 2
#define SWARMER_ACP_SLOWED_MODIFIER 2
#define SWARMER_ACP_NO_SIGHT_DAMAGE_MULTIPLIER 0.5

/obj/structure/swarmer/acp_turret
	name = "swarmer ACP turret"
	desc = "Стационарная установка \"Свармеров\", способная оглушать и влиять на магнитное поле целей."
	icon_state = "turret_acp"
	swarmer_examine = "Бьёт всех по области, нанося урон стамине и останавливая метаболизацию реагентов. Не работает в открученном состоянии."
	max_integrity = 200
	var/static/mutable_appearance/strike_overlay
	var/strike_icon_state = "turret_acp_strike"
	COOLDOWN_DECLARE(cooldown)
	var/cooldown_after_strike = 6 SECONDS
	var/range = 3
	var/damage = 15
	var/slowed_chance = 60
	var/slowed_duration = 2 SECONDS
	var/knockdown_duration = 5 SECONDS
	var/metabolization_block_duration = 10 SECONDS
	var/list/processing_targets = list()

// Встроенная установка мегасвармера учитывается отдельно от стационарных построек.
/obj/structure/swarmer/acp_turret/mounted

/obj/structure/swarmer/acp_turret/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	if(!strike_overlay)
		strike_overlay = mutable_appearance('icons/effects/swarmer.dmi', "acp_effect", ABOVE_ALL_MOB_LAYER)
	proximity_monitor = new(src, range)

/obj/structure/swarmer/acp_turret/Destroy(force)
	processing_targets = null
	QDEL_NULL(proximity_monitor)
	if(datum_flags & DF_ISPROCESSING)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/swarmer/acp_turret/emp_act(severity)
	. = ..()
	if(!QDELETED(src) && !(. & EMP_PROTECT_SELF))
		COOLDOWN_START(src, cooldown, cooldown_after_strike)

/obj/structure/swarmer/acp_turret/HasProximity(atom/movable/AM)
	handle_interloper(AM)

/obj/structure/swarmer/acp_turret/proc/handle_interloper(atom/movable/entity)
	if(entity.invisibility > SEE_INVISIBLE_LIVING)
		return

	if(!isliving(entity) || isswarmer(entity))
		return

	processing_targets[entity] = TRUE
	if(!(datum_flags & DF_ISPROCESSING))
		START_PROCESSING(SSobj, src)

/obj/structure/swarmer/acp_turret/process(seconds_per_tick)
	if(!length(processing_targets))
		return PROCESS_KILL

	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		processing_targets.Cut()
		return PROCESS_KILL
	for(var/mob/mob as anything in processing_targets)
		var/turf/mob_turf = get_turf(mob)
		if(QDELETED(mob) || !mob_turf || mob_turf.z != our_turf.z || get_dist(our_turf, mob_turf) > range)
			processing_targets -= mob

	if(!length(processing_targets))
		return PROCESS_KILL
	if(!anchored || !COOLDOWN_FINISHED(src, cooldown))
		return

	strike()
	COOLDOWN_START(src, cooldown, cooldown_after_strike)

/obj/structure/swarmer/acp_turret/proc/strike()
	flick(strike_icon_state, src)
	var/turf/our_turf = get_turf(src)
	new /obj/effect/temp_visual/acp_stomp(our_turf, range)
	for(var/mob/living/target as anything in processing_targets)
		target.apply_status_effect(/datum/status_effect/swarmer_metabolism_block, metabolization_block_duration, strike_overlay)
		apply_range_based_effects(target)

/obj/structure/swarmer/acp_turret/proc/apply_range_based_effects(mob/living/target)
	var/modifier = range - get_dist(src, target)
	var/final_knockdown_duration = knockdown_duration * modifier
	target.Knockdown(final_knockdown_duration)

	var/increase_modifier = max((range - 1), 1)
	var/slow_chance_increase_per_tile = (100 - slowed_chance) * (1 / increase_modifier)
	var/slow_duration_increase_per_tile = slowed_duration * (1 / increase_modifier)
	var/final_slowed_chance = round(slowed_chance + modifier * slow_chance_increase_per_tile)
	var/final_slowed_duration = round(slowed_duration + modifier * slow_duration_increase_per_tile)
	if(prob(final_slowed_chance))
		target.Slowed(final_slowed_duration, SWARMER_ACP_SLOWED_MODIFIER)

	var/final_damage = damage + damage * modifier * SWARMER_ACP_RANGE_DAMAGE_MODIFIER
	if(!can_see(src, target, range))
		final_damage *= SWARMER_ACP_NO_SIGHT_DAMAGE_MULTIPLIER

	if(!iscarbon(target))
		target.apply_damage(final_damage, BURN, blocked = target.getarmor(null, ENERGY))
		return

	target.apply_damage(final_damage * SWARMER_STAMINA_SCALE, STAMINA, blocked = target.getarmor(null, ENERGY))

/obj/effect/temp_visual/acp_stomp
	icon = 'icons/effects/swarmer_acp.dmi'
	icon_state = "swarmer_acp"
	pixel_y = -16
	pixel_x = -16
	duration = 0.8 SECONDS

/obj/effect/temp_visual/acp_stomp/Initialize(mapload, range = 1)
	. = ..()
	var/matrix/M = matrix() * 0.5
	transform = M
	animate(src, transform = M * 2 * (range + 1), time = duration, alpha = 0)
	playsound(loc, 'sound/swarmer/acp_turret.ogg', 100, TRUE)

#undef SWARMER_ACP_RANGE_DAMAGE_MODIFIER
#undef SWARMER_ACP_SLOWED_MODIFIER
#undef SWARMER_ACP_NO_SIGHT_DAMAGE_MULTIPLIER
