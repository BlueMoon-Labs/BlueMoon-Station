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
	if(jobban_isbanned(user, "emote"))
		to_chat(user, "You cannot send narrates (banned).")
		return FALSE
	if(user.client && user.client.prefs.muted & MUTE_IC)
		to_chat(user, "You cannot send IC messages (muted).")
		return FALSE
	if(!params)
		return FALSE
	message = params
	if(type_override)
		emote_type = type_override
	if(!can_run_emote(user) || check_invalid(user, message))
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
		for(var/mob/M in GLOB.dead_mob_list)
			if(!M.client || isnewplayer(M))
				continue
			var/T = get_turf(src)
			if(M.stat == DEAD && M.client && (M.client.prefs.chat_toggles & CHAT_GHOSTSIGHT) && !(M in viewers(T, null)) && (user.client))
				M.show_message("[FOLLOW_LINK(M, user)] " + message)

	message = "<span class='name'>([user])</span> <span class='pnarrate'>[user.say_emphasis(message)]</span>"
	user.visible_message(message = message, self_message = message, vision_distance = vision_dist, ignored_mobs = ignored_mobs_list, omni = TRUE)

/mob/living/verb/player_narrate()
	set category = "Say"
	set name = "Narrate (Player)"
	set desc = "Narrate an action or event! An alternative to emoting, for when your emote shouldn't start with your name!"
	if(GLOB.say_disabled)
		to_chat(usr, "<span class='danger'>Speech is currently admin-disabled.</span>")
		return
	display_typing_indicator(isMe = TRUE)
	var/message = stripped_multiline_input_or_reflect(usr, "Narrate an action or event! An alternative to emoting, for when your emote shouldn't start with your name!", "Narrate (Player)", null, MAX_MESSAGE_LEN)
	clear_typing_indicator()
	emote("narrate", message=message)

/datum/emote/sound/human/subtle/subtle_indicator
	key = "subtle-indicator"
	key_third_person = "subtle-indicator"

/mob/living/verb/subtle_indicator()
	// Set data
	set name = "Subtle (Indicator)"
	set category = "Say"

	// Check if say is disabled
	if(GLOB.say_disabled)
		// Warn user and return
		to_chat(usr, span_danger("Speech is currently admin-disabled."))
		return

	// Display typing indicator
	display_typing_indicator(isMe = TRUE)

	// Prompt user for text input
	var/input_message = input(usr, "What would you like to subtly emote, with a typing indicator?", "Input subtle emote") as message|null

	// Remove typing indicator
	clear_typing_indicator()

	// Run subtle emote with input
	usr.emote("subtle", message = input_message)
