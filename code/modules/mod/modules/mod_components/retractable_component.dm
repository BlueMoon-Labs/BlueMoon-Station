/datum/component/mod_retractable
	var/obj/item/storage_module
	var/obj/item/using_device
	var/obj/item/mod/control/my_modsuit
	var/retract_sound
	var/deploying = FALSE

/datum/component/mod_retractable/Initialize(device, modsuit, retract_sound, obj/item/stored_in)
	if(!istype(parent, /obj/item/mod/module) || !istype(device, /obj/item) || !istype(modsuit, /obj/item/mod/control))
		return COMPONENT_INCOMPATIBLE
	storage_module = stored_in ? stored_in : parent
	using_device = device
	my_modsuit = modsuit
	src.retract_sound = retract_sound
	RegisterSignal(using_device, COMSIG_MOVABLE_MOVED, PROC_REF(check_range))
	RegisterSignal(src, COMSIG_MODULE_ON_USE, PROC_REF(retract_in_hands))

/datum/component/mod_retractable/proc/retract_in_hands(datum/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(toggle_device))

/datum/component/mod_retractable/proc/toggle_device()
	var/mob/living/carbon/wearer = my_modsuit?.wearer
	if(deploying || QDELETED(using_device) || QDELETED(wearer))
		return
	if(wearer.is_holding(using_device))
		snap_back()
		return
	deploying = TRUE
	var/held = wearer.put_in_hands(using_device)
	deploying = FALSE
	check_range()
	if(held && !QDELETED(using_device) && wearer.is_holding(using_device))
		playsound(my_modsuit, retract_sound, MOD_RETRACT_VOLUME, TRUE)

/datum/component/mod_retractable/Destroy()
	UnregisterSignal(src, COMSIG_MODULE_ON_USE)
	UnregisterSignal(using_device, COMSIG_MOVABLE_MOVED)
	storage_module = null
	using_device = null
	my_modsuit = null
	return ..()

/datum/component/mod_retractable/proc/check_range()
	SIGNAL_HANDLER
	if(deploying || QDELETED(using_device) || QDELETED(storage_module) || QDELETED(my_modsuit))
		return
	if(using_device.loc == storage_module || my_modsuit.wearer?.is_holding(using_device))
		return
	snap_back()

/datum/component/mod_retractable/proc/snap_back()
	if(QDELETED(using_device) || QDELETED(storage_module) || using_device.loc == storage_module)
		return
	using_device.forceMove(storage_module)
	var/obj/item/mod/module/module = parent
	if(module.active)
		module.on_deactivation()
	playsound(my_modsuit, retract_sound, MOD_RETRACT_VOLUME, TRUE)
