/datum/smite/skibidi
	name = "Toiletification"

/datum/smite/skibidi/effect(client/user, mob/living/target)
	. = ..()
	if(!iscarbon(target))
		to_chat(user, span_warning("This must be used on a carbon mob."), confidential = TRUE)
		return
	playsound(target, 'sound/machines/toilet_flush.ogg', 80, TRUE)
	target.visible_message("[target] внезапно превращается в туалет!")
	new /obj/structure/toilet/skibidi(target.loc, target)

/obj/structure/toilet/skibidi
	name = "skibidi toilet"
	desc = "Everybody wants to rule the world."
	max_integrity = 300
	integrity_failure = 0.5

	/// Human who got entrapped by the evil toilet
	var/mob/living/carbon/human/trapped

	/// In case we don't get a human on init, we set up a toilet trap to trap whoever enters the tile
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered)
	)

	/// Delay between movements
	var/move_delay = 0.3 SECONDS
	/// when can we move again?
	var/can_move

/obj/structure/toilet/skibidi/Initialize(mapload, mob/living/carbon/human/toilet_man)
	. = ..()
	open = TRUE
	if(toilet_man)
		register_skibidi(toilet_man)
	else
		AddElement(/datum/element/connect_loc, loc_connections)
		update_appearance(UPDATE_ICON)

/obj/structure/toilet/skibidi/Destroy(force)
	if(trapped)
		unregister_skibidi(trapped)
	return ..()

/obj/structure/toilet/skibidi/examine(mob/user)
	. = ..()
	if(trapped)
		. += span_warning("[trapped] подвергается туалетофикации.")

/obj/structure/toilet/skibidi/examine_more(mob/user)
	. = ..()
	if(!trapped)
		return
	. += trapped.examine(user)

/obj/structure/toilet/skibidi/update_overlays()
	. = ..()
	if(!trapped || !open)
		return

	var/obj/item/bodypart/head/head = trapped.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		return

	if(dir == NORTH)
		return

	head.update_limb(FALSE, trapped)
	var/obj/item/organ/brain/stored_brain = head.brain
	var/obj/item/organ/eyes/stored_eyes = head.eyes
	head.brain = trapped.getorganslot(ORGAN_SLOT_BRAIN)
	head.eyes = trapped.getorganslot(ORGAN_SLOT_EYES)
	var/list/head_overlays = head.get_limb_icon(dropped = TRUE, ignore_brain = TRUE)
	head.brain = stored_brain
	head.eyes = stored_eyes
	if(!islist(head_overlays))
		head_overlays = list()

	if(islist(trapped.overlays_standing))
		for(var/layer_key in trapped.overlays_standing)
			var/list_layer = trapped.overlays_standing[layer_key]
			if(islist(list_layer))
				for(var/overlay in list_layer)
					if(istype(overlay, /mutable_appearance) && is_head_mutant_overlay(overlay))
						head_overlays += copy_head_overlay(overlay)
			else if(istype(list_layer, /mutable_appearance) && is_head_mutant_overlay(list_layer))
				head_overlays += copy_head_overlay(list_layer)

	for(var/image/head_piece in head_overlays)
		head_piece.dir = 0
	switch(dir)
		if(SOUTH)
			for(var/image/head_piece in head_overlays)
				head_piece.pixel_y -= 8
				head_piece.pixel_x += 1
		if(WEST)
			for(var/image/head_piece in head_overlays)
				head_piece.pixel_y -= 9
				head_piece.pixel_x += 1
		if(EAST)
			for(var/image/head_piece in head_overlays)
				head_piece.pixel_y -= 9
				head_piece.pixel_x -= 1
	. += head_overlays

/obj/structure/toilet/skibidi/proc/is_head_mutant_overlay(mutable_appearance/overlay)
	if(!overlay.icon_state)
		return FALSE
	var/static/list/head_part_prefixes = list(
		"m_ears_", "f_ears_",
		"m_mam_ears_", "f_mam_ears_",
		"m_snout_", "f_snout_",
		"m_mam_snouts_", "f_mam_snouts_",
		"m_horns_", "f_horns_",
		"m_frills_", "f_frills_",
		"m_ipc_antenna_", "f_ipc_antenna_",
		"m_xeno_head_", "f_xeno_head_",
	)
	for(var/prefix in head_part_prefixes)
		if(findtext(overlay.icon_state, prefix))
			return TRUE
	return findtext(overlay.icon_state, "_HORNS") > 0

