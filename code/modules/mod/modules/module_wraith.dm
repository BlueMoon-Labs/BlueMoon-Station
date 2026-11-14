/obj/item/mod/module/stealth/wraith
	name = "MOD Wraith cloaking module"
	desc = "Включённый модуль скрывает владельца и позволяет перегружать свет и электронику, пополняя заряд костюма. После срыва маскировка восстанавливается с задержкой, пока модуль включён. Несовместим с бронеплитами."
	icon_state = "cloak_traitor"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	stealth_alpha = 30
	passive_cloak = TRUE
	cooldown_time = 2 SECONDS
	incompatible_modules = list(/obj/item/mod/module/stealth, /obj/item/mod/module/welding/syndicate)
	var/stealth_active = FALSE
	var/mob/living/carbon/human/cloak_user
	COOLDOWN_DECLARE(recloak_timer)

/obj/item/mod/module/stealth/wraith/Destroy()
	stop_stealth()
	return ..()

/obj/item/mod/module/stealth/wraith/can_install(obj/item/mod/control/suit, mob/user)
	if(locate(/obj/item/mod/module/armor) in suit.modules)
		if(user)
			balloon_alert(user, "сначала снимите бронеплиты")
		return FALSE
	return ..()

/obj/item/mod/module/stealth/wraith/on_activation()
	if(!cloak_ready())
		mod?.balloon_alert(mod.wearer, "разверните костюм полностью")
		return FALSE
	. = ..()
	if(.)
		start_stealth()

/obj/item/mod/module/stealth/wraith/on_deactivation(display_message = TRUE, deleting = FALSE)
	stop_stealth()
	return ..()

/obj/item/mod/module/stealth/wraith/on_suit_deactivation()
	stop_stealth()

/obj/item/mod/module/stealth/wraith/on_unequip()
	stop_stealth()

/obj/item/mod/module/stealth/wraith/on_uninstall(deleting = FALSE, user)
	stop_stealth()
	return ..()

/obj/item/mod/module/stealth/wraith/on_process(delta_time)
	. = ..()
	if(!. || !active || !cloak_ready())
		stop_stealth()
		return
	if(cloak_user && cloak_user != mod.wearer)
		stop_stealth()
	if(!stealth_active)
		start_stealth()

/obj/item/mod/module/stealth/wraith/proc/start_stealth()
	if(!active || stealth_active || !cloak_ready() || !COOLDOWN_FINISHED(src, recloak_timer) || !check_power(use_power_cost))
		return FALSE
	cloak_user = mod.wearer
	RegisterSignal(cloak_user, COMSIG_PARENT_QDELETING, PROC_REF(on_cloak_user_deleted))
	RegisterSignal(cloak_user, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_cloak_part_removed))
	enable_cloak()
	RegisterSignal(cloak_user, list(COMSIG_ATOM_BUMPED, COMSIG_LIVING_GUN_PROCESS_FIRE), PROC_REF(unstealth))
	stealth_active = TRUE
	return TRUE

/obj/item/mod/module/stealth/wraith/proc/cloak_ready()
	if(!mod?.wearer || !mod.is_active())
		return FALSE
	for(var/obj/item/clothing/mod_part/part in mod.get_mod_parts(include_cell = FALSE))
		if(!part.check_module_ready())
			return FALSE
	return TRUE

/obj/item/mod/module/stealth/wraith/proc/stop_stealth()
	stealth_active = FALSE
	if(!cloak_user)
		return
	UnregisterSignal(cloak_user, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_BUMPED, COMSIG_LIVING_GUN_PROCESS_FIRE, COMSIG_MOB_UNEQUIPPED_ITEM))
	disable_cloak(cloak_user)
	cloak_user = null

/obj/item/mod/module/stealth/wraith/proc/on_cloak_part_removed(mob/source, obj/item/item)
	SIGNAL_HANDLER
	if(item in mod.get_mod_parts(include_cell = FALSE))
		stop_stealth()

/obj/item/mod/module/stealth/wraith/proc/on_cloak_user_deleted()
	SIGNAL_HANDLER
	stop_stealth()

/obj/item/mod/module/stealth/wraith/unstealth()
	if(!stealth_active)
		return
	stop_stealth()
	COOLDOWN_START(src, recloak_timer, MOD_WRAITH_RECLOAK)

/obj/item/mod/module/stealth/wraith/on_select_use(atom/target)
	if(!..() || target == mod.wearer)
		return FALSE
	if(get_dist(mod.wearer, target) > MOD_WRAITH_RANGE || !can_see(mod.wearer, target, MOD_WRAITH_RANGE))
		balloon_alert(mod.wearer, "слишком далеко")
		return FALSE
	if(istype(target, /obj/machinery/power/apc))
		balloon_alert(mod.wearer, "ЛКП защищён")
		return FALSE
	var/list/targets = list(target)
	if(iscarbon(target))
		var/mob/living/carbon/carbon = target
		targets |= carbon.get_all_gear()
	else if(isliving(target))
		targets |= target.GetAllContents()
	for(var/obj/item/mod/control/suit in targets.Copy())
		targets |= suit.modules
	var/success = FALSE
	for(var/atom/device in targets)
		if(!device.mod_disrupt(MOD_WRAITH_DURATION))
			continue
		success = TRUE
		mod.core.add_charge((DEFAULT_CHARGE_DRAIN * 250))
	return success

