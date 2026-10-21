//DO NOT ADD MECHA PARTS TO THE GAME WITH THE DEFAULT "SPRITE ME" SPRITE!
//I'm annoyed I even have to tell you this! SPRITE FIRST, then commit.

/obj/item/mecha_parts/mecha_equipment
	name = "mecha equipment"
	icon = 'icons/mecha/mecha_equipment.dmi'
	icon_state = "mecha_equip"
	force = 5
	max_integrity = 300
	var/equip_cooldown = 0
	var/equip_ready = TRUE //whether the equipment is ready for use. (or deactivated/activated for static stuff)
	var/energy_drain = 0
	var/obj/vehicle/sealed/mecha/chassis = null
	///Bitflag. Determines the range of the equipment.
	var/range = MECHA_MELEE
	/// Bitflag. Used by exosuit fabricator to assign sub-categories based on which exosuits can equip this.
	var/mech_flags = NONE
	var/salvageable = 1
	var/detachable = TRUE // Set to FALSE for built-in equipment that cannot be removed
	var/selectable = 1	// Set to 0 for passive equipment such as mining scanner or armor plates
	var/harmful = FALSE //Controls if equipment can be used to attack by a pacifist.
	var/destroy_sound = 'sound/mecha/critdestr.ogg'
	var/mecha_subcategory_flags // BLUEMOON ADD
	// Действие для модулей, которые включаются без выбора цели.
	var/ui_toggle_action
	var/list/pilot_actions = list()
	var/ui_icon

/obj/item/mecha_parts/mecha_equipment/proc/update_chassis_page()
	if(chassis)
		SStgui.update_uis(chassis)
		return TRUE
	return

/obj/item/mecha_parts/mecha_equipment/proc/update_equip_info()
	if(chassis)
		chassis.update_equipment_buttons()
		SStgui.update_uis(chassis)
		return TRUE
	return

/obj/item/mecha_parts/mecha_equipment/Destroy()
	QDEL_LIST_ASSOC_VAL(pilot_actions)
	if(chassis)
		LAZYREMOVE(chassis.equipment, src)
		if(chassis.selected == src)
			chassis.selected = null
		if(chassis.selected_right == src)
			chassis.selected_right = null
		update_chassis_page()
		log_message("[src] is destroyed.", LOG_MECHA)
		if(!LAZYLEN(chassis?.occupants))
			to_chat(chassis.occupants, "[icon2html(src, chassis.occupants)]<span class='danger'>[src] is destroyed!</span>")
			playsound(chassis, destroy_sound, 50)
		if(!detachable) //If we're a built-in nondetachable equipment, let's lock up the slot that we were in.
			chassis.max_equip--
		chassis = null
	return ..()

/obj/item/mecha_parts/mecha_equipment/try_attach_part(mob/user, obj/vehicle/sealed/mecha/M)
	if(can_attach(M))
		if(!user.temporarilyRemoveItemFromInventory(src))
			return FALSE
		attach(M)
		user.visible_message("<span class='notice'>[user] attaches [src] to [M].</span>", "<span class='notice'>You attach [src] to [M].</span>")
		return TRUE
	to_chat(user, "<span class='warning'>You are unable to attach [src] to [M]!</span>")
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/action_checks(atom/target)
	if(!target)
		return FALSE
	if(!chassis)
		return FALSE
	if(!equip_ready)
		return FALSE
	if(energy_drain && !chassis.has_charge(energy_drain))
		return FALSE
	if(chassis.is_currently_ejecting)
		return FALSE
	if(chassis.equipment_disabled)
		to_chat(chassis.occupants, "<span=warn>Error -- Equipment control unit is unresponsive.</span>")
		return FALSE
	if(TIMER_COOLDOWN_CHECK(chassis, COOLDOWN_MECHA_EQUIPMENT))
		return FALSE
	return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/action(mob/source, atom/target, params)
	TIMER_COOLDOWN_START(chassis, COOLDOWN_MECHA_EQUIPMENT, equip_cooldown)//Cooldown is on the MECH so people dont bypass it by switching equipment
	SStgui.update_uis(chassis)
	chassis.use_power(energy_drain)
	return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/do_after_cooldown(atom/target, mob/user)
	if(!chassis)
		return FALSE
	chassis.use_power(energy_drain)
	return do_after(user, equip_cooldown, target, extra_checks = CALLBACK(src, PROC_REF(do_after_checks), target))

/obj/item/mecha_parts/mecha_equipment/proc/do_after_mecha(atom/target, mob/user, delay)
	return do_after(user, delay, target, extra_checks = CALLBACK(src, PROC_REF(do_after_checks), target))

