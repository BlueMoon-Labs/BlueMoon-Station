#define ANTAG_TRAINING_TRAITOR_LOOT /obj/item/documents/nanotrasen
/// Покупка в учебном аплинке, на покупателе: (datum/uplink_item/item)
#define COMSIG_ANTAG_TRAINING_UPLINK_PURCHASE "antag_training_uplink_purchase"

/// Предметы аплинка, которые зовут призраков, действуют на станцию или берут цели и роли из раунда: тип -> причина отказа.
GLOBAL_LIST_INIT(antag_training_blocked_uplink_items, list(
	// Призраки: опрос, заселение, оповещение.
	/datum/uplink_item/dangerous/guardian = "голопаразита заселяет призрак",
	/datum/uplink_item/dangerous/nukieguardian = "голопаразита заселяет призрак",
	/datum/uplink_item/support/monkey_agent = "агента-обезьяну играет призрак",
	/datum/uplink_item/support/inteq_pai = "личность pAI - призрак, а записи СБ в нём станционные",
	/datum/uplink_item/support/reinforcement = "подкрепление играет призрак",
	/datum/uplink_item/bundles_tc/inteq_drone = "дрона заселяет призрак",
	/datum/uplink_item/bundles_tc/surplus = "в ящике может оказаться вызов призрака",
	/datum/uplink_item/role_restricted/haunted_magic_eightball = "шар зовёт призраков",
	/datum/uplink_item/role_restricted/reverse_bear_trap = "капкан оповещает призраков",
	// Станция: объявления, под, счета экипажа, машины и КПК всех уровней.
	/datum/uplink_item/device_tools/suspiciousphone = "CRAB-17 объявляет тревогу, сажает под на станцию и списывает деньги со счетов экипажа",
	/datum/uplink_item/explosives/syndicate_detonator = "детонатор взводит все бомбы синдиката на всех уровнях",
	/datum/uplink_item/device_tools/singularity_beacon = "маяк уводит на себя каждую новую сингулярность станции",
	/datum/uplink_item/device_tools/fakenucleardisk = "ложный диск сам переносится на станцию",
	/datum/uplink_item/stealthy_tools/chameleon = "КПК набора виден в сети станции и пишет экипажу",
	/datum/uplink_item/badass/costumes = "КПК костюма виден в сети станции и пишет экипажу",
	/datum/uplink_item/explosives/detomatix = "вирус бьёт по КПК станции",
	/datum/uplink_item/device_tools/frame = "вирус выдаёт аплинк КПК станции",
	// Раунд: задания, классы, роли и журнал покупок.
	/datum/uplink_item/bundles_tc/contract_kit = "контракты выдаются на экипаж станции, а напарника играет призрак",
	/datum/uplink_item/bundles_tc/reroll = "новые задания и класс берутся из раунда",
	/datum/uplink_item/stealthy_weapons/romerol_kit = "ромерол - реагент: химия разносит его дальше набора, в еду, шприцы и дым",
	/datum/uplink_item/role_restricted/arcane_tome = "том обращает в культ раунда",
	/datum/uplink_item/implants/uplink = "второй аплинк выдаёт кнопка «Выдать ручку с аплинком» в пульте",
	// Наборы, в которых попадаются закрытые предметы.
	/datum/uplink_item/bundles_tc/bundle = "в наборе попадаются CRAB-17, вирус Detomatix, КПК, видимый в сети станции, и аплинк-имплант раунда",
))

