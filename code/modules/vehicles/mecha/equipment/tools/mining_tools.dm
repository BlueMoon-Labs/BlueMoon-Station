
// Drill, Diamond drill, Mining scanner

#define DRILL_BASIC 1
#define DRILL_HARDENED 2


/obj/item/mecha_parts/mecha_equipment/drill
	name = "exosuit drill"
	desc = "Оборудование для инженерных и боевых экзокостюмов. Это дрель, что пронзит небеса!"
	icon_state = "mecha_drill"
	equip_cooldown = 15
	energy_drain = 10
	force = 15
	harmful = TRUE
	range = MECHA_MELEE
	tool_behaviour = TOOL_DRILL
	toolspeed = 0.9
	mech_flags = EXOSUIT_MODULE_WORKING | EXOSUIT_MODULE_COMBAT
	compatible_mecha_types = MECHA_TYPE_WORKING | MECHA_TYPE_COMBAT
	var/drill_delay = 7
	var/drill_level = DRILL_BASIC
	var/is_drilling = 0;

/obj/item/mecha_parts/mecha_equipment/drill/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/butchering, 50, 100, null, null, TRUE)

/obj/item/mecha_parts/mecha_equipment/drill/action(mob/source, atom/target, params)
	//Are we already drilling?
	if(is_drilling)
		return
	is_drilling = 1
	//Is the mech not in a position to start drilling, maybe due to damage? Is the tile literal space?
	if(!action_checks(target) || isspaceturf(target))
		is_drilling = 0
		return
	if(isobj(target))
		var/obj/target_obj = target
		if(target_obj.resistance_flags & UNACIDABLE)
			is_drilling = 0
			return
	target.visible_message(span_warning("[chassis] начинает бурить [target]."), \
				span_userdanger("[chassis] начинает бурить [target]..."), \
				span_hear("Вы слышите звук бурения."))
	if(do_after_cooldown(target, source))
		log_message("Начато бурение [target]", LOG_MECHA)
		//If it's a turf, activate special drill through code
		if(isturf(target))
			var/turf/T = target
			T.drill_act(src, source)
			is_drilling = 0
			log_message("Бурение [target] остановлено", LOG_MECHA)
			target.visible_message(span_warning("[chassis] заканчивает бурить [target]."), \
							span_userdanger("[chassis] заканчивает бурить [target]..."), \
							span_hear("Звук бурения стихает."))
			return
		while(do_after_mecha(target, source, drill_delay))
			//Let's make sure they're still within range yeah?
			if (!in_range(target,source))
				is_drilling = 0
				log_message("Бурение [target] остановлено", LOG_MECHA)
				target.visible_message(span_warning("[chassis] прекращает бурить [target]."), \
							span_userdanger("[chassis] прекращает бурить [target]..."), \
							span_hear("Звук бурения стихает."))
				return
			if(isliving(target))
				drill_mob(target, source)
				playsound(src,'sound/weapons/drill.ogg',40,TRUE)
			else if(isobj(target))
				var/obj/O = target
				if(!(O.drill_act(src, source)))
					break
				playsound(src,'sound/weapons/drill.ogg',40,TRUE)
			else
				is_drilling = 0
				log_message("Бурение [target] остановлено", LOG_MECHA)
				target.visible_message(span_warning("[chassis] прекращает бурить [target]."), \
							span_userdanger("[chassis] прекращает бурить [target]..."), \
							span_hear("Звук бурения стихает."))
				return
	is_drilling = 0
	return ..()

/turf/proc/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill, mob/user)
	return

/obj/proc/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill, mob/user)
	take_damage(drill.force, BRUTE, 0, FALSE, get_dir(drill.chassis, src))
	return TRUE

/turf/closed/wall/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill, mob/user)
	if(drill.do_after_mecha(src, user, 60 / drill.drill_level))
		drill.log_message("[src] пробурен насквозь", LOG_MECHA)
		dismantle_wall(TRUE, FALSE)

/turf/closed/wall/r_wall/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill, mob/user)
	if(drill.drill_level >= DRILL_HARDENED)
		if(drill.do_after_mecha(src, user, 120 / drill.drill_level))
			drill.log_message("[src] пробурен насквозь", LOG_MECHA)
			dismantle_wall(TRUE, FALSE)
	else
		to_chat(user, "[icon2html(src, user)][span_danger("[src] слишком прочен, чтобы пробурить его.")]")

/turf/closed/mineral/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill, mob/user)
	for(var/turf/closed/mineral/M in range(drill.chassis,1))
		if(get_dir(drill.chassis,M)&drill.chassis.dir)
			M.gets_drilled()
	drill.log_message("[user] пробуривает [src] насквозь", LOG_MECHA)
	drill.move_ores()

