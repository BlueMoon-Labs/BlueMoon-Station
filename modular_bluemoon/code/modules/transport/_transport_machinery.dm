/obj/machinery/transport
	armor = list(MELEE = 40, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 45, BIO = 0, RAD = 0, FIRE = 90, ACID = 100)
	max_integrity = 400
	integrity_failure = 0.1
	/// ID of the transport we're associated with for filtering commands
	var/configured_transport_id = TRAMSTATION_LINE_1
	/// weakref of the transport we're associated with
	var/datum/weakref/transport_ref
	var/list/methods_to_fix = list()
	var/list/repair_signals
	var/static/list/how_do_we_fix_it = list(
		"перезагрузить его мультитулом" = TOOL_MULTITOOL,
		"вызвать внеплановую перезагрузку мультитулом" = TOOL_MULTITOOL,
		"подлатать таблицу вызовов мультитулом" = TOOL_MULTITOOL,
		"аккуратно сбросить битую память ломом" = TOOL_CROWBAR,
		"подтянуть заземление гаечным ключом" = TOOL_WRENCH,
		"затянуть винты отвёрткой" = TOOL_SCREWDRIVER,
		"проверить напряжение на проводах мультитулом" = TOOL_MULTITOOL,
		"откусить лишние провода кусачками" = TOOL_WIRECUTTER,
	)
	var/malfunctioning = FALSE
	/// Unique tag of this device in transport logs
	var/id_tag

/obj/machinery/transport/Initialize(mapload)
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()

/// Finds the tram
/obj/machinery/transport/proc/link_tram()
	for(var/datum/transport_controller/linear/tram/tram as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(tram.specific_transport_id != configured_transport_id)
			continue
		transport_ref = WEAKREF(tram)
		log_transport("[id_tag]: Successfuly linked to transport ID [tram.specific_transport_id] [transport_ref]")
		break

	if(isnull(transport_ref))
		log_transport("[id_tag]: Tried to find a transport with ID [configured_transport_id], but failed!")

/obj/machinery/transport/proc/local_fault()
	if(malfunctioning || !isnull(repair_signals))
		return

	generate_repair_signals()
	malfunctioning = TRUE
	set_machine_stat(machine_stat | MAINT)
	update_appearance()

/// All subtypes have the same method of repair for consistency and predictability
/obj/machinery/transport/proc/generate_repair_signals()
	var/list/fix_it_keys = assoc_to_keys(how_do_we_fix_it)
	methods_to_fix += pick_n_take(fix_it_keys)

	LAZYINITLIST(repair_signals)
	for(var/tool_method in methods_to_fix)
		repair_signals += COMSIG_ATOM_TOOL_ACT(how_do_we_fix_it[tool_method])

	if(length(repair_signals))
		RegisterSignal(src, repair_signals, PROC_REF(on_machine_tooled))

/obj/machinery/transport/examine(mob/user)
	. = ..()
	for(var/tool_method in methods_to_fix)
		. += span_warning("Похоже, нужно [EXAMINE_HINT(tool_method)].")
	if(panel_open)
		. += span_notice("Его можно разобрать [EXAMINE_HINT("ломом")].")

/// Signal proc for [COMSIG_ATOM_TOOL_ACT], from a variety of signals, registered on the machinery.
/obj/machinery/transport/proc/on_machine_tooled(obj/machinery/source, mob/living/user, obj/item/tool)
	SIGNAL_HANDLER

	INVOKE_ASYNC(src, PROC_REF(try_fix_machine), source, user, tool)
	return TOOL_ACT_SIGNAL_BLOCKING

/// Attempts a do_after, and if successful, stops the event
/obj/machinery/transport/proc/try_fix_machine(obj/machinery/transport/machine, mob/living/user, obj/item/tool)
	SHOULD_CALL_PARENT(TRUE)

	machine.balloon_alert(user, "чиним...")
	if(!tool.use_tool(machine, user, 7 SECONDS, volume = 50))
		machine.balloon_alert(user, "прервано!")
		return FALSE

	playsound(src, 'sound/machines/synth_yes.ogg', 75)
	machine.balloon_alert(user, "починено!")
	UnregisterSignal(src, repair_signals)
	LAZYNULL(repair_signals)
	methods_to_fix = list()
	malfunctioning = FALSE
	set_machine_stat(machine_stat & ~MAINT)
	update_appearance()
	return TRUE

/obj/machinery/transport/welder_act(mob/living/user, obj/item/tool)
	if(user.a_intent == INTENT_HARM)
		return
	if(obj_integrity >= max_integrity)
		balloon_alert(user, "чинить нечего!")
		return TRUE
	if(!tool.tool_start_check(user, amount = 0))
		return TRUE
	balloon_alert(user, "чиним...")
	if(!tool.use_tool(src, user, 4 SECONDS, volume = 50))
		return TRUE
	balloon_alert(user, "починено")
	obj_integrity = max_integrity
	set_machine_stat(machine_stat & ~BROKEN)
	update_appearance()
	return TRUE
