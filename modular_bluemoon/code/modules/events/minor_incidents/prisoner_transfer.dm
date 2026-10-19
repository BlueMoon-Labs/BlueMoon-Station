#define PRISONER_TRANSFER_UPKEEP 300
/// Содержание платится двумя частями: при приёме и по окончании срока.
#define PRISONER_TRANSFER_INSTALLMENT (PRISONER_TRANSFER_UPKEEP / 2)
#define PRISONER_TRANSFER_MIN_TERM 10
#define PRISONER_TRANSFER_MAX_TERM 20
#define PRISONER_TRANSFER_ALERT_COOLDOWN (1 MINUTES)
#define PRISONER_TRANSFER_RANK "Transfer Prisoner"
#define PRISONER_TRANSFER_COURT "Центральный суд NanoTrasen"

/datum/round_event_control/prisoner_transfer
	name = "Prisoner Transfer"
	typepath = /datum/round_event/ghost_role/prisoner_transfer
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	min_players = 15
	min_staffing = list(DIRECTOR_DEPT_SECURITY = 2)
	severity = DIRECTOR_SEVERITY_MINOR
	category = EVENT_CATEGORY_FRIENDLY
	family = "prisoner_transfer"
	director_ghost_jobban = ROLE_GHOSTROLE
	/// Камеры и зона оформления брига, куда садится капсула.
	var/list/landing_area_types = list(/area/security/brig, /area/security/brig_cells, /area/security/holding_cell, /area/security/prison, /area/security/processing)

/datum/round_event_control/prisoner_transfer/New()
	. = ..()
	description = "ЦК этапирует на станцию заключённого за мелкое ненасильственное нарушение: капсула садится в бриг, заключённый заносится в базу СБ. Содержание - [PRISONER_TRANSFER_INSTALLMENT] кредитов при приёме и ещё [PRISONER_TRANSFER_INSTALLMENT], если к концу срока он в бриге или трудовом лагере; если он выходит оттуда без конвоя сотрудника СБ (в том числе в шкафу или мешке), датчик сообщает в канал СБ. Заключённый - гост-роль, не антагонист."

/datum/round_event_control/prisoner_transfer/proc/get_landing_turfs(first_only = FALSE)
	var/list/result = list()
	for(var/area/location as anything in minor_crew_station_areas(landing_area_types))
		result += minor_crew_area_floors(location, first_only)
		if(first_only && length(result))
			return result
	return result

/datum/round_event_control/prisoner_transfer/director_preflight()
	if(!length(get_landing_turfs(first_only = TRUE)))
		director_preflight_detail = "На станции нет брига, куда может сесть капсула."
		director_preflight_failure = director_preflight_detail
		return FALSE
	return ..()

/datum/round_event/ghost_role/prisoner_transfer
	role_name = "этапированный заключённый"
	minimum_required = 1
	fakeable = FALSE
	var/prisoner_number
	var/crime
	var/term
	var/landing_area_name
	var/datum/weakref/prisoner_ref
	var/datum/weakref/card_ref
	var/upkeep_paid = FALSE
	var/term_over = FALSE
	/// Вне мест заключения без конвоя, пока идёт срок.
	var/at_large = FALSE
	var/area/last_area
	/// Шкаф, мешок или кресло с заключённым и всё, во что они вложены: их перемещения тоже двигают датчик.
	var/list/atom/movable/watched_holders = list()
	COOLDOWN_DECLARE(escape_alert_cooldown)
	var/static/list/crimes = list(
		"вынос с Центрального командования тридцати семи казённых степлеров",
		"подделку подписи начальника смены на заявлении об отпуске",
		"систематическое хищение обедов из общего холодильника отдела кадров",
		"торговлю «целебной» водой из охладителя суперматерии",
		"рассылку любовных писем через служебный факс ЦК",
		"подпольный тотализатор на гонках уборочных ботов",
		"продажу поддельных билетов на эвакуационный шаттл",
		"переименование всех файлов архива ЦК в «Новый документ (2)»",
		"кормление космических карпов через служебный шлюз",
		"уклонение от обязательного корпоративного тимбилдинга пятый раз подряд",
		"взлом торгового автомата ради бесплатной газировки",
		"разведение хомяков в вентиляции общежития",
		"распространение слухов о закрытии столовой Центрального командования",
		"провоз сигарет Синдиката в коробках из-под пластырей",
		"заверение рецептов пиццы печатью капитана",
	)

