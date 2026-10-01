/obj/structure/bed/dildo_machine
	name = "Dildo machine"
	desc = "It provides pleasure."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "dilmachine"
	anchored = TRUE
	var/mode = "low"
	var/on = 0
	var/hole = CUM_TARGET_VAGINA
	var/obj/item/portallight/attached_portallight = null
	var/portal_error = FALSE
	var/obj/item/dildo/attached_dildo = new /obj/item/dildo/custom
	var/dual_mode = FALSE
	var/obj/item/dildo/dual_mode_attached_dildo
	buckle_lying = 90
	flags_1 = NODECONSTRUCT_1
	var/timer = 0
	var/static/list/speed_delay = list(
		"low"    = 2,
		"normal" = 1,
		"high"   = 0.2
	)

/obj/structure/bed/dildo_machine/New()
	..()
	add_overlay(mutable_appearance('modular_bluemoon/icons/obj/structures/lewd_devices.dmi', "dilmachine_over", MOB_LAYER + 1))

/obj/structure/bed/dildo_machine/Destroy()
	STOP_PROCESSING(SSobjlw,src)
	. = ..()

/obj/structure/bed/dildo_machine/examine(mob/user)
	. = ..()

	if(attached_portallight)
		. += "There is attached [span_lewd(attached_portallight.name)]."

	if(dual_mode)
		. += span_alert("\the [src.name] in dual mode.")

	if(attached_dildo)
		. += "There is attached [span_lewd(attached_dildo.name)]."
	else
		. += span_alert("There in no attached dildo.")

	if(dual_mode_attached_dildo)
		. += "There is a [span_lewd(dual_mode_attached_dildo.name)] attached to second spot."
	else if(dual_mode)
		. += span_alert("There in no second attached dildo.")

	if(attached_dildo || dual_mode_attached_dildo)
		. += span_notice("Ctrl-Click to detach dildo.")

	. += span_notice("Alt-Click to open menu.")

/obj/structure/bed/dildo_machine/CtrlClick(mob/user)
	. = ..()
	if(!iscarbon(user) || !in_range(src, user))
		return
	detach_dildo(user)

/obj/structure/bed/dildo_machine/proc/detach_dildo(mob/living/carbon/user, only_dual_dildo = FALSE)
	if(on)
		to_chat(user, span_warning("You can't detach the dildo from the machine while it's on."))
		return
	if(dual_mode_attached_dildo)
		if(user)
			user.put_in_hands(dual_mode_attached_dildo)
			to_chat(user, span_notice("You detach second dildo from the machine."))
		else
			dual_mode_attached_dildo.forceMove(get_turf(src))
		dual_mode_attached_dildo = null
	if(!only_dual_dildo && attached_dildo)
		if(user)
			user.put_in_hands(attached_dildo)
			to_chat(user, span_notice("You detach the dildo from the machine."))
		else
			attached_dildo.forceMove(get_turf(src))
		attached_dildo = null

/obj/structure/bed/dildo_machine/proc/detach_portallight(mob/living/carbon/user)
	if(on)
		to_chat(user, span_warning("You can't detach the portal light from the machine while it's on."))
		return
	if(attached_portallight)
		attached_portallight.forceMove(get_turf(src))
		attached_portallight = null
		hole = CUM_TARGET_VAGINA
		can_buckle = TRUE

/obj/structure/bed/dildo_machine/AltClick(mob/user)
	. = ..()
	if(!iscarbon(user) || !in_range(src, user))
		return

	var/static/list/INTERACTIONS = list("Toggle machine", "Change hole", "Change speed mode", "Detach dildo", "Detach portallight")
	var/static/list/HOLE_CHOICES = list("Vagina", "Anus", "Dual mode")
	var/static/list/HOLE_MAP = list(
		"Vagina" = CUM_TARGET_VAGINA,
		"Anus"   = CUM_TARGET_ANUS
	)
	var/static/list/SPEED_CHOICES = list("Low", "Normal", "High")

	var/choice = input(user, "Interactions") as null|anything in INTERACTIONS
	if(!choice) return

	switch(choice)
		if("Toggle machine")
			toggle(user)
		if("Change hole")
			if(on)
				to_chat(usr, span_warning("You can't change hole, while machine is working."))
				return
			var/h = input(user, "Choose hole") as null|anything in HOLE_CHOICES
			if(h)
				if(h == "Dual mode")
					dual_mode = TRUE
				else
					if(dual_mode)
						dual_mode = FALSE
					if(dual_mode_attached_dildo)
						detach_dildo(user, TRUE)
					hole = HOLE_MAP[h]
		if("Change speed mode")
			var/m = input(user, "Change speed mode") as null|anything in SPEED_CHOICES
			if(m)
				mode = lowertext(m)
		if("Detach dildo")
			detach_dildo(user)
		if("Detach portallight")
			detach_portallight(user)

