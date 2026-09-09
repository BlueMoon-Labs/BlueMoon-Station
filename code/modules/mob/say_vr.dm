/////////////////////////////////////////
///////////////// VERBS /////////////////
/////////////////////////////////////////

//////////////////// SUBTLER ANTI-GHOST ////////////////////
/mob/living/verb/subtler_byond(message as message)
	set name = "Subtler Anti-Ghost "
	set desc = "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят."
	set hidden = TRUE
	if(!message)
		return
	subtler(message)

/mob/living/verb/subtler(message = "" as message)
	set name = "Subtler Anti-Ghost"
	set category = "Say"
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, html_encode(message))
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	// текст верба приходит сырым, а канал эмоутов ничего не экранирует - кодируем ровно один раз здесь
	if(length(message))
		message = stripped_text_or_reflect(usr, message)
		if(!length(message))
			return
	usr.emote("subtler", message = message)

/mob/living/verb/subtler_indicatored()
	set name = "Subtler Anti-Ghost (Indicator)"
	set category = "Say"
	if(GLOB.say_disabled)
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	display_typing_indicator(isMe = TRUE)

	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение", null, MAX_MESSAGE_LEN, TRUE, TRUE)
	else
		message = stripped_multiline_input_or_reflect(src, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение")

	clear_typing_indicator()
	if(!length(message))
		return
	usr.emote("subtler", message = message)

//////////////////// SUBTLER TABLE ////////////////////
/mob/living/verb/subtler_table()
	set name = "Subtler Around Table"
	set category = "Say"
	if(GLOB.say_disabled)	//This is dumb but it's here because heehoo copypaste, who the FUCK uses this to identify lag?
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	usr.emote("subtler_table")

//////////////////// SUBTLER TARGET ////////////////////
/mob/living/verb/subtler_target_byond(message as message)
	set name = "Subtler Target "
	set desc = "Введите сообщение, которое увидит, ТОЛЬКО выбранный персонаж."
	set hidden = TRUE
	if(!message)
		return
	subtler_target(message)

/mob/living/verb/subtler_target(message = "" as message)
	set name = "Subtler Target"
	set category = "Say"
	if(GLOB.say_disabled)	//This is dumb but it's here because heehoo copypaste, who the FUCK uses this to identify lag?
		to_chat(usr, html_encode(message))
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return
	// текст верба приходит сырым, а канал эмоутов ничего не экранирует - кодируем ровно один раз здесь
	if(length(message))
		message = stripped_text_or_reflect(usr, message)
		if(!length(message))
			return
	usr.emote("subtler_target", message = list("text" = message, "indicator" = FALSE))

/mob/living/verb/subtler_target_indicatored()
	set name = "Subtler Target (Indicator)"
	set category = "Say"
	// Check if say is disabled
	if(GLOB.say_disabled)
		// Warn user and return
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	usr.emote("subtler_target", message = list("indicator" = TRUE))

//////////////////// NARRATE ////////////////////
/mob/living/verb/player_narrate()
	set name = "Narrate (Player)"
	set desc = "Narrate an action or event! An alternative to emoting, for when your emote shouldn't start with your name!"
	set category = "Say"
	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	display_typing_indicator(isMe = TRUE)
	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "Опишите действие или событие. Альтернатива эмоции, когда ваша эмоция не должна начинаться с вашего имени.", "Narrate (Player)", null, MAX_MESSAGE_LEN, TRUE, TRUE)
	else
		message = stripped_multiline_input_or_reflect(src, "Опишите действие или событие. Альтернатива эмоции, когда ваша эмоция не должна начинаться с вашего имени.", "Narrate (Player)")
	clear_typing_indicator()
	if(!length(message))
		return
	emote("narrate", message=message)

/mob/living/verb/player_narrate_subtler()
	set name = "Narrate Subtler (Player)"
	set desc = "Narrate an action or event! An alternative to emoting, for when your emote shouldn't start with your name! Only for adjacent players excluding ghosts."
	set category = "Say"
	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	display_typing_indicator(isMe = TRUE)
	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "Опишите действие или событие. Альтернатива эмоции, когда ваша эмоция не должна начинаться с вашего имени. Видно только игрокам поблизости, исключая призраков.", "Narrate Subtler (Player)", null, MAX_MESSAGE_LEN, TRUE, TRUE)
	else
		message = stripped_multiline_input_or_reflect(src, "Опишите действие или событие. Альтернатива эмоции, когда ваша эмоция не должна начинаться с вашего имени. Видно только игрокам поблизости, исключая призраков.", "Narrate Subtler (Player)")
	clear_typing_indicator()
	if(!length(message))
		return
	emote("narrate_subtler", message=message)

