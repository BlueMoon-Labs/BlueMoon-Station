// ⡆⣐⢕⢕⢕⢕⢕⢕⢕⢕⠅⢗⢕⢕⢕⢕⢕⢕⢕⠕⠕⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢐⢕⢕⢕⢕⢕⣕⢕⢕⠕⠁⢕⢕⢕⢕⢕⢕⢕⢕⠅⡄⢕⢕⢕⢕⢕⢕⢕⢕⢕
// ⢕⢕⢕⢕⢕⠅⢗⢕⠕⣠⠄⣗⢕⢕⠕⢕⢕⢕⠕⢠⣿⠐⢕⢕⢕⠑⢕⢕⠵⢕
// ⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
// ⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
// ⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
// ⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
// ⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
// ⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
// ⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
// ⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
// ⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
// ⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
// ⣿⣦⡀⣿⣿⣷⣶⣬⣍⣛⣛⣛⡛⠿⠿⠿⠛⠛⢛⣛⣉⣭⣤⣂⢜⠕⢑⣡⣴⣿

//The code execution of the emote datum is located at code/datums/emotes.dm
/// Makes the mob to run the specified emote.
/// * `act` - emote key (for example `emote("sigh")`).
/// * `m_type` - type override for the emote. See `EMOTE_VISIBLE`, `EMOTE_AUDIBLE`, etc.
/// * `message` - "param"[eter] for the emote. Mainly used in /me emotes, i.e. `L.emote("me", 1, "nibbles away at \the [parent]")`.
/// Also can be used in "blows a kiss to %t" kinda emotes, where it replaces "%t".
/// * `intentional` - whether this emote is triggered by the mob themselves (`TRUE`) or forced by game mechanics (`FALSE`).
/// * `message_override` - if set to some string, will replace the emote message with the provided string. If `message` is used,
/// this string can contain `%t`, which will be replaced with `message`.
/mob/proc/emote(act, m_type = null, message = null, intentional = FALSE, message_override = null)
	if(HAS_TRAIT_FROM(src, TRAIT_MUTE, TIMESTOP_TRAIT)) //запрещаю эмоутить в таймстопе
		return
	if(!act)
		return
	act = lowertext(act)
	var/param = message
	var/custom_param = findchar(act, " ")
	if(custom_param)
		param = copytext(act, custom_param + length(act[custom_param]))
		act = copytext(act, 1, custom_param)
	if(!intentional && (act == "scream" || act == "pain" || act == "realagony") && HAS_TRAIT(src, TRAIT_SUPPRESS_PAIN_EMOTES))
		return

	var/list/key_emotes = GLOB.emote_list[act]
	for(var/datum/emote/emote in key_emotes)
		if(!emote.can_run_emote(src, TRUE, intentional, param))
			continue
		if(emote.run_emote(src, param, m_type, intentional, message_override))
			SEND_SIGNAL(src, COMSIG_MOB_EMOTE, emote, act, m_type, message, intentional, message_override)
			return TRUE
	if(!key_emotes)
		to_chat(src, span_notice("Unusable emote '[act]'. Say *help for a list."))
		return

/mob/living/carbon/human
	var/acrobatic_stunts_count = 0
	COOLDOWN_DECLARE(acrobatic_dizziness_timer)

/mob/living/carbon/human/proc/handle_acrobatic_dizziness()
	if(TIMER_COOLDOWN_CHECK(src, "acrobatic_dizziness_invulnerability"))
		return
	if(COOLDOWN_FINISHED(src, acrobatic_dizziness_timer))
		acrobatic_stunts_count = 0
	COOLDOWN_START(src, acrobatic_dizziness_timer, (HAS_TRAIT(src, TRAIT_FREERUNNING) ? 1 : 2.5) SECONDS)
	acrobatic_stunts_count++
	if(acrobatic_stunts_count < 3)
		return

	COOLDOWN_RESET(src, acrobatic_dizziness_timer) // сбрасываем время = эффективно сбрасываем и acrobatic_stunts_count при следующем кувырке
	TIMER_COOLDOWN_START(src, "acrobatic_dizziness_invulnerability", 10 SECONDS)
	to_chat(src, span_warning("От частых кувырков у вас закружилась голова и подступила тошнота."))
	Dizzy(30)
	Jitter(20)
	add_movespeed_modifier(/datum/movespeed_modifier/acrobatic_dizzy)
	addtimer(CALLBACK(src, PROC_REF(remove_movespeed_modifier), "/datum/movespeed_modifier/acrobatic_dizzy"), 10 SECONDS)

/datum/movespeed_modifier/acrobatic_dizzy
	multiplicative_slowdown = 1.5

/datum/emote/flip
	name = "Сделать Кувырок"
	key = "flip"
	key_third_person = "flips"
	restraint_check = TRUE
	mob_type_allowed_typecache = list(/mob/living, /mob/dead/observer)
	mob_type_ignore_stat_typecache = list(/mob/dead/observer)

/datum/emote/flip/can_run_emote(mob/user, status_check = TRUE, intentional = FALSE)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_MOD_INVERTED))
		return FALSE

/datum/emote/flip/run_emote(mob/user, params, type_override, intentional = FALSE, message_override = null)
	. = ..()
	if(!.)
		return

	user.SpinAnimation(7,1)
	if(ishuman(user) && intentional)
		var/mob/living/carbon/human/H = user
		H.handle_acrobatic_dizziness()

/datum/emote/spin
	key = "spin"
	key_third_person = "spins"
	restraint_check = TRUE
	mob_type_allowed_typecache = list(/mob/living, /mob/dead/observer)
	mob_type_ignore_stat_typecache = list(/mob/dead/observer)

/datum/emote/spin/run_emote(mob/user, params, type_override, intentional = FALSE, message_override = null)
	. = ..()
	if(!.)
		return

	user.spin(20, 1)
	if(ishuman(user) && intentional)
		var/mob/living/carbon/human/H = user
		H.handle_acrobatic_dizziness()

	if(iscyborg(user))
		var/mob/living/silicon/robot/R = user
		if(R.hat)
			R.hat.forceMove(get_turf(user))
			R.hat = null

		if(user.has_buckled_mobs())
			var/datum/component/riding/riding_datum = R.GetComponent(/datum/component/riding)
			if(riding_datum)
				for(var/mob/M in R.buckled_mobs)
					riding_datum.force_dismount(M)
			else
				R.unbuckle_all_mobs()

