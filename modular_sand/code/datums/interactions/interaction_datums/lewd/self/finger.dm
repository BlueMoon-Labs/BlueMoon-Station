/datum/interaction/lewd/fingerass_self
	description = "Попа. Поиграться со своей задницей."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_user_exposed = INTERACTION_REQUIRE_ANUS
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "fingered self"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_ANUS
	p13target_strength = PLUG13_STRENGTH_NORMAL

/datum/interaction/lewd/fingerass_self/display_interaction(mob/living/user)

	user.visible_message(span_lewd("<b>\The [user]</b> [pick(
		"погружает палец в свой сфинктер.",
		"суёт палец в своё анальное колечко.",
		"разрабатывает своё анальное кольцо собственного пальца.")]"), ignored_mobs = user.get_unconsenting())
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
	user.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, user, CUM_TARGET_ANUS) //SPLURT edit

/datum/interaction/lewd/finger_self
	description = "Вагина. Поиграться со своей вагиной."
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_user_exposed = INTERACTION_REQUIRE_VAGINA
	interaction_sound = null
	interaction_flags = INTERACTION_FLAG_OOC_CONSENT | INTERACTION_FLAG_USER_IS_TARGET
	max_distance = 0
	write_log_user = "fingered own pussy"
	write_log_target = null
	p13user_emote = PLUG13_EMOTE_VAGINA

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

/datum/interaction/lewd/finger_self/display_interaction(mob/living/user)

	var/obj/item/reagent_containers/liquid_container

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item

	var/message = pick(
		"погружает палец в свою киску",
		"тихо выдыхает и всовывает палец в своё влагалище",
		"играется со своей киской",
		"разрабатывает своё влагалище своим пальчиком")
	if(!user.is_fucking(user, CUM_TARGET_HAND, user.getorganslot(ORGAN_SLOT_VAGINA)))
		user.set_is_fucking(user, CUM_TARGET_HAND, user.getorganslot(ORGAN_SLOT_VAGINA))

	if(liquid_container)
		message += " прямо в [liquid_container]"

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
	user.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, liquid_container ? liquid_container : user, ORGAN_SLOT_VAGINA)
