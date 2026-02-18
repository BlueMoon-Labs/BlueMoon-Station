/datum/interaction/lewd/finger
	description = "Пальчики. Поиграться с вагиной."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target_exposed = INTERACTION_REQUIRE_VAGINA
	interaction_sound = null
	p13target_emote = PLUG13_EMOTE_VAGINA
	p13target_strength = PLUG13_STRENGTH_NORMAL

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

/datum/interaction/lewd/finger/display_interaction(mob/living/user, mob/living/partner)
	var/obj/item/reagent_containers/liquid_container

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item

	var/message = "[pick("охотно играется с киской <b>[partner]</b>",
		"играется с киской <b>[partner]</b>",
		"фингерит киску \the <b>[partner]</b>",
		"разрабатывает влагалище <b>[partner]</b>",
		"грубо играется с киской <b>[partner]</b>")]"

	if(!partner.is_fucking(user, CUM_TARGET_HAND, partner.getorganslot(ORGAN_SLOT_VAGINA)))
		partner.set_is_fucking(user, CUM_TARGET_HAND, partner.getorganslot(ORGAN_SLOT_VAGINA))

	if(liquid_container)
		message += " над [liquid_container]"

	user.visible_message(span_lewd("<b>\The [user]</b> [message]."), ignored_mobs = user.get_unconsenting())
	playlewdinteractionsound(get_turf(user), pick('modular_bluemoon/sound/interactions/sfx/fingering01.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering02.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering03.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering04.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering05.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering06.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering07.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering08.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering09.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering10.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering11.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering12.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering13.ogg'), 100, 1, -1)
	partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, liquid_container ? liquid_container : user, ORGAN_SLOT_VAGINA) //SPLURT edit

/datum/interaction/lewd/fingerass
	description = "Пальчики. Поиграться с попкой."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target_exposed = INTERACTION_REQUIRE_ANUS
	p13target_emote = PLUG13_EMOTE_ANUS
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/fingerass/display_interaction(mob/living/user, mob/living/partner)
	user.visible_message("<span class='lewd'><b>\The [user]</b> [pick("погружает палец в сфинктер <b>[partner]</b>.",
		"суёт палец в анальное колечко <b>[partner]</b>.",
		"разрабатывает анальное кольцо <b>[partner]</b> при помощи собственного пальца.")]</span>", ignored_mobs = user.get_unconsenting())
	playlewdinteractionsound(get_turf(user), pick('modular_bluemoon/sound/interactions/sfx/fingering01.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering02.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering03.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering04.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering05.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering06.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering07.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering08.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering09.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering10.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering11.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering12.ogg',
						'modular_bluemoon/sound/interactions/sfx/fingering13.ogg'), 100, 1, -1)
	partner.handle_post_sex(NORMAL_LUST, null, user, ORGAN_SLOT_ANUS) //SPLURT edit
