//Interceptor
//Intercepts a telecomms signal, aka a radio message (;halp getting griff)
//Inputs:
//On (Boolean): If on, the circuit intercepts radio signals. Otherwise it does not. This doesn't affect no pass!
//No pass (Boolean): Decides if the signal will be silently intercepted
//					(false) or also blocked from being sent on the radio (true)
//Outputs:
//Source: name of the mob
//Job: job of the mob
//content: the actual message
//spans: a list of spans, there's not much info about this but stuff like robots will have "robot" span
/obj/item/integrated_circuit/input/tcomm_interceptor
	name = "telecommunication interceptor"
	desc = "This circuit allows for telecomms signals \
	to be fetched prior to being broadcasted."
	extended_desc = "Circuit capable of connecting to station's radio frequencies, \
	and intercept radio signals without having to wait for telecomms to process them. \
	Requires encryption keys to work with departmental radio channels."
	complexity = 6 // Now that this circuit is nerfed into oblivion, high complexity doesn't make much sense
	cooldown_per_use = 0.1
	w_class = WEIGHT_CLASS_SMALL
/*
	inputs = list(
		"intercept" = IC_PINTYPE_BOOLEAN,
		"no pass" = IC_PINTYPE_BOOLEAN
		)
*/
	inputs = list("intercept" = IC_PINTYPE_BOOLEAN)
	outputs = list(
		"source" = IC_PINTYPE_STRING,
		"job" = IC_PINTYPE_STRING,
		"content" = IC_PINTYPE_STRING,
		"spans" = IC_PINTYPE_LIST,
		"frequency" = IC_PINTYPE_NUMBER,
		"encryption keys" = IC_PINTYPE_LIST
		)
	activators = list(
		"on intercept" = IC_PINTYPE_PULSE_OUT
		)
	power_draw_idle = 0
	spawn_flags = IC_SPAWN_RESEARCH
	var/obj/machinery/telecomms/receiver/circuit/receiver
	var/list/encryption_keys = list()
	var/list/freq_whitelist = list()	// Frequencies that we can listen to. Determined by encription keys installed in this circuit.
//	var/list/freq_blacklist = list(FREQ_CENTCOM,FREQ_SYNDICATE,FREQ_INTEQ,FREQ_GHOST_INTEQ,FREQ_PIRATE,FREQ_CTF_RED,FREQ_CTF_BLUE)
	demands_object_input = TRUE
	expected_object_type = /obj/item/encryptionkey

/obj/item/integrated_circuit/input/tcomm_interceptor/Initialize(mapload)
	. = ..()
	receiver = new(src)
	receiver.holder = src

/obj/item/integrated_circuit/input/tcomm_interceptor/Destroy()
	QDEL_NULL(receiver)
//	GLOB.ic_jammers -= src
	return ..()

/obj/item/integrated_circuit/input/tcomm_interceptor/receive_signal(datum/signal/subspace/signal)
	if(!assembly)
		return
	var/turf/T = get_turf(assembly)
	if(!get_pin_data(IC_INPUT, 1) || !istype(signal) || signal.transmission_method != TRANSMISSION_SUBSPACE)	// Basically identical to subspace receiver
		return
	if(!(0 in signal.levels))	// Stupid workaround that allows this circuit to listen to bounced radios from nullspace even when their signal gets received by a broadcaster
		if(!(T.z in signal.levels))
			return
	if(signal.frequency != FREQ_COMMON)	// common freq check
		if(!(signal.frequency in freq_whitelist))	// encryption keys check
			return
	set_pin_data(IC_OUTPUT, 1, signal.data["name"] || "")
	set_pin_data(IC_OUTPUT, 2, signal.data["job"] || "")
	set_pin_data(IC_OUTPUT, 3, signal.data["message"] || "")
	set_pin_data(IC_OUTPUT, 4, signal.data["spans"] || list())
	set_pin_data(IC_OUTPUT, 5, signal.frequency)
	push_data()
	activate_pin(1)

/obj/item/integrated_circuit/input/tcomm_interceptor/on_data_written()
/*
	if(get_pin_data(IC_INPUT, 2))
		GLOB.ic_jammers |= src
		if(get_pin_data(IC_INPUT, 1))
			power_draw_idle = 200
		else
			power_draw_idle = 100
	else
		GLOB.ic_jammers -= src
*/
	if(get_pin_data(IC_INPUT, 1))
		power_draw_idle = 20
	else
		power_draw_idle = 0

/obj/item/integrated_circuit/input/tcomm_interceptor/power_fail()
	set_pin_data(IC_INPUT, 1, 0)
//	set_pin_data(IC_INPUT, 2, 0)

/obj/item/integrated_circuit/input/tcomm_interceptor/disconnect_all()
	set_pin_data(IC_INPUT, 1, 0)
//	set_pin_data(IC_INPUT, 2, 0)
	..()

/obj/item/integrated_circuit/input/tcomm_interceptor/attackby(obj/O, mob/user)
	if(istype(O, /obj/item/encryptionkey))
		if(length(encryption_keys) >= 8)
			to_chat(user, "<span class='notice'>В плате не хватает места, чтобы вставить '[O]'</span>")
			return
		user.transferItemToLoc(O,src)
		encryption_keys += O
		recalculate_channels()
		to_chat(user, "<span class='notice'>Вы вставляете [O] в плату.</span>")
	else
		..()

