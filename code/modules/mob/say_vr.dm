//////////////////////////////////////////////////////
////////////////////SUBTLE COMMAND////////////////////
//////////////////////////////////////////////////////

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

///////////////// EMOTE CODE
// Maybe making this as an emote is less messy?
// It was - ktccd
/datum/emote/sound/human/subtle
	key = "subtle"
	key_third_person = "subtle"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtle/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtle/run_emote(mob/user, params, type_override = null)
	if(jobban_isbanned(user, "emote"))
		to_chat(user, "You cannot send subtle emotes (banned).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	else if(!params)
		var/subtle_emote = ""
		if(user.client?.prefs.tgui_input_verbs)
			subtle_emote = tgui_input_text(user, "Введите сообщение, которое увидят персонажи в упор к вам и призраки.", "Subtle", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			subtle_emote = stripped_multiline_input_or_reflect(user, "Введите сообщение, которое увидят персонажи в упор к вам и призраки.", "Subtle")

		if(subtle_emote && !check_invalid(user, subtle_emote))
			message = subtle_emote
		else
			return FALSE
	else
		message = params
		if(type_override)
			emote_type = type_override
	. = TRUE
	if(!can_run_emote(user))
		return FALSE

	user.log_message(message, LOG_EMOTE)
	message = "<span class='emote'><b>[user]</b> <i>[user.say_emphasis(message)]</i></span>"

	for(var/mob/M in GLOB.dead_mob_list)
		if(!M.client || isnewplayer(M))
			continue
		var/T = get_turf(src)
		if(M.stat == DEAD && M.client && (M.client.prefs.chat_toggles & CHAT_GHOSTSIGHT) && !(M in viewers(T, null)) && (user.client)) //SKYRAT CHANGE - only user controlled mobs show their emotes to all-seeing ghosts, to reduce chat spam
			M.show_message(message)

	user.visible_message(message = message, self_message = message, vision_distance = 1, omni = TRUE)

///////////////// SUBTLE 2: NO GHOST BOOGALOO

/datum/emote/sound/human/subtler
	key = "subtler"
	key_third_person = "subtler"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtler/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler/run_emote(mob/user, params, type_override = null)
	var/const/vision_dist = 1
	if(jobban_isbanned(user, "emote"))
		to_chat(user, "You cannot send subtle emotes (banned).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	else if(!params)
		var/subtle_emote = "" 
		if(user.client?.prefs.tgui_input_verbs)
			subtle_emote = tgui_input_text(user, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			subtle_emote = stripped_multiline_input_or_reflect(user, "Введите сообщение, которое увидят персонажи в упор к вам. Призраки его не увидят.", "Введите скрытое сообщение")

		if(subtle_emote && !check_invalid(user, subtle_emote))
			message = subtle_emote
		else
			return FALSE
	else
		message = params
		if(type_override)
			emote_type = type_override
	. = TRUE
	if(!can_run_emote(user))
		return FALSE

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

///////////////// SUBTLE 3: DARE DICE

/datum/emote/sound/human/subtler_table
	key = "subtler_table"
	key_third_person = "subtler_table"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)

/datum/emote/sound/human/subtler_table/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler_table/run_emote(mob/user, params, type_override = null)
	if(!locate(/obj/structure/table) in range(user, 1))
		to_chat(user, "There are no tables around you.")
		return FALSE
	if(jobban_isbanned(user, "emote"))
		to_chat(user, "You cannot send subtle emotes (banned).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	else if(!params)
		var/subtle_emote = ""
		if(user.client?.prefs.tgui_input_verbs)
			subtle_emote = tgui_input_text(user, "Choose an emote to display.", "Subtler Around Table", null, MAX_MESSAGE_LEN, TRUE, TRUE)
		else
			subtle_emote = stripped_multiline_input_or_reflect(user, "Choose an emote to display.", "Subtler Around Table")

		if(subtle_emote && !check_invalid(user, subtle_emote))
			message = subtle_emote
		else
			return FALSE
	else
		message = params
		if(type_override)
			emote_type = type_override
	. = TRUE
	if(!can_run_emote(user))
		return FALSE

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

//BLUEMOON ADD START
///////////////// SUBTLE 4: TARGET

/datum/emote/sound/human/subtler_target
	key = "subtler_target"
	key_third_person = "subtler_target"
	message = null
	mob_type_blacklist_typecache = list(/mob/living/brain)
	emote_cooldown = 0

/datum/emote/sound/human/subtler_target/proc/check_invalid(mob/user, input)
	if(stop_bad_mime.Find(input, 1, 1))
		to_chat(user, "<span class='danger'>Invalid emote.</span>")
		return TRUE
	return FALSE

/datum/emote/sound/human/subtler_target/run_emote(mob/user, params, type_override = null)
	var/const/work_distance = 5
	. = TRUE
	var/list/parameters = list("text" = "", "indicator" = FALSE, "target" = null) // Параметры для использования

	if(jobban_isbanned(user, "emote"))
		to_chat(user, "You cannot send subtle emotes (banned).")
		return FALSE
	else if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE

	if(type_override)
		emote_type = type_override
	if(!can_run_emote(user))
		return FALSE

	if(params) // Копируем нужные пераметры
		if(islist(params))
			for(var/list_key in parameters)
				if(params[list_key] != null)
					parameters[list_key] = params[list_key]
		else if(istext(params))
			parameters["text"] = params

	var/mob/living/target

	// Определяем цель
	if(parameters["target"])
		target = parameters["target"]
	else
		var/list/possible_target = list()
		for(var/mob/living/L in oview(work_distance, user))
			LAZYADD(possible_target, L)

		if(possible_target.len > 13) // Много целей, TGUI с поиском
			target = tgui_input_list(user, "Выберете персонажа, который увидит ваши действия", "Выбор персонажа", possible_target)
		else // Радиальное меню
			for(var/mob/living/listed in possible_target)
				possible_target[listed] = new /mutable_appearance(listed)

			if(!possible_target || !possible_target.len)
				to_chat(user, span_warning("No target around."))
				return FALSE

			target = possible_target.len == 1 ? possible_target[1] : show_radial_menu(user, user, possible_target, radius = 40)

		if(!target)
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

		if(subtle_emote && !check_invalid(user, subtle_emote))
			message = subtle_emote
		else
			return FALSE

	message = "<span class='emote'><b>[user]</b> <i>[user.say_emphasis(message)]</i></span>"

	// Отправка сообщений
	if(target in view(work_distance, user))
		to_chat(target, "[span_nicegreen("Ты замечаешь, как")] [message]")
		// Логи
		user.log_message("[message] (SUBTLER-TARGET to [target.name])", LOG_SUBTLER)
	else
		to_chat(user, span_alert("[target_name] удалился слишком далеко и не увидел твои действия."))
		// Логи
		user.log_message("[message] (SUBTLER-TARGET to [target.name] (unheard))", LOG_SUBTLER)
	to_chat(user, message)

//BLUEMOON ADD END

///////////////// VERB CODE
/mob/living/verb/subtle()
	set name = "Subtle"
	set category = "Say"
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	usr.emote("subtle")

///////////////// VERB CODE 2
/mob/living/verb/subtler()
	set name = "Subtler Anti-Ghost"
	set category = "Say"
	if(GLOB.say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	usr.emote("subtler")

///////////////// VERB CODE 3
/mob/living/verb/subtler_table()
	set name = "Subtler Around Table"
	set category = "Say"
	if(GLOB.say_disabled)	//This is dumb but it's here because heehoo copypaste, who the FUCK uses this to identify lag?
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	usr.emote("subtler_table")

//BLUEMOON ADD START
///////////////// VERB CODE 4
/mob/living/verb/subtler_target()
	set name = "Subtler Target"
	set category = "Say"
	if(GLOB.say_disabled)	//This is dumb but it's here because heehoo copypaste, who the FUCK uses this to identify lag?
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	usr.emote("subtler_target", message = list("indicator" = FALSE))

/mob/living/verb/subtler_target_indicatored()
	set name = "Subtler Target (Indicator)"
	set category = "Say"
	// Check if say is disabled
	if(GLOB.say_disabled)
		// Warn user and return
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	usr.emote("subtler_target", message = list("indicator" = TRUE))
//BLUEMOON ADD END
