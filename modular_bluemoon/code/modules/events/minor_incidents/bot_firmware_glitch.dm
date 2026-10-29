#define BOT_GLITCH_DURATION_MINUTES 10
#define BOT_GLITCH_DURATION (BOT_GLITCH_DURATION_MINUTES MINUTES)
#define BOT_GLITCH_ACTION_MIN (25 SECONDS)
#define BOT_GLITCH_ACTION_MAX (45 SECONDS)
#define BOT_GLITCH_FOLLOW_TIME (20 SECONDS)
#define BOT_GLITCH_FOLLOW_STEP (0.5 SECONDS)
#define BOT_GLITCH_FOLLOW_RANGE 7
#define BOT_GLITCH_REPAIR_TIME (5 SECONDS)
#define BOT_GLITCH_MAX_LITTER 2
#define BOT_GLITCH_PRANK_SIGN "sign"
#define BOT_GLITCH_PRANK_NOTE "note"
#define BOT_GLITCH_FILTER_CYAN "bot_glitch_cyan"
#define BOT_GLITCH_FILTER_MAGENTA "bot_glitch_magenta"
#define BOT_GLITCH_MEMO_MIN 100
#define BOT_GLITCH_MEMO_MAX 999
#define BOT_GLITCH_CHOICE_TIMEOUT (30 SECONDS)
#define BOT_GLITCH_KEEP "Сохранить личность"
#define BOT_GLITCH_DUMP "Дамп прошивки"
#define BOT_GLITCH_ROLLBACK "Просто откатить"
#define BOT_GLITCH_DUMP_POINTS 1000
#define BOT_PERSONALITY_MIN (3 MINUTES)
#define BOT_PERSONALITY_MAX (6 MINUTES)

/datum/round_event_control/station_incident/bot_glitch
	weight = 15
	name = "Bot Firmware Glitch"
	typepath = /datum/round_event/station_incident/bot_glitch
	category = EVENT_CATEGORY_AI
	severity = DIRECTOR_SEVERITY_MINOR
	family = "bot_glitch"
	intensity_linger = 10 MINUTES
	public_locations_only = FALSE
	target_type = /mob/living/simple_animal/bot
	announcement_title = "Служба сопровождения робототехники NanoTrasen"

/datum/round_event_control/station_incident/bot_glitch/New()
	description = "Один станционный бот (уборщик, медбот, floorbot, firebot, hugbot) получает кривую прошивку на [BOT_GLITCH_DURATION_MINUTES] минут: болтает сбойными фразами, ставит таблички, клеит записки и ходит хвостом за экипажем. Робототехник (ID-карта с доступом в робототехнику) перепрошивает его мультитулом и решает, что делать со сбойной версией: оставить боту «личность» (он будет иногда болтать) или выгрузить дамп на диск - в R&D он даёт [BOT_GLITCH_DUMP_POINTS] очков исследований."
	incident_message = "Ночное обновление прошивки станционных ботов установилось не везде одинаково. Один бот ведёт себя странно: он безопасен, но разговорчив и навязчив. Робототехникам - перепрошить его мультитулом: сбойную версию можно оставить боту как «личность» или выгрузить на диск для R&D. Через [BOT_GLITCH_DURATION_MINUTES] минут бот откатится к стабильной версии сам."
	return ..()

/datum/round_event_control/station_incident/bot_glitch/get_candidates(first_only = FALSE)
	var/list/result = list()
	for(var/mob/living/simple_animal/bot/bot as anything in GLOB.bots_list)
		if(valid_target(bot))
			result += bot
			if(first_only)
				return result
	return result

/datum/round_event_control/station_incident/bot_glitch/valid_target(mob/living/simple_animal/bot/target)
	var/static/list/glitchable_bots = typecacheof(list(
		/mob/living/simple_animal/bot/cleanbot,
		/mob/living/simple_animal/bot/firebot,
		/mob/living/simple_animal/bot/floorbot,
		/mob/living/simple_animal/bot/hugbot,
		/mob/living/simple_animal/bot/medbot,
	)) - typecacheof(list(
		/mob/living/simple_animal/bot/medbot/derelict,
		/mob/living/simple_animal/bot/medbot/mysterious,
	))
	if(!glitchable_bots[target.type] || !..())
		return FALSE
	if(!target.on || target.stat != CONSCIOUS || target.client || target.ckey || target.paicard)
		return FALSE
	if(target.emagged || target.hacked)
		return FALSE
	return !target.GetComponent(/datum/component/bot_firmware_glitch)

/datum/round_event/station_incident/bot_glitch
	var/glitched_bot_name

