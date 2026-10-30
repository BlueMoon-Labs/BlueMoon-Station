/mob
	/// ПКМ по карте приходит кликом (второе действие), меню действий - на Shift+ПКМ. Иначе ПКМ открывает меню BYOND.
	var/right_click_actions = FALSE
	var/datum/context_menu/active_context_menu
	/// ПКМ сейчас зажат как модификатор: ЛКМ при нём - второе действие, а его отпускание не открывает меню
	var/right_button_chorded = FALSE

/mob/living
	right_click_actions = TRUE

/mob/living/silicon/ai
	right_click_actions = FALSE

/mob/living/simple_animal/revenant
	right_click_actions = FALSE

/client
	/// Подсказка, как переключить режим ПКМ, уже была в этой сессии
	var/context_menu_hint_shown = FALSE
	/// Макросы клавиши Shift, переключающие right-click карты: клавиша -> команда. null - не нужны.
	var/list/right_click_macros

/**
 * right-click карты: true - ПКМ приходит кликом, false - открывает меню BYOND (если show_popup_menus).
 * Когда у ПКМ и Shift+ПКМ разное, его переключают макросы Shift и Shift+UP прямо на клиенте, как у tg и Monkestation:
 * сервер о Shift узнаёт позже, чем игрок успевает щёлкнуть.
 */
/client/proc/update_right_click_mode()
	winset(src, "mapwindow.map", "right-click=[mob?.right_click_map_clicks(FALSE) ? "true" : "false"]")
	var/list/macros = mob?.right_click_shift_macros()
	if(json_encode(macros) != json_encode(right_click_macros))
		right_click_macros = macros
		full_macro_assert()
	refresh_popup_menus()

/client/proc/refresh_popup_menus()
	var/wanted = mob ? mob.popup_menus_wanted(click_intercept) : TRUE
	if(show_popup_menus != wanted)
		show_popup_menus = wanted

/// Меню BYOND на ПКМ только у тех, кто его выбрал (на ПКМ или на Shift+ПКМ), и только вне боя и мехов.
/// В билд-моде ПКМ - его настройки и броски. Какой из жестов открывает меню, решает right-click карты.
/mob/proc/popup_menus_wanted(datum/click_intercept)
	if(istype(click_intercept, /datum/buildmode) || piloting_mecha())
		return FALSE
	if(!right_click_actions)
		return TRUE
	if(right_click_needs_clicks())
		return FALSE
	return right_click_mode() == RIGHT_CLICK_MODE_NATIVE || shift_right_click_mode() == RIGHT_CLICK_MODE_NATIVE

/// Карта шлёт ПКМ (с Shift или без) кликом, а не меню BYOND. Пилот меха - всегда кликом.
/mob/proc/right_click_map_clicks(shift)
	if(piloting_mecha())
		return TRUE
	if(!right_click_actions)
		return FALSE
	return (shift ? shift_right_click_mode() : right_click_mode()) != RIGHT_CLICK_MODE_NATIVE

/// Макросы Shift и Shift+UP для right-click карты, если у ПКМ и Shift+ПКМ он разный
/mob/proc/right_click_shift_macros()
	var/plain = right_click_map_clicks(FALSE)
	var/shifted = right_click_map_clicks(TRUE)
	if(plain == shifted)
		return null
	return list(
		"Shift" = "\".winset :map.right-click=[shifted ? "true" : "false"]\"",
		"Shift+UP" = "\".winset :map.right-click=[plain ? "true" : "false"]\"",
	)

/mob/proc/right_click_needs_clicks()
	return SEND_SIGNAL(src, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE) || piloting_mecha()

/// Пилот меха, пока мех считает его своим: ПКМ у него - модуль меха, в том числе у ИИ
/mob/proc/piloting_mecha()
	var/obj/vehicle/sealed/mecha/mech = loc
	return ismecha(mech) && mech.is_occupant(src)

