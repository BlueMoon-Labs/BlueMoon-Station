/obj/item/organ/cyberimp/brain/nif
	name = "Nanite Implant Framework"
	desc = "A brain implant that infuses its user with nanites and runs NIFSoft programs."
	icon = 'icons/obj/clothing/modsuit/nifs.dmi'
	icon_state = "base_nif"
	w_class = WEIGHT_CLASS_NORMAL
	slot = ORGAN_SLOT_BRAIN_NIF
	actions_types = list(/datum/action/item_action/nif)
	var/mob/living/carbon/human/linked_mob
	var/stored_ckey
	var/is_calibrated = FALSE
	var/calibrating = FALSE
	var/calibration_end
	var/calibration_time = 3 MINUTES
	var/max_power_level = 1000
	var/power_level = 1000
	var/nutrition_drain = FALSE
	var/blood_drain = FALSE
	var/max_durability = 100
	var/durability = 100
	var/broken = FALSE
	var/max_nifsofts = 5
	var/list/loaded_nifsofts = list()
	var/recovery_timer
	COOLDOWN_DECLARE(damage_grace)

/obj/item/organ/cyberimp/brain/nif/Initialize(mapload)
	. = ..()
	power_level = max_power_level
	durability = max_durability

/obj/item/organ/cyberimp/brain/nif/Destroy()
	deltimer(recovery_timer)
	QDEL_LIST(loaded_nifsofts)
	linked_mob = null
	return ..()

/obj/item/organ/cyberimp/brain/nif/Insert(mob/living/carbon/human/receiver, special = FALSE, drop_if_replaced = TRUE)
	if(!istype(receiver) || (stored_ckey && receiver.ckey && stored_ckey != receiver.ckey))
		return FALSE
	. = ..()
	if(owner != receiver)
		return FALSE
	linked_mob = receiver
	stored_ckey = receiver.ckey
	calibrating = !is_calibrated
	calibration_end = world.time + calibration_time
	RegisterSignal(receiver, COMSIG_LIVING_DEATH, PROC_REF(on_wearer_death))
	START_PROCESSING(SSobj, src)

/obj/item/organ/cyberimp/brain/nif/Remove(special = FALSE)
	if(linked_mob)
		linked_mob.cure_blind(NIF_TRAIT)
		UnregisterSignal(linked_mob, COMSIG_LIVING_DEATH)
	QDEL_LIST(loaded_nifsofts)
	loaded_nifsofts = list()
	linked_mob = null
	calibrating = FALSE
	return ..()

/obj/item/organ/cyberimp/brain/nif/process(delta_time)
	if(!linked_mob)
		return ..()
	if(broken || durability <= 0 || linked_mob.stat == DEAD || IS_IN_STASIS(linked_mob))
		return
	if(calibrating)
		calibrate()
		return
	recharge(delta_time)
	for(var/datum/nifsoft/program in loaded_nifsofts.Copy())
		if(program.active && !change_power_level(program.active_cost * delta_time))
			program.deactivate()

/obj/item/organ/cyberimp/brain/nif/proc/calibrate()
	if(linked_mob.stat == DEAD)
		return
	var/progress = 1 - (calibration_end - world.time) / calibration_time
	if(progress < NIF_CALIBRATION_BLIND)
		linked_mob.become_blind(NIF_TRAIT)
	if(progress >= NIF_CALIBRATION_CLEAR)
		linked_mob.cure_blind(NIF_TRAIT)
	if(progress < 1)
		if(progress >= NIF_CALIBRATION_CLEAR && progress <= NIF_CALIBRATION_END)
			switch(rand(1, NIF_CALIBRATION_RISK))
				if(NIF_CALIBRATION_NAUSEA)
					linked_mob.adjust_disgust(NIF_CALIBRATION_DISGUST)
				if(NIF_CALIBRATION_FATIGUE)
					linked_mob.adjustStaminaLoss(NIF_CALIBRATION_STAMINA)
				else
					return
		return
	calibrating = FALSE
	is_calibrated = TRUE
	to_chat(linked_mob, span_notice("NIF calibration complete."))

