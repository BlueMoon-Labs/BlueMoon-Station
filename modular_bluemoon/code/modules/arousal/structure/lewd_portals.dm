/*
 * Портал с двумя решимами работы GLORYHOLE и WALLSTUCK
 * GLORYHOLE моб пристёгивается к порталу. У исходного моба гениталии
 * скрываются (hide_penis) а на связанном портале создаётся
 * /obj/lewd_portal_relay который показывает только член и яйца (penis_only)
 * (ABOVE_MOB_LAYER) чтобы яйца не перекрывали член.
 *
 * WALLSTUCK моб входит в стену. На исходном портале остаётся
 * только голова (head_only + TRAIT_HUMAN_NO_RENDER), а релей показывает
 * нижнюю часть тела (lower_body_only) ноги, обувь, форму, торс, хвост
 * и гениталии.
 *
 * Релей копирует overlays_standing моба через add_relay_overlay() на слои
 * вокруг ABOVE_MOB_LAYER
 *
 * Коммуникационный мост релей несёт флаг HEAR_1 и через
 * COMSIG_ATOM_HEARER_IN_VIEW добавляет владельца в hearers (как у дуллахантов),
 * поэтому любой сей/шепот/сабтлер рядом с релеем доходит до владельца, а речь
 * и subtler владельца ретранслируются у релея (COMSIG_MOB_SAY / COMSIG_MOB_EMOTE).
 *
 * Местами код может показаться проклятым, трогайте на свой страх и риск.
 */

#define GLORYHOLE "gloryhole"
#define WALLSTUCK "wallstuck"

/// релей интеракты, убирает требование к дистанции
/proc/is_lewd_portal_relay_interaction(mob/user, mob/target)
	if(!istype(user) || !istype(target))
		return FALSE
	for(var/obj/lewd_portal_relay/R in range(1, user))
		if(R.owner == target)
			return TRUE
	return FALSE

/// АЛЬФА МАСКА КОТОРАЯ СКРЫВАЕТ ЧАСТЬ ТЕЛА
/proc/build_top_hide_mask(fraction)
	var/static/icon/white_canvas = icon('icons/effects/alphacolors.dmi')
	var/icon/mask = new(white_canvas)
	var/size = world.icon_size
	var/cut = round(fraction * size)
	mask.DrawBox(null, 1, size - cut + 1, size, size)
	return mask

/obj/structure/lewd_portal
	name = "LustWish Portal"
	desc = "Портал, сквозь который человек может пролезть лишь частично."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_portals.dmi'
	icon_state = "portal"
	can_buckle = TRUE
	anchored = TRUE
	max_buckled_mobs = 1
	buckle_lying = 0
	buckle_prevents_pull = TRUE
	var/mob/living/carbon/human/current_mob = null
	var/portal_mode = GLORYHOLE
	var/obj/structure/lewd_portal/linked_portal
	var/obj/lewd_portal_relay/relayed_body
	var/mob_scale_y = 1
	var/wallstuck_offset_amount = 12
	var/mob_is_immobilized = FALSE
	var/locked_dir = SOUTH

/obj/structure/lewd_portal/Initialize(mapload)
	LAZYINITLIST(buckled_mobs)
	. = ..()

/obj/structure/lewd_portal/Destroy()
	visible_message("[src] исчезает!")
	linked_portal?.linked_portal = null
	if(linked_portal)
		qdel(linked_portal)
	return ..()

/obj/structure/lewd_portal/examine(mob/user)
	. = ..()
	var/inspect_mode = "gloryhole"
	if(portal_mode == WALLSTUCK)
		inspect_mode = "застрял в стене"
	. += span_notice("Сейчас он в режиме «[inspect_mode]».")
	. += span_notice("Alt+Click, чтобы сменить режим.")

