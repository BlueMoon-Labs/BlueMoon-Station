#define ANTAG_TRAINING_DEVIL_REVIVE_DELAY (5 SECONDS)
#define ANTAG_TRAINING_SINTOUCH_KNOCKDOWN (40 SECONDS)

/datum/antag_training_program/antag/devil
	name = "Дьявол"
	category = "Культы и магия"
	desc = "Инфернальные контракты и души учебных целей: кровавый ящер и истинный дьявол, воскрешение ценой душ, слабости истинного имени."
	icon = "file-contract"
	color = "red"
	learn = "Контракты с учебными целями|Души и их цена|Кровавый ящер и истинный дьявол|Воскрешение и слабости истинного имени"
	difficulty = 3
	antag_type = /datum/antagonist/devil/training
	options = list("Душа учебной цели", "Контракт для практики", "Истинное имя")

/datum/antag_training_program/antag/devil/New()
	. = ..()
	option_hints = list(
		"Душа учебной цели" = "Рядом появится учебная цель, и её душа станет вашей, как после подписанного контракта. Каждая душа - от отдельного человека. На [BLOOD_THRESHOLD] душах вы станете кровавым ящером, на [TRUE_THRESHOLD] - истинным дьяволом. Удалённая цель забирает свою душу.",
		"Контракт для практики" = "Контракт на силу для учебной цели появится у вас в руках. Манекен его не подпишет: подписывает только сам продающий душу, ручкой или кровью. Чтобы проверить подпись, призовите «Summon infernal contract» на другого участника полигона.",
		"Истинное имя" = "Ваше истинное имя, уязвимость, запрет, обязательство и обряд изгнания. В раунде экипаж узнаёт их, найдя имя в Codex Gigas.",
	)

