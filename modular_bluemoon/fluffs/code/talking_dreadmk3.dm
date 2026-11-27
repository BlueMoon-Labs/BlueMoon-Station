// Talking Dreadmk3 - Judge Dredd Style Lawgiver
// Compatible with BlueMoon Station

/// File location for the gun's speech
#define DREADMK3_SPEECH "dreadmk3_speech.json"
/// How long the gun should wait between speaking
#define DREADMK3_SPEECH_COOLDOWN 15 // 1.5 seconds in deciseconds

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking
	name = "\improper Законодатель MK3-AI"
	desc = "Стандартное оружие судей из Мега-Города Солнечной Федерации с интегрированным ИИ-помощником. Пистолет комплектуется несколькими типами боеприпасов, иногда набор снарядов отличается от стандартного в зависимости от миссии судьи. Оснащён биометрическим датчиком ладони — оружие может применять только судья, а при несанкционированном использовании в рукояти срабатывает взрывное устройство. Этот же пистолет на радость недругам что преступают Закон, со сломанной биометрией ради стандартизации электронных бойков. ИИ-модуль позволяет оружию общаться с владельцем."

	/// The json file this gun pulls from when speaking
	var/speech_json_file = DREADMK3_SPEECH
	/// If the gun's personality speech is on
	var/personality_mode = TRUE
	/// Keeps track of the last processed charge
	var/last_charge = 0
	/// A cooldown for when the weapon has last spoken
	var/last_speech = 0
	/// Did we already warn about low charge?
	var/low_charge_warned = FALSE
	/// Track if we're currently held to prevent spam
	var/currently_held = FALSE
	/// Was gun just picked up/dropped? Prevents instant spam
	var/interaction_locked = FALSE
	/// Is the gun currently in a recharger?
	var/in_recharger = FALSE
	/// Quiet mode - whisper instead of speaking
	var/quiet_mode = FALSE
	/// Last time weapon fired
	var/last_fire_time = 0
	/// Are we currently in firing sequence
	var/in_firing_sequence = FALSE
	/// Wounded below 50% — warned once
	var/health_warned_critical = FALSE
	/// Wounded below 25% — warned once
	var/health_warned_danger = FALSE
	/// Dying below 10% — warned once
	var/health_warned_dying = FALSE
	/// Last holder reference for crit-drop monitoring
	var/mob/living/carbon/human/last_holder = null
	/// Announce each holder death once, including when the gun stays in their inventory.
	var/holder_death_reported = FALSE
	/// Last scanned ID card to avoid repeat announcements
	var/obj/item/card/id/last_scanned_id = null
	/// Cooldown to avoid spamming health warnings
	COOLDOWN_DECLARE(health_check_cooldown)
	/// Cooldown between calls for help
	COOLDOWN_DECLARE(call_for_help_cooldown)
	/// Rate-limit dry-fire voice lines independently of urgent alerts.
	COOLDOWN_DECLARE(empty_warning_cooldown)
	/// Cooldown between idle comments
	COOLDOWN_DECLARE(idle_comment_cooldown)
	/// Cooldown between mode switch voice commands
	COOLDOWN_DECLARE(mode_switch_cooldown)
	// DREADMK3_AI_V31:VARS BEGIN
	/// In-range wanted targets already announced during this encounter (REF strings only).
	var/list/ai_wanted_seen = list()
	COOLDOWN_DECLARE(ai_arrest_scan_cooldown)
	COOLDOWN_DECLARE(ai_arrest_phrase_cooldown)
	COOLDOWN_DECLARE(ai_radio_emergency_cooldown)
	// DREADMK3_AI_V31:VARS END
	// DREADMK3_AI_V32:VARS BEGIN
	/// Per-weapon, in-round, bounded memory: no cross-round storage or mind references.
	var/list/ai_v32_owners = list()
	var/list/ai_v32_owner_order = list()
	var/ai_v32_previous_owner_key
	/// Deduplicating bounded event scheduler; key => priority.
	var/list/ai_v32_voice_queue = list()
	/// Additional pacing on top of DreadMK3's existing speech cooldown.
	var/ai_v32_last_queued_spoken = 0
	var/ai_v32_wounded_warned = FALSE
	var/ai_v32_combat_ended_at = 0
	// DREADMK3_AI_V32:VARS END

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/Initialize()
	. = ..()
	if(cell)
		last_charge = cell.charge
	START_PROCESSING(SSobj, src)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/Destroy()
	STOP_PROCESSING(SSobj, src)
	last_holder = null
	last_scanned_id = null
	return ..()

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/examine(mob/user)
	. = ..()
	var/charge_pct = (cell && cell.maxcharge > 0) ? round((cell.charge / cell.maxcharge) * 100) : 0
	. += "<span class='notice'>The AI display shows: Charge [charge_pct]%</span>"
	if(personality_mode)
		. += "<span class='notice'>AI Core: <b>Online</b></span>"
		. += "<span class='notice'>Voice Mode: <b>[quiet_mode ? "Quiet" : "Normal"]</b></span>"
		. += "<span class='notice'>Use <b>Ctrl+Click</b> to toggle AI core.</span>"
		. += "<span class='notice'>Use <b>Alt+Click</b> to toggle voice mode.</span>"
	else
		. += "<span class='warning'>AI Core: <b>Offline</b></span>"