/// do after checks for the mecha equipment do afters
/obj/item/mecha_parts/mecha_equipment/proc/do_after_checks(atom/target)
	return chassis && (get_dir(chassis, target) & chassis.dir)

/obj/item/mecha_parts/mecha_equipment/proc/can_attach(obj/vehicle/sealed/mecha/M)
	if(LAZYLEN(M.equipment)<M.max_equip)
		return TRUE

/obj/item/mecha_parts/mecha_equipment/proc/attach(obj/vehicle/sealed/mecha/M)
	LAZYADD(M.equipment, src)
	chassis = M
	forceMove(M)
	for(var/mob/pilot as anything in M.occupants)
		grant_pilot_action(pilot)
	log_message("[src] initialized.", LOG_MECHA)
	update_chassis_page()
	return

/obj/item/mecha_parts/mecha_equipment/proc/detach(atom/moveto=null)
	moveto = moveto || get_turf(chassis)
	if(src.Move(moveto))
		QDEL_LIST_ASSOC_VAL(pilot_actions)
		LAZYREMOVE(chassis.equipment, src)
		if(chassis.selected == src)
			chassis.selected = null
		if(chassis.selected_right == src)
			chassis.selected_right = null
		update_chassis_page()
		log_message("[src] removed from equipment.", LOG_MECHA)
		chassis = null
	return


/obj/item/mecha_parts/mecha_equipment/log_message(message, message_type=LOG_GAME, color=null, log_globally, atom/target = null)
	if(chassis)
		chassis.log_message("ATTACHMENT: [src] [message]", message_type, color, log_globally, target = target)
	else
		..(message, message_type, color, log_globally, target)


//Used for reloading weapons/tools etc. that use some form of resource
/obj/item/mecha_parts/mecha_equipment/proc/rearm()
	return FALSE


/obj/item/mecha_parts/mecha_equipment/proc/needs_rearm()
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/get_ui_data()
	if(!ui_icon)
		ui_icon = icon2base64(icon(icon, icon_state, SOUTH))
	return list(
		"name" = name,
		"desc" = desc,
		"image" = ui_icon,
		"ref" = REF(src),
		"integrity" = obj_integrity / max_integrity,
		"detachable" = detachable,
		"can_be_triggered" = selectable,
		"can_be_toggled" = !!ui_toggle_action,
		"active" = is_ui_active(),
		"toggle_action" = ui_toggle_action,
		"selected_left" = chassis.selected == src,
		"selected_right" = chassis.selected_right == src,
		"equip_cooldown" = equip_cooldown && DisplayTimeText(equip_cooldown),
		"energy_per_use" = energy_drain,
		"snowflake" = null,
	)

/obj/item/mecha_parts/mecha_equipment/proc/handle_ui_act(action, list/params)
	if(action == "detach")
		if(!detachable)
			return FALSE
		detach()
		return TRUE
	return FALSE

/obj/item/mecha_parts/mecha_equipment/proc/is_ui_active()
	return ui_toggle_action && (datum_flags & DF_ISPROCESSING)

/obj/item/mecha_parts/mecha_equipment/proc/grant_pilot_action(mob/pilot)
	if((!selectable && !ui_toggle_action) || !(chassis.occupants[pilot] & VEHICLE_CONTROL_EQUIPMENT) || pilot_actions[pilot])
		return
	var/datum/action/vehicle/sealed/mecha/module/action = new(src)
	action.chassis = chassis
	action.equipment = src
	action.name = "[ui_toggle_action ? "Включить/выключить" : "Выбрать"] [name]"
	action.icon_icon = icon
	action.button_icon_state = icon_state
	pilot_actions[pilot] = action
	action.Grant(pilot)

/obj/item/mecha_parts/mecha_equipment/proc/remove_pilot_action(mob/pilot)
	var/datum/action/action = pilot_actions[pilot]
	pilot_actions -= pilot
	qdel(action)

/obj/vehicle/sealed/mecha/proc/update_equipment_buttons()
	for(var/obj/item/mecha_parts/mecha_equipment/module as anything in equipment)
		for(var/pilot in module.pilot_actions)
			var/datum/action/action = module.pilot_actions[pilot]
			action.UpdateButtons()
	for(var/pilot in occupants)
		var/datum/action/vehicle/sealed/mecha/mech_cycle_equip/cycle = LAZYACCESSASSOC(occupant_actions, pilot, /datum/action/vehicle/sealed/mecha/mech_cycle_equip)
		if(cycle)
			cycle.button_icon_state = "mech_cycle_equip_[selected ? "on" : "off"]"
			cycle.UpdateButtons()