/// ПКМ открывает меню или делает второе действие - по настройкам игрока, у ПКМ и Shift+ПКМ они свои.
/// В комбат-режиме и в мехе ПКМ всегда действие. Клики, которые повторяет само меню, всегда действие.
/mob/proc/right_click_opens_menu(list/modifiers)
	if(!modifiers["right"] || modifiers["ctrl"] || modifiers["alt"] || modifiers["middle"] || modifiers["context_menu"] || !right_click_actions)
		return FALSE
	// ЛКМ при зажатом ПКМ приходит с right=1 и button=left: это второе действие, как и раньше
	if(modifiers["button"] && modifiers["button"] != "right")
		return FALSE
	return right_click_gesture(modifiers["shift"]) == RIGHT_CLICK_MODE_MENU

/**
 * Что делает ПКМ, дошедший до сервера кликом: RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU
 * или RIGHT_CLICK_MODE_NATIVE - для Shift+ПКМ это осмотр, как раньше в бою.
 * Меню BYOND сервер открыть не может: такой ПКМ кликом приходит только в бою, в мехе или раньше, чем дошёл Shift.
 */
/mob/proc/right_click_gesture(shift)
	var/plain = right_click_mode()
	var/in_combat = right_click_needs_clicks()
	if(!shift)
		return (!in_combat && plain == RIGHT_CLICK_MODE_MENU) ? RIGHT_CLICK_MODE_MENU : RIGHT_CLICK_MODE_ACTION
	var/shifted = shift_right_click_mode()
	// в бою голый ПКМ занят действием, меню остаётся на Shift
	if(in_combat && plain == RIGHT_CLICK_MODE_MENU)
		return RIGHT_CLICK_MODE_MENU
	return shifted

/// Shift+ЛКМ - осмотр. Shift+ПКМ - осмотр, только если на нём меню BYOND, а клик всё же дошёл (в бою, как раньше)
/mob/proc/shift_click_examines(list/modifiers)
	return modifiers["shift"] && (!modifiers["right"] || right_click_gesture(TRUE) == RIGHT_CLICK_MODE_NATIVE)

/// ЛКМ при зажатом ПКМ запоминается; следующий клик самим ПКМ - его отпускание, оно ничего не делает
/mob/proc/swallow_right_button_release(params)
	if(!findtext(params, "right=1"))
		return FALSE
	if(findtext(params, "button=right"))
		if(right_button_chorded)
			right_button_chorded = FALSE
			return TRUE
		return FALSE
	if(findtext(params, "button="))
		right_button_chorded = TRUE
	return FALSE

/// Как нажать второе действие при текущих настройках
/mob/proc/right_click_action_hint()
	if(right_click_gesture(FALSE) == RIGHT_CLICK_MODE_ACTION && (right_click_mode() != RIGHT_CLICK_MODE_NATIVE || right_click_needs_clicks()))
		return "ПКМ"
	if(right_click_gesture(TRUE) == RIGHT_CLICK_MODE_ACTION)
		return "Shift-ПКМ"
	return "ПКМ в бою"

/// Приставка к ПКМ в скринтипе: «Shift-», если второе действие на Shift+ПКМ, «В бою», если вне боя на ПКМ меню BYOND.
/// with_modifier - Ctrl+ПКМ и Alt+ПКМ, меню действий они не открывают, а меню BYOND открывают.
/mob/proc/right_click_screentip_prefix(with_modifier = FALSE)
	if(!right_click_actions)
		return ""
	if(with_modifier)
		return (right_click_mode() == RIGHT_CLICK_MODE_NATIVE && !right_click_needs_clicks()) ? "В бою " : ""
	switch(right_click_action_hint())
		if("Shift-ПКМ")
			return "Shift-"
		if("ПКМ в бою")
			return "В бою "
	return ""

/mob/proc/right_click_mode()
	if(client?.prefs)
		return client.prefs.right_click_mode()
	return CONFIG_GET(number/right_click_mode_default)

/mob/proc/shift_right_click_mode()
	if(client?.prefs)
		return client.prefs.shift_right_click_mode()
	return default_shift_right_click_mode(right_click_mode())

/// ПКМ, дошедший кликом, открывает меню только в режиме меню; в режиме BYOND он доходит лишь в бою, и это действие
/mob/proc/right_click_menu_preferred()
	return right_click_mode() == RIGHT_CLICK_MODE_MENU

/// Выбор игрока, а если он не выбирал - дефолт сервера: смена дефолта в конфиге доходит до всех, кто не переключал сам
/datum/preferences/proc/right_click_mode()
	if(isnull(right_click_choice))
		return CONFIG_GET(number/right_click_mode_default)
	return right_click_choice

