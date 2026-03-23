/*
 * HEAVY ROLLER BED
 */

/obj/structure/bed/roller
	var/can_move_superheavy_characters = FALSE // При TRUE позволяет укладывать на каталку сверхтяжелых персонажей

/obj/structure/bed/roller/heavy
	name = "heavy roller bed"
	desc = "A collapsed roller bed that can be carried around. Can be used to move heavy spacemens and spacevulfs."
	icon = 'modular_bluemoon/icons/obj/heavy_rollerbed.dmi'
	foldabletype = /obj/item/roller/heavy
	pixel_x = -16
	can_move_superheavy_characters = TRUE
	buckle_lying = 270

/obj/structure/bed/roller/heavy/post_buckle_mob(mob/living/M)
	M.pixel_x = initial(M.pixel_x)+16
	return ..()

/obj/item/roller/heavy
	name = "heavy roller bed"
	desc = "A collapsed roller bed that can be carried around. Can be used to move heavy spacemens and spacevulfs."
	icon = 'modular_bluemoon/icons/obj/heavy_rollerbed.dmi'
	rollertype = /obj/structure/bed/roller/heavy
	w_class = WEIGHT_CLASS_HUGE

/obj/item/roller/heavy/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, require_twohands = TRUE)


/*
 * STASIS ROLLER BED
 */

/obj/structure/bed/roller/stasis
	name = "stasis roller bed"
	desc = "A collapsed roller bed with a stasis function that can be carried around."
	icon = 'modular_bluemoon/icons/obj/rollerbed.dmi'
	foldabletype = /obj/item/roller/stasis
	buckle_lying = 90
	var/obj/item/stock_parts/cell/cell
	var/active_power_usage = 40 // at second (40 = ~ 15 min at bluespace cell)
	var/stasis_enabled = FALSE
	var/obj/effect/overlay/vis/mattress_overlay

/obj/structure/bed/roller/stasis/Initialize(mapload, obj/item/stock_parts/cell/C)
	. = ..()
	if(!isnull(C))
		cell = C
		cell.forceMove(src)
	if(cell)
		toggle() // ON
		START_PROCESSING(SSobj, src)

/obj/structure/bed/roller/stasis/Destroy()
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/structure/bed/roller/stasis/get_cell()
	return cell

/obj/structure/bed/roller/stasis/examine(mob/user)
	. = ..()
	if(cell)
		. += span_notice("Cell charge: [round(cell.percent())]%")
		. += span_notice("Alt-click to remove the cell.")
	else
		. += span_warning("No cell installed.")

/obj/structure/bed/roller/stasis/update_overlays()
	. = ..()
	var/const/overlay_name = "stasis"
	if(!mattress_overlay)
		mattress_overlay = SSvis_overlays.add_vis_overlay(src, icon, overlay_name, layer, plane, dir, alpha = 0, unique = TRUE)
		mattress_overlay.vis_flags = VIS_INHERIT_PLANE | VIS_INHERIT_LAYER | VIS_INHERIT_DIR | VIS_INHERIT_ID
	else
		vis_contents += mattress_overlay
		if(managed_vis_overlays)
			managed_vis_overlays += mattress_overlay
		else
			managed_vis_overlays = list(mattress_overlay)

	if(mattress_overlay.pixel_y ? !up : up)
		mattress_overlay.pixel_y = up ? 5 : 0

	if(mattress_overlay.alpha ? !stasis_enabled : stasis_enabled)
		var/new_alpha = stasis_enabled ? 255 : 0
		var/easing_direction = stasis_enabled ? EASE_OUT : EASE_IN
		animate(mattress_overlay, alpha = new_alpha, time = 50, easing = CUBIC_EASING|easing_direction)

/obj/structure/bed/roller/stasis/AltClick(mob/user)
	. = ..()
	if(user && user != get_occupant() && Adjacent(user) && user.can_hold_items())
		user.put_in_hands(cell)
		cell.update_appearance()
		cell = null

/obj/structure/bed/roller/stasis/attackby(obj/item/W, mob/user, params)
	if(!iscarbon(user))
		return
	if(!cell && istype(W, /obj/item/stock_parts/cell))
		cell = W
		W.forceMove(src)
		START_PROCESSING(SSobj, src)
		return
	return ..()

