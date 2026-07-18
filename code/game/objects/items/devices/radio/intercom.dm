/obj/item/radio/intercom
	name = "station intercom"
	desc = "Talk through this."
	icon_state = "intercom"
	var/icon_off = "intercom-p"
	plane = ABOVE_WALL_PLANE
	anchored = TRUE
	w_class = WEIGHT_CLASS_BULKY
	canhear_range = 2
	var/number = 0
	var/anyai = 1
	var/mob/living/silicon/ai/ai = list()
	dog_fashion = null
	var/unfastened = FALSE

	overlay_speaker_idle = "intercom_s"
	overlay_speaker_active = "intercom_recieve"
	overlay_mic_idle = "intercom_m"
	overlay_mic_active = null

/obj/item/radio/intercom/unscrewed
	unfastened = TRUE

/obj/item/radio/intercom/command
	name = "command intercom"
	desc = "The command's special free-frequency intercom."
	icon_state = "intercom_command"
	icon_off = "intercom_command-p"
	freerange = TRUE
	command = TRUE

/obj/item/radio/intercom/prison
	name = "receive-only intercom"
	desc = "A station intercom. It looks like it has been modified to not broadcast."
	icon_state = "intercom_prison"
	icon_off = "intercom_prison-p"
	prison_radio = TRUE

/obj/item/radio/intercom/syndicate
	name = "syndicate intercom"
	desc = "Talk smack through this."
	icon_state = "intercom_syndicate"
	icon_off = "intercom_syndicate-p"
	syndie = TRUE
	command = TRUE

/obj/item/radio/intercom/inteq
	name = "inteq intercom"
	desc = "A hardened intercom tuned for InteQ frequencies."
	icon_state = "intercom_inteq"
	icon_off = "intercom_inteq-p"

/obj/item/radio/intercom/inteq/Initialize(mapload)
	. = ..()
	make_inteq()

/obj/item/radio/intercom/ratvar
	name = "hierophant intercom"
	desc = "A modified intercom that uses the Hierophant network instead of subspace tech. Can listen to and broadcast on any frequency."
	icon_state = "intercom_ratvar"
	freerange = TRUE

/obj/item/radio/intercom/ratvar/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		to_chat(user, "<span class='danger'>[src] is fastened to the wall with [is_servant_of_ratvar(user) ? "replicant alloy" : "some material you've never seen"], and can't be removed.</span>")
		return //no unfastening!
	. = ..()

//ратварный интерком - поллер по своей природе: он следит за режимом игры,
//на это нет события, поэтому только он и остаётся на SSobj
/obj/item/radio/intercom/ratvar/Initialize(mapload, ndir, building)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/radio/intercom/ratvar/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/radio/intercom/ratvar/process()
	if(!istype(SSticker.mode, /datum/game_mode/clockwork_cult))
		invisibility = INVISIBILITY_OBSERVER
		alpha = 125
		emped = TRUE
	else
		invisibility = initial(invisibility)
		alpha = initial(alpha)
		emped = FALSE
	AreaPowerCheck()

/obj/item/radio/intercom/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)
	var/area/current_area = get_area(src)
	if(current_area)
		RegisterSignal(current_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(AreaPowerCheck))
	AreaPowerCheck()

/obj/item/radio/intercom/examine(mob/user)
	. = ..()
	if(!unfastened)
		. += "<span class='notice'>It's <b>screwed</b> and secured to the wall.</span>"
	else
		. += "<span class='notice'>It's <i>unscrewed</i> from the wall, and can be <b>detached</b>.</span>"

