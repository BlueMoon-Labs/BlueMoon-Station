/datum/component/condom_clipping
	var/attached_condoms = 0
	var/max_attached_condoms = 50 // остановимся на юбилейном числе
	var/mutable_appearance/condom_overlay = null

/datum/component/condom_clipping/Initialize()
	if(!isclothing(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/condom_clipping/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(clip_condom))
	// обработка через сингалы более громоздка, но безопаснее в целом и в особенности при взаимодействии с контейнерами
	RegisterSignal(parent, COMSIG_ATOM_ENTERED, PROC_REF(plus_condom))
	RegisterSignal(parent, COMSIG_ATOM_EXITED, PROC_REF(minus_condom))

/datum/component/condom_clipping/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	QDEL_NULL(condom_overlay)

/datum/component/condom_clipping/proc/update_parent_overlays(obj/item/genital_equipment/condom/condom = /obj/item/genital_equipment/condom/open/used)
	var/obj/item/clothing/C = parent
	if(!istype(C))
		CRASH("condom_clipping component has been assigned to incompatable atom for some reason.")
	switch(attached_condoms)
		if(1)
			if(istype(condom_overlay))
				return
			condom_overlay = new /mutable_appearance(condom)
			condom_overlay.layer = -UNIFORM_LAYER
			condom_overlay.transform *= 0.5
			condom_overlay.pixel_x = 8
			condom_overlay.pixel_y = 8
			C.add_overlay(condom_overlay)
		if(-INFINITY to 0)
			C.cut_overlay(condom_overlay)
			QDEL_NULL(condom_overlay)

/datum/component/condom_clipping/proc/clip_condom(datum/source, obj/item/genital_equipment/condom/condom, mob/living/user, mob/living/wearer)
	SIGNAL_HANDLER
	. = TRUE
	var/obj/item/clothing/C = parent
	if(source != C || !istype(condom) || !istype(user) || !user.canUseTopic(C, BE_CLOSE, ismonkey(user), NO_TK, FALSE))
		return FALSE
	if(attached_condoms >= max_attached_condoms)
		to_chat(user, span_warning("Уже некуда цеплять использованные презервативы..."))
		return FALSE
	if(condom.reagents?.total_volume > 0)
		if(user.transferItemToLoc(condom, C))
			if((C.current_equipped_slot & C.slot_flags) && (user == wearer || C.loc == user))
				user.visible_message(span_love("[user] нацепляет использованный презерватив себе на [C.name]."))
			else
				user.visible_message(span_love("[user] нацепляет использованный презерватив на [C.name][istype(wearer) ? " на [wearer]" : ""]."))
		else
			to_chat(user, span_warning("Не удалось прицепить презерватив."))
			return FALSE
	else
		to_chat(user, span_warning("Прежде чем нацеплять презерватив на одежду, его необходимо использовать по назначению."))
		return FALSE

/datum/component/condom_clipping/proc/plus_condom(datum/source, obj/item/genital_equipment/condom/condom, atom/oldLoc)
	SIGNAL_HANDLER
	if(!istype(condom))
		return
	attached_condoms++
	condom.obj_flags |= NOT_VISIBLE_IN_STORAGE
	var/datum/component/storage/s = source.GetComponent(/datum/component/storage)
	s?.refresh_mob_views()
	update_parent_overlays(condom)

/datum/component/condom_clipping/proc/unclip_condom(mob/living/user)
	. = TRUE
	if(attached_condoms <= 0 || !istype(user) || !user.canUseTopic(parent, BE_CLOSE, ismonkey(user), NO_TK, FALSE))
		return FALSE
	var/obj/item/clothing/C = parent
	var/obj/item/genital_equipment/condom/to_unclip = locate(/obj/item/genital_equipment/condom) in C.contents
	if(to_unclip)
		user.put_in_hands(to_unclip)
		if((C.current_equipped_slot & C.slot_flags) && ismob(C.loc))
			user.visible_message("[user] снимает использованный презерватив с [C.name] на [user == C.loc ? "себе" : C.loc].")
		else
			user.visible_message("[user] снимает использованный презерватив с [C.name].")
	else
		attached_condoms = 0
		update_parent_overlays()

/datum/component/condom_clipping/proc/minus_condom(datum/source, obj/item/genital_equipment/condom/condom, atom/newLoc)
	SIGNAL_HANDLER
	if(!istype(condom))
		return
	attached_condoms--
	condom.obj_flags &= ~NOT_VISIBLE_IN_STORAGE
	update_parent_overlays(condom)

// Я не буду отдельно просматривать тысячу типов одежды на ирл возможность зацепления использованных презервативов, все остается на совести игроков.
// Все остальное отыгрывается через пкм - custom examine text.

/obj/item/clothing/under/ComponentInitialize(mapload)
	. = ..()
	AddComponent(/datum/component/condom_clipping)

/obj/item/clothing/underwear/briefs/ComponentInitialize(mapload)
	. = ..()
	AddComponent(/datum/component/condom_clipping)

/obj/item/clothing/underwear/shirt/ComponentInitialize(mapload)
	. = ..()
	AddComponent(/datum/component/condom_clipping)

/obj/item/clothing/underwear/chastity_belt/ComponentInitialize(mapload)
	. = ..()
	AddComponent(/datum/component/condom_clipping)
