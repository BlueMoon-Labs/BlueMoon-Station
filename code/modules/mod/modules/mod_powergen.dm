/obj/item/mod/module/power
	name = "Basic powergen module"
	desc = "Незамысловатый модуль небольшого размера, приспособленный генерировать энергию из топлива"
	module_type = MODULE_TOGGLE
	var/obj/item/stock_parts/cell/mod_cell
	var/generation_rate = MOD_FUELGEN_RATE_GENERIC
	var/generation_amount = 100
	var/use_fuel = TRUE
	var/have_tesla_relay = FALSE
	var/max_fuel_amount = 50
	var/current_fuel_amount = 0
	var/use_fuel_by_step = 1
	var/use_sparks = TRUE
	var/fuel_type = /obj/item/stack/sheet/mineral/plasma
	COOLDOWN_DECLARE(power_generation_cooldown)
	var/powergen_cooldown_time = 5 SECONDS

/obj/item/mod/module/power/on_install()
	. = ..()
	if(!mod)
		return
	mod_cell = mod.get_cell()
	RegisterSignal(mod, COMSIG_CLICK_CTRL_SHIFT, PROC_REF(try_insert_fuel))

/obj/item/mod/module/power/on_uninstall(deleting, user)
	. = ..()
	mod_cell = null
	UnregisterSignal(mod, COMSIG_CLICK_CTRL_SHIFT)

/obj/item/mod/module/power/on_select_use(atom/target)
	. = ..()
	if(!current_fuel_amount || !.)
		return FALSE

/obj/item/mod/module/power/proc/try_insert_fuel(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(!iscarbon(user) || source != mod)
		return

	var/obj/item/item_in_active_hand = user.get_active_held_item()
	if(!item_in_active_hand || !istype(item_in_active_hand, fuel_type))
		return
	insert_fuel(item_in_active_hand, user)

/obj/item/mod/module/power/proc/insert_fuel(obj/item/stack/sheet/mineral/fuel, user)
	if(current_fuel_amount == max_fuel_amount)
		can_generate_power()
		return
	var/amount_fuel_can_be_used = max_fuel_amount

	if(fuel.amount > max_fuel_amount || (fuel.amount - max_fuel_amount) <= 0)
		amount_fuel_can_be_used = fuel.amount

	fuel.use(amount_fuel_can_be_used)
	current_fuel_amount = amount_fuel_can_be_used
	can_generate_power()

/obj/item/mod/module/power/proc/can_generate_power()
	if(!COOLDOWN_FINISHED(src, power_generation_cooldown))
		return FALSE
	if(have_tesla_relay)
		return TRUE
	if(mod || mod.wearer || mod_cell || !QDELETED(mod) || current_fuel_amount)
		return TRUE

/obj/item/mod/module/power/proc/charge_from_neaby_apc()
	return

/obj/item/mod/module/power/proc/generate()
	var/amount_to_recharge = generation_amount * generation_rate
	if(have_tesla_relay)
		charge_from_neaby_apc()
		return
	mod_cell.give(amount_to_recharge)
	current_fuel_amount -= use_fuel_by_step
	COOLDOWN_START(src, power_generation_cooldown, powergen_cooldown_time)
	if(current_fuel_amount <= 0)
		current_fuel_amount = 0

/obj/item/mod/module/power/proc/notify_user()
	//playsound
	if(!mod.wearer || !mod_cell)
		return
	if(use_sparks)
		do_sparks(rand(1,2), FALSE,  mod.drop_location())
	to_chat(mod.wearer, span_nicegreen("Модуль [name] перезарядил батарею в [mod.name], её новый заряд составляет: [mod_cell.percent()]%"))
	if(!current_fuel_amount)
		//playsound
		to_chat(mod.wearer, span_alertwarning("Модуль [name] с тихим жужжанием отключился, из-за недостатка топлива."))
		on_deactivation()


/obj/item/mod/module/power/on_process(delta_time)
	. = ..()
	if(!can_generate_power() || !active)
		return
	generate()
	notify_user()
