/datum/interaction/cuddle
	description = "Обнимашки!"
	simple_message = "USER обнимает TARGET."
	simple_style = "lewd"
	interaction_flags = INTERACTION_FLAG_ADJACENT
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW_PLUS
	p13user_duration = PLUG13_DURATION_SHORT
	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW_PLUS
	p13target_duration = PLUG13_DURATION_SHORT

/datum/interaction/cuddle/display_interaction(mob/living/user, mob/living/target)
	var/static/list/possible_messages = list(
		"<b>USER</b> обнимает <b>TARGET</b>.",
		"<b>USER</b> страстно обнимает <b>TARGET</b>.",
		"<b>USER</b> нежно обнимает <b>TARGET</b>.",
		"<b>USER</b> бережно обнимает <b>TARGET</b>.",
		"<b>USER</b> тыкается носом в <b>TARGET</b>.",
		"<b>USER</b> нежно тыкается носиком в <b>TARGET</b>.",
		"<b>USER</b> бережно тыкается носиком в <b>TARGET</b>.",
		"<b>USER</b> тискает <b>TARGET</b>.",
		"<b>USER</b> хватает <b>TARGET</b> в свои нежные объятия.",
		"<b>USER</b> нежно тискается с <b>TARGET</b>.",
		"<b>USER</b> бережно тискается с <b>TARGET</b>.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[capitalize(use_message)]</span>")
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)
// BlueMoon Add
/datum/interaction/scratch
	description = "Почесать спину"
	simple_message = "USER чешет спину TARGET."
	simple_style = "lewd"
	interaction_flags = INTERACTION_FLAG_ADJACENT
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW_PLUS
	p13user_duration = PLUG13_DURATION_SHORT
	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW_PLUS
	p13target_duration = PLUG13_DURATION_SHORT

/datum/interaction/scratch/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(target.get_lust() < 100)
		target.add_lust(3)

/datum/interaction/scratch/display_interaction(mob/living/user, mob/living/target)
	var/static/list/possible_messages = list(
		"<b>USER</b> чешет спинку <b>TARGET</b>.",
		"<b>USER</b> расчесываает спинку <b>TARGET</b>.",
		"<b>USER</b> водит ноготочками по спинке вызывая мурашки у <b>TARGET</b>.",
		"<b>USER</b> бережно водит руками по спинке <b>TARGET</b>.",
		"<b>USER</b> нежно разглаживает спинку <b>TARGET</b>.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[capitalize(use_message)]</span>")
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)

/datum/interaction/neckscratch
	description = "Почесать шею"
	simple_message = "USER чешет Шею TARGET."
	simple_style = "lewd"
	interaction_flags = INTERACTION_FLAG_ADJACENT
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW_PLUS
	p13user_duration = PLUG13_DURATION_SHORT
	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW_PLUS
	p13target_duration = PLUG13_DURATION_SHORT

/datum/interaction/neckscratch/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(target.get_lust() < 100)
		target.add_lust(3)

/datum/interaction/neckscratch/display_interaction(mob/living/user, mob/living/target)
	var/static/list/possible_messages = list(
		"<b>USER</b> чешет шею <b>TARGET</b>.",
		"<b>USER</b> расчесываает шейку у <b>TARGET</b>.",
		"<b>USER</b> водит ноготочками по шее вызывая мурашки у <b>TARGET</b>.",
		"<b>USER</b> бережно гладит шею <b>TARGET</b> добавляя слегка ноготочки.",
		"<b>USER</b> нежно разглаживает шею <b>TARGET</b>.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[capitalize(use_message)]</span>")
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)

/datum/interaction/earscratch
	description = "Почесать за ухом"
	simple_message = "USER чешет ухо TARGET."
	simple_style = "lewd"
	interaction_flags = INTERACTION_FLAG_ADJACENT
	required_from_user  = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'

	p13user_emote = PLUG13_EMOTE_BASIC
	p13user_strength = PLUG13_STRENGTH_LOW_PLUS
	p13user_duration = PLUG13_DURATION_SHORT
	p13target_emote = PLUG13_EMOTE_BASIC
	p13target_strength = PLUG13_STRENGTH_LOW_PLUS
	p13target_duration = PLUG13_DURATION_SHORT

/datum/interaction/earscratch/post_interaction(mob/living/user, mob/living/target)
	. = ..()
	if(target.get_lust() < 100)
		target.add_lust(3)

/datum/interaction/earscratch/display_interaction(mob/living/user, mob/living/target)
	var/static/list/possible_messages = list(
		"<b>USER</b> чешет за ушком <b>TARGET</b>.",
		"<b>USER</b> расчесываает за ушком у <b>TARGET</b>.",
		"<b>USER</b> водит ноготочками по краю уха вызывая мурашки у <b>TARGET</b>.",
		"<b>USER</b> бережно гладит ухо <b>TARGET</b> добавляя слегка ноготочки.",
		"<b>USER</b> нежно разглаживает ушко <b>TARGET</b>.",
	)
	var/use_message = replacetext(pick(possible_messages), "USER", "\the [user]")
	use_message = replacetext(use_message, "TARGET", "\the [target]")
	user.visible_message("<span class='[simple_style]'>[capitalize(use_message)]</span>")
	if(!HAS_TRAIT(user, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(user.loc)
	if(!HAS_TRAIT(target, TRAIT_LEWD_JOB))
		new /obj/effect/temp_visual/heart(target.loc)