/obj/item/radio/intercom/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(unfastened)
			user.visible_message("<span class='notice'>[user] starts tightening [src]'s screws...</span>", "<span class='notice'>You start screwing in [src]...</span>")
			if(I.use_tool(src, user, 30, volume=50))
				user.visible_message("<span class='notice'>[user] tightens [src]'s screws!</span>", "<span class='notice'>You tighten [src]'s screws.</span>")
				unfastened = FALSE
		else
			user.visible_message("<span class='notice'>[user] starts loosening [src]'s screws...</span>", "<span class='notice'>You start unscrewing [src]...</span>")
			if(I.use_tool(src, user, 40, volume=50))
				user.visible_message("<span class='notice'>[user] loosens [src]'s screws!</span>", "<span class='notice'>You unscrew [src], loosening it from the wall.</span>")
				unfastened = TRUE
		return
	else if(I.tool_behaviour == TOOL_WRENCH)
		if(!unfastened)
			to_chat(user, "<span class='warning'>You need to unscrew [src] from the wall first!</span>")
			return
		user.visible_message("<span class='notice'>[user] starts unsecuring [src]...</span>", "<span class='notice'>You start unsecuring [src]...</span>")
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 80))
			user.visible_message("<span class='notice'>[user] unsecures [src]!</span>", "<span class='notice'>You detach [src] from the wall.</span>")
			playsound(src, 'sound/items/deconstruct.ogg', 50, 1)
			new/obj/item/wallframe/intercom(get_turf(src))
			qdel(src)
		return
	return ..()

/obj/item/radio/intercom/attack_ai(mob/user)
	interact(user)

/obj/item/radio/intercom/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	interact(user)

/obj/item/radio/intercom/interact(mob/user)
	..()
	ui_interact(user, state = GLOB.default_state)

/obj/item/radio/intercom/can_receive(freq, level)
	if(!on)
		return FALSE
	if(wires.is_cut(WIRE_RX))
		return FALSE
	if(!(0 in level))
		var/turf/position = get_turf(src)
		if(isnull(position) || !(position.z in level))
			return FALSE
	if(!src.listening)
		return FALSE
	if(freq == FREQ_SYNDICATE || freq == FREQ_INTEQ || freq == FREQ_PIRATE)
		if(!(src.syndie))
			return FALSE//Prevents broadcast of messages over devices lacking the encryption

	return TRUE


/obj/item/radio/intercom/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, list/spans, message_mode, atom/movable/source)
	. = ..()
	if (message_mode == MODE_INTERCOM)
		return  // Avoid hearing the same thing twice
	if(!anyai && !(speaker in ai))
		return
	..()

///Событийная замена старого поллинга по SSobj: зовётся сигналом
///COMSIG_AREA_POWER_CHANGE области, переездом, ЭМИ и его окончанием.
/obj/item/radio/intercom/proc/AreaPowerCheck(datum/source)
	SIGNAL_HANDLER
	var/area/current_area = get_area(src)
	if(!current_area || emped)
		on = FALSE
	else
		on = current_area.powered(EQUIP)
	icon_state = on ? initial(icon_state) : icon_off

/obj/item/radio/intercom/emp_act(severity)
	. = ..()
	if(!(. & EMP_PROTECT_SELF))
		AreaPowerCheck() //emped уже выставлен родителем - гасим иконку сразу

/obj/item/radio/intercom/end_emp_effect(curremp)
	. = ..()
	AreaPowerCheck() //не включаемся вслепую - сверяемся с питанием области

/obj/item/radio/intercom/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	var/area/old_area = get_area(OldLoc)
	var/area/new_area = get_area(src)
	if(old_area == new_area)
		return
	if(old_area)
		UnregisterSignal(old_area, COMSIG_AREA_POWER_CHANGE)
	if(new_area)
		RegisterSignal(new_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(AreaPowerCheck))
	AreaPowerCheck()

/obj/item/radio/intercom/add_blood_DNA(list/blood_dna)
	return FALSE

//Created through the autolathe or through deconstructing intercoms. Can be applied to wall to make a new intercom on it!
/obj/item/wallframe/intercom
	name = "intercom frame"
	desc = "A ready-to-go intercom. Just slap it on a wall and screw it in!"
	icon_state = "intercom"
	result_path = /obj/item/radio/intercom/unscrewed
	pixel_shift = 29
	inverse = TRUE
	custom_materials = list(/datum/material/iron = 75, /datum/material/glass = 25)