/obj/structure/lewd_portal/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(M.client?.prefs?.erppref != "Yes")
		to_chat(user, span_danger("Похоже, [M] не хочет этого."))
		return FALSE
	if (!ishuman(M))
		balloon_alert(user, "[M.p_they()] не помещается!")
		return FALSE
	if(portal_mode == GLORYHOLE)
		var/mob/living/carbon/human/penis_inspection = M
		if(!penis_inspection.has_penis())
			balloon_alert(user, "требуется член!")
			return FALSE
	if (!linked_portal)
		balloon_alert(user, "портал не связан!")
		return FALSE
	if (!isnull(linked_portal.current_mob))
		balloon_alert(user, "портал уже занят!")
		return FALSE
	. = ..(M, user, check_loc = FALSE)
	if(.)
		visible_message("[user] вставляет [M] в [src]!")

/obj/structure/lewd_portal/post_buckle_mob(mob/living/buckled_mob)
	if (!ishuman(buckled_mob))
		return
	if(LAZYLEN(buckled_mobs))
		if(ishuman(buckled_mobs[1]))
			current_mob = buckled_mobs[1]
			mob_scale_y = current_mob.transform.e
			offset_algorithm()

	if(!isnull(current_mob) && !isnull(current_mob.dna?.species) && !isnull(linked_portal))
		relayed_body = new /obj/lewd_portal_relay(linked_portal.loc, current_mob, linked_portal)
		relayed_body.transform = relayed_body.transform.Scale(current_mob.transform.a, current_mob.transform.e)
		switch(linked_portal.dir)
			if(NORTH)
				relayed_body.pixel_y = 24
				if(portal_mode == GLORYHOLE)
					relayed_body.pixel_y += 3
			if(SOUTH)
				relayed_body.pixel_y = -24
				relayed_body.transform = turn(relayed_body.transform, 180)
				if(portal_mode == GLORYHOLE)
					relayed_body.pixel_y -= 3
			if(EAST)
				relayed_body.pixel_x = 24
				if(portal_mode == WALLSTUCK)
					relayed_body.transform = turn(relayed_body.transform, 90)
				else
					relayed_body.pixel_y = 7
			if(WEST)
				relayed_body.pixel_x = -24
				if(portal_mode == WALLSTUCK)
					relayed_body.transform = turn(relayed_body.transform, -90)
				else
					relayed_body.pixel_y = 7
		relayed_body.update_visuals()
		if(portal_mode == WALLSTUCK)
			relayed_body.filters += filter(type = "alpha", icon = build_top_hide_mask(0.4))
		if(portal_mode == GLORYHOLE)
			hide_penis()
			RegisterSignals(current_mob, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_UPDATE_GENITALS), PROC_REF(hide_penis))
			current_mob.dir = dir
			lock_mob_in_place(current_mob, dir)
			switch(dir)
				if(NORTH)
					current_mob.pixel_y += 24
				if(SOUTH)
					current_mob.pixel_y += -6
				if(EAST)
					current_mob.pixel_x += 12
				if(WEST)
					current_mob.pixel_x += -12
		else
			current_mob.dir = SOUTH
			head_only()
			RegisterSignals(current_mob, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_UPDATE_GENITALS), PROC_REF(head_only))
			lock_mob_in_place(current_mob, SOUTH)
			switch(dir)
				if(NORTH)
					current_mob.pixel_y += wallstuck_offset_amount
				if(SOUTH)
					current_mob.pixel_y += -wallstuck_offset_amount
					current_mob.transform = turn(current_mob.transform, 180)
				if(EAST)
					current_mob.pixel_x += wallstuck_offset_amount
					current_mob.transform = turn(current_mob.transform, 90)
				if(WEST)
					current_mob.pixel_x += -wallstuck_offset_amount
					current_mob.transform = turn(current_mob.transform, -90)
	else
		unbuckle_all_mobs()
	..()

/obj/structure/lewd_portal/proc/offset_algorithm()
	if(mob_scale_y <= 1)
		wallstuck_offset_amount = (-30 * mob_scale_y) + 42
	else
		wallstuck_offset_amount = (-24 * mob_scale_y) + 36
	wallstuck_offset_amount = clamp(round(wallstuck_offset_amount), 0, 18)

