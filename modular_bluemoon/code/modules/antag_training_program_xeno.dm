/datum/antag_training_program/creature/xeno
	name = "Ксеноморф"
	category = "Существа"
	desc = "Тело ксеноморфа выбранной касты: трава, смола, кислота и нейротоксин, эволюция дрона до королевы, яйца и лицехваты на учебных целях. Улей - только ксеноморфы этого полигона, личинки из целей вылезают без игроков. Упражнение «Улей» в лаборатории: трава, стена из смолы и лицехват на цели по шагам."
	icon = "bug"
	color = "purple"
	learn = "Выбор касты|Трава, смола, кислота и нейротоксин|Эволюция от дрона до королевы|Яйца и лицехваты|Улей: трава, смола и заражение"
	difficulty = 2
	mob_type = /mob/living/carbon/alien/humanoid/drone
	antag_type = /datum/antagonist/xeno/training
	choice_prompt = "Каста"
	choices = list(
		/mob/living/carbon/alien/larva = "Личинка",
		/mob/living/carbon/alien/humanoid/drone = "Дрон",
		/mob/living/carbon/alien/humanoid/sentinel = "Страж",
		/mob/living/carbon/alien/humanoid/hunter = "Охотник",
		/mob/living/carbon/alien/humanoid/royal/praetorian = "Преторианец",
		/mob/living/carbon/alien/humanoid/royal/queen = "Королева",
	)
	options = list("Плазма до максимума", "Личинка выросла", "Цель для хаггера")

/datum/antag_training_program/creature/xeno/New()
	. = ..()
	var/obj/effect/proc_holder/alien/evolve/evolve_power = /obj/effect/proc_holder/alien/evolve
	var/obj/effect/proc_holder/alien/lay_egg/egg_power = /obj/effect/proc_holder/alien/lay_egg
	var/list/caste_hints = list(
		/mob/living/carbon/alien/larva = "Маленькая и хрупкая: прячется под столами и ползает по вентиляции. Выросшая личинка выбирает касту кнопкой «Evolve».",
		/mob/living/carbon/alien/humanoid/drone = "Строитель улья: трава, смола, кислота. За [initial(evolve_power.plasma_cost)] плазмы становится преторианцем, если в улье полигона нет королевской особи.",
		/mob/living/carbon/alien/humanoid/sentinel = "Защитник улья: плевок нейротоксином, кислота и маскировка в тени.",
		/mob/living/carbon/alien/humanoid/hunter = "Самый быстрый: прыжок на жертву с оглушением, малый запас плазмы.",
		/mob/living/carbon/alien/humanoid/royal/praetorian = "Тяжёлая охрана королевы: нейротоксин, смола, отталкивание. Без вентиляции. За [initial(evolve_power.plasma_cost)] плазмы становится королевой, если в улье полигона её нет.",
		/mob/living/carbon/alien/humanoid/royal/queen = "Откладывает яйца за [initial(egg_power.plasma_cost)] плазмы: созревшее яйцо выпускает лицехвата на цель рядом. Королева полигона не мешает ксеноморфам станции, и наоборот.",
	)
	option_hints = list(
		"Плазма до максимума" = "Запас плазмы заполняется до предела касты. В раунде плазма копится на траве и от плазмы в воздухе.",
		"Личинка выросла" = "Только для личинки: рост сразу полный, кнопка «Evolve» предлагает охотника, стража или дрона. В раунде личинка растёт несколько минут.",
		"Цель для хаггера" = "Рядом встанет учебная цель без шлема: лицехват прыгает на неё сам, подсаживает эмбрион, и через несколько минут из цели вылезает личинка без игрока. Яйца, лицехваты, эмбрионы и личинки входят в общий лимит целей полигона, пустые яйца и мёртвые лицехваты тоже - убирайте их очисткой своих объектов. В центре и переходах кнопка не работает. Траву, смолу и заражение с шагами и оценкой проходят в упражнении «Улей» в лаборатории.",
	)
	for(var/caste_type in choices)
		option_hints[choice_option(caste_type)] = "Новое тело этой касты на вашем месте с полной плазмой. [caste_hints[caste_type]]"

