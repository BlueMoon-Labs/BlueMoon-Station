/obj/item/mod/module/thermal_regulator
	name = "MOD thermal regulator module"
	desc = "Терморегулятор поддерживает выбранную носителем температуру тела."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "regulator"
	module_type = MODULE_TOGGLE
	complexity = 1
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	incompatible_modules = list(/obj/item/mod/module/thermal_regulator)
	var/temperature_setting = BODYTEMP_NORMAL
	var/min_temp = T20C
	var/max_temp = T0C + 45

/obj/item/mod/module/thermal_regulator/get_configuration()
	. = ..()
	.["temperature_setting"] = add_ui_configuration("Temperature", "number", temperature_setting - T0C)

/obj/item/mod/module/thermal_regulator/configure_edit(key, value)
	if(key == "temperature_setting" && isnum(value))
		temperature_setting = clamp(value + T0C, min_temp, max_temp)

/obj/item/mod/module/thermal_regulator/on_active_process(delta_time)
	var/difference = temperature_setting - mod.wearer.bodytemperature
	mod.wearer.adjust_bodytemperature(SIGN(difference) * (BODYTEMP_AUTORECOVERY_DIVISOR / MOD_REGULATOR_DIVISOR) * log(1 + abs(difference) * MOD_REGULATOR_RATE * delta_time))

/obj/item/mod/module/signlang_radio
	name = "MOD glove translator module"
	desc = "Датчики перчаток передают жестовую речь по рации."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "signlang_radio"
	complexity = 1
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	required_modpart_index = MOD_PART_GLOVES
	incompatible_modules = list(/obj/item/mod/module/signlang_radio)

/obj/item/mod/module/signlang_radio/on_suit_activation()
	if(check_required_modpart())
		ADD_TRAIT(mod.wearer, TRAIT_CAN_SIGN_ON_COMMS, REF(src))

/obj/item/mod/module/signlang_radio/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_CAN_SIGN_ON_COMMS, REF(src))

/obj/item/mod/module/joint_torsion
	name = "MOD joint torsion ratchet module"
	desc = "Генератор заряжает батарею за счёт движения суставов при ходьбе. Не работает в невесомости."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "joint_torsion"
	complexity = 1
	required_modpart_index = MOD_PART_FEET
	var/power_per_step = DEFAULT_CHARGE_DRAIN * 0.45

/obj/item/mod/module/joint_torsion/on_suit_activation()
	if(check_required_modpart())
		RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved), override = TRUE)

/obj/item/mod/module/joint_torsion/on_suit_deactivation()
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)

/obj/item/mod/module/joint_torsion/proc/on_moved(mob/living/source, atom/old_loc, direction, forced)
	SIGNAL_HANDLER
	if(forced || source.throwing || source.buckled || source.body_position == LYING_DOWN)
		return
	if(!check_required_modpart() || !source.has_gravity() || source.movement_type & (FLOATING | FLYING))
		return
	mod.core?.add_charge(power_per_step)

/obj/item/mod/module/hearing_protection
	name = "MOD hearing protection module"
	desc = "Защищает слух носителя от громких звуков."
	removable = FALSE
	incompatible_modules = list(/obj/item/mod/module/hearing_protection)
	required_modpart_index = MOD_PART_HEAD

/obj/item/mod/module/hearing_protection/on_suit_activation()
	if(check_required_modpart())
		RegisterSignal(mod.wearer, COMSIG_CARBON_SOUNDBANG, PROC_REF(reduce_bang), override = TRUE)

/obj/item/mod/module/hearing_protection/on_suit_deactivation()
	UnregisterSignal(mod.wearer, COMSIG_CARBON_SOUNDBANG)

/obj/item/mod/module/hearing_protection/proc/reduce_bang(datum/source, list/protection)
	SIGNAL_HANDLER
	protection[1]--

/obj/item/mod/module/plate_compression
	name = "MOD plate compression module"
	desc = "Плотно складывает костюм до обычного размера. Несовместим с хранилищами."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "plate_compression"
	complexity = 2
	incompatible_modules = list(/obj/item/mod/module/plate_compression, /obj/item/mod/module/storage)
	var/new_size = WEIGHT_CLASS_NORMAL
	var/old_size

/obj/item/mod/module/plate_compression/on_install()
	. = ..()
	old_size = mod.w_class
	mod.w_class = new_size

/obj/item/mod/module/plate_compression/on_uninstall(deleting, user)
	mod.w_class = old_size
	old_size = null
	var/datum/component/storage/storage = mod.loc?.GetComponent(/datum/component/storage)
	if(storage && storage.max_w_class < mod.w_class)
		storage.remove_from_storage(mod, mod.drop_location())
	return ..()

/obj/item/mod/module/medbeam
	name = "MOD medical beamgun module"
	desc = "Наручный медицинский луч для лечения союзников."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "chronogun"
	module_type = MODULE_ACTIVE
	complexity = 1
	active_power_cost = DEFAULT_CHARGE_DRAIN
	device = /obj/item/gun/medbeam/mod
	incompatible_modules = list(/obj/item/mod/module/medbeam)
	cooldown_time = 0.05 SECONDS

/obj/item/gun/medbeam/mod
	name = "MOD medbeam"

/obj/item/mod/module/injector
	name = "MOD injector module"
	desc = "Выдвижной шприц увеличенной ёмкости, способный проникать через броню."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "injector"
	module_type = MODULE_ACTIVE
	complexity = 1
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	device = /obj/item/reagent_containers/syringe/mod
	incompatible_modules = list(/obj/item/mod/module/injector)
	cooldown_time = 0.5 SECONDS
	required_modpart_index = MOD_PART_GLOVES

/obj/item/reagent_containers/syringe/mod
	name = "MOD injector syringe"
	desc = "Шприц увеличенной ёмкости, способный проникать через броню."
	volume = 30
	amount_per_transfer_from_this = 30
	possible_transfer_amounts = list(5, 5 * 2, 5 * 3, 5 * 4, 30)
	proj_piercing = SYRINGE_PIERCE_ALL

/obj/item/mod/module/status_readout
	name = "MOD status readout module"
	desc = "A once-common module, this technology unfortunately went out of fashion in the safer regions of space; \
		and found new life in the research networks of the Periphery. This particular unit hooks into the suit's spine, \
		capable of capturing and displaying all possible biometric data of the wearer; sleep, nutrition, fitness, fingerprints, \
		and even useful information such as their overall health and wellness. The vitals monitor also comes with a speaker, loud enough \
		to alert anyone nearby that someone has, in fact, died."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "status"
	mod_module_flags = MOD_MODULE_GENERAL
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.1
	incompatible_modules = list(/obj/item/mod/module/status_readout)
	tgui_id = "status_readout"
	var/display_detailed_vitals = TRUE
	var/display_dna = FALSE
	var/display_time = FALSE
	var/death_sound = 'sound/effects/flatline3.ogg'
	var/death_sound_volume = 50
	var/sensor_boost = TRUE

/obj/item/mod/module/status_readout/add_ui_data()
	. = ..()
	.["display_time"] = display_time
	.["shift_time"] = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	.["shift_id"] = GLOB.round_id
	.["health"] = mod.wearer?.health || 0
	.["health_max"] = mod.wearer?.getMaxHealth() || 0
	if(display_detailed_vitals)
		.["loss_brute"] = mod.wearer?.getBruteLoss() || 0
		.["loss_fire"] = mod.wearer?.getFireLoss() || 0
		.["loss_tox"] = mod.wearer?.getToxLoss() || 0
		.["loss_oxy"] = mod.wearer?.getOxyLoss() || 0
		.["body_temperature"] = mod.wearer?.bodytemperature || 0
		.["nutrition"] = mod.wearer?.nutrition || 0
	if(display_dna)
		.["dna_unique_identity"] = mod.wearer ? md5(mod.wearer.dna.uni_identity) : null
		.["dna_unique_enzymes"] = mod.wearer?.dna.unique_enzymes
	.["viruses"] = null
	if(!length(mod.wearer?.diseases))
		return .
	var/list/viruses = list()
	for(var/datum/disease/virus as anything in mod.wearer.diseases)
		var/list/virus_data = list()
		virus_data["name"] = virus.name
		virus_data["type"] = virus.spread_text
		virus_data["stage"] = virus.stage
		virus_data["maxstage"] = virus.max_stages
		virus_data["cure"] = virus.cure_text
		viruses += list(virus_data)
	.["viruses"] = viruses

	return .

/obj/item/mod/module/status_readout/get_configuration()
	. = ..()
	.["display_detailed_vitals"] = add_ui_configuration("Detailed Vitals", "bool", display_detailed_vitals)
	.["display_dna"] = add_ui_configuration("DNA Information", "bool", display_dna)
	.["sensor_boost"] = add_ui_configuration("Suit Sensor Booster", "bool", sensor_boost)

/obj/item/mod/module/status_readout/configure_edit(key, value)
	switch(key)
		if("display_detailed_vitals")
			display_detailed_vitals = (value == TRUE || value == "1" || value == "true")
		if("display_dna")
			display_dna = (value == TRUE || value == "1" || value == "true")
		if("sensor_boost")
			sensor_boost = (value == TRUE || value == "1" || value == "true")
			update_sensor_booster()

/obj/item/mod/module/status_readout/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_LIVING_DEATH, PROC_REF(death_sound), override = TRUE)
	update_sensor_booster()

/obj/item/mod/module/status_readout/on_suit_deactivation(deleting)
	UnregisterSignal(mod.wearer, COMSIG_LIVING_DEATH)
	REMOVE_TRAIT(mod.wearer, TRAIT_MULTIZ_SUIT_SENSORS, REF(src))

/obj/item/mod/module/status_readout/proc/update_sensor_booster()
	if(sensor_boost && mod.is_active())
		ADD_TRAIT(mod.wearer, TRAIT_MULTIZ_SUIT_SENSORS, REF(src))
	else
		REMOVE_TRAIT(mod.wearer, TRAIT_MULTIZ_SUIT_SENSORS, REF(src))

/obj/item/mod/module/status_readout/proc/death_sound(mob/living/carbon/human/wearer)
	SIGNAL_HANDLER
	if(death_sound && death_sound_volume)
		playsound(wearer, death_sound, death_sound_volume, FALSE)

/obj/item/mod/module/status_readout/ninja
	name = "MOD Spider Clan status readout module"
	display_time = TRUE
	sensor_boost = FALSE
	death_sound = null

/obj/item/mod/module/shock_absorber
	name = "MOD shock absorption module"
	desc = "Absorbs the disabling shock of stun batons."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "no_baton"
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN
	mod_module_flags = MOD_MODULE_SECURITY
	incompatible_modules = list(/obj/item/mod/module/shock_absorber)

/obj/item/mod/module/shock_absorber/on_suit_activation()
	ADD_TRAIT(mod.wearer, TRAIT_BATON_RESISTANCE, REF(src))
	RegisterSignal(mod.wearer, COMSIG_MOD_BATON_RESISTED, PROC_REF(on_baton), override = TRUE)

/obj/item/mod/module/shock_absorber/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_BATON_RESISTANCE, REF(src))
	UnregisterSignal(mod.wearer, COMSIG_MOD_BATON_RESISTED)

/obj/item/mod/module/shock_absorber/proc/on_baton(mob/living/source)
	SIGNAL_HANDLER
	drain_power(use_power_cost)
	do_sparks(MOD_SHOCK_SPARKS, TRUE, source)

/obj/item/mod/module/tanner
	name = "MOD tanning module"
	desc = "A spray-tanning module. Rumors of radiation exposure remain unconfirmed."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "tanning"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	incompatible_modules = list(/obj/item/mod/module/tanner)
	cooldown_time = 30 SECONDS
	required_modpart_index = MOD_PART_CHEST
	mod_module_flags = MOD_MODULE_GENERAL

/obj/item/mod/module/tanner/on_use()
	if(!drain_power(use_power_cost))
		return FALSE
	playsound(mod.wearer, 'sound/machines/microwave/microwave-end.ogg', 50, TRUE)
	var/datum/reagents/holder = new(MOD_TANNER_VOLUME)
	holder.add_reagent(/datum/reagent/spraytan, MOD_TANNER_VOLUME)
	holder.reaction(mod.wearer, VAPOR)
	holder.trans_to(mod.wearer, MOD_TANNER_VOLUME)
	qdel(holder)
	if(prob(MOD_TANNER_RAD_CHANCE) && !HAS_TRAIT(mod.wearer, TRAIT_RADIMMUNE))
		mod.wearer.radiation = max(mod.wearer.radiation, RAD_MOB_HAIRLOSS)
	return TRUE

/obj/item/mod/module/headprotector
	name = "MOD safety-first head protection module"
	desc = "Helmet dampeners protect the brain from blunt impacts."
	icon_state = "welding"
	complexity = 1
	required_modpart_index = MOD_PART_HEAD
	incompatible_modules = list(/obj/item/mod/module/headprotector, /obj/item/mod/module/infiltrator)
	mod_module_flags = MOD_MODULE_ENGINEERING