/// Shift+ПКМ по выбору игрока, а без выбора - противоположное ПКМ: меню и действие меняются местами, меню BYOND остаётся
/datum/preferences/proc/shift_right_click_mode()
	if(isnull(shift_right_click_choice))
		return default_shift_right_click_mode(right_click_mode())
	return shift_right_click_choice

/proc/default_shift_right_click_mode(plain_mode)
	switch(plain_mode)
		if(RIGHT_CLICK_MODE_MENU)
			return RIGHT_CLICK_MODE_ACTION
		if(RIGHT_CLICK_MODE_ACTION)
			return RIGHT_CLICK_MODE_MENU
	return RIGHT_CLICK_MODE_NATIVE

/datum/preferences/proc/set_right_click_choice(new_mode)
	if(!(new_mode in list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_NATIVE)))
		return FALSE
	right_click_choice = new_mode
	save_pref_var("right_click_choice", "right_click_mode")
	return TRUE

/datum/preferences/proc/set_shift_right_click_choice(new_mode)
	if(!(new_mode in list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_NATIVE)))
		return FALSE
	shift_right_click_choice = new_mode
	save_pref_var("shift_right_click_choice", "shift_right_click_mode")
	return TRUE

/client/proc/set_right_click_mode(new_mode, new_shift_mode)
	if(!prefs?.set_right_click_choice(new_mode))
		return
	if(!isnull(new_shift_mode))
		prefs.set_shift_right_click_choice(new_shift_mode)
	GLOB.context_menu_stats.record_change(src, "раскладку", right_click_mode_name(prefs.right_click_mode(), prefs.shift_right_click_mode()))
	mob?.close_context_menu()
	update_right_click_mode()

/client/proc/set_shift_right_click_mode(new_mode)
	if(!prefs?.set_shift_right_click_choice(new_mode))
		return
	GLOB.context_menu_stats.record_change(src, "раскладку", right_click_mode_name(prefs.right_click_mode(), prefs.shift_right_click_mode()))
	mob?.close_context_menu()
	update_right_click_mode()

/client/verb/toggle_right_click_mode()
	set category = "OOC"
	set name = "Режим ПКМ"
	set desc = "Что делают ПКМ и Shift+ПКМ: меню действий, меню BYOND как раньше или сразу действие"
	choose_right_click_mode()

/// Готовые раскладки: название -> list(ПКМ, Shift+ПКМ). Любую другую пару собирают в настройках игры.
GLOBAL_LIST_INIT(right_click_mode_names, list(
	"ПКМ - меню действий, Shift+ПКМ - действие" = list(RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_ACTION),
	"ПКМ - действие, Shift+ПКМ - меню действий" = list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU),
	"ПКМ - действие, Shift+ПКМ - меню BYOND" = list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_NATIVE),
	"ПКМ - меню BYOND, Shift+ПКМ - меню действий" = list(RIGHT_CLICK_MODE_NATIVE, RIGHT_CLICK_MODE_MENU),
	"ПКМ - меню действий, Shift+ПКМ - меню BYOND" = list(RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_NATIVE),
	"Меню BYOND, как раньше" = list(RIGHT_CLICK_MODE_NATIVE, RIGHT_CLICK_MODE_NATIVE),
))

/proc/right_click_action_name(mode)
	switch(mode)
		if(RIGHT_CLICK_MODE_ACTION)
			return "действие"
		if(RIGHT_CLICK_MODE_MENU)
			return "меню действий"
	return "меню BYOND"

/proc/right_click_mode_name(mode, shift_mode)
	if(isnull(shift_mode))
		shift_mode = default_shift_right_click_mode(mode)
	for(var/mode_name in GLOB.right_click_mode_names)
		var/list/pair = GLOB.right_click_mode_names[mode_name]
		if(pair[1] == mode && pair[2] == shift_mode)
			return mode_name
	return "ПКМ - [right_click_action_name(mode)], Shift+ПКМ - [right_click_action_name(shift_mode)]"

