/**
 * Build a radial preview list from the same catalog used to apply skins.
 * Caller may cache/sort the returned list, then append private skins as before.
 */
/obj/item/robot_module/proc/get_borg_skin_preview_icons(list/catalog)
	var/list/previews = list()
	for(var/skin_name in catalog)
		var/list/entry = catalog[skin_name]
		if(!islist(entry))
			continue
		var/image/preview = entry["preview"]
		if(preview)
			previews[skin_name] = preview
	return previews

/**
 * Apply only the properties explicitly present in a cyborg skin profile.
 * The absence of a property leaves the module's original default unchanged.
 * This deliberately does not alter donor checks or selected preview icons.
 */
/obj/item/robot_module/proc/apply_borg_skin_profile(list/profile)
	if(!islist(profile))
		return FALSE
	if("cyborg_base_icon" in profile)
		cyborg_base_icon = profile["cyborg_base_icon"]
	if("cyborg_icon_override" in profile)
		cyborg_icon_override = profile["cyborg_icon_override"]
	if("hat_offset" in profile)
		hat_offset = profile["hat_offset"]
	if("sleeper_overlay" in profile)
		sleeper_overlay = profile["sleeper_overlay"]
	if("moduleselect_icon" in profile)
		moduleselect_icon = profile["moduleselect_icon"]
	if("moduleselect_alternate_icon" in profile)
		moduleselect_alternate_icon = profile["moduleselect_alternate_icon"]
	if("hasrest" in profile)
		hasrest = profile["hasrest"]
	if("dogborg" in profile)
		dogborg = profile["dogborg"]
	if("drakerest" in profile)
		drakerest = profile["drakerest"]
	if("special_light_key" in profile)
		special_light_key = profile["special_light_key"]
	if("has_snowflake_deadsprite" in profile)
		has_snowflake_deadsprite = profile["has_snowflake_deadsprite"]
	return TRUE

/obj/item/robot_module
	name = "Default"
	icon = 'icons/obj/module.dmi'
	icon_state = "std_mod"
	w_class = WEIGHT_CLASS_GIGANTIC
	item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1

	var/borghealth = 100

	var/list/basic_modules = list() //a list of paths, converted to a list of instances on New()
	var/list/emag_modules = list() //ditto
	var/list/ratvar_modules = list() //ditto ditto
	var/list/modules = list() //holds all the usable modules
	var/list/added_modules = list() //modules not inherient to the robot module, are kept when the module changes
	var/list/storages = list()
	var/list/added_channels = list() //Borg radio stuffs

	var/cyborg_base_icon = "robot" //produces the icon for the borg and, if no special_light_key is set, the lights
	var/special_light_key //if we want specific lights, use this instead of copying lights in the dmi

	var/moduleselect_icon = "nomod"

	var/can_be_pushed = FALSE
	var/magpulsing = FALSE
	var/clean_on_move = FALSE

	var/did_feedback = FALSE

	var/alist/hat_offset = NORMAL_HAT_OFFSET

	var/list/ride_offset_x = list("north" = 0, "south" = 0, "east" = -6, "west" = 6)
	var/list/ride_offset_y = list("north" = 4, "south" = 4, "east" = 3, "west" = 3)
	var/ride_allow_incapacitated = FALSE
	var/allow_riding = TRUE
	var/canDispose = FALSE // Whether the borg can stuff itself into disposal

	var/sleeper_overlay
	var/icon/cyborg_icon_override
	var/has_snowflake_deadsprite
	var/cyborg_pixel_offset
	var/moduleselect_alternate_icon
	var/dogborg = FALSE
	var/hasrest = FALSE //For the new borgs who are not dogs
	var/drakerest = FALSE //For the new drakemech resting icons
	/// Даём модулям киборга опцию иметь трейты
	var/list/cyborg_traits

/obj/item/robot_module/Initialize(mapload)
	. = ..()
	for(var/i in basic_modules)
		var/obj/item/I = new i(src)
		basic_modules += I
		basic_modules -= i
	for(var/i in emag_modules)
		var/obj/item/I = new i(src)
		emag_modules += I
		emag_modules -= i
	for(var/i in ratvar_modules)
		var/obj/item/I = new i(src)
		ratvar_modules += I
		ratvar_modules -= i

/obj/item/robot_module/Destroy()
	modules.Cut()
	QDEL_LIST(basic_modules)
	QDEL_LIST(emag_modules)
	QDEL_LIST(ratvar_modules)
	QDEL_LIST(added_modules)
	QDEL_LIST(storages)
	return ..()

/obj/item/robot_module/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/O in modules)
		O.emp_act(severity)

/obj/item/robot_module/proc/get_usable_modules()
	. = modules.Copy()

/obj/item/robot_module/proc/get_inactive_modules()
	. = list()
	var/mob/living/silicon/robot/R = loc
	for(var/m in get_usable_modules())
		if(!(m in R.held_items))
			. += m

/obj/item/robot_module/proc/get_or_create_estorage(storage_type)
	for(var/datum/robot_energy_storage/S in storages)
		if(istype(S, storage_type))
			return S

	return new storage_type(src)

/obj/item/robot_module/proc/add_module(obj/item/I, nonstandard, requires_rebuild)
	rad_flags |= RAD_NO_CONTAMINATE
	var/obj/item/stack/S = I
	if(istype(I, /obj/item/stack) && !S.is_cyborg) // Now handled in the type itself
		stack_trace("Non-cyborg variant of /obj/item/stack added to a cyborg's modules.")

	if(I.loc != src)
		I.forceMove(src)
	modules += I
	ADD_TRAIT(I, TRAIT_NODROP, CYBORG_ITEM_TRAIT)
	I.mouse_opacity = MOUSE_OPACITY_OPAQUE
	if(nonstandard)
		added_modules += I
	if(requires_rebuild)
		rebuild_modules()
	return I

//Adds flavoursome dogborg items to dogborg variants optionally without mechanical benefits
/obj/item/robot_module/proc/dogborg_equip()
	if(!has_snowflake_deadsprite)
		has_snowflake_deadsprite = TRUE
	if(isnull(cyborg_pixel_offset))
		cyborg_pixel_offset = -16
	basic_modules += new /obj/item/dogborg_nose(src)
	basic_modules += new /obj/item/dogborg_tongue(src)

	var/obj/item/dogborg/sleeper/I = /obj/item/dogborg/sleeper

	var/mechanics = CONFIG_GET(flag/enable_dogborg_sleepers)
	if (mechanics)
		if(istype(src, /obj/item/robot_module/security))
			I = new /obj/item/dogborg/sleeper/K9(src)
		else if(istype(src, /obj/item/robot_module/medical))
			I = new /obj/item/dogborg/sleeper(src)
		else if(istype(src, /obj/item/robot_module/engineering))
			I = new /obj/item/dogborg/sleeper/compactor(src)
			I.icon_state = "decompiler"
		else if(istype(src, /obj/item/robot_module/butler))
			I = new /obj/item/dogborg/sleeper/compactor(src)
			I.icon_state = "servicer"
			if(cyborg_base_icon in list("scrubpup", "drakejanit"))
				I.icon_state = "compactor"
		else
			I = new /obj/item/dogborg/sleeper/K9/flavour(src)
	else
		I = new /obj/item/dogborg/sleeper/K9/flavour(src)
		if(istype(src, /obj/item/robot_module/security))
			I.icon_state = "sleeperb"
		else if(istype(src, /obj/item/robot_module/medical))
			I.icon_state = "sleeper"
		else if(istype(src, /obj/item/robot_module/engineering))
			I.icon_state = "decompiler"
		else if(istype(src, /obj/item/robot_module/butler))
			I.icon_state = "servicer"
			if(cyborg_base_icon in list("scrubpup", "drakejanit"))
				I.icon_state = "compactor"

	basic_modules += I
	rebuild_modules()

/obj/item/robot_module/proc/remove_module(obj/item/I, delete_after)
	var/mob/living/silicon/robot/R = loc
	if(istype(R))
		var/held_slot = R.held_items.Find(I)
		if(held_slot)
			R.unequip_module_from_slot(I, held_slot)
	basic_modules -= I
	modules -= I
	emag_modules -= I
	ratvar_modules -= I
	added_modules -= I
	rebuild_modules()
	if(delete_after)
		qdel(I)

/obj/item/robot_module/proc/respawn_consumable(mob/living/silicon/robot/R, coeff = 1)
	for(var/datum/robot_energy_storage/st in storages)
		st.energy = min(st.max_energy, st.energy + coeff * st.recharge_rate)

	for(var/obj/item/I in get_usable_modules())
		if(istype(I, /obj/item/assembly/flash))
			var/obj/item/assembly/flash/F = I
			F.times_used = 0
			F.crit_fail = 0
			F.update_icon()
		else if(istype(I, /obj/item/melee/baton))
			var/obj/item/melee/baton/B = I
			if(B.cell)
				B.cell.charge = B.cell.maxcharge
		else if(istype(I, /obj/item/gun/energy))
			var/obj/item/gun/energy/EG = I
			if(EG.cell?.charge < EG.cell.maxcharge)
				var/obj/item/ammo_casing/energy/S = EG.ammo_type[EG.current_firemode_index]
				EG.cell.give(S.e_cost * coeff)
				if(!EG.chambered)
					EG.recharge_newshot(TRUE)
				EG.update_icon()
			else
				EG.charge_tick = 0
		else if(istype(I, /obj/item/gun/ballistic/revolver/grenadelauncher/cyborg))
			var/obj/item/gun/ballistic/revolver/grenadelauncher/cyborg/GL = I
			GL.recharge_from_station(coeff)

	R.toner = R.tonermax