/datum/antag_training_program/creature/xeno/refill(mob/living/carbon/alien/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	fill_plasma(body)
	var/obj/item/organ/alien/hivenode/node = body.getorgan(/obj/item/organ/alien/hivenode)
	if(node?.recent_queen_death)
		node.recent_queen_death = 0
		body.clear_alert("alien_noqueen")

/datum/antag_training_program/creature/xeno/proc/fill_plasma(mob/living/carbon/alien/body)
	var/obj/item/organ/alien/plasmavessel/vessel = body.getorgan(/obj/item/organ/alien/plasmavessel)
	if(!vessel)
		return 0
	body.adjustPlasma(vessel.max_plasma)
	return vessel.max_plasma

/datum/antag_training_program/creature/xeno/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/carbon/alien/body = user
	if(!isalien(body) || body != session.current_body)
		to_chat(user, span_warning("Вы не в теле ксеноморфа. Выберите касту в пульте, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Плазма до максимума")
			to_chat(body, span_notice("Плазма: [fill_plasma(body)]."))
		if("Личинка выросла")
			var/mob/living/carbon/alien/larva/larva = body
			if(!istype(larva))
				to_chat(body, span_warning("Кнопка для личинки: сначала выберите касту «[choices[/mob/living/carbon/alien/larva]]»."))
				return FALSE
			larva.amount_grown = larva.max_grown
			larva.update_icons()
			to_chat(larva, span_notice("Личинка выросла: кнопка «Evolve» предлагает касту."))
		if("Цель для хаггера")
			var/mob/living/carbon/human/host = spawn_prey_near(session, body, "human", "Цель встаёт рядом с вами, а в центре и переходах её нет: встаньте на одну из площадок.")
			if(!host)
				return FALSE
			to_chat(body, span_notice("[host.real_name] стоит рядом. Лицехват из созревшего яйца прыгает на цель сам, взятого в руку можно бросить в неё."))
	return TRUE

/// Сеанс полигона, которому принадлежит потомство source: разум учебного ксеноморфа или метка владельца.
/proc/antag_training_brood_session(atom/movable/source)
	var/mob/living/parent = source
	if(istype(parent) && parent.mind)
		var/datum/antagonist/xeno/training/role = parent.mind.has_antag_datum(/datum/antagonist/xeno/training)
		if(role?.training)
			return role.training
	return source.training_owner?.resolve()

/// На полигоне: хватит ли лимита целей на count новых особей, с отказом владельцу. Вне полигона - TRUE.
/proc/antag_training_brood_room(atom/movable/source, count = 1, mob/living/host)
	if(!source.training_origin)
		return TRUE
	var/datum/antag_training_arena/arena = source.training_origin.resolve()
	if(!arena || arena.finished)
		return FALSE
	var/refusal
	if(host && antag_training_member_body(host))
		refusal = "На полигоне эмбрион подсаживается только учебным целям, не участникам."
	else if(!arena.has_target_room(count))
		refusal = arena.target_limit_refusal()
	if(!refusal)
		return TRUE
	var/datum/antag_training_session/session = antag_training_brood_session(source)
	if(session)
		to_chat(session.current_body, span_warning(refusal))
	return FALSE

/// Ставит потомство source в лимит целей полигона; не вместившееся удаляется.
/proc/antag_training_claim_brood(atom/movable/source, list/brood)
	var/datum/antag_training_arena/arena = source.training_origin?.resolve()
	if(!arena)
		return
	var/datum/antag_training_session/session = antag_training_brood_session(source)
	for(var/atom/movable/thing as anything in brood)
		if(thing && !arena.claim_target(thing, session, TRUE))
			qdel(thing)

/// Эмбрион на полигоне: личинка без игрока вместо опроса призраков, и она в лимите целей вместо эмбриона.
/obj/item/organ/body_egg/alien_embryo/proc/antag_training_burst(kill_on_success)
	var/mob/living/carbon/host = owner
	var/datum/antag_training_arena/arena = host.training_origin.resolve()
	var/datum/antag_training_session/session = training_owner?.resolve()
	var/burst_zone = zone
	var/turf/spot = get_turf(host)
	qdel(src)
	if(antag_training_member_body(host))
		to_chat(host, span_notice("Эмбрион рассасывается: на полигоне личинки вылезают только из учебных целей."))
		return
	var/mob/living/carbon/alien/larva/larva = new(spot)
	if(!arena?.claim_target(larva, session, TRUE))
		qdel(larva)
		return
	if(!kill_on_success)
		larva.visible_message(span_danger("[host]: из груди выползает [larva]!"))
		host.adjustBruteLoss(40)
		return
	larva.visible_message(span_danger("[host]: из груди вырывается [larva]!"))
	host.apply_damage(rand(100, 300), BRUTE, burst_zone, FALSE)
	var/obj/item/bodypart/chest = host.get_bodypart(burst_zone)
	chest?.drop_organs(host)
	host.death(FALSE)

/datum/antagonist/xeno/training
	name = "Учебный ксеноморф"
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

/datum/antagonist/xeno/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/xeno/training/create_team(datum/team/xeno/new_team)
	return

/datum/antagonist/xeno/training/threat()
	return 0

/datum/antagonist/xeno/training/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	var/datum/antag_training_program/creature/xeno/program = training?.program
	if(istype(program) && isalien(new_body) && new_body.training_origin?.resolve() == training.arena)
		program.body_ref = WEAKREF(new_body)

/datum/antagonist/xeno/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/xeno/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/xeno/training/proc/briefing()
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/xeno_hive
	var/obj/effect/proc_holder/alien/evolve/evolve_power = /obj/effect/proc_holder/alien/evolve
	var/obj/effect/proc_holder/alien/lay_egg/egg_power = /obj/effect/proc_holder/alien/lay_egg
	return jointext(list(
		span_boldnotice("Тренировка ксеноморфа."),
		span_notice("Способности - на панели «Alien», их цена - плазма. Плазма копится на траве, там же ксеноморф лечится. «:a» в начале фразы - речь улья: её слышат только ксеноморфы этого полигона."),
		span_notice("Дрон за [initial(evolve_power.plasma_cost)] плазмы становится преторианцем, преторианец - королевой, если в улье полигона нет другой. Королева откладывает яйца за [initial(egg_power.plasma_cost)] плазмы: созревшее яйцо выпускает лицехвата на цель рядом, он подсаживает эмбрион, а через несколько минут из цели вылезает личинка без игрока."),
		span_notice("«Пульт полигона», раздел «Моя роль»: смена касты, плазма до максимума, рост личинки и цель для хаггера. Яйца, лицехваты, эмбрионы и личинки входят в общий лимит целей. После смерти вы появитесь в вестибюле хаба новым телом выбранной касты."),
		span_notice("Упражнение «[initial(exercise.name)]» в лаборатории для дрона, преторианца и королевы: трава, стена из смолы и лицехват из созревшего яйца на учебной цели с подсказками и оценкой. Пульт, вкладка «Упражнения»."),
	), "<br>")

/datum/antagonist/xeno/training/Destroy()
	training = null
	return ..()

/datum/antag_training_exercise/drill/xeno_hive
	id = "xeno_hive"
	name = "Улей"
	desc = "Учебная цель встаёт рядом с вами в лаборатории, возле неё созревшее яйцо. Посадите траву, выделите стену из смолы и откройте яйцо: лицехват прыгнет на цель и подсадит ей эмбрион. Нужна каста со смоляной железой: дрон, преторианец или королева. Засчитанные узел, трава вокруг него и стена убираются, когда вы начинаете упражнение заново или выходите."
	sector = "laboratory"
	program = /datum/antag_training_program/creature/xeno
	human_only = FALSE
	difficulty = 2
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/checked/xeno/weeds, /datum/antag_training_exercise_step/drill/checked/xeno/resin, /datum/antag_training_exercise_step/drill/checked/xeno/hugger)

/datum/antag_training_exercise/drill/xeno_hive/setup(datum/antag_training_session/session)
	var/mob/living/carbon/alien/body = session.current_body
	if(!isalien(body) || !body.getorgan(/obj/item/organ/alien/resinspinner))
		return "траву и смолу выделяют дрон, преторианец и королева - смените касту в «Моей роли»"
	// Цель и эмбрион в ней.
	if(!session.arena.has_target_room(2, session))
		return FALSE
	prepare_target(session, "human", get_turf(body))
	return TRUE

/datum/antag_training_exercise/drill/xeno_hive/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	var/datum/antag_training_arena/arena = run.session.arena
	var/turf/spot = arena.free_spot(get_turf(target), arena.zones[sector]["bounds"]) || get_turf(target)
	var/obj/structure/alien/egg/grown/egg = new(spot)
	egg.training_owner = WEAKREF(run.session)
	run.add_prop(egg, FALSE)
	if(egg.child)
		egg.child.training_owner = egg.training_owner
		run.add_prop(egg.child, FALSE)

/// Трава, расползшаяся от засчитанного узла, уходит вместе с прогоном, если её не держит другой узел.
/datum/antag_training_exercise/drill/xeno_hive/teardown(datum/antag_training_session/session)
	var/datum/antag_training_exercise_run/run = session.exercise_run
	var/datum/antag_training_exercise_step/drill/checked/xeno/weeds/planting = run ? locate() in run.steps : null
	var/turf/root = planting?.counted_spot
	if(!root)
		return
	var/obj/structure/alien/weeds/node/counted = planting.counted_ref?.resolve()
	for(var/obj/structure/alien/weeds/weed in range(planting.counted_reach, root))
		if(istype(weed, /obj/structure/alien/weeds/node))
			continue
		var/held = FALSE
		for(var/obj/structure/alien/weeds/node/other in range(planting.counted_reach, weed))
			if(other != counted)
				held = TRUE
				break
		if(!held)
			qdel(weed)

/// Трава, смола и эмбрион сигналов не шлют: шаг проверяет их сам раз в секунду.
/datum/antag_training_exercise_step/drill/checked/xeno
	target_death = "цель погибла раньше, чем лицехват подсадил ей эмбрион"
	/// Постройка, которую засчитывает шаг; стоявшие в зоне до шага не в счёт.
	var/structure_type
	var/list/old_structures

/datum/antag_training_exercise_step/drill/checked/xeno/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	if(structure_type && isnull(old_structures))
		old_structures = list()
		for(var/turf/spot as anything in zone_turfs())
			for(var/obj/structure/alien/built in spot)
				if(istype(built, structure_type))
					old_structures[WEAKREF(built)] = TRUE

/datum/antag_training_exercise_step/drill/checked/xeno/Destroy()
	old_structures = null
	return ..()

/datum/antag_training_exercise_step/drill/checked/xeno/proc/zone_turfs()
	var/datum/antag_training_arena/arena = run.session.arena
	var/list/bounds = arena.zones[run.exercise.sector]?["bounds"]
	if(!bounds || !arena.private_level)
		return list()
	var/z_level = arena.private_level.z_value
	return block(locate(bounds[1], bounds[3], z_level), locate(bounds[2], bounds[4], z_level))

/// Новая постройка structure_type рядом с участником внутри зоны упражнения; засчитанная уходит вместе с прогоном.
/datum/antag_training_exercise_step/drill/checked/xeno/check()
	var/mob/living/body = participant()
	var/datum/antag_training_arena/arena = run.session.arena
	var/list/bounds = arena.zones[run.exercise.sector]?["bounds"]
	if(!body || !bounds)
		return FALSE
	for(var/obj/structure/alien/built in range(2, body))
		if(istype(built, structure_type) && !(built.weak_reference && old_structures[built.weak_reference]) && arena.inside_bounds(get_turf(built), bounds))
			counted(built)
			return TRUE
	return FALSE

/datum/antag_training_exercise_step/drill/checked/xeno/proc/counted(obj/structure/alien/built)
	run.add_prop(built, FALSE)

/datum/antag_training_exercise_step/drill/checked/xeno/weeds
	name = "Посадите траву"
	hint = "Нажмите «Plant Weeds» на панели «Alien»: под вами вырастет узел травы, и она расползётся вокруг. На траве копится плазма и заживают раны. Не хватает плазмы - «Плазма до максимума» в «Моей роли»."
	structure_type = /obj/structure/alien/weeds/node
	var/datum/weakref/counted_ref
	var/turf/counted_spot
	/// Докуда расползается трава узла: на клетку дальше его радиуса.
	var/counted_reach = 0

/datum/antag_training_exercise_step/drill/checked/xeno/weeds/counted(obj/structure/alien/weeds/node/built)
	. = ..()
	counted_ref = WEAKREF(built)
	counted_spot = get_turf(built)
	counted_reach = built.node_range + 1

/datum/antag_training_exercise_step/drill/checked/xeno/weeds/Destroy()
	counted_spot = null
	return ..()

/datum/antag_training_exercise_step/drill/checked/xeno/resin
	name = "Выделите стену из смолы"
	hint = "Отойдите на свободную клетку, нажмите «Secrete Resin» на панели «Alien» и выберите «resin wall»: стена встанет на вашей клетке. Мембрана и гнездо не в счёт."
	structure_type = /obj/structure/alien/resin/wall

/datum/antag_training_exercise_step/drill/checked/xeno/weeds/New()
	. = ..()
	var/obj/effect/proc_holder/alien/plant/power = /obj/effect/proc_holder/alien/plant
	hint = "Нажмите «Plant Weeds» на панели «Alien»: под вами вырастет узел травы за [initial(power.plasma_cost)] плазмы, и трава расползётся вокруг. На траве копится плазма и заживают раны. Не хватает плазмы - «Плазма до максимума» в «Моей роли»."

/datum/antag_training_exercise_step/drill/checked/xeno/resin/New()
	. = ..()
	var/obj/effect/proc_holder/alien/resin/power = /obj/effect/proc_holder/alien/resin
	hint = "Отойдите на свободную клетку, нажмите «Secrete Resin» на панели «Alien» и выберите «resin wall»: стена встанет на вашей клетке за [initial(power.plasma_cost)] плазмы. Мембрана и гнездо не в счёт."

/datum/antag_training_exercise_step/drill/checked/xeno/hugger
	name = "Выпустите лицехвата на цель"
	hint = "Созревшее яйцо стоит вплотную к цели. Подойдите к яйцу и щёлкните по нему: оно раскроется, и лицехват сам прыгнет на цель рядом. Через несколько секунд он подсадит эмбрион. Лицехвата можно и взять из раскрытого яйца и бросить в цель."

/datum/antag_training_exercise_step/drill/checked/xeno/hugger/check()
	var/mob/living/carbon/target = exercise_target()
	if(istype(target) && target.getorgan(/obj/item/organ/body_egg/alien_embryo))
		return TRUE
	var/obj/item/clothing/mask/facehugger/hugger = run.find_prop(/obj/item/clothing/mask/facehugger)
	if(!hugger || hugger.stat == DEAD)
		run.finish(FALSE, "лицехват погиб, не подсадив эмбрион: начните упражнение заново")
	return FALSE
