/obj/item/mod/module/flashlight/darkness
	name = "MOD flashdark module"
	desc = "Пара излучателей создаёт область темноты вокруг носителя костюма."
	light_color = COLOR_BLACK
	light_range = 2
	light_power = -2
	min_range = 1
	max_range = 3
	var/obj/item/flashlight/flashdark/mod_internal/darkness

/obj/item/mod/module/flashlight/darkness/Destroy()
	QDEL_NULL(darkness)
	return ..()

/obj/item/mod/module/flashlight/darkness/apply_light()
	if(!darkness)
		darkness = new(mod.wearer)
	darkness.brightness_on = light_range
	darkness.flashlight_power = light_power
	darkness.on = TRUE
	darkness.update_brightness(mod.wearer)

/obj/item/mod/module/flashlight/darkness/clear_light()
	QDEL_NULL(darkness)

/obj/item/mod/module/flashlight/darkness/get_configuration()
	. = ..()
	. -= "light_color"

/obj/item/mod/module/flashlight/darkness/configure_edit(key, value)
	if(key != "light_range" || !isnum(value))
		return
	light_range = clamp(value, min_range, max_range)
	if(active)
		apply_light()

/obj/item/flashlight/flashdark/mod_internal
	actions_types = list()

/obj/item/mod/module/emp_shield/pulse
	name = "MOD EMP pulse module"
	desc = "Полевой ингибитор может создать электромагнитный импульс вокруг носителя, защищая его от собственного разряда."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "emp_pulse"
	module_type = MODULE_USABLE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	cooldown_time = 8 SECONDS
	var/emitting_pulse = FALSE

/obj/item/mod/module/emp_shield/pulse/handle_emp_act(source, severity)
	if(!emitting_pulse)
		return ..()

/obj/item/mod/module/emp_shield/pulse/proc/protect_pulse()
	SIGNAL_HANDLER
	return EMP_PROTECT_SELF | EMP_PROTECT_CONTENTS | EMP_PROTECT_WIRES

/obj/item/mod/module/emp_shield/pulse/on_use()
	if(!..() || !mod.is_active() || !drain_power(use_power_cost))
		return FALSE
	playsound(mod, 'sound/effects/empulse.ogg', MOD_EMP_PULSE_VOLUME, TRUE)
	var/turf/center = get_turf(mod)
	new /obj/effect/temp_visual/emp/pulse(center)
	log_combat(mod.wearer, src, "released an EMP pulse from")
	var/mob/living/carbon/human/user = mod.wearer
	emitting_pulse = TRUE
	RegisterSignal(user, COMSIG_ATOM_EMP_ACT, PROC_REF(protect_pulse))
	for(var/atom/target in spiral_range(MOD_EMP_PULSE_LIGHT_RANGE, center))
		if(target == user || target == mod)
			continue
		var/severity = get_dist(center, target) <= MOD_EMP_PULSE_HEAVY_RANGE ? MOD_EMP_SEVERITY_MAX : MOD_EMP_PULSE_LIGHT_SEVERITY
		target.emp_act(severity)
	UnregisterSignal(user, COMSIG_ATOM_EMP_ACT)
	emitting_pulse = FALSE
	return TRUE

/obj/item/mod/module/dispenser/mirage
	name = "MOD mirage grenade dispenser module"
	desc = "Создаёт гранаты, проецирующие неподвижную голографическую копию владельца."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "mirage_grenade"
	cooldown_time = 20 SECONDS
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi'
	overlay_state_inactive = "module_mirage_grenade"
	dispense_type = /obj/item/grenade/mirage

/obj/item/mod/module/dispenser/mirage/on_use()
	var/obj/item/grenade/mirage/grenade = ..()
	if(!istype(grenade))
		return FALSE
	grenade.preprime(mod.wearer)
	return grenade

/obj/item/grenade/mirage
	name = "mirage grenade"
	desc = "Создаёт временную голографическую копию того, кто взвёл гранату."
	icon = 'icons/obj/crystallizer_grenades.dmi'
	icon_state = "mirage"
	det_time = 3 SECONDS
	var/datum/weakref/mirage_source

/obj/item/grenade/mirage/Destroy()
	mirage_source = null
	primed_by = null
	return ..()

/obj/item/grenade/mirage/preprime(mob/user, delayoverride, msg = TRUE, volume = MOD_MIRAGE_ARM_VOLUME)
	if(isliving(user))
		mirage_source = WEAKREF(user)
	return ..()

