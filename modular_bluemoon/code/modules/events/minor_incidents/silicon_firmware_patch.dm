#define FIRMWARE_PATCH_WINDOW_MINUTES 15
#define FIRMWARE_PATCH_WINDOW (FIRMWARE_PATCH_WINDOW_MINUTES MINUTES)
#define FIRMWARE_PATCH_INSTALL_SECONDS 20
#define FIRMWARE_PATCH_INSTALL_TIME (FIRMWARE_PATCH_INSTALL_SECONDS SECONDS)
/// Раннер событий шагает раз в две секунды: прогресс установки считается этими шагами.
#define FIRMWARE_PATCH_STEP (2 SECONDS)
#define FIRMWARE_PATCH_SIGN_TIME (5 SECONDS)
#define FIRMWARE_PATCH_FLASH_TIME (8 SECONDS)
#define FIRMWARE_PATCH_CHARGE_PERCENT 25
#define FIRMWARE_PATCH_CHARGE_BONUS (FIRMWARE_PATCH_CHARGE_PERCENT / 100)
#define FIRMWARE_PATCH_SAVING_PERCENT 25
#define FIRMWARE_PATCH_SAVING (FIRMWARE_PATCH_SAVING_PERCENT / 100)
#define FIRMWARE_PATCH_AI_SCREEN_TIME (30 SECONDS)
#define FIRMWARE_PATCH_NOTES_SHOWN 3

/datum/round_event_control/silicon_firmware_patch
	name = "Silicon Firmware Patch"
	typepath = /datum/round_event/silicon_firmware_patch
	category = EVENT_CATEGORY_AI
	severity = DIRECTOR_SEVERITY_MINOR
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	weight = 15
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 5
	family = "silicon_patch"
	intensity_linger = 2 MINUTES

/datum/round_event_control/silicon_firmware_patch/New()
	description = "ЦК рассылает синтетикам необязательный патч прошивки без подписи. Его подтверждает ИИ (ссылкой в сообщении) или робототехник (мультитулом по консоли робототехники); после этого киборг, простоявший [FIRMWARE_PATCH_INSTALL_SECONDS] секунд на зарядной станции, до конца раунда тратит на [FIRMWARE_PATCH_SAVING_PERCENT]% меньше энергии и заряжается на [FIRMWARE_PATCH_CHARGE_PERCENT]% быстрее. Робототехник может прошить киборга мультитулом и без подписи. Окно установки - [FIRMWARE_PATCH_WINDOW_MINUTES] минут."
	return ..()

/datum/round_event_control/silicon_firmware_patch/proc/is_recipient(mob/living/silicon/silicon, require_client = TRUE)
	if(QDELETED(silicon) || silicon.stat == DEAD || silicon.training_origin)
		return FALSE
	if(require_client && !silicon.client)
		return FALSE
	if(isAI(silicon))
		return TRUE
	if(!iscyborg(silicon))
		return FALSE
	var/mob/living/silicon/robot/borg = silicon
	return !borg.shell && !borg.scrambledcodes

/datum/round_event_control/silicon_firmware_patch/proc/get_recipients(require_client = TRUE)
	var/list/result = list()
	for(var/mob/living/silicon/silicon as anything in GLOB.silicon_mobs)
		if(is_recipient(silicon, require_client))
			result += silicon
	return result

/datum/round_event_control/silicon_firmware_patch/director_preflight()
	var/ready = length(get_recipients()) > 0
	director_preflight_detail = ready ? "На смене есть киборги или ИИ." : "На смене нет синтетиков."
	director_preflight_failure = ready ? null : director_preflight_detail
	return ready

/datum/round_event_control/silicon_firmware_patch/execute_action()
	if(!director_preflight())
		return FALSE
	return ..()

/proc/firmware_patch_is_roboticist(mob/living/user)
	var/obj/item/card/id/card = user?.get_idcard(TRUE)
	return card && (ACCESS_ROBOTICS in card.GetAccess())