/datum/antag_training_program/antag/traitor
	name = "Предатель InteQ"
	category = "Предатели экипажа"
	desc = "Аплинк-имплант с полным счётом и магазин InteQ без предметов, действующих на станцию, учебные ликвидация и кража из хранилища станционного макета, ручка с аплинком, классы предателя. Упражнение «Тихая ликвидация»: покупка, убийство без свидетелей в кабинете главы и вынос документов в зал прибытия."
	icon = "user-secret"
	color = "orange"
	learn = "Аплинк-имплант и магазин InteQ|Классы предателя|Ликвидация без свидетелей|Кража и вынос документов"
	difficulty = 1
	order = 3
	sector = "station"
	antag_type = /datum/antagonist/traitor/training
	choice_prompt = "Сменить класс"
	target_action = "Цель ликвидации"
	options = list("Пополнить ТК", "Учебная цель: ликвидация", "Учебная цель: кража", "Выдать ручку с аплинком")
	var/static/list/class_types = list(
		"freeform" = TRAITOR_HUMAN,
		"assassin" = /datum/traitor_class/human/subterfuge/assassin,
		"subterfuge" = /datum/traitor_class/human/subterfuge,
		"hijack" = /datum/traitor_class/human/hijack,
	)
	var/static/list/class_hints = list(
		"freeform" = "В раунде такой агент получает одну свободную цель: враждовать с Nanotrasen и Синдикатом как угодно, не попадаясь.",
		"assassin" = "В раунде задания этого класса чаще других требуют убийства.",
		"subterfuge" = "В раунде - кражи, саботаж, подставы и защита, убийства реже.",
		"hijack" = "В раунде задача - угнать эвакуационный шаттл, а консоль шаттла взламывается быстрее. Предметы только для угона на полигоне закрыты: им нужна цель угона раунда.",
	)

/datum/antag_training_program/antag/traitor/New()
	if(!length(GLOB.traitor_classes))
		for(var/class_type in subtypesof(/datum/traitor_class))
			new class_type
	choices = list("freeform" = "Свободный", "assassin" = "Ассасин", "subterfuge" = "Диверсант")
	if(GLOB.traitor_classes[class_types["hijack"]])
		choices["hijack"] = "Угонщик"
	. = ..()
	option_hints = list(
		"Пополнить ТК" = "Счёт аплинк-импланта пополнится до [TELECRYSTALS_DEFAULT] ТК. В раунде кредиты дают один раз: [TELECRYSTALS_DEFAULT] в КПК, рации или ручке, [TELECRYSTALS_DEFAULT - UPLINK_IMPLANT_TELECRYSTAL_COST] в импланте.",
		"Учебная цель: ликвидация" = "Последняя ваша живая учебная цель станет целью ликвидации; кнопка «Цель ликвидации» в разделе «Цели» выбирает другую. Задание засчитается, как только манекен умрёт. В раунде - в конце смены, если цель к тому времени мертва. Ликвидацию без свидетелей с шагами и оценкой проходят в упражнении «Тихая ликвидация».",
		"Учебная цель: кража" = "В хранилище станционного макета появятся секретные документы. Возьмите их в руки - кража засчитается. В раунде кражу засчитывают, если предмет при вас в конце смены.",
		"Выдать ручку с аплинком" = "Ручка со скрытым аплинком на [TELECRYSTALS_DEFAULT] ТК: поверните колпачок на углы из сообщения, и откроется магазин. В раунде аплинк прячут ещё в КПК и рации; КПК на полигоне не выдаётся, он виден в сети станции.",
	)
	for(var/key in choices)
		var/datum/traitor_class/class = GLOB.traitor_classes[class_types[key]]
		option_hints[choice_option(key)] = "Работодатель - [class?.employer]. [class_hints[key]] Смена класса перевыдаёт роль: новый аплинк-имплант на [TELECRYSTALS_DEFAULT] ТК, учебные задания сбрасываются, купленное остаётся."

/datum/antag_training_program/antag/traitor/apply_choice(datum/antagonist/traitor/training/role)
	role.selected_kind = class_types[choice] || TRAITOR_HUMAN
	role.class_name = choices[choice]

/datum/antag_training_program/antag/traitor/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	. = ..()
	if(target.mind)
		to_chat(session.current_body, span_notice("[target.real_name] отмечен[target.ru_a()]: «Учебная цель: ликвидация» в «Моей роли» сделает [target.ru_ego()] целью."))