/// Разово, тем, кто режим не выбирал: что теперь делает ПКМ и как вернуть меню BYOND, пока не спросили в OOC
/datum/preferences/proc/show_right_click_notice()
	if(right_click_notice_seen || !parent)
		return
	right_click_notice_seen = TRUE
	save_pref_var("right_click_notice_seen")
	if(!isnull(right_click_choice))
		return
	var/text
	switch(right_click_mode())
		if(RIGHT_CLICK_MODE_MENU)
			text = "ПКМ открывает меню действий у курсора: осмотреть, взять, действия интентов, подсказки с хоткеями, другие объекты на клетке. Shift+ПКМ - второе действие сразу (толкнуть, открыть сумку не снимая, постучать). В комбат-режиме ПКМ - действие."
		if(RIGHT_CLICK_MODE_NATIVE)
			text = "ПКМ открывает меню BYOND, как раньше. Можно включить меню действий у курсора: ПКМ - действия с объектом, Shift+ПКМ - второе действие (толкнуть, открыть сумку не снимая, постучать)."
		else
			text = "ПКМ сразу делает второе действие (толкнуть, открыть сумку не снимая, постучать), меню действий - на Shift+ПКМ."
	to_chat(parent, examine_block(span_notice("<b>Новое на ПКМ.</b> [text]<br>Вернуть меню BYOND, как раньше, или разложить по-своему (например, ПКМ - действие, Shift+ПКМ - меню BYOND) - клик по шапке меню, верб «Режим ПКМ» во вкладке OOC или настройки игры, раздел «Меню ПКМ». Там же шрифт, размер и прозрачность меню.")))

/mob/dead/new_player/Login()
	. = ..()
	if(client?.prefs && !client.prefs.right_click_notice_seen)
		addtimer(CALLBACK(client.prefs, TYPE_PROC_REF(/datum/preferences, show_right_click_notice)), 7 SECONDS)

/client/proc/choose_right_click_mode()
	if(!prefs)
		return
	var/list/options = GLOB.right_click_mode_names.Copy()
	options += CONTEXT_MENU_SETTINGS_CHOICE
	var/current = right_click_mode_name(prefs.right_click_mode(), prefs.shift_right_click_mode())
	var/choice = tgui_input_list(mob, "Действие - второе действие сразу (толкнуть, открыть сумку не снимая, постучать). Меню действий - меню у курсора. Меню BYOND - как раньше. В комбат-режиме и в мехе ПКМ всегда действие. Сейчас: [current].", "Режим ПКМ", options, (current in options) ? current : null)
	if(!choice || QDELETED(src))
		return
	if(choice == CONTEXT_MENU_SETTINGS_CHOICE)
		prefs.ui_interact(mob)
		return
	var/list/pair = GLOB.right_click_mode_names[choice]
	if(!pair)
		return
	set_right_click_mode(pair[1], pair[2])
	to_chat(src, span_notice("[right_click_mode_name(prefs.right_click_mode(), prefs.shift_right_click_mode())]. В комбат-режиме и в мехе ПКМ всё равно действует. Шрифт, размер и прозрачность меню - в настройках игры, раздел «Меню ПКМ»."))

/mob/proc/open_context_menu(atom/target, params)
	close_context_menu()
	if(QDELETED(target) || !right_click_actions)
		return
	// клик по клетке, которую игрок не видит (за стеной, в темноте, вне обзора), click_catcher передаёт турфу с catcher=1:
	// меню BYOND там ничего не показывало, и это не должно, иначе список клетки - рентген
	if(params2list(params)["catcher"])
		return
	active_context_menu = new /datum/context_menu(src, target, params)
	GLOB.context_menu_stats.record_open(src, params2list(params))
	// кто выбрал меню сам, знает, как его сменить
	if(client && !client.context_menu_hint_shown && right_click_menu_preferred() && isnull(client.prefs?.right_click_choice))
		client.context_menu_hint_shown = TRUE
		to_chat(src, span_notice("Это меню действий. Чтобы ПКМ сразу действовал или открывал меню BYOND, как раньше, щёлкните по заголовку меню, вербу «Режим ПКМ» во вкладке OOC или выберите в настройках игры. Там же шрифт, размер и прозрачность меню."))
	return active_context_menu

/mob/proc/close_context_menu()
	if(active_context_menu)
		qdel(active_context_menu)

