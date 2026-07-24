#define WAND_OPEN "open"
#define WAND_BOLT "bolt"
#define WAND_EMERGENCY "emergency"
#define WAND_SHOCK "shock"
#define WAND_DEPOWER "depower"

/obj/item/door_remote
	icon_state = "remote_civilian_open"
	base_icon_state = "remote"
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	icon = 'icons/obj/device.dmi'
	name = "control wand"
	desc = "A remote for controlling a set of airlocks."
	w_class = WEIGHT_CLASS_TINY
	drop_sound = 'sound/items/door_remote/door_remote_drop1.ogg'
	pickup_sound = 'sound/items/door_remote/door_remote_pick_up1.ogg'

	var/department = "civilian"
	var/mode = WAND_OPEN
	var/region_access = 1 // see get_region_accesses() in access.dm
	var/list/access_list = list()
	var/list/extra_access = list()
	var/list/area/our_domain = null
	var/static/list/area/restricted_areas = list(
		/area/command/bridge,
		/area/security,
		/area/ai_monitored/turret_protected/ai_upload,
		/area/ai_monitored/turret_protected/ai,
	)
	COOLDOWN_DECLARE(shock_cooldown)
	var/mode_switch_sound = SFX_REMOTE_MODE_SWITCH
	var/action_sound = SFX_REMOTE_ACTION

/obj/item/door_remote/Initialize(mapload)
	. = ..()
	update_icon_state()
	return INITIALIZE_HINT_LATELOAD

/obj/item/door_remote/LateInitialize()
	access_list = get_region_accesses(region_access) | extra_access

/obj/item/door_remote/proc/is_my_domain(area/restricted_area)
	if(!our_domain)
		return FALSE
	for(var/area/dominion as anything in our_domain)
		if(istype(restricted_area, dominion))
			return TRUE
	return FALSE

/obj/item/door_remote/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	. = ..()
	balloon_alert(user, "restricted functions unlocked")
	obj_flags |= EMAGGED
	update_icon_state()

/obj/item/door_remote/attack_self(mob/user)
	var/static/list/ops = list(
		WAND_OPEN = "Open Door",
		WAND_BOLT = "Toggle Bolts",
		WAND_EMERGENCY = "Toggle Emergency Access",
		WAND_SHOCK = "Shock Door",
		WAND_DEPOWER = "Depower Door",
	)
	switch(mode)
		if(WAND_OPEN)
			mode = WAND_BOLT
		if(WAND_BOLT)
			mode = WAND_EMERGENCY
		if(WAND_EMERGENCY)
			if(!(obj_flags & EMAGGED))
				mode = WAND_OPEN
			else
				mode = WAND_SHOCK
		if(WAND_SHOCK)
			mode = WAND_DEPOWER
		if(WAND_DEPOWER)
			mode = WAND_OPEN
	update_icon_state()
	balloon_alert(user, "mode: [ops[mode]]")
	if(mode_switch_sound)
		playsound(src, mode_switch_sound, 50, TRUE)

/obj/item/door_remote/afterattack(atom/target, mob/user, proximity, params)
	. = ..()
	if(!user || !target)
		return
	interact_remote(target, user)

