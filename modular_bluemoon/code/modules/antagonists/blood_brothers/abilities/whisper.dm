/datum/action/cooldown/blood_bond/whisper
	name = "Шёпот крови"
	desc = "Сказать братьям то, чего не услышит никто, кроме них. Слышно на любом расстоянии; работает и в наручниках, но не без сознания, не под майндшилдом и не в теле без крови, вроде борга."
	bond_how = "Нажать кнопку и написать сообщение."
	button_icon_state = "whisper"
	cooldown_time = 2 SECONDS
	required_mobility_flags = NONE

/datum/action/cooldown/blood_bond/whisper/Activate(atom/target)
	var/mob/living/speaker = owner
	var/message = tgui_input_text(speaker, "Что сказать братьям?", "Шёпот крови", max_length = MAX_MESSAGE_LEN, encode = TRUE)
	message = trim(message)
	if(!message || QDELETED(src) || owner != speaker || !IsAvailable())
		return FALSE
	if(!speaker.can_speak_basic(message))
		return FALSE
	send_whisper(message)
	StartCooldown(bond_cooldown())
	return TRUE

/// Разослать шёпот; возвращает тела братьев, которым он дошёл
/datum/action/cooldown/blood_bond/whisper/proc/send_whisper(message)
	. = list()
	var/datum/team/brother_team/team = brother.team
	var/mob/living/speaker = owner
	var/line = span_cultitalic("<b>[speaker.real_name]</b> (шёпот крови): [message]")
	var/list/heard = list()
	for(var/datum/antagonist/brother/listener as anything in team.brother_antags())
		var/mob/living/body = listener.owner.current
		if(QDELETED(body) || (listener.owner in team.departed_minds) || listener.is_muted())
			continue
		to_chat(body, line)
		. += body
		heard += WEAKREF(listener.owner)
		if(body != speaker)
			body.playsound_local(get_turf(body), 'modular_bluemoon/sound/blood_brothers/brother_whisper.ogg', BROTHER_WHISPER_VOLUME, TRUE, pressure_affected = FALSE)
	team.whisper_log += list(list("name" = speaker.real_name, "text" = html_decode(message), "time" = STATION_TIME_TIMESTAMP("hh:mm", world.time), "heard" = heard))
	if(length(team.whisper_log) > BROTHER_WHISPER_LOG_SIZE)
		team.whisper_log.Cut(1, length(team.whisper_log) - BROTHER_WHISPER_LOG_SIZE + 1)
	if(!team.training)
		var/ghost_line = span_cultitalic("<b>[speaker.real_name]</b> (шёпот крови, [team.name]): [message]")
		for(var/mob/dead/observer/ghost in GLOB.player_list)
			to_chat(ghost, "[FOLLOW_LINK(ghost, speaker)] [ghost_line]")
	speaker.log_talk(message, LOG_SAY, tag = "blood bond")
	team.pulse_bond()
