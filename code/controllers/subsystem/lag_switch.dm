/// Подсистема экстренного снижения нагрузки (порт tg SSlag_switch): при перегрузе
/// сервера гасит косметику (рунечат, параллакс, звуки шагов и т.п.), капая
/// пиковую стоимость тика. Меры включаются админом через верб "Lag Switch"
/// или автоматически по порогу онлайна (config auto_lag_switch_pop) с
/// 20-секундным окном вето для админов.
SUBSYSTEM_DEF(lag_switch)
	name = "Lag Switch"
	flags = SS_NO_FIRE

	/// If the lag switch measures should attempt to trigger automatically
	var/auto_switch = FALSE
	/// Amount of connected clients at which the Lag Switch should engage
	var/trigger_pop = INFINITY
	/// List of bools corresponding to code/__DEFINES/lag_switch.dm
	var/static/list/measures[MEASURES_AMOUNT]
	/// Measures that toggle during automatic activation
	var/list/auto_measures = list(DISABLE_RUNECHAT, DISABLE_DEAD_RUNECHAT, DISABLE_USR_ICON2HTML, DISABLE_PARALLAX, DISABLE_FOOTSTEPS)
	/// Measures actually wired into this codebase; the rest are slot placeholders
	var/list/wired_measures = list(DISABLE_RUNECHAT, DISABLE_DEAD_RUNECHAT, DISABLE_USR_ICON2HTML, SLOWMODE_SAY, DISABLE_PARALLAX, DISABLE_FOOTSTEPS)
	/// Timer ID for the automatic veto period
	var/veto_timer_id
	/// Cooldown between say verb uses when slowmode is enabled
	var/slowmode_cooldown = 3 SECONDS

/datum/controller/subsystem/lag_switch/Initialize()
	for(var/i in 1 to measures.len)
		if(isnull(measures[i]))
			measures[i] = FALSE
	var/auto_switch_pop = CONFIG_GET(number/auto_lag_switch_pop)
	if(auto_switch_pop)
		auto_switch = TRUE
		trigger_pop = auto_switch_pop
		RegisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT, PROC_REF(client_connected))
	return ..()

/// Пересоздание МК (NEW_SS_GLOBAL): measures - static и переживает замену
/// инстанса сам, а админские настройки и взведённое окно вето - нет.
/// Таймер вето держит колбэк на старый инстанс - перевзводим на новый.
/// Регистрацию сигнала подключения не трогаем: в пути полной переинициализации
/// её сделает Initialize() по конфигу.
/datum/controller/subsystem/lag_switch/Recover()
	auto_switch = SSlag_switch.auto_switch
	trigger_pop = SSlag_switch.trigger_pop
	slowmode_cooldown = SSlag_switch.slowmode_cooldown
	if(SSlag_switch.veto_timer_id)
		deltimer(SSlag_switch.veto_timer_id)
		veto_timer_id = addtimer(CALLBACK(src, PROC_REF(auto_activate)), 20 SECONDS, TIMER_STOPPABLE)

/datum/controller/subsystem/lag_switch/proc/client_connected(datum/source, client/connected)
	SIGNAL_HANDLER
	if(veto_timer_id) //окно вето уже идёт - второй таймер перезаписал бы ссылку и стал неотменяемым
		return
	if(length(GLOB.clients) < trigger_pop)
		return

	auto_switch = FALSE
	UnregisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT)
	veto_timer_id = addtimer(CALLBACK(src, PROC_REF(auto_activate)), 20 SECONDS, TIMER_STOPPABLE)
	message_admins("Lag Switch: порог онлайна ([trigger_pop]) достигнут. Автовключение мер снижения нагрузки через 20 секунд. Отменить: верб Lag Switch -> \"Отменить автовключение\".")
	log_admin("Lag Switch population threshold reached. Automatic activation of lag mitigation measures in 20 seconds.")

/// Срабатывание таймера автовключения: онлайн мог упасть за окно вето
/// (клиент отвалился сам), тогда меры не включаем и перевзводим автотриггер.
/datum/controller/subsystem/lag_switch/proc/auto_activate()
	veto_timer_id = null
	if(length(GLOB.clients) < trigger_pop)
		auto_switch = TRUE
		RegisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT, PROC_REF(client_connected), override = TRUE)
		message_admins("Lag Switch: онлайн упал ниже порога за окно вето, автовключение отменено и перевзведено.")
		return
	set_all_measures(TRUE, TRUE)