/obj/item/mod/module/headprotector/on_suit_activation()
	if(check_required_modpart())
		ADD_TRAIT(mod.wearer, TRAIT_HEAD_INJURY_BLOCKED, REF(src))

/obj/item/mod/module/headprotector/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_HEAD_INJURY_BLOCKED, REF(src))

/obj/item/mod/module/plasma_stabilizer
	name = "MOD plasma stabilizer module"
	desc = "Maintains an oxygen-free atmosphere around a plasmaman's head, even with the helmet retracted."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "plasma_stabilizer"
	complexity = 1
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	incompatible_modules = list(/obj/item/mod/module/plasma_stabilizer)
	mod_module_flags = MOD_MODULE_GENERAL

/obj/item/mod/module/plasma_stabilizer/on_equip()
	ADD_TRAIT(mod.wearer, TRAIT_HEAD_ATMOS_SEALED, REF(src))

/obj/item/mod/module/plasma_stabilizer/on_unequip()
	REMOVE_TRAIT(mod.wearer, TRAIT_HEAD_ATMOS_SEALED, REF(src))

/obj/item/mod/module/quick_cuff
	name = "MOD restraint assist module"
	desc = "Enhanced gauntlet grip pads help the wearer apply restraints more quickly."
	complexity = 0
	required_modpart_index = MOD_PART_GLOVES
	incompatible_modules = list(/obj/item/mod/module/quick_cuff)
	mod_module_flags = MOD_MODULE_SECURITY

/obj/item/mod/module/quick_cuff/on_suit_activation()
	if(check_required_modpart())
		ADD_TRAIT(mod.wearer, TRAIT_FAST_CUFFING, REF(src))

/obj/item/mod/module/quick_cuff/on_suit_deactivation()
	REMOVE_TRAIT(mod.wearer, TRAIT_FAST_CUFFING, REF(src))

/obj/item/mod/module/disposal_connector
	name = "MOD disposal selector module"
	desc = "Selects a destination while travelling through the disposal pipeline."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "disposal"
	complexity = 2
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	incompatible_modules = list(/obj/item/mod/module/disposal_connector)
	mod_module_flags = MOD_MODULE_SUPPLY
	var/disposal_tag

/obj/item/mod/module/disposal_connector/Initialize(mapload)
	. = ..()
	disposal_tag = rand(1, length(GLOB.TAGGERLOCATIONS))

/obj/item/mod/module/disposal_connector/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_DISPOSING, PROC_REF(on_disposing), override = TRUE)

/obj/item/mod/module/disposal_connector/on_suit_deactivation()
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_DISPOSING)

/obj/item/mod/module/disposal_connector/get_configuration()
	. = ..()
	.["disposal_tag"] = add_ui_configuration("Disposal Tag", "list", GLOB.TAGGERLOCATIONS[disposal_tag], GLOB.TAGGERLOCATIONS)

/obj/item/mod/module/disposal_connector/configure_edit(key, value)
	if(key == "disposal_tag" && (value in GLOB.TAGGERLOCATIONS))
		disposal_tag = GLOB.TAGGERLOCATIONS.Find(value)

/obj/item/mod/module/disposal_connector/proc/on_disposing(datum/source, obj/structure/disposalholder/holder)
	SIGNAL_HANDLER
	holder.destinationTag = disposal_tag

/obj/item/mod/module/thread_ripper
	name = "MOD thread ripper module"
	desc = "Opens clothing around the selected body part for medical access and repairs it when the patient leaves."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "thread_ripper"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/thread_ripper)
	cooldown_time = 1.5 SECONDS
	required_modpart_index = MOD_PART_GLOVES
	mod_module_flags = MOD_MODULE_MEDICAL
	var/list/ripped_clothing = list()
	var/ripping = FALSE

/obj/item/mod/module/thread_ripper/Destroy()
	mend_all()
	ripped_clothing = null
	return ..()

/obj/item/mod/module/thread_ripper/on_select_use(atom/target)
	if(!..() || ripping || length(ripped_clothing) || !iscarbon(target) || target == mod.wearer || !mod.wearer.Adjacent(target))
		return FALSE
	var/mob/living/carbon/patient = target
	var/mob/living/carbon/human/user = mod.wearer
	var/target_zones = zone2body_parts_covered(user.zone_selected)
	ripping = TRUE
	playsound(src, 'sound/items/zip.ogg', MOD_SUPPORT_VOLUME, TRUE, frequency = -1)
	var/finished = do_after(user, 1.5 SECONDS, patient)
	ripping = FALSE
	if(!finished || QDELETED(src) || mod?.wearer != user || !active || !check_required_modpart() || !drain_power(use_power_cost))
		return FALSE
	for(var/obj/item/clothing/clothing in patient.get_equipped_items())
		var/shared_flags = target_zones & clothing.body_parts_covered
		if(!shared_flags)
			continue
		ripped_clothing[clothing] = shared_flags
		clothing.body_parts_covered &= ~shared_flags
		RegisterSignal(clothing, COMSIG_PARENT_QDELETING, PROC_REF(on_clothing_deleted))
	return TRUE

/obj/item/mod/module/thread_ripper/proc/on_clothing_deleted(obj/item/clothing/source)
	SIGNAL_HANDLER
	ripped_clothing -= source

/obj/item/mod/module/thread_ripper/on_active_process(delta_time)
	for(var/obj/item/clothing/clothing in ripped_clothing.Copy())
		var/mob/living/carbon/patient = clothing.loc
		if(istype(patient) && mod.wearer.Adjacent(patient) && !patient.is_holding(clothing))
			continue
		mend(clothing)

/obj/item/mod/module/thread_ripper/proc/mend(obj/item/clothing/clothing)
	if(!QDELETED(clothing))
		clothing.body_parts_covered |= ripped_clothing[clothing]
		UnregisterSignal(clothing, COMSIG_PARENT_QDELETING)
	ripped_clothing -= clothing

/obj/item/mod/module/thread_ripper/proc/mend_all()
	if(!length(ripped_clothing))
		return
	for(var/obj/item/clothing/clothing in ripped_clothing.Copy())
		mend(clothing)

/obj/item/mod/module/thread_ripper/on_deactivation()
	mend_all()
	return ..()

/obj/item/mod/module/organizer
	name = "MOD organizer module"
	desc = "Stores up to five organs and replaces exposed organs during surgery from a distance."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "organizer"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/organizer, /obj/item/mod/module/microwave_beam)
	cooldown_time = 0.5 SECONDS
	required_modpart_index = MOD_PART_GLOVES
	mod_module_flags = MOD_MODULE_MEDICAL
	var/list/organ_list = list()

/obj/item/mod/module/organizer/Destroy()
	for(var/obj/item/organ/organ in organ_list)
		organ.forceMove(drop_location())
	organ_list = null
	return ..()

/obj/item/mod/module/organizer/Exited(atom/movable/gone, direction)
	organ_list -= gone
	return ..()

/obj/item/mod/module/organizer/on_select_use(atom/target)
	if(!..() || !get_turf(target))
		return FALSE
	if(istype(target, /obj/item/organ))
		var/obj/item/organ/organ = target
		if(organ.owner || !isturf(organ.loc) || !mod.wearer.Adjacent(organ) || length(organ_list) >= MOD_ORGANIZER_CAPACITY)
			return FALSE
		organ.forceMove(src)
		organ_list += organ
	else
		if(!length(organ_list))
			return FALSE
		var/obj/item/organ/organ = organ_list[length(organ_list)]
		var/obj/item/projectile/mod_organ/projectile = new(get_turf(mod.wearer), organ)
		projectile.firer = mod.wearer
		projectile.preparePixelProjectile(target, mod.wearer)
		INVOKE_ASYNC(projectile, TYPE_PROC_REF(/obj/item/projectile, fire))
	playsound(src, 'sound/mecha/hydraulic.ogg', MOD_SUPPORT_VOLUME, TRUE)
	drain_power(use_power_cost)
	return TRUE

/obj/item/projectile/mod_organ
	name = "organ"
	damage = 0
	hitsound = 'sound/effects/attackblob.ogg'
	var/obj/item/organ/organ

/obj/item/projectile/mod_organ/Initialize(mapload, obj/item/organ/stored_organ)
	. = ..()
	if(!stored_organ)
		return INITIALIZE_HINT_QDEL
	appearance = stored_organ.appearance
	organ = stored_organ
	organ.forceMove(src)

/obj/item/projectile/mod_organ/Destroy()
	if(organ)
		organ.forceMove(drop_location())
	organ = null
	return ..()

/obj/item/projectile/mod_organ/on_hit(atom/target, blocked = 0)
	. = ..()
	if(!iscarbon(target) || !organ)
		return
	var/mob/living/carbon/patient = target
	for(var/datum/surgery/procedure in patient.surgeries)
		if(procedure.location != organ.zone || !ispath(procedure.steps[procedure.status], /datum/surgery_step/manipulate_organs))
			continue
		var/obj/item/organ/old = patient.getorganslot(organ.slot)
		if(old?.organ_flags & ORGAN_UNREMOVABLE)
			return
		organ.Insert(patient, TRUE)
		if(organ.owner == patient)
			organ = null
		return

/obj/item/mod/module/scorpion_hook
	name = "MOD SCORPION hook module"
	desc = "A wrist-mounted hardlight hook pulls its target closer and exhausts them."
	icon = 'icons/obj/clothing/modsuit/contractor_modules.dmi'
	icon_state = "hook"
	module_type = MODULE_ACTIVE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	device = /obj/item/gun/magic/hook/contractor
	incompatible_modules = list(/obj/item/mod/module/scorpion_hook)
	cooldown_time = 0.5 SECONDS
	required_modpart_index = MOD_PART_GLOVES

/obj/item/mod/module/scorpion_hook/infiltrator
	complexity = 0
	removable = FALSE

/obj/item/gun/magic/hook/contractor
	name = "SCORPION hook"
	desc = "A hardlight hook used to non-lethally pull targets closer."
	icon = 'icons/obj/clothing/modsuit/contractor_hook.dmi'
	icon_state = "hook_weapon"
	item_state = ""
	ammo_type = /obj/item/ammo_casing/magic/hook/contractor

/obj/item/ammo_casing/magic/hook/contractor
	projectile_type = /obj/item/projectile/hook/contractor

/obj/item/projectile/hook/contractor
	icon = 'icons/obj/clothing/modsuit/contractor_hook_projectile.dmi'
	damage = 0
	stamina = 25

/obj/item/projectile/hook/contractor/fire(setAngle)
	. = ..()
	QDEL_NULL(chain)
	if(firer)
		chain = firer.Beam(src, icon = icon, icon_state = "chain", time = INFINITY, maxdistance = INFINITY)
	return .

/obj/item/mod/module/flamethrower
	name = "MOD flamethrower module"
	desc = "Выдвижной огнемёт с питанием от MOD-костюма."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "flamethrower"
	module_type = MODULE_ACTIVE
	device = /obj/item/gun/magic/mod_flamethrower
	complexity = 3
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	incompatible_modules = list(/obj/item/mod/module/flamethrower)
	cooldown_time = 2.5 SECONDS
	required_modpart_index = MOD_PART_CHEST

/obj/item/mod/module/flamethrower/on_install()
	. = ..()
	var/obj/item/gun/magic/mod_flamethrower/gun = device
	gun.power_module = src

/obj/item/mod/module/flamethrower/on_uninstall(deleting = FALSE, user)
	var/obj/item/gun/magic/mod_flamethrower/gun = device
	if(gun)
		gun.power_module = null
	return ..()

/obj/item/mod/module/flamethrower/Destroy()
	var/obj/item/gun/magic/mod_flamethrower/gun = device
	if(gun)
		gun.power_module = null
	return ..()

/obj/item/gun/magic/mod_flamethrower
	name = "MOD flamethrower"
	desc = "Выдвижной огнемёт с питанием от MOD-костюма."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "flamethrower"
	item_state = "flamethrower_1"
	lefthand_file = 'icons/mob/inhands/weapons/flamethrower_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/flamethrower_righthand.dmi'
	fire_sound = 'sound/items/modsuit/flamethrower.ogg'
	fire_delay = 2.5 SECONDS
	checks_antimagic = FALSE
	max_charges = INFINITY
	can_charge = FALSE
	no_den_usage = FALSE
	pin = /obj/item/firing_pin
	ammo_type = /obj/item/ammo_casing/magic/mod_flame
	var/obj/item/mod/module/flamethrower/power_module

/obj/item/gun/magic/mod_flamethrower/Destroy()
	power_module = null
	return ..()

/obj/item/gun/magic/mod_flamethrower/can_shoot()
	return power_module?.active && power_module.mod?.is_active() && !power_module.mod.is_activating() && power_module.check_required_modpart() && power_module.check_power(power_module.use_power_cost)

/obj/item/gun/magic/mod_flamethrower/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(!user || user != power_module?.mod?.wearer || !user.is_holding(src) || !can_shoot())
		return FALSE
	if(!power_module.allowed_in_phaseout && istype(user.loc, /obj/effect/dummy/phased_mob))
		return FALSE
	. = ..()
	if(.)
		power_module.drain_power(power_module.use_power_cost)