/obj/structure/lewd_portal/proc/head_only()
	SIGNAL_HANDLER
	if(!current_mob)
		return
	ADD_TRAIT(current_mob, TRAIT_HUMAN_NO_RENDER, "lewd_portal")
	current_mob.cut_overlays()
	current_mob.overlays = list()
	current_mob.update_body_parts_head_only()
	current_mob.remove_overlay(BODY_LAYER)
	current_mob.remove_overlay(HANDS_LAYER)
	current_mob.apply_overlay(BODY_ADJ_LAYER)
	current_mob.apply_overlay(BODY_FRONT_LAYER)
	current_mob.apply_overlay(HORNS_LAYER)

/// фиксируем куклу на месте
/obj/structure/lewd_portal/proc/lock_mob_in_place(mob/living/M, fixed_dir)
	mob_is_immobilized = M.AmountImmobilized()
	locked_dir = fixed_dir
	M.Immobilize(INFINITY, ignore_canstun = TRUE)
	M.setDir(fixed_dir)
	RegisterSignal(M, COMSIG_ATOM_DIR_AFTER_CHANGE, PROC_REF(force_rotate_mob))
	ADD_TRAIT(M, TRAIT_NO_PIXEL_SHIFT, REF(src))
	ADD_TRAIT(M, TRAIT_LIVING_NO_DENSITY, REF(src))
	M.unpixel_shift()
	M.update_density()

/obj/structure/lewd_portal/proc/force_rotate_mob(mob/living/M)
	SIGNAL_HANDLER
	if(QDELETED(M) || M != current_mob)
		UnregisterSignal(M, COMSIG_ATOM_DIR_AFTER_CHANGE)
		return
	if(M.dir != locked_dir)
		M.setDir(locked_dir)

/obj/structure/lewd_portal/proc/hide_penis()
	SIGNAL_HANDLER
	if(!current_mob)
		return
	var/list/keep_overlays = list()
	var/static/list/genital_layers = list(GENITALS_FRONT_LAYER, GENITALS_BEHIND_LAYER, GENITALS_EXPOSED_LAYER)
	for(var/layer in genital_layers)
		for(var/image/I in current_mob.overlays_standing[layer])
			if(!istext(I.icon_state) || (findtext(I.icon_state, "penis_") != 1 && findtext(I.icon_state, "testicles_") != 1))
				keep_overlays += I
	for(var/layer in genital_layers)
		current_mob.remove_overlay(layer)
	for(var/image/I in keep_overlays)
		current_mob.add_overlay(I)

/obj/structure/lewd_portal/post_unbuckle_mob(mob/living/unbuckled_mob)
	UnregisterSignal(unbuckled_mob, list(COMSIG_ATOM_DIR_AFTER_CHANGE, COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_UPDATE_GENITALS))
	REMOVE_TRAIT(unbuckled_mob, TRAIT_HUMAN_NO_RENDER, "lewd_portal")
	REMOVE_TRAIT(unbuckled_mob, TRAIT_NO_PIXEL_SHIFT, REF(src))
	REMOVE_TRAIT(unbuckled_mob, TRAIT_LIVING_NO_DENSITY, REF(src))
	unbuckled_mob.SetImmobilized(mob_is_immobilized, ignore_canstun = TRUE)
	unbuckled_mob.update_density()
	mob_is_immobilized = FALSE
	visible_message("[unbuckled_mob] вылезает из [src]")
	current_mob = null
	mob_scale_y = 1
	QDEL_NULL(relayed_body)
	unbuckled_mob.cut_overlays()
	unbuckled_mob.overlays = list()
	unbuckled_mob.regenerate_icons()
	var/offset_amount = 24
	if(portal_mode == WALLSTUCK)
		offset_amount = wallstuck_offset_amount
	wallstuck_offset_amount = 12
	switch(dir)
		if(NORTH)
			unbuckled_mob.pixel_y -= offset_amount
		if(SOUTH)
			if(portal_mode == WALLSTUCK)
				unbuckled_mob.pixel_y += offset_amount
				unbuckled_mob.transform = turn(unbuckled_mob.transform, 180)
			else
				unbuckled_mob.pixel_y += 6
		if(EAST)
			if(portal_mode == WALLSTUCK)
				unbuckled_mob.pixel_x -= offset_amount
				unbuckled_mob.transform = turn(unbuckled_mob.transform, -90)
			else
				unbuckled_mob.pixel_x -= 12
		if(WEST)
			if(portal_mode == WALLSTUCK)
				unbuckled_mob.pixel_x += offset_amount
				unbuckled_mob.transform = turn(unbuckled_mob.transform, 90)
			else
				unbuckled_mob.pixel_x += 12
	. = ..()

