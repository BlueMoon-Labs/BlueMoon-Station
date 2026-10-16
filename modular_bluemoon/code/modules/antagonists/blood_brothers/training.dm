/datum/team/brother_team
	/// Учебная цель клятв: в учебной команде заменяет экипаж станции
	var/datum/mind/training_target

/datum/team/brother_team/training
	training = TRUE
	show_roundend_report = FALSE
	var/datum/antag_training_session/session
	/// Разум участника: голосует за клятву только он
	var/datum/mind/player_mind

/datum/team/brother_team/training/Destroy(force)
	. = ..()
	session = null
	player_mind = null
	training_target = null

/datum/team/brother_team/training/update_name()
	. = ..()
	name = "[name] (тренировка)"

/datum/team/brother_team/training/roundend_report()
	return

/datum/team/brother_team/training/all_signed()
	return !is_active_brother(player_mind) || (player_mind in signed)

/// Болванчики без игрока не уходят в призраки
/datum/team/brother_team/training/check_departures()
	ghost_since.Cut()
	return ..()

/datum/team/brother_team/training/recruit_role_ok(datum/mind/candidate)
	if(!ishuman(candidate?.current))
		return "клятву даёт только человек"
	if(candidate in severed_minds)
		return "эту клятву уже разорвали"
	if(!(candidate in session?.arena?.target_minds))
		return "на полигоне позвать можно только учебную цель"
	if(candidate.has_antag_datum(/datum/antagonist/brother))
		return "у этого человека своя роль"
	return TRUE

/datum/team/brother_team/training/proc/watch_mind(datum/mind/watched)
	RegisterSignal(watched, COMSIG_PARENT_QDELETING, PROC_REF(on_mind_deleted), override = TRUE)

/datum/team/brother_team/training/proc/set_training_target(datum/mind/new_target)
	training_target = new_target
	if(new_target)
		watch_mind(new_target)

/// Полигон удаляет разумы своих целей: команда отпускает их, чтобы не держать ссылки
/datum/team/brother_team/training/proc/on_mind_deleted(datum/mind/deleted)
	SIGNAL_HANDLER
	if((deleted in members) && !(deleted in departed_minds))
		handle_departure(deleted, BROTHER_DEPARTURE_DELETED)
	members -= deleted
	departed_minds -= deleted
	departed_reasons -= deleted
	departed_genders -= deleted
	severed_minds -= deleted
	severed_kinds -= deleted
	signed -= deleted
	fallen_minds -= deleted
	recruit_refusals -= deleted
	ghost_since -= deleted
	last_states -= deleted
	if(proposed_by == deleted)
		proposed = null
		proposed_by = null
		signed.Cut()
	if(stash_last_user == deleted)
		stash_last_user = null
	if(player_mind == deleted)
		player_mind = null
	if(training_target == deleted)
		training_target = null
	var/datum/blood_vow/shadow/shadow_vow = vow
	if(istype(shadow_vow))
		shadow_vow.cuffed_since -= deleted
	for(var/datum/blood_oath/offer as anything in offered.Copy())
		if(offer.target_mind != deleted)
			continue
		offered -= offer
		if(proposed == offer)
			proposed = null
			proposed_by = null
			signed.Cut()
		qdel(offer)
	if(oath?.target_mind == deleted)
		QDEL_NULL(oath)
		notify("Цель клятвы пропала с полигона, клятва снята. Выберите новую в окне клятвы или кнопкой «Сменить клятву».")
		INVOKE_ASYNC(src, PROC_REF(offer_oaths))
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.refresh_bond_actions()
		brother.update_sense()
		var/mob/living/body = brother.owner.current
		if(!isliving(body))
			continue
		for(var/datum/status_effect/brother_sense/blood_mark/mark as anything in body.has_status_effect_list(/datum/status_effect/brother_sense/blood_mark))
			if(mark.tracked == deleted)
				qdel(mark)
	refresh_brother_uis()

/datum/antagonist/brother/training
	name = "Учебный кровный брат"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	prevent_roundtype_conversion = FALSE
	soft_antag = TRUE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0

