/datum/interaction/lewd/handjob
	description = "Рука. Подрочить."
	interaction_sound = null
	required_from_user = INTERACTION_REQUIRE_HANDS
	required_from_target_exposed = INTERACTION_REQUIRE_PENIS
	p13target_emote = PLUG13_EMOTE_PENIS

	additional_details = list(
		INTERACTION_FILLS_CONTAINERS
	)

/datum/interaction/lewd/handjob/display_interaction(mob/living/user, mob/living/partner, is_hidden)
	var/distance = 7
	var/extrarange = DEFAULT_INTERACTION_SOUND_EXTRARANGE(is_hidden)
	var/const/volume = 70
	if(is_hidden)
		distance = 1
	var/picked_hidden = pick(hidden_additional)
	var/message
	//var/genital_name = partner.get_penetrating_genital_name() - стал не нужен.

	var/obj/item/reagent_containers/liquid_container
	var/shape_desc = get_penis_shape_desc(user) //  Описания каким органом ты трахаешь // BlueMoon Add

	var/obj/item/cached_item = user.get_active_held_item()
	if(istype(cached_item, /obj/item/reagent_containers))
		liquid_container = cached_item
	else
		cached_item = user.pulling
		if(istype(cached_item, /obj/item/reagent_containers))
			liquid_container = cached_item

	if(!partner.is_fucking(user, CUM_TARGET_HAND, partner.getorganslot(ORGAN_SLOT_PENIS)))
		partner.set_is_fucking(user, CUM_TARGET_HAND, partner.getorganslot(ORGAN_SLOT_PENIS))
	var/dirty_user = user.wants_dirty_text()
	var/dirty_partner = partner.wants_dirty_text()
	if(dirty_user || dirty_partner)
		message = replacetext(pick(GLOB.dirty_handjob_messages), "$PARTNER", "\the <b>[partner]</b>")
	else
		message = "[pick("дрочит пенис <b>[partner]</b>",
			"играется с членом <b>[partner]</b>",
			"использует свои пальчики, вздрачивая пенис <b>[partner]</b>",
			"вздрачивает член <b>[partner]</b>",
			"стимулирует [shape_desc] <b>[partner]</b>")]"

	if(liquid_container)
		message += " над [liquid_container]"

	playlewdinteractionsound(get_turf(user), pick('modular_sand/sound/interactions/bang1.ogg',
						'modular_sand/sound/interactions/bang2.ogg',
						'modular_sand/sound/interactions/bang3.ogg'), volume, 1, extrarange)
	user.visible_message(span_lewd("[is_hidden ? (picked_hidden) : null]<b>\The [user]</b> [message]."), ignored_mobs = user.get_unconsenting(), vision_distance = distance)
	if(partner.can_penetrating_genital_cum())
		partner.handle_post_sex(NORMAL_LUST, CUM_TARGET_HAND, liquid_container ? liquid_container : user, ORGAN_SLOT_PENIS) //SPLURT edit
