/proc/hk47_status_name(status)
	switch(status)
		if(HK47_STATUS_COVERT)
			return "тайный"
		if(HK47_STATUS_LICENSED)
			return "лицензия ЦК"
		if(HK47_STATUS_BODYGUARD)
			return "частный телохранитель"
		if(HK47_STATUS_EXPIRED)
			return "лицензия истекла"
		if(HK47_STATUS_OUTLAW)
			return "вне закона"
		if(HK47_STATUS_PARDONED)
			return "розыск снят"
	return status

/// Запоминает время для моба в списке WEAKREF -> world.time, заодно выбрасывая записи старше window.
/proc/hk47_remember(list/memory, mob/living/who, window)
	LAZYINITLIST(memory)
	for(var/datum/weakref/key as anything in memory)
		if(world.time - memory[key] > window)
			memory -= key
	var/datum/weakref/who_ref = WEAKREF(who)
	if(who_ref)
		memory[who_ref] = world.time
	return memory

/proc/hk47_recalls(list/memory, mob/living/who, window)
	var/datum/weakref/who_ref = who?.weak_reference
	if(!who_ref)
		return FALSE
	var/when = LAZYACCESS(memory, who_ref)
	return !isnull(when) && world.time - when <= window

/datum/antagonist/hk47
	var/status = HK47_STATUS_COVERT
	var/list/status_path = list(HK47_STATUS_COVERT)
	/// Открытые дела о раскрытой грязной работе: по ним СБ приказано задержать или уничтожить HK. ЦК может закрыть дело.
	var/reveals = 0
	/// Наибольшее число раскрытий за смену: пеленгатор, заказ на ядро и ионное оружие доставляются один раз.
	var/escalation_peak = 0
	/// ЦК отозвал лицензию за смерть члена экипажа; карту СБ может и уничтожить, дело от этого не закрывается.
	var/license_revoked = FALSE
	var/license_number
	var/datum/weakref/license_ref
	/// Общий id записей HK в базе СБ (general и security).
	var/record_id
	var/core_dropped = FALSE
	/// WEAKREF(жертва) -> world.time последнего попадания HK или его слуг.
	var/list/side_hits
	/// WEAKREF(напавший) -> world.time его нападения на HK или охраняемого.
	var/list/aggressors

/datum/antagonist/hk47/proc/apply_status_effects(mob/living/body)
	if(!body)
		return
	RegisterSignal(body, COMSIG_HK47_CONTRACT_COMPLETED, PROC_REF(on_contract_completed))
	RegisterSignal(body, COMSIG_LIVING_DEATH, PROC_REF(on_droid_death))
	RegisterSignal(body, COMSIG_HK_MASTER_CHANGED, PROC_REF(on_master_changed))
	RegisterSignal(body, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_droid_attacked))
	RegisterSignal(body, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_droid_shot))
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death), override = TRUE)
	body.AddComponent(/datum/component/hk_side_hits, src)

/datum/antagonist/hk47/proc/remove_status_effects(mob/living/body)
	if(!body)
		return
	UnregisterSignal(body, list(COMSIG_HK47_CONTRACT_COMPLETED, COMSIG_LIVING_DEATH, COMSIG_HK_MASTER_CHANGED, COMSIG_LIVING_ATTACKER_SET, COMSIG_LIVING_HIT_BY_PROJECTILE))
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	qdel(body.GetComponent(/datum/component/hk_side_hits))

/datum/antagonist/hk47/proc/is_licensed()
	return status == HK47_STATUS_LICENSED || status == HK47_STATUS_BODYGUARD

/datum/antagonist/hk47/proc/set_status(new_status)
	if(status == new_status)
		return FALSE
	status = new_status
	status_path += new_status
	return TRUE

/datum/antagonist/hk47/proc/status_path_text()
	var/list/names = list()
	for(var/step in status_path)
		names += hk47_status_name(step)
	return jointext(names, " -> ")

