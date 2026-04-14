/// File location for the long gun's speech
#define LONG_MOD_LASER_SPEECH "saibasan/long_modular_laser.json"
/// File location for the short gun's speech
#define SHORT_MOD_LASER_SPEECH "saibasan/short_modular_laser.json"
/// How long the gun should wait between speaking to lessen spam
#define MOD_LASER_SPEECH_COOLDOWN 2 SECONDS
/// What color is the default kill mode for these guns, used to make sure the chat colors are right at roundstart
#define DEFAULT_RUNECHAT_GUN_COLOR "#cd4456"

// Modular energy weapons, laser guns that can transform into different variants after a few seconds of waiting and animation
// Long version, takes both hands to use and doesn't fit in any bags out there
/obj/item/gun/energy/modular_laser_rifle
	name = "\improper Hyeseong modular laser rifle"
	desc = "A popular energy weapon system that can be reconfigured into many different variants on the fly. \
		Seen commonly amongst the Marsians who produce the weapon, with many different shapes and sizes to fit \
		the wide variety of modders the planet is home to."
	base_icon_state = "hyeseong"
	icon = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/guns48x.dmi'
	icon_state = "hyeseong_kill"
	lefthand_file = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/guns_righthand.dmi'
	item_state = "hyeseong_kill"
	mob_overlay_icon = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/guns_worn.dmi'
	cell_type = /obj/item/stock_parts/cell/hyeseong_internal_cell
	modifystate = FALSE
	ammo_type = list(/obj/item/ammo_casing/energy/cybersun_big_kill)
	ammo_x_offset = 0
	selfcharge = 1
	charge_delay = 1
	selfcharge_amount = 200
	shaded_charge = TRUE
	slot_flags = ITEM_SLOT_BACK
	obj_flags = UNIQUE_RENAME
	SET_BASE_PIXEL(-8, 0)
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_MEDIUM
	actions_types = list(/datum/action/item_action/toggle_personality)
	recoil = 0.25
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	zoomable = TRUE
	zoom_amt = 8 //Long range, enough to see in front of you, but no tiles behind you.
	zoom_out_amt = 5
	/// What datums of weapon modes can we use?
	var/list/weapon_mode_options = list(
		/datum/laser_weapon_mode,
		/datum/laser_weapon_mode/marksman,
		/datum/laser_weapon_mode/disabler_machinegun,
		/datum/laser_weapon_mode/launcher,
		/datum/laser_weapon_mode/shotgun,
	)
	/// Populates with a list of weapon mode names and their respective paths on init
	var/list/weapon_mode_name_to_path = list()
	/// Info for the radial menu for switching weapon mode
	var/list/radial_menu_data = list()
	/// Is the gun currently changing types? Prevents the gun from firing if yes
	var/currently_switching_types = FALSE
	/// How long transitioning takes before you're allowed to pick a weapon type
	var/transition_duration = 1 SECONDS
	/// What the currently selected weapon mode is, for quickly referencing for use in procs and whatnot
	var/datum/laser_weapon_mode/currently_selected_mode
	/// Name of the firing mode that is selected by default
	var/default_selected_mode = "Kill"
	/// Allows firing of the gun to be disabled for any reason, for example, if a gun has a melee mode
	var/disabled_for_other_reasons = FALSE
	/// The json file this gun pulls from when speaking
	var/speech_json_file = LONG_MOD_LASER_SPEECH
	/// Keeps track of the last processed charge, prevents message spam
	var/last_charge = 0
	/// If the gun's personality speech thing is on, defaults to on because just listen to her
	var/personality_mode = TRUE
	/// Extended examine text for examine_more
	var/expanded_examine_text = "The Hyeseong rifle is the first line of man-portable Marsian weapons platforms \
		from Cybersun Industries. Like her younger sister weapon, the Hoshi carbine, CI used funding aid provided \
		by TerraGov to develop a portable weapon fueled by a proprietary generator rumored to be fueled by superstable plasma. \
		A rugged and hefty weapon, the Hyeseong stars in applications anywhere from medium to long ranges, though struggling \
		in CQB. Her onboard machine intelligence, at first devised to support the operator and manage the internal reactor, \
		is shipped with a more professional and understated personality-- since influenced by 'negligence' from users in \
		wiping the intelligence's memory before resale or transport."
	/// A cooldown for when the weapon has last spoken, prevents messages from getting turbo spammed
	COOLDOWN_DECLARE(last_speech)
	/// Whether the battery compartment panel is open (screwdriver to toggle)
	var/panel_open = FALSE
	/// Timer id for the delayed radial menu (so we can cancel it in Destroy)
	var/mode_switch_timer_id