/obj/item/organ/cyberimp/brain/nif/proc/recharge(delta_time)
	if(power_level >= max_power_level)
		return
	if(nutrition_drain)
		if(HAS_TRAIT(linked_mob, TRAIT_NOHUNGER) || linked_mob.nutrition < NIF_MIN_NUTRITION)
			nutrition_drain = FALSE
		else
			var/used = min(linked_mob.nutrition - NIF_MIN_NUTRITION, NIF_NUTRITION_RATE * delta_time)
			linked_mob.adjust_nutrition(-used)
			change_power_level(-used * NIF_CONVERSION_RATE)
	if(!blood_drain)
		return
	if(linked_mob.blood_volume <= BLOOD_VOLUME_SAFE)
		blood_drain = FALSE
		return
	var/used = min(linked_mob.blood_volume - BLOOD_VOLUME_SAFE, delta_time)
	linked_mob.blood_volume -= used
	change_power_level(-used * NIF_CONVERSION_RATE)

/obj/item/organ/cyberimp/brain/nif/proc/change_power_level(amount)
	if(amount > power_level)
		return FALSE
	power_level = clamp(power_level - amount, 0, max_power_level)
	return TRUE

/obj/item/organ/cyberimp/brain/nif/proc/install_nifsoft(datum/nifsoft/program)
	if(installation_error(program.type))
		return FALSE
	loaded_nifsofts += program
	program.parent_nif = WEAKREF(src)
	program.linked_mob = linked_mob
	return TRUE

/obj/item/organ/cyberimp/brain/nif/proc/on_wearer_death()
	SIGNAL_HANDLER
	for(var/datum/nifsoft/program in loaded_nifsofts)
		program.deactivate()
	if(!COOLDOWN_FINISHED(src, damage_grace))
		return
	durability = max(0, durability - NIF_DURABILITY_LOSS)
	COOLDOWN_START(src, damage_grace, 20 MINUTES)

/obj/item/organ/cyberimp/brain/nif/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF || !COOLDOWN_FINISHED(src, damage_grace))
		return
	broken = TRUE
	durability = max(0, durability - NIF_DURABILITY_LOSS * (severity >= NIF_EMP_THRESHOLD ? 1 : NIF_LIGHT_EMP_FACTOR))
	COOLDOWN_START(src, damage_grace, 3 MINUTES)
	for(var/datum/nifsoft/program in loaded_nifsofts)
		program.deactivate()
	deltimer(recovery_timer)
	recovery_timer = addtimer(CALLBACK(src, PROC_REF(recover)), 30 SECONDS, TIMER_STOPPABLE)

/obj/item/organ/cyberimp/brain/nif/proc/recover()
	recovery_timer = null
	broken = FALSE

/obj/item/organ/cyberimp/brain/nif/standard
	name = "Standard Type NIF"

/obj/item/organ/cyberimp/brain/nif/roleplay_model
	name = "Econo-Deck Type NIF"
	max_power_level = 1000 / 2
	max_nifsofts = 3
	calibration_time = 1 MINUTES
	max_durability = 100 / 2

/obj/item/organ/cyberimp/brain/nif/roleplay_model/cheap
	name = "Trial-Lite Type NIF"

/obj/item/organ/cyberimp/brain/nif/standard/ghost_role
	is_calibrated = TRUE

/datum/nifsoft
	var/name = "NIFSoft"
	var/program_desc
	var/datum/weakref/parent_nif
	var/mob/living/carbon/human/linked_mob
	var/purchase_price = 300
	var/active = FALSE
	var/active_cost = 0
	var/activation_cost = 0
	var/active_mode = TRUE
	var/category = "Общее"
	var/compatible_nif = /obj/item/organ/cyberimp/brain/nif
	var/exclusive_group
	COOLDOWN_DECLARE(use_cooldown)

