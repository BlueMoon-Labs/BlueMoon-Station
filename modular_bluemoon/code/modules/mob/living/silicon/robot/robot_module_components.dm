/**
 * Компонент, который должен удаляться при сбросе модуля у киборга
 */
/datum/component/robot_module_component
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/robot_module_component/Initialize(...)
	if(!iscyborg(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_ROBOT_RESET_MODULE, PROC_REF(on_module_reset))
	return ..()

/datum/component/robot_module_component/proc/on_module_reset()
	SIGNAL_HANDLER
	return qdel(src)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/// Goliath hide plating for mining cyborgs — same progression as explorer suit / Ripley mech armor plates.
/datum/component/robot_module_component/mining_cyborg_goliath_plating
	var/amount = 0
	var/maxamount = 3
	var/upgrade_item = /obj/item/stack/sheet/animalhide/goliath_hide
	var/datum/armor/plate_bonus
	var/upgrade_name

/datum/component/robot_module_component/mining_cyborg_goliath_plating/Initialize()
	if(!iscyborg(parent))
		return COMPONENT_INCOMPATIBLE

	plate_bonus = getArmor(melee = 20, bullet = 5, laser = 5, energy = 5, fire = 20)

	var/obj/item/typecast = upgrade_item
	upgrade_name = initial(typecast.name)

	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	return ..()

/datum/component/robot_module_component/mining_cyborg_goliath_plating/Destroy(force, silent)
	var/mob/living/silicon/robot/R = parent
	for(var/i in 1 to amount)
		new upgrade_item(get_turf(R))
	plate_bonus = null
	upgrade_item = null
	return ..()

/datum/component/robot_module_component/mining_cyborg_goliath_plating/UnregisterFromParent()
	var/mob/living/silicon/robot/R = parent
	if(iscyborg(R))
		R.borg_plating_armor = null
	return ..()

/datum/component/robot_module_component/mining_cyborg_goliath_plating/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(amount)
		examine_list += span_notice("Корпус укреплён [amount]/[maxamount] [upgrade_name].")
	else
		examine_list += span_notice("К корпусу можно прикрепить до [maxamount] [upgrade_name] для дополнительной защиты.")

/datum/component/robot_module_component/mining_cyborg_goliath_plating/proc/on_attackby(datum/source, obj/item/I, mob/user, params)
	SIGNAL_HANDLER
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