/// Returns the human currently carrying the gun — hands, belt, suit, back, bag or any nested container
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/get_current_carrier()
	var/atom/current = src.loc
	var/depth = 0
	// Поднимаемся по цепочке контейнеров максимум 6 уровней
	// чтобы не уйти в бесконечный цикл при багах с loc
	while(current && depth < 6)
		if(ishuman(current))
			return current
		// Дошли до тайла или зоны — носителя нет
		if(isturf(current) || isarea(current))
			return null
		current = current.loc
		depth++
	return null

/// Makes the gun speak. Respects cooldown and personality toggle unless overridden.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/speak_up(json_string, ignores_cooldown = FALSE, ignores_personality_toggle = FALSE)
	if(!personality_mode && !ignores_personality_toggle)
		return
	if(!json_string)
		return
	if(!ignores_cooldown && (world.time < last_speech + DREADMK3_SPEECH_COOLDOWN))
		return
	var/message = pick(strings(speech_json_file, json_string))
	if(!message)
		return
	// Тихий режим — whisper (курсив над головой)
	// Обычный режим — say (обычный текст над головой)
	if(quiet_mode)
		// A quiet private/local voice: avoid broadcasting across a full normal view range.
		var/turf/voice_turf = get_turf(src)
		if(voice_turf)
			for(var/mob/listener in hearers(2, voice_turf))
				to_chat(listener, span_notice("<i>[src]: [message]</i>"))
	else
		say(message)
	last_speech = world.time

/// Resets all health warning flags — called on holder change or full recovery
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/reset_health_warnings()
	health_warned_critical = FALSE
	health_warned_danger = FALSE
	health_warned_dying = FALSE

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/equipped(mob/user, slot)
	. = ..()
	// DREADMK3_AI_V32:PICKUP BEGIN
	if(slot == ITEM_SLOT_HANDS)
		ai_v32_remember_owner(user)
	// DREADMK3_AI_V32:PICKUP END
	if(interaction_locked)
		return

	in_recharger = FALSE

	if(slot == ITEM_SLOT_BELT || slot == ITEM_SLOT_BACK || slot == ITEM_SLOT_SUITSTORE)
		currently_held = FALSE
		if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
			interaction_locked = TRUE
			speak_up("worn")
			addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10)

	else if(slot == ITEM_SLOT_HANDS)
		currently_held = TRUE
		// Сбрасываем данные прошлого носителя
		last_holder = null
		reset_health_warnings()
		// Проверяем ID нового носителя
		var/phrase_to_say = check_user_id_silent(user)

		if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
			interaction_locked = TRUE
			// Сначала pickup, затем ID фраза с небольшой задержкой
			speak_up("pickup")

			if(phrase_to_say)
				last_scanned_id = user.get_idcard(TRUE)
				addtimer(CALLBACK(src, PROC_REF(announce_scanned_id), user, last_scanned_id, phrase_to_say), 15)

			addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/dropped(mob/user)
	. = ..()
	if(interaction_locked)
		return

	currently_held = FALSE

	if(src in user.contents)
		return

	// Проверяем — намеренно положил или выронил из-за состояния
	if(isliving(user) && !QDELETED(user))
		var/mob/living/L = user
		if(L.stat == SOFT_CRIT || L.stat == UNCONSCIOUS || L.stat == DEAD)
			last_holder = ishuman(L) ? L : null
			speak_up("dropped_crit", TRUE)
			return

	// Проверяем — не попал ли в зарядник
	if(istype(loc, /obj/machinery/recharger) || istype(loc?.loc, /obj/machinery/recharger))
		return

	// Проверяем — не убрали ли в контейнер который несёт человек
	// (сумка, кобура, рюкзак надетые на моба)
	if(get_current_carrier())
		return

	// Намеренно положил на пол — обычная фраза
	if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
		interaction_locked = TRUE
		speak_up("putdown")
		addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10)