/obj/item/robot_module/proc/rebuild_modules() //builds the usable module list from the modules we have
	var/mob/living/silicon/robot/R = loc
	var/held_modules = R.held_items.Copy()
	R.uneq_all()
	modules = list()
	for(var/obj/item/I in basic_modules)
		add_module(I, FALSE, FALSE)
	if(R.emagged)
		for(var/obj/item/I in emag_modules)
			add_module(I, FALSE, FALSE)
	if(is_servant_of_ratvar(R))
		for(var/obj/item/I in ratvar_modules)
			add_module(I, FALSE, FALSE)
	for(var/obj/item/I in added_modules)
		add_module(I, FALSE, FALSE)
	// Remove only traits sourced by this robot module, even if the list is empty.
	REMOVE_TRAITS_IN(R, CYBORG_MODULE_TRAIT)
	if(cyborg_traits)
		for(var/trait in cyborg_traits)
			ADD_TRAIT(R, trait, CYBORG_MODULE_TRAIT)
	for(var/i in held_modules)
		if(i && (i in modules))
			R.activate_module(i)
	if(R.hud_used)
		R.hud_used.update_robot_modules_display()

/obj/item/robot_module/proc/transform_to(new_module_type)
	var/mob/living/silicon/robot/R = loc
	var/obj/item/robot_module/RM = new new_module_type(R)
	if(!RM.be_transformed_to(src))
		qdel(RM)
		return
	// A radial menu can yield: recheck which module still belongs to the robot.
	if(QDELETED(R) || QDELETED(src) || QDELETED(RM) || R.module != src || RM.loc != R)
		if(!QDELETED(RM))
			qdel(RM)
		return
	R.uneq_all()
	R.module = RM
	R.update_module_innate()
	RM.rebuild_modules()
	INVOKE_ASYNC(RM, PROC_REF(do_transform_animation))
	if(RM.dogborg || R.dogborg)
		RM.dogborg_equip()
		R.typing_indicator_state = /obj/effect/overlay/typing_indicator/machine/dogborg
	else
		R.typing_indicator_state = /obj/effect/overlay/typing_indicator/machine
	R.radio.extra_channels = RM.added_channels
	R.radio.recalculateChannels()
	R.maxHealth = RM.borghealth
	R.health = min(R.maxHealth, R.health)
	qdel(src)
	return RM

/obj/item/robot_module/proc/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(QDELETED(R) || QDELETED(old_module) || R.module != old_module || old_module.loc != R)
		return FALSE
	for(var/i in old_module.added_modules)
		added_modules += i
		old_module.added_modules -= i
	did_feedback = old_module.did_feedback
	return TRUE

/obj/item/robot_module/proc/do_transform_animation()
	var/mob/living/silicon/robot/R = loc
	if(!transform_target_is_valid(R))
		return FALSE
	if(R.hat)
		R.hat.forceMove(get_turf(R))
		R.hat = null
	R.cut_overlays()
	R.setDir(SOUTH)
	return do_transform_delay(R)

/obj/item/robot_module/proc/transform_target_is_valid(mob/living/silicon/robot/R)
	return istype(R) && !QDELETED(src) && !QDELETED(R) && loc == R && R.module == src

/mob/living/silicon/robot/proc/restore_module_transform_state(obj/item/robot_module/expected_module, was_locked_down, was_anchored)
	if(QDELETED(src))
		return
	// If a new module is already transforming, it owns the current state.
	if(module && module != expected_module)
		return
	if(!was_locked_down)
		SetLockdown(FALSE)
	set_anchored(was_anchored)
	mob_transforming = FALSE

/obj/item/robot_module/proc/do_transform_delay(mob/living/silicon/robot/R)
	if(!transform_target_is_valid(R))
		return FALSE
	var/was_locked_down = R.locked_down
	var/was_anchored = R.anchored
	sleep(1)
	if(!transform_target_is_valid(R))
		return FALSE
	flick("[cyborg_base_icon]_transform", R)
	R.mob_transforming = TRUE
	R.SetLockdown(TRUE)
	R.set_anchored(TRUE)
	sleep(1)
	if(!transform_target_is_valid(R))
		R.restore_module_transform_state(src, was_locked_down, was_anchored)
		return FALSE
	for(var/i in 1 to 4)
		playsound(R, pick('sound/items/drill3.ogg', 'sound/items/jaws_cut.ogg', 'sound/items/jaws_pry.ogg', 'sound/items/welder.ogg', 'sound/items/ratchet.ogg'), 80, 1, -1)
		sleep(7)
		if(!transform_target_is_valid(R))
			R.restore_module_transform_state(src, was_locked_down, was_anchored)
			return FALSE
	R.restore_module_transform_state(src, was_locked_down, was_anchored)
	R.setDir(SOUTH)
	R.updatehealth()
	R.update_icons()
	R.notify_ai(NEW_MODULE)
	if(R.hud_used)
		R.hud_used.update_robot_modules_display()
	SSblackbox.record_feedback("tally", "cyborg_modules", 1, R.module)
	return TRUE

/**
  * check_menu: Checks if we are allowed to interact with a radial menu
  *
  * Arguments:
  * * user The mob interacting with a menu
  */
/obj/item/robot_module/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(!user.client || user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/robot_module/standard
	name = "Standard"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/borghypo/epi,
		/obj/item/healthanalyzer/cyborg,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/pickaxe,
		/obj/item/gps/cyborg,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/soap/nanotrasen,
		/obj/item/borg/cyborghug)
	emag_modules = list(/obj/item/melee/transforming/energy/sword/cyborg)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg,
		/obj/item/clockwork/weapon/ratvarian_spear,
		/obj/item/clockwork/replica_fabricator/cyborg)
	moduleselect_icon = "standard"
	hat_offset = -3

/obj/item/robot_module/medical
	name = "Medical"
	added_channels = list(RADIO_CHANNEL_MEDICAL = 1)
	basic_modules = list(
		/obj/item/surgical_drapes,
		/obj/item/scalpel/upgraded_t2/cyborg,
		/obj/item/retractor/upgraded_t2/cyborg,
		/obj/item/hemostat/upgraded_t2/cyborg,
		/obj/item/circular_saw/upgraded_t2/cyborg,
		/obj/item/cautery/upgraded_t2/cyborg,
		/obj/item/surgicaldrill,
		/obj/item/bonesetter,
		/obj/item/blood_filter,
		/obj/item/shockpaddles/cyborg,
		/obj/item/healthanalyzer/cyborg,
		/obj/item/reagent_containers/borghypo,
		/obj/item/sensor_device,
		/obj/item/roller/robo,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/syringe,
		/obj/item/stack/medical/gauze/cyborg,
		/obj/item/stack/medical/bone_gel/cyborg,
		/obj/item/gripper/medical,
		/obj/item/organ_storage,
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/gps/cyborg,
		/obj/item/borg/cyborghug/medical,
		/obj/item/borg/lollipop)
	emag_modules = list(/obj/item/reagent_containers/borghypo/hacked)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/medical,
		/obj/item/clockwork/weapon/ratvarian_spear)
	cyborg_base_icon = "medical"
	moduleselect_icon = "medical"
	hat_offset = 3

