
#define ANTAG_TRAINING_SWARMER_SHEETS 10
#define ANTAG_TRAINING_SWARMER_DISPERSE_TIME (3 SECONDS)
#define ANTAG_TRAINING_SWARMER_METAL 150

/datum/antag_training_program/creature/swarmer
	name = "Сворм"
	desc = "Свармеры: ядро, общие запасы, смена корпусов, постройки и переработка."
	icon = "recycle"
	color = "teal"
	category = "Существа"
	learn = "Ресурсы роя|Смена корпуса|Разбор машин|Строительство|Перенос существ"
	difficulty = 2
	mob_type = /mob/living/simple_animal/hostile/swarmer/basic
	antag_type = /datum/antagonist/swarmer_training
	choice_prompt = "Корпус свармера"
	choices = list(
		/mob/living/simple_animal/hostile/swarmer/basic = "дрон",
		/mob/living/simple_animal/hostile/swarmer/generalist = "универсал",
		/mob/living/simple_animal/hostile/swarmer/rover = "ровер",
		/mob/living/simple_animal/hostile/swarmer/builder = "строитель",
		/mob/living/simple_animal/hostile/swarmer/combat = "боец",
		/mob/living/simple_animal/hostile/swarmer/mega = "мегасвармер",
	)
	options = list("Ресурсы до максимума", "Материалы", "Машина на разбор", "Цель для переноса")
	var/datum/team/swarmer_team/training_team

/datum/antag_training_program/creature/swarmer/Destroy()
	QDEL_NULL(training_team)
	return ..()

/datum/antag_training_program/creature/swarmer/spawn_creature_body(datum/antag_training_session/session, turf/where)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/body = .
	if(!istype(body))
		return
	if(!training_team)
		training_team = new
		training_team.training = TRUE
	if(QDELETED(training_team.swarmer_core))
		var/turf/core_turf = get_turf(body)
		for(var/turf/open/neighbor in orange(1, body))
			if(session.arena.owns_area(get_area(neighbor)) && !neighbor.is_blocked_turf())
				core_turf = neighbor
				break
		var/obj/structure/swarmer/core/core = new(core_turf, training_team)
		core.register_training_atom()
		core.training_owner = WEAKREF(session)
	body.join_swarm(training_team)
	refill(body)

/datum/antag_training_program/creature/swarmer/refill(mob/body)
	var/mob/living/simple_animal/hostile/swarmer/swarmer = body
	if(!istype(swarmer))
		return
	swarmer.revive(full_heal = TRUE, admin_revive = TRUE)
	if(training_team)
		training_team.set_metal(ANTAG_TRAINING_SWARMER_METAL)

