/obj/item/organ/cyberimp/arm
	name = "arm-mounted implant"
	desc = "You shouldn't see this! Adminhelp and report this as an issue on github!"
	zone = BODY_ZONE_R_ARM
	organ_flags = ORGAN_SYNTHETIC
	icon_state = "implant-toolkit"
	w_class = WEIGHT_CLASS_NORMAL
	actions_types = list(/datum/action/item_action/organ_action/toggle)

	var/list/items_list = list()
	// Used to store a list of all items inside, for multi-item implants.
	// I would use contents, but they shuffle on every activation/deactivation leading to interface inconsistencies.

	var/obj/item/holder = null
	// You can use this var for item path, it would be converted into an item on New()

/obj/item/organ/cyberimp/arm/Initialize(mapload)
	. = ..()
	if(ispath(holder))
		holder = new holder(src)

	update_icon()
	SetSlotFromZone()
	for(var/obj/item/I in contents)
		add_item(I)

/obj/item/organ/cyberimp/arm/Destroy()
	QDEL_LIST(items_list)
	QDEL_NULL(holder)
	return ..()

/obj/item/organ/cyberimp/arm/proc/add_item(obj/item/I)
	if(I in items_list)
		return
	I.forceMove(src)

	// Убираем возможность класть предметы на стол и в инвентарь
	I.item_flags |= ABSTRACT
	w_class = WEIGHT_CLASS_HUGE

	items_list += I
	// ayy only dropped signal for performance, we can't possibly have shitcode that doesn't call it when removing items from a mob, right?
	// .. right??!
	RegisterSignal(I, COMSIG_ITEM_DROPPED, PROC_REF(magnetic_catch))

/obj/item/organ/cyberimp/arm/proc/magnetic_catch(datum/source, mob/user)
	. = COMPONENT_DROPPED_RELOCATION
	var/obj/item/I = source			//if someone is misusing the signal, just runtime
	if(I in items_list)
		if(I in contents)		//already in us somehow? i probably shouldn't catch this so it's easier to spot bugs but eh..
			return
		I.visible_message("<span class='notice'>[I] snaps back into [src]!</span>")
		I.forceMove(src)
		if(I == holder)
			holder = null

/obj/item/organ/cyberimp/arm/proc/SetSlotFromZone()
	switch(zone)
		if(BODY_ZONE_L_ARM)
			slot = ORGAN_SLOT_LEFT_ARM_AUG
		if(BODY_ZONE_R_ARM)
			slot = ORGAN_SLOT_RIGHT_ARM_AUG
		else
			CRASH("Invalid zone for [type]")

/obj/item/organ/cyberimp/arm/update_icon_state()
	if(zone == BODY_ZONE_R_ARM)
		transform = null
	else // Mirroring the icon
		transform = matrix(-1, 0, 0, 0, 1, 0)

/obj/item/organ/cyberimp/arm/examine(mob/user)
	. = ..()
	. += "<span class='info'>[src] is assembled in the [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm configuration. You can use a screwdriver to reassemble it.</span>"

/obj/item/organ/cyberimp/arm/screwdriver_act(mob/living/user, obj/item/I)
	. = ..()
	if(.)
		return TRUE
	I.play_tool_sound(src)
	if(zone == BODY_ZONE_R_ARM)
		zone = BODY_ZONE_L_ARM
	else
		zone = BODY_ZONE_R_ARM
	SetSlotFromZone()
	to_chat(user, "<span class='notice'>You modify [src] to be installed on the [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm.</span>")
	update_icon()

/obj/item/organ/cyberimp/arm/Remove(special = FALSE)
	Retract()
	..()

/obj/item/organ/cyberimp/arm/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(owner)
		to_chat(owner, "<span class='warning'>[src] is hit by EMP!</span>")
		// give the owner an idea about why his implant is glitching
		Retract()