/obj/item/door_remote/proc/interact_remote(atom/interacting_with, mob/living/user)
	var/obj/machinery/door/door
	if(action_sound)
		playsound(src, action_sound, 50, TRUE)

	if(istype(interacting_with, /obj/machinery/door))
		door = interacting_with
		if(!door.opens_with_door_remote)
			return
	else
		for(var/obj/machinery/door/door_on_turf in get_turf(interacting_with))
			if(door_on_turf.opens_with_door_remote)
				door = door_on_turf
				break
		if(isnull(door))
			return

	if(!door.check_access_list(access_list) || !door.requiresID())
		interacting_with.balloon_alert(user, "can't access!")
		return

	var/area/door_area = get_area(door)
	if(is_type_in_list(door_area, restricted_areas) && !is_my_domain(door_area))
		interacting_with.balloon_alert(user, "can't access!")
		return

	var/obj/machinery/door/airlock/airlock = door

	if(!door.hasPower() || (istype(airlock) && !airlock.canAIControl()))
		interacting_with.balloon_alert(user, mode == WAND_OPEN ? "it won't budge!" : "nothing happens!")
		return

	switch(mode)
		if(WAND_OPEN)
			if(door.density)
				door.open()
			else
				door.close()
		if(WAND_BOLT)
			if(!istype(airlock))
				interacting_with.balloon_alert(user, "only airlocks!")
				return
			if(airlock.locked)
				airlock.unbolt()
				log_combat(user, airlock, "unbolted", src)
			else
				airlock.bolt()
				log_combat(user, airlock, "bolted", src)
		if(WAND_EMERGENCY)
			if(!istype(airlock))
				interacting_with.balloon_alert(user, "only airlocks!")
				return
			airlock.emergency = !airlock.emergency
			airlock.update_icon()
		if(WAND_SHOCK)
			if(!istype(airlock))
				interacting_with.balloon_alert(user, "only airlocks!")
				return
			if(!COOLDOWN_FINISHED(src, shock_cooldown))
				interacting_with.balloon_alert(user, "shock pulse resetting!")
				return
			if(airlock.isElectrified())
				interacting_with.balloon_alert(user, "already electrified!")
			else
				airlock.set_electrified(MACHINE_DEFAULT_ELECTRIFY_TIME, user)
				COOLDOWN_START(src, shock_cooldown, 10 SECONDS)
		if(WAND_DEPOWER)
			if(!istype(airlock))
				interacting_with.balloon_alert(user, "only airlocks!")
				return
			if(!airlock.secondsMainPowerLost)
				airlock.loseMainPower()
			else if(!airlock.secondsBackupPowerLost)
				airlock.loseBackupPower()

/obj/item/door_remote/update_icon_state()
	var/icon_state_mode
	if(!(obj_flags & EMAGGED))
		switch(mode)
			if(WAND_OPEN)
				icon_state_mode = "open"
			if(WAND_BOLT)
				icon_state_mode = "bolt"
			if(WAND_EMERGENCY)
				icon_state_mode = "emergency"
	else
		icon_state_mode = "emergency"

	icon_state = "[base_icon_state]_[department]_[icon_state_mode]"
	return ..()

/obj/item/door_remote/omni
	name = "omni door remote"
	desc = "This control wand can access any door on the station."
	department = "omni"
	region_access = 0
	our_domain = list(/area)

/obj/item/door_remote/captain
	name = "command door remote"
	desc = "A remote for controlling command airlocks."
	department = "command"
	region_access = 7
	our_domain = list(/area/command)

/obj/item/door_remote/chief_engineer
	name = "engineering door remote"
	desc = "A remote for controlling engineering airlocks."
	department = "engi"
	region_access = 5
	extra_access = list(ACCESS_CE)

/obj/item/door_remote/research_director
	name = "research door remote"
	desc = "A remote for controlling research airlocks."
	department = "sci"
	region_access = 4
	extra_access = list(ACCESS_RD)
	our_domain = list(
		/area/ai_monitored/turret_protected/ai,
		/area/ai_monitored/turret_protected/ai_upload,
	)

/obj/item/door_remote/head_of_security
	name = "security door remote"
	desc = "A remote for controlling security airlocks."
	department = "security"
	region_access = 2
	extra_access = list(ACCESS_HOS)
	our_domain = list(/area/security)

/obj/item/door_remote/quartermaster
	name = "cargo door remote"
	desc = "A remote for controlling cargo airlocks."
	department = "cargo"
	region_access = 6
	extra_access = list(ACCESS_QM, ACCESS_VAULT)

/obj/item/door_remote/chief_medical_officer
	name = "medical door remote"
	desc = "A remote for controlling medical airlocks."
	department = "med"
	region_access = 3
	extra_access = list(ACCESS_CMO)

/obj/item/door_remote/head_of_personnel
	name = "service door remote"
	desc = "A remote for controlling service airlocks."
	department = "civilian"
	region_access = 1
	extra_access = list(ACCESS_HOP)

/obj/item/door_remote/civillian
	name = "civilian door remote"
	desc = "A remote for controlling civilian airlocks."
	department = "civilian"
	region_access = 1

/obj/item/door_remote/away
	name = "away door remote"
	desc = "A remote for controlling away mission airlocks."
	department = "civilian"
	region_access = 8

#undef WAND_OPEN
#undef WAND_BOLT
#undef WAND_EMERGENCY
#undef WAND_SHOCK
#undef WAND_DEPOWER
