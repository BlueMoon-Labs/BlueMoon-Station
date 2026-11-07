// Inflatable barriers and their folded forms, ported from Paradise.
/obj/item/inflatable
	name = "inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation."
	icon = 'modular_bluemoon/icons/obj/structures/inflatable.dmi'
	icon_state = "folded_wall"
	w_class = WEIGHT_CLASS_SMALL
	var/structure_path = /obj/structure/inflatable
	var/inflating = FALSE

/obj/item/inflatable/attack_self(mob/user)
	return inflate(user)

/obj/item/inflatable/proc/inflate(mob/user)
	if(inflating || QDELETED(src) || !isturf(user.loc))
		return
	inflating = TRUE
	playsound(src, 'modular_bluemoon/sound/items/inflatable_zip.ogg', 75, TRUE)
	if(!do_after(user, 1 SECONDS, src, progress_loc = user))
		inflating = FALSE
		return
	if(QDELETED(src) || QDELETED(user))
		return
	inflating = FALSE
	if(!isturf(user.loc))
		return
	var/obj/structure/inflatable/inflated_structure = new structure_path(user.loc)
	transfer_fingerprints_to(inflated_structure)
	to_chat(user, span_notice("Вы надуваете [src]."))
	qdel(src)
	return inflated_structure

/obj/structure/inflatable
	armor_type = /datum/armor/inflatable
	name = "inflatable wall"
	desc = "An inflated membrane. Do not puncture."
	anchored = TRUE
	density = TRUE
	max_integrity = 50
	icon = 'modular_bluemoon/icons/obj/structures/inflatable.dmi'
	icon_state = "wall"
	CanAtmosPass = ATMOS_PASS_DENSITY
	var/torn = /obj/item/inflatable/torn
	var/intact = /obj/item/inflatable
	/// Only one folding callback may be pending, even if several people Alt-click.
	var/deflate_timer
	var/deflating = FALSE

/obj/structure/inflatable/Initialize(mapload)
	. = ..()
	register_context()
	air_update_turf(TRUE)

/obj/structure/inflatable/Destroy()
	if(deflate_timer)
		deltimer(deflate_timer)
		deflate_timer = null
	var/turf/old_turf = get_turf(src)
	. = ..()
	old_turf?.air_update_turf(TRUE)

/obj/structure/inflatable/examine(mob/user)
	. = ..()
	. += span_notice("Alt-клик позволяет медленно сдуть и сложить конструкцию.")

/obj/structure/inflatable/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Сдуть")
	return CONTEXTUAL_SCREENTIP_SET

/obj/structure/inflatable/attackby(obj/item/used_item, mob/living/user, params)
	. = ..()
	if(!(. & STOP_ATTACK_PROC_CHAIN) && !QDELETED(src) && (used_item.get_sharpness() || istype(used_item, /obj/item/screwdriver)))
		deconstruct(FALSE)
		return . | STOP_ATTACK_PROC_CHAIN

/obj/structure/inflatable/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	add_fingerprint(user)

/obj/structure/inflatable/AltClick(mob/user)
	if(!isliving(user) || !user.canUseTopic(src, BE_CLOSE, FALSE, TRUE, FALSE))
		return
	add_fingerprint(user)
	deconstruct(TRUE)
	return TRUE

/obj/structure/inflatable/deconstruct(disassembled = TRUE)
	if(QDELETED(src) || (disassembled && deflating))
		return
	playsound(src, 'modular_bluemoon/sound/machines/inflatable_hiss.ogg', 75, TRUE)
	if(!disassembled)
		visible_message(span_warning("[src] стремительно сдувается!"))
		deflate(FALSE)
		return
	deflating = TRUE
	visible_message(span_notice("[src] медленно сдувается."))
	deflate_timer = addtimer(CALLBACK(src, PROC_REF(deflate)), 4 SECONDS, TIMER_STOPPABLE)

/obj/structure/inflatable/proc/deflate(disassembled = TRUE)
	if(QDELETED(src))
		return
	var/obj/item/folded = create_folded_item(disassembled)
	if(folded)
		transfer_fingerprints_to(folded)
	qdel(src)
	return folded

/// A null item path lets disposable membranes disappear without leaving debris.
/obj/structure/inflatable/proc/create_folded_item(disassembled)
	var/item_path = disassembled ? intact : torn
	if(item_path)
		return new item_path(drop_location())

/obj/item/inflatable/door
	name = "inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation."
	icon_state = "folded_door"
	structure_path = /obj/structure/inflatable/door