/obj/item/integrated_circuit/input/tcomm_interceptor/attack_self(mob/user)
	if(encryption_keys.len)
		for(var/i in encryption_keys)
			var/obj/O = i
			O.forceMove(drop_location())
		encryption_keys.Cut()
		to_chat(user, "<span class='notice'>You slide the encryption keys out of the circuit.</span>")
		recalculate_channels()
	else
		to_chat(user, "<span class='notice'>There are no encryption keys to remove from the mechanism.</span>")

/obj/item/integrated_circuit/input/tcomm_interceptor/proc/recalculate_channels()
	freq_whitelist.Cut()
	var/list/weakreffd_ekeys = list()
	for(var/o in encryption_keys)
		var/obj/item/encryptionkey/K = o
		weakreffd_ekeys += WEAKREF(K)
		for(var/i in K.channels)
			freq_whitelist |= GLOB.radiochannels[i]
	set_pin_data(IC_OUTPUT, 6, weakreffd_ekeys)
	push_data()

/obj/item/integrated_circuit/input/quick_button
	name = "quick button"
	desc = "A button that can be used to quickly activate a pin."
	extended_desc = "This circuit adds a button to the assembly that can be easily accessed while the machine is being held. \
		<br>\"grant access to\" can be used to grant access to this button to internal pAIs or MMIs."
	can_be_asked_input = FALSE // Does not summon an input box.
	spawn_flags = IC_SPAWN_RESEARCH
	inputs = list(
		"grant access to" = IC_PINTYPE_REF,
		"button name" = IC_PINTYPE_STRING,
		"button style" = IC_PINTYPE_STRING
	)
	activators = list("on pressed" = IC_PINTYPE_PULSE_OUT)
	var/static/list/button_styles = list("blank","one","two","three","four","five","plus","minus","exclamation","question","cross","info","heart","skull","brain","brain_damage","injection","blood","shield","reaction","network","power","radioactive","electricity","magnetism","scan","repair","id","wireless","say","sleep","bomb")
	var/datum/action/circuit_action/circuit

/obj/item/integrated_circuit/input/quick_button/Initialize(mapload)
	. = ..()
	extended_desc += "<br>Possible button styles: "
	extended_desc += english_list(button_styles)
	circuit = new(src)
	update_button_style()
	RegisterSignal(circuit, COMSIG_ACTION_TRIGGER, PROC_REF(on_action_trigger))

/obj/item/integrated_circuit/input/quick_button/Destroy()
	UnregisterSignal(circuit, COMSIG_ACTION_TRIGGER)
	QDEL_NULL(circuit)
	. = ..()

/obj/item/integrated_circuit/input/quick_button/Moved(atom/OldLoc, Dir)
	. = ..()
	if(istype(loc, /obj/item/electronic_assembly))
		update_button_owner()
	else if(circuit.owner)
		circuit.Remove(circuit.owner)

/obj/item/integrated_circuit/input/quick_button/on_data_written()
	update_button_style()
	update_button_owner()

/obj/item/integrated_circuit/input/quick_button/ext_moved(oldLoc, dir)
	update_button_owner()

/obj/item/integrated_circuit/input/quick_button/proc/update_button_style()
	var/button_name = get_pin_data(IC_INPUT, 2)
	var/button_style = get_pin_data(IC_INPUT, 3)
	circuit.name = button_name ? button_name : "Quick button"
	circuit.button_icon_state = (button_style in button_styles) ? "nanite_[button_style]" : "nanite_power"
	circuit.UpdateButtons()

/obj/item/integrated_circuit/input/quick_button/proc/update_button_owner()
	var/obj/item/user_container = get_pin_data(IC_INPUT, 1)
	var/mob/user
	if(istype(user_container, /obj/item/mmi))
		var/obj/item/mmi/mmi = user_container
		if(!istype(mmi.loc, /obj/item/integrated_circuit/input/mmi_tank)) // Must be inside an MMI tank.
			return

		var/obj/item/integrated_circuit/input/mmi_tank/mmi_tank = mmi.loc
		if(mmi_tank.assembly != assembly) // The MMI must be in the same assembly as the button.
			return

		if(!mmi.brainmob) // How did we get here?
			return

		user = mmi.brainmob
	else if (istype(user_container, /obj/item/paicard))
		var/obj/item/paicard/paicard = user_container
		if(!istype(paicard.loc, /obj/item/integrated_circuit/input/pAI_connector)) // Must be a pAI connector.
			return

		var/obj/item/integrated_circuit/input/pAI_connector/pai_connector = paicard.loc
		if(pai_connector.assembly != assembly) // The pAI connector must be in the same assembly as the button.
			return

		if(!paicard.pai) // Please, don't do this, have a mob.
			return
		user = paicard.pai
	else if(assembly && ismob(assembly.loc)) // Last priority, the location, which means you SHOULD be holding it to gain the button.
		user = assembly.loc
	else if(circuit.owner) // If you're none of these, we take the button back and give it to nobody.
		circuit.Remove(circuit.owner)
		return
	circuit.Grant(user)

/obj/item/integrated_circuit/input/quick_button/proc/on_action_trigger(datum/action/circuit_action, obj/item/source)
	var/button_name = get_pin_data(IC_INPUT, 2)
	to_chat(circuit.owner, span_notice("You press the button labeled '[button_name ? button_name : "Quick button"]'."))
	assembly.balloon_alert(circuit.owner, "activated!")
	activate_pin(1)

/datum/action/circuit_action
	name = "Quick button"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "nanite_power"