/datum/round_event/ghost_role/prisoner_transfer/setup()
	prisoner_number = rand(1000, 9999)
	crime = pick(crimes)
	term = rand(PRISONER_TRANSFER_MIN_TERM, PRISONER_TRANSFER_MAX_TERM) MINUTES

/datum/round_event/ghost_role/prisoner_transfer/proc/get_landing_turfs()
	var/datum/round_event_control/prisoner_transfer/transfer = control
	return transfer?.get_landing_turfs()

/datum/round_event/ghost_role/prisoner_transfer/spawn_role()
	var/list/landing_turfs = get_landing_turfs()
	if(!length(landing_turfs))
		return MAP_ERROR
	var/mob/dead/selected
	for(var/mob/dead/candidate as anything in get_candidates(ROLE_GHOSTROLE, null, null))
		if(candidate.key && candidate.client)
			selected = candidate
			break
	if(!selected)
		return NOT_ENOUGH_PLAYERS
	var/turf/landing = pick(landing_turfs)
	landing_area_name = get_area_name(landing, TRUE)
	var/obj/structure/closet/supplypod/centcompod/pod = new()
	pod.delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 2 SECONDS)
	var/mob/living/carbon/human/prisoner = new(pod)
	selected.client.prefs.copy_to(prisoner)
	selected.client.prefs.apply_prefs_modified_limbs(prisoner)
	prisoner.dna.update_dna_identity()
	prepare_prisoner(prisoner)
	var/datum/mind/prisoner_mind = new /datum/mind(selected.key)
	prisoner_mind.active = TRUE
	prisoner_mind.transfer_to(prisoner)
	register_prisoner(prisoner)
	file_security_record(prisoner)
	new /obj/effect/pod_landingzone(landing, pod)
	greet(prisoner)
	spawned_mobs += prisoner
	message_admins("[ADMIN_LOOKUPFLW(prisoner)] этапирован на станцию событием Prisoner Transfer.")
	log_game("DIRECTOR: [control?.name], [key_name(prisoner)] - заключённый #[prisoner_number], капсула летит в отсек [landing_area_name].")
	return SUCCESSFUL_SPAWN

/// Роба, обувь, наручники, карта без доступа и приговор в кармане.
/datum/round_event/ghost_role/prisoner_transfer/proc/prepare_prisoner(mob/living/carbon/human/prisoner)
	prisoner.dna.species.before_equip_job(null, prisoner)
	prisoner.equipOutfit(/datum/outfit/transfer_prisoner)
	var/obj/item/card/id/prisoner/transfer/card = new(prisoner)
	card.assign_sentence(prisoner_number, crime, term)
	if(prisoner.equip_to_slot_or_del(card, ITEM_SLOT_ID))
		card_ref = WEAKREF(card)
	var/obj/item/paper/prisoner_sentence/sentence = new(prisoner)
	sentence.write_sentence(prisoner.real_name, prisoner_number, crime, term)
	if(!prisoner.equip_to_slot_if_possible(sentence, ITEM_SLOT_LPOCKET, disable_warning = TRUE))
		sentence.forceMove(prisoner.drop_location())
	stow_held_tanks(prisoner)
	if(!prisoner.handcuffed)
		prisoner.handcuffed = new /obj/item/restraints/handcuffs(prisoner)
		prisoner.update_handcuffed()

/// Наручники роняют всё из рук: баллоны плазмамена или вокса уходят в слоты, дыхание из баллона не прерывается.
/datum/round_event/ghost_role/prisoner_transfer/proc/stow_held_tanks(mob/living/carbon/human/prisoner)
	var/static/list/tank_slots = list(ITEM_SLOT_BELT, ITEM_SLOT_BACK, ITEM_SLOT_SUITSTORE, ITEM_SLOT_RPOCKET)
	var/obj/item/tank/breathing = prisoner.internal
	for(var/obj/item/tank/tank in prisoner.held_items)
		for(var/slot in tank_slots)
			if(prisoner.equip_to_slot_if_possible(tank, slot, disable_warning = TRUE))
				break
	if(breathing && breathing.loc == prisoner && !(breathing in prisoner.held_items))
		prisoner.internal = breathing
		prisoner.update_action_buttons_icon()