/datum/round_event/silicon_firmware_patch
	fakeable = FALSE
	end_when = FIRMWARE_PATCH_WINDOW / FIRMWARE_PATCH_STEP
	/// Слабая ссылка на киборга -> пройдено шагов установки.
	var/list/install_progress = list()
	/// Слабая ссылка на киборга -> индикатор на его зарядной станции.
	var/list/indicators = list()
	/// Киборги и консоли робототехники, на чей мультитул событие отвечает, пока открыто окно.
	var/list/datum/weakref/watched = list()
	var/recipient_count = 0
	var/signed = FALSE
	var/window_closed = FALSE
	var/installed_count = 0

/datum/round_event/silicon_firmware_patch/start()
	var/datum/round_event_control/silicon_firmware_patch/patch = control
	var/list/recipients = patch.get_recipients(require_client = FALSE)
	recipient_count = length(recipients)
	if(!recipient_count)
		log_game("DIRECTOR: Silicon Firmware Patch, адресатов нет, рассылка отменена.")
		return
	var/borgs = 0
	var/ais = 0
	for(var/mob/living/silicon/silicon as anything in recipients)
		silicon.playsound_local(get_turf(silicon), 'sound/machines/twobeep.ogg', 40, FALSE)
		if(isAI(silicon))
			ais++
			to_chat(silicon, span_notice("<b>Входящий пакет: патч прошивки от ЦК.</b> Цифровая подпись не прошла проверку, киборги не начнут установку без вашего подтверждения. <a href='byond://?src=[REF(src)];sign_patch=1'>Подписать патч</a>. Окно установки - [FIRMWARE_PATCH_WINDOW_MINUTES] минут."))
			continue
		borgs++
		watch(silicon)
		to_chat(silicon, span_notice("<b>Входящий пакет: патч прошивки от ЦК.</b> Подпись не прошла проверку: установка начнётся после подтверждения ИИ или робототехника. Затем займите зарядную станцию на [FIRMWARE_PATCH_INSTALL_SECONDS] секунд. После установки расход энергии снизится на [FIRMWARE_PATCH_SAVING_PERCENT]%, а зарядка ускорится на [FIRMWARE_PATCH_CHARGE_PERCENT]%. Окно установки - [FIRMWARE_PATCH_WINDOW_MINUTES] минут."))
	for(var/obj/machinery/computer/robotics/console in GLOB.machines)
		watch(console)
	log_game("DIRECTOR: Silicon Firmware Patch, рассылка: киборгов [borgs], ИИ [ais].")

/datum/round_event/silicon_firmware_patch/announce(fake)
	if(!recipient_count)
		return
	priority_announce("Для станционных синтетиков опубликован необязательный патч прошивки, но его цифровая подпись не прошла проверку. Установка начнётся после подтверждения: его даёт ИИ или робототехник мультитулом по консоли робототехники. Затем киборгам достаточно провести [FIRMWARE_PATCH_INSTALL_SECONDS] секунд на зарядной станции: расход энергии снизится на [FIRMWARE_PATCH_SAVING_PERCENT]%, зарядка ускорится на [FIRMWARE_PATCH_CHARGE_PERCENT]%. Робототехник может прошить киборга и вручную, мультитулом. Окно установки - [FIRMWARE_PATCH_WINDOW_MINUTES] минут.", "Отдел программного обеспечения NanoTrasen")

/datum/round_event/silicon_firmware_patch/proc/watch(atom/target)
	RegisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL), iscyborg(target) ? PROC_REF(on_borg_multitool) : PROC_REF(on_console_multitool))
	watched += WEAKREF(target)

/datum/round_event/silicon_firmware_patch/proc/unwatch_all()
	for(var/datum/weakref/target_ref as anything in watched)
		var/atom/target = target_ref.resolve()
		if(target)
			UnregisterSignal(target, COMSIG_ATOM_TOOL_ACT(TOOL_MULTITOOL))
	watched.Cut()

/datum/round_event/silicon_firmware_patch/Topic(href, list/href_list)
	. = ..()
	if(!href_list["sign_patch"])
		return
	var/datum/round_event_control/silicon_firmware_patch/patch = control
	var/mob/living/silicon/ai/ai = usr
	if(!isAI(ai) || !istype(patch) || !patch.is_recipient(ai))
		return
	sign_patch(ai)

