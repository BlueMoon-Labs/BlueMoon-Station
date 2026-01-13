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
		. += "<span class='notice'>Use <b>Ctrl+Click</b> to toggle AI core.</span>"
	else
		. += "<span class='warning'>AI Core: <b>Offline</b></span>"

/// Makes the gun speak with sound effect - now uses say() to speak like a character
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

	// Используем say() чтобы говорить как персонаж, а не в чат внизу
	say(message)
	playsound(src, 'sound/machines/synth_yes.ogg', 1, FALSE)
	last_speech = world.time

/// User says/whispers the mode name, gun confirms it
/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/proc/voice_command_mode_switch(mob/living/user)
	if(!user || !istype(user))
		return

	var/mode_name = get_mode_russian_name()
	if(!mode_name)
		return

	// Пользователь шепчет название режима
	user.whisper(mode_name)

/* Пока что не работает изза if(user.combat_indicator) потом допилю.
	// В комбат-моде говорим громко, иначе шёпотом
	if(user.combat_indicator)
		user.say(mode_name)
	else
		user.whisper(mode_name)
*/
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

	in_recharger = FALSE // Больше не в зарядке

	if(slot == ITEM_SLOT_BELT || slot == ITEM_SLOT_BACK || slot == ITEM_SLOT_SUITSTORE)
		currently_held = FALSE
		if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
			interaction_locked = TRUE
			speak_up("worn")
			addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10) // 1 second lock
	else if(slot == ITEM_SLOT_HANDS)
		currently_held = TRUE
		if(world.time >= last_speech + DREADMK3_SPEECH_COOLDOWN)
			interaction_locked = TRUE
			speak_up("pickup")
			addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10) // 1 second lock

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
		addtimer(CALLBACK(src, PROC_REF(unlock_interaction)), 10) // 1 second lock

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

	// Предупреждение о низком заряде - срабатывает когда заряд ВПЕРВЫЕ падает ниже 25%
	if(cell.charge <= cell_charge_quarter && !low_charge_warned)
		speak_up("lowcharge", TRUE) // Игнорируем кулдаун для важных сообщений
		low_charge_warned = TRUE

	// Сбрасываем флаг если заряд восстановился выше 30%
	if(cell.charge > (cell.maxcharge * 0.3) && low_charge_warned)
		low_charge_warned = FALSE

	// Сообщение о полном заряде - срабатывает когда заряд достигает 100%
	if(cell.charge >= cell.maxcharge && last_charge < cell.maxcharge)
		speak_up("fullcharge")

	last_charge = cell.charge

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/attack_self(mob/living/user)
	. = ..()
	if(personality_mode)
		// Голосовая команда + ответ оружия
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
	// Проверка на пустой выстрел ДО вызова родительского метода
	if(!can_shoot() && user && personality_mode)
		speak_up("empty", TRUE) // Игнорируем кулдаун для важного сообщения

	. = ..()
	if(.)
		shots_fired++
		if(personality_mode && prob(40))
			speak_up("firing")

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/emp_act(severity)
	. = ..()
	speak_up("emp", TRUE) // Игнорируем кулдаун для критических сообщений

/obj/item/gun/energy/e_gun/hos/dreadmk3/talking/CtrlClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	personality_mode = !personality_mode
	playsound(src, 'sound/machines/terminal_button08.ogg', 30, TRUE)
	speak_up("[personality_mode ? "online" : "offline"]", TRUE, TRUE) // Игнорируем всё для этого сообщения
	to_chat(user, "<span class='notice'>[src]'s AI core is now [personality_mode ? "online" : "offline"].</span>")
	return TRUE

#undef DREADMK3_SPEECH
#undef DREADMK3_SPEECH_COOLDOWN
#undef DREADMK3_CHAT_COLOR