/datum/antagonist/brother/training/on_gain()
	. = ..()
	var/datum/team/brother_team/training/training_team = team
	if(istype(training_team))
		training_team.watch_mind(owner)

/datum/antagonist/brother/training/greet()
	to_chat(owner.current, span_boldnotice("Тренировка кровного брата: рядом с вами стоит ваш учебный брат. Клятву вы даёте в одиночку - выберите её в окне «Кровная клятва», кнопка в левом верхнем углу."))
	to_chat(owner.current, span_notice("«Пульт полигона», раздел «Моя роль»: ранить, связать, убить и оживить брата, добавить печать связи, поставить себе майндшилд, сменить клятву, получить вещь для текущего шага и посмотреть обряд разрыва. «Принять в братство» на полигоне зовёт только учебные цели, и они соглашаются сразу."))

/datum/antag_training_program/blood_brother
	name = "Кровная клятва"
	options = list(
		"Ценность для текущего шага",
		"Поднять связь",
		"Ранить брата",
		"Связать брата",
		"Убить и оживить брата",
		"Майндшилд на себя / снять",
		"Сменить клятву",
		"Обряд разрыва на болванчике",
	)
	var/datum/team/brother_team/training/team
	var/datum/antag_training_session/session
	/// Учебный брат и цели клятв, созданные программой
	var/list/datum/weakref/spawned_bodies = list()

/datum/antag_training_program/blood_brother/setup(datum/antag_training_session/new_session)
	session = new_session
	var/datum/mind/player = session.avatar.mind
	team = new
	team.session = session
	team.player_mind = player
	var/mob/living/carbon/human/dummy = spawn_dummy()
	player.add_antag_datum(/datum/antagonist/brother/training, team)
	var/datum/antagonist/brother/training/dummy_brother = new
	dummy_brother.silent = TRUE
	dummy.mind.add_antag_datum(dummy_brother, team)
	team.start()
	return TRUE

/datum/antag_training_program/blood_brother/Destroy()
	QDEL_NULL(team)
	var/datum/antag_training_arena/arena = session?.arena
	for(var/datum/weakref/body_ref as anything in spawned_bodies)
		var/mob/living/body = body_ref.resolve()
		if(!body || body.key)
			continue
		if(arena)
			arena.targets -= body
			arena.target_minds -= body.mind
		QDEL_NULL(body.mind)
		qdel(body)
	spawned_bodies.Cut()
	session = null
	return ..()

/// Брат без игрока рядом с участником, в безопасном центре
/datum/antag_training_program/blood_brother/proc/spawn_dummy()
	var/datum/antag_training_arena/arena = session.arena
	var/turf/spot = arena.free_spot(get_step(session.avatar, EAST), arena.zones["hub"]["bounds"]) || get_turf(session.avatar)
	var/mob/living/carbon/human/dummy = new(spot)
	dummy.real_name = "Учебный брат"
	dummy.name = dummy.real_name
	dummy.training_owner = WEAKREF(session)
	dummy.mind_initialize()
	dummy.mind.add_antag_datum(/datum/antagonist/ghost_role/antag_training)
	dummy.equipOutfit(/datum/outfit/antag_training)
	ADD_TRAIT(dummy, TRAIT_NO_MIDROUND_ANTAG, REF(arena))
	ADD_TRAIT(dummy, TRAIT_EXEMPT_HEALTH_EVENTS, REF(arena))
	arena.targets += dummy
	arena.target_minds += dummy.mind
	spawned_bodies += WEAKREF(dummy)
	return dummy

/// Тело брата-болванчика: первый член команды без игрока, живой или мёртвый
/datum/antag_training_program/blood_brother/proc/dummy_body()
	for(var/datum/mind/member as anything in team.members - team.departed_minds - team.severed_minds)
		var/mob/living/carbon/human/body = member.current
		if(member != team.player_mind && ishuman(body) && !QDELETED(body))
			return body
	return null

/datum/antag_training_program/blood_brother/proc/living_dummy(mob/living/user)
	var/mob/living/carbon/human/dummy = dummy_body()
	if(!dummy)
		to_chat(user, span_warning("Брата-болванчика больше нет. Позовите учебную цель кнопкой «Принять в братство» или начните программу заново."))
		return null
	if(dummy.stat == DEAD)
		to_chat(user, span_warning("Брат мёртв: сначала оживите его."))
		return null
	return dummy