/// Unlocks pickup/drop interaction spam prevention
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/unlock_interaction()
	interaction_locked = FALSE

/// Delayed ID announcement may only play for the same human holding the same ID.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/announce_scanned_id(mob/living/carbon/human/expected_user, obj/item/card/id/expected_id, phrase_key)
	if(QDELETED(src) || !ishuman(expected_user) || QDELETED(expected_user) || !personality_mode)
		return
	if(get_current_carrier() != expected_user || expected_user.get_idcard(TRUE) != expected_id)
		return
	speak_up(phrase_key, TRUE)

/// Called when gun is inserted into recharger
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/enter_recharger()
	in_recharger = TRUE
	currently_held = FALSE
	if(personality_mode && world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
		speak_up("recharger_in")

/// Called when gun is removed from recharger
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/exit_recharger()
	in_recharger = FALSE
	if(personality_mode && world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
		speak_up("recharger_out")

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/process()
	// DREADMK3_AI_V31:PROCESS BEGIN
	if(personality_mode && COOLDOWN_FINISHED(src, ai_arrest_scan_cooldown))
		COOLDOWN_START(src, ai_arrest_scan_cooldown, 15 SECONDS)
		ai_scan_visible_arrests()
	// DREADMK3_AI_V31:PROCESS END
	if(cell && cell.maxcharge > 0)
		var/cell_charge_warn = cell.maxcharge * 0.35

		if(cell.charge <= cell_charge_warn && !low_charge_warned)
			speak_up("lowcharge", TRUE)
			low_charge_warned = TRUE

		if(cell.charge > (cell.maxcharge * 0.45) && low_charge_warned)
			low_charge_warned = FALSE

		if(cell.charge >= cell.maxcharge && last_charge < cell.maxcharge)
			speak_up("fullcharge")

		last_charge = cell.charge

	// --- Проверка здоровья носителя ---
	if(personality_mode)
		var/mob/living/carbon/human/target_holder = null
		var/mob/living/carbon/human/carrier = get_current_carrier()

		if(carrier)
			// Оружие при носителе (руки, кобура, броня, спина)
			if(last_holder != carrier)
				reset_health_warnings()
				last_holder = carrier
				holder_death_reported = FALSE
			if(carrier.stat == DEAD)
				if(!holder_death_reported)
					holder_death_reported = TRUE
					speak_up("holder_dead", TRUE)
			else
				holder_death_reported = FALSE
				target_holder = carrier

		else if(last_holder && !QDELETED(last_holder))
			// Оружие выронено — проверяем состояние последнего носителя
			switch(last_holder.stat)
				if(SOFT_CRIT, UNCONSCIOUS)
					// Носитель без сознания — следим если рядом (до 3 тайлов)
					if(get_dist(src, last_holder) <= 3)
						target_holder = last_holder
					else
						last_holder = null // Унесли далеко — теряем связь
				if(DEAD)
					// Носитель умер после потери оружия — ровно одно прощание.
					if(!holder_death_reported)
						holder_death_reported = TRUE
						speak_up("holder_dead", TRUE)
					last_holder = null
				else
					// Носитель пришёл в себя — мониторинг больше не нужен
					last_holder = null

		if(target_holder && COOLDOWN_FINISHED(src, health_check_cooldown))
			check_holder_health(target_holder)
			COOLDOWN_START(src, health_check_cooldown, 20 SECONDS)

	// --- Рандомные idle фразы ---
	// Пока оружие при носителе — в руках или в слоте
	if(personality_mode && get_current_carrier())
		if(COOLDOWN_FINISHED(src, idle_comment_cooldown))
			// Один бросок шанса в две минуты, а не каждый тик до успеха.
			COOLDOWN_START(src, idle_comment_cooldown, 2 MINUTES)
			if(prob(15))
				ai_v32_enqueue_event(ai_v32_idle_key(), 10)

	// DREADMK3_AI_V32:PROCESS BEGIN
	if(personality_mode)
		ai_v32_observe_context()
		ai_v32_flush_voice_queue()
	else if(length(ai_v32_voice_queue))
		ai_v32_voice_queue.Cut()
	// DREADMK3_AI_V32:PROCESS END

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/attack_self(mob/living/user)
	. = ..()
	// Голосовое переключение режима огня
	if(personality_mode)
		voice_command_mode_switch(user)

/// Checks holder health and reacts with voice lines based on thresholds
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/check_holder_health(mob/living/carbon/human/holder)
	if(!holder || QDELETED(holder))
		return
	if(holder.maxHealth <= 0)
		return

	var/health_pct = (holder.health / holder.maxHealth) * 100
	// DREADMK3_AI_V32:HEALTH BEGIN
	// Do not let routine remarks interrupt an emergency; no extra medical scans.
	if(personality_mode)
		if(health_pct <= 25)
			ai_v32_discard_routine_events()
		if(health_pct <= 75 && health_pct > 50 && !ai_v32_wounded_warned)
			ai_v32_wounded_warned = TRUE
			ai_v32_enqueue_event("ai_health_wounded", 65)
		else if(health_pct > 85)
			ai_v32_wounded_warned = FALSE
	// DREADMK3_AI_V32:HEALTH END

	// Порог умирания — ниже 10%
	if(health_pct <= 10 && !health_warned_dying)
		// DREADMK3_AI_V32:EMERGENCY BEGIN
		// Guaranteed single attempt on first dying-threshold crossing.
		// Reuses v3.1's cooldown + real equipped security headset.
		ai_send_emergency_on_owner_headset(holder)
		// DREADMK3_AI_V32:EMERGENCY END
		health_warned_dying = TRUE
		health_warned_danger = TRUE
		health_warned_critical = TRUE
		speak_up("health_dying", TRUE)
		// С шансом 70% зовём помощь рядом
		if(prob(70) && COOLDOWN_FINISHED(src, call_for_help_cooldown))
			call_for_help(holder)
			COOLDOWN_START(src, call_for_help_cooldown, 1 MINUTES)

	// Порог опасности — ниже 25%
	else if(health_pct <= 25 && !health_warned_danger)
		health_warned_danger = TRUE
		health_warned_critical = TRUE
		speak_up("health_danger", TRUE)
		// С шансом 50% зовём помощь рядом
		if(prob(50) && COOLDOWN_FINISHED(src, call_for_help_cooldown))
			call_for_help(holder)
			COOLDOWN_START(src, call_for_help_cooldown, 2 MINUTES)

	// Порог критического — ниже 50%, только если носитель в сознании и при оружии
	else if(health_pct <= 50 && !health_warned_critical)
		health_warned_critical = TRUE
		if(get_current_carrier()) // Носитель при оружии — слышит нас
			speak_up("health_critical", TRUE)

	// Сброс флагов при восстановлении здоровья
	if(health_pct > 50)
		reset_health_warnings()
	else if(health_pct > 25)
		health_warned_danger = FALSE
		health_warned_dying = FALSE
	else if(health_pct > 10)
		health_warned_dying = FALSE

/// Searches nearby for medics or security and calls for help
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/call_for_help(mob/living/carbon/human/holder)
	if(!holder || QDELETED(holder))
		return

	// DREADMK3_AI_V31:RADIO_HOOK BEGIN
	// This is strictly the owner's actual worn headset, not a built-in gun radio.
	ai_send_emergency_on_owner_headset(holder)
	// DREADMK3_AI_V31:RADIO_HOOK END

	// Статичные списки — не пересоздаются каждый вызов
	var/static/list/medical_jobs = list(
		"Chief Medical Officer", "Medical Doctor", "Paramedic",
		"Brig Physician", "Chemist", "Nurse"
	)
	var/static/list/security_jobs = list(
		"Head of Security", "Warden", "Security Officer",
		"Detective", "Peacekeeper", "Blueshield"
	)

	var/mob/living/carbon/human/target = null
	var/found_medic = FALSE

	// Ищем в радиусе 7 тайлов — медики в приоритете над СБ
	for(var/mob/living/carbon/human/nearby in range(7, src))
		if(nearby == holder || nearby.stat != CONSCIOUS || QDELETED(nearby))
			continue
		var/obj/item/card/id/id_card = nearby.get_idcard(TRUE)
		if(!id_card?.assignment)
			continue
		if((id_card.assignment in medical_jobs))
			target = nearby
			found_medic = TRUE
			break // Медик найден — дальше не ищем
		if(!target && (id_card.assignment in security_jobs))
			target = nearby // СБ как запасной вариант

	if(!target)
		// Никого подходящего рядом нет
		speak_up("help_no_one", TRUE)
		return

	// Обращаемся к найденному по типу должности
	speak_up(found_medic ? "help_call_medic" : "help_call_security", TRUE)

/// User clicks self with gun — gun announces mode and user says it aloud
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/voice_command_mode_switch(mob/living/user)
	if(!user || QDELETED(user))
		return
	if(!COOLDOWN_FINISHED(src, mode_switch_cooldown))
		return
	COOLDOWN_START(src, mode_switch_cooldown, 0.5 SECONDS)

	var/mode_name = get_mode_russian_name()
	if(!mode_name)
		return

	// В комбат-моде говорим громко, иначе шёпотом если тихий режим
	var/in_combat = FALSE
	var/datum/component/combat_mode/combat = user.GetComponent(/datum/component/combat_mode)
	if(combat)
		in_combat = combat.check_flags(user, COMBAT_MODE_ACTIVE)

	if(in_combat || !quiet_mode)
		user.say(mode_name)
	else
		user.whisper(mode_name)

	// Оружие отвечает с небольшой задержкой
	var/announce = get_current_mode_announce()
	if(announce)
		addtimer(CALLBACK(src, PROC_REF(announce_firemode), user, current_firemode_index, announce), 3)

/// Speak only if the same holder still wields the same selected mode.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/announce_firemode(mob/living/expected_user, expected_mode_index, phrase_key)
	if(QDELETED(src) || !expected_user || QDELETED(expected_user) || !personality_mode)
		return
	if(current_firemode_index != expected_mode_index || !expected_user.is_holding(src))
		return
	speak_up(phrase_key, TRUE)

/// Returns Russian name of current fire mode for voice command
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/get_mode_russian_name()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[current_firemode_index]
	if(istype(current_ammo, /obj/item/ammo_casing/energy/disabler))
		return "Станнер"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/laser))
		return "Лазер"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/ion))
		return "Ион"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/electrode))
		return "Тазер"
	return null