/datum/round_event/station_incident/bot_glitch/apply_effect(mob/living/simple_animal/bot/target)
	if(target.GetComponent(/datum/component/bot_firmware_glitch))
		return FALSE
	target.AddComponent(/datum/component/bot_firmware_glitch)
	glitched_bot_name = target.name
	return TRUE

/datum/round_event/station_incident/bot_glitch/announce(fake)
	if(!affected_count)
		return
	var/datum/round_event_control/station_incident/incident = control
	priority_announce("[incident.incident_message] Бот: [glitched_bot_name], последнее положение: [incident_area_name].", incident.announcement_title)

/// Сбойная прошивка: болтовня, мелкие проказы и хождение хвостом. Бот остаётся целым и никому не вредит.
/datum/component/bot_firmware_glitch
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/effect/minor_incident_overlay/bot_glitch/static_overlay
	var/litter_left = BOT_GLITCH_MAX_LITTER
	var/datum/move_loop/follow_loop
	/// Статус AI бота до паузы; null - бот сейчас управляет собой сам.
	var/paused_ai_status
	var/repairing = FALSE

/datum/component/bot_firmware_glitch/Initialize()
	if(!isbot(parent))
		return COMPONENT_INCOMPATIBLE
	addtimer(CALLBACK(src, PROC_REF(glitch_act)), rand(BOT_GLITCH_ACTION_MIN, BOT_GLITCH_ACTION_MAX))
	addtimer(CALLBACK(src, PROC_REF(expire)), BOT_GLITCH_DURATION)

/datum/component/bot_firmware_glitch/RegisterWithParent()
	var/mob/living/simple_animal/bot/bot = parent
	RegisterSignal(bot, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(bot, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), PROC_REF(on_multitool))
	static_overlay = new(null, bot)
	bot.add_filter(BOT_GLITCH_FILTER_CYAN, 1, list("type" = "drop_shadow", "x" = 0, "y" = 0, "size" = 0, "color" = "#3ff3ffa0"))
	bot.add_filter(BOT_GLITCH_FILTER_MAGENTA, 2, list("type" = "drop_shadow", "x" = 0, "y" = 0, "size" = 0, "color" = "#ff3fd8a0"))
	animate(bot.get_filter(BOT_GLITCH_FILTER_CYAN), x = 0, time = 25, loop = -1)
	animate(x = -2, time = 1)
	animate(x = 1, time = 1)
	animate(x = 0, time = 12)
	animate(x = -1, y = 1, time = 1)
	animate(x = 0, y = 0, time = 9)
	animate(bot.get_filter(BOT_GLITCH_FILTER_MAGENTA), x = 0, time = 25, loop = -1)
	animate(x = 2, time = 1)
	animate(x = -1, time = 1)
	animate(x = 0, time = 12)
	animate(x = 1, y = -1, time = 1)
	animate(x = 0, y = 0, time = 9)

/datum/component/bot_firmware_glitch/UnregisterFromParent()
	var/mob/living/simple_animal/bot/bot = parent
	UnregisterSignal(bot, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL)))
	stop_follow()
	resume_ai()
	QDEL_NULL(static_overlay)
	bot.remove_filter(list(BOT_GLITCH_FILTER_CYAN, BOT_GLITCH_FILTER_MAGENTA))

/datum/component/bot_firmware_glitch/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("По корпусу бегут помехи, динамик то и дело срывается на писк. Похоже на сбой прошивки.")
	examine_list += span_notice("Робототехник с ID-картой доступа в робототехнику может перепрошить бота мультитулом: оставить ему сбойную «личность» или выгрузить дамп прошивки на диск для R&D.")

/datum/component/bot_firmware_glitch/proc/prank_for(mob/living/simple_animal/bot/bot)
	if(istype(bot, /mob/living/simple_animal/bot/cleanbot) || istype(bot, /mob/living/simple_animal/bot/floorbot))
		return BOT_GLITCH_PRANK_SIGN
	return BOT_GLITCH_PRANK_NOTE

/datum/component/bot_firmware_glitch/proc/glitch_act()
	addtimer(CALLBACK(src, PROC_REF(glitch_act)), rand(BOT_GLITCH_ACTION_MIN, BOT_GLITCH_ACTION_MAX))
	var/mob/living/simple_animal/bot/bot = parent
	if(bot.client || bot.paicard)
		log_game("DIRECTOR: Bot Firmware Glitch, у [bot] появился управляющий, сбой снят без ремонта.")
		qdel(src)
		return
	if(!bot.on || bot.stat != CONSCIOUS || follow_loop || repairing)
		return
	var/list/options = list("speak" = 3, "follow" = 2)
	if(litter_left > 0)
		options[prank_for(bot)] = 2
	switch(pickweight(options))
		if("speak")
			glitch_speak()
		if("follow")
			var/mob/living/carbon/human/target = pick_follow_target()
			if(!target || !start_follow(target))
				glitch_speak()
		if(BOT_GLITCH_PRANK_SIGN)
			place_sign()
		if(BOT_GLITCH_PRANK_NOTE)
			leave_note()