/obj/item/robot_module/medical/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // No UI while a preconfigured cyborg is spawning.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/med_skin_profiles
	if(!med_skin_profiles)
		med_skin_profiles = list(
			"Default" = list(
				"cyborg_base_icon" = "medical",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "medical")
			),
			"Droid" = list(
				"cyborg_base_icon" = "medical",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"hat_offset" = DROID_HAT_OFFSET,
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "medical")
			),
			"Sleek" = list(
				"cyborg_base_icon" = "sleekmed",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleekmed")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinamed",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "marinamed")
			),
			"Eyebot" = list(
				"cyborg_base_icon" = "eyebotmed",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "eyebotmed")
			),
			"Heavy" = list(
				"cyborg_base_icon" = "heavymed",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavymed")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_med",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_med")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_medical",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_medical")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_med",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_med")
			),
			"Arachne" = list(
				"cyborg_base_icon" = "arachne",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "arachne")
			),
			"Insekt" = list(
				"cyborg_base_icon" = "insekt-Med",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "insekt-Med")
			),
			"Gibbs" = list(
				"cyborg_base_icon" = "gibbs",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "gibbs")
			),
			"RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_med",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_med")
			),
			"Qualified Doctor" = list(
				"cyborg_base_icon" = "qualified_doctor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "qualified_doctor")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootymedical",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootymedical")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootymedicalM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootymedicalM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootymedicalS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootymedicalS")
			),
			"Haydee" = list(
				"cyborg_base_icon" = "haydeemedical",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeemedical")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy_medical",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_medical")
			),
			"Medihound" = list(
				"cyborg_base_icon" = "medihound",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "msleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "medihound", -16)
			),
			"Medihound Dark" = list(
				"cyborg_base_icon" = "medihounddark",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "mdsleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "medihounddark", -16)
			),
			"Vale" = list(
				"cyborg_base_icon" = "valemed",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valemedsleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valemed", -16)
			),
			"Borgi" = list(
				"cyborg_base_icon" = "borgi-medi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "borgi-medi-sleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "borgi-medi-b")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakemed",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"sleeper_overlay" = "drakemedsleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakemedbox")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-medic",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-medic")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_medical",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_medical")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekamed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekamed")
			),
			"Meka (alt)" = list(
				"cyborg_base_icon" = "mekamed_alt",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekamed_alt")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekamed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekamed")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekamed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekamed")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tmed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tmed")
			),
			"K4T (alt)" = list(
				"cyborg_base_icon" = "k4tmed_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tmed_alt1")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixmed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixmed-sleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixmed-b")
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "medraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "medraptor_sleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "medraptor-b")
			),
			"Raptor V-4 (alt)" = list(
				"cyborg_base_icon" = "traumaraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "traumaraptor_sleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "traumaraptor-b")
			),
			"Mechoid" = list(
				"cyborg_base_icon" = "mechoid-medical",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-medical",
				"has_snowflake_deadsprite" = "mechoid-medical-wreck",
				"sleeper_overlay" = "medraptorsleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-medical")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_med",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_med-b")
			),
			"DrakeTrauma" = list(
				"cyborg_base_icon" = "draketrauma",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"sleeper_overlay" = "drakemedsleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "draketraumabox")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahanmed",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanmed")
			),
			"HoundTrauma" = list(
				"cyborg_base_icon" = "houndtrauma",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots_64x32.dmi',
				"sleeper_overlay" = "msleeper",
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_bluemoon/icons/mob/robots_64x32.dmi', "houndtrauma", -16)
			),
			"Catborg" = list(
				"cyborg_base_icon" = "meowdical",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_medical.dmi',
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_medical.dmi', icon_state = "meowdical")
			),
			"Kittyborg" = list(
				"cyborg_base_icon" = "medicat",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_medicat.dmi',
				"moduleselect_icon" = "medihound",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_medicat.dmi', icon_state = "medicat")
			),
			"Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaurmed",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaurmed")
			),
			"Dragon" = list(
				"cyborg_base_icon" = "dragon-med",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_med.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_med.dmi', icon_state = "dragon-med")
			)
		)
	var/static/list/med_icons
	if(!med_icons)
		med_icons = get_borg_skin_preview_icons(med_skin_profiles)
		med_icons = sort_list(med_icons)

	var/list/selectable_med_icons = get_selectable_borg_icons(med_icons, R.client)
	var/med_borg_icon = show_radial_menu(R, R , selectable_med_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(med_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(med_skin_profiles[med_borg_icon]))
		return FALSE
	return ..()

/obj/item/robot_module/engineering
	name = "Engineering"
	added_channels = list(RADIO_CHANNEL_ENGINEERING = 1)
	basic_modules = list(
		/obj/item/construction/rcd/borg,
		/obj/item/pipe_dispenser/cyborg,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/cyborg,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/storage/part_replacer/cyborg,
		/obj/item/holosign_creator/combifan,
		/obj/item/borg/sight/meson,
		/obj/item/t_scanner,
		/obj/item/analyzer,
		/obj/item/gripper,
		/obj/item/areaeditor/blueprints/cyborg,
		/obj/item/cyborg_inducer,
		/obj/item/stack/cable_coil/cyborg,
		/obj/item/electroadaptive_pseudocircuit,
		/obj/item/assembly/flash/cyborg,
		/obj/item/gps/cyborg,
		/obj/item/extinguisher,
		/obj/item/lightreplacer/cyborg,
		/obj/item/geiger_counter/cyborg,
		/obj/item/assembly/signaler/cyborg,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg)
	emag_modules = list(/obj/item/borg/stun)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/engineer,
		/obj/item/clockwork/replica_fabricator/cyborg)
	cyborg_base_icon = "engineer"
	moduleselect_icon = "engineer"
	magpulsing = TRUE
	hat_offset = -4
	cyborg_traits = list(TRAIT_KNOW_ENGI_WIRES)

/obj/item/robot_module/engineering/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // No UI while a preconfigured cyborg is spawning.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/engi_skin_profiles
	if(!engi_skin_profiles)
		engi_skin_profiles = list(
			"Default" = list(
				"cyborg_base_icon" = "engineer",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "engineer")
			),
			"Default - Treads" = list(
				"cyborg_base_icon" = "engi-tread",
				"special_light_key" = "engineer",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "engi-tread")
			),
			"Loader" = list(
				"cyborg_base_icon" = "loaderborg",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "loaderborg")
			),
			"Sleek" = list(
				"cyborg_base_icon" = "sleekeng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleekeng")
			),
			"Can" = list(
				"cyborg_base_icon" = "caneng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "caneng")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinaeng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "marinaeng")
			),
			"Spider" = list(
				"cyborg_base_icon" = "spidereng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "spidereng")
			),
			"Heavy" = list(
				"cyborg_base_icon" = "heavyeng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavyeng")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_eng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_eng")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_eng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_eng")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_engi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_engi")
			),
			"Conagher" = list(
				"cyborg_base_icon" = "conagher",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "conagher")
			),
			"Eyebot" = list(
				"cyborg_base_icon" = "eyeboteng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "eyeboteng")
			),
			"Wide" = list(
				"cyborg_base_icon" = "wide-engi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "wide-engi")
			),
			"RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_eng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_eng")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootyengineer",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyengineer")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootyengineerM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyengineerM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootyengineerS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyengineerS")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy_engineer",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_engineer")
			),
			"Pup Dozer" = list(
				"cyborg_base_icon" = "pupdozer",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "dozersleeper",
				"hat_offset" = PUP_DOZER_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "pupdozer", -16)
			),
			"Vale" = list(
				"cyborg_base_icon" = "valeeng",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valeengsleeper",
				"hasrest" = TRUE,
				"hat_offset" = VALE_HAT_OFFSET,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valeeng", -16)
			),
			"Borgi" = list(
				"cyborg_base_icon" = "borgi-eng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "borgi-eng-sleeper",
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "borgi-eng-b")
			),
			"Engihound" = list(
				"cyborg_base_icon" = "engihound",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "engihoundsleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "engihound-b")
			),
			"Engihound Dark" = list(
				"cyborg_base_icon" = "engihounddark",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "engihounddarksleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "engihounddark-b")
			),
			"Otie" = list(
				"cyborg_base_icon" = "otiee",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "otieesleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "otiee-b")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakeeng",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"sleeper_overlay" = "drakesecsleeper",
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakeengbox")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-engineering",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-engineering")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_engi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_engi")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekaengi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekaengi")
			),
			"Meka (alt)" = list(
				"cyborg_base_icon" = "mekaengi_alt",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekaengi_alt")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekaeng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekaeng")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekaeng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekaeng")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tengi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tengi")
			),
			"K4T (alt)" = list(
				"cyborg_base_icon" = "k4tengi_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tengi_alt1")
			),
			"Haydee" = list(
				"cyborg_base_icon" = "haydeeengi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeeengi")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixengi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixengi-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixengi-b")
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "engiraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "engiraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "engiraptor-b")
			),
			"Mechoid" = list(
				"cyborg_base_icon" = "mechoid-engineer",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-engineer",
				"has_snowflake_deadsprite" = "mechoid-engineer-wreck",
				"sleeper_overlay" = "engiraptor-sleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-engineer")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_eng",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_eng-b")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahaneng",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahaneng")
			),
			"Catborg" = list(
				"cyborg_base_icon" = "engi",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_engineering.dmi',
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_engineering.dmi', icon_state = "engi")
			),
			"Kittyborg" = list(
				"cyborg_base_icon" = "engi",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_engi.dmi',
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_engi.dmi', icon_state = "engi")
			),
			"Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaureng",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaureng")
			),
			"Dragon" = list(
				"cyborg_base_icon" = "dragon-engi",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_engi.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_engi.dmi', icon_state = "dragon-engi")
			)
		)
	var/static/list/engi_icons
	if(!engi_icons)
		engi_icons = get_borg_skin_preview_icons(engi_skin_profiles)
		engi_icons = sort_list(engi_icons)

	var/list/selectable_engi_icons = get_selectable_borg_icons(engi_icons, R.client)
	var/engi_borg_icon = show_radial_menu(R, R , selectable_engi_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(engi_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(engi_skin_profiles[engi_borg_icon]))
		return FALSE
	return ..()

/obj/item/robot_module/security
	name = "Security"
	added_channels = list(RADIO_CHANNEL_SECURITY = 1)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/melee/baton/loaded,
		/obj/item/gun/energy/disabler/cyborg,
		/obj/item/clothing/mask/gas/sechailer/cyborg,
		/obj/item/gps/cyborg,
		/obj/item/pinpointer/crew)
	emag_modules = list(/obj/item/gun/energy/laser/cyborg)
	ratvar_modules = list(/obj/item/clockwork/slab/cyborg/security,
		/obj/item/clockwork/weapon/ratvarian_spear)
	cyborg_base_icon = "sec"
	moduleselect_icon = "security"
	hat_offset = 3