/datum/antag_training_program/antag/traitor/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/traitor/training/traitor = role(session)
	if(!traitor)
		to_chat(user, span_warning("Роль предателя снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Пополнить ТК")
			traitor.refill_uplink()
		if("Учебная цель: ликвидация")
			var/mob/living/carbon/human/dummy = recent_target(session)
			if(!dummy)
				to_chat(user, span_warning("Нет живой учебной цели. Создайте человека в разделе «Цели» и нажмите кнопку снова."))
				return FALSE
			traitor.assign_kill_target(dummy)
		if("Учебная цель: кража")
			plant_loot(session, user, traitor)
		if("Выдать ручку с аплинком")
			issue_uplink_pen(session, user, traitor)
	return TRUE

/datum/antag_training_program/antag/traitor/proc/plant_loot(datum/antag_training_session/session, mob/living/user, datum/antagonist/traitor/training/traitor)
	var/datum/antag_training_sector/station = session.arena.sectors["station"]
	var/turf/vault = station?.landmark_turf("vault")
	if(!vault)
		to_chat(user, span_warning("Хранилище - в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."))
		return FALSE
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/loot = session.arena.issue_item(ANTAG_TRAINING_TRAITOR_LOOT, vault, 1, session)
	if(!loot)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	traitor.assign_steal_target(loot)
	return TRUE

/datum/antag_training_program/antag/traitor/proc/issue_uplink_pen(datum/antag_training_session/session, mob/living/user, datum/antagonist/traitor/training/traitor)
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return null
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/pen/pen = session.arena.issue_item(/obj/item/pen, get_turf(user), 1, session)
	if(!pen)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return null
	var/datum/component/uplink/antag_training/hidden = pen.AddComponent(/datum/component/uplink/antag_training)
	hidden.setup_unlock_code()
	user.put_in_hands(pen)
	traitor.antag_memory += "[hidden.unlock_note]<br>"
	to_chat(user, span_notice("Ручка с аплинком на [hidden.telecrystals] ТК у вас. Используйте её в руке и поверните колпачок по очереди на [jointext(hidden.unlock_code, " и ")] градусов - откроется магазин. Углы записаны в заметки роли."))
	return pen

/datum/antagonist/traitor/training
	name = "Учебный предатель InteQ"
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
	silent = TRUE
	give_objectives = FALSE
	should_give_codewords = FALSE
	var/datum/antag_training_session/training
	var/selected_kind = TRAITOR_HUMAN
	var/class_name = "Свободный"
	var/obj/item/implant/uplink/antag_training/training_implant
	var/list/training_phrases
	var/list/training_responses
	var/regex/training_phrase_regex
	var/regex/training_response_regex
	var/datum/objective/antag_training/kill_objective
	var/datum/weakref/kill_body_ref
	var/datum/objective/antag_training/steal_objective
	var/datum/weakref/loot_ref

/datum/antagonist/traitor/training/assign_traitor_kind()
	set_traitor_kind(GLOB.traitor_classes[selected_kind] ? selected_kind : TRAITOR_HUMAN)

/datum/antagonist/traitor/training/on_gain()
	training_phrases = generate_code_phrase(return_list = TRUE)
	training_responses = generate_code_phrase(return_list = TRUE)
	training_phrase_regex = new("([jointext(training_phrases, "|")])", "ig")
	training_response_regex = new("([jointext(training_responses, "|")])", "ig")
	. = ..()
	uplink = training_implant?.GetComponent(/datum/component/uplink)
	antag_memory += "<b>Учебные кодовые фразы</b>: [span_blue(jointext(training_phrases, ", "))]<br><b>Учебные ответы</b>: [span_red(jointext(training_responses, ", "))]<br>"
	greet()

/datum/antagonist/traitor/training/threat()
	return 0

/datum/antagonist/traitor/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/traitor/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/traitor/training/proc/briefing()
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/traitor_quiet_kill
	return jointext(list(
		span_boldnotice("Тренировка предателя InteQ. Класс «[class_name]», работодатель - [traitor_kind?.employer]."),
		span_notice("Аплинк вживлён: кнопка импланта открывает магазин на [TELECRYSTALS_DEFAULT] ТК, купленное появляется в руках. Голопаразиты, контракты, подкрепления, CRAB-17, наборы, где такое попадается, и всё, что зовёт призраков, действует на станцию или берёт задания и роли из раунда, на полигоне не продаются: кредиты за них не списываются, а Random Item выбирает только из открытого."),
		span_notice("Учебные кодовые фразы: [span_blue(jointext(training_phrases, ", "))]. Ответы: [span_red(jointext(training_responses, ", "))]. Это не слова смены - настоящие получают только предатели раунда. Услышанные фразы подсвечиваются."),
		span_notice("«Пульт полигона», раздел «Моя роль»: пополнить ТК, учебные ликвидация и кража из хранилища станционного макета, ручка с аплинком и смена класса."),
		span_notice("Упражнение «[initial(exercise.name)]» в станционном макете: купите снаряжение, убейте цель в кабинете главы, где никто не увидит, и вынесите документы в зал прибытия. Пульт, вкладка «Упражнения»."),
	), "<br>")

/datum/antagonist/traitor/training/handle_hearing(datum/source, list/hearing_args)
	if(!training_phrase_regex || !training_response_regex)
		return
	var/message = hearing_args[HEARING_RAW_MESSAGE]
	message = training_phrase_regex.Replace(message, "<span class='blue'>$1</span>")
	message = training_response_regex.Replace(message, "<span class='red'>$1</span>")
	hearing_args[HEARING_RAW_MESSAGE] = message

/datum/antagonist/traitor/training/ui_static_data(mob/user)
	. = ..()
	.["phrases"] = jointext(training_phrases, ", ")
	.["responses"] = jointext(training_responses, ", ")
	if(uplink)
		.["uplink_unlock_info"] = "Учебный аплинк вживлён: кнопка импланта открывает магазин на [TELECRYSTALS_DEFAULT] ТК, «Пополнить ТК» в «Моей роли» возвращает счёт."

/datum/antagonist/traitor/training/equip(silent = FALSE)
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body))
		return
	training_implant = new(body)
	RegisterSignal(training_implant, COMSIG_PARENT_QDELETING, PROC_REF(on_implant_gone))
	if(!training_implant.implant(body, null, TRUE))
		QDEL_NULL(training_implant)

