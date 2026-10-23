/obj/item/mod/module/hacker
	name = "MOD hacker module"
	desc = "Встроенный в перчатки модуль для взлома техники и электрического удара."
	icon_state = "hacker"
	removable = FALSE
	required_modpart_index = MOD_PART_GLOVES
	incompatible_modules = list(/obj/item/mod/module/hacker)
	var/mob/living/carbon/human/hacking_user
	var/door_hack_counter = 0
	var/communication_console_hacked = FALSE
	var/security_console_hacked = FALSE
	var/borg_hacked = FALSE

/obj/item/mod/module/hacker/on_suit_activation()
	bind_wearer()

/obj/item/mod/module/hacker/on_suit_deactivation()
	clear_wearer()

/obj/item/mod/module/hacker/on_equip()
	bind_wearer()

/obj/item/mod/module/hacker/on_unequip()
	clear_wearer()

/obj/item/mod/module/hacker/on_uninstall(deleting = FALSE, user)
	clear_wearer()
	return ..()

/obj/item/mod/module/hacker/Destroy()
	clear_wearer()
	return ..()

/obj/item/mod/module/hacker/proc/bind_wearer()
	if(hacking_user == mod?.wearer)
		return
	clear_wearer()
	if(!ishuman(mod?.wearer) || !mod.is_active())
		return
	hacking_user = mod.wearer
	RegisterSignal(hacking_user, COMSIG_MOB_CLICKON, PROC_REF(on_click))
	RegisterSignal(hacking_user, COMSIG_PARENT_QDELETING, PROC_REF(on_wearer_deleted))

/obj/item/mod/module/hacker/proc/clear_wearer()
	if(!hacking_user)
		return
	UnregisterSignal(hacking_user, list(COMSIG_MOB_CLICKON, COMSIG_PARENT_QDELETING))
	hacking_user = null

/obj/item/mod/module/hacker/proc/on_wearer_deleted()
	SIGNAL_HANDLER
	clear_wearer()

/obj/item/mod/module/hacker/proc/can_hack(mob/living/carbon/human/user, atom/target)
	return !QDELETED(src) && !QDELETED(target) && user == mod?.wearer && mod.is_active() && check_required_modpart() && !user.incapacitated() && user.Adjacent(target)

/obj/item/mod/module/hacker/proc/on_click(mob/living/carbon/human/source, atom/target, params)
	SIGNAL_HANDLER
	var/list/modifiers = params2list(params)
	if(!modifiers[RIGHT_CLICK] || source.get_active_held_item() || !can_hack(source, target))
		return
	if(!target.mod_hack_act(source, src))
		return
	target.add_fingerprint(source)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/mod/module/hacker/proc/pay_power(amount)
	if(!check_power(amount))
		mod.balloon_alert(mod.wearer, "недостаточно энергии")
		return FALSE
	return drain_power(amount)

/obj/item/mod/module/hacker/proc/receive_power(amount)
	if(!mod?.core || amount <= 0)
		return 0
	var/free_charge = mod.core.max_charge_amount() - mod.get_charge()
	if(free_charge <= 0)
		return 0
	return mod.core.add_charge(min(amount, free_charge))

/obj/item/mod/module/hacker/proc/charge_message(atom/source, amount)
	if(!mod?.wearer)
		return
	if(amount > 0)
		to_chat(mod.wearer, span_notice("Получено [amount] единиц энергии от [source]."))
	else
		to_chat(mod.wearer, span_warning("В [source] не осталось доступной энергии."))

/obj/item/mod/module/hacker/proc/drain_cell(mob/living/carbon/human/user, atom/target, obj/item/stock_parts/cell/cell, delay = MOD_HACK_DRAIN_DELAY)
	var/total = 0
	while(can_hack(user, target) && cell?.charge > 0)
		if(!do_after(user, delay, target = target) || !can_hack(user, target) || QDELETED(cell))
			break
		var/amount = min(cell.charge, rand(MOD_HACK_MIN_DRAIN, MOD_HACK_MAX_DRAIN))
		var/received = receive_power(amount)
		if(received <= 0)
			break
		cell.use(received)
		total += received
	charge_message(target, total)
	return total

/obj/item/mod/module/hacker/proc/drain_apc(mob/living/carbon/human/user, obj/machinery/power/apc/target)
	var/drained = drain_cell(user, target, target.cell)
	if(!drained || !can_hack(user, target) || target.obj_flags & EMAGGED)
		return
	target.obj_flags |= EMAGGED
	target.locked = FALSE
	target.update_icon()

/obj/item/mod/module/hacker/proc/drain_loose_cell(mob/living/carbon/human/user, obj/item/stock_parts/cell/target)
	if(drain_cell(user, target, target, MOD_HACK_CELL_DELAY) <= 0)
		return
	target.corrupt()
	target.update_icon()

