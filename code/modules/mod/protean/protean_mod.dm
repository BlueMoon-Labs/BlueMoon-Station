/datum/mod_theme/protean
	name = "protean"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/item/mod/control/pre_equipped/protean
	name = "MOD control unit"
	desc = "An integrated nanomachine housing. Its owner can retreat inside to recover and assist another wearer."
	theme = /datum/mod_theme/protean
	applied_core = /obj/item/mod/core/protean
	equip_cell = null
	initial_modules = list(/obj/item/mod/module/storage/extended, /obj/item/mod/module/protean_servo)
	var/modlocked = FALSE
	COOLDOWN_DECLARE(movement_cooldown)
	var/obj/item/mod/control/stored_modsuit
	var/list/cached_modules = list()
	var/list/native_modules = list()
	var/datum/mod_theme/stored_theme
	var/stored_skin

/obj/item/mod/control/pre_equipped/protean/Initialize(mapload, new_theme, new_skin)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)
	AddElement(/datum/element/strippable/protean, GLOB.strippable_human_items)

/obj/item/mod/control/pre_equipped/protean/Destroy()
	var/obj/item/mod/core/protean/protean_core = core
	var/mob/living/carbon/human/human = protean_core?.linked_protean
	if(human)
		if(human.remote_control == src)
			human.remote_control = null
		if(human.loc == src)
			human.forceMove(drop_location())
			human.SetStun(0)
			var/obj/item/organ/brain/protean/brain = human.getorganslot(ORGAN_SLOT_BRAIN)
			if(istype(brain))
				brain.set_transform_traits(FALSE)
		set_protean_modsuit(human, null)
	var/obj/item/mod/control/other = release_stored_modsuit()
	other?.forceMove(drop_location())
	for(var/obj/item/mod/module/module in take_cached_modules())
		module.forceMove(drop_location())
	cached_modules = null
	native_modules = null
	stored_theme = null
	stored_skin = null
	return ..()

/obj/item/mod/control/pre_equipped/protean/proc/get_protean()
	var/obj/item/mod/core/protean/protean_core = core
	return protean_core?.linked_protean

/obj/item/mod/control/pre_equipped/protean/proc/set_distress_signal(enabled)
	var/mutable_appearance/light = mutable_appearance('modular_bluemoon/icons/mob/protean/distress_light.dmi', "distress")
	cut_overlay(light)
	if(enabled)
		add_overlay(light)

/obj/item/mod/control/pre_equipped/protean/can_replace_cell()
	return FALSE

/obj/item/mod/control/pre_equipped/protean/emag_act(mob/user, obj/item/card/emag/emag_card)
	return FALSE

/obj/item/mod/control/pre_equipped/protean/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_BACK)
		return
	if(user == get_protean() || modlocked)
		ADD_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)

/obj/item/mod/control/pre_equipped/protean/proc/drop_suit()
	REMOVE_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)
	if(wearer)
		wearer.dropItemToGround(src, TRUE)

/obj/item/mod/control/pre_equipped/protean/proc/toggle_lock()
	modlocked = !modlocked
	if(modlocked || wearer == get_protean())
		ADD_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)
	else
		REMOVE_TRAIT(src, TRAIT_NODROP, PROTEAN_TRAIT)

/obj/item/mod/control/pre_equipped/protean/proc/obeys(mob/user)
	if(!modlocked || !is_active() || user == get_protean())
		return TRUE
	balloon_alert(user, "refuses to listen!")
	return FALSE

/obj/item/mod/control/pre_equipped/protean/choose_deploy(mob/user)
	if(obeys(user))
		return ..()

/obj/item/mod/control/pre_equipped/protean/quick_toggle_parts(mob/user)
	if(obeys(user))
		return ..()

/obj/item/mod/control/pre_equipped/protean/conceal(mob/user, part, force = FALSE)
	if(force || obeys(user))
		return ..()

/obj/item/mod/control/pre_equipped/protean/toggle_activate(mob/user, force_deactivate = FALSE)
	if(!force_deactivate && !obeys(user))
		return FALSE
	var/mob/living/carbon/human/human = get_protean()
	if(!is_active() && human?.has_status_effect(/datum/status_effect/protean_low_power_mode))
		balloon_alert(user, "энергосбережение или восстановление формы")
		return FALSE
	return ..()

/obj/item/mod/control/pre_equipped/protean/ui_status(mob/user, datum/ui_state/state)
	if(user == get_protean() && user.loc == src)
		return UI_INTERACTIVE
	return ..()

/obj/item/mod/control/pre_equipped/protean/ui_state(mob/user)
	if(user == get_protean() && user.loc == src)
		return GLOB.contained_state
	return ..()

