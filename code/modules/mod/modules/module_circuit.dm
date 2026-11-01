/obj/item/mod/module/circuit
	name = "MOD circuit adapter module"
	desc = "Переходник для программируемых схем, подключающий их к системам MOD-костюма."
	module_type = MODULE_USABLE
	complexity = 1
	idle_power_cost = DEFAULT_CHARGE_DRAIN * MOD_CIRCUIT_IDLE_MULTIPLIER
	incompatible_modules = list(/obj/item/mod/module/circuit)
	cooldown_time = 0.5 SECONDS
	var/obj/item/electronic_assembly/large/mod_circuit/assembly
	var/obj/item/integrated_circuit/mod_adapter_core/core
	var/list/pinned_chips = list()
	var/list/pin_actions = list()

/obj/item/mod/module/circuit/Initialize(mapload, obj/item/electronic_assembly/large/mod_circuit/printed_assembly)
	. = ..()
	assembly = printed_assembly || new /obj/item/electronic_assembly/large/mod_circuit(src)
	assembly.forceMove(src)
	assembly.module = src
	for(var/obj/item/integrated_circuit/chip as anything in assembly.assembly_components)
		chip.forceMove(src)
	core = locate() in assembly.assembly_components
	if(!core)
		core = new
		assembly.add_component(core)
	core.module = src

/obj/item/mod/module/circuit/Destroy()
	clear_pin_actions()
	pinned_chips = null
	QDEL_NULL(assembly)
	core = null
	return ..()

/obj/item/mod/module/circuit/on_install()
	. = ..()
	core?.bind_mod(mod)

/obj/item/mod/module/circuit/on_uninstall(deleting = FALSE, user)
	clear_pin_actions()
	core?.bind_mod(null)
	return ..()

/obj/item/mod/module/circuit/on_equip()
	refresh_pin_actions()
	core?.sync_state()

/obj/item/mod/module/circuit/on_suit_activation()
	core?.sync_state()

/obj/item/mod/module/circuit/on_suit_deactivation()
	core?.sync_state()

/obj/item/mod/module/circuit/on_unequip()
	clear_pin_actions()
	core?.sync_state()

/obj/item/mod/module/circuit/on_use()
	if(!..())
		return FALSE
	assembly?.interact(mod.wearer)
	return TRUE

/obj/item/mod/module/circuit/attack_self(mob/user)
	if(mod)
		return ..()
	assembly?.interact(user)
	return TRUE

/obj/item/mod/module/circuit/attackby(obj/item/item, mob/user, params)
	if(istype(item, /obj/item/integrated_circuit))
		return assembly?.try_add_component(item, user)
	return ..()

/obj/item/mod/module/circuit/get_configuration()
	. = ..()
	for(var/obj/item/integrated_circuit/mod_action/chip in assembly.assembly_components)
		.[REF(chip)] = add_ui_configuration(chip.name, "bool", chip in pinned_chips)

/obj/item/mod/module/circuit/configure_edit(key, value)
	var/obj/item/integrated_circuit/mod_action/chip = locate(key) in assembly.assembly_components
	if(!istype(chip))
		return
	if(text2num("[value]"))
		pinned_chips |= chip
	else
		pinned_chips -= chip
	refresh_pin_actions()

/obj/item/mod/module/circuit/proc/refresh_pin_actions()
	clear_pin_actions()
	if(!mod?.wearer)
		return
	for(var/obj/item/integrated_circuit/mod_action/chip in pinned_chips)
		if(!(chip in assembly.assembly_components))
			pinned_chips -= chip
			continue
		var/datum/action/cooldown/mod_circuit_action/action = new(chip, src)
		action.Grant(mod.wearer)
		pin_actions[chip] = action

/obj/item/mod/module/circuit/proc/clear_pin_actions()
	for(var/obj/item/integrated_circuit/mod_action/chip in pin_actions)
		qdel(pin_actions[chip])
	pin_actions.Cut()

/obj/item/electronic_assembly/large/mod_circuit
	name = "MOD circuit shell"
	cell_type = null
	can_charge = FALSE
	can_anchor = FALSE
	var/obj/item/mod/module/circuit/module

/obj/item/electronic_assembly/large/mod_circuit/Destroy()
	module = null
	return ..()