/obj/item/mod/module/hacker/proc/drain_smes(mob/living/carbon/human/user, obj/machinery/power/smes/target)
	var/total = 0
	while(can_hack(user, target) && target.charge > 0)
		if(!do_after(user, MOD_HACK_DRAIN_DELAY, target = target) || !can_hack(user, target))
			break
		var/amount = min(target.charge, rand(MOD_HACK_MIN_DRAIN, MOD_HACK_MAX_DRAIN))
		var/received = receive_power(amount)
		if(received <= 0)
			break
		target.charge -= received
		total += received
	charge_message(target, total)

/obj/item/mod/module/hacker/proc/drain_cable(mob/living/carbon/human/user, obj/structure/cable/target)
	var/total = 0
	while(can_hack(user, target))
		if(!do_after(user, MOD_HACK_DRAIN_DELAY, target = target) || !can_hack(user, target))
			break
		var/amount = min(target.delayed_surplus(), rand(MOD_HACK_MIN_DRAIN, MOD_HACK_MAX_DRAIN))
		var/received = receive_power(amount)
		if(received <= 0)
			break
		target.add_delayedload(received)
		total += received
	charge_message(target, total)

/obj/item/mod/module/hacker/proc/door_hacked(mob/living/carbon/human/user)
	door_hack_counter++
	var/datum/antagonist/ninja/ninja = user.mind?.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja)
		return
	var/datum/objective/door_jack/objective = locate() in ninja.objectives
	if(objective && door_hack_counter >= objective.doors_required)
		objective.completed = TRUE

/atom/proc/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	return FALSE

/obj/machinery/door/airlock/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!operating && density && hasPower() && !(obj_flags & EMAGGED) && module.pay_power(DEFAULT_CHARGE_DRAIN * 5))
		emag_act(user)
		module.door_hacked(user)
	return TRUE

/obj/machinery/door/window/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!operating && density && hasPower() && !(obj_flags & EMAGGED) && module.pay_power(DEFAULT_CHARGE_DRAIN * 5))
		emag_act(user)
		module.door_hacked(user)
	return TRUE

/obj/machinery/power/apc/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(cell?.charge > 0)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_apc), user, src)
	else
		module.charge_message(src, 0)
	return TRUE

/obj/machinery/power/smes/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(charge > 0)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_smes), user, src)
	else
		module.charge_message(src, 0)
	return TRUE

/obj/item/stock_parts/cell/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(charge > 0)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_loose_cell), user, src)
	else
		module.charge_message(src, 0)
	return TRUE

/obj/structure/cable/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_cable), user, src)
	return TRUE

/obj/item/gun/energy/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(cell?.charge > 0)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_cell), user, src, cell, MOD_HACK_CELL_DELAY)
	else
		module.charge_message(src, 0)
	return TRUE

/obj/vehicle/sealed/mecha/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(cell?.charge > 0)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, drain_cell), user, src, cell)
	else
		module.charge_message(src, 0)
	return TRUE

/mob/living/carbon/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!module.pay_power(DEFAULT_CHARGE_DRAIN * 10))
		return TRUE
	visible_message(span_danger("[user] поражает [src] электрическим разрядом!"))
	Knockdown(MOD_HACK_SHOCK_TIME)
	Jitter(MOD_HACK_SHOCK_TIME)
	do_sparks(3, FALSE, src)
	return TRUE

/obj/machinery/camera/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(isEmpProof())
		module.balloon_alert(user, "камера защищена")
		return TRUE
	if(module.pay_power(DEFAULT_CHARGE_DRAIN * 5))
		emp_act(MOD_HACK_CAMERA_EMP_STRENGTH)
	return TRUE

/obj/machinery/vending/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	INVOKE_ASYNC(src, PROC_REF(mod_hack_inventory), user, module)
	return TRUE

/obj/machinery/vending/proc/mod_hack_inventory(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(shoot_inventory || !wires || !do_after(user, MOD_HACK_VEND_DELAY, target = src) || !module.can_hack(user, src))
		return
	if(!module.pay_power(DEFAULT_CHARGE_DRAIN * 5))
		return
	wires.on_pulse(WIRE_THROW)
	module.balloon_alert(user, "автомат перегружен")

/obj/machinery/door/firedoor/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	open()
	return TRUE

/obj/machinery/button/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(is_operational && !(obj_flags & EMAGGED))
		emag_act(user)
	return TRUE

/mob/living/silicon/robot/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(ROLE_NINJA in faction || module.borg_hacked)
		return TRUE
	INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_robot), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_robot(mob/living/carbon/human/user, mob/living/silicon/robot/target)
	if(!do_after(user, MOD_HACK_ROBOT_DELAY, target = target) || !can_hack(user, target))
		return
	target.faction = list(ROLE_NINJA)
	target.bubble_icon = "syndibot"
	target.UnlinkSelf()
	target.ionpulse = TRUE
	QDEL_NULL(target.laws)
	target.laws = new /datum/ai_laws/ninja_override()
	target.uneq_all()
	target.module.transform_to(pick(
		/obj/item/robot_module/syndicate/spider,
		/obj/item/robot_module/syndicate_medical/spider,
		/obj/item/robot_module/saboteur/spider,
	))
	borg_hacked = TRUE
	var/datum/antagonist/ninja/ninja = user.mind?.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja)
		return
	var/datum/objective/cyborg_hijack/objective = locate() in ninja.objectives
	if(objective)
		objective.completed = TRUE

