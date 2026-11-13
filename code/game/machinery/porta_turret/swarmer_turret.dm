/obj/machinery/porta_turret/swarmer
	name = "energy turret"
	desc = "Вы это не должны видеть. Напишите баг-репорт, если увидели."
	icon = 'icons/obj/swarmer.dmi'
	icon_state = "barricade"
	invisibility = 0
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_color = LIGHT_COLOR_CYAN
	stun_projectile = /obj/item/projectile/beam/disabler/swarmer
	lethal_projectile = /obj/item/projectile/beam/disabler/swarmer
	stun_projectile_sound = 'sound/weapons/laser2.ogg'
	lethal_projectile_sound = 'sound/weapons/laser2.ogg'
	installation = null
	always_up = TRUE
	use_power = NO_POWER_USE
	has_cover = FALSE
	raised = TRUE
	density = TRUE
	shot_delay = 1 SECONDS

	faction = list(ROLE_SWARMER)
	turret_flags = TURRET_FLAG_SHOOT_ALL | TURRET_FLAG_SHOOT_BORGS | TURRET_FLAG_SHOOT_ANOMALOUS
	mode = TURRET_LETHAL
	req_access = list()
	hud_possible = list(DIAG_HUD)
	armor_type = /datum/armor/porta_turret/swarmer
	var/datum/team/swarmer_team/team

/datum/armor/porta_turret/swarmer
	bullet = 30 + SWARMER_BULLET_ARMOR_BONUS
	laser = 30 + SWARMER_LASER_ARMOR_BONUS

/obj/machinery/porta_turret/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	team = swarm_team
	team?.add_structure(src)
	prepare_huds()
	diag_hud_set_health()
	var/datum/atom_hud/data/diagnostic/diag_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	diag_hud?.add_to_hud(src)

/obj/machinery/porta_turret/swarmer/Destroy()
	team?.remove_structure(src)
	team = null
	return ..()

/obj/machinery/porta_turret/swarmer/update_icon_state()
	return

/obj/machinery/porta_turret/swarmer/proc/diag_hud_set_health()
	set_hud_image_state(DIAG_HUD, "huddiag[RoundDiagBar(obj_integrity/max_integrity)]")

/obj/machinery/porta_turret/swarmer/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(. && !QDELETED(src))
		diag_hud_set_health()

/obj/machinery/porta_turret/swarmer/repair_damage(amount)
	. = ..()
	if(.)
		diag_hud_set_health()

/obj/machinery/porta_turret/swarmer/proc/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	ui_interact(swarmer)

/obj/machinery/porta_turret/swarmer/proc/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(obj_integrity == max_integrity)
		swarmer.balloon_alert(swarmer, "не требует починки!")
		return

	swarmer.balloon_alert_to_viewers("чинит...", "починка!")
	if(!do_after(swarmer, SWARMER_REPAIR_DELAY(swarmer), src))
		return
	if(!team?.adjust_metal(-SWARMER_REPAIR_COST(swarmer)))
		swarmer.balloon_alert(swarmer, "недостаточно ресурсов!")
		return
	repair_damage(SWARMER_REPAIR_AMOUNT(swarmer))

/obj/machinery/porta_turret/swarmer/proc/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!is_builderswarmer(swarmer))
		return FALSE

	var/required_range = GLOB.swarmer_objects_minimum_distance[type]
	if(!anchored && required_range && team && !team.check_objs_of_type_in_range(get_turf(src), required_range, type))
		swarmer.balloon_alert(swarmer, "слишком близко!")
		to_chat(swarmer, span_warning("Минимальное расстояние между [name] — [required_range]!"))
		return FALSE

	var/message = anchored ? "открепляем..." : "прикрепляем..."
	swarmer.balloon_alert(swarmer, message)
	if(!do_after(swarmer, 5 SECONDS, src))
		swarmer.balloon_alert(swarmer, "сбито!")
		return FALSE

	if(!anchored && required_range && team && !team.check_objs_of_type_in_range(get_turf(src), required_range, type))
		swarmer.balloon_alert(swarmer, "слишком близко!")
		to_chat(swarmer, span_warning("Минимальное расстояние между [name] — [required_range]!"))
		return FALSE

	swarmer.balloon_alert(swarmer, "успех!")
	playsound(loc, 'sound/effects/empulse.ogg', 75, TRUE)
	set_anchored(!anchored)
	toggle_on(anchored)
	return