/obj/item/ammo_casing/magic/mod_flame
	projectile_type = /obj/item/projectile/bullet/mod_flame

/obj/item/projectile/bullet/mod_flame
	damage = 15
	range = 6
	alpha = 0
	pass_flags = PASSTABLE | PASSMOB
	sharpness = SHARP_NONE
	embedding = null
	impact_effect_type = null
	suppressed = SUPPRESSED_VERY
	damage_type = BURN
	flag = BOMB
	pixels_per_second = TILES_TO_PIXELS(8)
	wound_bonus = 30
	bare_wound_bonus = 30
	var/fire_stacks = 3
	shrapnel_type = null
	wound_falloff_tile = -4

/obj/item/projectile/bullet/mod_flame/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/victim = target
		victim.adjust_fire_stacks(fire_stacks)
		victim.IgniteMob()
	var/turf/open/location = get_turf(target)
	if(istype(location))
		new /obj/effect/hotspot(location)
		location.hotspot_expose(MOD_FLAME_TEMPERATURE, MOD_FLAME_VOLUME, TRUE)

/obj/item/mod/module/adrenaline_boost
	name = "MOD adrenaline boost module"
	desc = "Clears incapacitating effects and fatigue with a stimulant injection. Refill with radium."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "adrenaline_boost"
	module_type = MODULE_USABLE
	removable = FALSE
	allowed_incapacitated = TRUE
	incompatible_modules = list(/obj/item/mod/module/adrenaline_boost, /obj/item/mod/module/auto_doc)
	cooldown_time = 12 SECONDS
	var/reagent_required = /datum/reagent/radium
	var/reagent_required_amount = 20
	var/reagent_max_amount = 20

/obj/item/mod/module/adrenaline_boost/Initialize(mapload)
	. = ..()
	create_reagents(reagent_max_amount)
	reagents.add_reagent(reagent_required, reagent_max_amount)

/obj/item/mod/module/adrenaline_boost/on_install()
	. = ..()
	RegisterSignal(mod, COMSIG_PARENT_ATTACKBY, PROC_REF(on_refill))

/obj/item/mod/module/adrenaline_boost/on_uninstall(deleting, user)
	UnregisterSignal(mod, COMSIG_PARENT_ATTACKBY)
	return ..()

/obj/item/mod/module/adrenaline_boost/attackby(obj/item/item, mob/user, params)
	if(!refill(item, user))
		return ..()

/obj/item/mod/module/adrenaline_boost/proc/on_refill(datum/source, obj/item/item, mob/user, params)
	SIGNAL_HANDLER
	return refill(item, user) ? COMPONENT_NO_AFTERATTACK : NONE

/obj/item/mod/module/adrenaline_boost/proc/refill(obj/item/item, mob/user)
	if(!item.is_open_container() || !item.reagents || reagents.total_volume >= reagent_max_amount)
		return FALSE
	if(!item.reagents.trans_id_to(src, reagent_required, reagent_required_amount))
		return FALSE
	balloon_alert(user, "charge reloaded")
	return TRUE

/obj/item/mod/module/adrenaline_boost/on_use()
	if(!reagents.has_reagent(reagent_required, reagent_required_amount) || !..())
		return FALSE
	var/mob/living/carbon/human/user = mod.wearer
	user.SetAllImmobility(0)
	user.adjustStaminaLoss(-MOD_BOOST_STAMINA)
	user.stuttering = 0
	user.reagents.add_reagent(/datum/reagent/medicine/stimulants, MOD_BOOST_STIMULANT)
	var/remainder = reagents.total_volume * (1 - MOD_BOOST_CONSUMPTION)
	reagents.remove_reagent(reagent_required, reagents.total_volume)
	var/list/aftereffects = list()
	aftereffects[reagent_required] = remainder
	user.apply_status_effect(/datum/status_effect/mod_boost_aftereffects, 7 SECONDS, aftereffects)
	return TRUE

/datum/status_effect/mod_boost_aftereffects
	id = "mod_boost_aftereffects"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	var/list/chemicals

/datum/status_effect/mod_boost_aftereffects/on_creation(mob/living/new_owner, effect_duration, list/chemicals)
	duration = effect_duration
	src.chemicals = chemicals.Copy()
	return ..()

/datum/status_effect/mod_boost_aftereffects/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	for(var/reagent in chemicals)
		owner.reagents?.add_reagent(reagent, chemicals[reagent])
	to_chat(owner, span_warning("You are beginning to feel the after-effects of the injection."))

/datum/status_effect/mod_boost_aftereffects/Destroy()
	. = ..()
	chemicals = null

/obj/item/mod/module/auto_doc
	parent_type = /obj/item/mod/module/adrenaline_boost
	name = "MOD automatic paramedical module"
	desc = "Injects damage-specific medical compounds, coagulants and painkillers. Refill with cryptobiolin. Repeated treatments risk overdosing."
	module_type = MODULE_TOGGLE
	removable = TRUE
	allowed_incapacitated = FALSE
	complexity = 4
	use_power_cost = DEFAULT_CHARGE_DRAIN * 20
	cooldown_time = 0
	reagent_required = /datum/reagent/cryptobiolin
	reagent_max_amount = 120
	var/treatment_timer
	COOLDOWN_DECLARE(heal_timer)

/obj/item/mod/module/auto_doc/Destroy()
	deltimer(treatment_timer)
	treatment_timer = null
	return ..()

/obj/item/mod/module/auto_doc/on_activation()
	if(!..())
		return FALSE
	RegisterSignal(mod.wearer, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_health_changed))
	drain_power(use_power_cost)
	return TRUE

/obj/item/mod/module/auto_doc/on_deactivation()
	UnregisterSignal(mod.wearer, COMSIG_CARBON_UPDATEHEALTH)
	deltimer(treatment_timer)
	treatment_timer = null
	return ..()

/obj/item/mod/module/auto_doc/proc/on_health_changed()
	SIGNAL_HANDLER
	if(!treatment_timer && COOLDOWN_FINISHED(src, heal_timer))
		treatment_timer = addtimer(CALLBACK(src, PROC_REF(treat)), 0, TIMER_STOPPABLE)

/obj/item/mod/module/auto_doc/proc/treat()
	deltimer(treatment_timer)
	treatment_timer = null
	var/mob/living/carbon/human/user = mod?.wearer
	if(!active || !user || user.stat == DEAD || user.health > MOD_AUTODOC_THRESHOLD || !COOLDOWN_FINISHED(src, heal_timer))
		return FALSE
	if(istype(user.loc, /obj/effect/dummy/phased_mob))
		return FALSE
	if(!reagents.has_reagent(reagent_required, reagent_required_amount) || !check_power(use_power_cost * MOD_AUTODOC_TREATMENT))
		on_deactivation()
		return FALSE
	COOLDOWN_START(src, heal_timer, 30 SECONDS)
	if(user.getBruteLoss())
		inject_treatment(user, /datum/reagent/medicine/sal_acid)
	if(user.getFireLoss())
		inject_treatment(user, /datum/reagent/medicine/oxandrolone)
	if(user.getToxLoss())
		inject_treatment(user, /datum/reagent/medicine/pen_acid)
	if(user.getStaminaLoss())
		inject_treatment(user, /datum/reagent/medicine/stimulants, MOD_AUTODOC_SALVE)
	user.reagents.add_reagent(/datum/reagent/medicine/coagulant, MOD_AUTODOC_DOSE)
	reagents.remove_reagent(reagent_required, reagent_required_amount)
	drain_power(use_power_cost * MOD_AUTODOC_TREATMENT)
	playsound(user, 'sound/items/modsuit/auto_doc_hiss.ogg', MOD_PANEL_VOLUME, TRUE)
	user.apply_status_effect(/datum/status_effect/mod_boost_aftereffects, 45 SECONDS,
		list(/datum/reagent/cryptobiolin = MOD_AUTODOC_SALVE, /datum/reagent/drug/maint/sludge = MOD_AUTODOC_DOSE))
	return TRUE

/obj/item/mod/module/auto_doc/proc/inject_treatment(mob/living/user, reagent, amount = MOD_AUTODOC_DOSE)
	user.reagents.add_reagent(/datum/reagent/medicine/mine_salve, MOD_AUTODOC_SALVE)
	user.reagents.add_reagent(reagent, amount)
	to_chat(user, span_warning("Treatment administered. Further injections risk overdosing; consult a medical analyzer."))

/datum/reagent/drug/maint/sludge
	name = "Maintenance Sludge"
	description = "Half-refined sludge that increases wound resistance and suppresses pain while poisoning the body."
	color = "#203d2c"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 25

/datum/reagent/drug/maint/sludge/on_mob_metabolize(mob/living/user)
	. = ..()
	ADD_TRAIT(user, TRAIT_HARDLY_WOUNDED, type)
	ADD_TRAIT(user, TRAIT_PAINKILLER, type)

/datum/reagent/drug/maint/sludge/on_mob_end_metabolize(mob/living/user)
	REMOVE_TRAIT(user, TRAIT_HARDLY_WOUNDED, type)
	REMOVE_TRAIT(user, TRAIT_PAINKILLER, type)
	return ..()

/datum/reagent/drug/maint/sludge/on_mob_life(mob/living/carbon/user, delta_time)
	user.adjustToxLoss(MOD_SLUDGE_TOXIN * REM * delta_time)
	return ..()

/datum/reagent/drug/maint/sludge/overdose_process(mob/living/carbon/user, delta_time)
	. = ..()
	user.adjustToxLoss(REM * delta_time)
	if(DT_PROB(MOD_SLUDGE_VOMIT_CHANCE, delta_time))
		user.adjustToxLoss(MOD_SLUDGE_VOMIT_DAMAGE)
		user.vomit()

/obj/item/projectile/bullet/mod_flame/Move()
	. = ..()
	var/turf/location = get_turf(src)
	if(location)
		new /obj/effect/hotspot(location)
		location.hotspot_expose(MOD_FLAME_TEMPERATURE, MOD_FLAME_VOLUME, TRUE)

/obj/item/mod/module/recycler
	name = "MOD recycler module"
	desc = "Recycles loose garbage into raw materials. Select a nearby floor or container to unload. May recycle live ammunition."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "recycler"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	complexity = 2
	incompatible_modules = list(/obj/item/mod/module/recycler)
	mod_module_flags = MOD_MODULE_GENERAL
	var/efficiency = 1
	var/list/allowed_item_types = list(/obj/item/trash, /obj/item/shard, /obj/item/light, /obj/item/broken_bottle, /obj/item/ammo_casing, /obj/item/cigbutt)
	var/list/accepted_materials
	var/datum/component/material_container/container
	var/turf/watched_turf

/obj/item/mod/module/recycler/Initialize(mapload)
	. = ..()
	if(!accepted_materials)
		var/list/material_types = SSmaterials.materialtypes_by_category[MAT_CATEGORY_RIGID]
		accepted_materials = material_types.Copy()
	container = AddComponent(/datum/component/material_container, accepted_materials, MOD_RECYCLER_CAPACITY * MINERAL_MATERIAL_AMOUNT, TRUE, _disable_attackby = TRUE)

/obj/item/mod/module/recycler/Destroy()
	watch_turf(null)
	container = null
	return ..()

/obj/item/mod/module/recycler/on_activation()
	if(!..())
		return FALSE
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	on_move()
	return TRUE

/obj/item/mod/module/recycler/on_deactivation()
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
	watch_turf(null)
	return ..()

/obj/item/mod/module/recycler/proc/watch_turf(turf/next)
	if(watched_turf == next)
		return
	if(watched_turf)
		UnregisterSignal(watched_turf, COMSIG_ATOM_ENTERED)
	watched_turf = next
	if(watched_turf)
		RegisterSignal(watched_turf, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))

/obj/item/mod/module/recycler/proc/on_move()
	SIGNAL_HANDLER
	watch_turf(isturf(mod.wearer.loc) ? mod.wearer.loc : null)
	if(!watched_turf)
		return
	for(var/obj/item/item in watched_turf)
		if(is_type_in_list(item, allowed_item_types))
			recycle(item)

/obj/item/mod/module/recycler/proc/on_entered(datum/source, obj/item/item)
	SIGNAL_HANDLER
	if(istype(item) && is_type_in_list(item, allowed_item_types))
		addtimer(CALLBACK(src, PROC_REF(recycle_nearby), WEAKREF(item)), 0.5 SECONDS)

/obj/item/mod/module/recycler/proc/recycle_nearby(datum/weakref/item_ref)
	var/obj/item/item = item_ref.resolve()
	if(item && active && watched_turf && item.loc == watched_turf)
		recycle(item)

