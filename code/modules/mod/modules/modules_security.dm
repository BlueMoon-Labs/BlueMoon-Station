//Security modules for MODsuits

///Cloaking - Lowers the user's visibility, can be interrupted by being touched or attacked.
/obj/item/mod/module/stealth
	name = "MOD prototype cloaking module"
	desc = "Полная модернизация костюма, форма технологии визуального маскировки, использующей эзотерическую технологию \
		для изгиба света вокруг пользователя, а также миметические материалы для соответствия поверхности костюма \
		окружению на основе данных сенсоров. По какой-то причине эта технология встречается редко."
	icon_state = "cloak"
	module_type = MODULE_TOGGLE
	complexity = 4
	active_power_cost = DEFAULT_CHARGE_DRAIN * 2
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	incompatible_modules = list(/obj/item/mod/module/stealth)
	cooldown_time = 5 SECONDS
	/// Whether or not the cloak turns off on bumping.
	var/bumpoff = TRUE
	/// The alpha applied when the cloak is on.
	var/stealth_alpha = 50
	mod_module_flags = MOD_MODULE_SECURITY // BLUEMOON ADD

/obj/item/mod/module/stealth/on_activation()
	. = ..()
	if(!.)
		return
	if(bumpoff)
		RegisterSignal(mod.wearer, COMSIG_LIVING_MOB_BUMP, PROC_REF(unstealth))
	RegisterSignal(mod.wearer, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(mod.wearer, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_bullet_act))
	RegisterSignal(mod.wearer, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_PAW), PROC_REF(unstealth))
	ADD_TRAIT(mod.wearer, TRAIT_STRONG_INVISIBILITY, MOD_TRAIT)
	animate(mod.wearer, alpha = stealth_alpha, time = 1.5 SECONDS)
	drain_power(use_power_cost)

/obj/item/mod/module/stealth/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	if(bumpoff)
		UnregisterSignal(mod.wearer, COMSIG_LIVING_MOB_BUMP)
	UnregisterSignal(mod.wearer, list(COMSIG_HUMAN_MELEE_UNARMED_ATTACK, COMSIG_MOB_ITEM_ATTACK, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_BULLET_ACT, COMSIG_ATOM_HULK_ATTACK, COMSIG_ATOM_ATTACK_PAW))
	REMOVE_TRAIT(mod.wearer, TRAIT_STRONG_INVISIBILITY, MOD_TRAIT)
	animate(mod.wearer, alpha = 255, time = 1.5 SECONDS)

/obj/item/mod/module/stealth/proc/unstealth(datum/source)
	SIGNAL_HANDLER

	to_chat(mod.wearer, span_warning("[src] gets discharged from contact!"))
	do_sparks(2, TRUE, src)
	drain_power(use_power_cost)
	on_deactivation(display_message = TRUE, deleting = FALSE)

/obj/item/mod/module/stealth/proc/on_unarmed_attack(datum/source, atom/target)
	SIGNAL_HANDLER

	if(!isliving(target))
		return
	unstealth(source)

/obj/item/mod/module/stealth/proc/on_bullet_act(datum/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER

	if(projectile.nodamage)
		return
	unstealth(source)

///Magnetic Harness - Automatically puts guns in your suit storage when you drop them.
/obj/item/mod/module/magnetic_harness
	name = "MOD magnetic harness module"
	desc = "Основано на старых комплектах подвесок TerraGov, эта магнитная система автоматически возвращает упавшее оружие к носителю."
	icon_state = "mag_harness"
	complexity = 2
	use_power_cost = DEFAULT_CHARGE_DRAIN
	incompatible_modules = list(/obj/item/mod/module/magnetic_harness)
	/// Time before we activate the magnet.
	var/magnet_delay = 0.8 SECONDS
	/// The typecache of all guns we allow.
	var/static/list/guns_typecache
	/// The guns already allowed by the modsuit chestplate.
	var/list/already_allowed_guns = list()
	mod_module_flags = MOD_MODULE_SECURITY // BLUEMOON ADD

/obj/item/mod/module/magnetic_harness/Initialize(mapload)
	. = ..()
	if(!guns_typecache)
		guns_typecache = typecacheof(list(/obj/item/gun/ballistic, /obj/item/gun/energy, /obj/item/gun/grenadelauncher, /obj/item/gun/chem, /obj/item/gun/syringe))

/obj/item/mod/module/magnetic_harness/on_install()
	var/obj/item/clothing/mod_part/suit/chestplate = mod.get_chestplate()
	already_allowed_guns = guns_typecache & chestplate.allowed
	chestplate.allowed |= guns_typecache

/obj/item/mod/module/magnetic_harness/on_uninstall(deleting = FALSE)
	var/obj/item/clothing/mod_part/suit/chestplate = mod.get_chestplate()
	if(deleting)
		return
	chestplate.allowed -= (guns_typecache - already_allowed_guns)

/obj/item/mod/module/magnetic_harness/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(check_dropped_item))