/obj/structure/inflatable/door
	name = "inflatable door"
	icon_state = "door_closed"
	opacity = TRUE
	torn = /obj/item/inflatable/door/torn
	intact = /obj/item/inflatable/door
	var/state_closed = TRUE
	var/is_operating = FALSE

/obj/structure/inflatable/door/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(isnull(held_item))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, state_closed ? "Открыть" : "Закрыть")
	return CONTEXTUAL_SCREENTIP_SET

/obj/structure/inflatable/door/attack_ai(mob/user)
	if(iscyborg(user) && get_dist(user, src) <= 1)
		return try_to_operate(user)

/obj/structure/inflatable/door/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	..()
	return try_to_operate(user)

/obj/structure/inflatable/door/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /obj/effect/beam))
		return !opacity

/obj/structure/inflatable/door/proc/try_to_operate(atom/user)
	if(is_operating)
		return
	if(isliving(user))
		var/mob/living/living_user = user
		if(!living_user.client || !living_user.canUseTopic(src, BE_CLOSE, TRUE, TRUE, FALSE))
			return
		if(iscarbon(living_user))
			var/mob/living/carbon/carbon_user = living_user
			if(carbon_user.handcuffed)
				return
		return operate()
	if(ismecha(user) && get_dist(user, src) <= 1)
		return operate()

/obj/structure/inflatable/door/proc/operate()
	if(is_operating || QDELETED(src))
		return
	is_operating = TRUE
	flick(state_closed ? "door_opening" : "door_closing", src)
	sleep(1 SECONDS)
	if(QDELETED(src))
		return
	state_closed = !state_closed
	density = state_closed
	set_opacity(state_closed)
	update_icon()
	air_update_turf(TRUE)
	is_operating = FALSE

/obj/structure/inflatable/door/update_icon_state()
	. = ..()
	icon_state = "door_[state_closed ? "closed" : "open"]"

/obj/item/inflatable/torn
	name = "torn inflatable wall"
	desc = "A folded membrane which rapidly expands into a large cubical shape on activation. It is too torn to be usable."
	icon_state = "folded_wall_torn"
	structure_path = null

/obj/item/inflatable/torn/inflate(mob/user)
	to_chat(user, span_warning("Надувная стена слишком сильно порвана, чтобы её надуть!"))
	add_fingerprint(user)

/obj/item/inflatable/door/torn
	name = "torn inflatable door"
	desc = "A folded membrane which rapidly expands into a simple door on activation. It is too torn to be usable."
	icon_state = "folded_door_torn"
	structure_path = null

/obj/item/inflatable/door/torn/inflate(mob/user)
	to_chat(user, span_warning("Надувная дверь слишком сильно порвана, чтобы её надуть!"))
	add_fingerprint(user)

/obj/item/storage/briefcase/inflatable
	name = "inflatable barrier case"
	desc = "Contains inflatable walls and doors."
	icon_state = "inf_box"
	item_state = "syringe_kit"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = NONE
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

/obj/item/storage/briefcase/inflatable/ComponentInitialize()
	. = ..()
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	storage.can_hold = typecacheof(/obj/item/inflatable)
	storage.max_items = 7

/obj/item/storage/briefcase/inflatable/PopulateContents()
	for(var/i in 1 to 3)
		new /obj/item/inflatable/door(src)
	for(var/i in 1 to 4)
		new /obj/item/inflatable(src)

/obj/item/storage/briefcase/inflatable_mini
	name = "emergency barrier case"
	desc = "Contains inflatable walls and doors."
	icon = 'icons/obj/storage.dmi'
	icon_state = "inf_box_mini"
	item_state = "syringe_kit"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = NONE
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

/obj/item/storage/briefcase/inflatable_mini/ComponentInitialize()
	. = ..()
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	storage.can_hold = typecacheof(/obj/item/inflatable)
	storage.max_items = 3

/obj/item/storage/briefcase/inflatable_mini/PopulateContents()
	new /obj/item/inflatable/door(src)
	for(var/i in 1 to 2)
		new /obj/item/inflatable(src)

/obj/item/storage/briefcase/inflatable_airbag
	name = "emergency airbag case"
	desc = "Contains emergency airbags."
	icon = 'icons/obj/storage.dmi'
	icon_state = "inf_box_airbag"
	item_state = "syringe_kit"
	custom_price = PRICE_NORMAL
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = NONE
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'

/obj/item/storage/briefcase/inflatable_airbag/ComponentInitialize()
	. = ..()
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	storage.can_hold = typecacheof(/obj/item/airbag_module)
	storage.max_items = 7

/obj/item/storage/briefcase/inflatable_airbag/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/airbag_module(src)