/datum/antagonist/traitor/training/proc/on_implant_gone(datum/source)
	SIGNAL_HANDLER
	if(source != training_implant)
		return
	training_implant = null
	uplink = null

/datum/antagonist/traitor/training/proc/refill_uplink()
	var/datum/component/uplink/hidden = training_implant?.GetComponent(/datum/component/uplink)
	if(!hidden)
		to_chat(owner.current, span_warning("Аплинк-имплант извлечён. Смените класс, чтобы получить новый."))
		return FALSE
	if(hidden.telecrystals < TELECRYSTALS_DEFAULT)
		hidden.telecrystals = TELECRYSTALS_DEFAULT
		SStgui.update_uis(hidden)
	to_chat(owner.current, span_notice("На счету аплинка [hidden.telecrystals] ТК."))
	return TRUE

/datum/antagonist/traitor/training/proc/assign_kill_target(mob/living/carbon/human/dummy)
	drop_kill_objective()
	kill_objective = new
	kill_objective.owner = owner
	kill_objective.target = dummy.mind
	kill_objective.explanation_text = "Учебная ликвидация: убейте [dummy.real_name]."
	add_objective(kill_objective)
	update_static_data_for_all_viewers()
	kill_body_ref = WEAKREF(dummy)
	RegisterSignal(dummy, COMSIG_LIVING_DEATH, PROC_REF(on_kill_target_death))
	RegisterSignal(dummy.mind, COMSIG_PARENT_QDELETING, PROC_REF(on_kill_target_gone))
	to_chat(owner.current, span_notice("[dummy.real_name] - цель учебной ликвидации. Задание засчитается, как только манекен умрёт. В раунде ликвидацию засчитывают в конце смены, если цель к тому времени мертва."))