/obj/item/organ/cyberimp/arm/proc/Retract()
	if(!holder || (holder in src))
		return

	owner.visible_message("<span class='notice'>[owner] retracts [holder] back into [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm.</span>",
		"<span class='notice'>[holder] snaps back into your [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm.</span>",
		"<span class='italics'>You hear a short mechanical noise.</span>")

	owner.transferItemToLoc(holder, src, TRUE)
	holder = null
	RetractPLaySound()

// If it is necessary to process sounds in a special way
/obj/item/organ/cyberimp/arm/proc/RetractPLaySound()
	playsound(get_turf(owner), 'sound/mecha/mechmove03.ogg', 50, 1)

/obj/item/organ/cyberimp/arm/proc/Extend(obj/item/item)
	if(!(item in src))
		return

	holder = item

	holder.resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	holder.slot_flags = null
	holder.set_custom_materials(null)

	var/obj/item/arm_item = owner.get_active_held_item()

	if(arm_item)
		if(!owner.dropItemToGround(arm_item))
			to_chat(owner, "<span class='warning'>Your [arm_item] interferes with [src]!</span>")
			return
		else
			to_chat(owner, "<span class='notice'>You drop [arm_item] to activate [src]!</span>")

	var/result = (zone == BODY_ZONE_R_ARM ? owner.put_in_r_hand(holder) : owner.put_in_l_hand(holder))
	if(!result)
		to_chat(owner, "<span class='warning'>Your [name] fails to activate!</span>")
		return

	// Activate the hand that now holds our item.
	owner.swap_hand(result)//... or the 1st hand if the index gets lost somehow

	owner.visible_message(span_notice("[owner] extends [holder] from [owner.ru_ego()] [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm."),
		span_notice("You extend [holder] from your [zone == BODY_ZONE_R_ARM ? "right" : "left"] arm."),
		span_notice("You hear a short mechanical noise."))
	ExtendPlaySound(item)
	return TRUE

// If it is necessary to process sounds in a special way
/obj/item/organ/cyberimp/arm/proc/ExtendPlaySound(obj/item/I)
	playsound(get_turf(owner), 'sound/mecha/mechmove03.ogg', 50, 1)

/obj/item/organ/cyberimp/arm/ui_action_click(mob/user, actiontype)
	if(crit_fail || (organ_flags & ORGAN_FAILING) || (!holder && !contents.len))
		to_chat(owner, "<span class='warning'>The implant doesn't respond. It seems to be broken...</span>")
		return

	if(!holder || (holder in src))
		holder = null
		if(contents.len == 1)
			Extend(contents[1])
		else
			var/list/choice_list = list()
			for(var/obj/item/I in items_list)
				choice_list[I] = image(I)
			var/obj/item/choice = show_radial_menu(owner, owner, choice_list)
			if(owner && owner == usr && owner.stat != DEAD && (src in owner.internal_organs) && !holder && (choice in contents))
				// This monster sanity check is a nice example of how bad input is.
				Extend(choice)
	else
		Retract()

/obj/item/organ/cyberimp/arm/medibeam
	name = "integrated medical beamgun"
	desc = "A cybernetic implant that allows the user to project a healing beam from their hand."
	contents = newlist(/obj/item/gun/medbeam)

///////////////
//Tools  Arms//
///////////////

/obj/item/organ/cyberimp/arm/toolset
	name = "integrated toolset implant"
	desc = "A stripped-down version of the engineering cyborg toolset, designed to be installed on subject's arm. Contains all necessary tools."
	contents = newlist(/obj/item/screwdriver/cyborg, /obj/item/wrench/cyborg, /obj/item/weldingtool/largetank/cyborg,
		/obj/item/crowbar/cyborg, /obj/item/wirecutters/cyborg, /obj/item/multitool/cyborg)

/obj/item/organ/cyberimp/arm/toolset/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated knife!</span>")
	items_list += new /obj/item/kitchen/knife/combat/cyborg(src)
	return TRUE

