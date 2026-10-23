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

/client/proc/update_right_click_mode()
	winset(src, "mapwindow.map", "right-click=[mob?.right_click_actions ? "true" : "false"]")

/// ПКМ открывает меню или делает второе действие - по настройке игрока; Shift меняет одно на другое.
/// В комбат-режиме ПКМ всегда действие. Клики, которые повторяет само меню, всегда действие.
/mob/proc/right_click_opens_menu(list/modifiers)
	if(!modifiers["right"] || modifiers["ctrl"] || modifiers["alt"] || modifiers["middle"] || modifiers["context_menu"] || !right_click_actions)
		return FALSE
	// ЛКМ при зажатом ПКМ приходит с right=1 и button=left: это второе действие, как и раньше
	if(modifiers["button"] && modifiers["button"] != "right")
		return FALSE
	var/menu_on_plain_click = right_click_menu_preferred()
	if(menu_on_plain_click && SEND_SIGNAL(src, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE))
		menu_on_plain_click = FALSE
	return modifiers["shift"] ? !menu_on_plain_click : menu_on_plain_click

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
	return right_click_opens_menu(list("right" = 1)) ? "Shift-ПКМ" : "ПКМ"

/mob/proc/right_click_menu_preferred()
	return client?.prefs ? client.prefs.right_click_menu_enabled() : CONFIG_GET(flag/right_click_menu_default)

/// Выбор игрока, а если он не выбирал - дефолт сервера: смена дефолта в конфиге доходит до всех, кто не переключал сам
/datum/preferences/proc/right_click_menu_enabled()
	return isnull(right_click_menu) ? CONFIG_GET(flag/right_click_menu_default) : right_click_menu

/client/verb/toggle_right_click_mode()
	set category = "OOC"
	set name = "Режим ПКМ"
	set desc = "Что делает ПКМ: открывает меню действий или сразу действует"
	if(!prefs)
		return
	prefs.right_click_menu = !prefs.right_click_menu_enabled()
	prefs.save_pref_var("right_click_menu")
	if(prefs.right_click_menu)
		to_chat(src, span_notice("ПКМ открывает меню действий, Shift+ПКМ - второе действие (в комбат-режиме ПКМ всё равно действует)."))
	else
		to_chat(src, span_notice("ПКМ сразу действует, меню действий - на Shift+ПКМ."))

/mob/proc/open_context_menu(atom/target, params)
	close_context_menu()
	if(QDELETED(target) || !right_click_actions)
		return
	active_context_menu = new /datum/context_menu(src, target, params)
	if(client && !client.context_menu_hint_shown && right_click_menu_preferred())
		client.context_menu_hint_shown = TRUE
		to_chat(src, span_notice("Это меню действий. Чтобы ПКМ сразу действовал, а меню открывалось на Shift+ПКМ, переключите «Режим ПКМ» во вкладке OOC или в настройках игры."))
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
	/// Ширина последней отрисовки
	var/width = CONTEXT_MENU_WIDTH
	var/list/atom/movable/screen/context_menu/screen_objects = list()

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
	QDEL_LIST(screen_objects)
	user = null
	target = null
	tile = null
	clicked = null
	entries = null
	page_entry = null
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
	if(!(entry in entries) && entry != page_entry)
		return
	if(istype(entry, /datum/context_menu_entry/pick_group))
		show_group(entry)
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
