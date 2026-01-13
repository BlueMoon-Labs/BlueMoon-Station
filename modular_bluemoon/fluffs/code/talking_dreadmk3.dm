// Talking Dreadmk3 - Judge Dredd Style Lawgiver
// Compatible with BlueMoon Station

/// File location for the gun's speech
#define DREADMK3_SPEECH "dreadmk3_speech.json"
/// How long the gun should wait between speaking
#define DREADMK3_SPEECH_COOLDOWN 15 // 1.5 seconds in deciseconds
/// Default chat color for the gun
#define DREADMK3_CHAT_COLOR "#1e90ff"

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking
	name = "\improper Законодатель MK3-AI"
	desc = "Стандартное оружие судей из Мега-Города Солнечной Федерации с интегрированным ИИ-помощником. Пистолет комплектуется несколькими типами боеприпасов, иногда набор снарядов отличается от стандартного в зависимости от миссии судьи. Оснащён биометрическим датчиком ладони — оружие может применять только судья, а при несанкционированном использовании в рукояти срабатывает взрывное устройство. Этот же пистолет на радость недругам что преступают Закон, со сломанной биометрией ради стандартизации электронных бойков. ИИ-модуль позволяет оружию общаться с владельцем."

	/// The json file this gun pulls from when speaking
	var/speech_json_file = DREADMK3_SPEECH
	/// If the gun's personality speech is on
	var/personality_mode = TRUE
	/// Keeps track of the last processed charge
	var/last_charge = 0
	/// Shot counter
	var/shots_fired = 0
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
	/// Last time we checked ID
	COOLDOWN_DECLARE(id_check_cooldown)
	/// Last time gun made an idle comment
	COOLDOWN_DECLARE(idle_comment_cooldown)
	/// List of allowed firing pins with their voice lines
	var/static/list/allowed_pins = list(
		/obj/item/firing_pin = "pin_standard",
		/obj/item/firing_pin/test_range = "pin_test",
		/obj/item/firing_pin/implant/mindshield = "pin_mindshield",
		/obj/item/firing_pin/explorer = "pin_explorer",
		/obj/item/firing_pin/alert_level/blue = "pin_alert"
	)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/Initialize()
	. = ..()
	last_charge = cell.charge
	START_PROCESSING(SSobj, src)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The AI display shows: [shots_fired] rounds discharged.</span>"
	if(personality_mode)
		. += "<span class='notice'>AI Core: <b>Online</b></span>"
		. += "<span class='notice'>Voice Mode: <b>[quiet_mode ? "Quiet" : "Normal"]</b></span>"
		. += "<span class='notice'>Use <b>Ctrl+Click</b> to toggle AI core.</span>"
		. += "<span class='notice'>Use <b>Alt+Click</b> to toggle voice mode.</span>"
	else
		. += "<span class='warning'>AI Core: <b>Offline</b></span>"

/// Makes the gun speak
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

	// Тихий режим - whisper (текст над головой курсивом)
	// Обычный режим - say (текст над головой обычный)
	if(quiet_mode)
		visible_message("<span class='notice'><i>[message]</i></span>", blind_message = message)
	else
		say(message)

	last_speech = world.time

/// User says/whispers the mode name, gun confirms it
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/voice_command_mode_switch(mob/living/user)
	if(!user || !istype(user))
		return

	var/mode_name = get_mode_russian_name()
	if(!mode_name)
		return

	// Проверяем комбат мод через компонент
	var/in_combat = FALSE
	var/datum/component/combat_mode/combat = user.GetComponent(/datum/component/combat_mode)
	if(combat)
		in_combat = combat.check_flags(user, COMBAT_MODE_ACTIVE)

	// В комбат-моде говорим громко, иначе шёпотом (если не включен quiet_mode)
	if(in_combat || !quiet_mode)
		user.say(mode_name)
	else
		user.whisper(mode_name)

	// Оружие отвечает с небольшой задержкой
	addtimer(CALLBACK(src, PROC_REF(speak_up), get_current_mode_announce(), TRUE), 3)

