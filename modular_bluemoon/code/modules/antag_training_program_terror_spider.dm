/datum/antag_training_program/creature/terror_spider
	name = "Паук-террор"
	category = "Существа"
	desc = "Тело паука-террора любого вида от рыцаря до королевы: паутина, коконы, яды и визги, кладка яиц и выводок в лимите целей полигона, улей только с пауками полигона."
	icon = "spider"
	color = "brown"
	learn = "Виды от рыцаря до королевы|Паутина и коконы|Яды и визги|Кладка яиц и выводок"
	difficulty = 2
	antag_type = /datum/antagonist/terror_spiders/training
	choice_prompt = "Вид"
	choices = list(
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight = "Рыцарь (T1)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/lurker = "Наблюдатель (T1)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer = "Лекарь (T1)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/reaper = "Жнец (T1)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/builder = "Дрон (T1)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/widow = "Вдова (T2)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/guardian = "Защитник (T2)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/destroyer = "Разрушитель (T2)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/prince = "Принц (T3)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/princess = "Принцесса (T3)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/mother = "Мать (T3)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/defiler = "Осквернитель (T3)",
		/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen = "Королева (T4)",
	)
	options = list("Здоровье и кладки", "Цель для укуса", "Труп для кокона")

/datum/antag_training_program/creature/terror_spider/New()
	. = ..()
	option_hints = list(
		"Здоровье и кладки" = "Полное здоровье, сброс задержек способностей и режимов рыцаря. Королеве и принцессе - запас яиц не меньше стартового, лекарю - трупов на одну кладку. Выводок (яйца, паучата и выросшие пауки) входит в общий лимит целей полигона: [ANTAG_TRAINING_TARGET_LIMIT] шт.",
		"Цель для укуса" = "Рядом встанет живой манекен без брони: укус, яд вдовы и дрона, заражение осквернителя. Из заражённого со временем вылупляются паучата, если в лимите целей есть место. В безопасном центре кнопка не работает: встаньте на одну из площадок.",
		"Труп для кокона" = "Рядом ляжет учебный труп: кнопка «Wrap» оборачивает его в кокон, паук быстро регенерирует, а лекарь получает пищу для кладки. Тела других участников в кокон не берутся. В безопасном центре кнопка не работает.",
	)
	for(var/spider_type in choices)
		option_hints[choice_option(spider_type)] = "Новое тело этого вида в той же точке. [species_hint(spider_type)]"

/datum/antag_training_program/creature/terror_spider/proc/species_hint(spider_type)
	switch(spider_type)
		if(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen)
			return "Сначала «Nest» - гнездо: после него стены ломаются, а яйца откладываются кнопкой «Lay Queen Eggs», но в вентиляцию уже не залезть. Королевских яиц на полигоне нет."
		if(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/princess)
			return "Яйца откладываются сразу, новое добавляется со временем; свой выводок не больше двадцати."
		if(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer)
			return "Лечит пауков укусом и феромонами, три трупа в коконах дают одну кладку."
		if(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/defiler)
			return "Заражает укусом и белой паутиной, дымы и визг сбивают с толку."
	return "Способности вида - на кнопках действий."

