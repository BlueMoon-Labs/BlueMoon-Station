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
	if(mind)
		mind.death_handle_memory()

/mob/living/get_tooltip_data()
	if(activity)
		. = list()
		. += activity

//SET_ACTIVITY END

/mob/living/verb/player_narrate_subtler()
	set category = "Say"
	set name = "Narrate Subtler (Player)"
	set desc = "Narrate an action or event! An alternative to emoting, for when your emote shouldn't start with your name! Only for adjacent players excluding ghosts."
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

/datum/emote/sound/human/narrate/subtler
	key = "narrate_subtler"
	key_third_person = "narrate_subtler"
	subtler = TRUE