/// Returns JSON key for current fire mode announcement
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/get_current_mode_announce()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[current_firemode_index]
	if(istype(current_ammo, /obj/item/ammo_casing/energy/disabler))
		return "stun"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/laser))
		return "lethal"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/ion))
		return "ion"
	if(istype(current_ammo, /obj/item/ammo_casing/energy/electrode))
		return "taser"
	return null

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/afterattack(atom/target, mob/living/user, flag, params)
	// Проверка на пустой выстрел — до ..() пока заряд ещё не потрачен
	if(!can_shoot() && user && personality_mode && COOLDOWN_FINISHED(src, empty_warning_cooldown))
		COOLDOWN_START(src, empty_warning_cooldown, 8 SECONDS)
		speak_up("empty", TRUE)

	var/old_charge = cell ? cell.charge : 0
	. = ..()

	// Успешный выстрел — энергия потрачена
	if(cell && cell.charge < old_charge)
		// Если прошло достаточно времени — начинаем новую серию
		if(world.time > last_fire_time + 100)
			in_firing_sequence = FALSE
		// Объявляем начало серии стрельбы один раз
		if(!in_firing_sequence)
			in_firing_sequence = TRUE
			if(personality_mode)
				speak_up("firing")
		last_fire_time = world.time

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/emp_act(severity)
	. = ..()
	speak_up("emp", TRUE)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/CtrlClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	personality_mode = !personality_mode
	playsound(src, 'sound/machines/terminal_button08.ogg', 30, TRUE)
	speak_up(personality_mode ? "online" : "offline", TRUE, TRUE)
	to_chat(user, "<span class='notice'>[src]'s AI core is now [personality_mode ? "online" : "offline"].</span>")
	return TRUE

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(!personality_mode)
		to_chat(user, "<span class='warning'>AI core is offline.</span>")
		return TRUE
	quiet_mode = !quiet_mode
	playsound(src, 'sound/machines/terminal_button08.ogg', 30, TRUE)
	to_chat(user, "<span class='notice'>[src]'s voice mode is now [quiet_mode ? "quiet" : "normal"].</span>")
	if(quiet_mode)
		visible_message("<span class='notice'><i>Тихий режим активирован.</i></span>")
	else
		say("Голосовой режим восстановлен.")
	return TRUE