/datum/antagonist/traitor/training/proc/on_kill_target_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(!kill_objective || kill_objective.completed || source.mind != kill_objective.target || !(source.mind in training?.arena?.target_minds))
		return
	kill_objective.completed = TRUE
	update_static_data_for_all_viewers()
	to_chat(owner.current, span_notice("Учебная ликвидация выполнена: [source.real_name] убит[source.ru_a()]."))

/datum/antagonist/traitor/training/proc/on_kill_target_gone(datum/source)
	SIGNAL_HANDLER
	drop_kill_objective()
	update_static_data_for_all_viewers()

/datum/antagonist/traitor/training/proc/drop_kill_objective()
	if(!kill_objective)
		return
	var/mob/living/body = kill_body_ref?.resolve()
	if(body)
		UnregisterSignal(body, COMSIG_LIVING_DEATH)
	if(kill_objective.target)
		UnregisterSignal(kill_objective.target, COMSIG_PARENT_QDELETING)
	kill_objective.target = null
	kill_body_ref = null
	QDEL_NULL(kill_objective)

/datum/antagonist/traitor/training/proc/assign_steal_target(obj/item/loot)
	drop_steal_objective()
	steal_objective = new
	steal_objective.owner = owner
	steal_objective.explanation_text = "Учебная кража: заберите секретные документы из хранилища станционного макета."
	add_objective(steal_objective)
	update_static_data_for_all_viewers()
	loot_ref = WEAKREF(loot)
	RegisterSignal(loot, COMSIG_ITEM_EQUIPPED, PROC_REF(on_loot_equipped))
	RegisterSignal(loot, COMSIG_PARENT_QDELETING, PROC_REF(on_loot_gone))
	to_chat(owner.current, span_notice("В хранилище станционного макета лежат секретные документы. Возьмите их в руки - кража засчитается. В раунде кражу засчитывают, если предмет при вас в конце смены."))

/datum/antagonist/traitor/training/proc/on_loot_equipped(obj/item/source, mob/equipper, slot)
	SIGNAL_HANDLER
	if(!steal_objective || steal_objective.completed || equipper != owner.current)
		return
	steal_objective.completed = TRUE
	update_static_data_for_all_viewers()
	to_chat(equipper, span_notice("Учебная кража выполнена: документы у вас."))

/datum/antagonist/traitor/training/proc/on_loot_gone(datum/source)
	SIGNAL_HANDLER
	drop_steal_objective()
	update_static_data_for_all_viewers()

/datum/antagonist/traitor/training/proc/drop_steal_objective()
	var/obj/item/loot = loot_ref?.resolve()
	loot_ref = null
	if(loot)
		UnregisterSignal(loot, list(COMSIG_ITEM_EQUIPPED, COMSIG_PARENT_QDELETING))
		qdel(loot)
	QDEL_NULL(steal_objective)

/datum/antagonist/traitor/training/Destroy()
	drop_kill_objective()
	drop_steal_objective()
	QDEL_LIST(objectives)
	QDEL_NULL(training_implant)
	uplink = null
	training = null
	training_phrase_regex = null
	training_response_regex = null
	return ..()

/obj/item/implant/uplink/antag_training
	name = "training uplink implant"
	starting_tc = TELECRYSTALS_DEFAULT
	uplink_type = /datum/component/uplink/antag_training

/// Аплинк полигона: весь магазин без порога по онлайну, без покупок, зовущих призраков, без записей под ckey и статистики раунда.
/datum/component/uplink/antag_training