/obj/item/gun/energy/modular_laser_rifle/ComponentInitialize()
	. = ..()
	// Автострельба добавляется при смене режима (apply_to_weapon), а не здесь
	var/datum/component/automatic_fire/af = GetComponent(/datum/component/automatic_fire)
	if(af)
		qdel(af)

/obj/item/gun/energy/modular_laser_rifle/Initialize(mapload)
	. = ..()
	chat_color = DEFAULT_RUNECHAT_GUN_COLOR
	chat_color_darkened = DEFAULT_RUNECHAT_GUN_COLOR
	last_charge = cell.charge
	create_weapon_mode_stuff()

/obj/item/gun/energy/modular_laser_rifle/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		if(cell)
			. += span_notice("Power cell: [round(cell.percent(), 1)]% ([DisplayEnergy(cell.charge)] / [DisplayEnergy(cell.maxcharge)]).")
		else
			. += span_warning("No power cell installed.")
		. += span_notice("The battery compartment is [panel_open ? "open" : "closed"].")
		if(panel_open)
			if(cell)
				. += span_notice("There is a power cell inside.")
			else
				. += span_notice("The battery compartment is empty.")
	. += span_notice("You can <b>examine closer</b> to learn a little more about this weapon.")

/obj/item/gun/energy/modular_laser_rifle/examine_more(mob/user)
	. = ..()
	. += expanded_examine_text

/obj/item/gun/energy/modular_laser_rifle/Destroy()
	if(ismob(loc))
		UnregisterSignal(loc, COMSIG_LIVING_COMBAT_ENABLED)
	if(mode_switch_timer_id)
		deltimer(mode_switch_timer_id)
		mode_switch_timer_id = null
	if(currently_selected_mode)
		currently_selected_mode.remove_from_weapon(src)
		currently_selected_mode = null
	weapon_mode_name_to_path = null
	radial_menu_data = null
	return ..()

// /obj/item/gun/energy/modular_laser_rifle/attackby(obj/item/used_item, mob/living/user, params)
// 	if(used_item.tool_behaviour == TOOL_SCREWDRIVER)
// 		panel_open = !panel_open
// 		playsound(src, used_item.usesound, 50, TRUE)
// 		to_chat(user, span_notice("You [panel_open ? "open" : "close"] the battery compartment of [src]."))
// 		update_appearance()
// 		return TRUE
// 	if(panel_open && istype(used_item, /obj/item/stock_parts/cell))
// 		var/obj/item/stock_parts/cell/new_cell = used_item
// 		if(!user.transferItemToLoc(new_cell, src))
// 			return
// 		if(cell)
// 			cell.forceMove(drop_location())
// 			user.put_in_hands(cell)
// 			to_chat(user, span_notice("You replace the power cell in [src] with [new_cell]."))
// 		else
// 			to_chat(user, span_notice("You insert [new_cell] into [src]."))
// 		cell = new_cell
// 		last_charge = cell.charge
// 		recharge_newshot(TRUE)
// 		update_appearance()
// 		return TRUE
// 	return ..()

/obj/item/gun/energy/modular_laser_rifle/attack_self(mob/living/user)
	if(panel_open)
		if(cell)
			var/obj/item/stock_parts/cell/old_cell = cell
			cell = null
			chambered = null
			if(!user.put_in_hands(old_cell))
				old_cell.forceMove(drop_location())
			to_chat(user, span_notice("You remove the power cell from [src]."))
			recharge_newshot(TRUE)
			update_appearance()
		else
			to_chat(user, span_warning("The battery compartment is empty!"))
		return
	if(!currently_switching_types)
		change_to_switch_mode(user)
	return ..()

/// Handles filling out all of the lists regarding weapon modes and radials around that
/obj/item/gun/energy/modular_laser_rifle/proc/create_weapon_mode_stuff()
	if(length(weapon_mode_name_to_path) || length(radial_menu_data))
		return // We don't need to worry about it if there's already stuff here
	for(var/datum/laser_weapon_mode/laser_mode as anything in weapon_mode_options)
		weapon_mode_name_to_path["[initial(laser_mode.name)]"] = new laser_mode()
		var/datum/laser_weapon_mode/mode_instance = weapon_mode_name_to_path["[initial(laser_mode.name)]"]
		var/radial_icon
		var/radial_state
		if(mode_instance.radial_menu_icon && mode_instance.radial_menu_icon_state)
			radial_icon = mode_instance.radial_menu_icon
			radial_state = mode_instance.radial_menu_icon_state
		else
			var/obj/item/projectile/mode_projectile = initial(laser_mode.casing.projectile_type)
			radial_icon = mode_projectile.icon
			radial_state = mode_projectile.icon_state
		radial_menu_data["[initial(laser_mode.name)]"] = image(icon = radial_icon, icon_state = radial_state)
	currently_selected_mode = weapon_mode_name_to_path["[default_selected_mode]"]
	transform_gun(currently_selected_mode, FALSE, TRUE)