/// (En/Dis)able automatic triggering of switches based on client count
/datum/controller/subsystem/lag_switch/proc/toggle_auto_enable()
	auto_switch = !auto_switch
	if(auto_switch)
		RegisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT, PROC_REF(client_connected))
	else
		UnregisterSignal(SSdcs, COMSIG_GLOB_CLIENT_CONNECT)

/// Called from the admin verb to cancel a pending automatic activation
/datum/controller/subsystem/lag_switch/proc/cancel_auto_enable_in_progress()
	if(!veto_timer_id)
		return FALSE
	deltimer(veto_timer_id)
	veto_timer_id = null
	return TRUE

/// Update the slowmode timer length and clear existing cooldowns if reduced
/datum/controller/subsystem/lag_switch/proc/change_slowmode_cooldown(length_seconds)
	if(!length_seconds)
		return FALSE

	var/length_ds = length_seconds SECONDS
	if(length_ds <= 0)
		length_ds = 1 // one tick because cooldowns do not like 0

	if(length_ds < slowmode_cooldown)
		for(var/client/C as anything in GLOB.clients)
			COOLDOWN_RESET(C, say_slowmode)

	slowmode_cooldown = length_ds
	if(measures[SLOWMODE_SAY])
		to_chat(world, "<span class='boldannounce'>Интервал слоумода чата изменён на [length_seconds] сек.</span>")
	return TRUE

/// Handle the state change for individual measures
/datum/controller/subsystem/lag_switch/proc/set_measure(measure_key, state)
	if(isnull(measure_key) || isnull(state))
		stack_trace("SSlag_switch.set_measure() was called with a null arg")
		return FALSE
	if(!isnum(measure_key) || measure_key < 1 || measure_key > MEASURES_AMOUNT)
		stack_trace("SSlag_switch.set_measure() was called with an invalid measure_key")
		return FALSE
	if(measures[measure_key] == state)
		return TRUE

	measures[measure_key] = state

	switch(measure_key)
		if(SLOWMODE_SAY)
			if(state)
				to_chat(world, "<span class='boldannounce'>Для снижения нагрузки включён слоумод IC-чата: не чаще одного сообщения раз в [slowmode_cooldown / 10] сек.</span>")
			else
				for(var/client/C as anything in GLOB.clients)
					COOLDOWN_RESET(C, say_slowmode)
				to_chat(world, "<span class='boldannounce'>Слоумод IC-чата выключен.</span>")
		if(DISABLE_PARALLAX)
			if(state)
				to_chat(world, "<span class='boldannounce'>Параллакс временно отключён для снижения нагрузки.</span>")
			else
				to_chat(world, "<span class='boldannounce'>Параллакс снова включён.</span>")
			for(var/client/C as anything in GLOB.clients)
				C.parallax_holder?.Reset(null, TRUE)
		if(DISABLE_FOOTSTEPS)
			if(state)
				to_chat(world, "<span class='boldannounce'>Звуки шагов временно отключены для снижения нагрузки.</span>")
			else
				to_chat(world, "<span class='boldannounce'>Звуки шагов снова включены.</span>")
		if(DISABLE_RUNECHAT)
			if(state)
				to_chat(world, "<span class='boldannounce'>Рунечат (текст над головами) временно отключён для снижения нагрузки.</span>")
			else
				to_chat(world, "<span class='boldannounce'>Рунечат снова включён.</span>")

	return TRUE

/// Helper to loop over all measures for mass changes
/datum/controller/subsystem/lag_switch/proc/set_all_measures(state, automatic = FALSE)
	if(isnull(state))
		stack_trace("SSlag_switch.set_all_measures() was called with a null state arg")
		return FALSE

	if(automatic)
		message_admins("Lag Switch: автоматическое включение мер снижения нагрузки.")
		log_admin("Lag Switch enabling automatic measures now.")
		veto_timer_id = null
		for(var/i in 1 to auto_measures.len)
			set_measure(auto_measures[i], state)
		return TRUE

	for(var/i in 1 to measures.len)
		set_measure(i, state)
	return TRUE

