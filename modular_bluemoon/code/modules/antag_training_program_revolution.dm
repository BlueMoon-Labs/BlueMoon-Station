/datum/antag_training_program/antag/revolution
	name = "Глава революции"
	category = "Предатели экипажа"
	desc = "Вспышка и имплант СБ-интерфейса, обращение учебных целей в революционеров, учебные капитан и глава СБ в кабинете главы станционного макета."
	icon = "flag"
	color = "red"
	learn = "Вспышка и имплант СБ-интерфейса|Обращение в революционеры|Капитан и глава СБ в кабинете главы"
	difficulty = 2
	sector = "station"
	antag_type = /datum/antagonist/rev/head/training
	options = list("Главы станции", "Цель для обращения", "Починить вспышку")
	option_hints = list(
		"Главы станции" = "В кабинете главы станционного макета встанут учебные капитан и глава СБ, прежние учебные главы исчезнут. Их смерть - цель учебного мятежа: когда мертвы обе, пульт объявит победу. Глав вспышка не обращает. В раунде цели мятежа - все главы станции, революция побеждает, когда каждый из них мёртв или покинул станцию, и об этом узнаёт вся станция.",
		"Цель для обращения" = "Рядом встанет учебная цель. Ударьте её вспышкой, пока она в сознании и без защиты глаз, - она станет учебным революционером. В раунде вспышка обращает только живого игрока в сознании, не из командования и без импланта защиты разума.",
		"Починить вспышку" = "Перегоревшая вспышка снова работает, потерянную выдадут заново. В раунде вспышка перегорает от частых вспышек подряд, а каждое удачное обращение снижает износ.",
	)

/datum/antag_training_program/antag/revolution/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/rev/head/training/leader = role(session)
	if(!leader)
		to_chat(user, span_warning("Роль главы революции снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Главы станции")
			leader.training_team.place_heads(user)
		if("Цель для обращения")
			spawn_recruit(session, user)
		if("Починить вспышку")
			leader.repair_flash()
	return TRUE

/datum/antag_training_program/antag/revolution/proc/spawn_recruit(datum/antag_training_session/session, mob/living/user)
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	if(station?.state != ANTAG_TRAINING_SECTOR_READY)
		to_chat(user, span_warning("Цели для обращения встают в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."))
		return null
	if(world.time < session.arena.next_spawn_at)
		to_chat(user, span_warning("Подождите секунду перед следующей целью."))
		return null
	session.arena.next_spawn_at = world.time + 1 SECONDS
	var/mob/living/carbon/human/recruit = session.arena.spawn_creature("human", "station", FALSE, session, get_turf(user))
	if(!recruit)
		to_chat(user, span_warning("Достигнут лимит учебных целей. Удалите лишние в разделе «Цели»."))
		return null
	target_created(session, recruit)
	to_chat(user, span_notice("[recruit.real_name] ждёт в станционном макете: ударьте [recruit.ru_ego()] вспышкой."))
	return recruit

/datum/antagonist/rev/head/proc/converts_without_client(mob/living/carbon/human/target)
	return FALSE

/datum/antagonist/rev/head/training
	name = "Учебный глава революции"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training
	var/datum/team/revolution/training/training_team
	var/datum/weakref/flash_ref

/datum/antagonist/rev/head/training/create_team(datum/team/revolution/new_team)
	training_team = new
	training_team.training = training

/datum/antagonist/rev/head/training/get_team()
	return training_team

/datum/antagonist/rev/head/training/create_objectives()
	objectives |= training_team.objectives

/datum/antagonist/rev/head/training/remove_objectives()
	objectives -= training_team?.objectives

/datum/antagonist/rev/head/training/threat()
	return 0

/datum/antagonist/rev/head/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/rev/head/training/proc/brief()
	to_chat(owner.current, jointext(list(
		span_boldnotice("Тренировка главы революции."),
		span_notice("Вспышка у вас в кармане: удар ею по учебной цели в сознании и без защиты глаз обращает её в учебного революционера. Имплант СБ-интерфейса в глазах показывает импланты защиты разума - таких вспышка не обращает."),
		span_notice("«Пульт полигона», раздел «Моя роль»: учебные капитан и глава СБ в кабинете главы станционного макета, цель для обращения и починка вспышки. Учебная революция побеждает, когда обе учебные главы мертвы."),
		span_notice("Аплинк чёрного рынка на полигоне не выдаётся: его доставка уходит на станцию."),
	), "<br>"))

/datum/antagonist/rev/head/training/farewell()
	return

/datum/antagonist/rev/head/training/announce_victorious()
	return FALSE

/datum/antagonist/rev/head/training/get_admin_commands()
	. = ..()
	. -= list("Demote", "Force victory")

/datum/antagonist/rev/head/training/remove_revolutionary(borged, deconverter)
	if(!borged)
		return ..()
	deconversion_reason = deconverter
	owner.remove_antag_datum(type)

/datum/antagonist/rev/head/training/equip_rev()
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body))
		return
	issue_flash()
	var/obj/item/organ/cyberimp/eyes/hud/security/syndicate/hud_implant = new(body)
	hud_implant.Insert(body, special = FALSE, drop_if_replaced = FALSE)