/obj/item/robot_module/security/do_transform_animation()
	if(!..())
		return FALSE
	to_chat(loc, span_userdanger("Выбрав охранный модуль, вы все ещё следуете своим законам и стандартам силиконов, а не Космическому Закону. \
	Для Crewsimov это значит, что вы следуете приказам преступников до тех пор, пока содержание закона 1 не допустит обратного."))
	return TRUE

/obj/item/robot_module/security/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // No UI while a preconfigured cyborg is spawning.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/sec_skin_profiles
	if(!sec_skin_profiles)
		sec_skin_profiles = list(
			"Default" = list(
				"cyborg_base_icon" = "sec",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "sec")
			),
			"Default - Treads" = list(
				"cyborg_base_icon" = "sec-tread",
				"special_light_key" = "sec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sec-tread")
			),
			"Sleek" = list(
				"cyborg_base_icon" = "sleeksec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleeksec")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinasec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "marinasec")
			),
			"Can" = list(
				"cyborg_base_icon" = "cansec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "cansec")
			),
			"Spider" = list(
				"cyborg_base_icon" = "spidersec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "spidersec")
			),
			"Heavy" = list(
				"cyborg_base_icon" = "heavysec",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavysec")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_security",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_security")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_security",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_security")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_sec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_sec")
			),
			"Woody" = list(
				"cyborg_base_icon" = "woody",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "woody")
			),
			"Eyebot" = list(
				"cyborg_base_icon" = "eyebotsec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "eyebotsec")
			),
			"Insekt" = list(
				"cyborg_base_icon" = "insekt-Sec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "insekt-Sec")
			),
			"RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_sec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_sec")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootysecurity",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootysecurity")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootysecurityM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootysecurityM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootysecurityS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootysecurityS")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy_security",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_security")
			),
			"Sentry Bot" = list(
				"cyborg_base_icon" = "sentrybot",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "sentrybot")
			),
			"Securitron" = list(
				"cyborg_base_icon" = "securitron",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "securitron")
			),
			"K9" = list(
				"cyborg_base_icon" = "k9",
				"sleeper_overlay" = "ksleeper",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "k9", -16)
			),
			"K9 Dark" = list(
				"cyborg_base_icon" = "k9dark",
				"sleeper_overlay" = "k9darksleeper",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "k9dark", -16)
			),
			"Vale" = list(
				"cyborg_base_icon" = "valesec",
				"sleeper_overlay" = "valesecsleeper",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"hasrest" = TRUE,
				"hat_offset" = VALE_HAT_OFFSET,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valesec", -16)
			),
			"Borgi" = list(
				"cyborg_base_icon" = "borgi-sec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "borgi-sec-sleeper",
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "borgi-sec-b")
			),
			"Otie" = list(
				"cyborg_base_icon" = "oties",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "otiessleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "oties-b")
			),
			"Blade" = list(
				"cyborg_base_icon" = "bladesec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "bladesecsleeper",
				"hat_offset" = BLADE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "bladesec-b")
			),
			"EdgyBoy" = list(
				"cyborg_base_icon" = "badboi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "badboi-b")
			),
			"EdgyGirl" = list(
				"cyborg_base_icon" = "prettyboi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "prettyboi-b")
			),
			"Syndicate" = list(
				"cyborg_base_icon" = "syndihounddark",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot_synd.dmi',
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot_synd.dmi', icon_state = "syndihounddark")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakesec",
				"sleeper_overlay" = "drakesecsleeper",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakesecbox")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-security",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-security")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_sec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_sec")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekasec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekasec")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekasec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekasec")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekasec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekasec")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tsec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tsec")
			),
			"Haydee" = list(
				"cyborg_base_icon" = "haydeesec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeesec")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixsec",
				"sleeper_overlay" = "vixsec-sleeper",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixsec-b")
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "secraptor",
				"sleeper_overlay" = "secraptor-sleeper",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "secraptor-b")
			),
			"FMeka Syndie" = list(
				"cyborg_base_icon" = "fmekasyndi",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekasyndi")
			),
			"Mechoid" = list(
				"cyborg_base_icon" = "mechoid-security",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-security",
				"has_snowflake_deadsprite" = "mechoid-security-wreck",
				"sleeper_overlay" = "secraptor-sleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-security")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahanpeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanpeace")
			),
			"Catborg" = list(
				"cyborg_base_icon" = "sec",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_security.dmi',
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_security.dmi', icon_state = "sec")
			),
			"Kittyborg" = list(
				"cyborg_base_icon" = "sec",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sec.dmi',
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sec.dmi', icon_state = "sec")
			),
			"Dragon" = list(
				"cyborg_base_icon" = "dragon-sec",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_sec.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_sec.dmi', icon_state = "dragon-sec")
			)
		)
	var/static/list/sec_icons
	if(!sec_icons)
		sec_icons = get_borg_skin_preview_icons(sec_skin_profiles)
		sec_icons = sort_list(sec_icons)

	var/list/selectable_sec_icons = get_selectable_borg_icons(sec_icons, R.client)
	var/sec_borg_icon = show_radial_menu(R, R , selectable_sec_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(sec_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(sec_skin_profiles[sec_borg_icon]))
		return FALSE
	return ..()

/obj/item/robot_module/security/Initialize(mapload)
	. = ..()
	if(!CONFIG_GET(flag/weaken_secborg))
		for(var/obj/item/gun/energy/disabler/cyborg/pewpew in basic_modules)
			basic_modules -= pewpew
			basic_modules += new /obj/item/gun/energy/e_gun/advtaser/cyborg(src)
			qdel(pewpew)

/obj/item/robot_module/peacekeeper
	name = "Peacekeeper"
	added_channels = list(RADIO_CHANNEL_SECURITY = 1)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/cookiesynth,
		/obj/item/harmalarm,
		/obj/item/reagent_containers/borghypo/peace,
		/obj/item/holosign_creator/cyborg,
		/obj/item/borg/cyborghug/peacekeeper,
		/obj/item/megaphone,
		/obj/item/gps/cyborg,
		/obj/item/borg/projectile_dampen)
	emag_modules = list(/obj/item/reagent_containers/borghypo/peace/hacked)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/peacekeeper,
		/obj/item/clockwork/weapon/ratvarian_spear)
	cyborg_base_icon = "peace"
	moduleselect_icon = "standard"
	hat_offset = -2

/obj/item/robot_module/peacekeeper/do_transform_animation()
	if(!..())
		return FALSE
	to_chat(loc, span_userdanger("При законах ASIMOV/CREWSIMOV, вы блюститель ПОРЯДКА. \
	Вы не охранный модуль и от вас ожидается следование приказам с минимальным вредом в процессе исполнения. Вы следуете своим законам и политике силиконов, а не Космическому Закону."))
	return TRUE