/// Makes the gun inoperable, playing an animation and giving a prompt to switch gun modes after the transition_duration passes
/obj/item/gun/energy/modular_laser_rifle/proc/change_to_switch_mode(mob/living/user)
	currently_switching_types = TRUE
	flick("[base_icon_state]_switch_on", src)
	cut_overlays()
	playsound(src, 'sound/items/modsuit/ballin.ogg', 75, TRUE)
	var/new_icon_state = "[base_icon_state]_switch"
	icon_state = new_icon_state
	item_state = new_icon_state
	if(mode_switch_timer_id)
		deltimer(mode_switch_timer_id)
	mode_switch_timer_id = addtimer(CALLBACK(src, PROC_REF(show_radial_choice_menu), user), transition_duration, TIMER_STOPPABLE)
/// Shows the radial choice menu to the user, if the user doesnt exist or isnt holding the gun anymore, it reverts back to its last form
/obj/item/gun/energy/modular_laser_rifle/proc/show_radial_choice_menu(mob/living/user)
	if(!user?.is_holding(src))
		flick("[base_icon_state]_switch_off", src)
		transform_gun(currently_selected_mode, FALSE)
		playsound(src, 'sound/items/modsuit/ballout.ogg', 75, TRUE)
		return

	var/picked_choice = show_radial_menu(
		user,
		src,
		radial_menu_data,
		require_near = TRUE,
		tooltips = TRUE,
		)

	if(isnull(picked_choice) || isnull(weapon_mode_name_to_path["[picked_choice]"]))
		flick("[base_icon_state]_switch_off", src)
		transform_gun(currently_selected_mode, FALSE)
		playsound(src, 'sound/items/modsuit/ballout.ogg', 75, TRUE)
		return

	var/new_weapon_mode = weapon_mode_name_to_path["[picked_choice]"]
	transform_gun(new_weapon_mode, TRUE)

/// Transforms the gun into a different type, if replacing is set to true then it'll make sure to remove any effects the prior gun type had
/obj/item/gun/energy/modular_laser_rifle/proc/transform_gun(datum/laser_weapon_mode/new_weapon_mode, replacing = TRUE, dont_speak = FALSE)
	if(!new_weapon_mode)
		stack_trace("transform_gun was called but didn't get a new weapon mode, meaning it couldn't work.")
		return
	if(replacing && currently_selected_mode)
		currently_selected_mode.remove_from_weapon(src)
	currently_selected_mode = new_weapon_mode
	flick("[base_icon_state]_switch_off", src)
	currently_selected_mode.apply_stats(src)
	currently_selected_mode.apply_to_weapon(src)
	playsound(src, 'sound/items/modsuit/ballout.ogg', 75, TRUE)
	if(!dont_speak)
		speak_up(currently_selected_mode.json_speech_string, TRUE)
	currently_switching_types = FALSE

/obj/item/gun/energy/modular_laser_rifle/can_trigger_gun(mob/living/user, akimbo_usage)
	. = ..()
	if(currently_switching_types || disabled_for_other_reasons)
		return FALSE

/// Makes the gun speak with a sound effect and colored runetext based on the mode the gun is in, reads the gun's speech json as defined through variables
/obj/item/gun/energy/modular_laser_rifle/proc/speak_up(json_string, ignores_cooldown = FALSE, ignores_personality_toggle = FALSE)
	if(!personality_mode && !ignores_personality_toggle)
		return
	if(!json_string)
		return
	if(!ignores_cooldown && !COOLDOWN_FINISHED(src, last_speech))
		return
	say(pick_list_replacements(speech_json_file, json_string))
	playsound(src, 'sound/mobs/non-humanoids/tourist/tourist_talk.ogg', 15, TRUE, SHORT_RANGE_SOUND_EXTRARANGE, frequency = rand(2, 2.2))
	Shake(2, 2, 1 SECONDS)
	COOLDOWN_START(src, last_speech, MOD_LASER_SPEECH_COOLDOWN)