/datum/nifsoft/New(obj/item/organ/cyberimp/brain/nif/implant)
	. = ..()
	if(!implant?.install_nifsoft(src))
		qdel(src)

/datum/nifsoft/Destroy()
	deactivate()
	var/obj/item/organ/cyberimp/brain/nif/implant = parent_nif?.resolve()
	if(implant)
		implant.loaded_nifsofts -= src
	parent_nif = null
	linked_mob = null
	return ..()

/datum/nifsoft/proc/activate()
	if(active)
		deactivate()
		return TRUE
	if(!can_activate())
		return FALSE
	var/obj/item/organ/cyberimp/brain/nif/implant = parent_nif.resolve()
	if(!implant.change_power_level(activation_cost))
		to_chat(linked_mob, span_warning("NIF: недостаточно энергии для запуска [name]."))
		return FALSE
	active = active_mode
	return TRUE

/datum/nifsoft/proc/can_activate()
	var/obj/item/organ/cyberimp/brain/nif/implant = parent_nif?.resolve()
	return !QDELETED(src) && implant && !implant.calibrating && !implant.broken && implant.durability > 0 && (src in implant.loaded_nifsofts) && linked_mob && !linked_mob.incapacitated() && COOLDOWN_FINISHED(src, use_cooldown)

/datum/nifsoft/proc/deactivate()
	active = FALSE

/datum/nifsoft/scryer
	name = "NIFLink Holocaller"
	purchase_price = 200
	program_desc = "Project a wearable terminal for holographic calls with MODlink devices."
	active_cost = 1
	activation_cost = 20
	var/obj/item/clothing/neck/link_scryer/loaded/nifsoft/linked_scryer

/datum/nifsoft/scryer/New(obj/item/organ/cyberimp/brain/nif/implant)
	. = ..()
	if(QDELETED(src))
		return
	linked_scryer = new(implant)
	linked_scryer.parent_nifsoft = WEAKREF(src)

/datum/nifsoft/scryer/Destroy()
	deactivate()
	QDEL_NULL(linked_scryer)
	return ..()

/datum/nifsoft/scryer/activate()
	if(active)
		deactivate()
		return TRUE
	if(!linked_scryer || linked_mob?.handcuffed || linked_mob?.wear_neck || !..())
		return FALSE
	if(linked_mob.equip_to_slot_if_possible(linked_scryer, ITEM_SLOT_NECK))
		return TRUE
	deactivate()
	return FALSE

/datum/nifsoft/scryer/deactivate()
	. = ..()
	if(!linked_scryer)
		return
	linked_scryer.mod_link.end_call()
	var/obj/item/organ/cyberimp/brain/nif/implant = parent_nif?.resolve()
	if(!implant)
		return
	if(linked_mob?.is_holding(linked_scryer) || linked_mob?.wear_neck == linked_scryer)
		linked_mob.temporarilyRemoveItemFromInventory(linked_scryer, TRUE)
	linked_scryer.forceMove(implant)

/obj/item/clothing/neck/link_scryer/loaded/nifsoft
	name = "NIFLink Holocaller"
	desc = "A hardlight MODlink terminal projected by a nanite implant."
	removable_cell = FALSE
	var/datum/weakref/parent_nifsoft

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/Initialize(mapload)
	. = ..()
	QDEL_NULL(cell)
	cell = new /obj/item/stock_parts/cell/infinite/nif_cell(src)

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/Destroy()
	var/datum/nifsoft/scryer/program = parent_nifsoft?.resolve()
	if(program)
		program.linked_scryer = null
		program.deactivate()
	parent_nifsoft = null
	return ..()

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/AltClick(mob/user)
	return

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/screwdriver_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "cell is integrated!")
	return TOOL_ACT_TOOLTYPE_SUCCESS

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/dropped(mob/user)
	. = ..()
	var/datum/nifsoft/scryer/program = parent_nifsoft?.resolve()
	if(program?.active)
		program.deactivate()