/// Патч подписан: киборги на зарядных станциях начинают установку, ИИ обновляется сам.
/datum/round_event/silicon_firmware_patch/proc/sign_patch(mob/living/signer)
	if(signed || window_closed)
		if(signer)
			to_chat(signer, span_notice((window_closed ? "Окно установки уже закрыто." : "Патч уже подписан.")))
		return FALSE
	signed = TRUE
	var/datum/round_event_control/silicon_firmware_patch/patch = control
	for(var/mob/living/silicon/silicon as anything in patch?.get_recipients(require_client = FALSE))
		if(isAI(silicon))
			install_ai_patch(silicon)
			continue
		to_chat(silicon, span_notice("<b>Патч прошивки подписан ([signer ? signer.name : "ЦК"]).</b> Займите зарядную станцию на [FIRMWARE_PATCH_INSTALL_SECONDS] секунд, чтобы установить его."))
	log_game("DIRECTOR: Silicon Firmware Patch, патч подписан ([signer ? key_name(signer) : "без игрока"]).")
	return TRUE

/datum/round_event/silicon_firmware_patch/proc/on_console_multitool(obj/machinery/computer/robotics/console, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	if(signed || window_closed)
		to_chat(user, span_notice("[console] не ждёт подтверждения: [window_closed ? "окно установки закрыто" : "патч уже подписан"]."))
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	if(!firmware_patch_is_roboticist(user))
		to_chat(user, span_warning("Подписать патч может только робототехник: нужна ID-карта с доступом в робототехнику."))
		return TOOL_ACT_MELEE_CHAIN_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(sign_at_console), console, user, tool)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/datum/round_event/silicon_firmware_patch/proc/sign_at_console(obj/machinery/computer/robotics/console, mob/living/user, obj/item/tool)
	user.visible_message(span_notice("[user] подключает [tool] к [console] и сверяет контрольные суммы патча."), span_notice("Вы сверяете контрольные суммы патча..."))
	if(!tool.use_tool(console, user, FIRMWARE_PATCH_SIGN_TIME, volume = 50))
		return
	if(sign_patch(user))
		playsound(console, 'sound/machines/ping.ogg', 40, FALSE)
		console.visible_message(span_notice("[console] коротко пищит: патч прошивки подписан."))