/datum/antag_training_program/blood_brother/handle_choice(datum/antag_training_session/active_session, mob/living/user, choice)
	var/datum/antagonist/brother/brother = user.mind?.has_antag_datum(/datum/antagonist/brother)
	if(QDELETED(team) || brother?.team != team)
		to_chat(user, span_warning("Вы больше не кровный брат. Начните программу заново в разделе «Моя роль»."))
		return
	switch(choice)
		if("Ценность для текущего шага")
			issue_step_item(user)
		if("Поднять связь")
			raise_bond(user)
		if("Ранить брата")
			wound_brother(user)
		if("Связать брата")
			bind_brother(user)
		if("Убить и оживить брата")
			kill_or_revive_brother(user)
		if("Майндшилд на себя / снять")
			toggle_mindshield(user)
		if("Сменить клятву")
			pick_oath(user)
		if("Обряд разрыва на болванчике")
			sever_brother(user)

/datum/antag_training_program/blood_brother/proc/issue_step_item(mob/living/user)
	if(!team.oath)
		to_chat(user, span_warning("Сначала дайте клятву: в окне клятвы или кнопкой «Сменить клятву»."))
		return
	var/datum/blood_oath_step/current = team.oath.current_step()
	if(!current)
		to_chat(user, span_notice("Все шаги клятвы скреплены."))
		return
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return
	var/obj/item/supply = current.training_supply(session, get_turf(user))
	if(isnull(supply))
		to_chat(user, span_notice("Для шага «[current.name]» вещь не нужна. [current.desc]"))
		return
	if(!supply)
		to_chat(user, span_warning("Вещь для шага «[current.name]» на полигоне не выдать: её не собрать здесь или выдано слишком много предметов. Печать связи без шага добавляет «Поднять связь»."))
		return
	session.next_supply_at = world.time + 1 SECONDS
	user.put_in_hands(supply)
	to_chat(user, span_notice("Выдано: [supply.name]. Когда условие шага «[current.name]» выполнено, скрепите его в окне клятвы."))

/datum/antag_training_program/blood_brother/proc/raise_bond(mob/living/user)
	if(team.bond_tier >= BLOOD_BOND_TIER_MAX)
		to_chat(user, span_warning("Все печати связи уже стоят."))
		return
	team.set_bond_tier(team.bond_tier + 1)
	var/text = "Печатей связи: [team.bond_tier] из [BLOOD_BOND_TIER_MAX]. Что они открыли, видно на кнопках и во вкладке «Связь» окна клятвы."
	if(team.bond_tier >= BLOOD_BOND_TIER_MAX && !team.oath)
		text += " Венец даёт клятва: выберите её в окне клятвы или кнопкой «Сменить клятву»."
	to_chat(user, span_notice(text))

/datum/antag_training_program/blood_brother/proc/wound_brother(mob/living/user)
	var/mob/living/carbon/human/dummy = living_dummy(user)
	if(!dummy)
		return
	dummy.apply_damage(BROTHER_TRAINING_INJURY, BRUTE, BODY_ZONE_CHEST, forced = TRUE, wound_bonus = CANT_WOUND)
	to_chat(user, span_notice("Брат получил [BROTHER_TRAINING_INJURY] ушибов, Чутьё покажет, что он ранен. С первой печати его лечит «Кровь за кровь»: встаньте вплотную и нажмите кнопку."))

/datum/antag_training_program/blood_brother/proc/bind_brother(mob/living/user)
	var/mob/living/carbon/human/dummy = living_dummy(user)
	if(!dummy)
		return
	if(dummy.handcuffed)
		QDEL_NULL(dummy.handcuffed)
		dummy.update_handcuffed()
		to_chat(user, span_notice("Наручники с брата сняты."))
		return
	dummy.handcuffed = new /obj/item/restraints/handcuffs(dummy)
	dummy.update_handcuffed()
	to_chat(user, span_notice("Брат в наручниках, Чутьё это покажет. С печати [BROTHER_FURY_TIER] наручники на брате будят «Ярость за брата», а венец «Разрыв оков» их срывает. Нажмите ещё раз, чтобы снять."))