/obj/item/mod/module/recycler/proc/recycle(obj/item/item)
	if(QDELETED(item))
		return FALSE
	var/amount = container.get_item_material_amount(item)
	if(amount && !container.insert_item(item, efficiency))
		return FALSE
	qdel(item)
	playsound(src, 'sound/effects/rustle1.ogg', MOD_SUPPORT_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/recycler/on_select_use(atom/target)
	if(!..() || !mod.wearer.Adjacent(target))
		return FALSE
	var/datum/component/storage/storage = target.GetComponent(/datum/component/storage)
	var/turf/floor = get_turf(target)
	if(!storage && !isopenturf(target))
		return FALSE
	var/list/previous_contents = floor.contents.Copy()
	var/dispensed = dispense(floor)
	if(!dispensed)
		balloon_alert(mod.wearer, "not enough material")
		return FALSE
	if(storage)
		for(var/obj/item/product in floor.contents - previous_contents)
			SEND_SIGNAL(target, COMSIG_TRY_STORAGE_INSERT, product, mod.wearer)
	balloon_alert(mod.wearer, "material dispensed")
	return TRUE

/obj/item/mod/module/recycler/proc/dispense(turf/location)
	return container.retrieve_all(location)

/obj/item/mod/module/recycler/donk
	name = "MOD riot foam dart recycler module"
	desc = "Recycles garbage and spent darts into half-size boxes of riot foam darts."
	icon_state = "donk_recycler"
	efficiency = 0.7
	accepted_materials = list(/datum/material/iron)
	var/ammobox_type = /obj/item/ammo_box/foambox/riot/mini
	var/required_amount = MINERAL_MATERIAL_AMOUNT * 12.5

/obj/item/mod/module/recycler/donk/dispense(turf/location)
	if(!container.use_amount_mat(required_amount, /datum/material/iron))
		return FALSE
	new ammobox_type(location)
	return TRUE

/obj/item/mod/module/recycler/donk/safe
	name = "MOD foam dart recycler module"
	desc = "Recycles spent foam darts into half-size boxes of harmless foam darts."
	icon_state = "donk_safe_recycler"
	complexity = 1
	efficiency = 1
	allowed_item_types = list(/obj/item/ammo_casing/caseless/foam_dart)
	ammobox_type = /obj/item/ammo_box/foambox/mini
	required_amount = 250

/obj/item/ammo_box/foambox/mini
	icon = 'icons/obj/clothing/modsuit/foam_boxes.dmi'
	icon_state = "foambox_mini"
	max_ammo = 20
	custom_materials = list(/datum/material/iron = 250)

/obj/item/ammo_box/foambox/riot/mini
	icon = 'icons/obj/clothing/modsuit/foam_boxes.dmi'
	icon_state = "foambox_riot_mini"
	max_ammo = 20
	custom_materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT * 12.5)

/obj/item/mod/module/energy_net
	name = "MOD energy net module"
	desc = "A hardlight net launcher that immobilizes its target until the net is destroyed or the suit is shut down."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "energy_net"
	removable = FALSE
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 6
	incompatible_modules = list(/obj/item/mod/module/energy_net)
	cooldown_time = 5 SECONDS
	required_modpart_index = MOD_PART_GLOVES
	var/list/energy_nets = list()

/obj/item/mod/module/energy_net/Destroy()
	clear_nets()
	. = ..()
	energy_nets = null

/obj/item/mod/module/energy_net/on_suit_deactivation()
	clear_nets()

/obj/item/mod/module/energy_net/on_uninstall(deleting, user)
	clear_nets()
	return ..()

/obj/item/mod/module/energy_net/on_unequip()
	clear_nets()

/obj/item/mod/module/energy_net/on_select_use(atom/target)
	if(!get_turf(target) || !..())
		return FALSE
	var/obj/item/projectile/mod_net/projectile = new(get_turf(mod.wearer), src)
	projectile.firer = mod.wearer
	projectile.preparePixelProjectile(target, mod.wearer)
	playsound(mod, 'sound/weapons/punchmiss.ogg', MOD_NET_VOLUME, TRUE)
	INVOKE_ASYNC(projectile, TYPE_PROC_REF(/obj/item/projectile, fire))
	drain_power(use_power_cost)
	return TRUE

/obj/item/mod/module/energy_net/proc/add_net(obj/structure/energy_net/net)
	energy_nets += net
	RegisterSignal(net, COMSIG_PARENT_QDELETING, PROC_REF(remove_net))

/obj/item/mod/module/energy_net/proc/remove_net(obj/structure/energy_net/net)
	SIGNAL_HANDLER
	energy_nets -= net
	UnregisterSignal(net, COMSIG_PARENT_QDELETING)

/obj/item/mod/module/energy_net/proc/clear_nets()
	for(var/obj/structure/energy_net/net in energy_nets?.Copy())
		qdel(net)

/obj/item/projectile/mod_net
	name = "energy net"
	icon_state = "net_projectile"
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	damage = 0
	range = 9
	hitsound = 'sound/items/modsuit/net_deploy.ogg'
	var/datum/beam/line
	var/datum/weakref/module_ref

/obj/item/projectile/mod_net/Initialize(mapload, obj/item/mod/module/energy_net/module)
	. = ..()
	module_ref = WEAKREF(module)

/obj/item/projectile/mod_net/Destroy()
	QDEL_NULL(line)
	module_ref = null
	return ..()

/obj/item/projectile/mod_net/fire(setAngle)
	if(firer)
		line = firer.Beam(src, icon = icon, icon_state = "net_beam", time = INFINITY, maxdistance = INFINITY)
	return ..()

/obj/item/projectile/mod_net/on_hit(atom/target, blocked = 0)
	. = ..()
	var/obj/item/mod/module/energy_net/module = module_ref?.resolve()
	if(!isliving(target) || !module?.check_required_modpart())
		return
	var/mob/living/victim = target
	var/turf/location = get_turf(victim)
	if(!location || locate(/obj/structure/energy_net) in location)
		return
	var/obj/structure/energy_net/mod/net = new(location)
	module.add_net(net)
	if(victim.buckled)
		victim.buckled.unbuckle_mob(victim, force = TRUE)
	if(!net.buckle_mob(victim, force = TRUE))
		qdel(net)
		return
	net.affecting = victim
	victim.visible_message(span_danger("[victim] is caught in an energy net!"))

/obj/structure/energy_net/mod
	icon = 'icons/effects/modlink.dmi'

/obj/structure/energy_net/mod/Initialize(mapload)
	. = ..()
	var/mutable_appearance/floor_net = mutable_appearance(icon, "energynet_underlay", BELOW_MOB_LAYER)
	add_overlay(floor_net)

/obj/item/mod/module/night
	name = "MOD night vision module"
	desc = "Встроенный прибор ночного видения, совместимый с другими визорами МОДа."
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "night_visor"
	module_type = MODULE_TOGGLE
	removable = FALSE
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.1
	incompatible_modules = list(/obj/item/mod/module/night, /obj/item/mod/module/visor/night)
	required_modpart_index = MOD_PART_HEAD
	mod_module_flags = MOD_MODULE_VISOR

/obj/item/mod/module/night/on_activation()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(mod.wearer, TRAIT_TRUE_NIGHT_VISION, REF(src))
	mod.wearer.update_sight()

/obj/item/mod/module/night/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	REMOVE_TRAIT(mod.wearer, TRAIT_TRUE_NIGHT_VISION, REF(src))
	mod.wearer.update_sight()

/obj/item/mod/module/magnet
	custom_price = PRICE_EXPENSIVE
	mod_module_flags = MOD_MODULE_SUPPLY
	name = "MOD loader hydraulic magnet module"
	desc = "Электромагнит притягивает шкафы, удерживает их закрытыми и позволяет бросать их."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "magnet_loader"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	incompatible_modules = list(/obj/item/mod/module/magnet)
	cooldown_time = 1.5 SECONDS
	overlay_state_active = "module_magnet"
	use_mod_colors = TRUE
	var/obj/structure/closet/held_locker
	var/mob/living/grip_user
	var/pull_cycle = 0

/obj/item/mod/module/magnet/Destroy()
	release_grip(stop_pull = TRUE)
	return ..()

/obj/item/mod/module/magnet/on_deactivation()
	pull_cycle++
	release_grip(stop_pull = TRUE)
	return ..()

/obj/item/mod/module/magnet/on_uninstall(deleting = FALSE, user)
	pull_cycle++
	release_grip(stop_pull = TRUE)
	return ..()

/obj/item/mod/module/magnet/on_select_use(atom/target)
	if(!get_turf(target) || !..())
		return FALSE
	var/mob/living/user = mod.wearer
	var/obj/structure/closet/locker = user.pulling
	if(istype(locker))
		return throw_locker(locker, target)
	if(!istype(target, /obj/structure/closet) || !(target in view(MOD_MAGNET_RANGE, user)))
		return FALSE
	locker = target
	if(!can_move_locker(locker) || !drain_power(use_power_cost))
		return FALSE
	pull_cycle++
	playsound(locker, 'sound/effects/gravhit.ogg', MOD_MAGNET_VOLUME, TRUE)
	locker.throw_at(user, range = MOD_MAGNET_RANGE, speed = MOD_MAGNET_PULL_SPEED, force = MOVE_FORCE_WEAK, callback = CALLBACK(src, PROC_REF(catch_locker), WEAKREF(locker), WEAKREF(user), pull_cycle))
	return TRUE

/obj/item/mod/module/magnet/proc/can_move_locker(obj/structure/closet/locker)
	return !QDELETED(locker) && isturf(locker.loc) && !locker.anchored && locker.move_resist < MOVE_FORCE_OVERPOWERING

/obj/item/mod/module/magnet/proc/throw_locker(obj/structure/closet/locker, atom/target)
	if(!can_move_locker(locker) || !isturf(mod.wearer.loc) || !drain_power(use_power_cost))
		return FALSE
	var/mob/living/user = mod.wearer
	pull_cycle++
	user.stop_pulling()
	locker.forceMove(user.loc)
	playsound(locker, 'sound/effects/gravhit.ogg', MOD_MAGNET_VOLUME, TRUE)
	locker.throw_at(target, range = MOD_MAGNET_RANGE, speed = MOD_MAGNET_THROW_SPEED, thrower = user)
	return TRUE

/obj/item/mod/module/magnet/proc/catch_locker(datum/weakref/locker_ref, datum/weakref/user_ref, cycle)
	var/obj/structure/closet/locker = locker_ref?.resolve()
	var/mob/living/user = user_ref?.resolve()
	if(cycle != pull_cycle || !user || user != mod?.wearer || !active || !mod.is_active() || mod.is_activating())
		return FALSE
	if(!can_move_locker(locker) || !isturf(user.loc) || !locker.Adjacent(user) || user.incapacitated(ignore_grab = TRUE))
		return FALSE
	release_grip(stop_pull = TRUE)
	if(user.pulling != locker)
		user.start_pulling(locker)
	if(user.pulling != locker)
		return FALSE
	held_locker = locker
	grip_user = user
	ADD_TRAIT(locker, TRAIT_STRONGPULL, REF(src))
	RegisterSignal(user, list(COMSIG_LIVING_STOPPED_PULLING, COMSIG_PARENT_QDELETING), PROC_REF(on_grip_lost))
	RegisterSignal(locker, COMSIG_PARENT_QDELETING, PROC_REF(on_grip_lost))
	return TRUE

/obj/item/mod/module/magnet/proc/on_grip_lost(datum/source)
	SIGNAL_HANDLER
	release_grip()

/obj/item/mod/module/magnet/proc/release_grip(stop_pull = FALSE)
	var/obj/structure/closet/locker = held_locker
	var/mob/living/user = grip_user
	held_locker = null
	grip_user = null
	if(locker)
		REMOVE_TRAIT(locker, TRAIT_STRONGPULL, REF(src))
		UnregisterSignal(locker, COMSIG_PARENT_QDELETING)
	if(!user)
		return
	UnregisterSignal(user, list(COMSIG_LIVING_STOPPED_PULLING, COMSIG_PARENT_QDELETING))
	if(stop_pull && locker && user.pulling == locker)
		user.stop_pulling()

/obj/item/mod/module/hydraulic
	name = "MOD loader hydraulic arms module"
	desc = "Гидравлические приводы разгоняют носителя в выбранном направлении. Дальность зависит от времени подготовки."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "launch_loader"
	module_type = MODULE_ACTIVE
	have_shortcut_activation = TRUE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	cooldown_time = 4 SECONDS
	incompatible_modules = list(/obj/item/mod/module/hydraulic)
	overlay_state_inactive = "module_hydraulic"
	overlay_state_active = "module_hydraulic_active"
	use_mod_colors = TRUE
	var/launch_time = 2 SECONDS
	var/mob/living/launch_user
	var/launch_angle = 0
	var/atom/movable/screen/plane_master/renderer
	var/matrix/render_transform
	var/mutable_appearance/lightning
	var/launch_cycle = 0