/datum/component/uplink/antag_training/Initialize(_owner, _lockable = TRUE, _enabled = FALSE, uplink_flag = UPLINK_TRAITORS, starting_tc = TELECRYSTALS_DEFAULT, syndicate = FALSE)
	. = ..(null, _lockable, _enabled, uplink_flag, starting_tc, syndicate)
	if(. == COMPONENT_INCOMPATIBLE)
		return
	purchase_log = new(null, src)

/datum/component/uplink/antag_training/update_items()
	var/list/updated_items = get_uplink_items(uplink_flag, TRUE, allow_restricted, ignore_player_minimum = TRUE)
	update_sales(updated_items)
	uplink_items = updated_items

/datum/component/uplink/antag_training/proc/blocked_reason(datum/uplink_item/item)
	for(var/blocked_type in GLOB.antag_training_blocked_uplink_items)
		if(istype(item, blocked_type))
			return GLOB.antag_training_blocked_uplink_items[blocked_type]
	return null

/datum/component/uplink/antag_training/proc/refusal(datum/uplink_item/item)
	var/reason = blocked_reason(item)
	return reason ? "На полигоне недоступно: [item.name] - [reason]. Кредиты не списаны." : null

/datum/component/uplink/antag_training/build_uplink_shop_categories(mob/user)
	. = ..()
	for(var/list/category as anything in .)
		for(var/list/entry as anything in category["items"])
			var/datum/uplink_item/item = uplink_items[category["name"]][entry["name"]]
			var/reason = blocked_reason(item)
			if(reason)
				entry["desc"] = "[entry["desc"]] На полигоне недоступно: [reason]."
			else if(istype(item, /datum/uplink_item/bundles_tc/random))
				entry["desc"] = "[entry["desc"]] На полигоне выбирает только среди открытых предметов."

/datum/component/uplink/antag_training/refuse_purchase(mob/user, datum/uplink_item/item)
	var/refusal_text = refusal(item)
	if(!refusal_text)
		return FALSE
	to_chat(user, span_warning(refusal_text))
	return TRUE

/datum/component/uplink/antag_training/random_item_candidates(mob/user, datum/uplink_item/random_item)
	. = ..()
	for(var/datum/uplink_item/item as anything in .)
		if(blocked_reason(item))
			. -= item

/datum/component/uplink/antag_training/record_random_item(datum/uplink_item/picked)
	return

/datum/component/uplink/antag_training/record_purchase(datum/uplink_item/item, purchase_cost)
	if(item.limited_stock > 0)
		item.limited_stock -= 1

/datum/component/uplink/antag_training/implanting(datum/source, list/arguments)
	return

/datum/component/uplink/antag_training/failsafe(mob/living/carbon/user)
	var/turf/spot = get_turf(parent)
	if(!spot)
		return
	log_game("[key_name(user)] triggered a training uplink failsafe explosion at [AREACOORD(spot)].")
	explosion(parent, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 3, adminlog = FALSE)
	qdel(parent)

/datum/component/uplink/antag_training/MakePurchase(mob/user, datum/uplink_item/U)
	. = ..()
	if(. && user)
		SEND_SIGNAL(user, COMSIG_ANTAG_TRAINING_UPLINK_PURCHASE, U)

/datum/antag_training_exercise/drill/traitor_quiet_kill
	id = "traitor_quiet_kill"
	name = "Тихая ликвидация"
	desc = "В кабинете главы станционного макета сидит учебная цель, у стола лежат секретные документы. Купите снаряжение в аплинке, убейте цель прямо в кабинете, где нет свидетелей, и вынесите документы в зал прибытия."
	sector = "station"
	program = /datum/antag_training_program/antag/traitor
	difficulty = 2
	par_time = 2 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/traitor_purchase, /datum/antag_training_exercise_step/drill/traitor_kill, /datum/antag_training_exercise_step/drill/checked/traitor_extract)