/obj/item/mod/control/pre_equipped/protean/attackby(obj/item/item, mob/living/user, params)
	if(istype(item, /obj/item/organ/stomach/protean))
		return install_refactory(item, user)
	if(!istype(item, /obj/item/mod/control) && !istype(item, /obj/item/mod/construction/armor))
		return ..()
	if(is_active() || is_activating() || stored_modsuit)
		balloon_alert(user, "deactivate and remove absorbed suit!")
		return TRUE
	if(istype(item, /obj/item/mod/control) && !can_assimilate_modsuit(item))
		balloon_alert(user, "несовместимый MOD")
		return TRUE
	if(!do_after(user, PROTEAN_ASSIMILATE_TIME, src) || QDELETED(item) || !user.is_holding(item) || is_active() || is_activating() || stored_modsuit)
		return TRUE
	if(istype(item, /obj/item/mod/control))
		assimilate_modsuit(user, item)
		return TRUE
	var/obj/item/mod/construction/armor/plating = item
	if(!user.temporarilyRemoveItemFromInventory(plating))
		return TRUE
	change_theme(GLOB.mod_themes[plating.theme])
	qdel(plating)
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/install_refactory(obj/item/organ/stomach/protean/stomach, mob/living/user)
	var/mob/living/carbon/human/human = get_protean()
	var/obj/item/organ/brain/protean/brain = human?.getorganslot(ORGAN_SLOT_BRAIN)
	if(!istype(brain) || !brain.dead || !is_open() || human.getorganslot(ORGAN_SLOT_STOMACH) || !brain.can_repair())
		return TRUE
	if(!do_after(user, PROTEAN_REPAIR_INSTALL_TIME, src))
		return TRUE
	if(QDELETED(human) || QDELETED(stomach) || QDELETED(brain) || get_protean() != human || human.getorganslot(ORGAN_SLOT_BRAIN) != brain || !brain.dead || human.loc != src || !is_open() || human.getorganslot(ORGAN_SLOT_STOMACH) || !brain.can_repair())
		return TRUE
	if(!user.temporarilyRemoveItemFromInventory(stomach))
		return TRUE
	stomach.Insert(human, special = TRUE)
	brain.revive_timer()
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/retract_parts()
	if(is_active())
		finish_activation(FALSE)
	for(var/obj/item/clothing/mod_part/part in get_mod_parts(include_cell = FALSE))
		part.seal_part(FALSE)
		if(wearer && part.loc == wearer)
			conceal(wearer, part, TRUE)

/obj/item/mod/control/pre_equipped/protean/proc/change_theme(datum/mod_theme/new_theme, new_skin)
	if(!new_theme)
		return FALSE
	retract_parts()
	var/list/armor_modules = list()
	for(var/obj/item/mod/module/armor/plate in modules.Copy())
		armor_modules += plate
		uninstall(plate, deleting = TRUE)
	for(var/obj/item/part in get_mod_parts(include_cell = FALSE, include_mod = TRUE))
		part.name = initial(part.name)
		part.desc = initial(part.desc)
	var/obj/item/clothing/mod_part/suit/chest = get_chestplate()
	chest.allowed = MOD_BASE_ALLOWED
	remove_hardlight()
	QDEL_NULL(hardlight_effect)
	theme = new_theme
	theme.setup_theme(src, new_skin)
	for(var/obj/item/mod/module/armor/plate in armor_modules)
		if(theme.compatible_with_armor_modules)
			install(plate)
		if(plate.mod != src)
			plate.forceMove(drop_location())
	update_speed()
	update_hardlight()
	SStgui.update_uis(src)
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/assimilate_modsuit(mob/living/user, obj/item/mod/control/other, forced = FALSE)
	if(QDELETED(user) || stored_modsuit || !can_assimilate_modsuit(other) || is_active() || is_activating())
		return FALSE
	if(other.is_active() || other.is_activating() || other.one_of_parts_deployed())
		return FALSE
	if(other.ai && !ispAI(other.ai))
		balloon_alert(user, "remove the AI first!")
		return FALSE
	if(!user.temporarilyRemoveItemFromInventory(other, force = forced))
		return FALSE
	native_modules = list()
	for(var/obj/item/mod/module/module in modules)
		native_modules += WEAKREF(module)
	stored_modsuit = other
	RegisterSignal(other, COMSIG_PARENT_QDELETING, PROC_REF(on_stored_modsuit_deleted))
	stored_theme = theme
	stored_skin = skin
	other.remove_pai()
	var/list/incoming_contents = other.contents.Copy()
	for(var/atom/movable/stored in incoming_contents)
		stored.moveToNullspace()
	other.moveToNullspace()
	change_theme(other.theme, other.skin)
	var/list/saved_contents = contents.Copy()
	for(var/atom/movable/stored in saved_contents)
		stored.moveToNullspace()
	var/obj/item/mod/module/storage/new_storage = locate() in other.modules
	if(new_storage)
		var/obj/item/mod/module/storage/old_storage = locate() in modules
		if(old_storage)
			cached_modules += old_storage
			RegisterSignal(old_storage, COMSIG_PARENT_QDELETING, PROC_REF(on_cached_module_deleted))
			uninstall(old_storage)
	for(var/obj/item/mod/module/module in other.modules.Copy())
		other.uninstall(module, deleting = istype(module, /obj/item/mod/module/armor/prebuild))
		install(module)
		if(module.mod != src)
			module.forceMove(user.drop_location())
	for(var/atom/movable/stored in saved_contents + incoming_contents)
		stored.forceMove(src)
	enforce_complexity_limit(user)
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/can_assimilate_modsuit(obj/item/mod/control/other)
	return !QDELETED(other) && other != src && !istype(other, /obj/item/mod/control/pre_equipped/protean) && (other.slot_flags & ITEM_SLOT_BACK)