/datum/antag_training_program/creature/swarmer/handle_choice(datum/antag_training_session/session, mob/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/hostile/swarmer/body = user
	if(!istype(body) || body != session.current_body)
		return FALSE
	switch(option)
		if("Ресурсы до максимума")
			refill(body)
		if("Материалы")
			return issue_materials(session, body)
		if("Машина на разбор")
			return place_machine(session, body)
		if("Цель для переноса")
			return !!spawn_prey_near(session, body, "human", "Перейдите в сектор или на площадку.")
		else
			return FALSE
	return TRUE

/datum/antag_training_program/creature/swarmer/proc/issue_materials(datum/antag_training_session/session, mob/living/simple_animal/hostile/swarmer/body)
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/list/spots = list()
	for(var/turf/open/spot in orange(1, body))
		if(session.arena.owns_area(get_area(spot)) && !spot.is_blocked_turf())
			spots += spot
	if(!length(spots))
		spots += get_turf(body)
	var/issued = 0
	if(session.arena.issue_item(/obj/item/stack/sheet/metal, spots[1], ANTAG_TRAINING_SWARMER_SHEETS, session))
		issued++
	if(session.arena.issue_item(/obj/item/stack/sheet/glass, spots[min(2, length(spots))], ANTAG_TRAINING_SWARMER_SHEETS, session))
		issued++
	if(!issued)
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	to_chat(body, span_notice("Рядом лежат металл и стекло. Клик по стопке забирает несколько листов."))
	return TRUE

/datum/antag_training_program/creature/swarmer/proc/place_machine(datum/antag_training_session/session, mob/living/simple_animal/hostile/swarmer/body)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(body)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(body, span_warning("Машина встаёт рядом с вами, а в центре и переходах её нет: перейдите в сектор или на площадку."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	arena.prune_supplies()
	var/turf/spot
	for(var/turf/open/candidate in orange(1, body))
		if(!arena.construction_error(candidate))
			spot = candidate
			break
	if(!spot)
		to_chat(body, span_warning(arena.construction_error(get_step(body, body.dir)) || "Вокруг нет свободного пола. Отойдите от стен и вещей."))
		return FALSE
	var/obj/machinery/recharger/machine = new(spot)
	arena.track_supply(machine, session)
	arena.placed_structures += WEAKREF(machine)
	to_chat(body, span_notice("Рядом стоит зарядник оружия. Клик по нему разбирает его, пока вы стоите на месте, а металл потом можно переработать."))
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/training_consume_refusal(atom/target)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena || arena.finished || arena.resetting)
		return "Дождитесь окончания сброса полигона."
	var/datum/antag_training_session/session = arena.session_of(src)
	if(isturf(target))
		var/area/antag_training/sector/sector_area = get_area(target)
		if(istype(sector_area) && arena.owns_area(sector_area))
			return arena.foreign_part_refusal(target, session, src)
		return "Стены и пол ядра полигона не разбираются. Ешьте свои материалы и машины или разбирайте секторы."
	var/atom/movable/thing = target
	if(thing.training_origin?.resolve() != arena)
		return "Это не часть полигона."
	if(istype(thing, /obj/structure/sign/antag_training_board) || istype(thing, /obj/structure/antag_training_exit))
		return "Стенды и платформы полигона не разбираются."
	var/foreign = arena.foreign_part_refusal(thing, session, src)
	if(foreign)
		return foreign
	if(isliving(thing) || thing.training_owner || istype(get_area(thing), /area/antag_training/sector))
		return null
	return "Обстановку ядра полигона не разобрать. Ешьте свои материалы и машины или разбирайте секторы."

/mob/living/simple_animal/hostile/swarmer/proc/training_refuses(atom/target)
	if(!target || isliving(target))
		return FALSE
	var/refusal = training_consume_refusal(target)
	if(!refusal)
		return FALSE
	to_chat(src, span_warning(refusal))
	return TRUE

/mob/living/simple_animal/hostile/swarmer/proc/training_disperse(mob/living/target)
	if(target == src)
		return
	var/refusal = training_consume_refusal(target)
	if(refusal)
		to_chat(src, span_warning(refusal))
		return
	to_chat(src, span_info("Переносим это существо в другую часть полигона. Стойте на месте."))
	if(!do_mob(src, target, ANTAG_TRAINING_SWARMER_DISPERSE_TIME) || training_consume_refusal(target))
		return
	var/turf/destination = training_disperse_turf(target)
	if(!destination)
		to_chat(src, span_warning("На полигоне нет безопасного свободного места, куда можно перенести цель."))
		return
	var/mob/living/carbon/human/human_target = target
	if(ishuman(target) && !human_target.handcuffed)
		human_target.handcuffed = new /obj/item/restraints/handcuffs/energy/used(human_target)
		human_target.update_handcuffed()
		log_combat(src, human_target, "handcuffed")
	do_sparks(4, FALSE, target)
	playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
	do_teleport(target, destination, 0, channel = TELEPORT_CHANNEL_BLUESPACE)

// Выбираем дальний безопасный сектор, отдавая предпочтение зонам без других участников.
/mob/living/simple_animal/hostile/swarmer/proc/training_disperse_turf(mob/living/target)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena)
		return null
	var/datum/antag_training_session/session = arena.session_of(src)
	var/here = arena.match_zone(target)
	var/turf/core_turf = get_turf(team?.swarmer_core) || get_turf(src)
	var/core_zone = arena.match_zone(core_turf)
	var/turf/farthest
	var/turf/fallback
	var/max_distance = -1
	var/fallback_distance = -1
	for(var/zone_id in arena.zones)
		if(zone_id == "hub" || zone_id == here || zone_id == core_zone)
			continue
		var/list/zone = arena.zones[zone_id]
		var/turf/spot
		for(var/turf/center in list(zone["target"], zone["spawn"]))
			var/turf/candidate = arena.free_spot(center, zone["bounds"])
			if(candidate && is_safe_turf(candidate) && target.training_move_allowed(candidate))
				spot = candidate
				break
		if(!spot)
			continue
		var/occupied = FALSE
		for(var/datum/antag_training_session/member as anything in arena.members)
			var/turf/member_turf = get_turf(member.current_body)
			if(member != session && member_turf && arena.inside_bounds(member_turf, zone["bounds"]))
				occupied = TRUE
				break
		var/distance = get_dist_euclidian(core_turf, spot)
		if(!occupied && distance > max_distance)
			max_distance = distance
			farthest = spot
		else if(occupied && distance > fallback_distance)
			fallback_distance = distance
			fallback = spot
	return farthest || fallback

/datum/antagonist/swarmer_training
	name = "Учебный сворм"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	ui_name = null
	var/datum/antag_training_session/training

/datum/antagonist/swarmer_training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/swarmer_training/threat()
	return 0

/datum/antagonist/swarmer_training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/swarmer_training/proc/brief()
	to_chat(owner.current, span_notice("ЛКМ перерабатывает материалы. ПКМ переносит учебную цель в другую часть полигона. Выбирайте корпуса через ядро или пульт полигона. Запасы учебного роя принадлежат вашему сеансу."))

/datum/antagonist/swarmer_training/Destroy()
	training = null
	return ..()

#undef ANTAG_TRAINING_SWARMER_SHEETS
#undef ANTAG_TRAINING_SWARMER_DISPERSE_TIME
#undef ANTAG_TRAINING_SWARMER_METAL