// --- Админ-верб управления ---

GLOBAL_LIST_INIT(lag_switch_measure_names, list(
	"Заморозить свободный полёт призраков (не подключено)",
	"Запретить зум/т-рей призракам (не подключено)",
	"Отключить рунечат живых",
	"Отключить icon2html в вербах (examine и т.п.)",
	"Джойн только обсервером (не подключено)",
	"Слоумод IC-чата",
	"Отключить параллакс",
	"Отключить звуки шагов",
	"Отключить рунечат для мёртвых",
))

/client/proc/lag_switch_panel()
	set name = "Lag Switch"
	set category = "Debug"
	set desc = "Меры экстренного снижения нагрузки: рунечат, параллакс, шаги и т.д."
	if(!check_rights(R_DEBUG))
		return

	var/list/options = list()
	for(var/i in 1 to MEASURES_AMOUNT)
		var/state_label = SSlag_switch.measures[i] ? "ВКЛ " : "выкл"
		options["[state_label] - [GLOB.lag_switch_measure_names[i]]"] = i
	options["--- Включить все меры"] = "all_on"
	options["--- Выключить все меры"] = "all_off"
	options["--- Автовключение по онлайну: [SSlag_switch.auto_switch ? "ВКЛ (порог [SSlag_switch.trigger_pop])" : "выкл"]"] = "auto"
	options["--- Порог автовключения: [SSlag_switch.trigger_pop]"] = "pop"
	options["--- Интервал слоумода: [SSlag_switch.slowmode_cooldown / 10] сек"] = "slowmode"
	if(SSlag_switch.veto_timer_id)
		options["--- ОТМЕНИТЬ запланированное автовключение"] = "veto"

	var/choice = input(src, "Меры снижения нагрузки. Выбор меры переключает её.", "Lag Switch") as null|anything in options
	if(isnull(choice))
		return
	var/action = options[choice]
	switch(action)
		if("all_on")
			SSlag_switch.set_all_measures(TRUE)
			log_admin("[key_name(src)] enabled all lag switch measures")
			message_admins("[key_name_admin(src)] включает все меры Lag Switch.")
		if("all_off")
			SSlag_switch.set_all_measures(FALSE)
			log_admin("[key_name(src)] disabled all lag switch measures")
			message_admins("[key_name_admin(src)] выключает все меры Lag Switch.")
		if("auto")
			SSlag_switch.toggle_auto_enable()
			message_admins("[key_name_admin(src)] переключает автовключение Lag Switch: [SSlag_switch.auto_switch ? "ВКЛ" : "выкл"].")
		if("pop")
			var/new_pop = input(src, "Порог онлайна для автовключения мер:", "Lag Switch", SSlag_switch.trigger_pop) as null|num
			if(!isnull(new_pop) && new_pop > 0)
				SSlag_switch.trigger_pop = new_pop
				message_admins("[key_name_admin(src)] ставит порог автовключения Lag Switch: [new_pop].")
		if("slowmode")
			var/new_cd = input(src, "Интервал слоумода в секундах:", "Lag Switch", SSlag_switch.slowmode_cooldown / 10) as null|num
			if(!isnull(new_cd) && SSlag_switch.change_slowmode_cooldown(new_cd))
				message_admins("[key_name_admin(src)] ставит интервал слоумода: [new_cd] сек.")
		if("veto")
			if(SSlag_switch.cancel_auto_enable_in_progress())
				message_admins("[key_name_admin(src)] отменяет запланированное автовключение мер Lag Switch.")
		else
			var/toggled = SSlag_switch.measures[action]
			SSlag_switch.set_measure(action, !toggled)
			log_admin("[key_name(src)] toggled lag switch measure #[action] to [!toggled]")
			message_admins("[key_name_admin(src)] переключает меру Lag Switch \"[GLOB.lag_switch_measure_names[action]]\": [!toggled ? "ВКЛ" : "выкл"].")

/datum/controller/subsystem/lag_switch/stat_entry(msg)
	var/active = 0
	for(var/i in 1 to MEASURES_AMOUNT)
		if(measures[i])
			active++
	msg = "мер:[active]/[MEASURES_AMOUNT][auto_switch ? " авто@[trigger_pop]" : ""]"
	return ..()