/**
 * Меню действий у курсора.
 *
 * Пункты - обычные клики с модификаторами и интентом, вербы и колбэки.
 * Открывается сразу по объекту под курсором, остальные объекты клетки - пунктом «Другие на клетке».
 * По полу с вещами сперва список клетки.
 */
/datum/context_menu
	var/mob/user
	/// Атом, чьи действия показаны. null - список объектов клетки.
	var/atom/target
	/// Клетка клика, если на ней есть из чего выбирать
	var/turf/tile
	/// Игрок уже видел список клетки: из действий объекта к нему ведёт «Назад»
	var/tile_list_shown = FALSE
	/// Шапка вместо имени цели, например у списка одинаковых объектов
	var/header_text
	/// Разовые действия другими интентами, их показывает «Интенты…»
	var/list/datum/context_menu_entry/intent_entries = list()
	/// Шапка текущей отрисовки: по клику выбор режима ПКМ
	var/datum/context_menu_entry/mode_choice/header_entry
	/// Атом, по которому кликнули на самом деле: ему достаются icon-x/icon-y клика
	var/atom/clicked
	/// icon-x, icon-y и screen-loc исходного клика
	var/list/click_position
	var/list/datum/context_menu_entry/entries = list()
	var/page = 1
	/// «Ещё…» текущей страницы: его нет в entries, он собирается заново при каждой отрисовке
	var/datum/context_menu_entry/page/page_entry
	/// Левый верхний угол меню в пикселях от левого нижнего угла вьюпорта
	var/origin_x = 0
	var/origin_y = 0
	/// Ширина и левый край последней отрисовки
	var/width = CONTEXT_MENU_WIDTH
	var/left = 0
	var/list/atom/movable/screen/context_menu/screen_objects = list()
	/// Вид последней отрисовки по настройкам игрока: размер (1 = 100%), шрифт, непрозрачность строк, значки, зум карты, тема и прочее
	var/scale = 1
	var/smooth_font = TRUE
	var/row_alpha = 235
	var/show_icons = TRUE
	var/text_zoom = CONTEXT_MENU_DEFAULT_ZOOM
	var/font_id = "calibri"
	/// Цвета темы, GLOB.context_menu_themes
	var/list/theme
	var/density_padding = 0
	var/animation = "fade"
	var/hints_mode = "hover"
	var/position = "right"
	var/show_border = FALSE
	var/show_header = TRUE
	var/smooth_hover = TRUE
	/// Рисовать браузером (чёткий текст), а не maptext на карте
	var/use_html = TRUE
	/// Множитель длительности анимаций
	var/animation_speed = 1
	var/show_stripe = FALSE
	var/show_shadow = FALSE
	/// Щель между строками в пикселях
	var/row_gap = 0
	var/caps = FALSE
	var/text_outline = FALSE
	/// Пунктов действий на странице
	var/page_rows = CONTEXT_MENU_MAX_ROWS
	/// Цвет полоски: свой или темы
	var/accent
	/// Опасный пункт ждёт второго клика (confirm_danger)
	var/datum/context_menu_entry/confirm_entry
	var/confirm_danger = FALSE
	/// Когда закрываться на ходу: far, always, never
	var/close_on_move = "far"
	/// Отступ меню от курсора в пикселях карты
	var/cursor_offset = 4
	/// Звук открытия и выбора, ключ GLOB.context_menu_sounds
	var/menu_sound = "off"
	/// Пункт выбран и меню закрылось по делу; иначе закрытие считается брошенным меню в статистике
	var/chosen = FALSE
	/// Анимация открытия уже была; листание её не повторяет
	var/opened = FALSE
	/// Объекты экрана по строкам, шапка первой: строка появляется целиком
	var/list/row_groups = list()
	/// Хоткей строки под курсором - плашкой сбоку меню
	var/list/atom/movable/screen/hint_objects = list()
	var/atom/movable/screen/context_menu/hint_row