/obj/item/robot_module/peacekeeper/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // No UI while a preconfigured cyborg is spawning.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/peace_skin_profiles
	if(!peace_skin_profiles)
		peace_skin_profiles = list(
			"Default" = list(
				"cyborg_base_icon" = "peace",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "peace")
			),
			"Spider" = list(
				"cyborg_base_icon" = "whitespider",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "whitespider")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_peacekeeper",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_peacekeeper")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinapeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "marinapeace")
			),
			"Sleek" = list(
				"cyborg_base_icon" = "sleekpeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "sleekpeace")
			),
			"Omoikane" = list(
				"cyborg_base_icon" = "omoikane",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "omoikane")
			),
			"Insekt" = list(
				"cyborg_base_icon" = "insekt-Default",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "insekt-Default")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootypeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootypeace")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootypeaceM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootypeaceM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootypeaceS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootypeaceS")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy_peace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_peace")
			),
			"Borgi" = list(
				"cyborg_base_icon" = "borgi",
				"moduleselect_icon" = "borgi",
				"moduleselect_alternate_icon" = 'modular_citadel/icons/ui/screen_cyborg.dmi',
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "borgi")
			),
			"Vale" = list(
				"cyborg_base_icon" = "valepeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valepeacesleeper",
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "valepeace-b")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakepeace",
				"sleeper_overlay" = "drakepeacesleeper",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakepeacebox")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-peace",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-peace")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_peacekeeper",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_peacekeeper")
			),
			"Haydee" = list(
				"cyborg_base_icon" = "haydeepk",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeepk")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekapeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekapeace")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekapeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekapeace")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekapeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekapeace")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tpeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tpeace")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixpk",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixpk-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixpk-b")
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "peaceraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "peaceraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "peaceraptor-b")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_pk",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_pk-b")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahanpeace",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanpeace")
			),
			"Catborg" = list(
				"cyborg_base_icon" = "sci",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_science.dmi',
				"moduleselect_icon" = "medihound",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_science.dmi', icon_state = "sci")
			),
			"Kittyborg" = list(
				"cyborg_base_icon" = "sci",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sci.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_sci.dmi', icon_state = "sci")
			),
			"Dragon" = list(
				"cyborg_base_icon" = "dragon-pk",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_peacekeeper.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_peacekeeper.dmi', icon_state = "dragon-pk")
			)
		)
	var/static/list/peace_icons
	if(!peace_icons)
		peace_icons = get_borg_skin_preview_icons(peace_skin_profiles)
		peace_icons = sort_list(peace_icons)

	var/list/selectable_peace_icons = get_selectable_borg_icons(peace_icons, R.client)
	var/peace_borg_icon = show_radial_menu(R, R , selectable_peace_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(peace_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(peace_skin_profiles[peace_borg_icon]))
		return FALSE
	return ..()

/obj/item/reagent_containers/spray/cyborg_drying
	name = "drying agent spray"
	color = "#A000A0"
	list_reagents = list(/datum/reagent/drying_agent = 250)

/obj/item/reagent_containers/spray/cyborg_lube
	name = "lube spray"
	list_reagents = list(/datum/reagent/lube = 250)

/obj/item/robot_module/clown
	name = "Clown"
	added_channels = list(RADIO_CHANNEL_SERVICE = 1)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/toy/crayon/rainbow,
		/obj/item/instrument/bikehorn,
		/obj/item/bikehorn,
		/obj/item/bikehorn/airhorn,
		/obj/item/stamp/clown,
		/obj/item/paint/anycolor,
		/obj/item/soap/nanotrasen,
		/obj/item/pneumatic_cannon/pie/selfcharge/cyborg,
		/obj/item/razor,					//killbait material
		/obj/item/lipstick/purple,
		/obj/item/reagent_containers/spray/waterflower/cyborg,
		/obj/item/borg/cyborghug/peacekeeper,
		/obj/item/borg/lollipop/clown,
		/obj/item/picket_sign/cyborg,
		/obj/item/gps/cyborg,
		/obj/item/reagent_containers/borghypo/clown)
	emag_modules = list(
		/obj/item/reagent_containers/borghypo/clown/hacked,
		/obj/item/reagent_containers/spray/waterflower/cyborg/hacked)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg,
		/obj/item/clockwork/weapon/ratvarian_spear,
		/obj/item/clockwork/replica_fabricator/cyborg)
	moduleselect_icon = "service"
	cyborg_base_icon = "clown"
	hat_offset = -2

/obj/item/robot_module/butler
	name = "Service"
	added_channels = list(RADIO_CHANNEL_SERVICE = 1)
	basic_modules = list(
		/obj/item/gps/cyborg,
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/screwdriver/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/pen,
		/obj/item/toy/crayon/spraycan/borg,
		/obj/item/hand_labeler/borg,
		/obj/item/soap/nanotrasen,
		/obj/item/storage/bag/trash/cyborg,
		/obj/item/mop/cyborg,
		/obj/item/lightreplacer/cyborg,
		/obj/item/holosign_creator,
		/obj/item/reagent_containers/spray/cyborg_drying,
		/obj/item/razor,
		/obj/item/instrument/piano_synth,
		/obj/item/lighter,
		/obj/item/borg/lollipop,
		/obj/item/rsf/cyborg,
		/obj/item/reagent_containers/food/drinks/drinkingglass,
		/obj/item/reagent_containers/borghypo/borgshaker,
		/obj/item/reagent_containers/dropper,
		/obj/item/reagent_containers/food/condiment/enzyme,
		/obj/item/storage/bag/tray)
	emag_modules = list(/obj/item/reagent_containers/borghypo/borgshaker/hacked)
	ratvar_modules = list(/obj/item/clockwork/slab/cyborg/service,
		/obj/item/borg/sight/xray/truesight_lens)
	moduleselect_icon = "service"
	hat_offset = 0
	clean_on_move = TRUE

/obj/item/robot_module/butler/respawn_consumable(mob/living/silicon/robot/R, coeff = 1)
	..()
	var/obj/item/reagent_containers/O = locate(/obj/item/reagent_containers/food/condiment/enzyme) in basic_modules
	var/obj/item/lightreplacer/LR = locate(/obj/item/lightreplacer) in basic_modules
	if(O)
		O.reagents.add_reagent(/datum/reagent/consumable/enzyme, 2 * coeff)
	if(LR)
		for(var/i in 1 to coeff)
			LR.Charge(R)
	var/obj/item/reagent_containers/spray/cyborg_drying/CD = locate(/obj/item/reagent_containers/spray/cyborg_drying) in basic_modules
	if(CD)
		CD.reagents.add_reagent(/datum/reagent/drying_agent, 5 * coeff)

	var/obj/item/reagent_containers/spray/cyborg_lube/CL = locate(/obj/item/reagent_containers/spray/cyborg_lube) in emag_modules
	if(CL)
		CL.reagents.add_reagent(/datum/reagent/lube, 2 * coeff)