/obj/item/mod/module/magnetic_harness/on_suit_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_MOB_UNEQUIPPED_ITEM)

/obj/item/mod/module/magnetic_harness/proc/check_dropped_item(datum/source, obj/item/dropped_item, force, new_location)
	SIGNAL_HANDLER

	if(!is_type_in_typecache(dropped_item, guns_typecache))
		return
	if(new_location != get_turf(mod))
		return
	addtimer(CALLBACK(src, PROC_REF(pick_up_item), dropped_item), magnet_delay)

/obj/item/mod/module/magnetic_harness/proc/pick_up_item(obj/item/item)
	if(!isturf(item.loc) || !item.Adjacent(mod.wearer))
		return
	if(!mod.wearer.equip_to_slot_if_possible(item, ITEM_SLOT_SUITSTORE, qdel_on_fail = FALSE, disable_warning = TRUE))
		return
	playsound(mod, 'sound/items/modsuit/magnetic_harness.ogg', 50, TRUE)
	mod.balloon_alert(mod.wearer, "[item] reattached")
	drain_power(use_power_cost)

///Pepper Shoulders

///Holster - Instantly holsters any not huge gun.
/obj/item/mod/module/holster
	name = "MOD holster module"
	desc = "Основано на типичных отделениях хранения, эта система позволяет костюму размещать \
		стандартное огнестрельное оружие на поверхности и обеспечивает крайне быстрое извлечение. \
		Хотя некоторые пользователи предпочитают грудь, другие — предплечье для быстрого развёртывания, \
		некоторые представители правопорядка предпочитают, чтобы кобура выдвигалась из бедра."
	icon_state = "holster"
	module_type = MODULE_USABLE
	complexity = 2
	incompatible_modules = list(/obj/item/mod/module/holster)
	cooldown_time = 0.5 SECONDS
	allowed_inactive = TRUE
	/// Gun we have holstered.
	var/obj/item/gun/holstered
	mod_module_flags = MOD_MODULE_SECURITY // BLUEMOON ADD

/obj/item/mod/module/holster/on_use()
	. = ..()
	if(!.)
		return
	if(!holstered)
		var/obj/item/gun/holding = mod.wearer.get_active_held_item()
		if(!holding)
			mod.balloon_alert(mod.wearer, "nothing to holster!")
			return
		if(mod.wearer.transferItemToLoc(holding, src, force = FALSE, silent = TRUE))
			holstered = holding
			mod.balloon_alert(mod.wearer, "weapon holstered")
			playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
	else if(mod.wearer.put_in_active_hand(holstered, forced = FALSE, ignore_animation = TRUE))
		mod.balloon_alert(mod.wearer, "weapon drawn")
		playsound(mod, 'sound/weapons/revolverempty.ogg', 100, TRUE)
	else
		mod.balloon_alert(mod.wearer, "holster full!")

/obj/item/mod/module/holster/on_uninstall(deleting = FALSE)
	if(holstered)
		holstered.forceMove(drop_location())

/obj/item/mod/module/holster/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == holstered)
		holstered = null

/obj/item/mod/module/holster/Destroy()
	QDEL_NULL(holstered)
	return ..()

///Megaphone - Lets you speak loud.
/obj/item/mod/module/megaphone
	name = "MOD megaphone module"
	desc = "Микрочиповый мегафон, связанный с костюмом MOD, для очень важных целей, таких как: громкость."
	icon_state = "megaphone"
	module_type = MODULE_TOGGLE
	complexity = 1
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	incompatible_modules = list(/obj/item/mod/module/megaphone)
	cooldown_time = 0.5 SECONDS
	/// List of spans we add to the speaker.
	var/list/voicespan = list(SPAN_COMMAND)
	required_modpart_index = MOD_PART_HEAD