/turf/open/floor/plating/asteroid/drill_act(obj/item/mecha_parts/mecha_equipment/drill/drill)
	for(var/turf/open/floor/plating/asteroid/M in range(1, drill.chassis))
		if((get_dir(drill.chassis,M)&drill.chassis.dir) && !M.dug)
			M.getDug()
	drill.log_message("[src] пробурен насквозь", LOG_MECHA)
	drill.move_ores()


/obj/item/mecha_parts/mecha_equipment/drill/proc/move_ores()
	if(locate(/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp) in chassis.equipment && istype(chassis, /obj/vehicle/sealed/mecha/working/ripley))
		var/obj/vehicle/sealed/mecha/working/ripley/R = chassis //we could assume that it's a ripley because it has a clamp, but that's ~unsafe~ and ~bad practice~
		R.collect_ore()

/obj/item/mecha_parts/mecha_equipment/drill/attach(obj/vehicle/sealed/mecha/M)
	..()
	var/datum/component/butchering/butchering = src.GetComponent(/datum/component/butchering)
	butchering.butchering_enabled = TRUE

/obj/item/mecha_parts/mecha_equipment/drill/detach(atom/moveto)
	..()
	var/datum/component/butchering/butchering = src.GetComponent(/datum/component/butchering)
	butchering.butchering_enabled = FALSE

/obj/item/mecha_parts/mecha_equipment/drill/proc/drill_mob(mob/living/target, mob/user)
	target.visible_message(span_danger("[chassis] бурит [target] с помощью [src]!"), \
						span_userdanger("[chassis] бурит вас с помощью [src]!"))
	log_combat(user, target, "drilled", "[name]", "(INTENT: [uppertext(user.a_intent)]) (DAMTYPE: [uppertext(damtype)])")
	if(target.stat == DEAD && target.getBruteLoss() >= 200)
		log_combat(user, target, "gibbed", name)
		if(LAZYLEN(target.butcher_results) || LAZYLEN(target.guaranteed_butcher_results))
			var/datum/component/butchering/butchering = src.GetComponent(/datum/component/butchering)
			butchering.Butcher(chassis, target)
		else
			target.gib()
	else
		//drill makes a hole
		var/obj/item/bodypart/target_part = target.get_bodypart(ran_zone(BODY_ZONE_CHEST))
		target.apply_damage(10, BRUTE, BODY_ZONE_CHEST, target.run_armor_check(target_part, MELEE))

		//blood splatters
		var/splatter_dir = get_dir(chassis, target)
		if(isalien(target))
			new /obj/effect/temp_visual/dir_setting/bloodsplatter/xenosplatter(target.drop_location(), splatter_dir)
		else
			if(ishuman(target))
				var/mob/living/carbon/human/H = target
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(target.drop_location(), splatter_dir, H.dna.species.exotic_blood_color)
			else
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(target.drop_location(), splatter_dir)

		//organs go everywhere
		if(target_part && prob(10 * drill_level))
			target_part.dismember(BRUTE)

/obj/item/mecha_parts/mecha_equipment/drill/diamonddrill
	name = "diamond-tipped exosuit drill"
	desc = "Оборудование для инженерных и боевых экзокостюмов. Улучшенная версия дрели, что пронзит небеса!"
	icon_state = "mecha_diamond_drill"
	equip_cooldown = 10
	drill_delay = 4
	drill_level = DRILL_HARDENED
	force = 15
	toolspeed = 0.7

/obj/item/mecha_parts/mecha_equipment/mining_scanner
	name = "exosuit mining scanner"
	desc = "Оборудование для рабочих экзокостюмов. Автоматически проверяет окружающую породу на наличие полезных минералов."
	icon_state = "mecha_analyzer"
	selectable = 0
	equip_cooldown = 15
	mech_flags = EXOSUIT_MODULE_WORKING
	compatible_mecha_types = MECHA_TYPE_WORKING
	var/scanning_time = 0

/obj/item/mecha_parts/mecha_equipment/mining_scanner/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSfastprocess, src)

/obj/item/mecha_parts/mecha_equipment/mining_scanner/process()
	if(!loc)
		STOP_PROCESSING(SSfastprocess, src)
		qdel(src)
	if(chassis && scanning_time <= world.time)
		if(!LAZYLEN(chassis?.occupants))
			return
		scanning_time = world.time + equip_cooldown
		mineral_scan_pulse(get_turf(src))

#undef DRILL_BASIC
#undef DRILL_HARDENED
