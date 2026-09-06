
//HEV Suit - Compatible with current build
//Based on Half-Life's Hazardous Environment Suit

#define HEV_HEAL_AMOUNT 10
#define HEV_HEAL_COST 50
#define HEV_COOLDOWN 10 SECONDS
#define HEV_BLOOD_REPLENISHMENT 20
#define HEV_BLOOD_COST 30
#define HEV_INTERFACE_SOURCE "HEV_COSTUME"

/obj/item/clothing/head/helmet/space/hev_suit
	name = "hazardous environment suit helmet"
	desc = "The Mark IV HEV suit helmet. Provides excellent protection against hazardous environments."
	icon = 'modular_splurt/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "hev"
	item_state = "hev"
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT | ALLOWINTERNALS
	armor = list(MELEE = 20, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 30, BIO = 40, RAD = 50, FIRE = 40, ACID = 40, WOUND = 40)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	cold_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_HELM_MAX_TEMP_PROTECT
	flash_protect = 2
	strip_delay = 50
	equip_delay_other = 50
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	resistance_flags = FIRE_PROOF | ACID_PROOF
	dog_fashion = null
	slowdown = 0

/obj/item/clothing/suit/space/hev_suit
	name = "hazardous environment suit"
	desc = "The Mark IV HEV suit protects the user from hazardous environments and provides ballistic protection. Has an integrated medical system powered by a cell."
	icon = 'modular_splurt/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/suit_digi.dmi'
	icon_state = "hev"
	item_state = "hev"
	tail_state = "hev"
	w_class = WEIGHT_CLASS_BULKY
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.02
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	allowed = list(/obj/item/flashlight, /obj/item/tank/internals, /obj/item/gun, /obj/item/ammo_box, /obj/item/reagent_containers, /obj/item/melee/baton)
	slowdown = 0
	armor = list(MELEE = 20, BULLET = 20, LASER = 20, ENERGY = 20, BOMB = 30, BIO = 40, RAD = 50, FIRE = 40, ACID = 40, WOUND = 40)
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAUR
	cold_protection = CHEST | GROIN | LEGS | FEET | ARMS | HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	strip_delay = 80
	equip_delay_other = 80
	resistance_flags = FIRE_PROOF | ACID_PROOF
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC|STYLE_PAW_TAURIC

	///Power cell for the suit's systems
	var/obj/item/stock_parts/cell/cell = null
	var/cell_type = /obj/item/stock_parts/cell/high

	///Current user of the suit
	var/mob/living/carbon/current_user = null

	///Healing cooldown
	var/heal_cooldown = 0

	///Sound placeholder
	var/sound_file = 'modular_bluemoon/sound/creatures/mesa/madsci/microwaveboom.ogg'

	///Pickup sound system
	var/firstpickup = TRUE
	var/pickupsound = TRUE

	///Neural interface component
	var/datum/component/neural_interface/neural_interface

	///HEV health scan monitor for detecting nearby entities
	var/datum/neural_monitor/hev_scan/scan_monitor

/obj/item/clothing/suit/space/hev_suit/Initialize(mapload)
	. = ..()
	if(cell_type)
		cell = new cell_type(src)

/obj/item/clothing/suit/space/hev_suit/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(cell)
		QDEL_NULL(cell)
	current_user = null
	if(neural_interface)
		neural_interface.RemoveSource(HEV_INTERFACE_SOURCE)
		neural_interface = null
	if(scan_monitor)
		QDEL_NULL(scan_monitor)
	return ..()

/obj/item/clothing/suit/space/hev_suit/equipped(mob/user, slot)
	. = ..()
	if(!user)
		return
	current_user = user
	START_PROCESSING(SSobj, src)

	//Play pickup sound
	if(!pickupsound)
		return
	if(!ishuman(user))
		return
	if(slot == ITEM_SLOT_OCLOTHING)
		if(!firstpickup)
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/hevsuit_pickup.ogg', volume = 50))
		else
			firstpickup = FALSE
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/hevsuit_firstpickup.ogg', volume = 50))
			SEND_SOUND(user, sound('modular_splurt/sound/halflife/anomalous_materials.ogg', volume = 50))

/obj/item/clothing/suit/space/hev_suit/dropped(mob/user)
	. = ..()
	current_user = null
	if(neural_interface)
		neural_interface.RemoveSource(HEV_INTERFACE_SOURCE)
		neural_interface = null
	STOP_PROCESSING(SSobj, src)

	// Удаляем щит при снятии костюма
	var/datum/component/shielded/shield = GetComponent(/datum/component/shielded)
	if(shield)
		qdel(shield)