/obj/item/organ/cyberimp/arm/surgery
	name = "surgical toolset implant"
	desc = "A set of surgical tools hidden behind a concealed panel on the user's arm."
	contents = newlist(/obj/item/surgical_drapes, /obj/item/scalpel/augment, /obj/item/hemostat/augment, /obj/item/retractor/augment, /obj/item/cautery/augment, /obj/item/circular_saw/augment, /obj/item/blood_filter/augment, /obj/item/surgicaldrill/augment)

/obj/item/organ/cyberimp/arm/surgery/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated knife!</span>")
	items_list += new /obj/item/kitchen/knife/combat/cyborg(src)
	return TRUE

/obj/item/organ/cyberimp/arm/janitor
	name = "janitorial tools implant"
	desc = "A set of janitorial tools on the user's arm."
	contents = newlist(/obj/item/lightreplacer, /obj/item/holosign_creator, /obj/item/soap/nanotrasen, /obj/item/reagent_containers/spray/cyborg_drying, /obj/item/mop/advanced, /obj/item/paint/paint_remover, /obj/item/reagent_containers/glass/beaker/large, /obj/item/reagent_containers/spray/cleaner) //Beaker if for refilling sprays

/obj/item/organ/cyberimp/arm/janitor/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated deluxe cleaning supplies!</span>")
	items_list += new /obj/item/soap/syndie(src) //We add not replace.
	items_list += new /obj/item/reagent_containers/spray/cyborg_lube(src)
	return TRUE

/obj/item/organ/cyberimp/arm/service
	name = "service toolset implant"
	desc = "A set of miscellaneous gadgets hidden behind a concealed panel on the user's arm."
	contents = newlist(/obj/item/extinguisher/mini, /obj/item/kitchen/knife/combat/bone/plastic, /obj/item/hand_labeler, /obj/item/pen, /obj/item/reagent_containers/dropper, /obj/item/kitchen/rollingpin, /obj/item/reagent_containers/glass/beaker/large, /obj/item/reagent_containers/syringe,/obj/item/reagent_containers/food/drinks/shaker, /obj/item/radio/off, /obj/item/camera, /obj/item/modular_computer/tablet/preset/cargo)

/obj/item/organ/cyberimp/arm/service/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s integrated real knife!</span>")
	items_list += new /obj/item/kitchen/knife/combat/cyborg(src)
	return TRUE

///////////////
//Combat Arms//
///////////////

/obj/item/organ/cyberimp/arm/gun/laser
	name = "arm-mounted laser implant"
	desc = "A variant of the arm cannon implant that fires lethal laser beams. The cannon emerges from the subject's arm and remains inside when not in use."
	icon_state = "arm_laser"
	contents = newlist(/obj/item/gun/energy/laser/mounted)

/obj/item/organ/cyberimp/arm/gun/taser
	name = "arm-mounted taser implant"
	desc = "A variant of the arm cannon implant that fires electrodes and disabler shots. The cannon emerges from the subject's arm and remains inside when not in use."
	icon_state = "arm_taser"
	contents = newlist(/obj/item/gun/energy/e_gun/advtaser/mounted)

/obj/item/organ/cyberimp/arm/flash
	name = "integrated high-intensity photon projector" //Why not
	desc = "An integrated projector mounted onto a user's arm that is able to be used as a powerful flash."
	contents = newlist(/obj/item/assembly/flash/armimplant)

/obj/item/organ/cyberimp/arm/flash/Initialize(mapload)
	. = ..()
	if(locate(/obj/item/assembly/flash/armimplant) in items_list)
		var/obj/item/assembly/flash/armimplant/F = locate(/obj/item/assembly/flash/armimplant) in items_list
		F.I = src

/obj/item/organ/cyberimp/arm/baton
	name = "arm electrification implant"
	desc = "An illegal combat implant that allows the user to administer disabling shocks from their arm."
	contents = newlist(/obj/item/borg/stun)