/obj/item/electronic_assembly/large/mod_circuit/remove_component(obj/item/integrated_circuit/component)
	. = ..()
	module?.refresh_pin_actions()

/obj/item/electronic_assembly/large/mod_circuit/get_object()
	return module || src

/obj/item/electronic_assembly/large/mod_circuit/get_printed_item()
	if(!module)
		module = new /obj/item/mod/module/circuit(drop_location(), src)
	return module

/obj/item/electronic_assembly/large/mod_circuit/ui_host(mob/user)
	return get_object()

/obj/item/electronic_assembly/large/mod_circuit/ui_status(mob/user, datum/ui_state/state)
	if(!check_interactivity(user))
		return UI_CLOSE
	if(module?.mod)
		return GLOB.conscious_state.can_use_topic(src, user)
	return ..()

/obj/item/electronic_assembly/large/mod_circuit/check_interactivity(mob/user)
	if(!user)
		return FALSE
	if(!module?.mod)
		return user.canUseTopic(get_object(), BE_CLOSE)
	if(user == module.mod.wearer)
		return user.canUseTopic(module.mod, BE_CLOSE)
	return FALSE

/obj/item/electronic_assembly/large/mod_circuit/draw_power(amount)
	return module?.drain_power(amount * GLOB.CELLRATE)

/obj/item/integrated_circuit/mod_adapter_core
	name = "MOD circuit adapter core"
	desc = "Предоставляет схеме состояние MOD и входы управления."
	removable = FALSE
	spawn_flags = IC_SPAWN_RESEARCH
	limit_per_assembly = 1
	inputs = list("Module to Select" = IC_PINTYPE_STRING)
	outputs = list(
		"Wearer" = IC_PINTYPE_REF,
		"Deployed" = IC_PINTYPE_BOOLEAN,
		"Activated" = IC_PINTYPE_BOOLEAN,
		"Selected Module" = IC_PINTYPE_STRING,
		"Deployed Parts" = IC_PINTYPE_LIST,
	)
	activators = list(
		"Toggle Deployment" = IC_PINTYPE_PULSE_IN,
		"Toggle Suit" = IC_PINTYPE_PULSE_IN,
		"Select Module" = IC_PINTYPE_PULSE_IN,
		"On Module Selected" = IC_PINTYPE_PULSE_OUT,
		"On Deploy" = IC_PINTYPE_PULSE_OUT,
		"Finished Toggling" = IC_PINTYPE_PULSE_OUT,
	)
	var/obj/item/mod/module/circuit/module
	var/obj/item/mod/control/bound_mod

/obj/item/integrated_circuit/mod_adapter_core/Destroy()
	bind_mod(null)
	module = null
	return ..()

/obj/item/integrated_circuit/mod_adapter_core/proc/bind_mod(obj/item/mod/control/new_mod)
	if(bound_mod)
		UnregisterSignal(bound_mod, list(
			COMSIG_MOD_MODULE_SELECTED,
			COMSIG_MOD_DEPLOYED,
			COMSIG_MOD_RETRACTED,
			COMSIG_MOD_TOGGLED,
			COMSIG_MOD_MODULE_ADDED,
			COMSIG_MOD_MODULE_REMOVED,
			COMSIG_MOD_WEARER_SET,
			COMSIG_MOD_WEARER_UNSET,
		))
	bound_mod = new_mod
	if(bound_mod)
		RegisterSignal(bound_mod, COMSIG_MOD_MODULE_SELECTED, PROC_REF(on_module_selected))
		RegisterSignal(bound_mod, list(COMSIG_MOD_DEPLOYED, COMSIG_MOD_RETRACTED), PROC_REF(on_parts_changed))
		RegisterSignal(bound_mod, COMSIG_MOD_TOGGLED, PROC_REF(on_suit_toggled))
		RegisterSignal(bound_mod, list(COMSIG_MOD_MODULE_ADDED, COMSIG_MOD_MODULE_REMOVED, COMSIG_MOD_WEARER_SET, COMSIG_MOD_WEARER_UNSET), PROC_REF(on_state_changed))
	sync_state()