/obj/item/mod/control/pre_equipped/protean/proc/unassimilate_modsuit(mob/living/user, forced = FALSE)
	if(QDELETED(stored_modsuit) || (!forced && (is_active() || is_activating() || QDELETED(user))))
		return FALSE
	var/obj/item/mod/control/other = stored_modsuit
	if(!forced && (!user.has_active_hand() || !do_after(user, PROTEAN_ASSIMILATE_TIME, src)))
		return FALSE
	if(QDELETED(src) || QDELETED(other) || stored_modsuit != other || (!forced && (is_active() || is_activating())))
		return FALSE
	retract_parts()
	var/list/saved_contents = contents.Copy()
	for(var/atom/movable/stored in saved_contents)
		stored.moveToNullspace()
	var/list/retained_modules = list()
	for(var/datum/weakref/module_ref in native_modules)
		var/obj/item/mod/module/module = module_ref.resolve()
		if(module)
			retained_modules += module
	for(var/obj/item/mod/module/module in modules.Copy())
		if(module in retained_modules)
			continue
		uninstall(module, deleting = istype(module, /obj/item/mod/module/armor/prebuild))
		stored_modsuit.install(module)
		if(module.mod != stored_modsuit)
			module.forceMove(drop_location())
	change_theme(stored_theme, stored_skin)
	stored_theme = null
	stored_skin = null
	for(var/obj/item/mod/module/module in take_cached_modules())
		install(module)
		if(module.mod != src)
			module.forceMove(drop_location())
	native_modules.Cut()
	for(var/atom/movable/stored in saved_contents)
		stored.forceMove(src)
	stored_modsuit.forceMove(drop_location())
	if(user)
		user.put_in_hands(stored_modsuit)
	release_stored_modsuit()
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/release_stored_modsuit()
	var/obj/item/mod/control/other = stored_modsuit
	if(other)
		UnregisterSignal(other, COMSIG_PARENT_QDELETING)
	stored_modsuit = null
	return other

/obj/item/mod/control/pre_equipped/protean/proc/take_cached_modules()
	var/list/result = cached_modules.Copy()
	for(var/obj/item/mod/module/module in result)
		UnregisterSignal(module, COMSIG_PARENT_QDELETING)
	cached_modules.Cut()
	return result

/obj/item/mod/control/pre_equipped/protean/proc/on_cached_module_deleted(obj/item/mod/module/module)
	SIGNAL_HANDLER
	cached_modules -= module

/obj/item/mod/control/pre_equipped/protean/proc/on_stored_modsuit_deleted()
	SIGNAL_HANDLER
	release_stored_modsuit()
	stored_theme = null
	stored_skin = null
	native_modules.Cut()
	for(var/obj/item/mod/module/module in take_cached_modules())
		module.forceMove(drop_location())

/obj/item/mod/control/pre_equipped/protean/proc/unassimilate_theme()
	if(is_active() || is_activating() || stored_modsuit)
		return FALSE
	return change_theme(GLOB.mod_themes[/datum/mod_theme/protean])

/obj/item/mod/control/pre_equipped/protean/proc/enforce_complexity_limit(mob/user)
	for(var/obj/item/mod/module/module in modules.Copy())
		if(complexity <= complexity_max)
			break
		if(istype(module, /obj/item/mod/module/protean_servo) || istype(module, /obj/item/mod/module/storage))
			continue
		uninstall(module)
		module.forceMove(drop_location())

/obj/item/mod/control/pre_equipped/protean/examine(mob/user)
	. = ..()
	var/mob/living/carbon/human/human = get_protean()
	var/obj/item/organ/brain/protean/brain = human?.getorganslot(ORGAN_SLOT_BRAIN)
	if(!istype(brain) || !brain.dead)
		return
	if(!brain.can_repair())
		. += span_warning("The core no longer responds to repair attempts.")
	else if(human.getorganslot(ORGAN_SLOT_STOMACH))
		. += span_notice("The refactory is rebuilding the nanomachine mass.")
	else
		. += span_warning("Open the maintenance panel with a screwdriver and insert a replacement refactory.")

/obj/item/mod/control/pre_equipped/protean/proc/stop_for_low_power()
	if(is_activating())
		return FALSE
	if(is_active())
		for(var/obj/item/clothing/mod_part/part as anything in get_mod_parts(include_cell = FALSE))
			part.seal_part(FALSE)
	finish_activation(FALSE)
	return TRUE

/obj/item/mod/control/pre_equipped/protean/proc/stop_servo()
	var/obj/item/mod/module/protean_servo/servo = locate() in modules
	if(servo?.active)
		servo.on_deactivation()