/// Легенда прибытия: статус, первый контракт и то, что узнаёт станция. Без подходящей цели легенда сводится к тайной.
/datum/antagonist/hk47/proc/assign_legend(legend)
	var/datum/hk_contract/contract = start_legend_contract(legend)
	if(!contract && legend != HK47_STATUS_COVERT)
		legend = HK47_STATUS_COVERT
		contract = start_legend_contract(legend)
	status = legend
	status_path = list(legend)
	var/mob/living/droid = owner.current
	switch(legend)
		if(HK47_STATUS_COVERT)
			var/first_contract = contract ? "Первый контракт уже принят." : "Контракта пока нет: предложения придут в терминал."
			points += HK47_COVERT_ADVANCE_POINTS
			to_chat(droid, span_notice("<b>Легенда: тайное прибытие.</b> Станция о вас не знает: ни лицензии, ни записи в базе СБ. [first_contract] Прикрытия нет, поэтому заказчик выдал аванс: очков на счету - [points], первый модуль шасси можно поставить сразу (терминал, вкладка «МОДУЛИ»)."))
		if(HK47_STATUS_LICENSED)
			issue_license(/obj/item/card/id/hk47_license)
			file_security_record("Лицензированный подрядчик ЦК", "Лицензия ЦК № [license_number]: подрядчик по засекреченному контракту. Работе не препятствовать, вопросы - к главе СБ.")
			station_announce("На борт [station_name()] направлен лицензированный подрядчик ЦК - дроид HK-47, лицензия № [license_number]. Цель контракта засекречена. Работе подрядчика не препятствовать, вопросы - к главе службы безопасности.", "Центральное командование")
			to_chat(droid, span_notice("<b>Легенда: подрядчик ЦК, лицензия № [license_number].</b> Станции объявлено о вас без цели контракта, в базе СБ есть ваша запись, карта лицензии - в слоте ID. Первый контракт от ЦК уже принят."))
		if(HK47_STATUS_BODYGUARD)
			issue_license(/obj/item/card/id/hk47_license/bodyguard)
			file_security_record("Частный телохранитель", "Частный охранный контракт № [license_number], охраняемое лицо не раскрывается. Работе не препятствовать, вопросы - к главе СБ.")
			station_announce("В реестре ЦК зарегистрирован частный охранный контракт № [license_number]: на борт [station_name()] прибывает телохранитель, дроид HK-47. Охраняемое лицо не раскрывается по условиям контракта. Работе телохранителя не препятствовать, вопросы - к главе службы безопасности.", "Реестр частной охраны ЦК")
			to_chat(droid, span_notice("<b>Легенда: частный телохранитель, контракт № [license_number].</b> Охраняемый - [contract.display_target()], он знает о вас из личного сообщения и может поручиться перед СБ. Станции объявлено о контракте без имени охраняемого, в базе СБ есть ваша запись."))
	if(is_licensed())
		RegisterSignal(contract, COMSIG_PARENT_QDELETING, PROC_REF(on_license_contract_closed))
		to_chat(droid, span_warning("Лицензия действует, пока идёт этот контракт, и истекает вместе с ним. Раньше её отзовут, если член экипажа умрёт в течение [DisplayTimeText(HK47_HIT_MEMORY)] после вашего попадания или попадания ваших слуг. Не в счёт цель контракта, разыскиваемые СБ и те, кто за последние [DisplayTimeText(HK47_AGGRESSION_MEMORY)] напал на вас или на охраняемого. Кнопка Show License предъявляет карту всем рядом вместе с полномочиями."))
	antag_memory += "Легенда: [hk47_status_name(legend)][license_number ? ", лицензия № [license_number]" : ""].<br>"
	log_game("[key_name(owner)] прибывает как HK-47 с легендой «[hk47_status_name(legend)]», первый контракт: [contract ? contract.describe() : "нет"].")
	return legend

/// Первый контракт легенды, уже принятый; null, если цели под легенду нет.
/datum/antagonist/hk47/proc/start_legend_contract(legend)
	var/datum/hk_contract/contract = legend_contract(legend)
	if(!contract)
		return null
	// Охраняемому при принятии говорят, может ли он поручиться за HK: это решает статус легенды.
	status = legend
	contract.roll_modifier()
	if(accept(contract))
		return contract
	qdel(contract)
	return null

