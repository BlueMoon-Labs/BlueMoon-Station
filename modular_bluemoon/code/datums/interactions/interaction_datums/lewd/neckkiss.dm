/datum/interaction/lewd/neckkiss
	description = "Поцеловать шею."
	required_from_user = INTERACTION_REQUIRE_MOUTH
	simple_message = "USER целует шею TARGET."
	simple_style = "lewd"
	write_log_user = "kissed"
	write_log_target = "was kissed by"
	interaction_sound = null

	p13user_emote = PLUG13_EMOTE_BASIC
	p13target_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW
	p13target_strength = PLUG13_STRENGTH_LOW

/datum/interaction/lewd/neckkiss/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(user.get_lust() < 100)
		user.add_lust(20)
	if(target.get_lust() < 100)
		target.add_lust(20)

/datum/interaction/lewd/neckkiss/display_interaction(mob/living/user, mob/living/target)
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)
	var/static/list/possible_messages = list(
		"<b>USER</b> подтягивая к себе за плечи, прижимается к <b>TARGET</b> и целует в шею.",
		"<b>USER</b> смочив губы языком, целует шею <b>TARGET</b> прикусив её зубами.",
		"<b>USER</b> водит носом по шее, медленно целуя <b>TARGET</b> возле уха.",
		"<b>USER</b> медленно посасывает шею <b>TARGET</b> оставляя синяк от засоса.",
		"<b>USER</b> нежно прикусываетт кожу на шее <b>TARGET</b> оттягивая её зубами.",
		"<b>USER</b> страстно прижимается губами к шее <b>TARGET</b> оставляя синяк от засоса.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[is_hidden ? (picked_hidden) : null] [capitalize(use_message)]</span>", vision_distance = distance)

	playlewdinteractionsound(target, pick(
		'modular_splurt/sound/interactions/kiss/kiss1.ogg',
		'modular_splurt/sound/interactions/kiss/kiss2.ogg',
		'modular_splurt/sound/interactions/kiss/kiss3.ogg',
		'modular_splurt/sound/interactions/kiss/kiss4.ogg',
		'modular_splurt/sound/interactions/kiss/kiss5.ogg'), volume, 1, -1, ignored_mobs = user.get_unconsenting())