/// Гост-роль: не экипаж и не кандидат в мидраунд-антаги.
/datum/round_event/ghost_role/prisoner_transfer/proc/register_prisoner(mob/living/carbon/human/prisoner)
	prisoner.mind?.assigned_role = "Ghost Role"
	ADD_TRAIT(prisoner, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)
	ADD_TRAIT(prisoner, TRAIT_EXEMPT_HEALTH_EVENTS, GHOSTROLE_TRAIT)
	prisoner_ref = WEAKREF(prisoner)
	RegisterSignal(prisoner, COMSIG_MOVABLE_MOVED, PROC_REF(on_carrier_moved))

/// Общая, медицинская и криминальная записи, как у осуждённого с консоли СБ: статья, срок и статус.
/datum/round_event/ghost_role/prisoner_transfer/proc/file_security_record(mob/living/carbon/human/prisoner)
	var/record_id = num2hex(rand(1, 16777215), 6)
	var/timestamp = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	var/datum/data/record/general = new
	general.fields["id"] = record_id
	general.fields["name"] = prisoner.real_name
	general.fields["rank"] = PRISONER_TRANSFER_RANK
	general.fields["real_rank"] = PRISONER_TRANSFER_RANK
	general.fields["age"] = prisoner.age
	general.fields["species"] = prisoner.dna.species.name
	general.fields["fingerprint"] = md5(prisoner.dna.uni_identity)
	general.fields["gender"] = prisoner.gender == MALE ? "Male" : (prisoner.gender == FEMALE ? "Female" : "Other")
	general.fields["p_stat"] = "Active"
	general.fields["m_stat"] = "Stable"
	general.photo_source = new /datum/record_photo_source(prisoner)
	GLOB.data_core.general += general
	GLOB.data_core.register_record(general, "general")

	var/datum/data/record/medical = new
	medical.fields["id"] = record_id
	medical.fields["name"] = prisoner.real_name
	medical.fields["blood_type"] = prisoner.dna.blood_type
	medical.fields["b_dna"] = prisoner.dna.unique_enzymes
	medical.fields["mi_dis"] = "None"
	medical.fields["mi_dis_d"] = "No minor disabilities have been declared."
	medical.fields["ma_dis"] = "None"
	medical.fields["ma_dis_d"] = "No major disabilities have been diagnosed."
	medical.fields["alg"] = "None"
	medical.fields["alg_d"] = "No allergies have been detected in this patient."
	medical.fields["cdi"] = "None"
	medical.fields["cdi_d"] = "No diseases have been diagnosed at the moment."
	medical.fields["notes"] = "No notes."
	GLOB.data_core.medical += medical
	GLOB.data_core.register_record(medical, "medical")

	var/datum/data/record/security = new
	security.name = "Security Record #[record_id]"
	security.fields["id"] = record_id
	security.fields["name"] = prisoner.real_name
	security.fields["criminal"] = SEC_RECORD_STATUS_INCARCERATED
	var/datum/data/crime/conviction = GLOB.data_core.createCrimeEntry(capitalize(crime), "[term / (1 MINUTES)] минут содержания в бриге станции, этапный номер #[prisoner_number].", PRISONER_TRANSFER_COURT, timestamp, TRUE)
	security.fields["mi_crim"] = list(conviction)
	security.fields["ma_crim"] = list()
	security.fields["fines"] = list()
	security.fields["notes"] = "Этапирован Центральным командованием. Насилие не установлено. Вторая часть содержания выплачивается, если к концу срока заключённый в бриге или трудовом лагере."
	security.fields["actions_logs"] = list("<u>[GLOB.current_date_string] | [timestamp] ЗАПИСЬ НАЧАТА. СУБЪЕКТ - [prisoner.real_name] | [PRISONER_TRANSFER_RANK] | [record_id] -- ИНИЦИАТОР: [PRISONER_TRANSFER_COURT];</u><br>")
	LAZYINITLIST(security.fields["comments"])
	GLOB.data_core.security += security
	GLOB.data_core.register_record(security, "security")
	prisoner.sec_hud_set_security_status()
	return security