/// Checks user's ID card silently and returns the appropriate phrase key
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/check_user_id_silent(mob/living/carbon/human/user)
	if(!ishuman(user))
		return null

	var/obj/item/card/id/id_card = user.get_idcard(TRUE)
	if(!id_card?.assignment)
		return "no_id"

	// Не повторяем фразу для той же карты
	if(id_card == last_scanned_id)
		return null

	var/job = id_card.assignment

	// Должности СБ
	if((job in list("Head of Security", "Warden", "Security Officer", "Detective", "Brig Physician", "Peacekeeper")))
		return "id_[lowertext(replacetext(job, " ", "_"))]"
	// Командный состав
	if((job in list("Captain", "Blueshield", "Bridge Officer", "Internal Affairs Agent", "NanoTrasen Representative")))
		return "id_[lowertext(replacetext(job, " ", "_"))]"
	// Главы отделов
	if((job in list("Chief Medical Officer", "Research Director", "Chief Engineer", "Quartermaster", "Head of Personnel")))
		return "id_[lowertext(replacetext(job, " ", "_"))]"

	// Все остальные — гражданские
	return "id_civilian"

/// Called when firing pin is inserted — identifies pin type and announces it
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/on_pin_inserted()
	if(!personality_mode || !pin)
		return

	// Порядок важен — от частного к общему, иначе базовый тип перекроет всех
	var/phrase_key = null
	if(istype(pin, /obj/item/firing_pin/implant/mindshield))
		phrase_key = "pin_mindshield"
	else if(istype(pin, /obj/item/firing_pin/test_range))
		phrase_key = "pin_test"
	else if(istype(pin, /obj/item/firing_pin/explorer))
		phrase_key = "pin_explorer"
	else if(istype(pin, /obj/item/firing_pin/alert_level/blue))
		phrase_key = "pin_alert"
	else if(pin.type == /obj/item/firing_pin)
		phrase_key = "pin_standard"
	else
		phrase_key = "pin_unauthorized"

	addtimer(CALLBACK(src, PROC_REF(speak_up), phrase_key, TRUE, FALSE), 5)

