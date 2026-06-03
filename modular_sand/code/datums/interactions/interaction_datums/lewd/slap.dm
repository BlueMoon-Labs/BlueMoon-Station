/datum/interaction/lewd/slap
	description = "Попа. Шлёпнуть по заднице."
	simple_message = "USER с силой шлёпает задницу TARGET с громким звуком!"
	simple_style = "danger"
	interaction_sound = 'sound/weapons/slap.ogg'
	required_from_user = INTERACTION_REQUIRE_HANDS

	write_log_user = "ass-slapped"
	write_log_target = "was ass-slapped by"
	p13target_emote = PLUG13_EMOTE_ASS
	p13target_strength = PLUG13_STRENGTH_HIGH
	p13target_duration = PLUG13_DURATION_TINY
//BLUEMOON ADD перенос из /datum/interaction/lewd/display_interaction
/datum/interaction/lewd/slap/display_interaction(mob/living/user, mob/living/target, is_hidden)
	. = ..()
	if(iscatperson(target))
		target.emote(pick("nya","meow")) //W-what are you doing S-senpai? >///<

	if(isclownjob(target))
		if(prob(50))
			target.visible_message("<span class='lewd'>Задница <b>[target]</b> смешно хонкает!</span>")
		playlewdinteractionsound(get_turf(target), 'sound/items/bikehorn.ogg', 40, 1, -1)
//BLUEMOON ADD END

/datum/interaction/lewd/grope_ass
	description = "Попа. Полапать задницу."
	simple_message = "USER сжимает задницу TARGET!"
	simple_style = "danger"
	required_from_user = INTERACTION_REQUIRE_HANDS
	interaction_sound = 'sound/weapons/thudswoosh.ogg'
	write_log_user = "ass-gropped"
	write_log_target = "was ass-gropped by"
	p13target_emote = PLUG13_EMOTE_BACK
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/slap_breasts
	description = "Грудь. Шлёпнуть по груди."
	simple_message = "USER с силой шлёпает груди TARGET с громким звуком!"
	simple_style = "danger"
	interaction_sound = 'sound/weapons/slap.ogg'
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target = INTERACTION_REQUIRE_BREASTS

	p13target_emote = PLUG13_EMOTE_BREASTS
	p13target_strength = PLUG13_STRENGTH_HIGH
	p13target_duration = PLUG13_DURATION_TINY