/datum/antag_training_program/blood_brother/proc/kill_or_revive_brother(mob/living/user)
	var/mob/living/carbon/human/dummy = dummy_body()
	if(!dummy)
		living_dummy(user)
		return
	if(dummy.stat == DEAD)
		dummy.revive(full_heal = TRUE, admin_revive = TRUE)
		to_chat(user, span_notice("Брат снова жив: горе отпускает, связь вернулась."))
		return
	dummy.death()
	to_chat(user, span_notice("Брат погиб: так ощущается смерть брата, «Ярость за брата» просыпается сразу. Нажмите ещё раз, чтобы его оживить."))

/datum/antag_training_program/blood_brother/proc/toggle_mindshield(mob/living/user)
	var/obj/item/implant/mindshield/shield = length(user.implants) ? (locate(/obj/item/implant/mindshield) in user.implants) : null
	if(shield)
		shield.removed(user, silent = TRUE)
		qdel(shield)
		to_chat(user, span_notice("Майндшилд снят, связь с братом вернулась."))
		return
	shield = new(user)
	if(!shield.implant(user, null, TRUE))
		qdel(shield)
		to_chat(user, span_warning("Майндшилд не встаёт."))
		return
	to_chat(user, span_notice("Майндшилд стоит: связь заглушена, способности, Чутьё и печати не работают, брат видит вас заглушённым. Нажмите ещё раз, чтобы его снять."))

/// Клятвы, которые можно дать на полигоне: имя -> тип
/datum/antag_training_program/blood_brother/proc/oath_choices()
	. = list()
	for(var/oath_type in GLOB.blood_oath_types)
		var/datum/blood_oath/probe = new oath_type
		// Вызволению учебную цель программа создаёт сама, уже после выбора
		if(probe.available(team) || (!team.training_target && istype(probe, /datum/blood_oath/liberation)))
			.[probe.name] = oath_type
		qdel(probe)

/datum/antag_training_program/blood_brother/proc/pick_oath(mob/living/user)
	var/list/choices = oath_choices()
	var/choice = tgui_input_list(user, "Открытые способности связи сохранятся, шаги клятвы начнутся заново. Если клятве нужен человек, её целью станет учебная цель в лаборатории.", "Сменить клятву", choices)
	if(!choice || QDELETED(src) || QDELETED(session) || !session.can_control(user))
		return
	change_oath(user, choices[choice])

/// Дать клятву нужного типа; цель-человек - учебная цель полигона
/datum/antag_training_program/blood_brother/proc/change_oath(mob/living/user, oath_type)
	if(!(oath_type in GLOB.blood_oath_types) || QDELETED(team))
		return FALSE
	var/datum/blood_oath/new_oath = new oath_type
	var/mob/living/carbon/human/spawned
	if(!new_oath.prepare(team))
		spawned = session.arena.spawn_creature("human", "laboratory", FALSE, session)
		if(spawned)
			spawned_bodies += WEAKREF(spawned)
			team.set_training_target(spawned.mind)
		if(!spawned || !new_oath.prepare(team))
			to_chat(user, span_warning("Клятве «[new_oath.name]» на полигоне не нашлось целей."))
			qdel(new_oath)
			if(spawned)
				session.arena.targets -= spawned
				session.arena.target_minds -= spawned.mind
				QDEL_NULL(spawned.mind)
				qdel(spawned)
			return FALSE
	var/datum/blood_oath/old_oath = team.oath
	team.oath = null
	team.swear_oath(new_oath)
	if(team.oath != new_oath)
		team.oath = old_oath
		if(!QDELETED(new_oath))
			qdel(new_oath)
		to_chat(user, span_warning("Клятва не принята, попробуйте другую."))
		return FALSE
	qdel(old_oath)
	var/text = "Клятва «[new_oath.name]» дана. Шаги и их условия - в окне клятвы."
	if(new_oath.target_mind)
		text += " Её цель - [new_oath.target_mind.name], учебная цель полигона: она есть в разделе «Цели» пульта."
	to_chat(user, span_notice(text))
	return TRUE