/obj/structure/bed/roller/stasis/after_fold_roller(mob/user, obj/item/roller/stasis/I)
	if(stasis_enabled)
		play_power_sound(FALSE)
	if(cell && I)
		I.cell = cell
		cell.forceMove(I)
		cell = null
	return ..()

/obj/structure/bed/roller/stasis/post_buckle_mob(mob/living/M)
	. = ..()
	if(stasis_enabled)
		chill_out(M)

/obj/structure/bed/roller/stasis/post_unbuckle_mob(mob/living/M)
	. = ..()
	thaw_them(M)

/obj/structure/bed/roller/stasis/proc/toggle()
	stasis_enabled = !stasis_enabled

	var/mob/living/occupant = get_occupant()
	if (occupant && stasis_enabled != IS_IN_STASIS(occupant))
		if (stasis_enabled)
			chill_out(occupant)
		else
			thaw_them(occupant)

	play_power_sound()
	update_appearance()

/obj/structure/bed/roller/stasis/process(delta_time)
	if(!cell)
		if(stasis_enabled)
			toggle()
		return PROCESS_KILL
	if(cell.use(active_power_usage * delta_time) != stasis_enabled)
		toggle()

/obj/structure/bed/roller/stasis/proc/play_power_sound(state)
	if(isnull(state))
		state = stasis_enabled
	var/sound_freq = rand(5120, 8800)
	if(state)
		playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE, frequency = sound_freq)
	else
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE, frequency = sound_freq)

/obj/structure/bed/roller/stasis/proc/get_occupant()
	if(buckled_mobs && buckled_mobs.len && isliving(buckled_mobs[1]))
		return buckled_mobs[1]

/obj/structure/bed/roller/stasis/proc/chill_out(mob/living/target)
	if(target && target != get_occupant())
		return
	var/freq = rand(24750, 26550)
	playsound(src, 'sound/effects/spray.ogg', 5, TRUE, 2, frequency = freq)
	target.apply_status_effect(/datum/status_effect/grouped/stasis, STASIS_MACHINE_EFFECT)
	ADD_TRAIT(target, TRAIT_PAINKILLER, PAINKILLER_STASIS)
	target.throw_alert("painkiller", /atom/movable/screen/alert/painkiller)
	target.ExtinguishMob()

/obj/structure/bed/roller/stasis/proc/thaw_them(mob/living/target)
	target.remove_status_effect(/datum/status_effect/grouped/stasis, STASIS_MACHINE_EFFECT)
	REMOVE_TRAIT(target, TRAIT_PAINKILLER, PAINKILLER_STASIS)
	target.clear_alert("painkiller", /atom/movable/screen/alert/painkiller)

/obj/item/roller/stasis
	name = "Stasis roller bed"
	desc = "A collapsed roller bed with a stasis function that can be carried around."
	icon = 'modular_bluemoon/icons/obj/rollerbed.dmi'
	rollertype = /obj/structure/bed/roller/stasis
	var/obj/item/stock_parts/cell/cell

/obj/item/roller/stasis/examine(mob/user)
	. = ..()
	if(cell)
		. += span_notice("Cell charge: [round(cell.percent())]%")
		. += span_notice("Alt-click to remove the cell.")
	else
		. += span_warning("No cell installed.")

/obj/item/roller/stasis/get_cell()
	return cell

/obj/item/roller/stasis/attackby(obj/item/I, mob/living/user, params)
	if(!iscarbon(user))
		return
	if(!cell && istype(I, /obj/item/stock_parts/cell))
		cell = I
		I.forceMove(src)
		return
	return ..()

/obj/item/roller/stasis/AltClick(mob/user)
	. = ..()
	if(user && Adjacent(user) && user.can_hold_items())
		user.put_in_hands(cell)
		cell.update_appearance()
		cell = null

/obj/item/roller/stasis/deploy_roller(mob/user, atom/location)
	. = new rollertype(location, cell)
	cell = null
	after_deploy_roller(user, .)