/obj/item/mod/module/hydraulic/on_select_use(atom/target)
	if(launch_user || !get_turf(target) || !..())
		return FALSE
	var/mob/living/user = mod.wearer
	begin_launch(user)
	var/cycle = launch_cycle
	var/start_time = world.time
	var/charge_time = launch_time
	if(!do_after(user, launch_time, target = mod))
		charge_time = min(launch_time, world.time - start_time)
	if(cycle != launch_cycle || launch_user != user)
		return FALSE
	clear_charge_effects()
	if(!active || mod?.wearer != user || !mod.is_active() || mod.is_activating() || user.incapacitated(ignore_grab = TRUE) || QDELETED(target) || !isturf(user.loc) || !check_power(use_power_cost))
		finish_launch()
		return FALSE
	var/launch_range = charge_time / (1 SECONDS) * MOD_HYDRAULIC_RANGE_RATE
	if(launch_range < MOD_HYDRAULIC_MIN_SPEED)
		finish_launch()
		return FALSE
	launch_angle = Get_Angle(user, target)
	user.transform = matrix(user.transform).Turn(launch_angle)
	var/turf/destination = get_ranged_target_turf_direct(user, target, launch_range)
	var/launch_speed = max(round(MOD_HYDRAULIC_SPEED_FACTOR * launch_range), MOD_HYDRAULIC_MIN_SPEED)
	playsound(user, 'sound/items/modsuit/loader_launch.ogg', MOD_HYDRAULIC_VOLUME, TRUE)
	if(!user.throw_at(destination, range = launch_range, speed = launch_speed, thrower = user, spin = FALSE, callback = CALLBACK(src, PROC_REF(finish_launch), cycle)))
		finish_launch()
		return FALSE
	drain_power(use_power_cost)
	return TRUE

/obj/item/mod/module/hydraulic/proc/begin_launch(mob/living/user)
	launch_cycle++
	launch_user = user
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	renderer = user.hud_used?.get_plane_master(RENDER_PLANE_GAME)
	if(renderer)
		render_transform = matrix(renderer.transform)
		animate(renderer, launch_time, transform = matrix(render_transform).Scale(MOD_HYDRAULIC_ZOOM))
	lightning = mutable_appearance('icons/effects/effects.dmi', "electricity3", LOW_MOB_LAYER)
	user.add_overlay(lightning)
	playsound(user, 'sound/items/modsuit/loader_charge.ogg', MOD_HYDRAULIC_VOLUME, TRUE)
	mod.balloon_alert(user, "приводы заряжаются...")

/obj/item/mod/module/hydraulic/proc/clear_charge_effects()
	if(renderer && !QDELETED(renderer))
		animate(renderer)
		renderer.transform = render_transform
	renderer = null
	render_transform = null
	if(launch_user && lightning)
		launch_user.cut_overlay(lightning)
	lightning = null

/obj/item/mod/module/hydraulic/proc/finish_launch(cycle)
	if(!isnull(cycle) && cycle != launch_cycle)
		return
	launch_cycle++
	clear_charge_effects()
	if(launch_user)
		UnregisterSignal(launch_user, COMSIG_PARENT_QDELETING)
		launch_user.transform = matrix(launch_user.transform).Turn(-launch_angle)
	launch_user = null
	launch_angle = 0

/obj/item/mod/module/hydraulic/proc/on_user_deleted(datum/source)
	SIGNAL_HANDLER
	finish_launch()

/obj/item/mod/module/hydraulic/on_deactivation()
	finish_launch()
	return ..()

/obj/item/mod/module/hydraulic/on_uninstall(deleting = FALSE, user)
	finish_launch()
	return ..()

/obj/item/mod/module/hydraulic/Destroy()
	finish_launch()
	return ..()

/obj/item/mod/module/selfcleaner
	mod_module_flags = MOD_MODULE_GENERAL
	icon = 'icons/obj/clothing/modsuit/mod_modules_nova.dmi'
	name = "MOD perfumer module"
	desc = "Встроенный распылитель смывает грязь с носителя и его наружной одежды."
	icon_state = "cleaner"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 10 SECONDS
	incompatible_modules = list(/obj/item/mod/module/selfcleaner)

/obj/item/mod/module/selfcleaner/on_use()
	if(!..())
		return FALSE
	var/datum/reagent/space_cleaner/gentle/cleaner = new
	cleaner.reaction_mob(mod.wearer, TOUCH, MOD_PERFUMER_DOSE)
	qdel(cleaner)
	playsound(mod.wearer, 'sound/effects/spray.ogg', MOD_PERFUMER_VOLUME, FALSE)
	drain_power(use_power_cost)
	return TRUE

/obj/item/mod/module/jaeger_sprint
	name = "MOD jaeger sprint module"
	desc = "Дополнительное питание и охлаждение сервоприводов ног уменьшают замедление ценой повышенного расхода энергии."
	icon = 'icons/obj/clothing/modsuit/mod_jaeger.dmi'
	icon_state = "sprint"
	module_type = MODULE_TOGGLE
	required_modpart_index = MOD_PART_FEET
	active_power_cost = DEFAULT_CHARGE_DRAIN * 2
	incompatible_modules = list(/obj/item/mod/module/jaeger_sprint)

/obj/item/mod/module/jaeger_sprint/on_activation()
	. = ..()
	if(.)
		mod.update_speed()

/obj/item/mod/module/jaeger_sprint/on_deactivation()
	. = ..()
	mod.update_speed()

/obj/item/mod/module/jaeger_sprint/get_slowdown()
	return active && mod?.is_active() && check_required_modpart() ? MOD_JAEGER_SLOWDOWN : 0

/obj/item/mod/module/baton_holster
	name = "MOD baton holster module"
	desc = "Выдвижная кобура для дубинки контрактника. Вставьте дубинку в снятый модуль. Для извлечения достаточно развёрнутых перчаток и заряда MOD; включать костюм не требуется."
	icon = 'icons/obj/clothing/modsuit/contractor_modules.dmi'
	icon_state = "holster"
	module_type = MODULE_ACTIVE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN * 0.3
	cooldown_time = 0.5 SECONDS
	allowed_inactive = TRUE
	required_modpart_index = MOD_PART_GLOVES
	incompatible_modules = list(/obj/item/mod/module/baton_holster)

/obj/item/mod/module/baton_holster/Initialize(mapload)
	. = ..()
	if(device)
		RegisterSignal(device, COMSIG_PARENT_QDELETING, PROC_REF(on_baton_deleted))

/obj/item/mod/module/baton_holster/attackby(obj/item/item, mob/user, params)
	if(!istype(item, /obj/item/melee/classic_baton/telescopic/contractor_baton))
		return ..()
	if(mod || device)
		balloon_alert(user, mod ? "сначала снимите модуль" : "дубинка уже вставлена")
		return
	if(!user.transferItemToLoc(item, src))
		return
	device = item
	RegisterSignal(device, COMSIG_PARENT_QDELETING, PROC_REF(on_baton_deleted))
	balloon_alert(user, "дубинка вставлена")

/obj/item/mod/module/baton_holster/on_activation()
	if(!device)
		mod?.balloon_alert(mod.wearer, "сначала вставьте дубинку")
		return FALSE
	. = ..()
	if(.)
		START_PROCESSING(SSobj, src)

/obj/item/mod/module/baton_holster/on_deactivation()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mod/module/baton_holster/process(delta_time)
	if(!active || !mod?.wearer)
		on_deactivation()
		return PROCESS_KILL
	if(!mod.is_active())
		on_process(delta_time)

/obj/item/mod/module/baton_holster/proc/on_baton_deleted(datum/source)
	SIGNAL_HANDLER
	if(active)
		on_deactivation()
	QDEL_NULL(my_retract_component)
	device = null

/obj/item/mod/module/baton_holster/on_uninstall(deleting = FALSE, user)
	. = ..()
	if(!QDELING(src) && !loc)
		forceMove(mod.drop_location())

/obj/item/mod/module/baton_holster/Destroy()
	STOP_PROCESSING(SSobj, src)
	var/atom/destination = mod?.drop_location() || drop_location()
	if(active)
		on_deactivation()
	QDEL_NULL(my_retract_component)
	if(device)
		UnregisterSignal(device, COMSIG_PARENT_QDELETING)
		device.forceMove(destination)
		device = null
	return ..()

/obj/item/mod/module/baton_holster/preloaded
	device = /obj/item/melee/classic_baton/telescopic/contractor_baton

/obj/item/mod/module/baton_holster/check_required_modpart()
	return mod?.wearer && required_modpart && mod.wearer.get_item_by_slot(required_modpart.slot_flags) == required_modpart

/obj/item/mod/module/ash_accretion
	name = "MOD ash accretion module"
	desc = "Собирает защитный слой пепла при движении по грунту. Полное покрытие ускоряет носителя; на обычном полу пепел постепенно осыпается. Защита действует только при полном развёртывании включённого MOD."
	icon_state = "ash_accretion"
	need_full_deploy = TRUE
	incompatible_modules = list(/obj/item/mod/module/ash_accretion)
	use_mod_colors = TRUE
	var/layers = 0
	var/mob/living/carbon/human/ash_user
	var/static/list/accretion_turfs = typecacheof(list(/turf/open/floor/plating/asteroid, /turf/open/floor/plating/ashplanet, /turf/open/floor/plating/dirt))
	var/static/list/keep_turfs = typecacheof(list(/turf/open/floor/grass, /turf/open/floor/plating/snowed, /turf/open/floor/plating/ironsand, /turf/open/floor/plating/ice, /turf/open/indestructible/hierophant, /turf/open/indestructible/boss, /turf/open/indestructible/necropolis, /turf/open/lava, /turf/open/water))

/obj/item/mod/module/ash_accretion/on_equip()
	if(ash_user == mod.wearer)
		return
	on_unequip()
	ash_user = mod.wearer
	RegisterSignal(ash_user, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(ash_user, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM), PROC_REF(on_inventory_change))
	RegisterSignal(ash_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	refresh_protection()

/obj/item/mod/module/ash_accretion/on_unequip()
	clear_protection()
	UnregisterSignal(ash_user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM, COMSIG_PARENT_QDELETING))
	ash_user = null

/obj/item/mod/module/ash_accretion/on_uninstall(deleting = FALSE, user)
	on_unequip()
	return ..()

/obj/item/mod/module/ash_accretion/Destroy()
	on_unequip()
	return ..()

/obj/item/mod/module/ash_accretion/on_suit_activation()
	refresh_protection()

/obj/item/mod/module/ash_accretion/on_suit_deactivation()
	clear_protection()

/obj/item/mod/module/ash_accretion/proc/is_ready()
	return ash_user && mod?.wearer == ash_user && mod.is_active() && mod.all_parts_deployed()

/obj/item/mod/module/ash_accretion/proc/refresh_protection()
	if(!is_ready())
		clear_protection()
		return
	ADD_TRAIT(ash_user, TRAIT_ASHSTORM_IMMUNE, REF(src))
	ADD_TRAIT(ash_user, TRAIT_SNOWSTORM_IMMUNE, REF(src))

/obj/item/mod/module/ash_accretion/proc/clear_protection()
	if(ash_user)
		REMOVE_TRAIT(ash_user, TRAIT_ASHSTORM_IMMUNE, REF(src))
		REMOVE_TRAIT(ash_user, TRAIT_SNOWSTORM_IMMUNE, REF(src))
	set_layers(0)

/obj/item/mod/module/ash_accretion/proc/on_inventory_change(mob/source, obj/item/item)
	SIGNAL_HANDLER
	if(mod?.is_mod_part(item))
		refresh_protection()

/obj/item/mod/module/ash_accretion/proc/on_user_deleted(datum/source)
	SIGNAL_HANDLER
	on_unequip()

/obj/item/mod/module/ash_accretion/proc/on_move(mob/source)
	SIGNAL_HANDLER
	if(!is_ready())
		clear_protection()
		return
	if(!isturf(ash_user.loc))
		return
	if(is_type_in_typecache(ash_user.loc, accretion_turfs))
		set_layers(layers + 1)
		return
	if(is_type_in_typecache(ash_user.loc, keep_turfs) || !layers)
		return
	new /obj/effect/temp_visual/mod_light_ash(get_turf(ash_user))
	set_layers(layers - 1)

/obj/item/mod/module/ash_accretion/proc/set_layers(amount)
	amount = clamp(amount, 0, MOD_ASH_MAX_LAYERS)
	var/difference = amount - layers
	if(!difference || !mod)
		return
	layers = amount
	for(var/obj/item/part as anything in mod.get_mod_parts(include_cell = FALSE, include_mod = TRUE))
		if(QDELETED(part))
			continue
		part.set_armor(part.get_armor().modifyRating(melee = MOD_ASH_MELEE * difference, bullet = MOD_ASH_BULLET * difference, laser = MOD_ASH_LASER * difference, energy = MOD_ASH_ENERGY * difference, bomb = MOD_ASH_BOMB * difference))
	mod.update_speed()
	if(layers == MOD_ASH_MAX_LAYERS)
		mod.balloon_alert(ash_user, "полное покрытие пеплом")
		do_sparks(MOD_ASH_SPARKS, FALSE, ash_user)
		playsound(ash_user, 'sound/effects/sparks1.ogg', MOD_ASH_VOLUME, TRUE)
	else if(!layers && is_ready())
		mod.balloon_alert(ash_user, "пепел осыпался")

/obj/item/mod/module/ash_accretion/get_slowdown()
	return layers == MOD_ASH_MAX_LAYERS && is_ready() ? MOD_ASH_SLOWDOWN : 0

/obj/item/mod/module/ash_accretion/generate_worn_overlay()
	if(!is_ready())
		return list()
	overlay_state_inactive = mod.skin == "asteroid" ? "module_ash-asteroid" : "module_ash-mining"
	return ..()