/obj/structure/lewd_portal/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(isnull(linked_portal))
		balloon_alert(user, "портал не связан")
		return
	if(!isnull(current_mob) || !isnull(linked_portal.current_mob))
		balloon_alert(user, "портал занят")
		return
	if(portal_mode == GLORYHOLE)
		portal_mode = WALLSTUCK
		linked_portal.portal_mode = WALLSTUCK
		balloon_alert(user, "включён режим «застревания в стене»")
	else
		portal_mode = GLORYHOLE
		linked_portal.portal_mode = GLORYHOLE
		balloon_alert(user, "включён режим глорихолл")

/obj/structure/lewd_portal/wrench_act(mob/living/user, obj/item/I)
	..()
	I.play_tool_sound(src)
	deconstruct(disassembled = TRUE)
	return TRUE


/obj/item/wallframe/lewd_portal
	name = "Lustwish Portal Bore"
	desc = "Устройство, использующее блюспейс-технологию для переноса частей тела из одного пространства в другое."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_portals.dmi'
	icon_state = "device"
	result_path = /obj/structure/lewd_portal
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 5, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 5)
	pixel_shift = 32
	var/portal_uses = 2
	var/creation_mode = GLORYHOLE
	var/obj/structure/lewd_portal/previous_portal

/obj/item/wallframe/lewd_portal/Destroy(force)
	if(previous_portal)
		UnregisterSignal(previous_portal, COMSIG_PARENT_QDELETING)
		previous_portal = null
	return ..()

/// Обнуляет ссылку на сохранённый портал, если его снесли до установки пары.
/obj/item/wallframe/lewd_portal/proc/on_previous_portal_qdel(datum/source)
	SIGNAL_HANDLER
	previous_portal = null

/obj/item/wallframe/lewd_portal/examine(mob/user)
	. = ..()
	var/inspect_mode = "gloryhole"
	if(creation_mode == WALLSTUCK)
		inspect_mode = "застрял в стене"
	. += span_notice("Сейчас он в режиме «[inspect_mode]».")
	. += span_notice("Используйте в руке, чтобы сменить режим.")

/obj/item/wallframe/lewd_portal/try_build(turf/on_wall, mob/user)
	if(get_dist(on_wall, user) > 1)
		return
	var/ndir = get_dir(on_wall, user)
	if(!(ndir in GLOB.cardinals))
		return
	var/turf/T = get_turf(user)
	if(!isfloorturf(T))
		to_chat(user, span_warning("Вы не можете разместить [src] в этом месте!"))
		return
	return TRUE

/obj/item/wallframe/lewd_portal/attach(turf/on_wall, mob/user, params)
	if(result_path)
		playsound(src.loc, 'sound/machines/click.ogg', 75, TRUE)
		user.visible_message("[user.name] прикрепляет [src] к стене.",
			span_notice("Вы прикрепляете [src] к стене."),
			span_italics("Вы слышите щелчок."))
		var/ndir = get_dir(user, on_wall)

		var/obj/structure/lewd_portal/O = new result_path(get_turf(user))
		O.dir = ndir
		if(pixel_shift)
			switch(ndir)
				if(NORTH)
					O.pixel_y = pixel_shift
				if(SOUTH)
					O.pixel_y = -pixel_shift
				if(EAST)
					O.pixel_x = pixel_shift
				if(WEST)
					O.pixel_x = -pixel_shift
		after_attach(O)

	portal_uses--
	if(portal_uses <= 0)
		qdel(src)

/obj/item/wallframe/lewd_portal/after_attach(obj/attached_to)
	var/obj/structure/lewd_portal/portal_result = attached_to
	portal_result.portal_mode = creation_mode
	if(!previous_portal || QDELETED(previous_portal))
		if(previous_portal)
			UnregisterSignal(previous_portal, COMSIG_PARENT_QDELETING)
		previous_portal = portal_result
		RegisterSignal(previous_portal, COMSIG_PARENT_QDELETING, PROC_REF(on_previous_portal_qdel))
	else
		portal_result.linked_portal = previous_portal
		previous_portal.linked_portal = portal_result
		UnregisterSignal(previous_portal, COMSIG_PARENT_QDELETING)
		previous_portal = null
	. = ..()

