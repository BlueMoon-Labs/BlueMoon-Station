/// Ключ скринтипа -> модификаторы клика и подпись хоткея в меню
GLOBAL_LIST_INIT(context_menu_screentip_keys, list(
	SCREENTIP_CONTEXT_LMB = list("left=1", "ЛКМ"),
	SCREENTIP_CONTEXT_RMB = list("right=1", "ПКМ"),
	SCREENTIP_CONTEXT_SHIFT_LMB = list("shift=1;left=1", "Shift-ЛКМ"),
	SCREENTIP_CONTEXT_CTRL_LMB = list("ctrl=1;left=1", "Ctrl-ЛКМ"),
	SCREENTIP_CONTEXT_CTRL_RMB = list("ctrl=1;right=1", "Ctrl-ПКМ"),
	SCREENTIP_CONTEXT_ALT_LMB = list("alt=1;left=1", "Alt-ЛКМ"),
	SCREENTIP_CONTEXT_ALT_RMB = list("alt=1;right=1", "Alt-ПКМ"),
	SCREENTIP_CONTEXT_CTRL_SHIFT_LMB = list("ctrl=1;shift=1;left=1", "Ctrl-Shift-ЛКМ"),
))

GLOBAL_LIST_INIT(context_menu_intent_names, list(
	INTENT_HELP = "Помочь",
	INTENT_DISARM = "Обезоружить",
	INTENT_GRAB = "Схватить",
	INTENT_HARM = "Ударить",
))

GLOBAL_LIST_INIT(context_menu_intent_short, list(
	INTENT_HELP = "помощь",
	INTENT_DISARM = "дизарм",
	INTENT_GRAB = "захват",
	INTENT_HARM = "вред",
))

/datum/context_menu/proc/build_entries(atom/A)
	var/list/result = list()
	/// "модификаторы|интент" уже показанных кликов
	var/list/shown_clicks = list()
	if(tile)
		result += new /datum/context_menu_entry/pick("Назад", null, CONTEXT_ENTRY_SERVICE, null)
	add_basic_entries(A, result, shown_clicks)
	// подписи скринтипа точнее общих названий интентов, поэтому собираются раньше них
	var/list/main_clicks = list()
	var/list/other_clicks = list()
	add_screentip_entries(A, main_clicks, other_clicks, shown_clicks)
	add_intent_entries(A, main_clicks, shown_clicks)
	result += main_clicks
	result += other_clicks
	add_verb_entries(A, result)
	SEND_SIGNAL(A, COMSIG_ATOM_CONTEXT_MENU, user, result)
	return result

/datum/context_menu/proc/add_click(list/result, list/shown_clicks, atom/A, name, hint, modifiers, intent, style)
	var/key = "[modifiers]|[intent]"
	if(shown_clicks[key])
		return
	shown_clicks[key] = TRUE
	var/params = "[modifiers];context_menu=1"
	if(A == clicked && length(click_position))
		params = "[params];[list2params(click_position)]"
	if(!style)
		style = (intent && intent != INTENT_HELP) ? CONTEXT_ENTRY_DANGER : CONTEXT_ENTRY_NORMAL
	result += new /datum/context_menu_entry/click(name, hint, style, params, intent)

/datum/context_menu/proc/add_basic_entries(atom/A, list/result, list/shown_clicks)
	add_click(result, shown_clicks, A, "Осмотреть", "Shift-ЛКМ", "shift=1;left=1")
	if(isitem(A))
		var/obj/item/item = A
		if(!item.anchored && item.loc != user && !user.get_active_held_item() && user.CanReach(item))
			add_click(result, shown_clicks, A, "Взять", "ЛКМ", "left=1")
	if(isliving(user) && ismovable(A) && A != user)
		var/atom/movable/movable = A
		if(user.pulling == movable)
			result += new /datum/context_menu_entry/callback("Отпустить", null, CONTEXT_ENTRY_NORMAL, CALLBACK(user, TYPE_PROC_REF(/atom/movable, stop_pulling)))
		else if(!movable.anchored && user.Adjacent(movable))
			add_click(result, shown_clicks, A, "Потянуть", "Ctrl-ЛКМ", "ctrl=1;left=1")
	if(A != user)
		add_click(result, shown_clicks, A, "Указать", "Shift-СКМ", "shift=1;middle=1")