/datum/antagonist/hk47/proc/legend_contract(legend)
	switch(legend)
		if(HK47_STATUS_LICENSED)
			return make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/hunt) || make_contract(HK_CLIENT_CENTCOM, /datum/hk_contract_task/protect/head)
		if(HK47_STATUS_BODYGUARD)
			return make_contract(HK_CLIENT_PRIVATE, /datum/hk_contract_task/protect)
	for(var/client_id in shuffle(list(HK_CLIENT_SYNDICATE, HK_CLIENT_CORP, HK_CLIENT_PRIVATE)))
		var/list/weights = list()
		var/list/client_weights = task_weights(client_id)
		for(var/task_type in client_weights)
			if(!ispath(task_type, /datum/hk_contract_task/protect))
				weights[task_type] = client_weights[task_type]
		while(length(weights))
			var/task_type = pickweight(weights)
			weights -= task_type
			var/datum/hk_contract/contract = make_contract(client_id, task_type)
			if(contract)
				return contract
	return null

/// Грязный контракт - работа против станции и её людей по заказу не ЦК; охрана чистая у любого заказчика.
/datum/antagonist/hk47/proc/contract_is_dirty(datum/hk_contract/contract)
	return contract.client_id != HK_CLIENT_CENTCOM && !istype(contract.task, /datum/hk_contract_task/protect)

/datum/antagonist/hk47/proc/issue_license(license_type)
	var/mob/living/carbon/human/droid = owner.current
	license_number = "HK-[rand(100, 999)]-[rand(1000, 9999)]"
	var/obj/item/card/id/hk47_license/license = new license_type(null)
	license.license_number = license_number
	license.registered_name = droid?.real_name || HK47_NAME
	license_ref = WEAKREF(license)
	if(istype(droid) && droid.equip_to_slot_if_possible(license, ITEM_SLOT_ID, disable_warning = TRUE))
		return license
	if(droid && !droid.put_in_hands(license))
		license.forceMove(droid.drop_location())
	return license

/datum/antagonist/hk47/proc/security_record()
	return record_id ? GLOB.data_core.security_by_id[record_id] : null

/// Запись HK в базе СБ: general для списка консоли и security со статусом.
/datum/antagonist/hk47/proc/file_security_record(rank, note)
	var/mob/living/droid = owner.current
	var/record_name = droid?.real_name || HK47_NAME
	var/id = num2hex(rand(1, 16777215), 6)
	var/datum/data/record/general = new
	general.fields["id"] = id
	general.fields["name"] = record_name
	general.fields["rank"] = rank
	general.fields["real_rank"] = rank
	general.fields["gender"] = "Male"
	general.fields["age"] = "Unknown"
	general.fields["species"] = "HK"
	general.fields["fingerprint"] = "Нет: дроид"
	general.fields["p_stat"] = "Active"
	general.fields["m_stat"] = "Stable"
	if(ishuman(droid))
		general.photo_source = new /datum/record_photo_source(droid, null, null)
	GLOB.data_core.general += general
	GLOB.data_core.register_record(general, "general")
	var/datum/data/record/security = new
	security.name = "Security Record #[id]"
	security.fields["id"] = id
	security.fields["name"] = record_name
	security.fields["criminal"] = SEC_RECORD_STATUS_NONE
	security.fields["mi_crim"] = list()
	security.fields["ma_crim"] = list()
	security.fields["fines"] = list()
	security.fields["notes"] = note
	security.fields["actions_logs"] = list("<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [record_name] | [rank] | [id] -- ИНИЦИАТОР: Центральное командование;</u><br>")
	LAZYINITLIST(security.fields["comments"])
	GLOB.data_core.security += security
	GLOB.data_core.register_record(security, "security")
	record_id = id
	return security

/datum/antagonist/hk47/proc/note_security_record(note, criminal_status)
	var/datum/data/record/record = security_record()
	if(!record)
		return FALSE
	var/notes = record.fields["notes"]
	record.fields["notes"] = length(notes) ? "[notes] [note]" : note
	if(criminal_status)
		record.fields["criminal"] = criminal_status
	GLOB.data_core.append_sec_logs(record_id, note, "Центральное командование", "ЦК")
	var/mob/living/carbon/human/droid = owner.current
	if(istype(droid))
		droid.sec_hud_set_security_status()
	return TRUE

/// HK объявлен вне закона: лицензия, если была, отозвана, в базе СБ - арест.
/datum/antagonist/hk47/proc/declare_outlaw(note)
	var/obj/item/card/id/hk47_license/license = license_ref?.resolve()
	if(license)
		license.revoked = TRUE
	if(!security_record())
		file_security_record("Дроид-ассасин серии HK", "")
	note_security_record(note, SEC_RECORD_STATUS_ARREST)
	set_status(HK47_STATUS_OUTLAW)