/obj/item/wallframe/lewd_portal/attack_self(mob/user)
	if(previous_portal)
		balloon_alert(user, "порталы должны совпадать")
		return
	if(creation_mode == GLORYHOLE)
		creation_mode = WALLSTUCK
		balloon_alert(user, "включён режим «застревания в стене»")
	else
		creation_mode = GLORYHOLE
		balloon_alert(user, "включён режим глорихолл")

/obj/lewd_portal_relay
	name = "portal relay"
	desc = "Чей-то зад выглядывает из портала."
	anchored = TRUE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE
	flags_1 = HEAR_1
	var/mob/living/carbon/human/owner
	var/obj/structure/lewd_portal/owning_portal
	var/portal_mode = GLORYHOLE
	/// Подавляет include_owner() во время ретрансляции речи владельца, чтобы он не слышал сам себя через релей.
	var/relaying = FALSE

/obj/lewd_portal_relay/Initialize(mapload, mob/living/carbon/human/owner_ref, obj/structure/lewd_portal/owning_portal_reference)
	. = ..()
	appearance_flags |= KEEP_TOGETHER
	if(!owner_ref || !owning_portal_reference)
		return INITIALIZE_HINT_QDEL
	owning_portal = owning_portal_reference
	portal_mode = owning_portal.portal_mode
	owner = owner_ref
	if(portal_mode == GLORYHOLE)
		var/obj/item/organ/genital/penis/penis_reference = owner.getorganslot(ORGAN_SLOT_PENIS)
		var/penis_type = penis_reference?.shape
		name = "[penis_type] член"
		desc = "Чей-то член выглядывает из портала."
		dir = SOUTH
		if (owning_portal.dir == EAST || owning_portal.dir == WEST)
			dir = REVERSE_DIR(owning_portal.dir)
	else
		dir = NORTH
		var/species_name
		if(owner.dna?.species?.name)
			species_name = owner.dna.species.name
		else
			species_name = owner.dna.features["custom_species"]
		name = "[species_name] зад"
		desc = "Чей-то зад выглядывает из портала."
	RegisterSignals(owner, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_UPDATE_GENITALS), PROC_REF(update_visuals))
	RegisterSignal(src, COMSIG_ATOM_HEARER_IN_VIEW, PROC_REF(include_owner))
	RegisterSignal(owner, COMSIG_MOB_SAY, PROC_REF(relay_owner_say))
	RegisterSignal(owner, COMSIG_MOB_EMOTE, PROC_REF(relay_owner_emote))

/obj/lewd_portal_relay/Destroy(force)
	UnregisterSignal(src, COMSIG_ATOM_HEARER_IN_VIEW)
	if(!isnull(owner))
		UnregisterSignal(owner, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_MOB_UPDATE_GENITALS, COMSIG_MOB_SAY, COMSIG_MOB_EMOTE))
		owner = null
	owning_portal = null
	visible_message("[src] исчезает в портале!")
	return ..()

/// Мост коммуникации
/obj/lewd_portal_relay/proc/include_owner(datum/source, list/processing_list, list/hearers)
	SIGNAL_HANDLER
	if(relaying || QDELETED(owner))
		return
	hearers |= owner

/// Ретранслируем речь входящего
/obj/lewd_portal_relay/proc/relay_owner_say(mob/speaking, list/speech_args)
	SIGNAL_HANDLER
	if(relaying || QDELETED(owner))
		return
	var/message = speech_args[SPEECH_MESSAGE]
	if(!message)
		return
	var/datum/language/language = speech_args[SPEECH_LANGUAGE]
	var/list/spans = speech_args[SPEECH_SPANS]
	relaying = TRUE
	owner.send_speech(message, 7, src, , spans, language)
	relaying = FALSE