/datum/round_event/ghost_role/prisoner_transfer/proc/greet(mob/living/carbon/human/prisoner)
	to_chat(prisoner, span_boldannounce("Вы - этапированный заключённый #[prisoner_number]."))
	to_chat(prisoner, span_notice("Центральное командование отправило вас отбывать срок на станции: [term / (1 MINUTES)] минут за [crime]. Приговор лежит в кармане, статья и срок уже в базе СБ."))
	to_chat(prisoner, span_warning("Вы не антагонист. Можно ролевым образом пытаться сбежать, хитрить, торговаться с охраной или подать апелляцию, но без убийств, тяжёлых травм и диверсий. Мидраунд-антагонистом вас не выберут."))
	to_chat(prisoner, span_notice("Под кожей у вас этапный датчик: если без конвоя охраны выйти из отсеков СБ или трудового лагеря, он сообщит охране, где вы. Шкаф или мешок его не заглушит. Когда срок выйдет, ID-карта пискнет: попросите охрану вас отпустить."))

/// Датчик сверяет отсек самого заключённого, как бы его ни перемещали: пешком, в шкафу, в мешке или на кресле.
/datum/round_event/ghost_role/prisoner_transfer/proc/on_carrier_moved(datum/source)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/prisoner = prisoner_ref?.resolve()
	if(!prisoner)
		stop_tracking(null)
		return
	if(!upkeep_paid)
		if(!isturf(prisoner.loc))
			return
		begin_term()
	watch_holders(prisoner)
	var/area/current = get_area(prisoner)
	if(current == last_area)
		return
	var/area/previous = last_area
	last_area = current
	if(previous)
		on_prisoner_area(prisoner, current)

/// Капсула раскрылась: заключённый на полу брига, ЦК платит первую часть содержания, срок пошёл.
/datum/round_event/ghost_role/prisoner_transfer/proc/begin_term()
	pay_upkeep()
	var/obj/item/card/id/prisoner/transfer/card = card_ref?.resolve()
	if(card)
		card.sentence = world.time + term
	addtimer(CALLBACK(src, PROC_REF(serve_term)), term, TIMER_DELETE_ME)

/datum/round_event/ghost_role/prisoner_transfer/proc/watch_holders(mob/living/prisoner)
	if(isturf(prisoner.loc) && !length(watched_holders))
		return
	var/list/atom/movable/holders = list()
	for(var/atom/movable/holder = prisoner.loc, ismovable(holder), holder = holder.loc)
		holders += holder
	for(var/atom/movable/old_holder as anything in watched_holders - holders)
		UnregisterSignal(old_holder, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	for(var/atom/movable/new_holder as anything in holders - watched_holders)
		RegisterSignal(new_holder, COMSIG_MOVABLE_MOVED, PROC_REF(on_carrier_moved))
		RegisterSignal(new_holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))
	watched_holders = holders