/obj/machinery/porta_turret/swarmer/proc/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!is_builderswarmer(swarmer))
		return FALSE
	var/confirm = tgui_alert(swarmer, "Вы уверены, что хотите РАЗОБРАТЬ [name]?", "Разбор структуры", list("Да", "Нет"))
	if(confirm != "Да")
		return
	swarmer.balloon_alert(swarmer, "уничтожаем...")
	if(!do_after(swarmer, 5 SECONDS, src))
		swarmer.balloon_alert(swarmer, "сбито!")
		return FALSE
	swarmer.balloon_alert(swarmer, "уничтожено!")
	var/obj/effect/temp_visual/swarmer/disintegration/disintegrate_effect = new(get_turf(src))
	disintegrate_effect.adjust_size(src)
	qdel(src)

/obj/machinery/porta_turret/swarmer/allowed(mob/M)
	return FALSE

/obj/machinery/porta_turret/swarmer/obj_break(damage_flag)
	. = ..()
	qdel(src)

/obj/machinery/porta_turret/swarmer/setup(obj/item/gun/turret_gun)
	return

/obj/machinery/porta_turret/swarmer/assess_perp(mob/living/carbon/human/perp)
	return 10

/obj/machinery/porta_turret/swarmer/add_mech_targets(list/targets, list/visible_atoms)
	for(var/obj/vehicle/sealed/mecha/mech in visible_atoms)
		if(mech.invisibility <= SEE_INVISIBLE_LIVING && can_see(base, mech, scan_range))
			targets += mech

/obj/machinery/porta_turret/swarmer/tryToShootAt(list/atom/movable/targets)
	var/list/priority_targets = list()
	var/best_priority = 0
	for(var/atom/movable/candidate as anything in targets)
		var/priority = get_target_priority(candidate)
		if(!priority || priority < best_priority)
			continue
		if(priority > best_priority)
			priority_targets.Cut()
			best_priority = priority
		priority_targets += candidate
	return ..(priority_targets)

/obj/machinery/porta_turret/swarmer/proc/get_target_priority(atom/movable/candidate)
	if(ishuman(candidate))
		var/mob/living/carbon/human/human = candidate
		return human.stat != DEAD && !IS_STAMCRIT(human) ? 4 : 0
	if(!ismecha(candidate))
		return 2

	var/obj/vehicle/sealed/mecha/mech = candidate
	var/has_friendly_pilot = FALSE
	for(var/mob/living/pilot as anything in mech.occupants)
		if(pilot.stat == DEAD || !(mech.occupants[pilot] & VEHICLE_CONTROL_DRIVE))
			continue
		if(!in_faction(pilot))
			return 3
		has_friendly_pilot = TRUE
	return has_friendly_pilot ? 0 : 1

/obj/machinery/porta_turret/swarmer/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_SELF))
		take_damage(SWARMER_EMP_DAMAGE(severity))

/obj/machinery/porta_turret/swarmer/turret
	name = "swarmer turret"
	desc = "Штурмовая энергетическая турель \"Свармеров\", способная стрелять залпом по три пули."
	icon_state = "turret_rapid"
	max_integrity = 150
	shot_delay = 1.5 SECONDS
	stun_projectile = /obj/item/projectile/beam/disabler/swarmer/weak_turret
	lethal_projectile = /obj/item/projectile/beam/disabler/swarmer/weak_turret
	projectiles_per_shot = 3
	scan_range = 6

/obj/machinery/porta_turret/swarmer/sniper
	name = "swarmer sentry"
	desc = "Снайперская энергетическая турель \"Свармеров\", способная стрелять мощным выстрелом, что пробивает целей насквозь."
	icon_state = "turret_sniper"
	max_integrity = 200
	shot_delay = 2.5 SECONDS
	stun_projectile = /obj/item/projectile/beam/disabler/swarmer/strong_turret
	lethal_projectile = /obj/item/projectile/beam/disabler/swarmer/strong_turret

