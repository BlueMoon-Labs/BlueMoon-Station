/**
	# Interactions code by HONKERTRON feat TestUnit
- Contains a lot ammount of ERP and MEHANOYEBLYA
- CREDIT TO ATMTA STATION FOR MOST OF THIS CODE, I ONLY MADE IT WORK IN /vg/ - Matt
- Rewritten 30/08/16 by Zuhayr, sry if I removed anything important.
- I removed ERP and replaced it with handholding. Nothing of worth was lost. - Vic
- Fuck you, Vic. ERP is back. - TT
- >using var/ on everything, also TRUE
- "TGUIzes" the panel because yes - SandPoot
- Makes all the code good because yes as well - SandPoot
**/

/mob/proc/list_interaction_attributes()
	return list()

/mob/living/list_interaction_attributes()
	. = ..()
	if(has_hands())
		. += "...обладает руками."
	if(has_mouth())
		. += "...обладает [mouth_is_free() ? "неприкрытым" : "прикрытым"] ртом."
	// BLUEMOON ADD хвостики!
	if(has_tail())
		. += "...обладает хвостом."
	// BLUEMOON ADD END

/// The base of all interactions
/datum/interaction
	var/description
	var/simple_message
	var/simple_style = "notice"
	var/write_log_user
	var/write_log_target

	var/interaction_sound
	var/interaction_sound_volume = 50

	var/max_distance = 1

	var/interaction_flags = INTERACTION_FLAG_ADJACENT

	var/required_from_user = NONE
	var/required_from_user_exposed = NONE
	var/required_from_user_unexposed = NONE

	var/required_from_target = NONE
	var/required_from_target_exposed = NONE
	var/required_from_target_unexposed = NONE

	var/big_user_target_text = FALSE // BLUEMOON ADD большой текстик для TARGET И USER если TRUE
	var/message_by_user = TRUE /// BLUEMOON ADD Сообщение и звук происходит от user-а? Если нет, то от цели
	/// Additional details to be shown in the interaction menu, accepts more than one entry
	var/list/additional_details

	var/hearts_effect = FALSE

/// Checks if user can do an interaction, action_check is for whether you're actually doing it or not (useful for the menu and not removing the buttons)
/datum/interaction/proc/evaluate_user(mob/living/user, silent = TRUE, apply_cooldown = TRUE)
	if(SSinteractions.is_blacklisted(user))
		return FALSE

	if(required_from_user & INTERACTION_REQUIRE_MOUTH)
		if(!user.has_mouth())
			if(!silent)
				to_chat(user, "<span class='warning'>У вас нет рта.</span>")
			return FALSE

		if(!user.mouth_is_free())
			if(!silent)
				to_chat(user, "<span class='warning'>Ваш рот прикрыт.</span>")
			return FALSE

	if(required_from_user & INTERACTION_REQUIRE_HANDS)
		if(!user.has_hands())
			if(!silent)
				to_chat(user, span_warning("У вас нет рук."))
			return FALSE

	if(COOLDOWN_FINISHED(user, last_interaction_time))
		return TRUE

	if(apply_cooldown)
		return FALSE
	else
		return TRUE

/// Same as evaluate_user, but for target
/datum/interaction/proc/evaluate_target(mob/living/user, mob/living/target, silent = TRUE)
	if(SSinteractions.is_blacklisted(target))
		return FALSE

	if(!(interaction_flags & INTERACTION_FLAG_USER_IS_TARGET))
		if(user == target)
			if(!silent)
				to_chat(user, span_warning("Ты не можешь так поступить с собой."))
			return FALSE

	if(required_from_target & INTERACTION_REQUIRE_MOUTH)
		if(!target.has_mouth())
			if(!silent)
				to_chat(user, span_warning("Цель не имеет рта."))
			return FALSE

		if(!target.mouth_is_free())
			if(!silent)
				to_chat(user, span_warning("Рот цели прикрыт."))
			return FALSE

	if(required_from_target & INTERACTION_REQUIRE_HANDS)
		if(!target.has_hands())
			if(!silent)
				to_chat(user, span_warning("Цель не имеет рук."))
			return FALSE

	return TRUE

/// Actually doing the action, has a few checks to see if it's valid, usually overwritten to be make things actually happen and what-not
/datum/interaction/proc/do_action(mob/living/user, mob/living/target, apply_cooldown = TRUE , is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(target))
		return FALSE
	if(!(interaction_flags & INTERACTION_FLAG_USER_IS_TARGET))
		if(user == target) //tactical href fix
			to_chat(user, span_warning("Ты не можешь нацелиться на себя."))
			return FALSE
	if(get_dist(user, target) > max_distance)
		to_chat(user, span_warning("Слишком далеко."))
		return FALSE
	if(interaction_flags & INTERACTION_FLAG_ADJACENT && !(user.Adjacent(target) && target.Adjacent(user) || isbelly(user.loc) && user.loc:owner == target || isbelly(target.loc) && target.loc:owner == user)) // BLUEMOON EDIT can interact if in belly
		to_chat(user, span_warning("Ты не достаёшь."))
		return FALSE
	if(!evaluate_user(user, silent = FALSE, apply_cooldown = apply_cooldown))
		return FALSE
	if(!evaluate_target(user, target, silent = FALSE))
		return FALSE

	// BLUEMOON ADD START - специальные проверки от БМ
	if(!special_check(user, target))
		return
	// BLUEMOON ADD END

	if(QDELETED(user) || QDELETED(target))
		return FALSE

	if(write_log_user)
		user.log_message("[write_log_user] [target]", LOG_ATTACK)
	if(write_log_target)
		target.log_message("[write_log_target] [user]", LOG_VICTIM, log_globally = FALSE)
	display_interaction(user, target, is_hidden)
	post_interaction(user, target, apply_cooldown, is_hidden)
	return TRUE