/datum/round_event/ghost_role/prisoner_transfer/proc/on_holder_deleted(atom/movable/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	watched_holders -= source

/datum/round_event/ghost_role/prisoner_transfer/proc/pay_upkeep()
	if(upkeep_paid)
		return FALSE
	upkeep_paid = TRUE
	var/paid = minor_crew_pay_department(ACCOUNT_SEC, PRISONER_TRANSFER_INSTALLMENT, "ЦК: приём заключённого #[prisoner_number]")
	log_game("DIRECTOR: [control?.name], заключённый #[prisoner_number] доставлен в [landing_area_name][paid ? ", в бюджет СБ переведено [PRISONER_TRANSFER_INSTALLMENT] кр." : ", бюджета СБ нет."]")
	return paid

/// Бриг станции, трудовой лагерь или челнок до него.
/proc/prisoner_transfer_custody_area(area/location)
	return istype(location, /area/security) || istype(location, /area/mine/laborcamp) || istype(location, /area/shuttle/labor)

/proc/prisoner_transfer_is_guard(mob/living/guard)
	if(!isliving(guard) || guard.stat != CONSCIOUS)
		return FALSE
	var/obj/item/card/id/card = guard.get_idcard(TRUE)
	return card && (ACCESS_SECURITY in card.GetAccess())

/datum/round_event/ghost_role/prisoner_transfer/proc/in_custody(mob/living/prisoner)
	var/turf/location = get_turf(prisoner)
	if(!prisoner || prisoner.stat == DEAD || !location)
		return FALSE
	var/area/location_area = location.loc
	if(!prisoner_transfer_custody_area(location_area))
		return FALSE
	return is_station_level(location.z) || !istype(location_area, /area/security)

/// Заключённого, его кресло, шкаф или мешок с ним ведёт конвой: тянет или несёт на себе.
/datum/round_event/ghost_role/prisoner_transfer/proc/escorted(mob/living/prisoner)
	var/list/atom/movable/carried = list(prisoner)
	if(prisoner.buckled)
		carried += prisoner.buckled
	for(var/atom/movable/holder = prisoner.loc, ismovable(holder), holder = holder.loc)
		carried += holder
	for(var/atom/movable/thing as anything in carried)
		if(prisoner_transfer_is_guard(thing.pulledby) || (thing != prisoner && prisoner_transfer_is_guard(thing)))
			return TRUE
	return FALSE

/// Датчик: выход из брига или лагеря без конвоя во время срока - побег, возвращение - снова под стражей.
/datum/round_event/ghost_role/prisoner_transfer/proc/on_prisoner_area(mob/living/carbon/human/prisoner, area/new_area)
	if(!upkeep_paid || prisoner.stat == DEAD)
		return
	var/inside = prisoner_transfer_custody_area(new_area)
	if(term_over)
		if(!inside)
			log_game("DIRECTOR: [control?.name], [key_name(prisoner)] - заключённый #[prisoner_number] после срока вышел из-под стражи в [new_area.name], освобождён.")
			stop_tracking(prisoner)
		return
	if(inside)
		if(at_large)
			at_large = FALSE
			log_game("DIRECTOR: [control?.name], [key_name(prisoner)] - заключённый #[prisoner_number] снова под стражей ([new_area.name]).")
			paperwork_radio("Этапный датчик: заключённый #[prisoner_number] снова в отсеке [new_area.name].", RADIO_CHANNEL_SECURITY)
		return
	if(at_large || escorted(prisoner))
		return
	at_large = TRUE
	log_game("DIRECTOR: [control?.name], [key_name(prisoner)] - заключённый #[prisoner_number] покинул место заключения без конвоя: [new_area.name].")
	if(!COOLDOWN_FINISHED(src, escape_alert_cooldown))
		return
	COOLDOWN_START(src, escape_alert_cooldown, PRISONER_TRANSFER_ALERT_COOLDOWN)
	paperwork_radio("Этапный датчик: заключённый #[prisoner_number] покинул место заключения без конвоя, сейчас в отсеке [new_area.name].", RADIO_CHANNEL_SECURITY)

/// Срок вышел: вторая часть содержания, если заключённый жив и под стражей; директор больше не считает его нагрузкой.
/datum/round_event/ghost_role/prisoner_transfer/proc/serve_term()
	if(term_over)
		return FALSE
	term_over = TRUE
	at_large = FALSE
	var/mob/living/carbon/human/prisoner = prisoner_ref?.resolve()
	var/obj/item/card/id/prisoner/transfer/card = card_ref?.resolve()
	card?.sentence_served()
	release_director_load(prisoner)
	var/custody = in_custody(prisoner)
	var/paid = custody && minor_crew_pay_department(ACCOUNT_SEC, PRISONER_TRANSFER_INSTALLMENT, "ЦК: содержание заключённого #[prisoner_number], срок отбыт")
	if(custody)
		paperwork_radio("Заключённый #[prisoner_number] отбыл срок. [paid ? "В бюджет СБ переведена вторая часть содержания - [PRISONER_TRANSFER_INSTALLMENT] кредитов." : "Бюджета СБ нет, вторую часть содержания перевести некуда."] Заключённого можно освобождать.", RADIO_CHANNEL_SECURITY)
	else
		paperwork_radio("Срок заключённого #[prisoner_number] истёк, но ни в бриге, ни в трудовом лагере его нет: вторая часть содержания не выплачивается.", RADIO_CHANNEL_SECURITY)
		stop_tracking(prisoner)
	var/state = custody ? "под стражей" : (!prisoner ? "тела нет" : (prisoner.stat == DEAD ? "мёртв" : "не под стражей"))
	log_game("DIRECTOR: [control?.name], [prisoner ? key_name(prisoner) : "?"] - заключённый #[prisoner_number] отбыл срок: [state][paid ? ", в бюджет СБ переведено [PRISONER_TRANSFER_INSTALLMENT] кр." : ", без второй части содержания."]")
	return paid

/datum/round_event/ghost_role/prisoner_transfer/proc/stop_tracking(mob/living/prisoner)
	if(prisoner)
		UnregisterSignal(prisoner, COMSIG_MOVABLE_MOVED)
	for(var/atom/movable/holder as anything in watched_holders)
		UnregisterSignal(holder, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	watched_holders.Cut()

/// Отбывший срок заключённый - обычный гость станции и больше не держит intensity директора.
/datum/round_event/ghost_role/prisoner_transfer/proc/release_director_load(mob/living/prisoner)
	var/datum/mind/prisoner_mind = prisoner?.mind
	if(!prisoner_mind || !control)
		return FALSE
	return minor_crew_release_ghost_role(control.action_name(), prisoner_mind)

/datum/round_event/ghost_role/prisoner_transfer/announce(fake)
	priority_announce("Центральное командование этапирует на станцию заключённого #[prisoner_number], осуждённого за [crime], сроком на [term / (1 MINUTES)] минут. Капсула сядет в отсеке [landing_area_name]; статья и срок уже в базе СБ. На содержание в бюджет службы безопасности поступит [PRISONER_TRANSFER_INSTALLMENT] кредитов при приёме и ещё [PRISONER_TRANSFER_INSTALLMENT], если к концу срока заключённый будет в бриге или трудовом лагере. Этапный датчик сообщит в канал СБ, если заключённый выйдет оттуда без конвоя сотрудника СБ, даже в шкафу или мешке. По истечении срока заключённого можно отпустить.", "Служба исполнения наказаний NanoTrasen")

/datum/outfit/transfer_prisoner
	name = "Transfer Prisoner"
	uniform = /obj/item/clothing/under/rank/prisoner
	shoes = /obj/item/clothing/shoes/sneakers/orange

/obj/item/card/id/prisoner/transfer
	name = "transfer prisoner ID card"
	desc = "Карта этапированного заключённого: номер, статья и срок. Доступа не даёт никуда, даже в столовую. Когда срок выходит, карта пищит."
	assignment = PRISONER_TRANSFER_RANK
	access = list()

/obj/item/card/id/prisoner/transfer/proc/assign_sentence(number, offence, duration)
	registered_name = "Transfer Prisoner #[number]"
	crime = offence
	sentence = world.time + duration
	update_label()

/obj/item/card/id/prisoner/transfer/GetAccess()
	return access

/obj/item/card/id/prisoner/transfer/proc/sentence_served()
	playsound(src, 'sound/machines/ping.ogg', 40, TRUE)
	var/mob/living/holder = get(loc, /mob/living)
	if(holder)
		to_chat(holder, span_notice("Карта заключённого пищит: срок отбыт. Попросите охрану вас отпустить."))

/obj/item/paper/prisoner_sentence
	name = "paper - 'Sentence'"
	desc = "Приговор Центрального суда NanoTrasen с номером заключённого, статьёй и сроком."

/obj/item/paper/prisoner_sentence/proc/write_sentence(prisoner_name, number, offence, duration)
	var/escape_risk = pick("теоретическая", "умеренная", "по настроению", "зависит от меню")
	add_raw_text("<center><b>ПРИГОВОР</b><br>[PRISONER_TRANSFER_COURT]</center><hr>\
		<b>Осуждённый:</b> [prisoner_name], этапный номер #[number]<br>\
		<b>Осуждён за:</b> [offence]<br>\
		<b>Мера наказания:</b> [duration / (1 MINUTES)] минут содержания в бриге станции [station_name()]<br>\
		<b>Насилие:</b> не установлено. <b>Склонность к побегу:</b> [escape_risk].<hr>\
		Службе безопасности станции: принять, разместить, кормить по нормам, по истечении срока освободить. \
		На содержание осуждённого в бюджет службы безопасности переводится [PRISONER_TRANSFER_INSTALLMENT] кредитов при приёме и [PRISONER_TRANSFER_INSTALLMENT] - по окончании срока, если осуждённый в бриге или трудовом лагере. \
		Осуждённому вживлён этапный датчик: о выходе из брига или трудового лагеря без конвоя службы безопасности он сообщает в её канал.<br>\
		<i>Приговор обжалованию не подлежит, но жаловаться не запрещено.</i>")
	update_appearance()

#undef PRISONER_TRANSFER_UPKEEP
#undef PRISONER_TRANSFER_INSTALLMENT
#undef PRISONER_TRANSFER_MIN_TERM
#undef PRISONER_TRANSFER_MAX_TERM
#undef PRISONER_TRANSFER_ALERT_COOLDOWN
#undef PRISONER_TRANSFER_RANK
#undef PRISONER_TRANSFER_COURT