/obj/item/robot_module/butler/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		cyborg_base_icon = "service_f"
		special_light_key = "service"
		return ..() // Default service look without a client.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/service_skin_profiles
	if(!service_skin_profiles)
		service_skin_profiles = list(
			"(Service) Waitress" = list(
				"cyborg_base_icon" = "service_f",
				"special_light_key" = "service",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "service_f")
			),
			"(Service) Butler" = list(
				"cyborg_base_icon" = "service_m",
				"special_light_key" = "service",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "service_m")
			),
			"(Service) Bro" = list(
				"cyborg_base_icon" = "brobot",
				"special_light_key" = "service",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "brobot")
			),
			"(Service) Can" = list(
				"cyborg_base_icon" = "kent",
				"special_light_key" = "medical",
				"hat_offset" = 3,
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "kent")
			),
			//He is already wearing a hat
			"(Service) Tophat" = list(
				"cyborg_base_icon" = "tophat",
				"special_light_key" = null,
				"hat_offset" = INFINITY,
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "tophat")
			),
			"(Service) Sleek" = list(
				"cyborg_base_icon" = "sleekserv",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleekserv")
			),
			"(Service) Heavy" = list(
				"cyborg_base_icon" = "heavyserv",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavyserv")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) MissM" = list(
				"cyborg_base_icon" = "missm_service",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_service")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) Protectron" = list(
				"cyborg_base_icon" = "protectron_service",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_service")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) Zoomba" = list(
				"cyborg_base_icon" = "zoomba_green",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_green")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) Lloyd" = list(
				"cyborg_base_icon" = "lloyd",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "lloyd")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) Handy" = list(
				"cyborg_base_icon" = "handy-service",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy-service")
			),
			// SPLURT Addon (Hyper Port)
			"(Service) BootyF" = list(
				"cyborg_base_icon" = "bootyservice",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyservice")
			),
			// SPLURT Addon (Hyper Port)
			"(Service) BootyM" = list(
				"cyborg_base_icon" = "bootyserviceM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyserviceM")
			),
			// SPLURT Addon (Hyper Port)
			"(Service) BootyS" = list(
				"cyborg_base_icon" = "bootyserviceS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyserviceS")
			),
			"(Service) DarkK9" = list(
				"cyborg_base_icon" = "k50",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "ksleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "k50", -16)
			),
			"(Service) Vale" = list(
				"cyborg_base_icon" = "valeserv",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valeservsleeper",
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valeserv", -16)
			),
			"(Service) ValeDark" = list(
				"cyborg_base_icon" = "valeservdark",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valeservsleeper",
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valeservdark", -16)
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) K69" = list(
				"cyborg_base_icon" = "k69",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "ksleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "k69-b")
			),
			// SPLURT Addon (Skyrat Port)
			"(Service) Borgi" = list(
				"cyborg_base_icon" = "borgi-serv",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "borgi-sleeper",
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "borgi-serv-b")
			),
			// //Gardelin0 Addon
			"(Service) Fembot" = list(
				"cyborg_base_icon" = "fembot-service",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-service")
			),
			"(Service) M-Meka" = list(
				"cyborg_base_icon" = "mmekaserv",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekaserv")
			),
			"(Service) F-Meka" = list(
				"cyborg_base_icon" = "fmekaserv",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekaserv")
			),
			"(Service) K4T" = list(
				"cyborg_base_icon" = "k4tserve",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tserve")
			),
			"(Service Alt) K4T" = list(
				"cyborg_base_icon" = "k4tserve_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tserve_alt1")
			),
			// SPLURT Addon (ChompS Port)
			"(Service) Feline" = list(
				"cyborg_base_icon" = "vixserv",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixserv-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixserv-b")
			),
			// SPLURT Addon (ChompS Port)
			"(Service) Raptor V-4" = list(
				"cyborg_base_icon" = "serviraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "serviraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "serviraptor-b")
			),
			// SPLURT Addon (ChompS Port)
			"(Fancy) Raptor V-4" = list(
				"cyborg_base_icon" = "fancyraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "fancyraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "fancyraptor-b")
			),
			// BubberStation Port; Made by aKhro/@aKromatopzia (GitHub)
			"(Service) SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_srv",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_srv-b")
			),
			"(Janitor) Default" = list("cyborg_base_icon" = "janitor", "preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "janitor")),
			"(Janitor) Marina" = list(
				"cyborg_base_icon" = "marinajan",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "marinajan")
			),
			"(Janitor) Sleek" = list(
				"cyborg_base_icon" = "sleekjan",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleekjan")
			),
			"(Janitor) Can" = list(
				"cyborg_base_icon" = "canjan",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "canjan")
			),
			"(Janitor) Heavy" = list(
				"cyborg_base_icon" = "heavyres",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavyres")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) MissM" = list(
				"cyborg_base_icon" = "missm_janitor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_janitor")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Protectron" = list(
				"cyborg_base_icon" = "protectron_janitor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_janitor")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Zoomba" = list(
				"cyborg_base_icon" = "zoomba_jani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_jani")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Flynn" = list(
				"cyborg_base_icon" = "flynn",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "flynn")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Eyebot" = list(
				"cyborg_base_icon" = "eyebotjani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "eyebotjani")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Insekt" = list(
				"cyborg_base_icon" = "insekt-Sci",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "insekt-Sci")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Wide" = list(
				"cyborg_base_icon" = "wide-jani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "wide-jani")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Spider" = list(
				"cyborg_base_icon" = "spidersci",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "spidersci")
			),
			// SPLURT Addon (Old Skyrat Port)
			"(Janitor) RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_jan",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_jan")
			),
			// SPLURT Addon (Hyper Port)
			"(Janitor) BootyF" = list(
				"cyborg_base_icon" = "bootyjanitor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyjanitor")
			),
			// SPLURT Addon (Hyper Port)
			"(Janitor) BootyM" = list(
				"cyborg_base_icon" = "bootyjanitorM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyjanitorM")
			),
			// SPLURT Addon (Hyper Port)
			"(Janitor) BootyS" = list(
				"cyborg_base_icon" = "bootyjanitorS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyjanitorS")
			),
			// SPLURT Addon (Fallout 13)
			"(Janitor) Handy" = list(
				"cyborg_base_icon" = "handy_janitor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_janitor")
			),
			"(Janitor) Scrubpuppy" = list(
				"cyborg_base_icon" = "scrubpup",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "jsleeper",
				"hat_offset" = PUP_CLEAN_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "scrubpup", -16)
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Borgi" = list(
				"cyborg_base_icon" = "borgi-jani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "borgi-jani-sleeper",
				"hat_offset" = BORGI_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "borgi-jani-b")
			),
			// SPLURT Addon (Skyrat Port)
			"(Janitor) Otie" = list(
				"cyborg_base_icon" = "otiej",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "otiejsleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "otiej-b")
			),
			// Dergborg brought to you by Navier#1236 | Skyrat | Commissioned Artist: deviantart.com/mizartz
			"(Janitor) Drake" = list(
				"cyborg_base_icon" = "drakejanit",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"sleeper_overlay" = "drakesecsleeper",
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakejanitbox")
			),
			// //CassiusRogue request
			"(Janitor) Ratge" = list(
				"cyborg_base_icon" = "ratge",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/ratge.dmi',
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/ratge.dmi', icon_state = "ratge")
			),
			// SPLURT Addon
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_service",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_service")
			),
			// SPLURT Addon
			"(Janitor) Haydee" = list(
				"cyborg_base_icon" = "haydeejan",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeejan")
			),
			// SPLURT Addon, Also added to Bubberstation
			"(Slutvice) Haydee" = list(
				"cyborg_base_icon" = "HaydeeServ",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "HaydeeServ")
			),
			"(Janitor) Meka" = list(
				"cyborg_base_icon" = "mekajani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekajani")
			),
			"(Janitor) M-Meka" = list(
				"cyborg_base_icon" = "mmekajani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekajani")
			),
			"(Janitor) F-Meka" = list(
				"cyborg_base_icon" = "fmekajani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekajani")
			),
			"(Janitor) K4T" = list(
				"cyborg_base_icon" = "k4tjani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tjani")
			),
			"(Janitor Alt) K4T" = list(
				"cyborg_base_icon" = "k4tjani_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tjani_alt1")
			),
			// SPLURT Addon (ChompS Port)
			"(Janitor) Feline" = list(
				"cyborg_base_icon" = "vixjani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixjani-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixjani-b")
			),
			// SPLURT Addon (ChompS Port); If someone decide to make science module for SPLURT, just cut and paste it, then apply tweaks
			"(Janitor Alt) Feline" = list(
				"cyborg_base_icon" = "vixsci",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixsci-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixsci-b")
			),
			// SPLURT Addon (ChompS Port)
			"(Janitor) Raptor V-4" = list(
				"cyborg_base_icon" = "janiraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "janiraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "janiraptor-b")
			),
			// SPLURT Addon (ChompS Port); Ditto with sci module thing.
			"(Janitor Alt) Raptor V-4" = list(
				"cyborg_base_icon" = "sciraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "sciraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "sciraptor-b")
			),
			// BubberStation Port; Made by aKhro/@aKromatopzia (GitHub)
			"(Janitor) SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_jani",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_jani-b")
			),
			// BubberStation Port; Made by aKhro/@aKromatopzia (GitHub); Ditto with sci module thing.
			"(Janitor Alt) SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_sci",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_sci-b")
			),
			//ADD BLUEMOON Note: Был забыт для добавления в список
			"(Service) Meka" = list(
				"cyborg_base_icon" = "mekaserve",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekaserve")
			),
			"(Waiter) Meka" = list(
				"cyborg_base_icon" = "mekaserve_alt",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekaserve_alt")
			),
			// SPLURT Addon (Fallout 13)
			"(Pleasure) Handy" = list(
				"cyborg_base_icon" = "handy_pleasure",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_pleasure")
			),
			//Danaiyka request
			// Bez etogo ne bydet texturki smerti. Ne znayu pochemy tak.
			"(Service) Mechoid" = list(
				"cyborg_base_icon" = "mechoid-civi",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-civi",
				"has_snowflake_deadsprite" = "mechoid-civi-wreck",
				"sleeper_overlay" = "serviraptor-sleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-civi")
			),
			//Danaiyka request
			// Bez etogo ne bydet texturki smerti. Ne znayu pochemy tak.
			"(Janitor) Mechoid" = list(
				"cyborg_base_icon" = "mechoid-janitor",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-janitor",
				"has_snowflake_deadsprite" = "mechoid-janitor-wreck",
				"sleeper_overlay" = "janiraptor-sleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-janitor")
			),
			"(Service) Dullahan" = list(
				"cyborg_base_icon" = "dullahanserv",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanserv")
			),
			"(Janitor) Dullahan" = list(
				"cyborg_base_icon" = "dullahanjani",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanjani")
			),
			"(Janitor) Catborg" = list(
				"cyborg_base_icon" = "service",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_service.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_service.dmi', icon_state = "service")
			),
			"(Janitor) Kittyborg" = list(
				"cyborg_base_icon" = "jani",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_jani.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_jani.dmi', icon_state = "jani")
			),
			"(Janitor) Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaurjani",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaurjani")
			),
			"(Service) Dragon" = list(
				"cyborg_base_icon" = "dragon-serv",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_service.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_service.dmi', icon_state = "dragon-serv")
			),
			"(Janitor) Dragon" = list(
				"cyborg_base_icon" = "dragon-jani",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jani.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jani.dmi', icon_state = "dragon-jani")
			),
			"(Jester) Dragon" = list(
				"cyborg_base_icon" = "dragon-clown",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jester.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_jester.dmi', icon_state = "dragon-clown")
			),
			"(Janitor) Fembot" = list(
				"cyborg_base_icon" = "fembot-service",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"sleeper_overlay" = "fembotsleeper",
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "fembot-service")
			),
			"(Janitor) Fembot (BlueMoon)" = list(
				"cyborg_base_icon" = "fembot-janitor",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-janitor")
			)
		)
	var/static/list/service_icons
	if(!service_icons)
		service_icons = get_borg_skin_preview_icons(service_skin_profiles)
		service_icons = sort_list(service_icons)

	var/list/selectable_service_icons = get_selectable_borg_icons(service_icons, R.client)
	var/service_robot_icon = show_radial_menu(R, R , selectable_service_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(service_robot_icon, R.client))
		return ..()
	// Static skin data migrated from legacy Service/Janitor switch.
	// The duplicate Janitor Fembot cases intentionally remain a legacy switch below.
	if(!apply_borg_skin_profile(service_skin_profiles[service_robot_icon]))
		return FALSE
	return ..()

