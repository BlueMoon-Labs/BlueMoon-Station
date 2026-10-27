/obj/item/mod/module/shooting_assistant
	name = "MOD shooting assistant module"
	desc = "Штурмовой режим ускоряет стрельбу ценой точности. Снайперский режим повышает точность и даёт дополнительный рикошет, но замедляет движение. Оба режима отключают стрельбу с двух рук."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "shooting_assistant"
	complexity = 3
	required_modpart_index = MOD_PART_GLOVES
	mod_module_flags = MOD_MODULE_SECURITY
	incompatible_modules = list(/obj/item/mod/module/shooting_assistant)
	var/selected_mode = MOD_SHOOT_OFF
	var/mob/living/carbon/human/assisted_user

/obj/item/mod/module/shooting_assistant/get_configuration()
	. = ..()
	.["shooting_mode"] = add_ui_configuration("Режим", "list", selected_mode, list(MOD_SHOOT_OFF, MOD_SHOOT_FAST, MOD_SHOOT_PRECISE))

/obj/item/mod/module/shooting_assistant/configure_edit(key, value)
	if(key == "shooting_mode")
		return set_mode(value)

/obj/item/mod/module/shooting_assistant/proc/set_mode(mode)
	if(!(mode in list(MOD_SHOOT_OFF, MOD_SHOOT_FAST, MOD_SHOOT_PRECISE)))
		return FALSE
	if(mode != MOD_SHOOT_OFF && (!mod?.is_active() || !check_required_modpart() || !mod.get_charge()))
		balloon_alert(mod?.wearer, "включите MOD и разверните перчатки")
		return FALSE
	selected_mode = mode
	apply_mode()
	return TRUE