/obj/structure/bed/dildo_machine/proc/toggle(mob/living/carbon/user)
	if(!on)
		if(!attached_dildo)
			if(user)
				to_chat(user, span_warning("You can't toggle machine, without dildo."))
			return
		if(dual_mode && !dual_mode_attached_dildo)
			if(user)
				to_chat(user, span_warning("You can't toggle machine in dual mode, without second dildo."))
			return

	on = !on
	if(on)
		portal_error = FALSE
		START_PROCESSING(SSobjlw,src)
	if(!on)
		STOP_PROCESSING(SSobjlw,src)
	if(user)
		to_chat(user, span_notice("[src] в[on ? "" : "ы"]ключена."))

/obj/structure/bed/dildo_machine/process(delta_time)
	timer -= delta_time
	if(timer >= 0) // chech interval
		return
	else
		timer = speed_delay[mode]
	fuck()

/obj/structure/bed/dildo_machine/proc/fuck()
	if(!on || !attached_dildo || (dual_mode && !dual_mode_attached_dildo) || !hole || !(has_buckled_mobs() || attached_portallight))
		visible_message(span_alert("The machine warning: the subject or dildo is missing."))
		on = FALSE
		STOP_PROCESSING(SSobjlw,src)
		return

	if(has_buckled_mobs())
		for(var/mob/living/carbon/human/M in buckled_mobs)
			fuck_target(M , hole)
			return

	else if(attached_portallight)
		var/mob/living/carbon/human/portal_target
		if(ishuman(attached_portallight.portalunderwear.loc) && (attached_portallight.portalunderwear.current_equipped_slot & (ITEM_SLOT_UNDERWEAR | ITEM_SLOT_MASK)))
			portal_target = attached_portallight.portalunderwear.loc
		else
			var/datum/component/genital_equipment/equipment = attached_portallight.portalunderwear.GetComponent(/datum/component/genital_equipment)
			if(equipment?.holder_genital)
				portal_target = equipment.get_wearer()
		if(portal_target)
			var/hole_target = attached_portallight.portalunderwear.targetting
			if(hole_target == CUM_TARGET_VAGINA || hole_target == CUM_TARGET_ANUS || hole_target == CUM_TARGET_MOUTH)
				hole = hole_target
				dual_mode = FALSE
				portal_error = FALSE
				fuck_target(portal_target, hole, TRUE)
				return
		// keep machine on while the portal is empty or has unsopported organ
			else
				if(!portal_error)
					portal_error = TRUE
					visible_message(span_alert("The machine warning: attached portal not supported."))
				return
		else
			if(!portal_error)
				portal_error = TRUE
				visible_message(span_alert("The machine warning: attached portal empty."))
			return

/obj/structure/bed/dildo_machine/proc/fuck_target(mob/living/carbon/human/M, target_hole, isPortal = FALSE)
	var/list/organ_slots = list()
	if(dual_mode)
		organ_slots = list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS)
	else
		organ_slots += target_hole

	if(!isPortal)
		for(var/organ_slot in organ_slots)
			var/obj/item/organ/genital/organ = M.getorganslot(organ_slot)
			if(!organ || !(organ.is_exposed() || organ.always_accessible))
				visible_message(span_alert("The machine warning: cannot reach the hole."))
				on = FALSE
				return

	var/i = 1
	for(var/organ_slot in organ_slots)
		var/gained_lust = attached_dildo.target_reaction(M,null, i>1 ? 0 : 1, organ_slot,null,FALSE,TRUE,TRUE,FALSE)
		M.client?.plug13.send_emote(organ_slot == CUM_TARGET_ANUS ? PLUG13_EMOTE_ANUS : PLUG13_EMOTE_GROIN, min(gained_lust * 5, 100), PLUG13_DURATION_NORMAL)
		i += 1

	if(M.client?.prefs.cit_toggles & SEX_JITTER)
		M.Jitter(3)

	if(mode == "high" && target_hole == CUM_TARGET_MOUTH)
		target_hole = CUM_TARGET_THROAT
	if(mode == "low" && target_hole == CUM_TARGET_THROAT)
		target_hole = CUM_TARGET_MOUTH

	var/message_end = ""
	if(dual_mode)
		message_end = "обе дырочки"
	else
		switch(target_hole)
			if(CUM_TARGET_VAGINA)
				message_end = "вагину"
			if(CUM_TARGET_ANUS)
				message_end = "попку"
			if(CUM_TARGET_MOUTH)
				message_end = "ротик"
			if(CUM_TARGET_THROAT)
				message_end = "горло"

	var/message = "[pick("вгоняет дилдо в", "трахает", "разрабатывает")] [message_end]" // normal mode
	switch(mode)
		if("high")
			message = "[pick("активно","безжалостно","жестоко")] [pick("трахает", "насилует", "долбит")] [message_end]"
		if("low")
			message = "[pick("медленно","плавно","мягко")] [pick("вводит дилдо в", "погружает дилдо в")] [message_end]"

	playsound(loc, "modular_sand/sound/interactions/bang[rand(1, 6)].ogg", 30, 1)
	visible_message(span_lewd("\the [src] [message]"))