//////////////////// ACTIVITY ////////////////////
/mob/living/verb/set_activity()
	set name = "Деятельность"
	set desc = "Описывает то, что вы сейчас делаете."
	set category = "Say"

	if(activity)
		reset_activity()
		return
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	if(stat != CONSCIOUS)
		to_chat(src, span_warning("Недоступно в твоем нынешнем состоянии"))
		return

	display_typing_indicator(isMe = TRUE)

	var/message = ""
	if(client?.prefs.tgui_input_verbs)
		message = tgui_input_text(src, "Здесь можно описать продолжительную (долго длящуюся) деятельность, которая будет отображаться столько, сколько тебе нужно.", "Опиши свою деятельность", "", MAX_MESSAGE_LEN, encode = TRUE)
	else
		message = stripped_multiline_input_or_reflect(src, "Здесь можно описать продолжительную (долго длящуюся) деятельность, которая будет отображаться столько, сколько тебе нужно.", "Опиши свою деятельность")

	clear_typing_indicator()
	if(!length(message))
		return
	activity = message
	usr.emote("me",1,activity,TRUE)
	activity = capitalize(activity)
	set_activity_indicator(TRUE)

//////////////////////////////////////////////////////
////////////////////SUBTLE COMMAND////////////////////
//////////////////////////////////////////////////////

//////////////////// ACTIVITY ////////////////////
/mob/living/proc/set_activity_indicator(state)
	var/mutable_appearance/activity_indicator = mutable_appearance('modular_bluemoon/icons/mob/activity_indicator.dmi', "tea", FLY_LAYER, appearance_flags = APPEARANCE_UI_IGNORE_ALPHA | KEEP_APART)
	activity_indicator.pixel_y = 10
	if(state)
		add_overlay(activity_indicator)
	else
		cut_overlay(activity_indicator)

/mob/living/proc/reset_activity()
	activity = ""
	set_activity_indicator(FALSE)
	to_chat(src, span_notice("Деятельность сброшена"))

/mob/living/update_stat()
	if(activity && stat != CONSCIOUS)
		reset_activity()
	. = ..()

/mob/living/death(gibbed)
	. = ..()
	if(activity)
		reset_activity()
	if(mind)
		mind.death_handle_memory()

/mob/living/get_tooltip_data()
	if(activity)
		. = list()
		. += activity
//////////////////// ACTIVITY END ////////////////////

/mob/proc/get_top_level_mob()
	if(ismob(src.loc) && src.loc != src)
		var/mob/M = src.loc
		return M.get_top_level_mob()
	return src

/proc/get_top_level_mob(mob/S)
	if(ismob(S.loc) && S.loc != S)
		var/mob/M = S.loc
		return M.get_top_level_mob()
	return S

//////////////////////////////////////////////
///////////////// EMOTE CODE /////////////////
//////////////////////////////////////////////

///////////////// SUBTLE 2: NO GHOST BOOGALOO /////////////////

