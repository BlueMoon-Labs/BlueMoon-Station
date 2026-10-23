/datum/context_menu_entry
	var/name
	/// Горячая клавиша этого действия, показывается справа
	var/hint
	var/style = CONTEXT_ENTRY_NORMAL

/datum/context_menu_entry/New(name, hint, style)
	src.name = name
	src.hint = hint
	if(style)
		src.style = style

/datum/context_menu_entry/proc/execute(mob/user, atom/target)
	return

/// Чей значок рисуется в строке
/datum/context_menu_entry/proc/icon_source()
	return null

/// Повторяет клик игрока с модификаторами и, если задан, разово с другим интентом
/datum/context_menu_entry/click
	var/params
	var/intent

/datum/context_menu_entry/click/New(name, hint, style, params, intent)
	..()
	src.params = params
	src.intent = intent

/datum/context_menu_entry/click/execute(mob/user, atom/target)
	if(!intent || user.a_intent == intent)
		INVOKE_ASYNC(user, TYPE_PROC_REF(/mob, CommonClickOn), target, params)
		return
	var/old_intent = user.a_intent
	user.a_intent = intent
	// Клик возвращается на первом сне, развилка по интенту к этому моменту пройдена
	INVOKE_ASYNC(user, TYPE_PROC_REF(/mob, CommonClickOn), target, params)
	if(user.a_intent == intent)
		user.a_intent = old_intent

/datum/context_menu_entry/verb_call
	var/verb_path

/datum/context_menu_entry/verb_call/New(name, hint, style, verb_path)
	..()
	src.verb_path = verb_path

/datum/context_menu_entry/verb_call/execute(mob/user, atom/target)
	if(!(verb_path in target.verbs))
		return
	INVOKE_ASYNC(target, verb_path)

/datum/context_menu_entry/callback
	var/datum/callback/on_choose

/datum/context_menu_entry/callback/New(name, hint, style, datum/callback/on_choose)
	..()
	src.on_choose = on_choose

/datum/context_menu_entry/callback/execute(mob/user, atom/target)
	on_choose?.InvokeAsync()

/// Выбор объекта из клетки; пустой - назад к списку клетки
/datum/context_menu_entry/pick
	var/datum/weakref/picked_ref

/datum/context_menu_entry/pick/New(name, hint, style, atom/picked)
	..()
	picked_ref = WEAKREF(picked)

/datum/context_menu_entry/pick/icon_source()
	return picked_ref?.resolve()

/// Несколько одинаковых объектов клетки одной строкой: открывает их список
/datum/context_menu_entry/pick_group
	var/list/datum/weakref/refs = list()

/datum/context_menu_entry/pick_group/New(name, hint, style, list/atom/things)
	..()
	for(var/atom/thing as anything in things)
		refs += WEAKREF(thing)

/datum/context_menu_entry/pick_group/icon_source()
	for(var/datum/weakref/ref as anything in refs)
		var/atom/thing = ref.resolve()
		if(thing)
			return thing

/datum/context_menu_entry/page
