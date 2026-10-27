/obj/item/mod/module/pathfinder
	name = "MOD pathfinder module"
	desc = "Позволяет вживить маяк и вызвать к нему MOD. Костюм самостоятельно прокладывает путь, используя собственный доступ, надевается и разворачивает части."
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'
	icon_state = "pathfinder"
	complexity = 1
	module_type = MODULE_USABLE
	allowed_inactive = TRUE
	use_power_cost = DEFAULT_CHARGE_DRAIN * 10
	incompatible_modules = list(/obj/item/mod/module/pathfinder)
	mod_module_flags = MOD_MODULE_SECURITY
	var/obj/item/implant/mod/implant
	var/datum/mod_pathfinder_flight/flight

/obj/item/mod/module/pathfinder/Initialize(mapload)
	. = ..()
	implant = new(src)

/obj/item/mod/module/pathfinder/Destroy()
	QDEL_NULL(flight)
	QDEL_NULL(implant)
	return ..()

/obj/item/mod/module/pathfinder/on_uninstall(deleting = FALSE, user)
	QDEL_NULL(flight)
	return ..()

/obj/item/mod/module/pathfinder/update_icon_state()
	icon_state = implant?.loc == src ? "pathfinder" : "pathfinder_empty"
	return ..()

/obj/item/mod/module/pathfinder/examine(mob/user)
	. = ..()
	var/list/examine_text = .
	examine_text.Insert(length(examine_text), span_notice(implant?.loc == src ? "Примените модуль к человеку, чтобы вживить маяк." : "Маяк находится вне модуля."))

/obj/item/mod/module/pathfinder/attack(mob/living/target, mob/living/user)
	if(!ishuman(target) || implant?.loc != src)
		return
	if(!do_after(user, MOD_PATHFINDER_IMPLANT_TIME, target))
		return
	if(QDELETED(implant) || implant.loc != src || !user.Adjacent(target))
		return
	implant.implant(target, user)

/obj/item/mod/module/pathfinder/on_use()
	if(!..())
		return FALSE
	if(implant?.loc == src)
		return implant.implant(mod.wearer, mod.wearer)
	balloon_alert(mod.wearer, "используйте кнопку импланта")
	return FALSE

/obj/item/mod/module/pathfinder/proc/recall(mob/recaller)
	if(!mod || recaller != implant?.imp_in || !ishuman(recaller))
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_MODULE_TRIGGERED, recaller) & MOD_ABORT_USE)
		return FALSE
	if(flight || mod.wearer || !isturf(mod.loc) || !isturf(recaller.loc))
		balloon_alert(recaller, "костюм занят или недоступен")
		return FALSE
	if(mod.is_open() || mod.is_welded() || mod.is_active() || mod.is_activating() || mod.anchored)
		balloon_alert(recaller, "костюм не готов к полёту")
		return FALSE
	if(mod.z != recaller.z || get_dist(mod, recaller) > MOD_PATHFINDER_RANGE)
		balloon_alert(recaller, "костюм слишком далеко")
		return FALSE
	if(!check_power(use_power_cost))
		balloon_alert(recaller, "костюм обесточен")
		return FALSE
	flight = new(src, recaller)
	balloon_alert(recaller, "костюм вызван")
	return TRUE

/obj/item/mod/module/pathfinder/proc/attach(mob/living/carbon/human/target)
	if(!mod || target != implant?.imp_in || mod.wearer || !target.Adjacent(mod) || !check_power(use_power_cost))
		return FALSE
	var/obj/item/old_item = target.get_item_by_slot(mod.slot_flags)
	if(old_item && !target.dropItemToGround(old_item))
		balloon_alert(target, "освободите слот для костюма")
		return FALSE
	if(!target.equip_to_slot_if_possible(mod, mod.slot_flags, qdel_on_fail = FALSE, disable_warning = TRUE))
		return FALSE
	for(var/obj/item/clothing/mod_part/part as anything in mod.get_mod_parts(include_cell = FALSE))
		if(part.loc != target)
			mod.deploy(target, part)
	drain_power(use_power_cost)
	balloon_alert(target, "костюм доставлен")
	playsound(mod, 'sound/machines/ping.ogg', MOD_PATHFINDER_VOLUME, TRUE)
	return TRUE

/datum/mod_pathfinder_flight
	var/obj/item/mod/module/pathfinder/module
	var/obj/item/mod/control/suit
	var/mob/living/carbon/human/target
	var/obj/item/card/id/id_card
	var/list/path
	var/turf/destination
	var/image/jets
	var/matrix/old_transform
	var/was_flying
	var/could_pick_up
	var/timeout
	var/finding_path = FALSE

/datum/mod_pathfinder_flight/New(obj/item/mod/module/pathfinder/new_module, mob/living/carbon/human/new_target)
	module = new_module
	suit = module.mod
	target = new_target
	id_card = new()
	id_card.access = length(suit.req_access) ? suit.req_access.Copy() : list()
	old_transform = matrix(suit.transform)
	was_flying = suit.movement_type & FLYING
	could_pick_up = suit.interaction_flags_item & INTERACT_ITEM_ATTACK_HAND_PICKUP
	suit.movement_type |= FLYING
	suit.interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP
	jets = image('icons/obj/clothing/modsuit/mod_modules.dmi', icon_state = "mod_jet", layer = LOW_ITEM_LAYER)
	suit.add_overlay(jets)
	RegisterSignal(suit, COMSIG_ATOM_ATTACK_HAND, PROC_REF(block_pickup))
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(on_target_deleted))
	timeout = world.time + MOD_PATHFINDER_TIMEOUT
	START_PROCESSING(SSfastprocess, src)

