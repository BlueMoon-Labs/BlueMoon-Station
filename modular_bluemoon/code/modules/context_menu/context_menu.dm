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

/// В режиме «меню BYOND» ПКМ кликом приходит только через show_popup_menus, поэтому карта тогда без right-click
/client/proc/update_right_click_mode()
	var/map_clicks = mob?.piloting_mecha() || (mob?.right_click_actions && prefs?.right_click_mode() != RIGHT_CLICK_MODE_NATIVE)
	winset(src, "mapwindow.map", "right-click=[map_clicks ? "true" : "false"]")
	refresh_popup_menus()

/// Меню BYOND на ПКМ только у тех, кто его выбрал, и только вне боя и мехов
/client/proc/refresh_popup_menus()
	if(mob?.piloting_mecha())
		show_popup_menus = FALSE
		return
	show_popup_menus = !mob?.right_click_actions || (prefs?.right_click_mode() == RIGHT_CLICK_MODE_NATIVE && !mob.right_click_needs_clicks())

/mob/proc/right_click_needs_clicks()
	return SEND_SIGNAL(src, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE) || piloting_mecha()

/// Пилот меха, пока мех считает его своим: ПКМ у него - модуль меха, в том числе у ИИ
/mob/proc/piloting_mecha()
	var/obj/vehicle/sealed/mecha/mech = loc
	return ismecha(mech) && mech.is_occupant(src)

/// ПКМ открывает меню или делает второе действие - по настройке игрока; Shift меняет одно на другое.
/// В комбат-режиме и в мехе ПКМ всегда действие. Клики, которые повторяет само меню, всегда действие.
/// В режиме «меню BYOND» меню действий нет вовсе, всё как раньше.
/mob/proc/right_click_opens_menu(list/modifiers)
	if(!modifiers["right"] || modifiers["ctrl"] || modifiers["alt"] || modifiers["middle"] || modifiers["context_menu"] || !right_click_actions)
		return FALSE
	// ЛКМ при зажатом ПКМ приходит с right=1 и button=left: это второе действие, как и раньше
	if(modifiers["button"] && modifiers["button"] != "right")
		return FALSE
	if(right_click_mode() == RIGHT_CLICK_MODE_NATIVE)
		return FALSE
	var/menu_on_plain_click = right_click_menu_preferred()
	if(menu_on_plain_click && right_click_needs_clicks())
		menu_on_plain_click = FALSE
	return modifiers["shift"] ? !menu_on_plain_click : menu_on_plain_click

/// Shift+ЛКМ - осмотр. Shift+ПКМ - осмотр только в режиме «меню BYOND», как раньше в бою; в остальных режимах это меню или второе действие.
/mob/proc/shift_click_examines(list/modifiers)
	return modifiers["shift"] && (!modifiers["right"] || right_click_mode() == RIGHT_CLICK_MODE_NATIVE)

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

/// Как нажать второе действие при текущих настройках и режиме
/mob/proc/right_click_action_hint()
	if(right_click_mode() == RIGHT_CLICK_MODE_NATIVE && !right_click_needs_clicks())
		return "ПКМ в бою"
	return right_click_opens_menu(list("right" = 1)) ? "Shift-ПКМ" : "ПКМ"

/// Приставка к ПКМ в скринтипе: в режиме меню второе действие на Shift+ПКМ, в режиме BYOND вне боя ПКМ - меню BYOND.
/// with_modifier - Ctrl+ПКМ и Alt+ПКМ, меню они не открывают.
/mob/proc/right_click_screentip_prefix(with_modifier = FALSE)
	if(!right_click_actions)
		return ""
	if(right_click_mode() == RIGHT_CLICK_MODE_NATIVE && !right_click_needs_clicks())
		return "В бою "
	if(!with_modifier && right_click_opens_menu(list("right" = 1)))
		return "Shift-"
	return ""

/mob/proc/right_click_mode()
	if(client?.prefs)
		return client.prefs.right_click_mode()
	return CONFIG_GET(number/right_click_mode_default)

/// ПКМ, дошедший кликом, открывает меню только в режиме меню; в режиме BYOND он доходит лишь в бою, и это действие
/mob/proc/right_click_menu_preferred()
	return right_click_mode() == RIGHT_CLICK_MODE_MENU