/obj/item/organ/cyberimp/arm/combat
	name = "combat cybernetics implant"
	desc = "A powerful cybernetic implant that contains combat modules built into the user's arm."
	contents = newlist(/obj/item/melee/transforming/energy/blade/hardlight, /obj/item/gun/medbeam, /obj/item/borg/stun, /obj/item/assembly/flash/armimplant)

/obj/item/organ/cyberimp/arm/combat/Initialize(mapload)
	. = ..()
	if(locate(/obj/item/assembly/flash/armimplant) in items_list)
		var/obj/item/assembly/flash/armimplant/F = locate(/obj/item/assembly/flash/armimplant) in items_list
		F.I = src

/obj/item/organ/cyberimp/arm/esword
	name = "arm-mounted energy blade"
	desc = "An illegal and highly dangerous cybernetic implant that can project a deadly blade of concentrated energy."
	contents = newlist(/obj/item/melee/transforming/energy/blade/hardlight)

/obj/item/organ/cyberimp/arm/shield
	name = "arm-mounted riot shield"
	desc = "A deployable riot shield to help deal with civil unrest."
	contents = newlist(/obj/item/shield/riot/implant)

/obj/item/organ/cyberimp/arm/shield/Extend(obj/item/I, silent = FALSE)
	if(I.obj_integrity == 0)				//that's how the shield recharge works
		if(!silent)
			to_chat(owner, "<span class='warning'>[I] is still too unstable to extend. Give it some time!</span>")
		return FALSE
	return ..()

/obj/item/organ/cyberimp/arm/shield/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(.)
		RegisterSignal(M, COMSIG_LIVING_ACTIVE_BLOCK_START, PROC_REF(on_signal))

/obj/item/organ/cyberimp/arm/shield/Remove(special = FALSE)
	UnregisterSignal(owner, COMSIG_LIVING_ACTIVE_BLOCK_START)
	return ..()

/obj/item/organ/cyberimp/arm/shield/proc/on_signal(datum/source, obj/item/blocking_item, list/other_items)
	if(!blocking_item)		//if they don't have something
		var/obj/item/shield/S = locate() in contents
		if(!Extend(S, TRUE))
			return
		other_items += S

/obj/item/organ/cyberimp/arm/shield/emag_act()
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(usr, "<span class='notice'>You unlock [src]'s high-power flash!</span>")
	var/obj/item/assembly/flash/armimplant/F = new(src)
	items_list += F
	F.I = src

/////////////////


//IPC/Synth Arm//


/////////////////

/obj/item/organ/cyberimp/arm/power_cord
	name = "power cord implant"
	desc = "An internal power cord hooked up to a battery. Useful if you run on volts."
	contents = newlist(/obj/item/apc_powercord)
	zone = "l_arm"

/obj/item/apc_powercord
	name = "power cord"
	desc = "An internal power cord hooked up to a battery. Useful if you run on electricity. Not so much otherwise."
	icon = 'icons/obj/power.dmi'
	icon_state = "wire1"
	var/in_use = FALSE	//No stacking doafters
	/// Powercord shares power with others, not draws
	var/power_sharing_mod = FALSE

/obj/item/apc_powercord/examine(user)
	. = ..()
	if(in_use)
		. += span_info("It's already connected to something")

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/human_user = user

	if(loc == human_user && isrobotic(human_user) && HAS_TRAIT(human_user, TRAIT_BLUEMOON_POWERSHARING))
		. += span_info("Powersharing capabilities are currently <b>[power_sharing_mod ? "ON" : "OFF"]</b>, you can toggle them by <b>using in hand</b> your power cord")
		. += span_green("\n You currently have <b>[human_user.nutrition]</b> charge units or roughly <b>[human_user.nutrition * 6]W</b> left")