/// Приказ СБ, который следует из открытых дел: уничтожить, задержать или ничего.
/datum/antagonist/hk47/proc/wanted_record_status()
	if(reveals >= HK47_EXECUTE_REVEAL)
		return SEC_RECORD_STATUS_EXECUTE
	if(reveals || license_revoked)
		return SEC_RECORD_STATUS_ARREST
	return SEC_RECORD_STATUS_NONE

/datum/antagonist/hk47/proc/revoke_license(mob/living/victim)
	if(!is_licensed())
		return FALSE
	var/victim_name = victim?.real_name || "член экипажа"
	license_revoked = TRUE
	declare_outlaw("Лицензия № [license_number] отозвана ЦК: погиб [victim_name], не цель контракта. Задержать.")
	station_announce("Лицензия № [license_number] дроида HK-47 отозвана. Дроид вне закона: службе безопасности задержать или вывести его из строя.", "Центральное командование")
	to_chat(owner.current, span_userdanger("Утверждение: ЦК отозвал вашу лицензию за смерть [victim_name]. Вы вне закона, СБ получила приказ на арест."))
	log_game("[key_name(owner)] теряет лицензию HK-47: погиб [key_name(victim)], не цель контракта.")
	message_admins("[ADMIN_LOOKUPFLW(owner.current)] теряет лицензию HK-47: погиб [ADMIN_LOOKUPFLW(victim)], не цель контракта.")
	return TRUE

/datum/antagonist/hk47/proc/on_license_contract_closed(datum/source)
	SIGNAL_HANDLER
	if(!QDELETED(src) && is_licensed())
		INVOKE_ASYNC(src, PROC_REF(expire_license))

/// Контракт, под который выдана лицензия, закрыт: лицензия истекает без розыска.
/datum/antagonist/hk47/proc/expire_license()
	if(!is_licensed())
		return FALSE
	var/obj/item/card/id/hk47_license/license = license_ref?.resolve()
	if(license)
		license.expired = TRUE
	var/bodyguard = status == HK47_STATUS_BODYGUARD
	note_security_record("Лицензия № [license_number] истекла: [bodyguard ? "частный охранный контракт" : "контракт ЦК"] закрыт.")
	if(bodyguard)
		station_announce("Частный охранный контракт № [license_number] закрыт. Лицензия телохранителя HK-47 больше не действует.", "Реестр частной охраны ЦК")
	else
		station_announce("Контракт подрядчика HK-47 закрыт, лицензия № [license_number] больше не действует.", "Центральное командование")
	set_status(HK47_STATUS_EXPIRED)
	to_chat(owner.current, span_warning("Утверждение: контракт под лицензией закрыт, лицензия № [license_number] истекла. Станция о вас помнит, но прикрытия больше нет: раскрытая грязная работа объявит вас вне закона."))
	log_game("[key_name(owner)]: лицензия HK-47 № [license_number] истекла вместе с контрактом.")
	return TRUE

/datum/antagonist/hk47/proc/on_contract_completed(mob/living/source, datum/hk_contract/contract, witnessed)
	SIGNAL_HANDLER
	if(contracts_done == HK47_CONTRACTS_TO_WIN)
		to_chat(source, span_boldnotice("Утверждение: [HK47_CONTRACTS_TO_WIN] контракта выполнены, эвакуация открыта. Встаньте у клетки с открытым космосом и подайте сигнал из терминала. Новую грязную работу ЦК теперь заметит и без свидетелей."))
	if(contract_reveals(contract, witnessed))
		INVOKE_ASYNC(src, PROC_REF(escalate))

/// Грязная работа раскрывает HK при свидетелях, а после выполненных для победы контрактов - всегда.
/datum/antagonist/hk47/proc/contract_reveals(datum/hk_contract/contract, witnessed)
	return contract_is_dirty(contract) && (witnessed || contracts_done > HK47_CONTRACTS_TO_WIN)