/atom/proc/mod_disrupt(duration)
	return FALSE

/atom/proc/apply_mod_disruption(duration)
	if(HAS_TRAIT(src, TRAIT_MOD_DISRUPTED))
		return FALSE
	AddComponent(/datum/component/mod_disruption, duration)
	return TRUE

/datum/component/mod_disruption
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/restore_turret = FALSE

/datum/component/mod_disruption/Initialize(duration)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	ADD_TRAIT(parent, TRAIT_MOD_DISRUPTED, REF(src))
	if(istype(parent, /obj/machinery/camera))
		var/obj/machinery/camera/camera = parent
		GLOB.cameranet.removeCamera(camera)
		GLOB.cameranet.invalidate_camera_cache()
		camera.set_light(0)
	if(istype(parent, /obj/machinery/porta_turret))
		var/obj/machinery/porta_turret/turret = parent
		restore_turret = turret.on
		turret.toggle_on(FALSE)
	QDEL_IN(src, duration)

/datum/component/mod_disruption/UnregisterFromParent()
	REMOVE_TRAIT(parent, TRAIT_MOD_DISRUPTED, REF(src))
	if(!QDELETED(parent) && istype(parent, /obj/machinery/camera))
		var/obj/machinery/camera/camera = parent
		if(camera.can_use())
			GLOB.cameranet.addCamera(camera)
		GLOB.cameranet.invalidate_camera_cache()
	if(!QDELETED(parent) && restore_turret)
		var/obj/machinery/porta_turret/turret = parent
		turret.toggle_on(TRUE)
	return ..()

/obj/item/flashlight/mod_disrupt(duration)
	if(!apply_mod_disruption(duration))
		return FALSE
	on = FALSE
	update_brightness()
	return TRUE

/obj/item/mod/module/flashlight/mod_disrupt(duration)
	if(!active || !apply_mod_disruption(duration))
		return FALSE
	on_deactivation()
	return TRUE

/obj/machinery/light/mod_disrupt(duration)
	return break_light_tube()

/obj/machinery/power/floodlight/mod_disrupt(duration)
	if(flags_1 & NODECONSTRUCT_1)
		return FALSE
	obj_break(ENERGY)
	return TRUE

/obj/machinery/camera/mod_disrupt(duration)
	if(isEmpProof())
		return FALSE
	return apply_mod_disruption(duration * MOD_WRAITH_CAMERA_MULTIPLIER)

/obj/machinery/porta_turret/mod_disrupt(duration)
	return apply_mod_disruption(duration)

/mob/living/simple_animal/bot/secbot/mod_disrupt(duration)
	if(!apply_mod_disruption(duration))
		return FALSE
	target = null
	mode = BOT_IDLE
	walk_to(src, 0)
	return TRUE

/mob/living/silicon/robot/mod_disrupt(duration)
	if(!apply_mod_disruption(duration))
		return FALSE
	toggle_headlamp(TRUE)
	return TRUE

/mob/living/silicon/pai/mod_disrupt(duration)
	if(!apply_mod_disruption(duration))
		return FALSE
	silent = max(silent, round(duration / SSmobs.wait))
	balloon_alert(src, "звук заблокирован")
	return TRUE

/obj/item/paicard/mod_disrupt(duration)
	return pai?.mod_disrupt(duration)

/obj/item/modular_computer/mod_disrupt(duration)
	if(!has_light || !apply_mod_disruption(duration))
		return FALSE
	set_light_on(FALSE)
	update_icon()
	return TRUE

/obj/item/radio/mod_disrupt(duration)
	if(!broadcasting || !apply_mod_disruption(duration))
		return FALSE
	broadcasting = FALSE
	update_icon()
	return TRUE

/obj/item/melee/baton/mod_disrupt(duration)
	if(!turned_on || !apply_mod_disruption(duration))
		return FALSE
	switch_status(FALSE)
	return TRUE

/obj/item/clothing/head/hardhat/mod_disrupt(duration)
	if(!on || !apply_mod_disruption(duration))
		return FALSE
	toggle_helmet_light()
	return TRUE

/obj/item/clothing/head/helmet/space/plasmaman/mod_disrupt(duration)
	if(!helmet_on || !apply_mod_disruption(duration))
		return FALSE
	helmet_on = FALSE
	set_light(0)
	update_icon()
	return TRUE

/obj/item/kinetic_crusher/mod_disrupt(duration)
	if(!light_on || !apply_mod_disruption(duration))
		return FALSE
	set_light_on(FALSE)
	update_brightness()
	update_icon()
	return TRUE

/obj/vehicle/sealed/mecha/mod_disrupt(duration)
	if(!(mecha_flags & LIGHTS_ON) || !apply_mod_disruption(duration))
		return FALSE
	mecha_flags &= ~LIGHTS_ON
	set_light(0)
	return TRUE