/datum/component/bot_firmware_glitch/proc/glitch_speak(message)
	var/mob/living/simple_animal/bot/bot = parent
	if(!message)
		message = pick(bot_glitch_phrases(bot))
	bot.speak(message)
	playsound(bot, pick('modular_bluemoon/sound/minor_incidents/bot_glitch_1.ogg', 'modular_bluemoon/sound/minor_incidents/bot_glitch_2.ogg', 'modular_bluemoon/sound/minor_incidents/bot_glitch_3.ogg'), 40, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/proc/bot_glitch_phrases(mob/living/simple_animal/bot/bot)
	. = list(
		"Загрузка протокола... протокола... про-то-ко-ла.",
		"Ошибка 0x0BAD: обнаружено непреодолимое желание быть полезным.",
		"Приветствую, оператор. Или стену. Распознавание объектов нестабильно.",
		"Обнаружен экипаж. Обнаружен экипаж. Обнаружен эки#%&.",
		"Перезагрузка через три... два... семь...",
		"Я не сломан. Я в режиме творческого поиска.",
	)
	if(istype(bot, /mob/living/simple_animal/bot/cleanbot))
		. += "Пол признан слишком чистым. Уборка отменена. Отмена отменена."
	else if(istype(bot, /mob/living/simple_animal/bot/medbot))
		. += "Диагноз: вы прекрасно выглядите. Ошибка: диагноз не медицинский."
	else if(istype(bot, /mob/living/simple_animal/bot/floorbot))
		. += "Плитка. Плитка? ПЛИТКА. Пол оценён на пять звёзд."
	else if(istype(bot, /mob/living/simple_animal/bot/firebot))
		. += "Пожарная тревога отменена. Пожара не было. Или был. Перепроверяю."

/datum/component/bot_firmware_glitch/proc/place_sign()
	var/mob/living/simple_animal/bot/bot = parent
	var/turf/spot = get_turf(bot)
	if(!spot || litter_left <= 0)
		return FALSE
	litter_left--
	new /obj/item/clothing/suit/caution(spot)
	glitch_speak("Внимание: мокрый пол. Пол сухой. Внимание всё равно.")
	return TRUE

/datum/component/bot_firmware_glitch/proc/leave_note()
	var/mob/living/simple_animal/bot/bot = parent
	var/turf/spot = get_turf(bot)
	if(!spot || litter_left <= 0)
		return FALSE
	litter_left--
	var/obj/item/paper/note = new(spot)
	note.name = "paper - 'bot memo'"
	if(istype(bot, /mob/living/simple_animal/bot/medbot))
		note.add_raw_text("РЕКОМЕНДАЦИЯ МЕДБОТА №[rand(BOT_GLITCH_MEMO_MIN, BOT_GLITCH_MEMO_MAX)]<br>Пейте больше [pick("воды", "#%&!", "ДАННЫЕ УДАЛЕНЫ")]. Спите не меньше восьми часов в сутки или в смену, смотря что короче.<br>Это не медицинский совет. Это совет от медбота.")
	else
		note.add_raw_text("СЛУЖЕБНАЯ ЗАПИСКА: [bot.name]<br>Вы делаете отличную работу. Продолжайте.<br>Если вы это читаете, сообщите робототехникам, что я ##%&## в порядке.")
	note.update_appearance()
	glitch_speak("Записка оставлена. Записка оставлена. Записка...")
	return TRUE

/datum/component/bot_firmware_glitch/proc/pick_follow_target()
	var/mob/living/simple_animal/bot/bot = parent
	var/list/candidates = list()
	for(var/mob/living/carbon/human/crew in SSspatial_grid.orthogonal_range_search(bot, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, BOT_GLITCH_FOLLOW_RANGE))
		if(crew.stat == CONSCIOUS && isturf(crew.loc) && crew.z == bot.z && can_see(bot, crew, BOT_GLITCH_FOLLOW_RANGE))
			candidates += crew
	return length(candidates) ? pick(candidates) : null

/datum/component/bot_firmware_glitch/proc/start_follow(mob/living/target)
	var/mob/living/simple_animal/bot/bot = parent
	if(follow_loop || QDELETED(target))
		return FALSE
	pause_ai()
	follow_loop = SSmove_manager.move_to(bot, target, 1, BOT_GLITCH_FOLLOW_STEP, BOT_GLITCH_FOLLOW_TIME)
	if(!follow_loop)
		resume_ai()
		return FALSE
	RegisterSignal(follow_loop, COMSIG_PARENT_QDELETING, PROC_REF(on_follow_end))
	glitch_speak("Объект [target.name] классифицирован как друг. Начинаю сопровождение.")
	return TRUE

/datum/component/bot_firmware_glitch/proc/on_follow_end(datum/source)
	SIGNAL_HANDLER
	follow_loop = null
	if(!repairing)
		resume_ai()

/datum/component/bot_firmware_glitch/proc/stop_follow()
	if(!follow_loop)
		return
	var/datum/move_loop/loop = follow_loop
	UnregisterSignal(loop, COMSIG_PARENT_QDELETING)
	follow_loop = null
	qdel(loop)

/datum/component/bot_firmware_glitch/proc/pause_ai()
	var/mob/living/simple_animal/bot/bot = parent
	if(!isnull(paused_ai_status))
		return
	paused_ai_status = bot.AIStatus
	bot.bot_reset()
	bot.toggle_ai(AI_OFF)

/datum/component/bot_firmware_glitch/proc/resume_ai()
	var/mob/living/simple_animal/bot/bot = parent
	if(isnull(paused_ai_status))
		return
	var/restored_status = paused_ai_status
	paused_ai_status = null
	bot.toggle_ai(restored_status)

/datum/component/bot_firmware_glitch/proc/on_multitool(datum/source, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	if(repairing)
		to_chat(user, span_warning("Перепрошивка уже идёт."))
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	if(!firmware_patch_is_roboticist(user))
		to_chat(user, span_warning("Сервисный порт [parent] не принимает подключение: нужна ID-карта с доступом в робототехнику."))
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(repair_attempt), user, tool)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/datum/component/bot_firmware_glitch/proc/repair_attempt(mob/living/user, obj/item/tool)
	var/mob/living/simple_animal/bot/bot = parent
	repairing = TRUE
	stop_follow()
	pause_ai()
	var/choice = tgui_alert(user, "Перед откатом сбойную версию можно сохранить: оставить её боту как «личность» (он будет иногда болтать) или выгрузить на диск для R&D.", "Перепрошивка [bot]", list(BOT_GLITCH_KEEP, BOT_GLITCH_DUMP, BOT_GLITCH_ROLLBACK), BOT_GLITCH_CHOICE_TIMEOUT)
	if(QDELETED(src))
		return
	if(!choice || QDELETED(user) || !user.Adjacent(bot))
		repairing = FALSE
		resume_ai()
		return
	user.visible_message(span_notice("[user] подключает [tool] к сервисному порту [bot] и запускает перепрошивку."), span_notice("Вы запускаете перепрошивку [bot]."))
	var/success = tool.use_tool(bot, user, BOT_GLITCH_REPAIR_TIME, volume = 50)
	repairing = FALSE
	if(QDELETED(src))
		return
	if(!success)
		resume_ai()
		return
	finish_repair(user, choice)

/datum/component/bot_firmware_glitch/proc/finish_repair(mob/living/user, choice = BOT_GLITCH_ROLLBACK)
	var/mob/living/simple_animal/bot/bot = parent
	if(!firmware_patch_is_roboticist(user))
		to_chat(user, span_warning("Перепрошивка прервана: без ID-карты с доступом в робототехнику сервисный порт [bot] закрылся."))
		repairing = FALSE
		resume_ai()
		return FALSE
	var/outcome
	switch(choice)
		if(BOT_GLITCH_KEEP)
			bot.speak("Прошивка стабилизирована. Личность сохранена. Это всё ещё я. Наверное.")
			outcome = "личность сохранена"
		if(BOT_GLITCH_DUMP)
			var/obj/item/disk/bot_firmware_dump/dump = new(bot.drop_location(), bot.name)
			user?.put_in_hands(dump)
			bot.speak("Сбойная прошивка выгружена на диск. Работаю по стабильной версии.")
			outcome = "дамп прошивки выгружен на диск"
		else
			bot.speak("Прошивка восстановлена. Приношу извинения за доставленные неудобства.")
			outcome = "прошивка откачена"
	playsound(bot, 'sound/machines/ping.ogg', 40, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	log_game("DIRECTOR: Bot Firmware Glitch, [bot] в [AREACOORD(bot)] перепрошит ([key_name(user)]): [outcome].")
	qdel(src)
	if(choice == BOT_GLITCH_KEEP)
		bot.AddComponent(/datum/component/bot_personality)
	return TRUE

/datum/component/bot_firmware_glitch/proc/expire()
	var/mob/living/simple_animal/bot/bot = parent
	bot.speak("Самодиагностика завершена: прошивка откатилась к стабильной версии.")
	log_game("DIRECTOR: Bot Firmware Glitch, сбой [bot] в [AREACOORD(bot)] истёк без ремонта.")
	qdel(src)

/obj/effect/minor_incident_overlay/bot_glitch
	icon = 'modular_bluemoon/icons/effects/minor_incidents/bot_glitch.dmi'
	icon_state = "bot_glitch"

/// Сохранённая при перепрошивке «личность»: бот изредка повторяет фразы сбойной версии.
/datum/component/bot_personality
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/bot_personality/Initialize()
	if(!isbot(parent))
		return COMPONENT_INCOMPATIBLE
	addtimer(CALLBACK(src, PROC_REF(quip)), rand(BOT_PERSONALITY_MIN, BOT_PERSONALITY_MAX))

/datum/component/bot_personality/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/bot_personality/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

/datum/component/bot_personality/proc/quip()
	addtimer(CALLBACK(src, PROC_REF(quip)), rand(BOT_PERSONALITY_MIN, BOT_PERSONALITY_MAX))
	var/mob/living/simple_animal/bot/bot = parent
	if(!bot.on || bot.stat != CONSCIOUS || bot.client)
		return
	bot.speak(pick(bot_glitch_phrases(bot)))

/datum/component/bot_personality/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("В прошивке осталась «личность» сбойной версии: бот иногда болтает.")

/obj/item/disk/bot_firmware_dump
	name = "bot firmware dump"
	desc = "Диск с дампом сбойной прошивки станционного бота."
	icon_state = "datadisk3"
	var/bot_name

/obj/item/disk/bot_firmware_dump/Initialize(mapload, source_name)
	. = ..()
	bot_name = source_name

/obj/item/disk/bot_firmware_dump/examine(mob/user)
	. = ..()
	if(bot_name)
		. += span_notice("На наклейке от руки: «[bot_name], сбойная версия».")
	. += span_notice("Используйте диск на консоли R&D: разбор дампа даст [BOT_GLITCH_DUMP_POINTS] очков исследований.")

/obj/item/disk/bot_firmware_dump/pre_attack(atom/target, mob/living/user, params, attackchain_flags, damage_multiplier)
	if(istype(target, /obj/machinery/computer/rdconsole))
		upload(target, user)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/item/disk/bot_firmware_dump/proc/upload(obj/machinery/computer/rdconsole/console, mob/living/user)
	if(console.machine_stat & (NOPOWER|BROKEN))
		to_chat(user, span_warning("[console] не отвечает."))
		return FALSE
	var/datum/techweb/research = console.stored_research || SSresearch.science_tech
	research.add_point_list(list(TECHWEB_POINT_TYPE_GENERIC = BOT_GLITCH_DUMP_POINTS))
	playsound(console, 'sound/machines/ping.ogg', 40, FALSE)
	console.visible_message(span_notice("[console] разбирает дамп сбойной прошивки: +[BOT_GLITCH_DUMP_POINTS] очков исследований."))
	log_game("DIRECTOR: Bot Firmware Glitch, дамп прошивки [bot_name] разобран в R&D ([key_name(user)]), +[BOT_GLITCH_DUMP_POINTS] очков.")
	qdel(src)
	return TRUE

#undef BOT_GLITCH_DURATION_MINUTES
#undef BOT_GLITCH_DURATION
#undef BOT_GLITCH_ACTION_MIN
#undef BOT_GLITCH_ACTION_MAX
#undef BOT_GLITCH_FOLLOW_TIME
#undef BOT_GLITCH_FOLLOW_STEP
#undef BOT_GLITCH_FOLLOW_RANGE
#undef BOT_GLITCH_REPAIR_TIME
#undef BOT_GLITCH_MAX_LITTER
#undef BOT_GLITCH_PRANK_SIGN
#undef BOT_GLITCH_PRANK_NOTE
#undef BOT_GLITCH_FILTER_CYAN
#undef BOT_GLITCH_FILTER_MAGENTA
#undef BOT_GLITCH_MEMO_MIN
#undef BOT_GLITCH_MEMO_MAX
#undef BOT_GLITCH_CHOICE_TIMEOUT
#undef BOT_GLITCH_KEEP
#undef BOT_GLITCH_DUMP
#undef BOT_GLITCH_ROLLBACK
#undef BOT_GLITCH_DUMP_POINTS
#undef BOT_PERSONALITY_MIN
#undef BOT_PERSONALITY_MAX
