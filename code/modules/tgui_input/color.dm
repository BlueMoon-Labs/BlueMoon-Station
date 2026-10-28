// Открывает выбор цвета и возвращает #RRGGBB либо null при отмене, закрытии или тайм-ауте.
// user: моб или клиент; message: пояснение; title: заголовок; default: исходный цвет.
// timeout задаётся в децисекундах; 0 отключает ограничение времени.
/proc/tgui_input_color(mob/user, message = "", title = "Выбор цвета", default = COLOR_WHITE, timeout = 0)
	if(!user)
		user = usr
	if(istype(user, /client))
		var/client/client = user
		user = client.mob
	if(!istype(user) || !user.client)
		return null
	default = uppertext(sanitize_hexcolor(default, 6, TRUE, COLOR_WHITE))
	if(!user.client.prefs.tgui_input_mode)
		var/mob/prompt_mob = begin_native_prompt(user)
		var/native_color = input(user, message, title, default) as null|color
		end_native_prompt(prompt_mob)
		return isnull(native_color) ? null : uppertext(sanitize_hexcolor(native_color, 6, TRUE, COLOR_WHITE))
	var/datum/tgui_input_color/color_input = new(user, message, title, default, timeout)
	color_input.ui_interact(user)
	color_input.wait()
	if(!QDELETED(color_input))
		. = color_input.entry
		qdel(color_input)

// Общий диалог выбора цвета; подтверждённое значение проверяется на сервере.
/datum/tgui_input_color
	var/closed = FALSE
	var/default
	var/entry
	var/message
	var/start_time
	var/timeout
	var/title
	var/timeout_timer

/datum/tgui_input_color/New(mob/user, message, title, default, timeout)
	src.default = uppertext(sanitize_hexcolor(default, 6, TRUE, COLOR_WHITE))
	src.message = message
	src.title = title
	if(timeout > 0)
		src.timeout = timeout
		start_time = world.time
		timeout_timer = QDEL_IN_STOPPABLE(src, timeout)

/datum/tgui_input_color/Destroy(force, ...)
	closed = TRUE
	if(timeout_timer)
		deltimer(timeout_timer)
		timeout_timer = null
	SStgui.close_uis(src)
	return ..()

/datum/tgui_input_color/proc/wait()
	while(isnull(entry) && !closed && !QDELETED(src))
		stoplag(1)

/datum/tgui_input_color/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ColorInputModal")
		if(!ui.open())
			qdel(ui)
			ui_close(user)

/datum/tgui_input_color/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_input_color/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_input_color/ui_static_data(mob/user)
	return list(
		"init_value" = default,
		"large_buttons" = user.client.prefs.tgui_large_buttons,
		"swapped_buttons" = !user.client.prefs.tgui_swapped_buttons,
		"message" = message,
		"title" = title,
	)

/datum/tgui_input_color/ui_data(mob/user)
	var/list/data = list()
	if(timeout)
		data["timeout"] = CLAMP01((timeout - (world.time - start_time)) / timeout)
	return data

/datum/tgui_input_color/ui_act(action, list/params)
	. = ..()
	if(. || closed)
		return
	switch(action)
		if("submit")
			var/choice = params["entry"]
			if(!istext(choice) || length(choice) != 7 || !GLOB.is_color.Find(choice))
				return
			closed = TRUE
			set_entry(choice)
			SStgui.close_uis(src)
			return TRUE
		if("cancel")
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE

/datum/tgui_input_color/proc/set_entry(entry)
	src.entry = uppertext(entry)

// Асинхронный диалог: callback получает #RRGGBB только при подтверждении.
// При отмене или тайм-ауте callback не вызывается. Функция возвращает датум диалога.
// Аргументы совпадают с синхронной версией; callback идёт перед timeout.
/proc/tgui_input_color_async(mob/user, message = "", title = "Выбор цвета", default = COLOR_WHITE, datum/callback/callback, timeout = 60 SECONDS)
	if(!user)
		user = usr
	if(istype(user, /client))
		var/client/client = user
		user = client.mob
	if(!istype(user) || !user.client)
		return null
	var/datum/tgui_input_color/async/color_input = new(user, message, title, default, callback, timeout)
	if(user.client.prefs.tgui_input_mode)
		color_input.ui_interact(user)
	else
		color_input.prompt_native(user)
	if(!QDELETED(color_input))
		return color_input

/datum/tgui_input_color/async
	var/datum/callback/callback

/datum/tgui_input_color/async/New(mob/user, message, title, default, datum/callback/callback, timeout)
	src.callback = callback
	..(user, message, title, default, timeout)

/datum/tgui_input_color/async/Destroy(force, ...)
	QDEL_NULL(callback)
	return ..()

/datum/tgui_input_color/async/ui_close(mob/user)
	. = ..()
	qdel(src)

/datum/tgui_input_color/async/set_entry(entry)
	. = ..()
	callback?.InvokeAsync(src.entry)

/datum/tgui_input_color/async/wait()
	return

// Нативный диалог не задерживает вызывающий код; тайм-аут запрещает поздний callback.
/datum/tgui_input_color/async/proc/prompt_native(mob/user)
	set waitfor = FALSE
	var/mob/prompt_mob = begin_native_prompt(user)
	var/native_color = input(user, message, title, default) as null|color
	end_native_prompt(prompt_mob)
	if(QDELETED(src))
		return
	if(!isnull(native_color))
		set_entry(uppertext(sanitize_hexcolor(native_color, 6, TRUE, COLOR_WHITE)))
	qdel(src)