// DREADMK3_AI_V31:PROCS BEGIN
/// Match the actual active advanced SecHUD, regardless of its source (glasses, implant, suit).
/// This mirrors BlueMoon's observer HUD registry and does not grant a new HUD.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_owner_has_active_sechud(mob/living/carbon/human/holder)
	if(!holder || QDELETED(holder) || HAS_TRAIT(holder, TRAIT_BLOCK_SECHUD))
		return FALSE
	var/datum/atom_hud/data/human/security/advanced/sec_hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	return !!sec_hud?.hudusers[holder]

/// Lightweight, owner-visible wanted check. Follows the real SecHUD identity resolution.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_scan_visible_arrests()
	var/mob/living/carbon/human/holder = get_current_carrier()
	if(!holder || holder.stat != CONSCIOUS || !(src in holder.held_items) || !ai_owner_has_active_sechud(holder) || !GLOB.data_core)
		ai_wanted_seen.Cut()
		return

	var/list/seen_now = list()
	for(var/mob/living/carbon/human/person in view(3, holder))
		if(person == holder || QDELETED(person))
			continue
		// Exactly the face/ID resolution used by SecHUD, not real_name through disguises.
		var/visible_identity = person.get_face_name(person.get_id_name(""))
		if(!visible_identity)
			continue
		var/datum/data/record/security_record = antag_training_station_record(GLOB.data_core.security_by_name, visible_identity, person)
		if(security_record?.fields["criminal"] != SEC_RECORD_STATUS_ARREST)
			continue
		var/key = REF(person)
		seen_now[key] = ai_wanted_seen[key] || FALSE
		if(seen_now[key] || !COOLDOWN_FINISHED(src, ai_arrest_phrase_cooldown))
			continue
		ai_v32_enqueue_event("ai_arrest_detected", 45)
		seen_now[key] = TRUE
		COOLDOWN_START(src, ai_arrest_phrase_cooldown, 45 SECONDS)
	// Leaving view or changing status forgets this encounter naturally.
	ai_wanted_seen = seen_now

