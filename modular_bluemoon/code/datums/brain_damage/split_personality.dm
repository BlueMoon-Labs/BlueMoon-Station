#define OWNER 0
#define STRANGER 1
#define TAKE_CONTROL_COOLDOWN 5 MINUTES

/datum/brain_trauma/severe/split_personality
	desc = "Мозг пациента разделён на две личности, которые могут передавать друг другу управление телом по желанию."
	var/datum/action/innate/split_personality_control/body_action
	var/datum/action/innate/split_personality_control/backseat_action
	var/last_take_control = 0

/datum/brain_trauma/severe/split_personality/brainwashing
	desc = "Patient's brain is split into two personalities, which randomly switch control of the body."

/datum/brain_trauma/severe/split_personality/brainwashing/setup_personality_actions()
	return

/datum/brain_trauma/severe/split_personality/on_life()
	if(got_ghost)
		var/mob/living/split_personality/inactive = get_inactive_personality_mob()
		if(!inactive?.ckey && current_controller == OWNER)
			got_ghost = FALSE
			setup_personality_actions()
	else if(last_attempt + 100 < world.time)
		get_ghost()
		last_attempt = world.time
	return ..()

/datum/brain_trauma/severe/split_personality/on_stranger_joined()
	setup_personality_actions()

/datum/brain_trauma/severe/split_personality/cleanup_personality_actions()
	QDEL_NULL(body_action)
	QDEL_NULL(backseat_action)

/datum/brain_trauma/severe/split_personality/setup_personality_actions()
	if(!body_action)
		body_action = new(src)
	if(!backseat_action)
		backseat_action = new(src)
	body_action.Grant(owner)
	if(got_ghost)
		backseat_action.Grant(get_inactive_personality_mob())
	else if(backseat_action.owner)
		backseat_action.Remove(backseat_action.owner)

/datum/brain_trauma/severe/split_personality/proc/get_inactive_personality_mob()
	return current_controller == OWNER ? stranger_backseat : owner_backseat

/datum/brain_trauma/severe/split_personality/proc/is_take_control_attempt(mob/living/requester)
	if(requester == owner_backseat)
		return current_controller == STRANGER
	if(requester == stranger_backseat)
		return current_controller == OWNER
	return FALSE

/datum/brain_trauma/severe/split_personality/proc/can_voluntary_switch(mob/living/requester)
	if(!requester || QDELETED(requester))
		return FALSE
	if(requester == owner)
		return got_ghost
	if(requester == owner_backseat)
		return current_controller == STRANGER && world.time >= last_take_control + TAKE_CONTROL_COOLDOWN
	if(requester == stranger_backseat)
		return got_ghost && current_controller == OWNER && world.time >= last_take_control + TAKE_CONTROL_COOLDOWN
	return FALSE

/datum/brain_trauma/severe/split_personality/proc/request_voluntary_switch(mob/living/requester)
	if(!can_voluntary_switch(requester))
		if(is_take_control_attempt(requester) && world.time < last_take_control + TAKE_CONTROL_COOLDOWN)
			to_chat(requester, span_warning("Вы сможете забрать управление через [DisplayTimeText(last_take_control + TAKE_CONTROL_COOLDOWN - world.time)]."))
		else if(requester == owner_backseat)
			to_chat(requester, span_warning("Вы не можете забрать управление прямо сейчас."))
		else if(!got_ghost)
			to_chat(requester, span_warning("Вторая личность ещё не подключилась."))
		else
			to_chat(requester, span_warning("Вы не можете передать управление прямо сейчас."))
		return
	if(is_take_control_attempt(requester))
		last_take_control = world.time
	switch_personalities(TRUE)

/datum/brain_trauma/severe/split_personality/proc/send_inner_message(mob/living/sender, message)
	if(!length(message))
		return
	var/mob/living/recipient
	if(sender == owner)
		recipient = get_inactive_personality_mob()
	else if(sender == owner_backseat || sender == stranger_backseat)
		recipient = owner
	if(recipient?.client)
		to_chat(recipient, span_notice("Вы слышите голос в голове... \"[message]\""))
	else
		to_chat(sender, span_warning("В ответ — тишина."))

/datum/action/innate/split_personality_control
	name = "Вторая личность"
	desc = "Поговорить с другой личностью или передать/забрать управление телом."
	icon_icon = 'icons/mob/actions.dmi'
	button_icon_state = "default"
	var/datum/brain_trauma/severe/split_personality/trauma

/datum/action/innate/split_personality_control/New(datum/brain_trauma/severe/split_personality/T)
	trauma = T
	..()

/datum/action/innate/split_personality_control/Activate()
	if(!trauma || QDELETED(trauma))
		return

	var/list/options = list()
	if(trauma.got_ghost)
		options += "Отправить сообщение"
	if(trauma.can_voluntary_switch(owner))
		options += "Передать / забрать управление"

	if(!length(options))
		to_chat(owner, span_warning("Вторая личность ещё не подключилась."))
		return

	var/choice = tgui_input_list(owner, "Выберите действие.", "Вторая личность", options)
	if(!choice)
		return

	switch(choice)
		if("Отправить сообщение")
			var/message = tgui_input_text(owner, "Ваше сообщение услышит только другая личность.", "Внутренний голос", max_length = MAX_MESSAGE_LEN)
			trauma.send_inner_message(owner, message)
		if("Передать / забрать управление")
			trauma.request_voluntary_switch(owner)

#undef OWNER
#undef STRANGER
#undef TAKE_CONTROL_COOLDOWN