/// Ретранслируем сабтлер входящего
/obj/lewd_portal_relay/proc/relay_owner_emote(mob/speaking, datum/emote/emote, act, m_type, message, intentional, message_override)
	SIGNAL_HANDLER
	if(relaying || QDELETED(owner))
		return
	if(!istype(emote, /datum/emote/sound/human/subtler))
		return
	// После run_emote в emote.message уже лежит готовый отформатированный текст
	// аргумент message сигнала бывает null при вводе через *subtler текст
	if(!emote.message)
		return
	var/subtler_message = emote.message
	var/list/ignored_mobs_list = LAZYCOPY(GLOB.dead_mob_list)
	var/see_invis = owner.see_invisible
	for(var/atom/A in range(1, get_turf(src)))
		var/list/stack = list(A)
		while(stack.len)
			var/atom/B = stack[stack.len]
			stack.len--
			if(ismob(B))
				var/mob/M = B
				if(M != owner)
					var/invis = M.invisibility
					var/atom/movable/x = M
					while(istype(x.loc, /atom/movable))
						x = x.loc
						if(x.invisibility > invis)
							invis = x.invisibility
					if(see_invis < invis)
						LAZYADD(ignored_mobs_list, M)
			if(istype(B, /atom/movable))
				var/atom/movable/MV = B
				if(MV.contents && MV.contents.len)
					stack += MV.contents
	relaying = TRUE
	visible_message(subtler_message, subtler_message, vision_distance = 1, ignored_mobs = ignored_mobs_list, omni = TRUE)
	relaying = FALSE

/obj/lewd_portal_relay/proc/update_visuals()
	SIGNAL_HANDLER
	if(portal_mode == GLORYHOLE)
		penis_only()
	else
		lower_body_only()

/obj/lewd_portal_relay/proc/add_relay_overlay(overlay, target_layer = ABOVE_MOB_LAYER, apply_mask = FALSE, exclude_head_category = FALSE)
	var/list/relayed_overlays = list()
	if(islist(overlay))
		for(var/overlay_entry in overlay)
			if(isimage(overlay_entry) || isappearance(overlay_entry))
				var/mutable_appearance/overlay_appearance = overlay_entry
				if(exclude_head_category && overlay_appearance?.category == "HEAD")
					continue
				var/image/copy = image(overlay_appearance)
				copy.layer = target_layer
				copy.plane = GAME_PLANE
				if(apply_mask)
					copy.filters += filter(type = "alpha", icon = icon('modular_bluemoon/icons/obj/structures/lewd_portals.dmi', "mask"))
				relayed_overlays += copy
	else if(isimage(overlay) || isappearance(overlay))
		var/image/copy = image(overlay)
		copy.layer = target_layer
		copy.plane = GAME_PLANE
		if(apply_mask)
			copy.filters += filter(type = "alpha", icon = icon('modular_bluemoon/icons/obj/structures/lewd_portals.dmi', "mask"))
		relayed_overlays += copy
	add_overlay(relayed_overlays)

/obj/lewd_portal_relay/proc/penis_only()
	cut_overlays()
	overlays = list()
	var/use_skintone = owner.dna.species.use_skintones && owner.dna.features["genitals_use_skintone"]

	var/obj/item/organ/genital/penis/penis_reference = owner.getorganslot(ORGAN_SLOT_PENIS)
	if(penis_reference)
		var/datum/sprite_accessory/S = GLOB.cock_shapes_list[penis_reference.shape]
		if(S && S.icon_state != "none")
			var/mutable_appearance/penis_image = mutable_appearance(S.icon, layer = ABOVE_MOB_LAYER, plane = GAME_PLANE)
			var/aroused_state = penis_reference.aroused_state && S.alt_aroused
			penis_image.icon_state = "[ORGAN_SLOT_PENIS]_[S.icon_state]_[penis_reference.size_to_state()][use_skintone ? "_s" : ""]_[aroused_state]_FRONT"
			if(use_skintone)
				penis_image.color = SKINTONE2HEX(owner.skin_tone)
			else
				switch(S.color_src)
					if("cock_color")
						penis_image.color = "#[owner.dna.features["cock_color"]]"
			if(S.center)
				penis_image = center_image(penis_image, S.dimension_x, S.dimension_y)
			add_overlay(penis_image)

	var/obj/item/organ/genital/testicles/balls_reference = owner.getorganslot(ORGAN_SLOT_TESTICLES)
	if(balls_reference)
		var/datum/sprite_accessory/balls_S = GLOB.balls_shapes_list[balls_reference.shape]
		if(balls_S && balls_S.icon_state != "none")
			var/mutable_appearance/balls_image = mutable_appearance(balls_S.icon, layer = ABOVE_MOB_LAYER - 0.1, plane = GAME_PLANE)
			var/balls_aroused = balls_reference.aroused_state && balls_S.alt_aroused
			balls_image.icon_state = "[ORGAN_SLOT_TESTICLES]_[balls_S.icon_state]_[balls_reference.size_to_state()][use_skintone ? "_s" : ""]_[balls_aroused]_FRONT"
			if(use_skintone)
				balls_image.color = SKINTONE2HEX(owner.skin_tone)
			else
				switch(balls_S.color_src)
					if("balls_color")
						balls_image.color = "#[owner.dna.features["balls_color"]]"
			if(balls_S.center)
				balls_image = center_image(balls_image, balls_S.dimension_x, balls_S.dimension_y)
			add_overlay(balls_image)