/obj/item/integrated_circuit/mod_adapter_core/proc/sync_state()
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_OUTPUT_WEARER, bound_mod?.wearer ? WEAKREF(bound_mod.wearer) : null)
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_OUTPUT_DEPLOYED, bound_mod?.all_parts_deployed() || FALSE)
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_OUTPUT_ACTIVE, bound_mod?.is_active() || FALSE)
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_OUTPUT_SELECTED, bound_mod?.selected_module?.name)
	var/list/deployed_parts = list()
	if(bound_mod)
		for(var/obj/item/part in bound_mod.get_mod_parts(include_cell = FALSE))
			if(part.loc != bound_mod)
				deployed_parts += part.name
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_OUTPUT_PARTS, deployed_parts)
	push_data()

/obj/item/integrated_circuit/mod_adapter_core/do_work(ord)
	if(!bound_mod?.wearer)
		return
	switch(ord)
		if(MOD_CIRCUIT_ACT_TOGGLE_PARTS)
			INVOKE_ASYNC(bound_mod, TYPE_PROC_REF(/obj/item/mod/control, quick_toggle_parts), bound_mod.wearer)
		if(MOD_CIRCUIT_ACT_TOGGLE_SUIT)
			INVOKE_ASYNC(bound_mod, TYPE_PROC_REF(/obj/item/mod/control, toggle_activate), bound_mod.wearer)
		if(MOD_CIRCUIT_ACT_SELECT_MODULE)
			if(!bound_mod.is_active())
				return
			var/module_name = get_pin_data(IC_INPUT, MOD_CIRCUIT_INPUT_MODULE)
			for(var/obj/item/mod/module/selected in bound_mod.modules)
				if(selected.name == module_name && selected.module_type != MODULE_PASSIVE)
					INVOKE_ASYNC(selected, TYPE_PROC_REF(/obj/item/mod/module, on_select))
					return

/obj/item/integrated_circuit/mod_adapter_core/proc/on_module_selected(datum/source, obj/item/mod/module/selected)
	SIGNAL_HANDLER
	sync_state()
	activate_pin(MOD_CIRCUIT_ACT_MODULE_SELECTED)

/obj/item/integrated_circuit/mod_adapter_core/proc/on_parts_changed()
	SIGNAL_HANDLER
	sync_state()
	activate_pin(MOD_CIRCUIT_ACT_PARTS_CHANGED)

/obj/item/integrated_circuit/mod_adapter_core/proc/on_suit_toggled()
	SIGNAL_HANDLER
	sync_state()
	activate_pin(MOD_CIRCUIT_ACT_SUIT_TOGGLED)

/obj/item/integrated_circuit/mod_adapter_core/proc/on_state_changed()
	SIGNAL_HANDLER
	sync_state()

/obj/item/integrated_circuit/mod_action
	name = "MOD circuit action"
	desc = "Кнопка для активации сигнала программируемой схемы из панели способностей."
	spawn_flags = IC_SPAWN_RESEARCH
	outputs = list("User" = IC_PINTYPE_REF)
	activators = list("Pressed" = IC_PINTYPE_PULSE_OUT)

/obj/item/integrated_circuit/mod_action/proc/press(mob/user)
	set_pin_data(IC_OUTPUT, MOD_CIRCUIT_ACTION_OUTPUT_USER, WEAKREF(user))
	push_data()
	activate_pin(MOD_CIRCUIT_ACTION_ACT_PRESSED)

/datum/action/cooldown/mod_circuit_action
	name = "MOD circuit action"
	button_icon = 'icons/mob/actions/actions_items.dmi'
	background_icon_state = "bg_tech_blue"
	button_icon_state = "bci_blank"
	var/obj/item/integrated_circuit/mod_action/chip
	var/obj/item/mod/module/circuit/module

/datum/action/cooldown/mod_circuit_action/New(obj/item/integrated_circuit/mod_action/new_chip, obj/item/mod/module/circuit/new_module)
	. = ..()
	chip = new_chip
	module = new_module
	name = chip.name

/datum/action/cooldown/mod_circuit_action/Destroy()
	chip = null
	module = null
	return ..()

/datum/action/cooldown/mod_circuit_action/IsAvailable()
	return ..() && module?.mod?.is_active() && module.mod.wearer == owner && (chip in module.assembly?.assembly_components)

/datum/action/cooldown/mod_circuit_action/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	chip.press(owner)
	return TRUE