/obj/machinery/computer/secure_data/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!module.security_console_hacked)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_security_console), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_security_console(mob/living/carbon/human/user, obj/machinery/computer/secure_data/target)
	if(!do_after(user, MOD_HACK_CONSOLE_DELAY, target = target) || !can_hack(user, target))
		return
	target.AI_notify_hack()
	for(var/datum/data/record/security_record in GLOB.data_core.security)
		security_record.fields["criminal"] = SEC_RECORD_STATUS_ARREST
	security_console_hacked = TRUE
	var/datum/antagonist/ninja/ninja = user.mind?.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja)
		return
	var/datum/objective/security_scramble/objective = locate() in ninja.objectives
	if(objective)
		objective.completed = TRUE

/obj/machinery/computer/communications/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!module.communication_console_hacked)
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_communications), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_communications(mob/living/carbon/human/user, obj/machinery/computer/communications/target)
	if(!do_after(user, MOD_HACK_CONSOLE_DELAY, target = target) || !can_hack(user, target))
		return
	target.AI_notify_hack()
	switch(rand(MOD_HACK_EVENT_LONE, MOD_HACK_EVENT_METEORS))
		if(MOD_HACK_EVENT_LONE)
			priority_announce("Зарегистрирован неизвестный сигнал связи.", "[command_name()] Приоритетное оповещение")
			var/datum/round_event_control/operative/loneop_event = new
			loneop_event.runEvent()
		if(MOD_HACK_EVENT_PIRATES)
			priority_announce("Обнаружен сигнал вооружённому кораблю.", "[command_name()] Приоритетное оповещение")
			var/datum/round_event_control/pirates/pirate_event = new
			pirate_event.runEvent()
		if(MOD_HACK_EVENT_METEORS)
			priority_announce("Обнаружен сигнал с запросом на метеоритную атаку.", "[command_name()] Приоритетное оповещение")
			var/datum/round_event_control/meteor_wave/threatening/meteor_event = new
			meteor_event.runEvent()
	communication_console_hacked = TRUE
	var/datum/antagonist/ninja/ninja = user.mind?.has_antag_datum(/datum/antagonist/ninja)
	if(!ninja)
		return
	var/datum/objective/terror_message/objective = locate() in ninja.objectives
	if(objective)
		objective.completed = TRUE

/obj/machinery/rnd/server/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_research), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_research(mob/living/carbon/human/user, obj/machinery/rnd/server/target)
	if(!do_after(user, MOD_HACK_RESEARCH_DELAY, target = target) || !can_hack(user, target))
		return
	target.AI_notify_hack()
	target.stored_research?.modify_points_all(0)
	to_chat(user, span_notice("Исследовательские записи на [target] повреждены."))

/mob/living/simple_animal/bot/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_bot), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_bot(mob/living/carbon/human/user, mob/living/simple_animal/bot/target)
	if(!do_after(user, MOD_HACK_BOT_DELAY, target = target) || !can_hack(user, target))
		return
	if(!pay_power(DEFAULT_CHARGE_DRAIN * 7))
		return
	do_sparks(3, source = target)
	balloon_alert(user, "отойдите!")
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(explosion), target,
		MOD_HACK_BOT_DEVASTATION, MOD_HACK_BOT_HEAVY, MOD_HACK_BOT_LIGHT, MOD_HACK_BOT_FLASH), MOD_HACK_BOT_EXPLOSION_DELAY)

/obj/machinery/recycler/mod_hack_act(mob/living/carbon/human/user, obj/item/mod/module/hacker/module)
	if(!(obj_flags & EMAGGED))
		INVOKE_ASYNC(module, TYPE_PROC_REF(/obj/item/mod/module/hacker, hack_recycler), user, src)
	return TRUE

/obj/item/mod/module/hacker/proc/hack_recycler(mob/living/carbon/human/user, obj/machinery/recycler/target)
	if(!do_after(user, MOD_HACK_RECYCLER_DELAY, target = target) || !can_hack(user, target))
		return
	target.emag_act(user)