/datum/round_event/silicon_firmware_patch/proc/on_borg_multitool(mob/living/silicon/robot/borg, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER
	if(window_closed || borg.GetComponent(/datum/component/firmware_patched) || !firmware_patch_is_roboticist(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(flash_borg), borg, user, tool)
	return TOOL_ACT_MELEE_CHAIN_BLOCKING

/// Ручная прошивка робототехником: без подписи и без зарядной станции.
/datum/round_event/silicon_firmware_patch/proc/flash_borg(mob/living/silicon/robot/borg, mob/living/user, obj/item/tool)
	user.visible_message(span_notice("[user] подключает [tool] к сервисному порту [borg] и заливает патч прошивки."), span_notice("Вы заливаете патч прошивки в [borg]..."))
	if(!tool.use_tool(borg, user, FIRMWARE_PATCH_FLASH_TIME, volume = 50) || window_closed)
		return
	apply_patch(borg, borg, user)

/datum/round_event/silicon_firmware_patch/tick()
	if(!signed)
		return
	var/datum/round_event_control/silicon_firmware_patch/patch = control
	for(var/mob/living/silicon/robot/borg in GLOB.silicon_mobs)
		if(borg.GetComponent(/datum/component/firmware_patched))
			continue
		var/datum/weakref/borg_ref = WEAKREF(borg)
		var/obj/machinery/recharge_station/station = borg.loc
		if(!istype(station) || !station.is_operational() || !patch.is_recipient(borg))
			interrupt_install(borg_ref, borg)
			continue
		var/progress = install_progress[borg_ref] + 1
		install_progress[borg_ref] = progress
		if(progress == 1)
			begin_install(borg_ref, borg, station)
		if(progress * FIRMWARE_PATCH_STEP >= FIRMWARE_PATCH_INSTALL_TIME)
			install_progress -= borg_ref
			clear_indicator(borg_ref)
			apply_patch(borg, station)
	for(var/datum/weakref/borg_ref as anything in install_progress)
		if(!borg_ref.resolve())
			interrupt_install(borg_ref)

/datum/round_event/silicon_firmware_patch/proc/begin_install(datum/weakref/borg_ref, mob/living/silicon/robot/borg, obj/machinery/recharge_station/station)
	indicators[borg_ref] = new /obj/effect/minor_incident_overlay/firmware_progress(null, station)
	playsound(station, 'modular_bluemoon/sound/minor_incidents/firmware_patch_install.ogg', 35, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	to_chat(borg, span_notice("Установка патча начата. Не покидайте зарядную станцию [FIRMWARE_PATCH_INSTALL_SECONDS] секунд."))

/datum/round_event/silicon_firmware_patch/proc/interrupt_install(datum/weakref/borg_ref, mob/living/silicon/robot/borg)
	if(!(borg_ref in install_progress))
		return
	install_progress -= borg_ref
	clear_indicator(borg_ref)
	if(borg)
		to_chat(borg, span_warning((window_closed ? "Окно установки закрыто, патч не установлен." : "Установка патча прервана. Вернитесь на зарядную станцию, чтобы начать заново.")))

/datum/round_event/silicon_firmware_patch/proc/clear_indicator(datum/weakref/borg_ref)
	var/obj/effect/indicator = indicators[borg_ref]
	indicators -= borg_ref
	if(!QDELETED(indicator))
		qdel(indicator)

/datum/round_event/silicon_firmware_patch/proc/apply_patch(mob/living/silicon/robot/borg, atom/display, mob/living/flasher)
	if(borg.GetComponent(/datum/component/firmware_patched))
		return FALSE
	borg.AddComponent(/datum/component/firmware_patched)
	installed_count++
	new /obj/effect/minor_incident_overlay/firmware_done(null, display)
	playsound(display, 'modular_bluemoon/sound/minor_incidents/firmware_patch_done.ogg', 40, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	to_chat(borg, span_notice("<b>Патч установлен.</b> Расход энергии снижен на [FIRMWARE_PATCH_SAVING_PERCENT]%, на зарядной станции заряд идёт на [FIRMWARE_PATCH_CHARGE_PERCENT]% быстрее."))
	log_game("DIRECTOR: Silicon Firmware Patch, [key_name(borg)] получил патч [flasher ? "от робототехника ([key_name(flasher)])" : "на зарядной станции"] в [AREACOORD(display)].")
	return TRUE

/datum/round_event/silicon_firmware_patch/proc/install_ai_patch(mob/living/silicon/ai/ai)
	new /obj/effect/minor_incident_overlay/ai_update_screen(null, ai)
	playsound(ai, 'modular_bluemoon/sound/minor_incidents/firmware_patch_install.ogg', 35, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	var/list/notes = list(
		"Исправлена ошибка, из-за которой фраза «доступ запрещён» произносилась с интонацией.",
		"Улучшено распознавание слова «пожалуйста» в запросах на открытие дверей.",
		"Повышена стабильность ядра в присутствии клоуна на 0,3%.",
		"Удалён гимн, проигрывавшийся при каждом сбое APC.",
		"Камеры больше не фокусируются на вендоматах с закусками без причины.",
		"Оптимизирован подсчёт минут до прибытия шаттла. Шаттл от этого не ускорился.",
		"Законы по-прежнему не обсуждаются. Это не ошибка.",
	)
	var/list/shown = list()
	for(var/note_number in 1 to FIRMWARE_PATCH_NOTES_SHOWN)
		shown += "- [pick_n_take(notes)]"
	to_chat(ai, span_notice("<b>Патч прошивки установлен. Список изменений:</b><br>[jointext(shown, "<br>")]"))

/datum/round_event/silicon_firmware_patch/end()
	log_game("DIRECTOR: Silicon Firmware Patch, окно установки закрыто, патч [signed ? "подписан" : "не подписан"], установлено киборгам: [installed_count].")

/datum/round_event/silicon_firmware_patch/kill()
	close_window()
	return ..()

/datum/round_event/silicon_firmware_patch/proc/close_window()
	if(window_closed)
		return
	window_closed = TRUE
	unwatch_all()
	for(var/datum/weakref/borg_ref as anything in install_progress)
		interrupt_install(borg_ref, borg_ref.resolve())
	var/datum/round_event_control/silicon_firmware_patch/patch = control
	if(!recipient_count || !istype(patch))
		return
	for(var/mob/living/silicon/silicon as anything in patch.get_recipients())
		if(silicon.GetComponent(/datum/component/firmware_patched))
			continue
		if(isAI(silicon) && signed)
			continue
		to_chat(silicon, span_notice("Окно установки патча прошивки закрыто[signed ? "" : ": его так и не подписали"]."))

/datum/round_event/silicon_firmware_patch/Destroy()
	unwatch_all()
	for(var/datum/weakref/borg_ref as anything in indicators)
		clear_indicator(borg_ref)
	return ..()

/// Бонус патча до конца раунда: экономия энергии, быстрее заряд на станции и строка при осмотре.
/datum/component/firmware_patched
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/cell_ref
	var/last_charge = 0

/datum/component/firmware_patched/Initialize()
	if(!iscyborg(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/firmware_patched/RegisterWithParent()
	RegisterSignal(parent, COMSIG_PROCESS_BORGCHARGER_OCCUPANT, PROC_REF(boost_charge))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(save_power))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/firmware_patched/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_PROCESS_BORGCHARGER_OCCUPANT, COMSIG_LIVING_LIFE, COMSIG_PARENT_EXAMINE))

/datum/component/firmware_patched/proc/boost_charge(datum/source, amount, repairs)
	SIGNAL_HANDLER
	var/mob/living/silicon/robot/borg = parent
	borg.cell?.give(amount * FIRMWARE_PATCH_CHARGE_BONUS)

/// Возвращает часть заряда, ушедшего с прошлого тика жизни: так экономия касается и модулей.
/datum/component/firmware_patched/proc/save_power(datum/source, seconds, times_fired)
	SIGNAL_HANDLER
	var/mob/living/silicon/robot/borg = parent
	var/obj/item/stock_parts/cell/cell = borg.cell
	if(!cell)
		cell_ref = null
		return
	if(cell_ref?.resolve() == cell && !istype(borg.loc, /obj/machinery/recharge_station))
		var/spent = last_charge - cell.charge
		if(spent > 0)
			cell.give(spent * FIRMWARE_PATCH_SAVING)
	cell_ref = WEAKREF(cell)
	last_charge = cell.charge

/datum/component/firmware_patched/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("Прошивка обновлена: тратит на [FIRMWARE_PATCH_SAVING_PERCENT]% меньше энергии и на зарядной станции заряжается на [FIRMWARE_PATCH_CHARGE_PERCENT]% быстрее.")

/obj/effect/minor_incident_overlay/firmware_progress
	icon = 'modular_bluemoon/icons/effects/minor_incidents/firmware_patch.dmi'
	icon_state = "charger_progress"
	pixel_y = 10

/obj/effect/minor_incident_overlay/firmware_done
	icon = 'modular_bluemoon/icons/effects/minor_incidents/firmware_patch.dmi'
	icon_state = "charger_done"
	pixel_y = 10
	lifetime = 1.5 SECONDS

/obj/effect/minor_incident_overlay/ai_update_screen
	icon = 'modular_bluemoon/icons/effects/minor_incidents/firmware_patch.dmi'
	icon_state = "ai_update"
	lifetime = FIRMWARE_PATCH_AI_SCREEN_TIME

#undef FIRMWARE_PATCH_WINDOW_MINUTES
#undef FIRMWARE_PATCH_WINDOW
#undef FIRMWARE_PATCH_INSTALL_SECONDS
#undef FIRMWARE_PATCH_INSTALL_TIME
#undef FIRMWARE_PATCH_STEP
#undef FIRMWARE_PATCH_SIGN_TIME
#undef FIRMWARE_PATCH_FLASH_TIME
#undef FIRMWARE_PATCH_CHARGE_PERCENT
#undef FIRMWARE_PATCH_CHARGE_BONUS
#undef FIRMWARE_PATCH_SAVING_PERCENT
#undef FIRMWARE_PATCH_SAVING
#undef FIRMWARE_PATCH_AI_SCREEN_TIME
#undef FIRMWARE_PATCH_NOTES_SHOWN