/datum/mod_pathfinder_flight/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	UnregisterSignal(suit, COMSIG_ATOM_ATTACK_HAND)
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)
	if(suit)
		if(!was_flying)
			suit.movement_type &= ~FLYING
		if(could_pick_up)
			suit.interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP
		suit.cut_overlay(jets)
		suit.transform = old_transform
	if(module?.flight == src)
		module.flight = null
	QDEL_NULL(id_card)
	module = null
	suit = null
	target = null
	jets = null
	old_transform = null
	path = null
	destination = null
	return ..()

/datum/mod_pathfinder_flight/proc/block_pickup()
	SIGNAL_HANDLER
	return COMPONENT_NO_ATTACK_HAND

/datum/mod_pathfinder_flight/proc/on_target_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/mod_pathfinder_flight/proc/can_fly()
	if(QDELETED(module) || QDELETED(suit) || QDELETED(target))
		return FALSE
	if(module.mod != suit || module.implant?.imp_in != target || !isturf(suit.loc) || !isturf(target.loc))
		return FALSE
	if(suit.wearer || suit.anchored || suit.is_open() || suit.is_welded() || suit.is_active() || suit.is_activating())
		return FALSE
	if(suit.z != target.z || get_dist(suit, target) > MOD_PATHFINDER_RANGE || world.time >= timeout)
		return FALSE
	return module.check_power(module.use_power_cost)

/datum/mod_pathfinder_flight/process(delta_time)
	if(finding_path)
		return
	if(!can_fly())
		suit?.balloon_alert(target, "связь с костюмом потеряна")
		qdel(src)
		return
	if(suit.Adjacent(target))
		var/obj/item/mod/module/pathfinder/arrived_module = module
		var/mob/living/carbon/human/arrived_target = target
		qdel(src)
		arrived_module.attach(arrived_target)
		return
	if(!length(path) || destination != get_turf(target))
		finding_path = TRUE
		destination = get_turf(target)
		path = get_path_to(suit, destination, MOD_PATHFINDER_RANGE, mintargetdist = 1, id = id_card, simulated_only = FALSE, cancel_source = src)
		if(QDELETED(src))
			return
		finding_path = FALSE
		if(!can_fly())
			qdel(src)
			return
	if(!length(path))
		suit.balloon_alert(target, "нет пути к маяку")
		qdel(src)
		return
	var/turf/next_step = path[1]
	for(var/obj/machinery/door/door in next_step)
		if(!door.density)
			continue
		if(!door.check_access(id_card))
			path = null
			return
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open))
		return
	var/matrix/rotation = matrix(old_transform)
	rotation.Turn(Get_Angle(suit, target))
	suit.transform = rotation
	if(step_towards(suit, next_step))
		path.Cut(1, 2)
	else
		path = null

/obj/item/implant/mod
	name = "MOD pathfinder implant"
	desc = "Маяк для вызова связанного MOD-костюма."
	actions_types = list(/datum/action/item_action/mod_recall)
	allow_multiple = TRUE
	var/obj/item/mod/module/pathfinder/module

/obj/item/implant/mod/Initialize(mapload)
	. = ..()
	if(!istype(loc, /obj/item/mod/module/pathfinder))
		return INITIALIZE_HINT_QDEL
	module = loc

/obj/item/implant/mod/Destroy()
	if(module)
		QDEL_NULL(module.flight)
		module.implant = null
		module.update_icon_state()
	module = null
	return ..()

/obj/item/implant/mod/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	if(!ishuman(target) || !module)
		return FALSE
	. = ..()
	module.update_icon_state()
	if(.)
		balloon_alert(target, "маяк MOD вживлён")
		playsound(target, 'sound/effects/spray.ogg', MOD_PATHFINDER_VOLUME, TRUE)

/obj/item/implant/mod/removed(mob/living/source, silent = FALSE, special = 0)
	if(module)
		QDEL_NULL(module.flight)
	return ..()

/datum/action/item_action/mod_recall
	name = "Вызвать MOD"
	desc = "Вызывает связанный костюм к маяку. Для полёта закройте панель и оставьте костюм на полу."
	check_flags = AB_CHECK_CONSCIOUS
	background_icon_state = "bg_tech_blue"
	icon_icon = 'icons/mob/actions/actions_mod.dmi'
	button_icon_state = "recall"
	COOLDOWN_DECLARE(recall_cooldown)

/datum/action/item_action/mod_recall/Trigger(trigger_flags)
	if(!IsAvailable() || !COOLDOWN_FINISHED(src, recall_cooldown))
		return FALSE
	var/obj/item/implant/mod/implant = target
	if(!implant.module?.recall(owner))
		return FALSE
	COOLDOWN_START(src, recall_cooldown, MOD_PATHFINDER_COOLDOWN)
	return TRUE
