/obj/structure/swarmer
	name = "swarmer structure"
	desc = "Вы не должны это видеть."
	icon = 'icons/obj/swarmer.dmi'
	hud_possible = list(DIAG_HUD)
	resistance_flags = FIRE_PROOF | UNACIDABLE | ACID_PROOF
	light_color = LIGHT_COLOR_CYAN
	max_integrity = 30
	anchored = TRUE
	density = TRUE
	var/lon_range = 1
	var/swarmer_examine
	var/projectiles_pass = TRUE
	var/swarmers_pass = FALSE
	var/datum/team/swarmer_team/team

/obj/structure/swarmer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	team = swarm_team
	team?.add_structure(src)
	set_light(lon_range)

	prepare_huds()
	var/datum/atom_hud/data/diagnostic/diag_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	diag_hud?.add_to_hud(src)
	diag_hud_set_health()

/obj/structure/swarmer/Destroy(force)
	team?.remove_structure(src)
	team = null
	return ..()

/obj/structure/swarmer/proc/diag_hud_set_health()
	set_hud_image_state(DIAG_HUD, "huddiag[RoundDiagBar(obj_integrity/max_integrity)]")

/obj/structure/swarmer/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(. && !QDELETED(src))
		diag_hud_set_health()
		SEND_SIGNAL(src, COMSIG_SWARMER_CORE_DAMAGED)

/obj/structure/swarmer/repair_damage(amount)
	var/old_integrity = obj_integrity
	obj_integrity = min(max_integrity, obj_integrity + amount)
	diag_hud_set_health()
	return obj_integrity - old_integrity

/obj/structure/swarmer/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = NONE)
	switch(damage_type)
		if(BRUTE)
			playsound(src, 'sound/weapons/Egloves.ogg', 80, TRUE)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, TRUE)

/obj/structure/swarmer/proc/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!anchored)
		swarmer.balloon_alert(swarmer, "не прикручено!")
		return FALSE
	return TRUE

/obj/structure/swarmer/proc/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(obj_integrity == max_integrity)
		swarmer.balloon_alert(swarmer, "не требует починки!")
		return

	swarmer.balloon_alert_to_viewers("чинит...", "починка...")
	if(!do_after(swarmer, SWARMER_REPAIR_DELAY(swarmer), src))
		swarmer.balloon_alert(swarmer, "сбито!")
		return
	if(!team?.adjust_metal(-SWARMER_REPAIR_COST(swarmer)))
		swarmer.balloon_alert(swarmer, "недостаточно ресурсов!")
		return
	if(!repair_damage(SWARMER_REPAIR_AMOUNT(swarmer)))
		swarmer.balloon_alert(swarmer, "полностью починено!")

/obj/structure/swarmer/proc/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!is_builderswarmer(swarmer))
		return FALSE

	var/required_range = GLOB.swarmer_objects_minimum_distance[type]
	if(!anchored && required_range && team && !team.check_objs_of_type_in_range(get_turf(src), required_range, type))
		swarmer.balloon_alert(swarmer, "слишком близко!")
		to_chat(swarmer, span_warning("Минимальное расстояние между [name] — [required_range]!"))
		return FALSE

	var/message = anchored ? "открепляем..." : "прикрепляем..."
	swarmer.balloon_alert(swarmer, message)
	if(!do_after(swarmer, 3 SECONDS, src))
		swarmer.balloon_alert(swarmer, "сбито!")
		return FALSE

	if(!anchored && required_range && team && !team.check_objs_of_type_in_range(get_turf(src), required_range, type))
		swarmer.balloon_alert(swarmer, "слишком близко!")
		to_chat(swarmer, span_warning("Минимальное расстояние между [name] — [required_range]!"))
		return FALSE

	swarmer.balloon_alert(swarmer, "успех!")
	playsound(loc, 'sound/effects/empulse.ogg', 75, TRUE)
	set_anchored(!anchored)
	update_icon(UPDATE_ICON_STATE)
	return TRUE

/obj/structure/swarmer/proc/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
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

/obj/structure/swarmer/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(is_swarmerprojectile(mover) && projectiles_pass)
		return TRUE
	if(isswarmer(mover) && swarmers_pass)
		return TRUE

/obj/structure/swarmer/emp_act(severity)
	..()
	take_damage(SWARMER_EMP_DAMAGE(severity))

/obj/structure/swarmer/examine(mob/user)
	. = ..()
	if(swarmer_examine)
		. += span_swarmer(swarmer_examine)