/// Раскрытие грязной работы: новое дело поднимает приказ СБ, а пеленгатор, заказ на ядро и ионное оружие доставляются только при первом достижении ступени.
/datum/antagonist/hk47/proc/escalate()
	reveals++
	var/new_peak = reveals > escalation_peak
	escalation_peak = max(escalation_peak, reveals)
	log_game("[key_name(owner)]: раскрытие HK-47 номер [reveals][new_peak ? "" : ", ступень уже пройдена"].")
	message_admins("[ADMIN_LOOKUPFLW(owner.current)]: раскрытие HK-47 номер [reveals].")
	var/datum/data/record/record = security_record()
	var/was_execute = record?.fields["criminal"] == SEC_RECORD_STATUS_EXECUTE
	if(reveals == 1 || status != HK47_STATUS_OUTLAW)
		var/had_license = is_licensed()
		declare_outlaw("Перехвачен сигнал дроида-ассасина HK: выполнен заказ против станции. Задержать.")
		station_announce("Перехвачен закодированный сигнал дроида-ассасина серии HK: на борту [station_name()] работает наёмный убийца, и как минимум один его заказ уже выполнен.[had_license ? " Ранее выданная дроиду HK-47 лицензия аннулирована." : ""] Сообщайте о дроидах серии HK службе безопасности.", "Перехват", ANNOUNCER_INTERCEPT)
		var/next_step = escalation_peak < HK47_TRACKER_REVEAL ? " Следующее раскрытие даст СБ пеленгатор вашего сигнала." : ""
		to_chat(owner.current, span_userdanger("Утверждение: вашу работу видели. ЦК объявил станции о дроиде-ассасине[had_license ? ", лицензия отозвана" : ""], СБ получила приказ на арест.[next_step]"))
	if(reveals == HK47_TRACKER_REVEAL && new_peak)
		deliver_to_brig(new /obj/item/pinpointer/hk47(null, src))
		post_core_bounty()
		note_security_record("В бриг доставлен пеленгатор сигнала дроида HK.")
		station_announce("Службе безопасности: в бриг доставлен пеленгатор сигнала дроида HK. Отделу снабжения: ЦК выкупит ядро памяти дроида, заказ уже в консоли заданий ЦК.", "Перехват", ANNOUNCER_INTERCEPT)
		to_chat(owner.current, span_userdanger("Утверждение: у СБ пеленгатор вашего сигнала, карго ищет ваше ядро. Пеленгатор теряет вас в маскировке и после отключения, а с другого уровня станции показывает, выше вы или ниже. Следующее раскрытие - приказ на уничтожение и ионное оружие для СБ."))
	else if(reveals >= HK47_EXECUTE_REVEAL && !was_execute)
		note_security_record("Дроид HK-47 продолжает выполнять заказы против станции. Приказ - уничтожить.", SEC_RECORD_STATUS_EXECUTE)
		if(reveals == HK47_EXECUTE_REVEAL && new_peak)
			deliver_to_brig(new /obj/structure/closet/crate/secure/weapon/hk47_countermeasures)
			station_announce("Службе безопасности: дроид-ассасин HK снова выполнил заказ против станции. Приказ - уничтожить. В бриг доставлен ящик с ионной винтовкой и ЭМИ-гранатами, он открывается доступом СБ.", "Перехват", ANNOUNCER_INTERCEPT)
			to_chat(owner.current, span_userdanger("Утверждение: СБ приказано вас уничтожить, в бриге ионная винтовка и ЭМИ-гранаты."))
		else
			station_announce("Службе безопасности: дроид-ассасин HK снова выполнил заказ против станции. Приказ - уничтожить.", "Перехват", ANNOUNCER_INTERCEPT)
			to_chat(owner.current, span_userdanger("Утверждение: СБ снова приказано вас уничтожить. Ионное оружие ЦК уже в бриге, второго ящика не будет."))
	else if(reveals > 1)
		note_security_record("Дроид HK-47 снова выполнил заказ против станции.")
		to_chat(owner.current, span_userdanger("Утверждение: вашу работу снова видели, открытых дел: [reveals]. Всё, что ЦК шлёт против вас, СБ уже получила."))

/datum/antagonist/hk47/proc/station_announce(text, title, sound)
	priority_announce(text, title, sound)

/datum/antagonist/hk47/proc/notify_vip(mob/living/vip, text)
	to_chat(vip, span_boldnotice(text))

/datum/antagonist/hk47/proc/deliver_to_brig(atom/movable/cargo)
	var/turf/landing = hk47_floor_in_areas(HK47_TRACKER_AREAS)
	if(!landing)
		stack_trace("HK-47: на станции нет пола СБ для пеленгатора.")
		qdel(cargo)
		return
	var/obj/structure/closet/supplypod/centcompod/pod = new
	cargo.forceMove(pod)
	new /obj/effect/pod_landingzone(landing, pod)

