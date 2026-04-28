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
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)

	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null] <b>\The [user]</b> [pick(
		"погружает палец в свой сфинктер.",
		"суёт палец в своё анальное колечко.",
		"разрабатывает своё анальное кольцо собственного пальца.")]"), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', volume, 1, -1)
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
	var/is_hidden = ..()
	var/distance = 7
	var/volume = 50
	if(is_hidden)
		distance = 1
		volume = sound_quiet_volume
	var/picked_hidden = pick(hidden_additional)
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

	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null] <b>\The [user]</b> [message]."), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	playlewdinteractionsound(get_turf(user), 'modular_sand/sound/interactions/champ_fingering.ogg', volume, 1, -1)
	user.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, liquid_container ? liquid_container : user, ORGAN_SLOT_VAGINA)
