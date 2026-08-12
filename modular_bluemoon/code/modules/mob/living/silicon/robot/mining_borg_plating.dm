/// Goliath hide plating for mining cyborgs — same progression as explorer suit / Ripley mech armor plates.
/datum/component/mining_cyborg_goliath_plating
	var/amount = 0
	var/maxamount = 3
	var/upgrade_item = /obj/item/stack/sheet/animalhide/goliath_hide
	var/datum/armor/plate_bonus
	var/upgrade_name

/datum/component/mining_cyborg_goliath_plating/Initialize()
	if(!iscyborg(parent))
		return COMPONENT_INCOMPATIBLE

	plate_bonus = getArmor(melee = 20, bullet = 5, laser = 5, energy = 5, fire = 20)

	var/obj/item/typecast = upgrade_item
	upgrade_name = initial(typecast.name)

	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_PARENT_PREQDELETED, PROC_REF(on_qdeleting))
	return ..()

/datum/component/mining_cyborg_goliath_plating/UnregisterFromParent()
	var/mob/living/silicon/robot/R = parent
	if(iscyborg(R))
		R.borg_plating_armor = null
	return ..()

/datum/component/mining_cyborg_goliath_plating/proc/on_examine(datum/source, mob/user, list/examine_list)
	if(amount)
		examine_list += span_notice("Корпус укреплён [amount]/[maxamount] [upgrade_name].")
	else
		examine_list += span_notice("К корпусу можно прикрепить до [maxamount] [upgrade_name] для дополнительной защиты.")

/datum/component/mining_cyborg_goliath_plating/proc/on_attackby(datum/source, obj/item/I, mob/user, params)
	if(!istype(I, upgrade_item))
		return
	if(amount >= maxamount)
		to_chat(user, span_warning("Вы не можете улучшить [parent] дальше!"))
		return

	var/mob/living/silicon/robot/R = parent
	if(!istype(R.module, /obj/item/robot_module/miner))
		to_chat(user, span_warning("Только шахтёрские киборги могут быть укреплены шкурой голиафа."))
		return

	if(istype(I, /obj/item/stack))
		if(!I.use(1))
			return
	else
		if(length(I.contents))
			to_chat(user, span_warning("[I] нельзя использовать для бронирования, пока внутри что-то лежит!"))
			return
		qdel(I)

	amount++
	R.borg_plating_armor = (R.borg_plating_armor ? R.borg_plating_armor : getArmor()).attachArmor(plate_bonus)

	R.update_icons()
	to_chat(user, span_info("Вы укрепляете [R], повышая сопротивление урону в ближнем бою, огню и снарядам."))

/datum/component/mining_cyborg_goliath_plating/proc/on_qdeleting(datum/source, force)
	var/mob/living/silicon/robot/R = parent
	for(var/i in 1 to amount)
		new upgrade_item(get_turf(R))

/mob/living/silicon/robot
	var/datum/armor/borg_plating_armor

/mob/living/silicon/robot/getarmor(def_zone, type)
	if(borg_plating_armor && type)
		return borg_plating_armor.getRating(type)
	return ..()

/obj/item/robot_module/miner/rebuild_modules()
	. = ..()
	var/mob/living/silicon/robot/R = loc
	if(!iscyborg(R) || QDELETED(R))
		return
	if(!R.GetComponent(/datum/component/mining_cyborg_goliath_plating))
		R.AddComponent(/datum/component/mining_cyborg_goliath_plating)

/// Borg plasma cutter uses a weaker shot that costs 4x less energy from the cyborg cell.
/obj/item/projectile/plasma/weak/cyborg
	range = 8

/obj/item/ammo_casing/energy/plasma/weak/cyborg
	projectile_type = /obj/item/projectile/plasma/weak/cyborg
	e_cost = 25

/obj/item/gun/energy/plasmacutter/cyborg
	ammo_type = list(/obj/item/ammo_casing/energy/plasma/weak/cyborg)