/obj/item/robot_module/miner
	name = "Miner"
	added_channels = list(RADIO_CHANNEL_SUPPLY = 1)
	basic_modules = list(
		/obj/item/kinetic_crusher/cyborg,
		/obj/item/gun/energy/kinetic_accelerator/cyborg,
		/obj/item/pickaxe/drill/cyborg,
		/obj/item/gun/energy/plasmacutter/cyborg,
		/obj/item/t_scanner/adv_mining_scanner,
		/obj/item/storage/bag/ore/cyborg,
		/obj/item/card/id/miningborg,
		/obj/item/borg/sight/meson,
		/obj/item/gripper/mining,
		/obj/item/cyborg_clamp,
		/obj/item/storage/bag/sheetsnatcher/borg,
		/obj/item/dest_tagger,
		/obj/item/stack/packageWrap/cyborg,
		/obj/item/stack/marker_beacon/cyborg,
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/weldingtool/mini/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/gps/cyborg)
	emag_modules = list(/obj/item/gun/energy/plasmacutter/cyborg/emagged)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/miner,
		/obj/item/clockwork/weapon/ratvarian_spear,
		/obj/item/borg/sight/xray/truesight_lens)
	cyborg_base_icon = "miner"
	moduleselect_icon = "miner"
	hat_offset = 0

/obj/item/robot_module/miner/rebuild_modules()
	. = ..()
	var/mob/living/silicon/robot/R = loc
	if(!iscyborg(R) || QDELETED(R))
		return
	if(!R.GetComponent(/datum/component/robot_module_component/mining_cyborg_goliath_plating))
		R.AddComponent(/datum/component/robot_module_component/mining_cyborg_goliath_plating)

/obj/item/robot_module/miner/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!R?.client)
		return ..() // No UI while a preconfigured cyborg is spawning.
	// BORGV5: previews and appearance are defined together in this skin catalog.
	var/static/list/mining_skin_profiles
	if(!mining_skin_profiles)
		mining_skin_profiles = list(
			"Lavaland" = list(
				"cyborg_base_icon" = "miner",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "miner")
			),
			"Asteroid" = list(
				"cyborg_base_icon" = "minerOLD",
				"special_light_key" = "miner",
				"preview" = image(icon = 'icons/mob/robots.dmi', icon_state = "minerOLD")
			),
			"Droid" = list(
				"cyborg_base_icon" = "miner",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"hat_offset" = DROID_HAT_OFFSET,
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "miner")
			),
			"Sleek" = list(
				"cyborg_base_icon" = "sleekmin",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "sleekmin")
			),
			"Can" = list(
				"cyborg_base_icon" = "canmin",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "canmin")
			),
			"Marina" = list(
				"cyborg_base_icon" = "marinamin",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "marinamin")
			),
			"Spider" = list(
				"cyborg_base_icon" = "spidermin",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "spidermin")
			),
			"Heavy" = list(
				"cyborg_base_icon" = "heavymin",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/robots.dmi',
				"preview" = image(icon = 'modular_citadel/icons/mob/robots.dmi', icon_state = "heavymin")
			),
			"MissM" = list(
				"cyborg_base_icon" = "missm_miner",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "missm_miner")
			),
			"Protectron" = list(
				"cyborg_base_icon" = "protectron_miner",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "protectron_miner")
			),
			"Zoomba" = list(
				"cyborg_base_icon" = "zoomba_miner",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = ZOOMBA_HAT_OFFSET,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "zoomba_miner")
			),
			"Ishimura" = list(
				"cyborg_base_icon" = "ishimura",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "ishimura")
			),
			"Mining Drone" = list(
				"cyborg_base_icon" = "miningdrone",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "miningdrone")
			),
			"RoboMaid" = list(
				"cyborg_base_icon" = "robomaid_miner",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "robomaid_miner")
			),
			"BootyF" = list(
				"cyborg_base_icon" = "bootyminer",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyminer")
			),
			"BootyM" = list(
				"cyborg_base_icon" = "bootyminerM",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyminerM")
			),
			"BootyS" = list(
				"cyborg_base_icon" = "bootyminerS",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "bootyminerS")
			),
			"Handy" = list(
				"cyborg_base_icon" = "handy_miner",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "handy_miner")
			),
			"Blade" = list(
				"cyborg_base_icon" = "blade",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "bladesleeper",
				"hat_offset" = BLADE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "blade", -16)
			),
			"Vale" = list(
				"cyborg_base_icon" = "valemine",
				"cyborg_icon_override" = 'modular_citadel/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "valeminesleeper",
				"hat_offset" = VALE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = build_private_radial_preview('modular_citadel/icons/mob/widerobot.dmi', "valemine", -16)
			),
			"Cargohound" = list(
				"cyborg_base_icon" = "cargohound",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "cargohound-sleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "cargohound-b")
			),
			"Cargohound Dark" = list(
				"cyborg_base_icon" = "cargohounddark",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "cargohounddark-sleeper",
				"hat_offset" = HOUND_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "cargohounddark-b")
			),
			"Otie" = list(
				"cyborg_base_icon" = "otiec",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "otiecsleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "otiec-b")
			),
			"Drake" = list(
				"cyborg_base_icon" = "drakemine",
				"cyborg_icon_override" = 'modular_sand/icons/mob/cyborg/drakemech.dmi',
				"sleeper_overlay" = "drakeminesleeper",
				"hat_offset" = DRAKE_HAT_OFFSET,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"drakerest" = TRUE,
				"preview" = image(icon = 'modular_sand/icons/mob/cyborg/drakemech.dmi', icon_state = "drakeminebox")
			),
			"Fembot" = list(
				"cyborg_base_icon" = "fembot-miner",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/robots.dmi',
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/robots.dmi', icon_state = "fembot-miner")
			),
			"Assaultron" = list(
				"cyborg_base_icon" = "assaultron_mining",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "assaultron_mining")
			),
			"Haydee" = list(
				"cyborg_base_icon" = "haydeeminer",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots.dmi',
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots.dmi', icon_state = "haydeeminer")
			),
			"Meka" = list(
				"cyborg_base_icon" = "mekamine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekamine")
			),
			"Meka (alt)" = list(
				"cyborg_base_icon" = "mekamine_alt",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mekamine_alt")
			),
			"M-Meka" = list(
				"cyborg_base_icon" = "mmekamine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "mmekamine")
			),
			"F-Meka" = list(
				"cyborg_base_icon" = "fmekamine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "fmekamine")
			),
			"K4T" = list(
				"cyborg_base_icon" = "k4tmine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tmine")
			),
			"K4T (alt)" = list(
				"cyborg_base_icon" = "k4tmine_alt1",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "k4tmine_alt1")
			),
			"Feline" = list(
				"cyborg_base_icon" = "vixmine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/widerobot.dmi',
				"sleeper_overlay" = "vixmine-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/widerobot.dmi', icon_state = "vixmine-b")
			),
			"Raptor V-4" = list(
				"cyborg_base_icon" = "mineraptor",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_64x45.dmi',
				"sleeper_overlay" = "mineraptor-sleeper",
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_64x45.dmi', icon_state = "mineraptor-b")
			),
			"Mechoid" = list(
				"cyborg_base_icon" = "mechoid-mining",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robots.dmi',
				"special_light_key" = "mechoid-mining",
				"has_snowflake_deadsprite" = "mechoid-mining-wreck",
				"sleeper_overlay" = "mineraptor-sleeper",
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robots.dmi', icon_state = "mechoid-mining")
			),
			"SmollRaptor" = list(
				"cyborg_base_icon" = "smolraptor_min",
				"cyborg_icon_override" = 'icons/mob/smolraptor.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'icons/mob/smolraptor.dmi', icon_state = "smolraptor_min-b")
			),
			"Dullahan" = list(
				"cyborg_base_icon" = "dullahanmine",
				"cyborg_icon_override" = 'modular_splurt/icons/mob/robots_32x64.dmi',
				"hat_offset" = TALL_HAT_OFFSET,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_splurt/icons/mob/robots_32x64.dmi', icon_state = "dullahanmine")
			),
			"Catborg" = list(
				"cyborg_base_icon" = "mining",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_mining.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/catborgs/catborg_mining.dmi', icon_state = "mining")
			),
			"Kittyborg" = list(
				"cyborg_base_icon" = "mining",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_mine.dmi',
				"dogborg" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/kittycatborgs/kittyborg/Kittyborg_mine.dmi', icon_state = "mining")
			),
			"Dullahan (Taur)" = list(
				"cyborg_base_icon" = "dullahantaurmine",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi',
				"hat_offset" = DULLAHAN_TAUR_HAT_OFFSET,
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dullahan_taur.dmi', icon_state = "dullahantaurmine")
			),
			"Dragon" = list(
				"cyborg_base_icon" = "dragon-mining",
				"cyborg_icon_override" = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_miner.dmi',
				"has_snowflake_deadsprite" = TRUE,
				"hasrest" = TRUE,
				"dogborg" = TRUE,
				"hat_offset" = 3,
				"preview" = image(icon = 'modular_bluemoon/icons/mob/robot/dragonborg/dragon_miner.dmi', icon_state = "dragon-mining")
			)
		)
	var/static/list/mining_icons
	if(!mining_icons)
		mining_icons = get_borg_skin_preview_icons(mining_skin_profiles)
		mining_icons = sort_list(mining_icons)

	var/list/selectable_mining_icons = get_selectable_borg_icons(mining_icons, R.client)
	var/mining_borg_icon = show_radial_menu(R, R , selectable_mining_icons, custom_check = CALLBACK(src, PROC_REF(check_menu), R), radius = 42, require_near = TRUE)
	if(apply_donator_borg_icon(mining_borg_icon, R.client))
		return ..()
	// Refactored from the original selection switch; profiles mirror legacy assignments.
	if(!apply_borg_skin_profile(mining_skin_profiles[mining_borg_icon]))
		return FALSE
	return ..()

