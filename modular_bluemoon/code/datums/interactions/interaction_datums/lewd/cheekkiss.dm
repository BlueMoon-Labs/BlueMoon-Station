/datum/interaction/cheekkiss
	description = "Поцеловать в щёчку."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	simple_message = "USER целует TARGET в щёчку."
	simple_style = "lewd"
	write_log_user = "kissed"
	write_log_target = "was kissed by"
	interaction_sound = null

	p13user_emote = PLUG13_EMOTE_BASIC
	p13target_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_strength = PLUG13_STRENGTH_LOW

	hearts_effect = TRUE

/datum/interaction/cheekkiss/post_interaction(mob/living/user, mob/living/target, apply_cooldown, is_hidden)
	. = ..()
	if(user.get_lust() < 100)
		user.add_lust(3)
	if(target.get_lust() < 100)
		target.add_lust(3)

/datum/interaction/cheekkiss/display_interaction(mob/living/user, mob/living/target, is_hidden)
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/static/list/possible_messages = list(
		"<b>USER</b> вытянув губы бантиком, целует <b>TARGET</b> в щеку.",
		"<b>USER</b> делает легкое, почти невесомое прикосновение губ к щеке <b>TARGET</b>.",
		"<b>USER</b> губы касаются щеки <b>TARGET</b> и тут же отстраняются.",
		"<b>USER</b> громко с причмокиванием целует <b>TARGET</b> в щеку.",
		"<b>USER</b> тычет губами в щеку <b>TARGET</b> одаривая легким поцелуем.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[is_hidden ? pick(hidden_additional) : null] [capitalize(use_message)]</span>", vision_distance = distance)

	playlewdinteractionsound(get_turf(target), pick(
		'modular_splurt/sound/interactions/kiss/kiss1.ogg',
		'modular_splurt/sound/interactions/kiss/kiss2.ogg',
		'modular_splurt/sound/interactions/kiss/kiss3.ogg',
		'modular_splurt/sound/interactions/kiss/kiss4.ogg',
		'modular_splurt/sound/interactions/kiss/kiss5.ogg'), volume, 1, extrarange, ignored_mobs = user.get_unconsenting())