/datum/antag_training_exercise/drill/traitor_quiet_kill/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	var/datum/antag_training_sector/station = session.arena.sectors[sector]
	var/turf/office = station?.landmark_turf("head_office")
	if(!office || !station.landmark_turf("arrivals"))
		return "в станционном макете не найдены кабинет главы или зал прибытия, сбросьте сектор"
	session.exercise_run.add_prop(new ANTAG_TRAINING_TRAITOR_LOOT(office))
	prepare_target(session, "human", office)
	return TRUE

/// Клетки комнаты у метки сектора прогона как множество для проверки места.
/proc/antag_training_mark_room(datum/antag_training_exercise_run/run, mark_id)
	. = list()
	var/datum/antag_training_sector/place = run?.session?.arena?.sectors[run.exercise.sector]
	for(var/turf/tile as anything in antag_training_room_turfs(place?.landmark_turf(mark_id), place))
		.[tile] = TRUE

/datum/antag_training_exercise_step/drill/traitor_purchase
	name = "Купите снаряжение в аплинке"
	hint = "Нажмите кнопку аплинк-импланта на панели действий: откроется магазин InteQ. Купите что-нибудь для тихого убийства, например Energy Dagger в разделе «Stealthy Weapons». Кончились ТК - «Пополнить ТК» в «Моей роли»."
	target_death = "цель погибла раньше, чем вы купили снаряжение"

/datum/antag_training_exercise_step/drill/traitor_purchase/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/body = participant()
	if(body)
		RegisterSignal(body, COMSIG_ANTAG_TRAINING_UPLINK_PURCHASE, PROC_REF(on_purchase))

/datum/antag_training_exercise_step/drill/traitor_purchase/proc/on_purchase(mob/living/source, datum/uplink_item/item)
	SIGNAL_HANDLER
	complete()

/datum/antag_training_exercise_step/drill/traitor_kill
	name = "Убейте цель в кабинете главы"
	hint = "Цель сидит в кабинете главы и сама никуда не уходит. Зайдите внутрь и убейте её там: смерть за дверью кабинета видят свидетели. Не вытаскивайте цель в коридор."
	target_death = null
	var/list/office_turfs

/datum/antag_training_exercise_step/drill/traitor_kill/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	office_turfs = antag_training_mark_room(run, "head_office")
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_kill))

/datum/antag_training_exercise_step/drill/traitor_kill/detach()
	office_turfs = null
	return ..()

/datum/antag_training_exercise_step/drill/traitor_kill/proc/on_kill(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(office_turfs?[get_turf(source)])
		// Тело убитой цели дальше не нужно: взрывчатка, разорвавшая его, не проваливает вынос документов.
		run.release_prop(source)
		complete()
	else
		run?.finish(FALSE, "свидетели: убийство в коридоре")

/datum/antag_training_exercise_step/drill/checked/traitor_extract
	name = "Вынесите документы в зал прибытия"
	hint = "Секретные документы лежат в кабинете главы у стола. Возьмите их в руку или в сумку и дойдите с ними до зала прибытия: шаг засчитается, когда вы с документами окажетесь внутри зала."
	target_death = null
	var/list/arrival_turfs

/datum/antag_training_exercise_step/drill/checked/traitor_extract/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	arrival_turfs = antag_training_mark_room(run, "arrivals")

/datum/antag_training_exercise_step/drill/checked/traitor_extract/detach()
	arrival_turfs = null
	return ..()

/datum/antag_training_exercise_step/drill/checked/traitor_extract/check()
	var/obj/item/loot = run.find_prop(ANTAG_TRAINING_TRAITOR_LOOT)
	var/mob/living/body = participant()
	return loot && body && get(loot.loc, /mob/living) == body && arrival_turfs?[get_turf(loot)]

#undef COMSIG_ANTAG_TRAINING_UPLINK_PURCHASE
#undef ANTAG_TRAINING_TRAITOR_LOOT