/datum/antagonist/hk47/proc/post_core_bounty()
	if(!length(GLOB.bounties_list))
		setup_bounties()
	var/datum/bounty/item/hk47_core/bounty = new
	bounty.mark_high_priority()
	return try_add_bounty(bounty)

/// Попадание HK или его слуги: память для лицензии и модификаторов, а удар по цели контракта - решающий момент для свидетелей.
/datum/antagonist/hk47/proc/note_side_hit(mob/living/victim)
	if(!isliving(victim) || is_hk_side(victim))
		return
	side_hits = hk47_remember(side_hits, victim, HK47_HIT_MEMORY)
	if(active_contract && victim == active_contract.target_body())
		active_contract.note_witnesses()
	if(victim.stat == DEAD && victim.timeofdeath == world.time)
		on_side_kill(victim)

/datum/antagonist/hk47/proc/recent_side_hit(mob/living/victim)
	return hk47_recalls(side_hits, victim, HK47_HIT_MEMORY)

/datum/antagonist/hk47/proc/note_aggressor(mob/living/attacker)
	if(isliving(attacker) && !is_hk_side(attacker))
		aggressors = hk47_remember(aggressors, attacker, HK47_AGGRESSION_MEMORY)

/datum/antagonist/hk47/proc/on_droid_attacked(mob/living/source, mob/living/attacker)
	SIGNAL_HANDLER
	note_aggressor(attacker)