/obj/item/gun/energy/modular_laser_rifle/equipped(mob/user, slot, initial)
	. = ..()
	if(slot & (ITEM_SLOT_BELT|ITEM_SLOT_BACK|ITEM_SLOT_SUITSTORE))
		speak_up("worn")
	else if(slot & ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_LIVING_COMBAT_ENABLED, PROC_REF(on_combat_enabled))
		speak_up("pickup")
		return
	UnregisterSignal(user, COMSIG_LIVING_COMBAT_ENABLED)

/obj/item/gun/energy/modular_laser_rifle/dropped(mob/user, silent)
	. = ..()
	if(src in user.contents)
		return // If they're still holding us or have us on them, dw about it
	UnregisterSignal(user, COMSIG_LIVING_COMBAT_ENABLED)
	speak_up("putdown")

/obj/item/gun/energy/modular_laser_rifle/process(seconds_per_tick)
	. = ..()
	if(!cell)
		return
	var/cell_charge_quarter = cell.maxcharge / 4
	if((cell_charge_quarter > cell.charge) && !(last_charge < cell_charge_quarter))
		speak_up("lowcharge")
	else if((cell.maxcharge == cell.charge) && !(last_charge == cell.maxcharge))
		speak_up("fullcharge")
	last_charge = cell.charge

/// Called when the holder enables combat mode (combat indicator).
/obj/item/gun/energy/modular_laser_rifle/proc/on_combat_enabled(mob/living/source)
	SIGNAL_HANDLER
	speak_up("combatmode")

/obj/item/gun/energy/modular_laser_rifle/ui_action_click(mob/user, actiontype)
	if(!istype(actiontype, /datum/action/item_action/toggle_personality))
		return ..()
	playsound(src, 'sound/machines/beep.ogg', 30, TRUE)
	personality_mode = !personality_mode
	speak_up("[personality_mode ? "pickup" : "putdown"]", ignores_personality_toggle = TRUE)
	return ..()

// Power cell for the big rifle
/obj/item/stock_parts/cell/hyeseong_internal_cell
	name = "\improper Hyeseong modular laser rifle internal cell"
	desc = "These are usually supposed to be inside of the gun, you know."
	maxcharge = 10000

/datum/action/item_action/toggle_personality
	name = "Toggle Weapon Personality"
	desc = "Toggles the weapon's personality core. Studies find that turning them off makes them quite sad, however."
	background_icon_state = "bg_mod"

//Short version of the above modular rifle, has less charge and different modes
/obj/item/gun/energy/modular_laser_rifle/carbine
	name = "\improper Hoshi modular laser carbine"
	icon = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/guns32x.dmi'
	icon_state = "hoshi_kill"
	item_state = "hoshi_kill"
	base_icon_state = "hoshi"
	charge_sections = 3
	cell_type = /obj/item/stock_parts/cell/hyeseong_internal_cell
	ammo_type = list(/obj/item/ammo_casing/energy/cybersun_small_hellfire)
	slot_flags = ITEM_SLOT_BACK | ITEM_SLOT_BELT
	SET_BASE_PIXEL(0, 0)
	w_class = WEIGHT_CLASS_NORMAL
	weapon_weight = WEAPON_LIGHT
	weapon_mode_options = list(
		/datum/laser_weapon_mode/hellfire,
		/datum/laser_weapon_mode/sword,
		/datum/laser_weapon_mode/flare,
		/datum/laser_weapon_mode/shotgun_small,
		/datum/laser_weapon_mode/trickshot_disabler,
	)
	default_selected_mode = "Incinerate"
	speech_json_file = SHORT_MOD_LASER_SPEECH
	expanded_examine_text = "The Hoshi carbine is the latest line of man-portable Marsian weapons platforms from \
		Cybersun Industries. Like her older sister weapon, the Hyeseong rifle, CI used funding aid provided by TerraGov \
		to develop a portable weapon fueled by a proprietary generator rumored to be fueled by superstable plasma. A \
		lithe and mobile weapon, the Hoshi stars in close-quarters battle, trickshots, and area-of-effect blasts; though \
		ineffective at ranged combat. Her onboard machine intelligence, at first devised to support the operator and \
		manage the internal reactor, was originally shipped with a more energetic personality-- since influenced by 'negligence' \
		from users in wiping the intelligence's memory before resale or transport."

/obj/item/gun/energy/modular_laser_rifle/carbine/emp_act(severity)
	. = ..()
	speak_up("emp", TRUE) // She gets very upset if you emp her

#undef LONG_MOD_LASER_SPEECH
#undef SHORT_MOD_LASER_SPEECH
#undef MOD_LASER_SPEECH_COOLDOWN
#undef DEFAULT_RUNECHAT_GUN_COLOR