/obj/effect/temp_visual/mod_light_ash
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "light_ash"
	duration = 3.2 SECONDS

/obj/item/mod/module/active_sonar
	mod_module_flags = MOD_MODULE_SECURITY
	name = "MOD active sonar"
	desc = "Сонар постепенно сканирует пространство вокруг носителя. При использовании посылает громкий импульс, показывающий всех живых существ поблизости."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "active_sonar"
	module_type = MODULE_USABLE
	complexity = 2
	idle_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	use_power_cost = DEFAULT_CHARGE_DRAIN * 3
	cooldown_time = 15 SECONDS
	required_modpart_index = MOD_PART_HEAD
	incompatible_modules = list(/obj/item/mod/module/active_sonar)
	var/scanned_slice = 1
	var/charge_time = 1.1 SECONDS
	var/list/pings = list()
	COOLDOWN_DECLARE(scan_cooldown)

/obj/item/mod/module/active_sonar/on_suit_activation()
	START_PROCESSING(SSfastprocess, src)

/obj/item/mod/module/active_sonar/on_suit_deactivation()
	stop_scanning()

/obj/item/mod/module/active_sonar/on_unequip()
	stop_scanning()

/obj/item/mod/module/active_sonar/on_uninstall(deleting = FALSE, user)
	stop_scanning()
	return ..()

/obj/item/mod/module/active_sonar/Destroy()
	stop_scanning()
	return ..()

/obj/item/mod/module/active_sonar/proc/is_ready()
	return mod?.wearer && mod.is_active() && !mod.is_activating() && check_required_modpart()

/obj/item/mod/module/active_sonar/process()
	if(!is_ready())
		clear_pings()
		return
	if(!COOLDOWN_FINISHED(src, cooldown_current_timer) || !COOLDOWN_FINISHED(src, scan_cooldown))
		return
	scan_creatures(scanned_slice)
	scanned_slice = scanned_slice % MOD_SONAR_SLICES + 1
	COOLDOWN_START(src, scan_cooldown, 0.5 SECONDS)

/obj/item/mod/module/active_sonar/proc/get_creatures()
	. = list()
	if(!is_ready())
		return
	for(var/mob/living/creature in range(world.view, mod.wearer))
		if(creature != mod.wearer && creature.stat != DEAD)
			. += creature

/obj/item/mod/module/active_sonar/proc/scan_creatures(slice)
	var/detected = 0
	for(var/mob/living/creature as anything in get_creatures())
		var/target_slice = round(SIMPLIFY_DEGREES(Get_Angle(mod.wearer, creature)) / (MOD_SONAR_DEGREES / MOD_SONAR_SLICES)) + 1
		if(slice && target_slice != slice)
			continue
		var/obj/effect/temp_visual/mod_sonar_ping/ping = new(get_turf(mod.wearer), mod.wearer, creature, !slice)
		if(QDELETED(ping))
			continue
		pings += ping
		RegisterSignal(ping, COMSIG_PARENT_QDELETING, PROC_REF(on_ping_deleted))
		detected++
	return detected

/obj/item/mod/module/active_sonar/proc/on_ping_deleted(datum/source)
	SIGNAL_HANDLER
	pings -= source

/obj/item/mod/module/active_sonar/proc/clear_pings()
	for(var/obj/effect/temp_visual/mod_sonar_ping/ping as anything in pings.Copy())
		qdel(ping)

/obj/item/mod/module/active_sonar/proc/stop_scanning()
	STOP_PROCESSING(SSfastprocess, src)
	clear_pings()
	scanned_slice = 1

/obj/item/mod/module/active_sonar/on_use()
	if(!is_ready() || !..())
		return FALSE
	var/obj/item/mod/control/suit = mod
	var/mob/living/carbon/human/user = suit.wearer
	suit.balloon_alert(user, "зарядка сонара...")
	playsound(user, 'sound/mecha/skyfall_power_up.ogg', MOD_SONAR_CHARGE_VOLUME, TRUE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	if(!do_after(user, charge_time, target = suit))
		return FALSE
	if(QDELETED(src) || mod != suit || suit.wearer != user || !is_ready() || !drain_power(use_power_cost))
		return FALSE
	playsound(user, 'sound/effects/ping.ogg', MOD_SONAR_PING_VOLUME, TRUE)
	var/detected = scan_creatures()
	to_chat(user, span_notice("Импульс сонара обнаружил живых существ поблизости: [detected]."))
	return TRUE

/obj/effect/temp_visual/mod_sonar_ping
	icon = 'icons/obj/clothing/modsuit/sonar_effects.dmi'
	duration = 3 SECONDS
	randomdir = FALSE
	var/image/ping_image
	var/client/viewer
	var/datum/weakref/user_ref
	var/datum/weakref/target_ref
	var/turf/ping_turf
	var/follow_target

/obj/effect/temp_visual/mod_sonar_ping/Initialize(mapload, mob/living/user, mob/living/target, follow = TRUE)
	. = ..()
	if(!user || !target)
		return INITIALIZE_HINT_QDEL
	user_ref = WEAKREF(user)
	target_ref = WEAKREF(target)
	follow_target = follow
	ping_turf = get_turf(target)
	viewer = user.client
	ping_image = image(icon, get_turf(user), follow ? "sonar_ping" : "sonar_ping_small", ABOVE_ALL_MOB_LAYER)
	ping_image.plane = ABOVE_LIGHTING_PLANE
	if(ishuman(target))
		ping_image.color = COLOR_SOFT_RED
	if(!update_ping())
		return INITIALIZE_HINT_QDEL
	viewer?.images += ping_image
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(user, list(COMSIG_MOB_LOGOUT, COMSIG_PARENT_QDELETING), PROC_REF(end_ping))
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(end_ping))
	if(follow_target)
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

/obj/effect/temp_visual/mod_sonar_ping/proc/on_move(datum/source)
	SIGNAL_HANDLER
	update_ping()

/obj/effect/temp_visual/mod_sonar_ping/proc/update_ping()
	var/mob/living/user = user_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	var/turf/user_turf = get_turf(user)
	if(follow_target)
		ping_turf = get_turf(target)
	if(!user_turf || !ping_turf || user_turf.z != ping_turf.z)
		qdel(src)
		return FALSE
	ping_image.loc = user_turf
	ping_image.pixel_x = (ping_turf.x - user_turf.x) * world.icon_size
	ping_image.pixel_y = (ping_turf.y - user_turf.y) * world.icon_size
	return TRUE

/obj/effect/temp_visual/mod_sonar_ping/proc/end_ping(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/temp_visual/mod_sonar_ping/Destroy()
	var/mob/living/user = user_ref?.resolve()
	var/mob/living/target = target_ref?.resolve()
	if(user)
		UnregisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_LOGOUT, COMSIG_PARENT_QDELETING))
	if(target)
		UnregisterSignal(target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	viewer?.images -= ping_image
	viewer = null
	user_ref = null
	target_ref = null
	ping_turf = null
	QDEL_NULL(ping_image)
	return ..()

/obj/item/mod/module/shove_blocker
	name = "MOD bulwark module"
	custom_price = PRICE_REALLY_EXPENSIVE
	desc = "Амортизирующие пластины защищают от толчков, потери равновесия и отбрасывания брошенными предметами."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "bulwark"
	complexity = 3
	required_modpart_index = MOD_PART_CHEST
	incompatible_modules = list(/obj/item/mod/module/shove_blocker)
	var/mob/living/carbon/human/protected_user

/obj/item/mod/module/shove_blocker/on_suit_activation()
	clear_protection()
	if(!check_required_modpart())
		return
	protected_user = mod.wearer
	ADD_TRAIT(protected_user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))
	ADD_TRAIT(protected_user, TRAIT_NO_THROW_HITPUSH, REF(src))
	RegisterSignal(protected_user, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(block_stagger))

/obj/item/mod/module/shove_blocker/on_suit_deactivation()
	clear_protection()

/obj/item/mod/module/shove_blocker/on_unequip()
	clear_protection()

/obj/item/mod/module/shove_blocker/on_uninstall(deleting = FALSE, user)
	clear_protection()
	return ..()

/obj/item/mod/module/shove_blocker/Destroy()
	clear_protection()
	return ..()

/obj/item/mod/module/shove_blocker/proc/clear_protection()
	if(!protected_user)
		return
	REMOVE_TRAIT(protected_user, TRAIT_BRAWLING_KNOCKDOWN_BLOCKED, REF(src))
	REMOVE_TRAIT(protected_user, TRAIT_NO_THROW_HITPUSH, REF(src))
	UnregisterSignal(protected_user, COMSIG_LIVING_STATUS_STAGGER)
	protected_user = null

/obj/item/mod/module/shove_blocker/proc/block_stagger(mob/source, amount, updating, ignore_canstun)
	SIGNAL_HANDLER
	if(amount > 0 && !ignore_canstun)
		return COMPONENT_NO_STUN

/obj/item/mod/module/shove_blocker/locked
	name = "superglued MOD bulwark module"
	removable = FALSE
	complexity = 0

/obj/item/mod/module/pepper_shoulders
	custom_price = PRICE_ALMOST_EXPENSIVE
	name = "MOD pepper shoulders module"
	desc = "Плечевые распылители выпускают облако перцового аэрозоля при атаке на носителя или по его команде."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "pepper_shoulder"
	overlay_state_inactive = "module_pepper"
	overlay_state_use = "module_pepper_used"
	module_type = MODULE_USABLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN
	cooldown_time = 5 SECONDS
	required_modpart_index = MOD_PART_CHEST
	incompatible_modules = list(/obj/item/mod/module/pepper_shoulders)
	var/mob/living/carbon/human/pepper_user

/obj/item/mod/module/pepper_shoulders/on_equip()
	on_unequip()
	pepper_user = mod.wearer
	RegisterSignal(pepper_user, COMSIG_LIVING_RUN_BLOCK, PROC_REF(on_attack))

/obj/item/mod/module/pepper_shoulders/on_unequip()
	UnregisterSignal(pepper_user, COMSIG_LIVING_RUN_BLOCK)
	pepper_user = null

/obj/item/mod/module/pepper_shoulders/on_uninstall(deleting = FALSE, user)
	on_unequip()
	return ..()

/obj/item/mod/module/pepper_shoulders/Destroy()
	on_unequip()
	return ..()

/obj/item/mod/module/pepper_shoulders/proc/on_attack(mob/source, real_attack)
	SIGNAL_HANDLER
	if(real_attack)
		INVOKE_ASYNC(src, PROC_REF(on_use))
	return NONE

/obj/item/mod/module/pepper_shoulders/on_use()
	if(!mod?.wearer || !mod.is_active() || mod.is_activating() || !check_required_modpart() || !..())
		return FALSE
	if(!drain_power(use_power_cost))
		return FALSE
	var/datum/reagents/pepper = new(MOD_PEPPER_DOSE)
	pepper.add_reagent(/datum/reagent/consumable/condensedcapsaicin, MOD_PEPPER_DOSE)
	var/datum/effect_system/smoke_spread/chem/smoke = new()
	smoke.set_up(pepper, MOD_PEPPER_RADIUS, get_turf(mod.wearer))
	smoke.start()
	qdel(pepper)
	playsound(mod.wearer, 'sound/effects/spray.ogg', MOD_PEPPER_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	return TRUE

/obj/item/mod/module/pepper_shoulders/security
	complexity = 0

/obj/item/mod/module/hat_stabilizer
	name = "MOD hat stabilizer module"
	desc = "Держатель позволяет надевать шляпу поверх шлема MOD. При отключении крепления шляпа держится свободно и может упасть."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "hat_holder"
	required_modpart_index = MOD_PART_HEAD
	incompatible_modules = list(/obj/item/mod/module/hat_stabilizer)
	var/obj/item/clothing/head/attached_hat
	var/mob/living/carbon/human/hat_user
	var/added_cover = NONE
	var/added_visor_cover = NONE
	var/tilt_direction = 1

/obj/item/mod/module/hat_stabilizer/on_install()
	. = ..()
	RegisterSignal(required_modpart, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(required_modpart, COMSIG_CLICK_ALT, PROC_REF(on_alt_click))
	RegisterSignal(required_modpart, COMSIG_ITEM_WORN_OVERLAYS, PROC_REF(on_worn_overlays))
	RegisterSignal(required_modpart, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_update_overlays))
	RegisterSignal(required_modpart, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/obj/item/mod/module/hat_stabilizer/on_uninstall(deleting = FALSE, user)
	on_unequip()
	remove_hat_to_hands(user)
	UnregisterSignal(required_modpart, list(COMSIG_PARENT_ATTACKBY, COMSIG_CLICK_ALT, COMSIG_ITEM_WORN_OVERLAYS, COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_PARENT_EXAMINE))
	return ..()

/obj/item/mod/module/hat_stabilizer/on_equip()
	on_unequip()
	hat_user = mod.wearer
	RegisterSignal(hat_user, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(on_fall))
	RegisterSignal(hat_user, COMSIG_MOVABLE_POST_THROW, PROC_REF(on_throw))

/obj/item/mod/module/hat_stabilizer/on_unequip()
	UnregisterSignal(hat_user, list(COMSIG_LIVING_SET_BODY_POSITION, COMSIG_MOVABLE_POST_THROW))
	hat_user = null

/obj/item/mod/module/hat_stabilizer/on_suit_activation()
	update_hat()

/obj/item/mod/module/hat_stabilizer/on_suit_deactivation()
	update_hat()

/obj/item/mod/module/hat_stabilizer/Destroy()
	on_unequip()
	remove_hat()
	return ..()

/obj/item/mod/module/hat_stabilizer/proc/on_attackby(datum/source, obj/item/item, mob/user)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/clothing/head))
		return
	attach_hat(item, user)
	return COMPONENT_NO_AFTERATTACK