/obj/structure/toilet/skibidi/proc/copy_head_overlay(mutable_appearance/source)
	var/mutable_appearance/copy = mutable_appearance(source.icon, source.icon_state, source.layer, source.plane, source.alpha, source.appearance_flags, source.color, source.blend_mode, source.pixel_x, source.pixel_y)
	copy.dir = 0
	copy.transform = source.transform
	copy.category = source.category
	return copy

/obj/structure/toilet/skibidi/setDir(newdir)
	var/old_dir = dir
	. = ..()
	if(dir != old_dir)
		update_appearance(UPDATE_ICON)

/obj/structure/toilet/skibidi/relaymove(mob/living/user, direction)
	if(!direction || !open || (can_move >= world.time))
		return

	var/turf/target_turf = get_step(src, direction)
	if(isturf(loc) && target_turf && !target_turf.density)
		can_move = world.time + move_delay
		setDir(direction)
		trapped?.setDir(direction)
		forceMove(target_turf)

/obj/structure/toilet/skibidi/obj_break(damage_flag)
	if(trapped)
		trapped.forceMove(loc)
	return ..()

/obj/structure/toilet/skibidi/proc/on_entered(datum/source, atom/movable/entered)
	SIGNAL_HANDLER

	if(!open || !ishuman(entered))
		return

	playsound(src, 'sound/machines/toilet_flush.ogg', 80, TRUE)
	audible_message("[entered] смывается в [src]!")
	register_skibidi(entered)

/obj/structure/toilet/skibidi/proc/register_skibidi(mob/living/carbon/human/trapped)
	trapped.forceMove(src)
	src.trapped = trapped
	RemoveElement(/datum/element/connect_loc, loc_connections)
	RegisterSignal(trapped, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	RegisterSignal(trapped, COMSIG_MOVABLE_MOVED, PROC_REF(on_trapped_moved))
	if(trapped.dir)
		setDir(trapped.dir)
	name = "[trapped] toilet"
	update_appearance(UPDATE_ICON)

/obj/structure/toilet/skibidi/proc/unregister_skibidi(mob/living/carbon/human/trapped)
	src.trapped = null
	UnregisterSignal(trapped, COMSIG_MOB_SAY)
	UnregisterSignal(trapped, COMSIG_MOVABLE_MOVED)
	if(trapped.loc == src)
		trapped.forceMove(src.loc)
	if(!QDELING(src) && (obj_integrity < integrity_failure * max_integrity))
		AddElement(/datum/element/connect_loc, loc_connections)
	name = initial(name)

/obj/structure/toilet/skibidi/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	if(!open)
		speech_args[SPEECH_MESSAGE] = ""
		playsound(src, 'sound/machines/toilet_flush.ogg', 20, TRUE)
	else
		playsound(src, 'sound/machines/toilet_flush.ogg', 40, TRUE)

	var/message = speech_args[SPEECH_MESSAGE]
	if(!length(message) || message[1] == "*")
		return

	speech_args[SPEECH_SPANS] |= SPAN_SANS
	if(prob(50))
		message = pick(\
			"Доб-доб!",\
			"Да-да!",\
			"Шкибиди!",\
			"Шкибиди-доб-доб!",\
			"Шкибиди-доб-доб-да-да!",\
			"Йип-йип!",\
			"Шкибиди-доб, йип-йип!",\
			"СТИЛЬ [repeat_string(rand(0,20), "ШКИБИ")]ДИ!"\
		)
	else
		if(prob(50))
			message += " ДОБ-ДОБ!"
		if(prob(50))
			message += " ДА-ДА!"

	speech_args[SPEECH_MESSAGE] = message

/obj/structure/toilet/skibidi/proc/on_trapped_moved(atom/source)
	SIGNAL_HANDLER

	// Персонаж двигается вместе с туалетом — не считаем это побегом
	if(trapped?.loc == src)
		return

	var/mob/living/carbon/human/goodbye = trapped
	unregister_skibidi(goodbye)

	var/obj/item/bodypart/head/skibidi_head = goodbye.get_bodypart(BODY_ZONE_HEAD)
	if(skibidi_head)
		skibidi_head.drop_limb(special = FALSE)
		skibidi_head.forceMove(loc)

	goodbye.gib()

	update_appearance(UPDATE_ICON)