/obj/item/mod/module/megaphone/on_activation()
	. = ..()
	if(!.)
		return
	RegisterSignal(mod.wearer, COMSIG_MOB_SAY, PROC_REF(handle_speech))

/obj/item/mod/module/megaphone/on_deactivation(display_message = TRUE, deleting = FALSE)
	. = ..()
	if(!.)
		return
	UnregisterSignal(mod.wearer, COMSIG_MOB_SAY)

/obj/item/mod/module/megaphone/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER

	speech_args[SPEECH_SPANS] |= voicespan
	playsound(get_turf(mod), 'sound/items/megaphone.ogg', 100, 0, 1)
	drain_power(use_power_cost)

/obj/item/mod/module/energy_shield
	name = "LEEXP VER-I EnergyShield Module"
	desc = "Первая массовая версия встроенных проекторов энергитического щита, защищающая пользователя от \
	любых снарядов, тратя заряд батареи. Это Low-Effecticy-Experimental(LEEXP) модель из экспериментальной ветки, \
	которая требует просто чудовищных затрат электроэнергии и способна посадить  мгновение ока даже блюспейс батарею. \
	Более старшие модели, обычно, имеют встроенный реактор, способный компенсировать перепады напряжения, однако, \
	это крайне дефицитная деталь, поэтому энергополе будет отключено как только заряд батареи упадёт ниже 50%."
	icon_state = "bad_energy_shield"
	complexity = 5
	module_type = MODULE_TOGGLE
	need_full_deploy = TRUE
	minimum_cell_charge = MOD_MINIMUM_CELL_CHARGE_SHIELD
	incompatible_modules = list(
		/obj/item/mod/module/anomaly_locked/antigrav,
		/obj/item/mod/module/armor,
		)
	var/max_charges = 2
	var/current_charges
	var/recharge_delay = 25 SECONDS //на 5 больше, чем дефолт у рига.
	var/recharge_rate = 1
	var/shield_state = "shield-old"
	var/used_modificator = MOD_DEFAULT_SHIELD_CELL_DRAIN_MODIFICATOR
	var/need_drain_power = TRUE
	var/datum/component/shielded/shield_comp

/obj/item/mod/module/energy_shield/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	on_emp(src, severity)

/obj/item/mod/module/energy_shield/proc/on_emp(datum/source, severity)
	SIGNAL_HANDLER
	on_deactivation()

/obj/item/mod/module/energy_shield/proc/calculate_cell_drain(mob/living/source, real_attack, object, damage, attack_text, attack_type, armour_penetration, attacker, def_zone, return_list)
	if(!need_drain_power)
		return
	var/obj/item/stock_parts/cell/mod_cell = mod.get_cell()
	var/charge_drain = (damage * armour_penetration) * used_modificator
	mod_cell.use(charge_drain, FALSE)

/obj/item/mod/module/energy_shield/on_activation()
	. = ..()
	if(!. || shield_comp) //чтобы не добавлять лишнего.
		return
	shield_comp = mod.wearer.AddComponent(/datum/component/shielded, current_charges, max_charges, recharge_delay, recharge_rate, mod.slot_flags, shield_state)
	RegisterSignal(mod.wearer, COMSIG_LIVING_RUN_BLOCK, PROC_REF(calculate_cell_drain))

/obj/item/mod/module/energy_shield/on_deactivation()
	. = ..()
	UnregisterSignal(mod.wearer, COMSIG_LIVING_RUN_BLOCK)
	qdel(shield_comp)
	shield_comp = null

/obj/item/mod/module/energy_shield/ert
	name = "HESP II Responce Team module"
	desc = "Старшая модель энергощита для модулярных костюмов, способная выдерживать куда больше попаданий, чем\
	гражданская версия. В неё встроен небольшой реактор, который компенсирует часть попаданий, тратя куда меньше \
	энергии, держа поле включенным дольше. Сбоку есть гравировка, которая гласит о том, что данный модуль является \
	собственностью ПАКТа."
	icon_state = "ert_energy_shield"
	minimum_cell_charge = MOD_MINIMUM_CELL_CHARGE_SHIELD_ERT
	used_modificator = MOD_ERT_SHIELD_CELL_DRAIN_MODIFICATOR
	recharge_delay = 18 SECONDS
	max_charges = 4 //в два раза больше станционного

//СДЕЛАТЬ ЗАРяДКУ МОДА ИНДУЦЕРОМ

///Criminal Capture

///Mirage grenade dispenser

///Projectile Dampener

///Active Sonar