/obj/item/robot_module/syndicate
	name = "Syndicate Assault"
	added_channels = list(RADIO_CHANNEL_SYNDICATE = 1)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/melee/transforming/energy/sword/cyborg,
		/obj/item/gun/energy/printer,
		/obj/item/gun/ballistic/revolver/grenadelauncher/cyborg,
		/obj/item/card/emag,
		/obj/item/crowbar/cyborg,
		/obj/item/pinpointer/syndicate_cyborg)

	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/security,
		/obj/item/clockwork/weapon/ratvarian_spear)
	cyborg_base_icon = "synd_sec"
	moduleselect_icon = "malf"
	hat_offset = 3
	use_private_skin_optional_menu = TRUE

/obj/item/robot_module/syndicate/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!show_optional_donator_borg_icon_menu(R))
		return FALSE
	return ..()

/obj/item/robot_module/syndicate/rebuild_modules()
	..()
	var/mob/living/silicon/robot/Syndi = loc
	Syndi.faction  -= "silicon" //ai turrets

/obj/item/robot_module/syndicate/remove_module(obj/item/I, delete_after)
	..()
	var/mob/living/silicon/robot/Syndi = loc
	Syndi.faction += "silicon" //ai is your bff now!

/obj/item/robot_module/syndicate_medical
	name = "Syndicate Medical"
	added_channels = list(RADIO_CHANNEL_SYNDICATE = 1)
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/borghypo/syndicate,
		/obj/item/gripper/medical,
		/obj/item/shockpaddles/syndicate/cyborg,
		/obj/item/healthanalyzer/advanced/cyborg,
		/obj/item/surgical_drapes/advanced,
		/obj/item/retractor/advanced,
		/obj/item/surgicaldrill/advanced,
		/obj/item/scalpel/advanced,
		/obj/item/melee/transforming/energy/sword/cyborg/saw,
		/obj/item/bonesetter,
		/obj/item/blood_filter,
		/obj/item/stack/medical/bone_gel/cyborg,
		/obj/item/roller/robo,
		/obj/item/card/emag,
		/obj/item/pinpointer/syndicate_cyborg,
		/obj/item/stack/medical/gauze/cyborg,
		/obj/item/gun/medbeam/syndicate,
		/obj/item/organ_storage)
	ratvar_modules = list(
		/obj/item/clockwork/slab/cyborg/medical,
		/obj/item/clockwork/weapon/ratvarian_spear)
	cyborg_base_icon = "synd_medical"
	moduleselect_icon = "malf"
	hat_offset = 3
	use_private_skin_optional_menu = TRUE

/obj/item/robot_module/syndicate_medical/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!show_optional_donator_borg_icon_menu(R))
		return FALSE
	return ..()

/obj/item/robot_module/saboteur
	name = "Syndicate Saboteur"
	added_channels = list(RADIO_CHANNEL_SYNDICATE = 1)
	basic_modules = list(
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/nuke,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/holosign_creator/atmos,
		/obj/item/gripper,
		/obj/item/construction/rcd/borg/syndicate,
		/obj/item/pipe_dispenser,
		/obj/item/storage/part_replacer/cyborg,
		/obj/item/lightreplacer/cyborg,
		/obj/item/extinguisher,
		/obj/item/assembly/flash/cyborg,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/borg/sight/thermal,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/dest_tagger/borg,
		/obj/item/stack/cable_coil/cyborg,
		/obj/item/pinpointer/syndicate_cyborg,
		/obj/item/borg_chameleon)

	ratvar_modules = list(
	/obj/item/clockwork/slab/cyborg/engineer,
	/obj/item/clockwork/replica_fabricator/cyborg)

	cyborg_base_icon = "synd_engi"
	moduleselect_icon = "malf"
	magpulsing = TRUE
	hat_offset = -4
	canDispose = TRUE
	cyborg_traits = list(TRAIT_KNOW_ENGI_WIRES)
	use_private_skin_optional_menu = TRUE

/obj/item/robot_module/saboteur/be_transformed_to(obj/item/robot_module/old_module)
	var/mob/living/silicon/robot/R = loc
	if(!show_optional_donator_borg_icon_menu(R))
		return FALSE
	return ..()

/obj/item/robot_module/syndicate/inteq
	name = "InteQ Assault"
	added_channels = list(RADIO_CHANNEL_INTEQ = 1)
	cyborg_base_icon = "inteq_sec"

/obj/item/robot_module/syndicate_medical/inteq
	name = "InteQ Medical"
	added_channels = list(RADIO_CHANNEL_INTEQ = 1)
	cyborg_base_icon = "inteq_medical"

/obj/item/robot_module/saboteur/inteq
	name = "InteQ Saboteur"
	added_channels = list(RADIO_CHANNEL_INTEQ = 1)
	cyborg_base_icon = "inteq_engi"

/datum/robot_energy_storage
	var/name = "Generic energy storage"
	var/max_energy = 30000
	var/recharge_rate = 1000
	var/energy

/datum/robot_energy_storage/New(var/obj/item/robot_module/R = null)
	energy = max_energy
	if(R)
		R.storages |= src
	return

/datum/robot_energy_storage/proc/use_charge(amount)
	if (energy >= amount)
		energy -= amount
		if (energy == 0)
			return TRUE
		return 2
	else
		return FALSE

/datum/robot_energy_storage/proc/add_charge(amount)
	energy = min(energy + amount, max_energy)

/datum/robot_energy_storage/metal
	name = "Metal Synthesizer"

/datum/robot_energy_storage/glass
	name = "Glass Synthesizer"

/datum/robot_energy_storage/wire
	max_energy = 50
	recharge_rate = 2
	name = "Wire Synthesizer"

/datum/robot_energy_storage/medical
	max_energy = 2500
	recharge_rate = 250
	name = "Gauze / Bone Gel"

/datum/robot_energy_storage/beacon
	max_energy = 30
	recharge_rate = 1
	name = "Marker Beacon Storage"

/datum/robot_energy_storage/wrapping_paper
	max_energy = 30
	recharge_rate = 1
	name = "Wrapping Paper Storage"

/obj/item/robot_module/syndicate/spider// used for space ninja and their cyborg hacking special objective
	name = "Spider Assault"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/melee/transforming/energy/sword/cyborg,
		/obj/item/gun/energy/printer,
		/obj/item/pinpointer/spider_cyborg)

	cyborg_base_icon = "spider_sec"

/obj/item/robot_module/syndicate_medical/spider// ditto
	name = "Spider Medical"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/extinguisher/mini,
		/obj/item/crowbar/cyborg,
		/obj/item/reagent_containers/borghypo/syndicate,
		/obj/item/gripper/medical,
		/obj/item/shockpaddles/syndicate/cyborg,
		/obj/item/healthanalyzer/advanced,
		/obj/item/surgical_drapes/advanced,
		/obj/item/retractor,
		/obj/item/hemostat,
		/obj/item/cautery,
		/obj/item/surgicaldrill,
		/obj/item/scalpel,
		/obj/item/bonesetter,
		/obj/item/stack/medical/bone_gel/cyborg,
		/obj/item/melee/transforming/energy/sword/cyborg/saw,
		/obj/item/roller/robo,
		/obj/item/stack/medical/gauze/cyborg,
		/obj/item/gun/medbeam,
		/obj/item/organ_storage,
		/obj/item/pinpointer/spider_cyborg)

	cyborg_base_icon = "spider_medical"

/obj/item/robot_module/saboteur/spider// ditto
	name = "Spider Saboteur"
	basic_modules = list(
		/obj/item/assembly/flash/cyborg,
		/obj/item/borg/sight/thermal,
		/obj/item/construction/rcd/borg/syndicate,
		/obj/item/pipe_dispenser,
		/obj/item/restraints/handcuffs/cable/zipties,
		/obj/item/extinguisher,
		/obj/item/weldingtool/largetank/cyborg,
		/obj/item/screwdriver/nuke,
		/obj/item/wrench/cyborg,
		/obj/item/crowbar/cyborg,
		/obj/item/wirecutters/cyborg,
		/obj/item/multitool/cyborg,
		/obj/item/storage/part_replacer/cyborg,
		/obj/item/holosign_creator/atmos,
		/obj/item/gripper,
		/obj/item/lightreplacer/cyborg,
		/obj/item/stack/sheet/metal/cyborg,
		/obj/item/stack/sheet/glass/cyborg,
		/obj/item/stack/sheet/rglass/cyborg,
		/obj/item/stack/rods/cyborg,
		/obj/item/stack/tile/plasteel/cyborg,
		/obj/item/dest_tagger/borg,
		/obj/item/stack/cable_coil/cyborg,
		/obj/item/borg_chameleon,
		/obj/item/pinpointer/spider_cyborg)

	cyborg_base_icon = "spider_engi"