/datum/antagonist/hk47/proc/on_droid_shot(mob/living/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	note_aggressor(projectile.firer)

/datum/antagonist/hk47/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(recent_side_hit(died))
		on_side_kill(died)

/// Смерть вскоре после попадания HK или слуги: лишняя жертва для контракта, а при лицензии - повод её отозвать.
/datum/antagonist/hk47/proc/on_side_kill(mob/living/victim)
	if(active_contract?.modifier?.tracks_collateral)
		active_contract.note_collateral(victim)
	if(is_licensed() && !license_kill_excused(victim))
		INVOKE_ASYNC(src, PROC_REF(revoke_license), victim)

/datum/antagonist/hk47/proc/license_kill_excused(mob/living/died)
	var/datum/mind/died_mind = died.mind
	if(!died_mind || died_mind == owner || !(died_mind in crew_minds()))
		return TRUE
	if(active_contract && !istype(active_contract.task, /datum/hk_contract_task/protect) && died_mind == active_contract.target_mind())
		return TRUE
	return hk47_wanted_by_security(died_mind) || hk47_recalls(aggressors, died, HK47_AGGRESSION_MEMORY)

/datum/antagonist/hk47/proc/on_droid_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	var/turf/drop = get_turf(source)
	if(core_dropped || !drop)
		return
	core_dropped = TRUE
	new /obj/item/hk47_core(drop)
	source.visible_message(span_danger("Из треснувшей головы [source] выпадает ядро памяти."))

/obj/item/card/id/hk47_license
	name = "HK-47 contractor license"
	desc = "Лицензия ЦК подрядчика по засекреченному контракту. Номер лицензии выбит на карте, статус обновляется по сети ЦК."
	icon_state = "centcom"
	assignment = "Лицензированный подрядчик ЦК"
	uses_overlays = FALSE
	bank_support = ID_NO_BANK_ACCOUNT
	actions_types = list(/datum/action/item_action/hk47_show_license)
	var/license_number
	var/revoked = FALSE
	var/expired = FALSE
	var/terms = "Подрядчик ЦК по засекреченному контракту, цель не раскрывается. Работе не препятствовать, вопросы - к главе СБ. Доступа в помещения лицензия не даёт."
	COOLDOWN_DECLARE(present_cooldown)

/obj/item/card/id/hk47_license/examine(mob/user)
	. = ..()
	. += license_text()

/obj/item/card/id/hk47_license/proc/license_text()
	if(revoked)
		return "Лицензия № [license_number]: [span_danger("ОТОЗВАНА")]. Дроид вне закона, службе безопасности приказано его задержать."
	if(expired)
		return "Лицензия № [license_number]: [span_warning("ИСТЕКЛА")]. Контракт закрыт, полномочий у дроида больше нет."
	return "Лицензия № [license_number]: [span_notice("действительна")]. [terms] Действует, пока идёт контракт. Если член экипажа, не цель контракта, погибнет после попадания дроида, ЦК отзовёт лицензию и СБ получит приказ задержать."

/obj/item/card/id/hk47_license/attack_self(mob/user)
	present(user)

/obj/item/card/id/hk47_license/ui_action_click(mob/user, action)
	present(user)

/obj/item/card/id/hk47_license/proc/present(mob/living/user)
	if(!COOLDOWN_FINISHED(src, present_cooldown) || user.incapacitated())
		return
	COOLDOWN_START(src, present_cooldown, HK47_LICENSE_PRESENT_COOLDOWN)
	add_fingerprint(user)
	user.visible_message(span_notice("[user] предъявляет [icon2html(src, viewers(user))] [name]. [license_text()]"), span_notice("Вы предъявляете лицензию. [license_text()]"))

/obj/item/card/id/hk47_license/bank_examine(mob/user)
	return list()

/obj/item/card/id/hk47_license/bodyguard
	name = "HK-47 bodyguard license"
	desc = "Карта частного телохранителя из реестра ЦК. Охраняемое лицо на карте не указано, номер контракта выбит, статус обновляется по сети ЦК."
	icon_state = "silver"
	assignment = "Частный телохранитель"
	terms = "Частный телохранитель из реестра ЦК. Охраняемое лицо не указано, но может само поручиться за дроида. Работе не препятствовать, вопросы - к главе СБ. Доступа в помещения лицензия не даёт."

/datum/action/item_action/hk47_show_license
	name = "Show License"
	desc = "Предъявить лицензию всем, кто рядом: номер, статус и полномочия."

/obj/item/pinpointer/hk47
	name = "HK signal tracker"
	desc = "Пеленгатор ЦК, настроенный на сигнал дроида-ассасина HK-47. Стрелка ведёт к дроиду на этом же уровне, а с другого уровня станции пеленгатор подсказывает, выше сигнал или ниже. Отключённый или замаскированный дроид сигнала не даёт, но маяк его эвакуации ловится и сквозь маскировку. Пеленгатор работает, пока дроид в розыске: снимет ЦК розыск - сигнал пропадёт."
	var/datum/weakref/hunter_ref
	/// Уровень сигнала, о котором пеленгатор уже сообщил владельцу.
	var/reported_level

/obj/item/pinpointer/hk47/Initialize(mapload, datum/antagonist/hk47/hunter)
	. = ..()
	hunter_ref = WEAKREF(hunter)

/// Дроид, на которого указывает стрелка, или null, если сигнал потерян.
/obj/item/pinpointer/hk47/proc/signal_source()
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	var/mob/living/droid = hunter?.owner?.current
	if(!droid || droid.stat == DEAD || hunter.status != HK47_STATUS_OUTLAW)
		return null
	if(HAS_TRAIT(droid, TRAIT_HK47_DISGUISED) && !hunter.extracting)
		return null
	if(!hk47_level_relation(get_turf(src), get_turf(droid)))
		return null
	return droid

/obj/item/pinpointer/hk47/proc/signal_level()
	var/mob/living/droid = signal_source()
	return droid ? hk47_level_relation(get_turf(src), get_turf(droid)) : null

/obj/item/pinpointer/hk47/scan_for_target()
	var/mob/living/droid = signal_source()
	if(droid != target)
		if(droid)
			set_target(droid)
		else
			unset_target()
	var/level = droid ? hk47_level_relation(get_turf(src), get_turf(droid)) : null
	if(level == reported_level)
		return
	reported_level = level
	var/mob/holder = loc
	if(!ismob(holder))
		return
	if(level == HK47_LEVEL_ABOVE)
		balloon_alert(holder, "сигнал выше")
	else if(level == HK47_LEVEL_BELOW)
		balloon_alert(holder, "сигнал ниже")

/obj/item/pinpointer/hk47/examine(mob/user)
	. = ..()
	switch(signal_level())
		if(HK47_LEVEL_SAME)
			. += span_notice("Сигнал HK-47 устойчивый.")
		if(HK47_LEVEL_ABOVE)
			. += span_notice("Сигнал HK-47 идёт сверху: дроид выше, на другом уровне.")
		if(HK47_LEVEL_BELOW)
			. += span_notice("Сигнал HK-47 идёт снизу: дроид ниже, на другом уровне.")
		else
			. += span_warning("Сигнал HK-47 потерян: дроид отключён, замаскирован, далеко от станции или больше не в розыске.")

/obj/item/hk47_core
	name = "HK-47 memory core"
	desc = "Ядро памяти дроида-ассасина HK-47: журнал контрактов, ключи заказчиков и архив «мешков с мясом». ЦК выкупает такие ядра через отдел снабжения."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain"
	item_state = "hk47_core"
	lefthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/hk_droids/hk_droids_righthand.dmi'
	color = "#c8804a"
	w_class = WEIGHT_CLASS_SMALL

/datum/bounty/item/hk47_core
	name = "HK-47 Memory Core"
	description = "ЦК нужен журнал контрактов дроида-ассасина HK-47. Отправьте его ядро памяти: оно выпадает из головы отключённого дроида."
	reward = HK47_CORE_BOUNTY_REWARD
	wanted_types = list(/obj/item/hk47_core)

/obj/structure/closet/crate/secure/weapon/hk47_countermeasures
	name = "HK countermeasures crate"
	desc = "Ящик ЦК для службы безопасности: ионная винтовка и коробка ЭМИ-гранат против дроида-ассасина HK. Открывается доступом СБ."
	req_access = list(ACCESS_SECURITY)

/obj/structure/closet/crate/secure/weapon/hk47_countermeasures/PopulateContents()
	new /obj/item/gun/energy/ionrifle(src)
	new /obj/item/storage/box/emps(src)

/// Попадания тела на стороне HK-47 - самого HK, NPC HK-50, HK-50 с разумом - уходят в учёт антагониста.
/datum/component/hk_side_hits
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/hunter_ref
	var/list/watched_guns

/datum/component/hk_side_hits/Initialize(datum/antagonist/hk47/hunter)
	if(!isliving(parent) || !istype(hunter))
		return COMPONENT_INCOMPATIBLE
	hunter_ref = WEAKREF(hunter)

/datum/component/hk_side_hits/RegisterWithParent()
	RegisterSignals(parent, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_HOSTILE_ATTACKINGTARGET), PROC_REF(on_struck))
	RegisterSignal(parent, COMSIG_PROJECTILE_ON_HIT, PROC_REF(on_projectile_hit))
	RegisterSignal(parent, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_equipped))
	var/mob/living/body = parent
	for(var/obj/item/gun/gun in body.GetAllContents())
		watch_gun(gun)