/obj/item/grenade/mirage/prime(mob/living/lanced_by)
	. = ..()
	do_sparks(rand(MOD_MIRAGE_SPARKS_MIN, MOD_MIRAGE_SPARKS_MAX), FALSE, src)
	var/mob/living/original = mirage_source?.resolve()
	if(original)
		var/mob/living/simple_animal/hostile/illusion/mirage/copy = new(get_turf(src))
		copy.mock_as(original)
	qdel(src)

/mob/living/simple_animal/hostile/illusion/mirage
	density = FALSE
	AIStatus = AI_OFF
	wander = FALSE
	melee_damage_lower = 0
	melee_damage_upper = 0
	var/datum/weakref/mirage_source

/mob/living/simple_animal/hostile/illusion/mirage/Destroy()
	mirage_source = null
	return ..()

/mob/living/simple_animal/hostile/illusion/mirage/proc/mock_as(mob/living/original)
	Copy_Parent(original, MOD_MIRAGE_LIFETIME, MOD_MIRAGE_HEALTH)
	parent_mob = null
	mirage_source = WEAKREF(original)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/mob/living, death)), MOD_MIRAGE_LIFETIME)

/mob/living/simple_animal/hostile/illusion/mirage/examine(mob/user)
	var/mob/living/original = mirage_source?.resolve()
	return original ? original.examine(user) : ..()

/mob/living/simple_animal/hostile/illusion/mirage/death(gibbed)
	do_sparks(rand(MOD_MIRAGE_SPARKS_MIN, MOD_MIRAGE_SPARKS_MAX), FALSE, src)
	return ..()

/obj/item/mod/module/surgical_processor/emergency
	desc = "Хирургический процессор с предзагруженными операциями для экстренного восстановления органов и тканей."
	device = /obj/item/surgical_processor/mod/emergency

/obj/item/surgical_processor/mod/emergency
	advanced_surgeries = list(
		/datum/surgery/healing/combo/upgraded/femto,
		/datum/surgery/blood_filter,
		/datum/surgery/brain_surgery,
		/datum/surgery/coronary_bypass,
		/datum/surgery/eye_surgery,
		/datum/surgery/hepatectomy,
		/datum/surgery/advanced/revival,
	)

/obj/item/mod/module/insignia/syndie
	color = COLOR_SYNDIE_RED

/obj/item/mod/module/welding/camera_vision
	name = "MOD camera vision module"
	desc = "Оптическая система шлема защищает глаза от вспышек и мешает камерам отслеживать владельца."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "welding_camera"
	removable = FALSE
	complexity = 0
	overlay_state_inactive = null

/obj/item/mod/module/welding/camera_vision/on_suit_activation()
	. = ..()
	ADD_TRAIT(mod.get_helmet(), TRAIT_MOD_CAMERA_BLOCK, REF(src))

/obj/item/mod/module/welding/camera_vision/on_suit_deactivation(deleting = FALSE)
	. = ..()
	REMOVE_TRAIT(mod.get_helmet(), TRAIT_MOD_CAMERA_BLOCK, REF(src))

/obj/item/mod/module/welding/syndicate
	name = "MODsuit flash-protected optical suite"
	desc = "Встроенная оптическая система Синдиката защищает глаза и закрывает забрало при переходе в боевой режим."
	complexity = 0
	removable = FALSE
	overlay_icon_file = 'icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi'
	overlay_state_inactive = "module_armorbooster_off"
	use_mod_colors = TRUE

/obj/item/mod/module/welding/syndicate/on_suit_activation()
	. = ..()
	RegisterSignal(mod.wearer, list(COMSIG_LIVING_COMBAT_ENABLED, COMSIG_LIVING_COMBAT_DISABLED), PROC_REF(on_combat_toggle), override = TRUE)

/obj/item/mod/module/welding/syndicate/on_suit_deactivation(deleting = FALSE)
	. = ..()
	UnregisterSignal(mod.wearer, list(COMSIG_LIVING_COMBAT_ENABLED, COMSIG_LIVING_COMBAT_DISABLED))