/obj/item/clothing/neck/link_scryer/loaded/nifsoft/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK)
		return
	var/datum/nifsoft/scryer/program = parent_nifsoft?.resolve()
	if(program?.active)
		program.deactivate()

/obj/item/stock_parts/cell/infinite/nif_cell
	name = "nanite cell"

/obj/item/disk/nifsoft_uploader
	name = "NIFSoft uploader disk"
	icon = 'icons/obj/clothing/modsuit/nif_disks.dmi'
	icon_state = "base_disk"
	var/loaded_nifsoft = /datum/nifsoft/scryer

/obj/item/disk/nifsoft_uploader/attack_self(mob/living/carbon/human/user)
	attempt_install(user)

/obj/item/disk/nifsoft_uploader/attack(mob/living/carbon/human/target, mob/living/user)
	if(!istype(target) || !user.is_holding(src) || !do_after(user, 5 SECONDS, target) || QDELETED(src) || !user.is_holding(src))
		return
	attempt_install(target)

/obj/item/disk/nifsoft_uploader/proc/attempt_install(mob/living/carbon/human/human)
	if(!istype(human))
		return FALSE
	var/obj/item/organ/cyberimp/brain/nif/implant = human.getorganslot(ORGAN_SLOT_BRAIN_NIF)
	if(!istype(implant))
		return FALSE
	var/datum/nifsoft/program = new loaded_nifsoft(implant)
	if(QDELETED(program))
		return FALSE
	qdel(src)
	return TRUE

/obj/item/disk/nifsoft_uploader/scryer
	name = "NIFSoft Scryer Uploader Disk"

/datum/action/item_action/nif
	name = "Open NIF Menu"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/item_action/nif/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/obj/item/organ/cyberimp/brain/nif/implant = target
	implant.ui_interact(owner)

/obj/item/organ/cyberimp/brain/nif/ui_interact(mob/user, datum/tgui/ui)
	if(user != linked_mob)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "NIFLink", name)
		ui.open()

/obj/item/organ/cyberimp/brain/nif/ui_state(mob/user)
	return GLOB.conscious_state

/obj/item/organ/cyberimp/brain/nif/ui_status(mob/user, datum/ui_state/state)
	if(!linked_mob || user != linked_mob || owner != user)
		return UI_CLOSE
	return GLOB.conscious_state.can_use_topic(src, user)

/obj/item/organ/cyberimp/brain/nif/ui_data(mob/user)
	var/list/programs = list()
	for(var/datum/nifsoft/program in loaded_nifsofts)
		programs += list(list("name" = program.name, "description" = program.program_desc, "active" = program.active,
			"toggle" = program.active_mode, "ready" = program.can_activate(), "ref" = REF(program)))
	return list("power" = power_level, "maximum" = max_power_level, "durability" = durability, "max_durability" = max_durability, "calibrating" = calibrating,
		"calibration_remaining" = calibrating ? clamp(calibration_end - world.time, 0, calibration_time) / (1 SECONDS) : 0,
		"broken" = broken, "nutrition" = nutrition_drain, "blood" = blood_drain, "programs" = programs,
		"catalog" = program_catalog(), "slots" = max_nifsofts, "balance" = linked_mob?.get_bank_account()?.account_balance)

/obj/item/organ/cyberimp/brain/nif/ui_act(action, params)
	if(..() || usr != linked_mob || owner != linked_mob)
		return FALSE
	switch(action)
		if("nutrition")
			nutrition_drain = !nutrition_drain
		if("blood")
			blood_drain = !blood_drain
		if("activate", "remove")
			var/datum/nifsoft/program = locate(params["ref"]) in loaded_nifsofts
			if(!program)
				return FALSE
			if(action == "activate")
				program.activate()
			else
				qdel(program)
		if("purchase")
			return purchase_program(text2path(params["program"]))
	return TRUE