/obj/item/apc_powercord/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	user.DelayNextAction(CLICK_CD_MELEE)

	if(!ishuman(user) || !proximity_flag)
		return ..()
	var/mob/living/carbon/human/H = user

	if(in_use)
		to_chat(H, "<span class='warning'>[src] is already connected to something!</span>")
		return

	var/obj/item/organ/stomach/ipc/cell = locate(/obj/item/organ/stomach/ipc) in H.internal_organs
	if(!cell)
		to_chat(H, "<span class='warning'>Your power cell is missing!</span>")
		return

	if(power_sharing_mod)
		if(H.nutrition <= NUTRITION_LEVEL_STARVING)
			to_chat(user, "<span class='warning'>You have too low energy level to share!</span>")
			return

		if(istype(target, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/A = target
			if(A.cell && A.cell.charge <= A.cell.maxcharge - 50)
				in_use = TRUE
				apc_powershare_loop(A, H)
				return

		else if(istype(target, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = target
			if(C.charge <= C.maxcharge - 50)
				in_use = TRUE
				cell_powershare_loop(C, H)
				return

		else if(istype(target, /mob/living/carbon/human))
			var/mob/living/carbon/human/comrade = target
			if(comrade == H)
				to_chat(H, span_warning("You can't charge yourself!"))
				return
			if(!isrobotic(comrade))
				to_chat(H, span_warning("[target] is organic! Boowomp..."))
				return
			var/obj/item/apc_powercord/c_cord = locate(/obj/item/apc_powercord) in comrade.held_items
			if(!c_cord)
				to_chat(H, span_warning("Ask [comrade] to extract [comrade.p_their()] power cord!"))
				return
			var/obj/item/organ/stomach/ipc/c_cell = locate(/obj/item/organ/stomach/ipc) in comrade.internal_organs
			if(!c_cell)
				to_chat(H, span_warning("[comrade] lacks power cell!"))
				return
			if(comrade.nutrition >= NUTRITION_LEVEL_WELL_FED)
				to_chat(H, span_warning("[comrade] is already charged!"))
				return
			playsound(src, 'sound/misc/menu/ui_select1.ogg', 30, 1, -1)
			synth_powershare_loop(comrade, H)

		else if(istype(target, /mob/living/silicon/robot))
			var/mob/living/silicon/robot/borgy = target
			if(!borgy.cell)
				to_chat(H, span_warning("[borgy] lacks power cell!"))
				return
			if(borgy.cell.charge >= borgy.cell.maxcharge - 50)
				to_chat(H, span_warning("[borgy] is already charged!"))
				return
			in_use = TRUE
			playsound(src, 'sound/misc/menu/ui_select1.ogg', 30, 1, -1)
			cyborg_powershare_loop(borgy, H)

		to_chat(H, span_warning("You can't charge [target]!"))
		return ..()

	else
		if(H.nutrition >= NUTRITION_LEVEL_WELL_FED)
			to_chat(user, "<span class='warning'>You are already fully charged!</span>")
			return

		if(istype(target, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/A = target
			if(A.cell && A.cell.charge > 0)
				in_use = TRUE
				apc_powerdraw_loop(A, H)
				return

		else if(istype(target, /obj/item/stock_parts/cell))
			var/obj/item/stock_parts/cell/C = target
			if(C.charge > 0)
				in_use = TRUE
				cell_powerdraw_loop(C, H)
				return

		to_chat(user, "<span class='warning'>There is no charge to draw from [target].</span>")
		return ..()

/obj/item/apc_powercord/attack_self(mob/user)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(!isrobotic(H) || !HAS_TRAIT(H, TRAIT_BLUEMOON_POWERSHARING))
		to_chat(H, span_warning("У вас нет приспособлений для раздачи энергии!"))
		return
	power_sharing_mod = !power_sharing_mod
	playsound(src, 'sound/misc/menu/ui_select1.ogg', 30, 1, -1)
	to_chat(H, span_notice("Раздача энергии [power_sharing_mod ? "включена" : "выключена"]."))

/obj/item/apc_powercord/proc/apc_powerdraw_loop(obj/machinery/power/apc/A, mob/living/carbon/human/H)
	H.visible_message("<span class='notice'>[H] inserts a power connector into [A].</span>", "<span class='notice'>You begin to draw power from [A].</span>")
	while(do_after(H, 10, target = A))
		if(loc != H)
			to_chat(H, "<span class='warning'>You must keep your connector out while charging!</span>")
			break
		if(A.cell.charge == 0)
			to_chat(H, "<span class='warning'>[A] doesn't have enough charge to spare.</span>")
			break
		A.charging = 1
		if(A.cell.charge >= 500)
			do_sparks(1, FALSE, A)
			H.adjust_nutrition(50)
			A.cell.use(300)
			to_chat(H, "<span class='notice'>You siphon off some of the stored charge for your own use.</span>")
		else
			H.adjust_nutrition(A.cell.charge/6)
			A.cell.use(A.cell.charge)
			to_chat(H, "<span class='notice'>You siphon off as much as [A] can spare.</span>")
			break
		if(H.nutrition > NUTRITION_LEVEL_WELL_FED)
			to_chat(H, "<span class='notice'>You are now fully charged.</span>")
			break
	in_use = FALSE
	H.visible_message("<span class='notice'>[H] unplugs from [A].</span>", "<span class='notice'>You unplug from [A].</span>")

/obj/item/apc_powercord/proc/apc_powershare_loop(obj/machinery/power/apc/A, mob/living/carbon/human/H)
	H.visible_message(span_notice("[H] inserts a power connector into [A]."), span_notice("You begin to share power with [A]."))
	while(do_after(H, 10, target = A))
		if(loc != H)
			to_chat(H, span_warning("You must keep your connector out while charging!"))
			break
		if(!power_sharing_mod)
			to_chat(H, span_warning("You disabled powersharing mod. Aborting."))
			break
		if(H.nutrition <= NUTRITION_LEVEL_STARVING)
			to_chat(H, span_warning("You have too low energy level to share!"))
			break
		if(!A.cell)
			to_chat(H, span_warning("APC cell is missing!"))
			break
		if(A.cell.charge >= A.cell.maxcharge - 50)
			to_chat(H, span_warning("[A] is fully charged."))
			break

		H.adjust_nutrition(-50)
		A.cell.give(300)
		to_chat(H, span_notice("You share some charge with [A]"))

	in_use = FALSE
	H.visible_message(span_notice("[H] unplugs from [A]"), span_notice("You unplug from [A]."))

/obj/item/apc_powercord/proc/cell_powerdraw_loop(obj/item/stock_parts/cell/C, mob/living/carbon/human/H)
	H.visible_message("<span class='notice'>[H] connects a power cord to [C]</span>", "<span class='notice'>You begin to draw power from [C].</span>")
	while(do_after(H, 10, target = C))
		if(loc != H)
			to_chat(H, "<span class='warning'>You must keep your connector out while charging!</span>")
			break
		if(C.charge == 0)
			to_chat(H, "<span class='warning'>[C] doesn't have any charge remaining.</span>")
			break
		var/siphoned_charge = min(C.charge, 2000)
		C.use(siphoned_charge)
		do_sparks(1, FALSE, C)
		H.adjust_nutrition(siphoned_charge / 100)	//Less efficient on a pure power basis than APC recharge. Still a very viable way of gaining nutrition. (100 nutrition / base 10k cell)
		if(H.nutrition > NUTRITION_LEVEL_WELL_FED)
			to_chat(H, "<span class='notice'>You are now fully charged.</span>")
			break
	in_use = FALSE
	H.visible_message("<span class='notice'>[H] disconnects [src] from [C].</span>", "<span class='notice'>You disconnect from [C].</span>")

/obj/item/apc_powercord/proc/cell_powershare_loop(obj/item/stock_parts/cell/C, mob/living/carbon/human/H)
	H.visible_message(span_notice("[H] connects a power cord to [C]."), span_notice("You begin to charge [C]."))
	while(do_after(H, 10, target = C))
		if(loc != H)
			to_chat(H, span_warning("You must keep your connector out while charging!"))
			break
		if(!power_sharing_mod)
			to_chat(H, span_warning("You disabled powersharing mod. Aborting."))
			break
		if(H.nutrition <= NUTRITION_LEVEL_STARVING)
			to_chat(H, span_warning("You have too low energy level to share!"))
			break
		if(C.charge >= C.maxcharge - 50)
			to_chat(H, span_warning("[C] is fully charged."))
			break

		H.adjust_nutrition(-50)
		C.give(300)
		do_sparks(1, FALSE, C)
		to_chat(H, span_notice("You share some charge with [C]"))

	in_use = FALSE
	H.visible_message(span_notice("[H] disconnects from [C]."), span_notice("You disconnect from [C]."))

/obj/item/apc_powercord/proc/synth_powershare_loop(mob/living/carbon/human/charged_synth, mob/living/carbon/human/H)
	H.visible_message(span_notice("[H] connects [H.p_their()] power cord with [charged_synth]'s one'."), span_notice("You begin to share power with [charged_synth]."))
	while(do_after(H, 10, target = charged_synth))
		if(loc != H)
			to_chat(H, span_warning("You must keep your connector out while charging!"))
			break
		if(!power_sharing_mod)
			to_chat(H, span_warning("You disabled powersharing mod. Aborting."))
			break
		if(H.nutrition <= NUTRITION_LEVEL_STARVING)
			to_chat(H, span_warning("You have too low energy level to share!"))
			break
		if(charged_synth.nutrition >= NUTRITION_LEVEL_WELL_FED)
			to_chat(H, span_warning("[charged_synth] is fully charged!"))
			break
		var/obj/item/apc_powercord/c_cord = locate(/obj/item/apc_powercord) in charged_synth.held_items
		if(!c_cord)
			to_chat(H, span_warning("Ask [charged_synth] to NOT collapse [charged_synth.p_their()] power cord!"))
			break

		H.adjust_nutrition(-50)
		charged_synth.adjust_nutrition(50)
		do_sparks(1, FALSE, charged_synth)
		to_chat(H, span_notice("You share some charge with [charged_synth]"))

	in_use = FALSE
	H.visible_message(span_notice("[charged_synth] separates [H.p_their()] power cord from [charged_synth]."), span_notice("You unplug from [charged_synth]."))

/obj/item/apc_powercord/proc/cyborg_powershare_loop(mob/living/silicon/robot/B, mob/living/carbon/human/H)
	H.visible_message(span_notice("[H] inserts a power connector into [B]'s charging port."), span_notice("You begin to share power with [B]."))
	while(do_after(H, 10, target = B))
		if(loc != H)
			to_chat(H, span_warning("You must keep your connector out while charging!"))
			break
		if(!power_sharing_mod)
			to_chat(H, span_warning("You disabled powersharing mod. Aborting."))
			break
		if(H.nutrition <= NUTRITION_LEVEL_STARVING)
			to_chat(H, span_warning("You have too low energy level to share!"))
			break
		if(!B.cell)
			to_chat(H, span_warning("Borg's cell is missing!"))
			break
		if(B.cell.charge >= B.cell.maxcharge - 50)
			to_chat(H, span_warning("[B] is fully charged."))
			break

		H.adjust_nutrition(-50)
		B.cell.give(300)
		do_sparks(1, FALSE, B)
		to_chat(H, span_notice("You share some charge with [B]"))

	in_use = FALSE
	H.visible_message(span_notice("[H] unplugs from [B]"), span_notice("You unplug from [B]."))