/obj/structure/bed/dildo_machine/attackby(obj/item/used_item, mob/user, params)
	add_fingerprint(user)
	// It's bed, no moving, use screwdriver
	/*
	if(used_item.tool_behaviour == TOOL_WRENCH)
		to_chat(user, "<span class='notice'>You begin to [anchored ? "unwrench" : "wrench"] [src].</span>")
		if(used_item.use_tool(src, user, 20, volume=30))
			to_chat(user, "<span class='notice'>You successfully [anchored ? "unwrench" : "wrench"] [src].</span>")
			setAnchored(!anchored)
	*/
	if(istype(used_item, /obj/item/screwdriver))
		to_chat(user, span_notice("You unscrew the frame and begin to deconstruct it..."))
		playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
		if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
			to_chat(user, span_notice("You disassemble it."))
			var/obj/item/dildo_machine_kit/kit = new /obj/item/dildo_machine_kit (src.loc)
			if(kit.attached_dildo)
				qdel(kit.attached_dildo)
				kit.attached_dildo = null
			if(dual_mode_attached_dildo)
				dual_mode_attached_dildo.forceMove(get_turf(src))
				dual_mode_attached_dildo = null
			if(attached_dildo)
				attached_dildo.forceMove(kit)
				kit.attached_dildo = attached_dildo
				attached_dildo = null
			qdel(src)
	else if(istype(used_item, /obj/item/dildo) && !(used_item.item_flags & ABSTRACT))
		if(!attached_dildo)
			if(user.transferItemToLoc(used_item, src))
				attached_dildo = used_item
				return TRUE
		else if(dual_mode && !dual_mode_attached_dildo)
			if(user.transferItemToLoc(used_item, src))
				dual_mode_attached_dildo = used_item
				return TRUE
	// вот бы еще оверлей добавить с прикрепленным фонариком
	else if(istype(used_item, /obj/item/portallight))
		if(!attached_portallight && (!buckled_mobs || buckled_mobs.len == 0))
			if(user.transferItemToLoc(used_item, src))
				attached_portallight = used_item
				can_buckle = FALSE
				return TRUE
	else
		return ..()

/obj/item/dildo_machine_kit
	name = "dildo machine construction kit"
	desc = "Construction requires a screwdriver. Put it on the ground first!"
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "kit"
	throwforce = 0
	var/unwrapped = 0
	w_class = WEIGHT_CLASS_HUGE
	var/obj/item/dildo/attached_dildo = new /obj/item/dildo/custom

/obj/item/dildo_machine_kit/examine(mob/user)
	. = ..()
	if(attached_dildo)
		. += "There is a [span_lewd(attached_dildo.name)] inside, but you can't pull it out, deploy machine first."
	else
		. += "There in [span_alert("no dildo inside")] and you can't insert it, deploy machine first."

/obj/item/dildo_machine_kit/attackby(obj/item/used_item, mob/user, params) //constructing a bed here.
	add_fingerprint(user)
	if(istype(used_item, /obj/item/screwdriver))
		if (!(item_flags & IN_INVENTORY) && !(item_flags & IN_STORAGE))
			to_chat(user, span_notice("You screw the frame to the floor and begin to construct it..."))
			playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
			if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
				to_chat(user, span_notice("You assemble it."))
				var/obj/structure/bed/dildo_machine/machine = new /obj/structure/bed/dildo_machine (src.loc)
				if(machine.attached_dildo)
					qdel(machine.attached_dildo)
					machine.attached_dildo = null
				if(attached_dildo)
					attached_dildo.forceMove(machine)
					machine.attached_dildo = attached_dildo
					attached_dildo = null
				qdel(src)
			return
	else
		return ..()