/// Выбор игрока, а если он не выбирал - дефолт сервера: смена дефолта в конфиге доходит до всех, кто не переключал сам
/datum/preferences/proc/right_click_mode()
	if(isnull(right_click_choice))
		return CONFIG_GET(number/right_click_mode_default)
	return right_click_choice

/datum/preferences/proc/set_right_click_choice(new_mode)
	if(!(new_mode in list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_NATIVE)))
		return FALSE
	right_click_choice = new_mode
	save_pref_var("right_click_choice", "right_click_mode")
	return TRUE

/client/proc/set_right_click_mode(new_mode)
	if(!prefs?.set_right_click_choice(new_mode))
		return
	log_game("[key_name(src)] выбрал режим ПКМ: [right_click_mode_name(new_mode)]")
	mob?.close_context_menu()
	update_right_click_mode()

/client/verb/toggle_right_click_mode()
	set category = "OOC"
	set name = "Режим ПКМ"
	set desc = "Меню действий, меню BYOND как раньше или сразу действие"
	choose_right_click_mode()

GLOBAL_LIST_INIT(right_click_mode_names, list(
	"Меню действий" = RIGHT_CLICK_MODE_MENU,
	"Меню BYOND, как раньше" = RIGHT_CLICK_MODE_NATIVE,
	"Сразу действие" = RIGHT_CLICK_MODE_ACTION,
))

/proc/right_click_mode_name(mode)
	for(var/mode_name in GLOB.right_click_mode_names)
		if(GLOB.right_click_mode_names[mode_name] == mode)
			return mode_name

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
	to_chat(parent, examine_block(span_notice("<b>Новое на ПКМ.</b> [text]<br>Вернуть меню BYOND, как раньше, или выбрать другой режим - клик по шапке меню, верб «Режим ПКМ» во вкладке OOC или настройки игры, раздел «ПКМ».")))

/mob/dead/new_player/Login()
	. = ..()
	if(client?.prefs && !client.prefs.right_click_notice_seen)
		addtimer(CALLBACK(client.prefs, TYPE_PROC_REF(/datum/preferences, show_right_click_notice)), 7 SECONDS)

/client/proc/choose_right_click_mode()
	if(!prefs)
		return
	var/choice = tgui_input_list(mob, "Меню действий: ПКМ - меню у курсора, Shift+ПКМ - второе действие. Меню BYOND: как раньше, вне боя ПКМ открывает меню BYOND. Сразу действие: ПКМ действует, меню на Shift+ПКМ. В комбат-режиме и в мехе ПКМ всегда действие.", "Режим ПКМ", GLOB.right_click_mode_names, right_click_mode_name(prefs.right_click_mode()))
	if(!choice || QDELETED(src) || isnull(GLOB.right_click_mode_names[choice]))
		return
	set_right_click_mode(GLOB.right_click_mode_names[choice])
	switch(prefs.right_click_mode())
		if(RIGHT_CLICK_MODE_ACTION)
			to_chat(src, span_notice("ПКМ сразу действует, меню действий - на Shift+ПКМ."))
		if(RIGHT_CLICK_MODE_NATIVE)
			to_chat(src, span_notice("ПКМ открывает меню BYOND, как раньше; в комбат-режиме и в мехе ПКМ действует, Shift+ПКМ осматривает."))
		else
			to_chat(src, span_notice("ПКМ открывает меню действий, Shift+ПКМ - второе действие (в комбат-режиме и в мехе ПКМ всё равно действует)."))

/mob/proc/open_context_menu(atom/target, params)
	close_context_menu()
	if(QDELETED(target) || !right_click_actions)
		return
	active_context_menu = new /datum/context_menu(src, target, params)
	// кто выбрал меню сам, знает, как его сменить
	if(client && !client.context_menu_hint_shown && right_click_menu_preferred() && isnull(client.prefs?.right_click_choice))
		client.context_menu_hint_shown = TRUE
		to_chat(src, span_notice("Это меню действий. Чтобы ПКМ сразу действовал или открывал меню BYOND, как раньше, щёлкните по заголовку меню, вербу «Режим ПКМ» во вкладке OOC или выберите в настройках игры."))
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

	var/turf/target_turf = isturf(target) ? target : (isturf(target.loc) ? target.loc : null)
	if(target_turf && target != user)
		var/list/candidates = get_tile_candidates(target_turf)
		if(isturf(target) && length(candidates))
			tile = target_turf
			show_tile()
			return
		if(!isturf(target) && length(candidates) > 1)
			tile = target_turf
	show_target(target)