/obj/item/mod/module/hat_stabilizer/proc/attach_hat(obj/item/clothing/head/hat, mob/user)
	if(attached_hat || !required_modpart || !istype(hat) || hat.clothing_flags & PLASMAMAN_HELMET_EXEMPT)
		return FALSE
	if(!user.transferItemToLoc(hat, required_modpart))
		return FALSE
	attached_hat = hat
	added_cover = hat.flags_cover & ~required_modpart.flags_cover
	added_visor_cover = hat.visor_flags_cover & ~required_modpart.visor_flags_cover
	required_modpart.flags_cover |= added_cover
	required_modpart.visor_flags_cover |= added_visor_cover
	tilt_direction = pick(-1, 1)
	RegisterSignal(hat, COMSIG_MOVABLE_MOVED, PROC_REF(on_hat_moved))
	RegisterSignal(hat, COMSIG_PARENT_QDELETING, PROC_REF(on_hat_deleted))
	update_hat()
	return TRUE

/obj/item/mod/module/hat_stabilizer/proc/remove_hat()
	var/obj/item/clothing/head/hat = attached_hat
	if(!hat)
		return
	UnregisterSignal(hat, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	attached_hat = null
	if(required_modpart)
		required_modpart.visor_flags_cover &= ~added_visor_cover
		var/sealed_cover = check_required_modpart() ? required_modpart.visor_flags_cover : NONE
		required_modpart.flags_cover &= ~(added_cover & ~sealed_cover)
	added_cover = NONE
	added_visor_cover = NONE
	if(!QDELETED(hat) && hat.loc == required_modpart)
		hat.forceMove(mod?.drop_location() || drop_location())
	update_hat()
	return hat

/obj/item/mod/module/hat_stabilizer/proc/remove_hat_to_hands(mob/user)
	var/obj/item/clothing/head/hat = remove_hat()
	if(!QDELETED(hat) && !QDELETED(user))
		user.put_in_hands(hat)

/obj/item/mod/module/hat_stabilizer/proc/update_hat()
	if(attached_hat && required_modpart)
		added_cover |= attached_hat.flags_cover & ~required_modpart.flags_cover
		required_modpart.flags_cover |= attached_hat.flags_cover
	required_modpart?.update_appearance()
	if(mod?.wearer?.head == required_modpart)
		mod.wearer.update_inv_head()

/obj/item/mod/module/hat_stabilizer/proc/on_alt_click(datum/source, mob/user)
	SIGNAL_HANDLER
	if(attached_hat && user.canUseTopic(required_modpart, BE_CLOSE))
		INVOKE_ASYNC(src, PROC_REF(remove_hat_to_hands), user)

/obj/item/mod/module/hat_stabilizer/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(attached_hat)
		examine_list += span_notice("На шлеме закреплена [attached_hat]. Alt+Click, чтобы снять.")

/obj/item/mod/module/hat_stabilizer/proc/on_worn_overlays(datum/source, isinhands, icon_file, used_state, style_flags, list/overlays)
	SIGNAL_HANDLER
	if(isinhands || !attached_hat)
		return
	var/mutable_appearance/hat = attached_hat.build_worn_icon(default_layer = HEAD_LAYER, default_icon_file = 'icons/mob/clothing/head.dmi', override_state = attached_hat.icon_state)
	hat.appearance_flags |= RESET_COLOR
	if(!check_required_modpart())
		var/matrix/tilt = matrix(hat.transform)
		tilt.Turn(MOD_HAT_TILT * tilt_direction)
		hat.transform = tilt
	overlays += hat

/obj/item/mod/module/hat_stabilizer/proc/on_update_overlays(datum/source, list/overlays)
	SIGNAL_HANDLER
	if(attached_hat)
		overlays += mutable_appearance(attached_hat.icon, attached_hat.icon_state)

/obj/item/mod/module/hat_stabilizer/proc/on_hat_moved(datum/source)
	SIGNAL_HANDLER
	remove_hat()

/obj/item/mod/module/hat_stabilizer/proc/on_hat_deleted(datum/source)
	SIGNAL_HANDLER
	remove_hat()

/obj/item/mod/module/hat_stabilizer/proc/on_fall(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	if(source.head == required_modpart && source.body_position == LYING_DOWN && !check_required_modpart())
		remove_hat()

/obj/item/mod/module/hat_stabilizer/proc/on_throw(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	if(source.head != required_modpart || check_required_modpart())
		return
	var/obj/item/clothing/head/hat = remove_hat()
	hat?.throw_at(get_edge_target_turf(get_turf(source), pick(GLOB.alldirs)), MOD_HAT_THROW_RANGE, MOD_HAT_THROW_SPEED)

/obj/item/mod/module/hat_stabilizer/syndicate
	name = "MOD elite hat stabilizer module"
	complexity = 0
	removable = FALSE

/obj/item/mod/module/criminalcapture
	mod_module_flags = MOD_MODULE_SECURITY
	name = "MOD criminal capture module"
	desc = "Создаёт голографический мешок с пригодной для дыхания атмосферой для перевозки заключённых. Мешок рассеивается при отключении питания или удалении от носителя."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "criminal_capture"
	module_type = MODULE_ACTIVE
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	cooldown_time = 0.5 SECONDS
	have_shortcut_activation = TRUE
	incompatible_modules = list(/obj/item/mod/module/criminalcapture)
	var/capture_time = 2.5 SECONDS
	var/packup_time = 1 SECONDS
	var/bodybag_type = /obj/structure/closet/body_bag/containment/prisoner/mod_hardlight
	var/obj/structure/closet/body_bag/linked_bodybag
	var/mob/living/carbon/human/bag_user
	var/capturing = FALSE
	var/capture_cycle = 0

/obj/item/mod/module/criminalcapture/on_select_use(atom/target)
	if(capturing || !get_turf(target) || !..() || !mod.wearer.Adjacent(target))
		return FALSE
	var/obj/item/mod/control/suit = mod
	var/mob/living/carbon/human/user = suit.wearer
	var/packing = target == linked_bodybag
	if(linked_bodybag && !packing)
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!packing && target_turf.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	capturing = TRUE
	var/cycle = capture_cycle
	var/ready = do_after(user, packing ? packup_time : capture_time, target)
	capturing = FALSE
	if(!ready || QDELETED(src) || cycle != capture_cycle || mod != suit || suit.wearer != user || !active || suit.selected_module != src || !suit.is_active() || suit.is_activating() || QDELETED(target) || !user.Adjacent(target))
		return FALSE
	if(packing)
		if(target != linked_bodybag)
			return FALSE
		packup()
		return TRUE
	if(linked_bodybag || get_turf(target) != target_turf || target_turf.is_blocked_turf(exclude_mobs = TRUE) || !drain_power(use_power_cost))
		return FALSE
	if(create_bag(user, target_turf, target))
		return TRUE
	suit.core?.add_charge(use_power_cost)
	balloon_alert(user, "цель не помещается в мешок")
	return FALSE

/obj/item/mod/module/criminalcapture/proc/create_bag(mob/living/carbon/human/user, turf/target_turf, atom/target)
	linked_bodybag = new bodybag_type(target_turf)
	if(isliving(target) && target.loc != linked_bodybag && !linked_bodybag.insert(target))
		QDEL_NULL(linked_bodybag)
		return FALSE
	linked_bodybag.take_contents()
	active_power_cost = DEFAULT_CHARGE_DRAIN * MOD_CAPTURE_UPKEEP
	bag_user = user
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(check_range))
	RegisterSignal(linked_bodybag, COMSIG_MOVABLE_MOVED, PROC_REF(check_range))
	RegisterSignal(linked_bodybag, COMSIG_PARENT_QDELETING, PROC_REF(on_bag_deleted))
	playsound(linked_bodybag, 'sound/weapons/egloves.ogg', MOD_CAPTURE_VOLUME, TRUE)
	return TRUE

/obj/item/mod/module/criminalcapture/on_process(delta_time)
	active_power_cost = linked_bodybag ? DEFAULT_CHARGE_DRAIN * MOD_CAPTURE_UPKEEP : 0
	return ..()

/obj/item/mod/module/criminalcapture/on_deactivation()
	packup()
	return ..()

/obj/item/mod/module/criminalcapture/on_unequip()
	packup()

/obj/item/mod/module/criminalcapture/on_uninstall(deleting = FALSE, user)
	packup()
	return ..()

/obj/item/mod/module/criminalcapture/Destroy()
	packup()
	return ..()

/obj/item/mod/module/criminalcapture/proc/check_range()
	SIGNAL_HANDLER
	if(!bag_user || !linked_bodybag)
		return
	var/turf/user_turf = get_turf(bag_user)
	var/turf/bag_turf = get_turf(linked_bodybag)
	if(!user_turf || !bag_turf || user_turf.z != bag_turf.z || get_dist(user_turf, bag_turf) > MOD_CAPTURE_RANGE)
		packup()

/obj/item/mod/module/criminalcapture/proc/unlink_bag()
	UnregisterSignal(bag_user, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(linked_bodybag, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	bag_user = null
	linked_bodybag = null
	active_power_cost = 0

/obj/item/mod/module/criminalcapture/proc/on_bag_deleted(datum/source)
	SIGNAL_HANDLER
	unlink_bag()

/obj/item/mod/module/criminalcapture/proc/packup()
	capture_cycle++
	var/obj/structure/closet/body_bag/bag = linked_bodybag
	unlink_bag()
	if(QDELETED(bag))
		return
	bag.open(force = TRUE)
	playsound(bag, 'sound/weapons/egloves.ogg', MOD_CAPTURE_VOLUME, TRUE)
	animate(bag, alpha = MOD_CAPTURE_FADE_ALPHA, time = 0.5 SECONDS)
	QDEL_IN(bag, 0.5 SECONDS)

/obj/item/mod/module/criminalcapture/patienttransport
	mod_module_flags = MOD_MODULE_MEDICAL
	name = "MOD patient transport module"
	desc = "Создаёт голографический мешок с пригодной для дыхания атмосферой для перевозки пациентов."
	icon_state = "patient_transport"
	bodybag_type = /obj/structure/closet/body_bag/containment/mod_hardlight
	capture_time = 1.5 SECONDS
	packup_time = 0.5 SECONDS

/obj/structure/closet/body_bag/containment/proc/create_mod_air()
	if(!air_contents)
		air_contents = new(MOD_CAPTURE_AIR_VOLUME)
	else
		air_contents.clear()
	air_contents.set_temperature(T20C)
	var/moles = (ONE_ATMOSPHERE * MOD_CAPTURE_AIR_VOLUME) / (R_IDEAL_GAS_EQUATION * T20C)
	air_contents.set_moles(GAS_O2, moles * O2STANDARD)
	air_contents.set_moles(GAS_N2, moles * N2STANDARD)

/obj/structure/closet/body_bag/containment/mod_hardlight
	name = "голографический транспортный мешок"
	desc = "Голографический мешок для безопасной перевозки пациентов."
	icon = 'icons/obj/clothing/modsuit/mod_bodybags.dmi'
	material_drop = null
	icon_state = "holobag_med"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	foldedbag_path = null
	weather_protection = list(TRAIT_SNOWSTORM_IMMUNE)

/obj/structure/closet/body_bag/containment/mod_hardlight/Initialize(mapload)
	. = ..()
	create_mod_air()

/obj/structure/closet/body_bag/containment/mod_hardlight/Destroy()
	QDEL_NULL(air_contents)
	return ..()

/obj/structure/closet/body_bag/containment/mod_hardlight/return_air()
	if(opened)
		return ..()
	create_mod_air()
	return air_contents

/obj/structure/closet/body_bag/containment/mod_hardlight/remove_air(amount)
	if(opened)
		return ..()
	create_mod_air()
	return air_contents.remove(amount)

/obj/structure/closet/body_bag/containment/mod_hardlight/remove_air_ratio(ratio)
	if(opened)
		return ..()
	create_mod_air()
	return air_contents.remove_ratio(ratio)

/obj/structure/closet/body_bag/containment/mod_hardlight/MouseDrop()
	return FALSE

/obj/structure/closet/body_bag/containment/mod_hardlight/Entered(atom/movable/entrant)
	. = ..()
	if(isliving(entrant))
		ADD_TRAIT(entrant, TRAIT_SNOWSTORM_IMMUNE, REF(src))

/obj/structure/closet/body_bag/containment/mod_hardlight/Exited(atom/movable/leaver)
	. = ..()
	if(isliving(leaver))
		REMOVE_TRAIT(leaver, TRAIT_SNOWSTORM_IMMUNE, REF(src))

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight
	name = "голографический мешок для заключённых"
	desc = "Голографический транспортный мешок с крепёжными ремнями."
	icon = 'icons/obj/clothing/modsuit/mod_bodybags.dmi'
	material_drop = null
	icon_state = "holobag_sec"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	foldedbag_path = null
	weather_protection = list(TRAIT_SNOWSTORM_IMMUNE)

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/Initialize(mapload)
	. = ..()
	create_mod_air()

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/Destroy()
	QDEL_NULL(air_contents)
	return ..()

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/return_air()
	if(opened)
		return ..()
	create_mod_air()
	return air_contents

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/remove_air(amount)
	if(opened)
		return ..()
	create_mod_air()
	return air_contents.remove(amount)

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/remove_air_ratio(ratio)
	if(opened)
		return ..()
	create_mod_air()
	return air_contents.remove_ratio(ratio)

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/MouseDrop()
	return FALSE

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/Entered(atom/movable/entrant)
	. = ..()
	if(isliving(entrant))
		ADD_TRAIT(entrant, TRAIT_SNOWSTORM_IMMUNE, REF(src))

/obj/structure/closet/body_bag/containment/prisoner/mod_hardlight/Exited(atom/movable/leaver)
	. = ..()
	if(isliving(leaver))
		REMOVE_TRAIT(leaver, TRAIT_SNOWSTORM_IMMUNE, REF(src))

/obj/item/mod/module/projectile_dampener
	mod_module_flags = MOD_MODULE_SECURITY
	name = "MOD projectile dampener module"
	desc = "Ослабляет и замедляет снаряды в небольшом поле вокруг носителя."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "projectile_dampener"
	module_type = MODULE_TOGGLE
	complexity = 3
	active_power_cost = DEFAULT_CHARGE_DRAIN
	cooldown_time = 1.5 SECONDS
	incompatible_modules = list(/obj/item/mod/module/projectile_dampener)
	var/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/dampening_field

/obj/item/mod/module/projectile_dampener/on_activation()
	if(!..())
		return FALSE
	QDEL_NULL(dampening_field)
	dampening_field = make_field(/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field, list("host" = mod.wearer, "current_range" = MOD_DAMPENER_RADIUS))
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(move_field))
	return TRUE

/obj/item/mod/module/projectile_dampener/on_deactivation()
	clear_field()
	return ..()

/obj/item/mod/module/projectile_dampener/on_unequip()
	clear_field()

/obj/item/mod/module/projectile_dampener/on_uninstall(deleting = FALSE, user)
	clear_field()
	return ..()

/obj/item/mod/module/projectile_dampener/Destroy()
	clear_field()
	return ..()

/obj/item/mod/module/projectile_dampener/on_active_process(delta_time)
	dampening_field?.recalculate_field()

/obj/item/mod/module/projectile_dampener/proc/clear_field()
	UnregisterSignal(dampening_field?.host, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(dampening_field)

/obj/item/mod/module/projectile_dampener/proc/move_field()
	SIGNAL_HANDLER
	if(dampening_field)
		INVOKE_ASYNC(dampening_field, TYPE_PROC_REF(/datum/proximity_monitor/advanced, recalculate_field), TRUE)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field
	requires_processing = FALSE
	var/static/image/bullet_overlay = image('icons/effects/fields.dmi', "projectile_dampen_effect")

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/Destroy()
	for(var/obj/item/projectile/bullet as anything in tracked.Copy())
		release_projectile(bullet)
	projector = null
	return ..()

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/update_new_turfs()
	field_turfs_new = list()
	edge_turfs_new = list()
	var/turf/center = get_turf(host)
	if(!center)
		return FALSE
	for(var/turf/location in range(current_range, center))
		field_turfs_new += location
		if(get_dist(location, center) == current_range)
			edge_turfs_new += location
	return TRUE

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/setup_field_turf(turf/location)
	. = ..()
	for(var/obj/item/projectile/bullet in location)
		capture_projectile(bullet)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/cleanup_field_turf(turf/location)
	for(var/obj/item/projectile/bullet in location)
		if(!contains_projectile(bullet))
			release_projectile(bullet)
	return ..()

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/field_turf_crossed(atom/movable/movable)
	if(istype(movable, /obj/item/projectile))
		capture_projectile(movable)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/field_turf_uncrossed(atom/movable/movable)
	if(istype(movable, /obj/item/projectile) && !contains_projectile(movable))
		release_projectile(movable)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/field_edge_canpass()
	return TRUE

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/field_edge_crossed(atom/movable/movable)
	if(istype(movable, /obj/item/projectile))
		capture_projectile(movable)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/field_edge_uncrossed(atom/movable/movable)
	if(istype(movable, /obj/item/projectile) && !contains_projectile(movable))
		release_projectile(movable)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/proc/contains_projectile(atom/movable/movable)
	var/turf/location = get_turf(movable)
	var/turf/center = get_turf(host)
	return location && center && location.z == center.z && get_dist(location, center) <= current_range

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/capture_projectile(obj/item/projectile/bullet, track_projectile = TRUE)
	if(QDELETED(bullet) || (bullet in tracked) || !contains_projectile(bullet))
		return
	tracked += bullet
	ADD_TRAIT(bullet, TRAIT_MOD_DAMPENED, REF(src))
	bullet.pixels_per_second *= MOD_DAMPENER_SPEED
	bullet.damage *= MOD_DAMPENER_DAMAGE
	bullet.knockdown *= MOD_DAMPENER_DEBUFF
	bullet.stun *= MOD_DAMPENER_DEBUFF
	bullet.stamina *= MOD_DAMPENER_DEBUFF
	bullet.add_overlay(bullet_overlay)
	RegisterSignal(bullet, COMSIG_PARENT_QDELETING, PROC_REF(forget_projectile))
	RegisterSignal(bullet, COMSIG_MOVABLE_MOVED, PROC_REF(projectile_moved))

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/release_projectile(obj/item/projectile/bullet)
	if(!(bullet in tracked))
		return
	tracked -= bullet
	UnregisterSignal(bullet, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
	bullet.pixels_per_second /= MOD_DAMPENER_SPEED
	bullet.damage /= MOD_DAMPENER_DAMAGE
	bullet.knockdown /= MOD_DAMPENER_DEBUFF
	bullet.stun /= MOD_DAMPENER_DEBUFF
	bullet.stamina /= MOD_DAMPENER_DEBUFF
	REMOVE_TRAIT(bullet, TRAIT_MOD_DAMPENED, REF(src))
	if(!HAS_TRAIT(bullet, TRAIT_MOD_DAMPENED))
		bullet.cut_overlay(bullet_overlay)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/proc/forget_projectile(obj/item/projectile/bullet)
	SIGNAL_HANDLER
	release_projectile(bullet)

/datum/proximity_monitor/advanced/peaceborg_dampener/mod_field/proc/projectile_moved(obj/item/projectile/bullet)
	SIGNAL_HANDLER
	if(!contains_projectile(bullet))
		release_projectile(bullet)

/obj/item/mod/module/chameleon
	mod_module_flags = MOD_MODULE_GENERAL
	name = "MOD chameleon module"
	desc = "Маскирует выключенный MOD под рюкзак или пояс. Маскировка снимается при включении костюма."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "chameleon"
	module_type = MODULE_USABLE
	complexity = 2
	allowed_inactive = TRUE
	cooldown_time = 0.5 SECONDS
	incompatible_modules = list(/obj/item/mod/module/chameleon)
	var/list/possible_disguises
	var/list/saved_look
	var/obj/item/current_disguise
	var/static/list/visual_vars = list("name", "desc", "icon", "icon_state", "item_state", "mob_overlay_icon", "alternate_worn_layer", "lefthand_file", "righthand_file")

/obj/item/mod/module/chameleon/on_install()
	. = ..()
	possible_disguises = list()
	var/base_path = mod.slot_flags & ITEM_SLOT_BACK ? /obj/item/storage/backpack : /obj/item/storage/belt
	for(var/obj/item/disguise as anything in typesof(base_path))
		if(!initial(disguise.icon_state))
			continue
		var/label = "[initial(disguise.name)] ([initial(disguise.icon_state)])"
		if(!possible_disguises[label])
			possible_disguises[label] = disguise

/obj/item/mod/module/chameleon/on_uninstall(deleting = FALSE, user)
	return_look()
	possible_disguises = null
	return ..()

/obj/item/mod/module/chameleon/Destroy()
	return_look()
	possible_disguises = null
	return ..()

/obj/item/mod/module/chameleon/on_use()
	if(!..())
		return FALSE
	if(mod.is_active() || mod.is_activating())
		balloon_alert(mod.wearer, "сначала выключите MOD")
		return FALSE
	if(current_disguise)
		return return_look()
	var/obj/item/mod/control/suit = mod
	var/picked = tgui_input_list(mod.wearer, "Выберите внешний вид MOD", "Маскировка", possible_disguises)
	if(QDELETED(src) || mod != suit || !picked)
		return FALSE
	return set_disguise(possible_disguises[picked])

/obj/item/mod/module/chameleon/get_configuration()
	. = ..()
	var/list/choices = list(MOD_CHAMELEON_RESET)
	var/selected = MOD_CHAMELEON_RESET
	for(var/label in possible_disguises)
		choices += label
		if(possible_disguises[label] == current_disguise)
			selected = label
	.["disguise"] = add_ui_configuration("Маскировка", "list", selected, choices)

/obj/item/mod/module/chameleon/configure_edit(key, value)
	if(key != "disguise")
		return
	if(value == MOD_CHAMELEON_RESET)
		return return_look()
	return set_disguise(possible_disguises?[value])

/obj/item/mod/module/chameleon/proc/set_disguise(obj/item/disguise)
	if(!mod || mod.is_active() || mod.is_activating() || !valid_disguise(disguise))
		return FALSE
	if(!saved_look)
		saved_look = list()
		for(var/key in visual_vars)
			saved_look[key] = mod.vars[key]
	current_disguise = disguise
	apply_look()
	RegisterSignal(mod, COMSIG_MOD_ACTIVATE, PROC_REF(on_activation_attempt), override = TRUE)
	RegisterSignal(mod, COMSIG_ATOM_UPDATE_ICON_STATE, PROC_REF(on_icon_update), override = TRUE)
	refresh_look()
	return TRUE

/obj/item/mod/module/chameleon/proc/valid_disguise(disguise)
	for(var/label in possible_disguises)
		if(possible_disguises[label] == disguise)
			return TRUE
	return FALSE

/obj/item/mod/module/chameleon/proc/apply_look()
	mod.name = initial(current_disguise.name)
	mod.desc = initial(current_disguise.desc)
	mod.icon = initial(current_disguise.icon)
	mod.icon_state = initial(current_disguise.icon_state)
	mod.item_state = initial(current_disguise.item_state)
	mod.mob_overlay_icon = initial(current_disguise.mob_overlay_icon)
	mod.alternate_worn_layer = initial(current_disguise.alternate_worn_layer)
	mod.lefthand_file = initial(current_disguise.lefthand_file)
	mod.righthand_file = initial(current_disguise.righthand_file)

/obj/item/mod/module/chameleon/proc/on_icon_update()
	SIGNAL_HANDLER
	if(current_disguise)
		apply_look()

/obj/item/mod/module/chameleon/proc/on_activation_attempt()
	SIGNAL_HANDLER
	return_look()

/obj/item/mod/module/chameleon/proc/return_look()
	if(!mod || !saved_look)
		return FALSE
	UnregisterSignal(mod, list(COMSIG_MOD_ACTIVATE, COMSIG_ATOM_UPDATE_ICON_STATE))
	for(var/key in saved_look)
		mod.vars[key] = saved_look[key]
	saved_look = null
	current_disguise = null
	refresh_look()
	return TRUE

/obj/item/mod/module/chameleon/proc/refresh_look()
	if(mod.wearer)
		mod.wearer.regenerate_icons()
	if(ismob(mod.loc))
		var/mob/holder = mod.loc
		holder.update_inv_hands()

/obj/item/mod/module/chameleon/on_suit_activation()
	return_look()

/obj/item/mod/module/mister/cleaner
	name = "MOD janitorial mister module"
	desc = "Опрыскиватель космическим очистителем. Восполняет запас реагента, пока модуль активен."
	volume = 100
	watertank_type = /obj/item/watertank/mod_cleaner
	active_power_cost = DEFAULT_CHARGE_DRAIN
	mod_module_flags = MOD_MODULE_GENERAL

/obj/item/mod/module/mister/cleaner/on_active_process(delta_time)
	var/refill = min(volume - tank.reagents.total_volume, MOD_CLEANER_REFILL * delta_time)
	if(refill > 0)
		tank.reagents.add_reagent(/datum/reagent/space_cleaner, refill)

/obj/item/watertank/mod_cleaner
	name = "MOD cleaning tank"
	volume = 100

/obj/item/watertank/mod_cleaner/Initialize(mapload)
	. = ..()
	reagents.reagents_holder_flags = AMOUNT_VISIBLE
	reagents.add_reagent(/datum/reagent/space_cleaner, volume)