/datum/context_menu/New(mob/user, atom/target, params)
	src.user = user
	clicked = target
	var/list/modifiers = params2list(params)
	click_position = list()
	for(var/key in list("icon-x", "icon-y", "screen-loc"))
		if(modifiers[key])
			click_position[key] = modifiers[key]
	set_origin(modifiers["screen-loc"])
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_user_moved))
	RegisterSignal(user, list(COMSIG_MOB_DEATH, COMSIG_MOB_LOGOUT), PROC_REF(on_user_lost))
	RegisterSignal(user, COMSIG_MOB_KEYDOWN, PROC_REF(on_key_down))
	// гладкий шрифт рисуется под зум карты; окно могли растянуть с прошлого раза
	if(user.client && user.client.prefs?.context_menu_option("font") != "pixel")
		INVOKE_ASYNC(user.client, TYPE_PROC_REF(/client, refresh_context_menu_zoom))

	var/turf/target_turf = isturf(target) ? target : (isturf(target.loc) ? target.loc : null)
	if(target_turf && target != user)
		var/list/candidates = get_tile_candidates(target_turf)
		// по полу и по предмету в большой куче нужен именно список: вещь ищут в нём, а не в действиях верхней
		if((isturf(target) && length(candidates)) || (isitem(target) && length(candidates) >= CONTEXT_MENU_PILE_MIN))
			tile = target_turf
			show_tile()
			return
		if(!isturf(target) && length(candidates) > 1)
			tile = target_turf
	show_target(target)

/datum/context_menu/Destroy()
	if(user && !chosen)
		GLOB.context_menu_stats.record_abandon(user)
	if(user)
		if(user.active_context_menu == src)
			user.active_context_menu = null
		user.client?.screen -= screen_objects
	hide_hint()
	hide_html()
	QDEL_LIST(screen_objects)
	user = null
	target = null
	tile = null
	clicked = null
	entries = null
	page_entry = null
	intent_entries = null
	header_entry = null
	confirm_entry = null
	row_groups = null
	html_rows = null
	theme = null
	return ..()

/// Объекты клетки, из которых игрок выбирает: верхние первыми, мобы раньше вещей
/datum/context_menu/proc/get_tile_candidates(turf/T)
	var/list/candidates = list()
	for(var/atom/movable/thing as anything in T)
		if(thing == user || thing.mouse_opacity == MOUSE_OPACITY_TRANSPARENT || thing.invisibility > user.see_invisible || !thing.name)
			continue
		candidates += thing
	return sort_list(candidates, GLOBAL_PROC_REF(cmp_context_menu_order))

/// Список клетки; одинаковые объекты (тип и имя) от CONTEXT_MENU_GROUP_MIN штук - одной строкой со счётом
/datum/context_menu/proc/show_tile()
	set_target(null)
	tile_list_shown = TRUE
	header_text = null
	entries = list()
	var/list/same_things = list()
	var/list/candidates = get_tile_candidates(tile)
	// вещь, по которой щёлкнули, - первой строкой: в куче её не надо искать
	if(clicked in candidates)
		candidates -= clicked
		candidates.Insert(1, clicked)
	for(var/atom/movable/thing as anything in candidates)
		var/key = "[thing.type]|[thing.name]"
		if(!same_things[key])
			same_things[key] = list()
		same_things[key] += thing
	for(var/key in same_things)
		var/list/atom/movable/things = same_things[key]
		var/atom/movable/first = things[1]
		if(length(things) >= CONTEXT_MENU_GROUP_MIN)
			entries += new /datum/context_menu_entry/pick_group("[context_menu_name(first.name)] ([length(things)])", null, CONTEXT_ENTRY_NORMAL, things)
			continue
		for(var/atom/movable/thing as anything in things)
			entries += new /datum/context_menu_entry/pick(context_menu_name(thing.name), pick_hint(thing), CONTEXT_ENTRY_NORMAL, thing)
	entries += new /datum/context_menu_entry/pick(context_menu_name(tile.name), pick_hint(tile), CONTEXT_ENTRY_NORMAL, tile)
	page = 1
	render()

/datum/context_menu/proc/show_group(datum/context_menu_entry/pick_group/group)
	set_target(null)
	header_text = group.name
	entries = list(new /datum/context_menu_entry/pick("Назад", null, CONTEXT_ENTRY_SERVICE, null))
	for(var/datum/weakref/ref as anything in group.refs)
		var/atom/movable/thing = ref.resolve()
		if(thing?.loc == tile)
			entries += new /datum/context_menu_entry/pick(context_menu_name(thing.name), pick_hint(thing), CONTEXT_ENTRY_NORMAL, thing)
	page = 1
	render()