/datum/antagonist/rev/head/training/proc/issue_flash()
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body) || !training?.arena)
		return null
	var/obj/item/assembly/flash/handheld/flash = training.arena.issue_item(/obj/item/assembly/flash/handheld, get_turf(body), 1, training)
	if(!flash)
		return null
	flash_ref = WEAKREF(flash)
	if(!body.equip_to_slot_if_possible(flash, ITEM_SLOT_RPOCKET, qdel_on_fail = FALSE, disable_warning = TRUE))
		body.put_in_hands(flash)
	return flash

/datum/antagonist/rev/head/training/proc/repair_flash()
	var/mob/living/body = owner.current
	var/obj/item/assembly/flash/flash = flash_ref?.resolve()
	if(!QDELETED(flash) && body?.contains_atom(flash))
		flash.crit_fail = FALSE
		flash.times_used = 0
		flash.update_icon()
		to_chat(body, span_notice("Вспышка снова работает."))
		return flash
	if(world.time < training.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return null
	training.next_supply_at = world.time + 1 SECONDS
	flash = issue_flash()
	if(!flash)
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return null
	to_chat(body, span_notice("Прежней вспышки при вас нет - выдана новая."))
	return flash

/datum/antagonist/rev/head/training/converts_without_client(mob/living/carbon/human/target)
	var/datum/antag_training_arena/arena = training?.arena
	return arena && (target.mind in arena.target_minds) && target.training_origin?.resolve() == arena

/datum/antagonist/rev/head/training/add_revolutionary(datum/mind/rev_mind, stun = TRUE)
	if(!training_team || !(rev_mind in training?.arena?.target_minds) || !can_be_converted(rev_mind.current))
		return FALSE
	var/mob/living/carbon/recruit_body = rev_mind.current
	if(stun)
		recruit_body.silent = max(recruit_body.silent, 5)
		recruit_body.flash_act(1, 1)
		recruit_body.Stun(100)
	var/datum/antagonist/rev/training/recruit = new
	recruit.training = training
	if(!rev_mind.add_antag_datum(recruit, training_team))
		return FALSE
	to_chat(owner.current, span_notice("[recruit_body.real_name] обращен[recruit_body.ru_a()] в учебного революционера."))
	return TRUE

/datum/antagonist/rev/head/training/Destroy()
	var/datum/team/revolution/training/team = training_team
	. = ..()
	training_team = null
	training = null
	flash_ref = null
	qdel(team)

/datum/antagonist/rev/training
	name = "Учебный революционер"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	var/datum/antag_training_session/training
	var/datum/team/revolution/training/training_team

/datum/antagonist/rev/training/create_team(datum/team/revolution/new_team)
	if(istype(new_team, /datum/team/revolution/training))
		training_team = new_team

/datum/antagonist/rev/training/get_team()
	return training_team

/datum/antagonist/rev/training/create_objectives()
	objectives |= training_team?.objectives

/datum/antagonist/rev/training/remove_objectives()
	objectives -= training_team?.objectives

/datum/antagonist/rev/training/threat()
	return 0

/datum/antagonist/rev/training/greet()
	return

/datum/antagonist/rev/training/farewell()
	return

/datum/antagonist/rev/training/announce_victorious()
	return FALSE

/datum/antagonist/rev/training/get_admin_commands()
	. = ..()
	. -= list("Promote", "Force victory")

/datum/antagonist/rev/training/remove_revolutionary(borged, deconverter)
	return ..(FALSE, deconverter)

/datum/antagonist/rev/training/add_revolutionary(datum/mind/rev_mind, stun = TRUE)
	return FALSE

/datum/antagonist/rev/training/Destroy()
	. = ..()
	training_team = null
	training = null

/// Учебная революция: вне списка команд раунда, без таймеров раунда, цели - учебные главы своей арены.
/datum/team/revolution/training
	name = "Training Revolution"
	show_roundend_report = FALSE
	var/datum/antag_training_session/training
	var/victorious = FALSE

/datum/team/revolution/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/revolution/training/roundend_report()
	return

/datum/team/revolution/training/antag_check_extras()
	return null

/datum/team/revolution/training/is_gamemode_hero()
	return FALSE

/datum/team/revolution/training/proc/place_heads(mob/living/user)
	var/datum/antag_training_arena/arena = training?.arena
	var/datum/antag_training_sector/station = arena?.sectors["station"]
	var/turf/office = station?.landmark_turf("head_office")
	if(!office)
		to_chat(user, span_warning("Кабинет главы - в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."))
		return FALSE
	if(world.time < arena.next_spawn_at)
		to_chat(user, span_warning("Подождите секунду перед следующей расстановкой."))
		return FALSE
	arena.next_spawn_at = world.time + 1 SECONDS
	remove_heads()
	victorious = FALSE
	var/list/head_jobs = list("Captain" = "Учебный капитан", "Head of Security" = "Учебный глава СБ")
	for(var/job_title in head_jobs)
		var/mob/living/carbon/human/head = arena.spawn_creature("human", "station", FALSE, training, office)
		if(!head)
			to_chat(user, span_warning("Достигнут лимит учебных целей. Удалите лишние в разделе «Цели» и расставьте глав снова."))
			sync_objectives()
			return FALSE
		head.real_name = head_jobs[job_title]
		head.name = head.real_name
		head.mind.name = head.real_name
		head.mind.assigned_role = job_title
		add_head(head)
	sync_objectives()
	to_chat(user, span_notice("Учебные главы стоят в кабинете главы станционного макета. Учебная революция победит, когда все они будут мертвы."))
	return TRUE

/datum/team/revolution/training/proc/add_head(mob/living/carbon/human/head)
	var/datum/objective/antag_training/mutiny/mutiny = new
	mutiny.team = src
	mutiny.target = head.mind
	mutiny.head = head
	mutiny.explanation_text = "Учебный мятеж: убейте [head.real_name]."
	objectives += mutiny
	RegisterSignal(head, COMSIG_MOB_DEATH, PROC_REF(on_head_death))
	RegisterSignal(head, COMSIG_LIVING_REVIVE, PROC_REF(on_head_revived))
	RegisterSignal(head, COMSIG_PARENT_QDELETING, PROC_REF(on_head_gone))

/datum/team/revolution/training/proc/head_objective(mob/living/head)
	for(var/datum/objective/antag_training/mutiny/mutiny in objectives)
		if(mutiny.head == head)
			return mutiny
	return null

/datum/team/revolution/training/proc/drop_objective(datum/objective/antag_training/mutiny/mutiny)
	if(mutiny.head)
		UnregisterSignal(mutiny.head, list(COMSIG_MOB_DEATH, COMSIG_LIVING_REVIVE, COMSIG_PARENT_QDELETING))
	mutiny.head = null
	mutiny.target = null
	qdel(mutiny)

/datum/team/revolution/training/proc/remove_heads()
	for(var/datum/objective/antag_training/mutiny/mutiny in objectives.Copy())
		var/mob/living/head = mutiny.head
		drop_objective(mutiny)
		if(head && training?.can_manage_target(head))
			QDEL_NULL(head.mind)
			qdel(head)

/datum/team/revolution/training/proc/sync_objectives()
	for(var/datum/mind/member as anything in members)
		var/datum/antagonist/rev/rebel = member.has_antag_datum(/datum/antagonist/rev)
		if(!rebel)
			continue
		rebel.objectives |= objectives
		rebel.update_static_data_for_all_viewers()

/datum/team/revolution/training/proc/on_head_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	var/datum/objective/antag_training/mutiny/mutiny = head_objective(source)
	if(!mutiny || !(source.mind in training?.arena?.target_minds))
		return
	mutiny.completed = TRUE
	check_victory()

/datum/team/revolution/training/proc/on_head_revived(mob/living/source)
	SIGNAL_HANDLER
	var/datum/objective/antag_training/mutiny/mutiny = head_objective(source)
	if(!mutiny)
		return
	mutiny.completed = FALSE
	victorious = FALSE
	sync_objectives()

/datum/team/revolution/training/proc/on_head_gone(mob/living/source)
	SIGNAL_HANDLER
	var/datum/objective/antag_training/mutiny/mutiny = head_objective(source)
	if(mutiny)
		drop_objective(mutiny)
		sync_objectives()
		check_victory()

/datum/team/revolution/training/proc/check_victory()
	if(victorious || !length(objectives) || !training)
		return FALSE
	for(var/datum/objective/antag_training/mutiny/mutiny in objectives)
		if(!mutiny.completed || mutiny.head?.stat != DEAD || !(mutiny.target in training.arena?.target_minds))
			return FALSE
	victorious = TRUE
	sync_objectives()
	log_game("[key_name(training.current_body)] на тренировочном полигоне довёл учебную революцию до победы.")
	training.practice_message("Учебная революция победила: учебные главы макета мертвы. В раунде о победе революции объявляют всей станции, а новые главы и охрана на станцию больше не прибывают.")
	return TRUE

/datum/team/revolution/training/Destroy(force, ...)
	for(var/datum/objective/antag_training/mutiny/mutiny in objectives.Copy())
		drop_objective(mutiny)
	for(var/datum/mind/member as anything in members.Copy())
		var/datum/antagonist/rev/training/recruit = member.has_antag_datum(/datum/antagonist/rev/training)
		if(recruit)
			recruit.silent = TRUE
			member.remove_antag_datum(/datum/antagonist/rev/training)
	training = null
	return ..()

/datum/objective/antag_training/mutiny
	name = "training mutiny"
	var/mob/living/carbon/human/head