/// Разовые действия каждым интентом. С предметом в руке - только «использовать» и удар им.
/datum/context_menu/proc/add_intent_entries(atom/A, list/result, list/shown_clicks)
	var/obj/item/held_item = user.get_active_held_item()
	if(held_item && held_item != A)
		add_click(result, shown_clicks, A, "Использовать: [held_item.name]", "ЛКМ", "left=1", null, CONTEXT_ENTRY_CURRENT)
		if(isliving(A) && A != user && user.a_intent != INTENT_HARM && (INTENT_HARM in user.possible_a_intents))
			add_click(result, shown_clicks, A, "Ударить: [held_item.name]", null, "left=1", INTENT_HARM)
		return
	if(!isliving(A) || A == user || !length(user.possible_a_intents))
		return
	for(var/intent in GLOB.context_menu_intent_names)
		if(!(intent in user.possible_a_intents))
			continue
		if(user.a_intent == intent)
			add_click(result, shown_clicks, A, GLOB.context_menu_intent_names[intent], "ЛКМ", "left=1", null, CONTEXT_ENTRY_CURRENT)
		else
			add_click(result, shown_clicks, A, GLOB.context_menu_intent_names[intent], null, "left=1", intent)

/// Строки скринтипа цели и предмета в руке: каждая - тот самый клик. ЛКМ - в main, остальное - в other.
/datum/context_menu/proc/add_screentip_entries(atom/A, list/main, list/other, list/shown_clicks)
	var/list/context = list()
	if(!(A.collect_screentip_context(user, user.get_active_held_item(), context) & CONTEXTUAL_SCREENTIP_SET))
		return
	for(var/key in context)
		var/list/key_info = GLOB.context_menu_screentip_keys[key]
		if(!key_info)
			continue
		var/list/result = key == SCREENTIP_CONTEXT_LMB ? main : other
		// второе действие у игрока в режиме меню висит на Shift+ПКМ
		var/key_hint = key == SCREENTIP_CONTEXT_RMB ? user.right_click_action_hint() : key_info[2]
		var/list/by_intent = context[key]
		if(!islist(by_intent))
			by_intent = list(INTENT_ANY = by_intent)
		// подпись конкретного интента важнее общей
		var/list/intents_in_order = by_intent - INTENT_ANY
		if(by_intent[INTENT_ANY])
			intents_in_order += INTENT_ANY
		for(var/intent in intents_in_order)
			var/text = by_intent[intent]
			if(!text)
				continue
			if(intent == INTENT_ANY || intent == user.a_intent)
				add_click(result, shown_clicks, A, capitalize(text), key_hint, key_info[1], null, key == SCREENTIP_CONTEXT_LMB ? CONTEXT_ENTRY_CURRENT : null)
			else if(intent in user.possible_a_intents)
				add_click(result, shown_clicks, A, capitalize(text), key == SCREENTIP_CONTEXT_LMB ? null : "[key_hint], [GLOB.context_menu_intent_short[intent]]", key_info[1], intent)

/// Вербы предмета в руках/на себе или структуры рядом. У мобов и турфов вербы почти все про себя, их не трогаем.
/datum/context_menu/proc/add_verb_entries(atom/A, list/result)
	if(!isobj(A))
		return
	if(A.loc != user && (isitem(A) || !user.Adjacent(A)))
		return
	for(var/procpath/verb_path as anything in A.verbs)
		if(verb_path.hidden || !verb_path.name || verb_path.invisibility > user.see_invisible)
			continue
		if(verb_path == /obj/item/verb/verb_pickup)
			continue
		result += new /datum/context_menu_entry/verb_call(capitalize(verb_path.name), null, CONTEXT_ENTRY_NORMAL, verb_path)
