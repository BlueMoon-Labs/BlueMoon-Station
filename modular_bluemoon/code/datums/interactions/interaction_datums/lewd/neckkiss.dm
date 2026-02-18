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
	user.visible_message("<span class='[simple_style]'>[capitalize(use_message)]</span>")
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)
	playlewdinteractionsound(target, pick(
		'modular_bluemoon/sound/interactions/sfx/kiss1.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss2.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss3.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss4.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss5.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss6.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss7.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss8.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss9.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss10.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss11.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss12.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss13.ogg',
		'modular_bluemoon/sound/interactions/sfx/kiss14.ogg'), 100, 1, -1, ignored_mobs = user.get_unconsenting())
