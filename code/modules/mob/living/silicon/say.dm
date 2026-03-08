// (EDIT) Pe4henika bluemoon -- start
/mob/living/proc/robot_talk(message)
    log_talk(message, LOG_SAY)
    var/desig = "Default Cyborg"
    if(issilicon(src))
        var/mob/living/silicon/S = src
        desig = trim_left(S.designation + " " + S.job)

    var/message_a = say_quote(message)
    var/is_ai = isAI(src)

    var/rendered_name = is_ai ? "<font size=3><b>[name]</b></font>" : "<span class='name'>[name]</span>"
    var/rendered_msg = is_ai ? "<font size=3><span class='command'><b>[message_a]</b></span></font>" : "<span class='message'>[message_a]</span>"

    var/header = "<span class='binarysay'>Robotic Talk,</span>"

    for(var/mob/M in GLOB.player_list)
        if(M.binarycheck())
            if(isAI(M))
                var/ai_name_link = is_ai ? "<font size=3><a href='?src=[REF(M)];track=[html_encode(name)]'><b>[name] ([desig])</b></a></font>" : "<a href='?src=[REF(M)];track=[html_encode(name)]'><span class='name'>[name] ([desig])</span></a>"
                to_chat(M, "<span class='binarysay'>[header] [ai_name_link] [rendered_msg]</span>")
            else
                to_chat(M, "<span class='binarysay'>[header] [rendered_name] [rendered_msg]</span>")

        if(isobserver(M))
            var/following = src
            if(is_ai)
                var/mob/living/silicon/ai/ai = src
                following = ai.eyeobj
            var/link = FOLLOW_LINK(M, following)
            to_chat(M, "<span class='binarysay'>[link] [header] [rendered_name] [rendered_msg]</span>")
// (EDIT) Pe4henika bluemoon -- end

/mob/living/silicon/binarycheck()
	return TRUE

/mob/living/silicon/lingcheck()
	return FALSE //Borged or AI'd lings can't speak on the ling channel.

/mob/living/silicon/radio(message, message_mode, list/spans, language)
	. = ..()
	if(. != 0)
		return .

	if(message_mode == "robot")
		if (radio)
			radio.talk_into(src, message, , spans, language)
		return REDUCE_RANGE

	else if(message_mode in GLOB.radiochannels)
		if(radio)
			radio.talk_into(src, message, message_mode, spans, language)
			return ITALICS | REDUCE_RANGE

	return FALSE

/mob/living/silicon/get_message_mode(message)
	. = ..()
	if(..() == MODE_HEADSET)
		return MODE_ROBOT
	else
		return .