/// Display the message
/datum/interaction/proc/display_interaction(mob/living/user, mob/living/target, is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(target))
		return
	var/vision_distance = 7
	var/hidden_message
	if(is_hidden)
		vision_distance = 1
		hidden_message = pick(hidden_additional)

	if(simple_message)
		var/use_message = replacetext(simple_message, "USER", big_user_target_text ? "<b>\the [user]</b>" : "\the [user]") // BLUEMOON ADD большой текст
		use_message = replacetext(use_message, "TARGET", big_user_target_text ? "<b>\the [target]</b>" : "\the [target]") // BLUEMOON ADD большой текст
		if(message_by_user)
			user.visible_message("<span class='[simple_style]'>[hidden_message][capitalize(use_message)]</span>" , null, null, vision_distance)
		else
			target.visible_message("<span class='[simple_style]'>[hidden_message][capitalize(use_message)]</span>" , null, null, vision_distance)

/// After the interaction, the base only plays the sound and only if it has one
/datum/interaction/proc/post_interaction(mob/living/user, mob/living/target, apply_cooldown = TRUE, is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(target))
		return
	if(apply_cooldown)
		COOLDOWN_START(user, last_interaction_time, 0.5 SECONDS)
	if(interaction_sound)
		var/soundfile_to_play

		// pickweight so you can make a certain sound play
		// more times. This does NOT mean you are forced to
		// use the system. If you do not make the list
		// associative, all options will have the same chances!
		if(islist(interaction_sound))
			soundfile_to_play = pickweight(interaction_sound)
		else
			soundfile_to_play = interaction_sound

		play_interaction_sound(message_by_user ? user : target, soundfile_to_play, is_hidden)

	// PLUG 13 INTEGRATION from modular_bluemoon\code\modules\plug13_integration\bluemoon_interaction.dm
	if (p13user_emote && p13user_strength && p13user_duration)
		user.client?.plug13?.send_emote(
			p13user_emote,
			clamp(p13user_strength + get_lust_modifier(user), 10, 100),
			p13user_duration
		)

	if (p13target_emote && p13target_strength && p13target_duration)
		target.client?.plug13?.send_emote(
			p13target_emote,
			clamp(p13target_strength + get_lust_modifier(target), 10, 100),
			p13target_duration
		)

	if(interaction_flags & INTERACTION_FLAG_ADJACENT && user != target)
		SEND_SIGNAL(user, COMSIG_INTERACTION_ADJACENT, target)
		SEND_SIGNAL(target, COMSIG_INTERACTION_ADJACENT, user)

	if(hearts_effect)
		if(!HAS_TRAIT(user, TRAIT_LEWD_JOB) && !is_hidden)
			new /obj/effect/temp_visual/heart(user.loc)
		if(user != target && !HAS_TRAIT(target, TRAIT_LEWD_JOB) && !is_hidden)
			new /obj/effect/temp_visual/heart(target.loc)

/datum/interaction/proc/play_interaction_sound(mob/living/sound_source, soundin, is_hidden, volume)
	var/turf/sound_turf = get_turf(sound_source)
	if(!sound_turf)
		return
	if(!isnum(volume))
		volume = interaction_sound_volume
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	if(interaction_flags & INTERACTION_FLAG_OOC_CONSENT)
		var/list/ignored_mobs
		if(interaction_flags & INTERACTION_FLAG_UNHOLY_CONTENT)
			ignored_mobs = sound_source.get_unconsenting(unholy = TRUE)
		else if(interaction_flags & INTERACTION_FLAG_UNHOLY_HARD)
			ignored_mobs = sound_source.get_unconsenting(unholy_hard = TRUE)
		playlewdinteractionsound(sound_turf, soundin, volume, 1, extrarange, ignored_mobs = ignored_mobs)
	else
		playsound(sound_turf, soundin, volume, 1, extrarange)

/datum/interaction/cheer/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
    if(user.ckey == "pingvas")
        if(apply_cooldown)
            COOLDOWN_START(user, last_interaction_time, 3 SECONDS)
        playsound(get_turf(user), 'modular_bluemoon/sound/plush/milp7.ogg', 50, FALSE, -1)
        return
    . = ..()

/datum/interaction/lewd/titgrope_self/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
    if(user.ckey == "dimakr" || user.ckey == "pingvas")
        if(apply_cooldown)
            COOLDOWN_START(user, last_interaction_time, 3 SECONDS)
        playsound(get_turf(user), 'modular_bluemoon/sound/plush/milp6.ogg', 50, FALSE, -1)
        return
    . = ..()

/datum/interaction/handwave/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
	var/obj/item/clothing/mask/screammask/mask = locate() in user.get_equipped_items()
	if(mask)
		if(apply_cooldown)
			COOLDOWN_START(user, last_interaction_time, 3 SECONDS)
		var/soundfile_to_play = pick('modular_bluemoon/sound/interactions/chuv2.ogg', 'modular_bluemoon/sound/interactions/chuv3.ogg')
		playsound(get_turf(user), soundfile_to_play, 80, FALSE, -1)
		return
	. = ..()