/datum/antag_training_program/antag/devil/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/devil/training/devil = role(session)
	if(!devil)
		to_chat(user, span_warning("Роль дьявола снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Душа учебной цели")
			return grant_soul(session, user, devil)
		if("Контракт для практики")
			return issue_contract(session, user, devil)
		if("Истинное имя")
			to_chat(user, devil.true_name_report())
			return TRUE
	return FALSE

/datum/antag_training_program/antag/devil/proc/soul_dummy(datum/antag_training_session/session, mob/living/user)
	return place_practice_dummy(session, user, "Учебная цель не появилась: идёт сброс или дуэль, либо целей уже [ANTAG_TRAINING_TARGET_LIMIT]. Удалите лишние в разделе «Цели».")

/datum/antag_training_program/antag/devil/proc/grant_soul(datum/antag_training_session/session, mob/living/user, datum/antagonist/devil/training/devil)
	if(devil.changing_form)
		to_chat(user, span_warning("Тело ещё меняется. Подождите несколько секунд."))
		return FALSE
	var/mob/living/carbon/human/dummy = soul_dummy(session, user)
	if(!dummy)
		return FALSE
	dummy.mind.soulOwner = devil.owner
	INVOKE_ASYNC(devil, TYPE_PROC_REF(/datum/antagonist/devil, add_soul), dummy.mind)
	to_chat(user, span_notice("[dummy.real_name] отдал[dummy.ru_a()] вам душу. В раунде душу продают сами, подписав ваш контракт. Душ в запасе: [devil.soul_power()]."))
	return TRUE

/datum/antag_training_program/antag/devil/proc/issue_contract(datum/antag_training_session/session, mob/living/user, datum/antagonist/devil/training/devil)
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.arena.prune_supplies()
	if(session.arena.supply_count >= ANTAG_TRAINING_SUPPLY_LIMIT)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	var/mob/living/carbon/human/dummy = recent_target(session) || soul_dummy(session, user)
	if(!dummy)
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/paper/contract/infernal/power/contract = new(get_turf(user), dummy.mind, devil.owner)
	session.arena.track_supply(contract, session)
	user.put_in_hands(contract)
	to_chat(user, span_notice("Контракт на силу для [dummy.real_name] у вас в руках. Манекен его не подпишет - подписывает только сам продающий. «Recall Contract» вернёт неподписанный контракт в пустоту или призовёт его в руки."))
	return TRUE

/datum/antagonist/devil/training
	name = "Учебный дьявол"
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
	ascendable = FALSE
	var/datum/antag_training_session/training
	var/changing_form = FALSE
	var/list/datum/antagonist/sintouched/training/sinners = list()

/datum/antagonist/devil/training/on_gain()
	var/list/known_devils = GLOB.allDevils.Copy()
	. = ..()
	var/key = lowertext(truename)
	if(known_devils[key])
		GLOB.allDevils[key] = known_devils[key]
	else
		GLOB.allDevils -= key

/datum/antagonist/devil/training/threat()
	return 0

/datum/antagonist/devil/training/get_admin_commands()
	. = ..()
	. -= "Переключить возвышение"

/datum/antagonist/devil/training/proc/soul_power()
	return SOULVALUE

/datum/antagonist/devil/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/devil/training/proc/brief()
	to_chat(owner.current, jointext(list(
		span_boldnotice("Тренировка дьявола. Ваше истинное имя - [truename]."),
		span_notice("Души дают силу. «Summon infernal contract» призывает контракт для человека рядом, а подписать его может только сам продающий - другой участник полигона. Души учебных целей выдаёт «Душа учебной цели» в разделе «Моя роль» пульта. На [BLOOD_THRESHOLD] душах вы станете кровавым ящером, на [TRUE_THRESHOLD] - истинным дьяволом."),
		span_notice("Смерть при запасе душ воскрешает вас в вестибюле хаба полигона через [ANTAG_TRAINING_DEVIL_REVIVE_DELAY / (1 SECONDS)] с ценой [LOSS_PER_DEATH] душ, если над телом не завершён обряд изгнания. В раунде воскрешение ждёт [DEVILRESURRECTTIME / (1 SECONDS)] с, а вместо уничтоженного тела появляется новое где-то на станции."),
		span_notice("Возвышения в архидьявола на полигоне нет: в раунде оно затемняет космос всей станции, зовёт призраков и вызывает эвакуацию. Контракты на престиж и друга тоже закрыты."),
		span_warning("Вы не можете применять насилие, чтобы заставить кого-то продать душу, и не можете намеренно вредить другому дьяволу."),
		true_name_report(),
	), "<br>"))

/datum/antagonist/devil/training/proc/true_name_report()
	return jointext(list(
		span_notice("Истинное имя: [truename]. В раунде экипаж узнаёт ваши слабости, найдя это имя в Codex Gigas."),
		"Уязвимость: [GLOB.lawlorify[LAW][bane]]",
		"Запрет: [GLOB.lawlorify[LAW][ban]]",
		"Обязательство: [GLOB.lawlorify[LAW][obligation]]",
		"Изгнание: [GLOB.lawlorify[LAW][banish]]",
	), "<br>")

/datum/antagonist/devil/training/add_soul(datum/mind/soul)
	if(QDELETED(soul) || (soul in soulsOwned))
		return
	RegisterSignal(soul, COMSIG_PARENT_QDELETING, PROC_REF(on_soul_deleted))
	return ..()

/datum/antagonist/devil/training/remove_soul(datum/mind/soul)
	UnregisterSignal(soul, COMSIG_PARENT_QDELETING)
	return ..()

/datum/antagonist/devil/training/proc/on_soul_deleted(datum/mind/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(remove_soul), source)

/datum/antagonist/devil/training/increase_blood_lizard()
	changing_form = TRUE
	try
		. = ..()
	catch(var/exception/error)
		changing_form = FALSE
		throw error
	changing_form = FALSE

/datum/antagonist/devil/training/increase_true_devil()
	changing_form = TRUE
	try
		. = ..()
	catch(var/exception/error)
		changing_form = FALSE
		throw error
	changing_form = FALSE

/datum/antagonist/devil/training/increase_arch_devil()
	to_chat(owner.current, span_notice("Возвышения в архидьявола на полигоне нет. В раунде оно затемняет космос всей станции, зовёт призраков и вызывает эвакуационный шаттл."))

/datum/antagonist/devil/training/give_summon_contract()
	. = ..()
	swap_spell(/obj/effect/proc_holder/spell/targeted/summon_contract, /obj/effect/proc_holder/spell/targeted/summon_contract/training)

/datum/antagonist/devil/training/give_true_spells()
	. = ..()
	swap_spell(/obj/effect/proc_holder/spell/targeted/sintouch, /obj/effect/proc_holder/spell/targeted/sintouch/training)

/datum/antagonist/devil/training/proc/swap_spell(base_type, training_type)
	for(var/obj/effect/proc_holder/spell/spell as anything in owner.spell_list)
		if(spell.type == base_type)
			owner.RemoveSpell(spell)
	owner.AddSpell(new training_type(null))

/datum/antagonist/devil/training/proc/can_revive()
	return training?.arena && !training.finished && !training.resetting && !QDELETED(training.current_body)

/datum/antagonist/devil/training/proc/fallback_recovery()
	if(training?.auto_recover && training.current_body?.stat == DEAD)
		training.recover()
	return -1

/datum/antagonist/devil/training/beginResurrectionCheck(mob/living/body)
	if(SOULVALUE <= 0)
		to_chat(owner.current, span_userdanger("Душ в запасе нет: воскреснуть нечем. В раунде это окончательная смерть."))
		return
	if(training)
		deltimer(training.recovery_timer)
		training.recovery_timer = null
	to_chat(owner.current, span_userdanger("Через [ANTAG_TRAINING_DEVIL_REVIVE_DELAY / (1 SECONDS)] с вы воскреснете в вестибюле хаба полигона ценой [LOSS_PER_DEATH] душ. В раунде воскрешение ждёт [DEVILRESURRECTTIME / (1 SECONDS)] с. Оставайтесь в теле."))
	sleep(ANTAG_TRAINING_DEVIL_REVIVE_DELAY)
	if(QDELETED(src) || !training)
		return
	if(QDELETED(body) || body != owner.current || body.stat != DEAD)
		return fallback_recovery()
	if(SOULVALUE <= 0)
		to_chat(owner.current, span_userdanger("Пока вы ждали, души ушли: воскреснуть нечем. В раунде это окончательная смерть."))
		return fallback_recovery()
	if(check_banishment(body))
		to_chat(owner.current, span_userdanger("Над вашим телом завершён обряд изгнания. В раунде вы бы не воскресли."))
		return fallback_recovery()
	to_chat(owner.current, span_userdanger("МЫ СНОВА ЖИВЫ!"))
	return hellish_resurrection(body)

/datum/antagonist/devil/training/hellish_resurrection(mob/living/body)
	if(!can_revive())
		return fallback_recovery()
	log_game("[key_name(owner.current)] воскресает учебным дьяволом [truename] на тренировочном полигоне.")
	reviveNumber += LOSS_PER_DEATH
	update_hud()
	if(istype(body, /mob/living/carbon/true_devil))
		var/mob/living/carbon/true_devil/devil_form = body
		devil_form.oldform?.revive(TRUE, FALSE)
	create_new_body()
	check_regression()

/datum/antagonist/devil/training/create_new_body()
	if(!can_revive())
		return -1
	training.recover()

/datum/antagonist/devil/training/Destroy()
	for(var/datum/mind/soul as anything in soulsOwned)
		UnregisterSignal(soul, COMSIG_PARENT_QDELETING)
		if(soul.soulOwner == owner)
			soul.soulOwner = soul
	soulsOwned.Cut()
	for(var/datum/antagonist/sintouched/training/touched as anything in sinners.Copy())
		UnregisterSignal(touched, COMSIG_PARENT_QDELETING)
		if(!QDELETED(touched) && touched.owner)
			touched.on_removal()
	sinners.Cut()
	training = null
	return ..()

/datum/antagonist/devil/training/proc/add_sinner(mob/living/carbon/human/sinner)
	var/datum/antagonist/sintouched/training/touched = sinner.mind.add_antag_datum(/datum/antagonist/sintouched/training)
	if(!touched)
		return null
	sinners += touched
	RegisterSignal(touched, COMSIG_PARENT_QDELETING, PROC_REF(on_sinner_deleted))
	return touched

/datum/antagonist/devil/training/proc/on_sinner_deleted(datum/antagonist/sintouched/training/source)
	SIGNAL_HANDLER
	sinners -= source

/obj/effect/proc_holder/spell/targeted/summon_contract/training
	desc = "Призывает инфернальный контракт для человека рядом, а над мёртвым - контракт на воскрешение. На полигоне контракты на престиж и друга недоступны."
	var/static/list/contract_types = list(
		"Power" = /obj/item/paper/contract/infernal/power,
		"Wealth" = /obj/item/paper/contract/infernal/wealth,
		"Prestige" = /obj/item/paper/contract/infernal/prestige,
		"Magic" = /obj/item/paper/contract/infernal/magic,
		"Knowledge" = /obj/item/paper/contract/infernal/knowledge,
		"Friendship" = /obj/item/paper/contract/infernal/friend,
	)
	var/static/list/blocked_contracts = list(
		"Prestige" = "подписавший вписывается капитаном в законы ИИ станции",
		"Friendship" = "друга играет призрак",
	)

/obj/effect/proc_holder/spell/targeted/summon_contract/training/cast(list/targets, mob/user = usr)
	for(var/mob/living/carbon/signer in targets)
		if(!signer.mind || !user.mind)
			to_chat(user, span_notice("У [signer] нет разума: контракт не призвать."))
			continue
		if(signer.stat == DEAD)
			if(user.dropItemToGround(user.get_active_held_item()))
				user.put_in_hands(new /obj/item/paper/contract/infernal/revive(user.loc, signer.mind, user.mind))
			continue
		var/contract_name = choose_contract(user)
		var/contract_type = contract_types[contract_name]
		if(!contract_type || blocked_contracts[contract_name])
			if(contract_type)
				to_chat(user, span_warning("На полигоне недоступно: контракт [contract_name] - [blocked_contracts[contract_name]]."))
			revert_cast(user)
			return
		signer.put_in_hands(new contract_type(signer.loc, signer.mind, user.mind))

/obj/effect/proc_holder/spell/targeted/summon_contract/training/proc/choose_contract(mob/user)
	return input(user, "What type of contract?") as null|anything in contract_types

/obj/effect/proc_holder/spell/targeted/sintouch/training/cast(list/targets, mob/living/user = usr)
	for(var/mob/living/carbon/human/sinner in targets)
		if(!sinner.mind || sinner.mind.has_antag_datum(/datum/antagonist/sintouched) || sinner.anti_magic_check(FALSE, TRUE))
			continue
		var/datum/antagonist/devil/training/devil = user.mind?.has_antag_datum(/datum/antagonist/devil/training)
		if(!devil?.add_sinner(sinner))
			continue
		sinner.DefaultCombatKnockdown(ANTAG_TRAINING_SINTOUCH_KNOCKDOWN)

/datum/antagonist/sintouched/training
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0

/datum/antagonist/sintouched/training/threat()
	return 0

/datum/antagonist/sintouched/training/Destroy()
	QDEL_LIST(objectives)
	return ..()

#undef ANTAG_TRAINING_DEVIL_REVIVE_DELAY
#undef ANTAG_TRAINING_SINTOUCH_KNOCKDOWN