/datum/antag_training_program/blood_brother/proc/sever_brother(mob/living/user)
	var/mob/living/carbon/human/dummy = dummy_body()
	if(!dummy)
		living_dummy(user)
		return
	dummy.visible_message(span_warning("Что-то невидимое, тянувшееся от ладони [dummy], с сухим треском рвётся."))
	team.sever(dummy.mind, "учебный обряд", BROTHER_SEVER_RITE)
	to_chat(user, span_notice("Так клятву рвёт обряд священника: он бьёт Библией связанного или лежащего брата и читает [DisplayTimeText(BROTHER_SEVER_RITE_TIME)]. Операция по иссечению шрама рвёт клятву так же. Место брата свободно: позовите учебную цель кнопкой «Принять в братство»."))

/// Вещь для шага на полигоне: null - шагу вещь не нужна, FALSE - выдать не вышло
/datum/blood_oath_step/proc/training_supply(datum/antag_training_session/session, turf/destination)
	return null

/datum/blood_oath_step/heist_item/training_supply(datum/antag_training_session/session, turf/destination)
	return brother_training_loot(session, destination, item_info)

/datum/blood_oath_step/blood_debt_take/training_supply(datum/antag_training_session/session, turf/destination)
	var/datum/blood_oath/blood_debt/debt = oath
	return brother_training_loot(session, destination, debt.gift_info)

/datum/blood_oath_step/initiation_gift/training_supply(datum/antag_training_session/session, turf/destination)
	var/datum/blood_oath/initiation/initiation = oath
	return brother_training_loot(session, destination, initiation.gift_info)

/datum/blood_oath_step/vendetta_id/training_supply(datum/antag_training_session/session, turf/destination)
	return brother_training_card(session, destination, oath.target_mind?.name)

/datum/blood_oath_step/compromat_papers/training_supply(datum/antag_training_session/session, turf/destination)
	return brother_training_card(session, destination, oath.target_mind?.name)

/datum/blood_oath_step/liberation_key/training_supply(datum/antag_training_session/session, turf/destination)
	return brother_training_card(session, destination, null, list(ACCESS_BRIG))

/datum/blood_oath_step/hijack_access/training_supply(datum/antag_training_session/session, turf/destination)
	return brother_training_card(session, destination, null, list(ACCESS_HEADS))

/datum/blood_oath_step/exposure_papers/training_supply(datum/antag_training_session/session, turf/destination)
	return session.arena.issue_item(/obj/item/documents/nanotrasen, destination, 1, session) || FALSE

/datum/blood_oath_step/exposure_copy/training_supply(datum/antag_training_session/session, turf/destination)
	var/obj/item/documents/photocopy/copy = session.arena.issue_item(/obj/item/documents/photocopy, destination, 1, session)
	if(!copy)
		return FALSE
	copy.copy_type = /obj/item/documents/nanotrasen
	return copy

/datum/blood_oath_step/compromat_photo/training_supply(datum/antag_training_session/session, turf/destination)
	return session.arena.issue_item(/obj/item/camera, destination, 1, session) || FALSE

/// Ценность из пула краж или её заменитель, годный для цели; диск ядерной аутентификации не выдаётся
/proc/brother_training_loot(datum/antag_training_session/session, turf/destination, datum/objective_item/item_info)
	var/static/list/never_issued = typecacheof(list(/obj/item/disk/nuclear))
	if(!item_info)
		return FALSE
	for(var/item_type in list(item_info.targetitem) + item_info.altitems)
		if(never_issued[item_type])
			continue
		var/obj/item/loot = session.arena.issue_item(item_type, destination, 1, session)
		if(!loot)
			return FALSE
		if(item_info.check_special_completion(loot))
			return loot
		qdel(loot)
	return FALSE

/proc/brother_training_card(datum/antag_training_session/session, turf/destination, owner_name, list/card_access)
	var/obj/item/card/id/card = session.arena.issue_item(/obj/item/card/id, destination, 1, session)
	if(!card)
		return FALSE
	if(owner_name)
		card.registered_name = owner_name
		card.update_label()
	if(card_access)
		card.access = card_access.Copy()
	return card