/datum/context_menu/proc/show_admin_verbs()
	header_text = "Админ: [context_menu_name(target.name)]"
	entries = list(new /datum/context_menu_entry/back("Назад", null, CONTEXT_ENTRY_SERVICE))
	for(var/procpath/verb_path as anything in context_menu_admin_verbs_for(target, user.client?.verbs))
		entries += new /datum/context_menu_entry/admin_verb(verb_path.name, null, CONTEXT_ENTRY_NORMAL, verb_path)
	page = 1
	render()

/datum/context_menu/proc/show_target(atom/new_target)
	set_target(new_target)
	header_text = null
	entries = build_entries(new_target)
	page = 1
	render()

/datum/context_menu/proc/set_target(atom/new_target)
	if(target)
		UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	target = new_target
	if(target)
		RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))

/datum/context_menu/proc/choose(datum/context_menu_entry/entry)
	if(!(entry in entries) && entry != page_entry && entry != header_entry)
		return
	GLOB.context_menu_stats.record_choice(user, context_menu_entry_kind(entry), entry.name)
	if(istype(entry, /datum/context_menu_entry/mode_choice))
		var/client/chooser_client = user.client
		chosen = TRUE
		qdel(src)
		if(chooser_client)
			INVOKE_ASYNC(chooser_client, TYPE_PROC_REF(/client, choose_right_click_mode))
		return
	if(istype(entry, /datum/context_menu_entry/intent_list))
		header_text = "Интенты: [context_menu_name(target.name)]"
		entries = list(new /datum/context_menu_entry/back("Назад", null, CONTEXT_ENTRY_SERVICE)) + intent_entries
		page = 1
		render()
		return
	if(istype(entry, /datum/context_menu_entry/pick_group))
		show_group(entry)
		return
	if(istype(entry, /datum/context_menu_entry/admin_list))
		show_admin_verbs()
		return
	if(istype(entry, /datum/context_menu_entry/back))
		show_target(target)
		return
	if(istype(entry, /datum/context_menu_entry/pick))
		var/datum/context_menu_entry/pick/pick_entry = entry
		var/atom/picked = pick_entry.picked_ref?.resolve()
		if(picked && (picked == tile || picked.loc == tile))
			show_target(picked)
		else
			show_tile()
		return
	if(istype(entry, /datum/context_menu_entry/page))
		page = page % page_count() + 1
		render()
		return
	// опасное действие по настройке - со второго клика: первый только переспрашивает
	if(confirm_danger && entry.style == CONTEXT_ENTRY_DANGER && confirm_entry != entry)
		confirm_entry = entry
		render()
		return
	play_menu_sound()
	var/mob/chooser = user
	var/atom/chosen_target = target
	chosen = TRUE
	qdel(src)
	if(QDELETED(chooser) || QDELETED(chosen_target))
		return
	entry.execute(chooser, chosen_target)

/// Ctrl, Shift или Alt по строке объекта из списка - тот же клик по самому объекту, без захода в его действия.
/// Осмотр оставляет список открытым: в куче осматривают подряд.
/datum/context_menu/proc/click_picked(datum/context_menu_entry/pick/entry, list/modifiers)
	if(!(entry in entries) || !(modifiers["ctrl"] || modifiers["shift"] || modifiers["alt"]))
		return FALSE
	var/atom/picked = entry.picked_ref?.resolve()
	if(!picked || (picked != tile && picked.loc != tile))
		return FALSE
	var/mob/chooser = user
	GLOB.context_menu_stats.record_choice(user, "pick_[modifiers["ctrl"] ? "ctrl" : (modifiers["alt"] ? "alt" : "shift")]", null)
	if(modifiers["shift"] && !modifiers["ctrl"] && !modifiers["alt"] && !modifiers["middle"] && !modifiers["right"])
		chooser.ShiftClickOn(picked)
		return TRUE
	var/list/click_modifiers = list("context_menu" = 1)
	for(var/key in list("ctrl", "shift", "alt", "middle", "right", "left"))
		if(modifiers[key])
			click_modifiers[key] = modifiers[key]
	chosen = TRUE
	qdel(src)
	INVOKE_ASYNC(chooser, TYPE_PROC_REF(/mob, CommonClickOn), picked, list2params(click_modifiers))
	return TRUE