/// The only radio path: piggyback on the current/last fallen owner's worn headset.
/// Existing channel encryption, telecomms, transmit wires, radio blackouts and jammers apply.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_send_emergency_on_owner_headset(mob/living/carbon/human/holder)
	if(!personality_mode || !holder || QDELETED(holder) || !COOLDOWN_FINISHED(src, ai_radio_emergency_cooldown))
		return FALSE
	var/mob/living/carbon/human/carrier = get_current_carrier()
	if(carrier && carrier != holder)
		return FALSE
	if(!carrier && (last_holder != holder || !get_turf(src) || src.z != holder.z || get_dist(src, holder) > 3))
		return FALSE
	var/obj/item/radio/headset/headset
	if(istype(holder.ears, /obj/item/radio/headset))
		headset = holder.ears
	else if(istype(holder.ears_extra, /obj/item/radio/headset))
		headset = holder.ears_extra
	if(!headset || QDELETED(headset) || !headset.on || !headset.listening)
		return FALSE
	if(!headset.channels || !headset.channels[RADIO_CHANNEL_SECURITY])
		return FALSE
	if(headset.speaker_jammed(holder))
		return FALSE
	var/message = "АВАРИЙНЫЙ СИГНАЛ: Законодатель MK3-AI. [holder.real_name] нуждается в медицинской помощи. Местоположение: [AREACOORD(holder)]."
	// Use the established subspace pipeline with the weapon as the *speaker*.
	// The actual transmitter remains the headset; no omnipotent direct frequency call.
	INVOKE_ASYNC(headset, TYPE_PROC_REF(/obj/item/radio, talk_into_impl), src, message, RADIO_CHANNEL_SECURITY, list(), /datum/language/common)
	COOLDOWN_START(src, ai_radio_emergency_cooldown, 2 MINUTES)
	return TRUE

// DREADMK3_AI_V32:PROCS BEGIN
/// Store max 6 identities per gun in memory for this round only. No personal data in files.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_remember_owner(mob/living/user)
	if(!personality_mode || !ishuman(user) || QDELETED(user))
		return
	var/mob/living/carbon/human/holder = user
	var/owner_key = holder.mind ? REF(holder.mind) : REF(holder)
	if(!owner_key)
		return
	var/previous = ai_v32_previous_owner_key
	var/was_known = ai_v32_owners[owner_key]
	if(previous != owner_key)
		// Do not replay another officer's old remarks on a handoff.
		ai_v32_voice_queue.Cut()
		ai_v32_wounded_warned = FALSE
	var/had_previous = length(ai_v32_owner_order) > 0
	if(!was_known)
		ai_v32_owners[owner_key] = 1
		ai_v32_owner_order += owner_key
		if(length(ai_v32_owner_order) > 6)
			var/expired_key = ai_v32_owner_order[1]
			ai_v32_owner_order.Cut(1, 2)
			ai_v32_owners -= expired_key
		ai_v32_enqueue_event(had_previous ? "ai_owner_new" : "ai_owner_first", 30)
	else
		ai_v32_owners[owner_key] = min(was_known + 1, 1000)
		if(previous != owner_key)
			ai_v32_enqueue_event("ai_owner_return", 40)
	ai_v32_previous_owner_key = owner_key