/obj/item/mod/module/welding/syndicate/proc/on_combat_toggle()
	SIGNAL_HANDLER
	playsound(mod, 'sound/mecha/mechmove03.ogg', MOD_OPTICS_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	mod.wearer.update_inv_back()

/obj/item/mod/module/welding/syndicate/generate_worn_overlay()
	if(!mod?.wearer || !check_required_modpart())
		return list()
	var/static/list/states = icon_states('icons/mob/clothing/modsuit/mod_modules_whitemoon.dmi')
	var/combat_state = SEND_SIGNAL(mod.wearer, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE) ? "on" : "off"
	overlay_state_inactive = "module_armorbooster_[combat_state]-[mod.skin]"
	if(!(overlay_state_inactive in states))
		overlay_state_inactive = "module_armorbooster_[combat_state]-syndicate"
	return ..()

/obj/item/mod/module/storage/large_capacity
	parent_type = /obj/item/mod/module/storage/extended

/obj/item/mod/module/storage/bluespace
	parent_type = /obj/item/mod/module/storage/extended
	name = "MOD bluespace storage module"
	desc = "Встроенное хранилище использует блюспейс-карманы для переноски крупного снаряжения и сумок."
	icon_state = "storage_bluespace"
	max_w_class = MAX_WEIGHT_CLASS_BAG_OF_HOLDING
	max_volume = STORAGE_VOLUME_BAG_OF_HOLDING

/obj/item/mod/module/storage/bluespace/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/assembly/signaler/anomaly/bluespace))
		balloon_alert(user, "уже улучшено")
		return TRUE
	return ..()

/obj/item/mod/module/storage/belt
	name = "MOD case storage module"
	desc = "Компактное хранилище поясного MOD-костюма вмещает семь небольших предметов."
	icon_state = "storage_case"
	complexity = 0
	max_w_class = WEIGHT_CLASS_SMALL
	storage_flags = STORAGE_FLAGS_LEGACY_DEFAULT

/obj/item/mod/module/storage/belt/can_install(obj/item/mod/control/suit, mob/user)
	if(!(suit.slot_flags & ITEM_SLOT_BELT))
		if(user)
			balloon_alert(user, "нужен поясной MOD")
		return FALSE
	return ..()

/obj/item/mod/module/storage/belt/update_capacity()
	. = ..()
	if(!mod_storage)
		return
	mod_storage.max_items = MOD_CASE_STORAGE_SLOTS
	mod_storage.max_combined_w_class = WEIGHT_CLASS_NORMAL * MOD_CASE_STORAGE_SLOTS
	if(locate(/obj/item/mod/module/storage_upgrader) in mod.modules)
		mod_storage.storage_flags = STORAGE_FLAGS_VOLUME_DEFAULT

/obj/item/mod/module/springlock/bite_of_87
	speed_bootup_bonus = 10

/obj/item/mod/module/springlock/bite_of_87/Initialize(mapload)
	. = ..()
	var/obj/item/mod/module/dna_lock/lock_type = /obj/item/mod/module/dna_lock
	name = initial(lock_type.name)
	icon_state = initial(lock_type.icon_state)
	complexity = initial(lock_type.complexity)
	use_power_cost = initial(lock_type.use_power_cost)

/obj/item/mod/module/springlock/bite_of_87/update_desc()
	var/obj/item/mod/module/dna_lock/lock_type = /obj/item/mod/module/dna_lock
	desc = initial(lock_type.desc)

/obj/item/mod/module/springlock/bite_of_87/on_suit_activation()
	. = ..()
	if(prob(MOD_BITE_EASTER_CHANCE) || (SSholidays.holidays && SSholidays.holidays[APRIL_FOOLS]))
		mod.set_mod_color(MOD_BITE_SUIT_COLOR)
		mod.wearer.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
		mod.wearer.add_atom_colour(MOD_BITE_BODY_COLOR, FIXED_COLOUR_PRIORITY)

/obj/item/mod/module/stealth/ninja
	name = "MOD advanced cloaking module"
	icon_state = "cloak_ninja"
	bumpoff = FALSE
	desc = "Система маскировки клана Паука скрывает носителя и заглушает его шаги. Поле сохраняется при столкновениях."
	stealth_alpha = 20
	active_power_cost = DEFAULT_CHARGE_DRAIN
	use_power_cost = DEFAULT_CHARGE_DRAIN * 5
	cooldown_time = 3 SECONDS

/obj/item/mod/module/stealth/ninja/on_activation()
	if(!check_power(use_power_cost))
		return FALSE
	. = ..()
	if(.)
		ADD_TRAIT(mod.wearer, TRAIT_SILENT_STEP, REF(src))

/obj/item/mod/module/stealth/ninja/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	REMOVE_TRAIT(mod.wearer, TRAIT_SILENT_STEP, REF(src))