/obj/item/autosurgeon/nif
	name = "Standard Type NIF Autosurgeon"
	starting_organ = /obj/item/organ/cyberimp/brain/nif/standard
	uses = 1

/obj/item/autosurgeon/nif/attack_self(mob/living/carbon/human/user)
	var/obj/item/organ/cyberimp/brain/nif/implant = storedorgan
	if(!istype(user) || !istype(implant) || (implant.stored_ckey && implant.stored_ckey != user.ckey))
		return
	return ..()

/obj/item/autosurgeon/nif/disposable
	name = "Econo-Deck Type Autosurgeon"
	starting_organ = /obj/item/organ/cyberimp/brain/nif/roleplay_model/cheap

/obj/item/autosurgeon/nif/ghost_role
	name = "Enhanced Standard Type NIF Autosurgeon"
	starting_organ = /obj/item/organ/cyberimp/brain/nif/standard/ghost_role

/obj/item/nif_repair_kit
	name = "Cerulean NIF Regenerator"
	desc = "A nanite paste applicator for repairing implanted NIFs."
	icon = 'icons/obj/clothing/modsuit/nif_devices.dmi'
	icon_state = "repair_paste"
	w_class = WEIGHT_CLASS_SMALL
	var/uses = 5

/obj/item/nif_repair_kit/attack(mob/living/carbon/human/target, mob/living/user)
	if(!istype(target) || !uses)
		return
	var/obj/item/organ/cyberimp/brain/nif/implant = target.getorganslot(ORGAN_SLOT_BRAIN_NIF)
	if(!istype(implant) || implant.durability >= implant.max_durability)
		return
	if(!do_after(user, 5 SECONDS, target) || QDELETED(src) || QDELETED(implant) || implant.owner != target || !uses)
		return
	implant.durability = min(implant.max_durability, implant.durability + NIF_REPAIR_AMOUNT)
	if(!--uses)
		qdel(src)

/obj/item/nifsoft_remover
	name = "Lopland 'Wrangler' NIF-Cutter"
	desc = "A device that removes installed NIFSoft programs."
	icon = 'icons/obj/clothing/modsuit/nif_devices.dmi'
	icon_state = "nifsoft_remover"
	var/create_disk = FALSE

/obj/item/nifsoft_remover/attack(mob/living/carbon/human/target, mob/living/user)
	if(!istype(target))
		return
	var/obj/item/organ/cyberimp/brain/nif/implant = target.getorganslot(ORGAN_SLOT_BRAIN_NIF)
	if(!istype(implant) || !length(implant.loaded_nifsofts))
		return
	var/datum/nifsoft/program = tgui_input_list(user, "Choose a program to remove", name, implant.loaded_nifsofts)
	if(!program || QDELETED(implant) || !user.is_holding(src) || !do_after(user, 5 SECONDS, target))
		return
	if(QDELETED(src) || QDELETED(implant) || implant.owner != target || !(program in implant.loaded_nifsofts) || !user.is_holding(src))
		return
	if(create_disk)
		var/obj/item/disk/nifsoft_uploader/disk = new(user.drop_location())
		disk.loaded_nifsoft = program.type
		disk.name = "[program.name] datadisk"
		user.put_in_hands(disk)
	log_combat(user, target, "removed NIFSoft", program.name)
	qdel(program)

/obj/item/nifsoft_remover/syndie
	name = "Cybersun 'Scalpel' NIF-Cutter"
	icon_state = "nifsoft_remover_syndie"
	create_disk = TRUE

/datum/supply_pack/medical/nif
	name = "NIF Holocalling Kit"
	desc = "A NIF autosurgeon, holocaller program and maintenance tools."
	cost = CARGO_CRATE_VALUE * 5
	contains = list(/obj/item/autosurgeon/nif, /obj/item/disk/nifsoft_uploader/scryer, /obj/item/nif_repair_kit, /obj/item/nifsoft_remover, /obj/item/nif_hud_adapter)
	crate_name = "NIF holocalling kit"