/// Подсказка строки объекта: что сделают клики с модификаторами прямо по ней
/datum/context_menu/proc/pick_hint(atom/thing)
	if(ismovable(thing))
		var/atom/movable/movable = thing
		if(!movable.anchored)
			return "Ctrl - потянуть, Shift - осмотреть"
	return "Shift - осмотреть"

/// Колесо над меню листает страницы: вниз - дальше
/datum/context_menu/proc/scroll(delta)
	var/pages = page_count()
	if(pages == 1 || !delta)
		return
	page = delta < 0 ? page % pages + 1 : (page + pages - 2) % pages + 1
	render()

/// Список объектов листают в поисках вещи, его страницы длиннее, чем у действий
/datum/context_menu/proc/rows_per_page()
	return target ? page_rows : CONTEXT_MENU_MAX_LIST_ROWS

/// Пункты, которые есть на каждой странице: «Админ…» не должен уезжать на вторую страницу за действиями
/datum/context_menu/proc/pinned_entries()
	. = list()
	// «Админ…» вверху и так на первой странице
	if(context_menu_style_option(user?.context_menu_prefs()?.context_menu_style, "admin_pos") == "top")
		return
	for(var/datum/context_menu_entry/admin_list/admin_entry in entries)
		. += admin_entry

/datum/context_menu/proc/page_count()
	var/pinned = length(pinned_entries())
	var/paged = length(entries) - pinned
	var/per_page = rows_per_page() - pinned
	if(paged <= per_page)
		return 1
	return CEILING(paged / (per_page - 1), 1)

/// Пункты текущей страницы, с закреплёнными и «Ещё…» в конце, если страниц несколько
/datum/context_menu/proc/visible_entries()
	var/list/pinned = pinned_entries()
	var/list/paged = entries - pinned
	if(page_count() == 1)
		page_entry = null
		return paged + pinned
	var/per_page = rows_per_page() - length(pinned) - 1
	var/first = (page - 1) * per_page + 1
	. = paged.Copy(first, min(first + per_page, length(paged) + 1))
	. += pinned
	page_entry = new /datum/context_menu_entry/page("Ещё… ([page]/[page_count()])", "или колесо мыши", CONTEXT_ENTRY_SERVICE)
	. += page_entry

/// На ходу меню остаётся, пока его объект рядом и на том же уровне
/datum/context_menu/proc/on_user_moved(datum/source)
	SIGNAL_HANDLER
	if(close_on_move == "always")
		qdel(src)
		return
	var/turf/anchor = get_turf(target || tile)
	var/turf/user_turf = get_turf(user)
	if(!anchor || !user_turf || anchor.z != user_turf.z)
		qdel(src)
		return
	if(close_on_move == "far" && get_dist(user_turf, anchor) > CONTEXT_MENU_MAX_DISTANCE)
		qdel(src)

/datum/context_menu/proc/play_menu_sound()
	var/sound_file = GLOB.context_menu_sounds[menu_sound]
	if(sound_file && user?.client)
		user.playsound_local(get_turf(user), sound_file, 25, FALSE)

/// Имя пункта на экране: переспрошенный опасный - с вопросом
/datum/context_menu/proc/entry_display_name(datum/context_menu_entry/entry)
	return entry == confirm_entry ? "Точно? [entry.name]" : entry.name

/datum/context_menu/proc/on_user_lost(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/context_menu/proc/on_target_deleted(datum/source)
	SIGNAL_HANDLER
	if(tile && source != tile)
		show_tile()
		return
	qdel(src)

/datum/context_menu/proc/on_key_down(datum/source, key, client/user_client, full_key)
	SIGNAL_HANDLER
	if(key == "Escape")
		qdel(src)

/// Имя объекта для строки меню: без \proper и \improper (capitalize иначе ломает первую букву) и с заглавной
/proc/context_menu_name(name)
	return capitalize(replacetext(replacetext(format_text(name), "\proper", ""), "\improper", ""))

/proc/cmp_context_menu_order(atom/movable/a, atom/movable/b)
	var/a_mob = ismob(a)
	var/b_mob = ismob(b)
	if(a_mob != b_mob)
		return b_mob - a_mob
	if(a.plane != b.plane)
		return b.plane - a.plane
	return b.layer - a.layer