/obj/item/clothing/suit/space/hev_suit/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stock_parts/cell))
		if(cell)
			to_chat(user, span_warning("[src] already has a cell installed."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		cell = I
		to_chat(user, span_notice("You install [I] into [src]."))
		playsound(src, sound_file, 50)
		return
	if(istype(I, /obj/item/screwdriver))
		if(!cell)
			to_chat(user, span_warning("[src] has no cell to remove."))
			return
		cell.forceMove(drop_location())
		cell = null
		to_chat(user, span_notice("You remove the cell from [src]."))
		playsound(src, sound_file, 50)
		return
	return ..()

/obj/item/clothing/suit/space/hev_suit/process(seconds_per_tick)
	if(!current_user)
		return
	if(!cell || cell.charge <= 0)
		return

	//Check for helmet - neural interface only works with helmet
	var/has_helmet = FALSE
	var/mob/living/carbon/human/human_user = current_user
	if(istype(human_user) && human_user.head)
		has_helmet = TRUE

	//Initialize neural interface if helmet present
	if(has_helmet && !neural_interface)
		neural_interface = human_user.LoadComponent(/datum/component/neural_interface)
		if(neural_interface)
			neural_interface.AddSource(HEV_INTERFACE_SOURCE)
			//Initialize HEV scan monitor
			if(!scan_monitor)
				neural_interface.add_monitor_by_type(HEV_INTERFACE_SOURCE, /datum/neural_monitor/hev_scan, current_user)
				scan_monitor = neural_interface.get_enabled_monitor_by_type(/datum/neural_monitor/hev_scan)

	//Remove neural interface if no helmet
	if(!has_helmet && neural_interface)
		neural_interface.RemoveSource(HEV_INTERFACE_SOURCE)
		neural_interface = null
		scan_monitor = null

	var/efficiency_multiplier = has_helmet ? 1.0 : 0.7

	// Blood replenishment
	if(current_user.blood_volume < BLOOD_VOLUME_OKAY)
		if(world.time > heal_cooldown)
			if(cell.use(HEV_BLOOD_COST * efficiency_multiplier))
				current_user.blood_volume += HEV_BLOOD_REPLENISHMENT * efficiency_multiplier
				heal_cooldown = world.time + HEV_COOLDOWN
				to_chat(current_user, span_notice("[src]: Blood replenishment administered."))
				if(neural_interface)
					SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Blood replenishment administered", "HEALTH", "#4ad1fa86", 12, 0)
				playsound(src, sound_file, 30)
			else
				to_chat(current_user, span_warning("[src]: Insufficient power for blood replenishment."))

	// Disease curing
	var/diseased = FALSE
	if(current_user.diseases && current_user.diseases.len > 0)
		for(var/datum/disease/disease_to_kill in current_user.diseases)
			if(disease_to_kill)
				disease_to_kill.cure()
				diseased = TRUE
		if(diseased && world.time > heal_cooldown)
			if(cell.use(HEV_HEAL_COST * efficiency_multiplier))
				heal_cooldown = world.time + HEV_COOLDOWN
				to_chat(current_user, span_notice("[src]: Disease cured."))
				if(neural_interface)
					SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Disease cured", "HEALTH", "#4ad1fa86", 12, 0)
				playsound(src, sound_file, 30)

	// Healing damage types
	if(world.time <= heal_cooldown)
		return

	var/brute_loss = current_user.getBruteLoss()
	var/fire_loss = current_user.getFireLoss()
	var/tox_loss = current_user.getToxLoss()
	var/oxy_loss = current_user.getOxyLoss()

	if(brute_loss > 0)
		if(cell.use(HEV_HEAL_COST * efficiency_multiplier))
			current_user.adjustBruteLoss(-HEV_HEAL_AMOUNT * efficiency_multiplier)
			heal_cooldown = world.time + HEV_COOLDOWN
			to_chat(current_user, span_notice("[src]: Brute damage treated."))
			if(neural_interface)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "HEAL_STATUS", "BRUTE", 5 SECONDS, 0)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Brute damage treated", "HEALTH", "#4ad1fa86", 12, 0)
			playsound(src, sound_file, 30)
		return

	if(fire_loss > 0)
		if(cell.use(HEV_HEAL_COST * efficiency_multiplier))
			current_user.adjustFireLoss(-HEV_HEAL_AMOUNT * efficiency_multiplier)
			heal_cooldown = world.time + HEV_COOLDOWN
			to_chat(current_user, span_notice("[src]: Burn damage treated."))
			if(neural_interface)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "HEAL_STATUS", "BURN", 5 SECONDS, 0)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Burn damage treated", "HEALTH", "#4ad1fa86", 12, 0)
			playsound(src, sound_file, 30)
		return

	if(tox_loss > 0)
		if(cell.use(HEV_HEAL_COST * efficiency_multiplier))
			current_user.adjustToxLoss(-HEV_HEAL_AMOUNT * 2 * efficiency_multiplier)
			heal_cooldown = world.time + HEV_COOLDOWN
			to_chat(current_user, span_notice("[src]: Toxin damage treated."))
			if(neural_interface)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "HEAL_STATUS", "TOXIN", 5 SECONDS, 0)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Toxin damage treated", "HEALTH", "#4ad1fa86", 12, 0)
			current_user.balloon_alert(current_user, "обнаружен нейротоксин. Противоядие введено")
			playsound(src, sound_file, 30)
		return

	if(oxy_loss > 0)
		if(cell.use(HEV_HEAL_COST * efficiency_multiplier))
			current_user.adjustOxyLoss(-HEV_HEAL_AMOUNT * efficiency_multiplier)
			heal_cooldown = world.time + HEV_COOLDOWN
			to_chat(current_user, span_notice("[src]: Oxygen deprivation treated."))
			if(neural_interface)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "HEAL_STATUS", "OXY", 5 SECONDS, 0)
				SEND_SIGNAL(current_user, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Oxygen deprivation treated", "HEALTH", "#4ad1fa86", 12, 0)
			playsound(src, sound_file, 30)
		return

/obj/item/clothing/suit/space/hev_suit/examine(mob/user)
	. = ..()
	if(!cell)
		. += span_warning("No power cell installed.")
	else
		var/charge_percent = cell.percent()
		. += span_notice("Power cell charge: [round(charge_percent, 1)]%")

#undef HEV_HEAL_AMOUNT
#undef HEV_HEAL_COST
#undef HEV_COOLDOWN
#undef HEV_BLOOD_REPLENISHMENT
#undef HEV_BLOOD_COST
#undef HEV_INTERFACE_SOURCE

// ============================================================================
// HEV Scan Monitor - Automatic entity detection for HEV suit
// ============================================================================
// Scans for nearby players and Xen fauna (houndeye, headcrab) using view()
// and marks them with neural interface overlays
// ============================================================================

/datum/neural_monitor/hev_scan
	name = "HEV SCAN MONITOR"
	processing = TRUE
	var/icon/overlay_player
	var/icon/overlay_hostile
	var/scan_range = 7
	var/scan_cooldown = 2 SECONDS
	var/last_scan_time = 0

/datum/neural_monitor/hev_scan/New(...)
	. = ..()
	overlay_player = icon(icon='icons/effects/neural_interface_overlays.dmi', icon_state="circle")
	overlay_hostile = icon(icon='icons/effects/neural_interface_overlays.dmi', icon_state="target")

/datum/neural_monitor/hev_scan/Destroy(force, ...)
	overlay_player = null
	overlay_hostile = null
	. = ..()

/datum/neural_monitor/hev_scan/process(delta_time)
	if(!..())
		return FALSE

	if(!monitor_atom)
		return FALSE

	if(world.time < last_scan_time + scan_cooldown)
		return FALSE

	last_scan_time = world.time

	perform_scan()

	return TRUE

/datum/neural_monitor/hev_scan/proc/perform_scan()
	if(!monitor_atom)
		return

	var/mob/living/carbon/human/user = monitor_atom
	if(!istype(user))
		return

	// Scan for entities in view range
	for(var/atom/movable/M in view(scan_range, user))
		if(!M)
			continue

		// Skip self
		if(M == user)
			continue

		// Check for players (carbon humans)
		if(iscarbon(M) && isliving(M))
			var/mob/living/carbon/C = M
			if(C.stat != DEAD)
				scan_entity(C, "PLAYER")
				continue

		// Check for Xen fauna - houndeye
		if(istype(M, /mob/living/simple_animal/hostile/blackmesa/xen/houndeye))
			var/mob/living/simple_animal/hostile/blackmesa/xen/houndeye/H = M
			if(H.stat != DEAD)
				scan_entity(H, "HOUNDEYE", hostile = TRUE)
				continue

		// Check for Xen fauna - headcrab (mesa variant)
		if(istype(M, /mob/living/simple_animal/hostile/headcrab/mesa))
			var/mob/living/simple_animal/hostile/headcrab/mesa/HC = M
			if(HC.stat != DEAD)
				scan_entity(HC, "HEADCRAB", hostile = TRUE)
				continue

/datum/neural_monitor/hev_scan/proc/scan_entity(atom/target, entity_type, hostile = FALSE)
	if(!target || QDELETED(target))
		return

	var/image/overlay
	if(hostile)
		overlay = image(icon = overlay_hostile)
	else
		overlay = image(icon = overlay_player)

	var/scan_data = get_entity_data(target, entity_type, hostile)
	var/unique_key = "\ref[target]_[entity_type]"

	owner.write_image_data(unique_key, overlay, target, scan_data, 2 SECONDS, 32, -5)

/datum/neural_monitor/hev_scan/proc/get_entity_data(atom/target, entity_type, hostile)
	if(!target)
		return "ERROR"

	var/data = "[entity_type]"

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		var/health_percent = C.health / C.maxHealth * 100
		data += "\nHP: [round(health_percent, 0.1)]%"
		if(C.getBruteLoss() > 0)
			data += " BR:[round(C.getBruteLoss())]"
		if(C.getFireLoss() > 0)
			data += " BRN:[round(C.getFireLoss())]"
	else if(isanimal(target))
		var/mob/living/simple_animal/A = target
		var/health_percent = A.health / A.maxHealth * 100
		data += "\nHP: [round(health_percent, 0.1)]%"
		if(hostile)
			data += "\nHOSTILE"

	return data