/obj/item/mod/module/shooting_assistant/proc/apply_mode()
	clear_mode()
	if(selected_mode == MOD_SHOOT_OFF || !mod?.is_active() || !check_required_modpart() || !mod.get_charge())
		return
	assisted_user = mod.wearer
	ADD_TRAIT(assisted_user, TRAIT_MOD_NO_AKIMBO, REF(src))
	RegisterSignal(assisted_user, COMSIG_MOD_GUN_SPREAD, PROC_REF(change_spread))
	RegisterSignal(assisted_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	if(selected_mode == MOD_SHOOT_FAST)
		idle_power_cost = DEFAULT_CHARGE_DRAIN * MOD_SHOOT_FAST_POWER
		ADD_TRAIT(assisted_user, TRAIT_DOUBLE_TAP, REF(src))
		return
	idle_power_cost = DEFAULT_CHARGE_DRAIN * MOD_SHOOT_PRECISE_POWER
	ADD_TRAIT(assisted_user, TRAIT_NICE_SHOT, REF(src))
	assisted_user.add_movespeed_modifier(/datum/movespeed_modifier/mod_shooting_assistant)
	RegisterSignal(assisted_user, COMSIG_MOD_PROJECTILE_FIRE, PROC_REF(change_projectile))

/obj/item/mod/module/shooting_assistant/proc/clear_mode()
	idle_power_cost = 0
	if(!assisted_user)
		return
	UnregisterSignal(assisted_user, list(COMSIG_MOD_GUN_SPREAD, COMSIG_MOD_PROJECTILE_FIRE, COMSIG_PARENT_QDELETING))
	REMOVE_TRAIT(assisted_user, TRAIT_MOD_NO_AKIMBO, REF(src))
	REMOVE_TRAIT(assisted_user, TRAIT_DOUBLE_TAP, REF(src))
	REMOVE_TRAIT(assisted_user, TRAIT_NICE_SHOT, REF(src))
	assisted_user.remove_movespeed_modifier(/datum/movespeed_modifier/mod_shooting_assistant)
	assisted_user = null

/obj/item/mod/module/shooting_assistant/proc/on_user_deleted()
	SIGNAL_HANDLER
	clear_mode()

/obj/item/mod/module/shooting_assistant/proc/change_spread(mob/source, obj/item/gun/gun, list/spread)
	SIGNAL_HANDLER
	if(selected_mode == MOD_SHOOT_FAST)
		spread["min"] += MOD_SHOOT_FAST_MIN
		spread["max"] += MOD_SHOOT_FAST_MAX
	else
		spread["min"] += MOD_SHOOT_PRECISE_MIN
		spread["max"] += MOD_SHOOT_PRECISE_MAX
	return MOD_SHOOT_SPREAD_CHANGED

/obj/item/mod/module/shooting_assistant/proc/change_projectile(mob/source, obj/item/projectile/projectile)
	SIGNAL_HANDLER
	projectile.ricochets_max++
	projectile.min_ricochets++
	projectile.ricochet_incidence_leeway = 0
	projectile.accuracy_falloff = 0

/obj/item/mod/module/shooting_assistant/drain_power(amount)
	. = ..()
	if(!.)
		set_mode(MOD_SHOOT_OFF)

/obj/item/mod/module/shooting_assistant/on_suit_activation()
	apply_mode()

/obj/item/mod/module/shooting_assistant/on_suit_deactivation()
	clear_mode()

/obj/item/mod/module/shooting_assistant/on_unequip()
	clear_mode()

/obj/item/mod/module/shooting_assistant/on_uninstall(deleting = FALSE, user)
	clear_mode()
	return ..()

/obj/item/mod/module/shooting_assistant/Destroy()
	clear_mode()
	return ..()

/datum/movespeed_modifier/mod_shooting_assistant
	multiplicative_slowdown = 0.5

/obj/item/mod/module/weapon_recall
	name = "MOD weapon recall module"
	desc = "Связывает MOD с энергетической катаной. Видимое оружие летит в руки, удалённое телепортируется за дополнительную энергию. Активные перчатки запрещают стрельбу и усиливают броски оружия."
	icon = 'icons/obj/clothing/modsuit/mod_modules_whitemoon.dmi'
	icon_state = "recall"
	module_type = MODULE_USABLE
	removable = FALSE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 2
	cooldown_time = 0.5 SECONDS
	required_modpart_index = MOD_PART_GLOVES
	mod_module_flags = MOD_MODULE_SECURITY
	incompatible_modules = list(/obj/item/mod/module/weapon_recall)
	var/obj/item/linked_weapon
	var/mob/living/carbon/human/recall_user

/obj/item/mod/module/weapon_recall/on_suit_activation()
	return on_activation()

/obj/item/mod/module/weapon_recall/on_activation()
	clear_user()
	if(!..())
		return FALSE
	recall_user = mod.wearer
	ADD_TRAIT(recall_user, TRAIT_NOGUNS, REF(src))
	ADD_TRAIT(recall_user, TRAIT_MOD_TOSS_GUN, REF(src))
	RegisterSignal(recall_user, COMSIG_PARENT_QDELETING, PROC_REF(on_user_deleted))
	return TRUE

/obj/item/mod/module/weapon_recall/on_suit_deactivation()
	clear_user()

/obj/item/mod/module/weapon_recall/on_deactivation()
	clear_user()
	return ..()

/obj/item/mod/module/weapon_recall/on_unequip()
	clear_user()

/obj/item/mod/module/weapon_recall/on_uninstall(deleting = FALSE, user)
	clear_user()
	unlink_weapon()
	return ..()

/obj/item/mod/module/weapon_recall/Destroy()
	clear_user()
	unlink_weapon()
	return ..()

/obj/item/mod/module/weapon_recall/proc/clear_user()
	if(!recall_user)
		return
	UnregisterSignal(recall_user, COMSIG_PARENT_QDELETING)
	REMOVE_TRAIT(recall_user, TRAIT_NOGUNS, REF(src))
	REMOVE_TRAIT(recall_user, TRAIT_MOD_TOSS_GUN, REF(src))
	recall_user = null

/obj/item/mod/module/weapon_recall/proc/on_user_deleted()
	SIGNAL_HANDLER
	clear_user()

/obj/item/mod/module/weapon_recall/on_use()
	if(!mod?.is_active() || !check_required_modpart() || !..())
		return FALSE
	if(!linked_weapon)
		var/obj/item/weapon = mod.wearer.is_holding_item_of_type(/obj/item/energy_katana)
		if(!weapon)
			balloon_alert(mod.wearer, "возьмите энергетическую катану")
			return FALSE
		return set_weapon(weapon)
	if(mod.wearer.contains_atom(linked_weapon))
		balloon_alert(mod.wearer, "оружие уже при вас")
		return FALSE
	var/turf/location = get_turf(linked_weapon)
	if(!location)
		return FALSE
	var/distance = max(1, get_dist(mod.wearer, location))
	var/in_view = (linked_weapon in view(mod.wearer))
	if(!in_view && !drain_power(use_power_cost * distance))
		balloon_alert(mod.wearer, "недостаточно энергии")
		return FALSE
	linked_weapon.forceMove(location)
	if(!in_view || location == get_turf(mod.wearer))
		return recall_weapon()
	do_sparks(MOD_RECALL_SPARKS, FALSE, linked_weapon)
	return linked_weapon.throw_at(mod.wearer, distance + 1, linked_weapon.throw_speed, mod.wearer)

/obj/item/mod/module/weapon_recall/proc/set_weapon(obj/item/weapon)
	if(!istype(weapon, /obj/item/energy_katana))
		return FALSE
	unlink_weapon()
	linked_weapon = weapon
	RegisterSignal(weapon, COMSIG_MOVABLE_IMPACT, PROC_REF(catch_weapon))
	RegisterSignal(weapon, COMSIG_PARENT_QDELETING, PROC_REF(on_weapon_deleted))
	balloon_alert(mod?.wearer, "оружие привязано")
	return TRUE

/obj/item/mod/module/weapon_recall/proc/unlink_weapon()
	UnregisterSignal(linked_weapon, list(COMSIG_MOVABLE_IMPACT, COMSIG_PARENT_QDELETING))
	linked_weapon = null

/obj/item/mod/module/weapon_recall/proc/on_weapon_deleted()
	SIGNAL_HANDLER
	unlink_weapon()

/obj/item/mod/module/weapon_recall/proc/catch_weapon(obj/item/weapon, atom/target)
	SIGNAL_HANDLER
	if(weapon != linked_weapon || target != mod?.wearer || !mod.is_active() || !check_required_modpart())
		return
	INVOKE_ASYNC(src, PROC_REF(recall_weapon))
	return COMPONENT_MOVABLE_IMPACT_NEVERMIND

/obj/item/mod/module/weapon_recall/proc/recall_weapon()
	if(!linked_weapon || !mod?.is_active() || !check_required_modpart())
		return FALSE
	linked_weapon.forceMove(get_turf(mod.wearer))
	if(!mod.wearer.put_in_hands(linked_weapon))
		mod.wearer.equip_to_slot_if_possible(linked_weapon, ITEM_SLOT_BELT, disable_warning = TRUE)
	do_sparks(MOD_RECALL_SPARKS, FALSE, linked_weapon)
	return TRUE

/obj/item/mod/module/dispenser/ninja
	name = "MOD ninja star dispenser module"
	desc = "Создаёт электрические сюрикены клана Паука из нанитов костюма."
	dispense_type = /obj/item/throwing_star/stamina/ninja
	cooldown_time = 0.5 SECONDS

/obj/item/mod/module/dna_lock/reinforced
	name = "MOD reinforced DNA lock module"
	desc = "Усиленный ДНК-замок клана Паука, защищённый от ЭМИ. Попытка включить костюм с чужой ДНК уничтожит нарушителя."
	icon_state = "dnalock_ninja"
	use_power_cost = DEFAULT_CHARGE_DRAIN * 0.5
	individual_protect_from_emp = TRUE

/obj/item/mod/module/dna_lock/reinforced/on_mod_activation(datum/source, mob/user)
	. = ..()
	if(. != MOD_CANCEL_ACTIVATE || !isliving(user) || user == mod.ai)
		return .
	var/mob/living/intruder = user
	to_chat(intruder, span_userdanger("Обнаружена чужая ДНК. Протокол клана Паука: уничтожение нарушителя."))
	intruder.investigate_log("has been gibbed by using a MODsuit equipped with [src].", INVESTIGATE_DEATHS)
	intruder.gib()
	return MOD_CANCEL_ACTIVATE