/datum/context_menu/Destroy()
	if(user)
		if(user.active_context_menu == src)
			user.active_context_menu = null
		user.client?.screen -= screen_objects
	hide_hint()
	QDEL_LIST(screen_objects)
	user = null
	target = null
	tile = null
	clicked = null
	entries = null
	page_entry = null
	intent_entries = null
	header_entry = null
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
	for(var/atom/movable/thing as anything in get_tile_candidates(tile))
		var/key = "[thing.type]|[thing.name]"
		if(!same_things[key])
			same_things[key] = list()
		same_things[key] += thing
	for(var/key in same_things)
		var/list/atom/movable/things = same_things[key]
		var/atom/movable/first = things[1]
		if(length(things) >= CONTEXT_MENU_GROUP_MIN)
			entries += new /datum/context_menu_entry/pick_group("[capitalize(first.name)] ([length(things)])", null, CONTEXT_ENTRY_NORMAL, things)
			continue
		for(var/atom/movable/thing as anything in things)
			entries += new /datum/context_menu_entry/pick(capitalize(thing.name), null, CONTEXT_ENTRY_NORMAL, thing)
	entries += new /datum/context_menu_entry/pick(capitalize(tile.name), null, CONTEXT_ENTRY_NORMAL, tile)
	page = 1
	render()

/datum/context_menu/proc/show_group(datum/context_menu_entry/pick_group/group)
	set_target(null)
	header_text = group.name
	entries = list(new /datum/context_menu_entry/pick("Назад", null, CONTEXT_ENTRY_SERVICE, null))
	for(var/datum/weakref/ref as anything in group.refs)
		var/atom/movable/thing = ref.resolve()
		if(thing?.loc == tile)
			entries += new /datum/context_menu_entry/pick(capitalize(thing.name), null, CONTEXT_ENTRY_NORMAL, thing)
	page = 1
	render()

/datum/context_menu/proc/show_admin_verbs()
	header_text = "Админ: [target.name]"
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
	if(istype(entry, /datum/context_menu_entry/mode_choice))
		var/client/chooser_client = user.client
		qdel(src)
		if(chooser_client)
			INVOKE_ASYNC(chooser_client, TYPE_PROC_REF(/client, choose_right_click_mode))
		return
	if(istype(entry, /datum/context_menu_entry/intent_list))
		header_text = "Интенты: [target.name]"
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
	var/mob/chooser = user
	var/atom/chosen_target = target
	qdel(src)
	if(QDELETED(chooser) || QDELETED(chosen_target))
		return
	entry.execute(chooser, chosen_target)

/datum/context_menu/proc/page_count()
	if(length(entries) <= CONTEXT_MENU_MAX_ROWS)
		return 1
	return CEILING(length(entries) / (CONTEXT_MENU_MAX_ROWS - 1), 1)

/// Пункты текущей страницы, с «Ещё…» в конце, если страниц несколько
/datum/context_menu/proc/visible_entries()
	if(page_count() == 1)
		page_entry = null
		return entries.Copy()
	var/per_page = CONTEXT_MENU_MAX_ROWS - 1
	var/first = (page - 1) * per_page + 1
	. = entries.Copy(first, min(first + per_page, length(entries) + 1))
	page_entry = new /datum/context_menu_entry/page("Ещё… ([page]/[page_count()])", null, CONTEXT_ENTRY_SERVICE)
	. += page_entry

/// На ходу меню остаётся, пока его объект рядом и на том же уровне
/datum/context_menu/proc/on_user_moved(datum/source)
	SIGNAL_HANDLER
	var/turf/anchor = get_turf(target || tile)
	var/turf/user_turf = get_turf(user)
	if(!anchor || !user_turf || anchor.z != user_turf.z || get_dist(user_turf, anchor) > CONTEXT_MENU_MAX_DISTANCE)
		qdel(src)

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

/proc/cmp_context_menu_order(atom/movable/a, atom/movable/b)
	var/a_mob = ismob(a)
	var/b_mob = ismob(b)
	if(a_mob != b_mob)
		return b_mob - a_mob
	if(a.plane != b.plane)
		return b.plane - a.plane
	return b.layer - a.layer
