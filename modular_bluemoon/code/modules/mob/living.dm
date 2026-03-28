//SET_ACTIVITY START
/// Continuous and static "/me"
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
	// BLUEMOON EDIT START - изменение памяти после смерти
	if(mind)
		mind.death_handle_memory()
	// BLUEMOON EDIT END

/mob/living/get_tooltip_data()
	if(activity)
		. = list()
		. += activity

//SET_ACTIVITY END