/// Queue only new contextual voice lines, drop duplicates and low-priority overflow.
/// Priority: context=10, owner=30-40, arrest=45, wounded=65; base dying alerts
/// continue to speak immediately, while routine queue is suspended during danger.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_enqueue_event(event_key, priority = 10)
	if(!personality_mode || !event_key)
		return FALSE
	if(event_key in ai_v32_voice_queue)
		return FALSE
	if(length(ai_v32_voice_queue) >= 8)
		var/worst_key
		var/worst_priority = INFINITY
		for(var/queued_key in ai_v32_voice_queue)
			if(ai_v32_voice_queue[queued_key] < worst_priority)
				worst_key = queued_key
				worst_priority = ai_v32_voice_queue[queued_key]
		if(priority <= worst_priority)
			return FALSE
		ai_v32_voice_queue -= worst_key
	ai_v32_voice_queue[event_key] = priority
	return TRUE

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_discard_routine_events()
	if(!length(ai_v32_voice_queue))
		return
	for(var/queued_key in ai_v32_voice_queue.Copy())
		if(ai_v32_voice_queue[queued_key] < 65)
			ai_v32_voice_queue -= queued_key

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_flush_voice_queue()
	if(!personality_mode || !length(ai_v32_voice_queue))
		return
	var/mob/living/carbon/human/holder = get_current_carrier()
	if(!holder || QDELETED(holder))
		ai_v32_voice_queue.Cut()
		return
	if(holder.stat != CONSCIOUS || world.time < last_speech + DREADMK3_SPEECH_COOLDOWN)
		return
	if(world.time < ai_v32_last_queued_spoken + 8 SECONDS)
		return
	var/health_pct = holder.maxHealth > 0 ? (holder.health / holder.maxHealth) * 100 : 0
	if(health_pct <= 25)
		ai_v32_discard_routine_events()
		return
	var/best_key
	var/best_priority = -1
	for(var/queued_key in ai_v32_voice_queue)
		var/priority = ai_v32_voice_queue[queued_key]
		if(priority > best_priority)
			best_key = queued_key
			best_priority = priority
	if(!best_key)
		return
	ai_v32_voice_queue -= best_key
	speak_up(best_key)
	ai_v32_last_queued_spoken = world.time

/// Choose one context-specific idle category; no nearby-mob search here.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_idle_key()
	var/mob/living/carbon/human/holder = get_current_carrier()
	if(!holder)
		return "idle"
	if(!(src in holder.held_items))
		return "ai_idle_holstered"
	if(last_fire_time && world.time < last_fire_time + 90 SECONDS)
		return "ai_idle_postcombat"
	var/obj/item/card/id/card = holder.get_idcard(TRUE)
	var/static/list/official_jobs = list("Captain", "Head of Security", "Bridge Officer", "Internal Affairs Agent", "Head of Personnel", "Research Director", "Chief Engineer", "Chief Medical Officer", "Quartermaster")
	if(card && (card.assignment in official_jobs))
		return "ai_idle_official"
	return "idle"

/// Called only from the gun's existing SSobj process; no additional processing subsystem.
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/ai_v32_observe_context()
	var/mob/living/carbon/human/holder = get_current_carrier()
	if(!holder || QDELETED(holder) || holder.stat != CONSCIOUS)
		return
	// One line after a finished firefight, never every process tick.
	if(last_fire_time && last_fire_time != ai_v32_combat_ended_at && world.time >= last_fire_time + 12 SECONDS && world.time <= last_fire_time + 90 SECONDS)
		ai_v32_combat_ended_at = last_fire_time
		ai_v32_enqueue_event("ai_postcombat", 50)
// DREADMK3_AI_V32:PROCS END


#undef DREADMK3_SPEECH
#undef DREADMK3_SPEECH_COOLDOWN