/datum/component/hk_side_hits/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_SET_AS_ATTACKER, COMSIG_HOSTILE_ATTACKINGTARGET, COMSIG_PROJECTILE_ON_HIT, COMSIG_MOB_EQUIPPED_ITEM))
	for(var/obj/item/gun/gun as anything in watched_guns)
		UnregisterSignal(gun, list(COMSIG_PROJECTILE_ON_HIT, COMSIG_PARENT_QDELETING))
	watched_guns = null

/datum/component/hk_side_hits/proc/watch_gun(obj/item/gun/gun)
	if(gun in watched_guns)
		return
	LAZYADD(watched_guns, gun)
	RegisterSignal(gun, COMSIG_PROJECTILE_ON_HIT, PROC_REF(on_projectile_hit))
	RegisterSignal(gun, COMSIG_PARENT_QDELETING, PROC_REF(on_gun_deleted))

/datum/component/hk_side_hits/proc/on_gun_deleted(obj/item/gun/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_PROJECTILE_ON_HIT, COMSIG_PARENT_QDELETING))
	LAZYREMOVE(watched_guns, source)

/datum/component/hk_side_hits/proc/on_equipped(mob/living/source, obj/item/equipped, slot)
	SIGNAL_HANDLER
	if(istype(equipped, /obj/item/gun))
		watch_gun(equipped)
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	if(hunter && source == hunter.owner?.current)
		hunter.active_contract?.on_hunter_took(equipped)

/datum/component/hk_side_hits/proc/on_struck(mob/living/source, atom/victim)
	SIGNAL_HANDLER
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	hunter?.note_side_hit(victim)

/// Сигнал приходит уже после урона и от любого стрелка: оружие HK могли подобрать чужие.
/datum/component/hk_side_hits/proc/on_projectile_hit(atom/source, atom/movable/firer, atom/target, angle)
	SIGNAL_HANDLER
	var/datum/antagonist/hk47/hunter = hunter_ref?.resolve()
	if(hunter?.is_hk_side(firer))
		hunter.note_side_hit(target)