/obj/lewd_portal_relay/proc/lower_body_only()
	owner.update_body()
	cut_overlays()
	overlays = list()
	for(var/limb in list(BODY_ZONE_R_LEG, BODY_ZONE_L_LEG, BODY_ZONE_CHEST))
		var/obj/item/bodypart/limb_object = owner.get_bodypart(limb)
		if(istype(limb_object))
			var/limb_icon_list = limb_object.get_limb_icon()
			add_relay_overlay(limb_icon_list, ABOVE_MOB_LAYER - 0.3, limb_object == owner.get_bodypart(BODY_ZONE_CHEST))
	if(owner.shoes && owner.overlays_standing[SHOES_LAYER])
		add_relay_overlay(owner.overlays_standing[SHOES_LAYER], ABOVE_MOB_LAYER - 0.2)
	if(owner.w_uniform && owner.overlays_standing[UNIFORM_LAYER])
		add_relay_overlay(owner.overlays_standing[UNIFORM_LAYER], ABOVE_MOB_LAYER - 0.1, TRUE)
	add_relay_overlay(owner.overlays_standing[BODY_LAYER], ABOVE_MOB_LAYER - 0.25, TRUE)
	add_relay_overlay(owner.overlays_standing[BODY_BEHIND_LAYER], ABOVE_MOB_LAYER - 0.15, FALSE, TRUE)
	add_relay_overlay(owner.overlays_standing[BODY_FRONT_LAYER], ABOVE_MOB_LAYER - 0.15, FALSE, TRUE)
	add_relay_overlay(owner.overlays_standing[GENITALS_BEHIND_LAYER], ABOVE_MOB_LAYER - 0.05)
	add_relay_overlay(owner.overlays_standing[GENITALS_FRONT_LAYER], ABOVE_MOB_LAYER - 0.04)
	add_relay_overlay(owner.overlays_standing[GENITALS_EXPOSED_LAYER], ABOVE_MOB_LAYER - 0.04)

/obj/lewd_portal_relay/CtrlShiftClick(mob/user)
	. = ..()
	if(!isliving(user) || !owner)
		return
	var/datum/component/interaction_menu_granter/menu = user.GetComponent(/datum/component/interaction_menu_granter)
	if(!menu)
		return
	menu.open_menu(user, owner)

/obj/lewd_portal_relay/examine(mob/user)
	. = ..()
	if(owner)
		if(owner.real_name)
			. += span_notice("Он принадлежит [owner.real_name].")

/obj/lewd_portal_relay/AltClick(mob/living/user)
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK))
		return
	if(portal_mode == GLORYHOLE)
		return
	if(dir == NORTH)
		dir = SOUTH
	else
		dir = NORTH
	to_chat(user, span_info("Вы переворачиваете [name]."))
	to_chat(owner, span_info("Вы чувствуете, как ваш зад переворачивают."))

#undef GLORYHOLE
#undef WALLSTUCK