/// Get Russian name for current mode for voice commands
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/get_mode_russian_name()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[current_firemode_index]

	if(istype(current_ammo, /obj/item/ammo_casing/energy/disabler))
		return "Станнер"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/laser))
		return "Лазер"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/ion))
		return "Ион"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/electrode))
		return "Тазер"

	return null

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/equipped(mob/user, slot)
	. = ..()
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
		// Один таймер для всех проверок
		var/phrase_to_say = null

		// Проверяем ID (раз в 5 минут)
		if(COOLDOWN_FINISHED(src, id_check_cooldown))
			phrase_to_say = check_user_id_silent(user)
			COOLDOWN_START(src, id_check_cooldown, 5 MINUTES)

		if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
			interaction_locked = TRUE
			if(phrase_to_say)
				addtimer(CALLBACK(src, PROC_REF(speak_up), phrase_to_say, TRUE), 15)
			speak_up("pickup")
			addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/dropped(mob/user)
	. = ..()
	if(interaction_locked)
		return

	currently_held = FALSE
	if(src in user.contents)
		return
	if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
		interaction_locked = TRUE
		speak_up("putdown")
		addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10)

/// Unlocks interaction after pickup/drop
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/unlock_interaction()
	interaction_locked = FALSE

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
	// Проверка заряда
	var/cell_charge_quarter = cell.maxcharge / 4

	if(cell.charge <= cell_charge_quarter && !low_charge_warned)
		speak_up("lowcharge", TRUE)
		low_charge_warned = TRUE

	if(cell.charge > (cell.maxcharge * 0.3) && low_charge_warned)
		low_charge_warned = FALSE

	if(cell.charge >= cell.maxcharge && last_charge < cell.maxcharge)
		speak_up("fullcharge")

	last_charge = cell.charge

	// Рандомные idle фразы
	if(personality_mode && (currently_held || (loc && ishuman(loc))))
		if(COOLDOWN_FINISHED(src, idle_comment_cooldown))
			if(prob(15))
				speak_up("idle")
				COOLDOWN_START(src, idle_comment_cooldown, 2 MINUTES)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/attack_self(mob/living/user)
	. = ..()
	if(personality_mode)
		voice_command_mode_switch(user)

/// Gets the announcement for current fire mode
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/get_current_mode_announce()
	var/obj/item/ammo_casing/energy/current_ammo = ammo_type[current_firemode_index]

	if(istype(current_ammo, /obj/item/ammo_casing/energy/disabler))
		return "stun"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/laser))
		return "lethal"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/ion))
		return "ion"
	else if(istype(current_ammo, /obj/item/ammo_casing/energy/electrode))
		return "taser"

	return null

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/afterattack(atom/target, mob/living/user, flag, params)
	// Проверка на пустой выстрел
	if(!can_shoot() && user && personality_mode)
		speak_up("empty", TRUE)

	. = ..()
	if(.)
		shots_fired++
		if(personality_mode && prob(40))
			speak_up("firing")

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/emp_act(severity)
	. = ..()
	speak_up("emp", TRUE)

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/CtrlClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	personality_mode = !personality_mode
	playsound(src, 'sound/machines/terminal_button08.ogg', 30, TRUE)
	speak_up("[personality_mode ? "online" : "offline"]", TRUE, TRUE)
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

/// Checks user's ID card silently and returns phrase key
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/check_user_id_silent(mob/living/carbon/human/user)
	if(!ishuman(user))
		return null

	var/obj/item/card/id/id_card = user.get_idcard(TRUE)
	if(!id_card || !id_card.assignment)
		return "no_id"

	var/job = id_card.assignment

	// Security jobs
	if(job in list("Head of Security", "Warden", "Security Officer", "Detective", "Brig Physician", "Peacekeeper"))
		return "id_[lowertext(replacetext(job, " ", "_"))]"

	// Command jobs
	if(job in list("Captain", "Blueshield", "Bridge Officer", "Internal Affairs Agent", "NanoTrasen Representative"))
		return "id_[lowertext(replacetext(job, " ", "_"))]"

	// Department heads
	if(job in list("Chief Medical Officer", "Research Director", "Chief Engineer", "Quartermaster", "Head of Personnel"))
		return "id_[lowertext(replacetext(job, " ", "_"))]"

	// Everyone else is civilian
	return "id_civilian"

/// Called when firing pin is inserted - checks and announces
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/on_pin_inserted()
	if(!personality_mode || !pin)
		return

	// Проверяем тип бойка
	var/phrase_key = null
	for(var/pin_type in allowed_pins)
		if(istype(pin, pin_type))
			phrase_key = allowed_pins[pin_type]
			break

	if(!phrase_key)
		phrase_key = "pin_unauthorized"

	addtimer(CALLBACK(src, PROC_REF(speak_up), phrase_key, TRUE), 5)

#undef DREADMK3_SPEECH
#undef DREADMK3_SPEECH_COOLDOWN
#undef DREADMK3_CHAT_COLOR
