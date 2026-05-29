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
/datum/interaction/lewd/slap/display_interaction(mob/living/user, mob/living/target)
	..()
	if(iscatperson(target))
		target.emote(pick("nya","meow")) //W-what are you doing S-senpai? >///<

	if(isclownjob(target))
		if(prob(50))
			target.visible_message("<span class='lewd'>Задница <b>[target]</b> смешно хонкает!</span>")
		playlewdinteractionsound(target, 'sound/items/bikehorn.ogg', 40, 1, -1)
//BLUEMOON ADD END
/datum/interaction/lewd/slap/special_check(mob/living/user, mob/living/target)
	. = ..()
	if(!.)
		return
	if((target.client?.prefs.cit_toggles & NO_ASS_SLAP) && target != user)
		to_chat(user, span_warning("По какой-то причине, вы не можете сделать это с [target]."))
		to_chat(user, span_warning(span_small("Игрок отключил механическую возможность шлепать себя. Попробуйте отыгрывать это через действия.")))
		return FALSE
	if(ishuman(user) && ishuman(target) && HAS_TRAIT(target, TRAIT_STEEL_ASS))
		var/mob/living/carbon/human/human_user = user
		if(prob(10))
			var/obj/item/bodypart/bodypart = human_user.get_active_hand()
			if(istype(bodypart))
				var/datum/wound/blunt/moderate/moderate_wound = new
				moderate_wound.apply_wound(bodypart)
		human_user.adjustStaminaLoss(75)
		human_user.Stun(3 SECONDS)
		human_user.visible_message(\
			span_danger("\The [user] slaps \the [target]'s ass, but their hand bounces off like they hit metal!"),\
			span_danger("You slap [user == target ? "your" : "\the [target]'s"] ass, but feel an intense amount of pain as you realise their buns are harder than steel!"),\
			"You hear a slap."
		)
		var/list/ouchies = list(
			'modular_splurt/sound/effects/pan0.ogg',
			'modular_splurt/sound/effects/pan1.ogg'
		)
		playsound(target.loc, pick(ouchies), 15, 1, -1)
		if(!isrobotic(user))
			user.emote("scream")
		return FALSE

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