/datum/emote/sound/human/subtler
	key = "subtler"
	key_third_person = "subtler"
	emote_cooldown = 0
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtler/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, span_danger("Invalid emote."))
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler/run_emote(mob/user, params, type_override = null)
	var/const/vision_dist = 1
	message = null
	if(jobban_isbanned(user, "emote"))
		if(istext(params))
			to_chat(user, params)
		to_chat(user, span_boldwarning("You cannot send emotes (banned)."))
		return FALSE
	if(user.client && user.client.prefs.muted & MUTE_IC)
		if(istext(params))
			to_chat(user, params)
		to_chat(user, span_boldwarning("You cannot send IC messages (muted)."))
		return FALSE

	// params сюда доходит уже закодированным (верб, инпут индикатора или sanitize() внутри say для "*subtler")
	if(istext(params) && length(params))
		message = params
	else
		if(user.client?.prefs.tgui_input_verbs)
			message = tgui_input_text(user, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			message = stripped_multiline_input_or_reflect(user, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение")

	if(!message)
		return FALSE
	if(type_override)
		emote_type = type_override
	if(check_invalid(user, message))
		to_chat(user, message)
		return FALSE
	if(!can_run_emote(user))
		to_chat(user, message)
		to_chat(user, "You cannot do it now.")
		return FALSE

	. = TRUE

	user.log_message(message, LOG_SUBTLER)
	message = "<span class='emote'><b>[user]</b> <i>[user.say_emphasis(message)]</i></span>"

	var/list/ignored_mobs_list = LAZYCOPY(GLOB.dead_mob_list)
	var/see_invis = user.see_invisible
	for(var/atom/A in range(vision_dist, get_turf(user)))
		// ищем всех мобов, включая тех что внутри contents
		var/list/stack = list(A)
		while(stack.len)
			var/atom/B = stack[stack.len]
			stack.len-- // pop

			if(ismob(B))
				var/mob/M = B
				if(M != user)
					// ищем максимальную невидимость по цепочке loc вверх
					var/invis = M.invisibility
					var/atom/movable/x = M
					while(istype(x.loc, /atom/movable))
						x = x.loc
						if(x.invisibility > invis)
							invis = x.invisibility

					if(see_invis < invis)
						LAZYADD(ignored_mobs_list, M) // Исключаем мобов, которые должны быть невидимы для нас

			if(istype(B, /atom/movable))
				var/atom/movable/MV = B
				if(MV.contents && MV.contents.len)
					stack += MV.contents

	user.visible_message(message = message, self_message = message, vision_distance = vision_dist, ignored_mobs = ignored_mobs_list, omni = TRUE)

///////////////// SUBTLE 3: DARE DICE /////////////////

/datum/emote/sound/human/subtler_table
	key = "subtler_table"
	key_third_person = "subtler_table"
	emote_cooldown = 0
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtler_table/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler_table/run_emote(mob/user, params, type_override = null)
	message = null
	if(!locate(/obj/structure/table) in range(user, 1))
		if(istext(params))
			to_chat(user, params)
		to_chat(user, "There are no tables around you.")
		return FALSE
	if(jobban_isbanned(user, "emote"))
		if(istext(params))
			to_chat(user, params)
		to_chat(user, "You cannot send subtle emotes (banned).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		if(istext(params))
			to_chat(user, params)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE

	// params сюда доходит уже закодированным (верб или sanitize() внутри say для "*subtler_table")
	if(istext(params) && length(params))
		message = params
	else
		if(user.client?.prefs.tgui_input_verbs)
			message = tgui_input_text(user, "Choose an emote to display.", "Subtler Around Table", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			message = stripped_multiline_input_or_reflect(user, "Choose an emote to display.", "Subtler Around Table")

	if(!message)
		return FALSE
	if(check_invalid(user, message))
		to_chat(user, message)
		return FALSE

	if(type_override)
		emote_type = type_override
	if(!can_run_emote(user))
		return FALSE
	. = TRUE

	user.log_message("[message] (TABLE-WRAPPING)", LOG_SUBTLER)
	message = "<span class='emote'><b>[user]</b> <i>[user.say_emphasis(message)]</i></span>"

	var/list/show_to = list()
	var/list/processed = list()
	for(var/obj/structure/table/T in range(user, 1))
		if(processed[T])
			continue
		for(var/obj/structure/table/T2 in T.connected_floodfill(25))
			processed[T2] = TRUE
			for(var/mob/living/L in range(T2, 1))
				show_to |= L

	for(var/i in show_to)
		var/mob/M = i
		M.show_message(message)

///////////////// SUBTLE 4: TARGET /////////////////

/datum/emote/sound/human/subtler_target
	key = "subtler_target"
	key_third_person = "subtler_target"
	emote_cooldown = 0
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtler_target/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler_target/run_emote(mob/user, params, type_override = null)
	var/const/work_distance = 5
	message = null
	. = TRUE
	var/list/parameters = list("text" = "", "indicator" = FALSE, "target" = null) // Параметры для использования

	if(params) // Копируем нужные пераметры
		if(islist(params))
			for(var/list_key in parameters)
				if(params[list_key] != null)
					parameters[list_key] = params[list_key]
		else if(istext(params) && length(params))
			parameters["text"] = params

	if(jobban_isbanned(user, "emote"))
		to_chat(user, parameters["text"])
		to_chat(user, "You cannot send emotes (banned).")
		return FALSE
	if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, parameters["text"])
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	if(type_override)
		emote_type = type_override
	if(!can_run_emote(user))
		to_chat(user, parameters["text"])
		return FALSE

	var/mob/living/target

	// Определяем цель
	if(parameters["target"])
		target = parameters["target"]
	else
		var/list/possible_target = list()
		for(var/mob/living/L in oview(work_distance, user))
			possible_target += L

		// Все мобы в loc цепочке
		possible_target |= user.get_all_recursive_loc(/mob/living)
		// Все мобы внутри нас
		possible_target |= user.GetAllContents(/mob/living) - user

		if(possible_target.len > 13) // Много целей, TGUI с поиском
			target = tgui_input_list(user, "Выберете персонажа, который увидит ваши действия", "Выбор персонажа", possible_target)
		else // Радиальное меню
			for(var/mob/living/listed as anything in possible_target)
				possible_target[listed] = new /mutable_appearance(listed)

			if(!LAZYLEN(possible_target))
				to_chat(user, parameters["text"])
				to_chat(user, span_warning("No target around."))
				return FALSE

			target = possible_target.len == 1 ? possible_target[1] : show_radial_menu(user, user, possible_target, radius = 40)

		if(QDELETED(target))
			to_chat(user, span_warning("Target is now unavailable."))
			to_chat(user, parameters["text"])
			return FALSE

	var/target_name = target.get_visible_name()

	// Текст сообщения
	if(parameters["text"])
		message = parameters["text"]
	else
		if(parameters["indicator"]) // Показываем индикатор
			user.display_typing_indicator(isMe = TRUE)
		// Вводим сообщение
		var/subtle_emote = ""
		if(user.client?.prefs.tgui_input_verbs)
			subtle_emote = tgui_input_text(user, "Введите сообщение, которое увидит, ТОЛЬКО [target_name].", "Введите скрытое сообщение", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			subtle_emote = stripped_multiline_input_or_reflect(user, "Введите сообщение, которое увидит, ТОЛЬКО [target_name].", "Введите скрытое сообщение")

		if(parameters["indicator"]) // Удаляем индикатор
			user.clear_typing_indicator()

		message = subtle_emote

	if(!message)
		return FALSE
	if(check_invalid(user, message))
		to_chat(user, message)
		return FALSE

	message = "<span class='emote'><b>[user]</b> <i>[user.say_emphasis(message)]</i></span>"

	// Отправка сообщений
	if(!QDELETED(target) && get_dist(user, target) <= work_distance)
		to_chat(target, "[span_nicegreen("Ты замечаешь, как")] [message]")
		// Логи
		user.log_message("[message] (SUBTLER-TARGET to [target.name])", LOG_SUBTLER)
	else
		to_chat(user, span_alert("[target_name] удали[target.ru_sya()] слишком далеко и не увидел[target.ru_a()] твои действия."))
		// Логи
		user.log_message("[message] (SUBTLER-TARGET to [target.name] (unheard))", LOG_SUBTLER)
	to_chat(user, message)

///////////////// NARRATE /////////////////
/datum/emote/sound/human/narrate
	key = "narrate"
	key_third_person = "narrates"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)
	emote_type = EMOTE_OMNI
	var/subtler = FALSE

/datum/emote/sound/human/narrate/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/narrate/run_emote(mob/user, params, type_override, intentional)
	. = TRUE
	if(!istext(params))
		return FALSE
	// params сюда доходит уже закодированным (верб или sanitize() внутри say для "*narrate")
	message = params
	if(!length(message))
		return FALSE
	if(jobban_isbanned(user, "emote"))
		to_chat(user, message)
		to_chat(user, "You cannot send narrates (banned).")
		return FALSE
	if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, message)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	if(type_override)
		emote_type = type_override
	if(!can_run_emote(user))
		to_chat(user, message)
		to_chat(user, "You cannot do it now.")
		return FALSE
	if(check_invalid(user, message))
		to_chat(user, message)
		return FALSE

	user.log_message(message, LOG_EMOTE)
	var/list/ignored_mobs_list = list()
	var/vision_dist = DEFAULT_MESSAGE_RANGE
	if(subtler)
		message = "<i>[message]</i>"
		// копипаст с "subtler"
		vision_dist = 1
		ignored_mobs_list = LAZYCOPY(GLOB.dead_mob_list)
		for(var/atom/A in range(vision_dist, get_turf(user)))
			// ищем всех мобов, включая тех что внутри contents
			var/list/stack = list(A)
			while(stack.len)
				var/atom/B = stack[stack.len]
				stack.len-- // pop
				if(ismob(B))
					var/mob/M = B
					if(M != user)
						// ищем максимальную невидимость по цепочке loc вверх
						var/invis = M.invisibility
						var/atom/movable/x = M
						while(istype(x.loc, /atom/movable))
							x = x.loc
							if(x.invisibility > invis)
								invis = x.invisibility
						if(user.see_invisible < invis)
							LAZYADD(ignored_mobs_list, M) // Исключаем мобов, которые должны быть невидимы для нас
				if(istype(B, /atom/movable))
					var/atom/movable/MV = B
					if(MV.contents && MV.contents.len)
						stack += MV.contents
	else
		var/T = get_turf(user)
		for(var/mob/M in GLOB.dead_mob_list)
			if(!M.client || isnewplayer(M))
				continue
			if(M.stat == DEAD && (M.client.prefs.chat_toggles & CHAT_GHOSTSIGHT) && !(M in viewers(T, null)))
				M.show_message("[FOLLOW_LINK(M, user)] " + message)

	message = "<span class='name'>([user])</span> <span class='pnarrate'>[user.say_emphasis(message)]</span>"
	user.visible_message(message = message, self_message = message, vision_distance = vision_dist, ignored_mobs = ignored_mobs_list, omni = TRUE)

/datum/emote/sound/human/narrate/subtler
	key = "narrate_subtler"
	key_third_person = "narrate_subtler"
	subtler = TRUE