/datum/antag_training_program/creature/terror_spider/refill(mob/living/simple_animal/hostile/retaliate/poison/terror_spider/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	body.degenerate = FALSE
	for(var/obj/effect/proc_holder/spell/power as anything in body.mob_spell_list)
		if(power.charge_type == "recharge")
			power.revert_cast(body)
	if(istype(body, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight))
		var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/knight = body
		knight.attack_mode_av = 1
		knight.defence_mode_av = 1
	if(istype(body, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen))
		var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/queen = body
		queen.spider_growinstantly = initial(queen.spider_growinstantly)
		queen.spider_spawnfrequency = initial(queen.spider_spawnfrequency)
		queen.canlay = max(queen.canlay, initial(queen.canlay))
		queen.spider_lastspawn = world.time
	if(istype(body, /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer))
		var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/healer/healer = body
		healer.fed = max(healer.fed, healer.feedings_to_lay)

/datum/antag_training_program/creature/terror_spider/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле паука. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Здоровье и кладки")
			refill(body)
			to_chat(body, span_notice("Здоровье, способности и кладки восполнены."))
		if("Цель для укуса")
			return place_prey(session, body, "human", "живой манекен стоит рядом: кусайте")
		if("Труп для кокона")
			return place_prey(session, body, "corpse", "учебный труп лежит рядом: «Wrap» оборачивает его в кокон")
	return TRUE

/datum/antag_training_program/creature/terror_spider/proc/place_prey(datum/antag_training_session/session, mob/living/body, template_id, success)
	var/mob/living/carbon/human/prey = spawn_prey_near(session, body, template_id, "В центре и переходах цели не встают: перейдите на одну из площадок.")
	if(!prey)
		return FALSE
	to_chat(body, span_notice("[prey.real_name]: [success]."))
	return TRUE

/datum/antagonist/terror_spiders/training
	name = "Учебный паук-террор"
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

/datum/antagonist/terror_spiders/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/terror_spiders/training/create_team(datum/team/terror_spiders/new_team)
	return

/datum/antagonist/terror_spiders/training/get_team()
	return null

/datum/antagonist/terror_spiders/training/threat()
	return 0

/datum/antagonist/terror_spiders/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/terror_spiders/training/proc/brief()
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/body = owner.current
	to_chat(body, jointext(list(
		span_boldnotice("Тренировка паука-террора."),
		istype(body) ? span_notice(body.spider_intro_text) : null,
		span_notice("Укус по манекену - атака на «вред», кнопки действий - паутина, кокон и способности вида. «:t» - улей: его слышат только пауки этого полигона, как и чутьё улья о рождении и смерти."),
		span_notice("«Пульт полигона», раздел «Моя роль»: смена вида, здоровье и кладки, живая цель и труп для кокона рядом. Яйца, паучата и выросший выводок занимают места в лимите целей ([ANTAG_TRAINING_TARGET_LIMIT] шт.): сверх него кладка не ложится. После смерти вы появитесь новым пауком в вестибюле хаба."),
	) - null, "<br>"))

/datum/antagonist/terror_spiders/training/Destroy()
	training = null
	return ..()

/// Сеанс полигона, которому принадлежит паук-участник, его выводок или носитель паучат.
/proc/antag_training_terror_session(atom/movable/parent)
	var/datum/antag_training_session/session = parent.training_owner?.resolve()
	if(session || !ismob(parent))
		return session
	var/mob/parent_mob = parent
	var/datum/antagonist/terror_spiders/training/role = parent_mob.mind?.has_antag_datum(/datum/antagonist/terror_spiders/training)
	return role?.training

/// Хватит ли лимита целей полигона на count потомков parent; вне полигона - всегда.
/proc/antag_training_terror_room(atom/movable/parent, count)
	var/datum/antag_training_arena/arena = parent.training_origin?.resolve()
	if(!arena || arena.has_target_room(count))
		return TRUE
	to_chat(parent, span_warning("Кладка не ложится. [arena.target_limit_refusal()]"))
	return FALSE

/// Ставит потомка полигона в лимит целей под сеансом parent; inherit - место parent переходит потомку. FALSE - мест нет, потомок удалён.
/proc/antag_training_terror_claim(atom/movable/parent, atom/movable/child, inherit = FALSE, datum/antag_training_session/owner)
	var/datum/antag_training_arena/arena = child.training_origin?.resolve()
	if(!arena)
		return TRUE
	if(inherit && (parent in arena.targets))
		arena.targets -= parent
		arena.UnregisterSignal(parent, COMSIG_PARENT_QDELETING)
	if(arena.claim_target(child, owner || antag_training_terror_session(parent), TRUE))
		return TRUE
	qdel(child)
	return FALSE

/// Кладка вылупилась не целиком: lost паучат не поместились в лимит целей.
/proc/antag_training_terror_shortfall(atom/movable/parent, lost)
	var/datum/antag_training_arena/arena = parent.training_origin?.resolve()
	var/datum/antag_training_session/session = antag_training_terror_session(parent)
	if(arena && session)
		to_chat(session.current_body, span_warning("Кладка «[parent.name]» вылупилась не целиком, паучат не поместилось: [lost]. [arena.target_limit_refusal()]"))

/obj/item/organ/body_egg/terror_eggs
	var/datum/weakref/training_infector

/// Паучата заражённого носителя достаются сеансу паука, который его заразил.
/obj/item/organ/body_egg/terror_eggs/proc/mark_infector(atom/movable/infector)
	var/datum/antag_training_session/session = antag_training_terror_session(infector)
	if(session)
		training_infector = WEAKREF(session)
