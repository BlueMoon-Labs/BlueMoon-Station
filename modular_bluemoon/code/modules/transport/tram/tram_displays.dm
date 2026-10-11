/obj/machinery/transport/destination_sign
	name = "destination sign"
	desc = "Табло, показывающее, куда едет трамвай."
	icon = 'modular_bluemoon/icons/obj/tram/tram_display.dmi'
	icon_state = "desto_blank"
	base_icon_state = "desto"
	use_power = NO_POWER_USE
	idle_power_usage = 120
	active_power_usage = 470
	anchored = TRUE
	density = FALSE
	layer = SIGN_LAYER
	light_range = 0
	init_process = FALSE
	/// What sign face prefixes we have icons for
	var/static/list/available_faces = list(TRAMSTATION_LINE_1)
	/// The sign face we're displaying
	var/sign_face
	var/sign_color = COLOR_DISPLAY_BLUE

/obj/machinery/transport/destination_sign/split/north
	pixel_x = -8

/obj/machinery/transport/destination_sign/split/south
	pixel_x = 8

/obj/machinery/transport/destination_sign/indicator
	icon = 'modular_bluemoon/icons/obj/tram/tram_indicator.dmi'
	icon_state = "indi_blank"
	base_icon_state = "indi"
	use_power = IDLE_POWER_USE
	max_integrity = 50
	light_range = 2
	light_power = 0.7
	light_cone_angle = 115

/obj/item/wallframe/indicator_display
	name = "indicator display frame"
	desc = "Из этого собирается трамвайное табло. Осталось закрепить его на стене."
	icon_state = "indi_blank"
	icon = 'modular_bluemoon/icons/obj/tram/tram_indicator.dmi'
	custom_materials = list(/datum/material/iron = MINERAL_MATERIAL_AMOUNT * 7)
	result_path = /obj/machinery/transport/destination_sign/indicator
	pixel_shift = 32
	inverse = TRUE

/obj/machinery/transport/destination_sign/Initialize(mapload)
	. = ..()
	RegisterSignal(SStransport, COMSIG_TRANSPORT_UPDATED, PROC_REF(update_sign))
	SStransport.displays += src

/obj/machinery/transport/destination_sign/Destroy()
	SStransport.displays -= src
	return ..()

/obj/machinery/transport/destination_sign/indicator/Initialize(mapload, ndir, built)
	. = ..()
	if(ndir)
		setDir(ndir)
	set_light(l_cone_dir = REVERSE_DIR(dir))

/obj/machinery/transport/destination_sign/indicator/setDir(newdir)
	. = ..()
	set_light(l_cone_dir = REVERSE_DIR(dir))

/obj/machinery/transport/destination_sign/indicator/LateInitialize()
	. = ..()
	link_tram()
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(tram)
		update_sign(src, tram, tram.controller_active, tram.controller_status, tram.travel_direction, tram.destination_platform)

/obj/machinery/transport/destination_sign/indicator/examine(mob/user)
	. = ..()
	. += span_notice("Табло снимается со стены [EXAMINE_HINT("гаечным ключом")].")

/obj/machinery/transport/destination_sign/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/atom/drop = drop_location()
		if(disassembled)
			new /obj/item/wallframe/indicator_display(drop)
		else
			new /obj/item/stack/sheet/mineral/titanium(drop, 2)
			new /obj/item/stack/sheet/metal(drop)
			new /obj/item/shard(drop)
			new /obj/item/shard(drop)
	qdel(src)

/obj/machinery/transport/destination_sign/indicator/wrench_act(mob/living/user, obj/item/tool)
	balloon_alert(user, "откручиваем...")
	tool.play_tool_sound(src)
	if(!tool.use_tool(src, user, 6 SECONDS))
		return TRUE
	playsound(loc, 'sound/items/Deconstruct.ogg', 50, vary = TRUE)
	balloon_alert(user, "снято")
	deconstruct(TRUE)
	return TRUE

/obj/machinery/transport/destination_sign/proc/update_sign(datum/source, datum/transport_controller/linear/tram/controller, controller_active, controller_status, travel_direction, obj/effect/landmark/transport/nav_beacon/tram/destination_platform)
	SIGNAL_HANDLER

	if(machine_stat & (NOPOWER|BROKEN))
		sign_face = null
		update_appearance()
		return

	if(controller && (controller.specific_transport_id != configured_transport_id))
		return

	if(!controller || !controller.controller_operational || isnull(destination_platform))
		sign_face = "[base_icon_state]_NIS"
		sign_color = COLOR_DISPLAY_RED
		update_appearance()
		return

	if(controller.controller_status & EMERGENCY_STOP || controller.controller_status & SYSTEM_FAULT)
		sign_face = "[base_icon_state]_NIS"
		sign_color = COLOR_DISPLAY_RED
		update_appearance()
		return

	var/face_line = (controller.specific_transport_id in available_faces) ? controller.specific_transport_id : TRAMSTATION_LINE_1
	sign_face = "[base_icon_state]_[face_line][controller_active][destination_platform.platform_code][travel_direction]"
	sign_color = COLOR_DISPLAY_BLUE

	update_appearance()

/obj/machinery/transport/destination_sign/update_icon_state()
	. = ..()
	if(isnull(sign_face))
		icon_state = "[base_icon_state]_blank"
	else
		icon_state = sign_face

/obj/machinery/transport/destination_sign/update_overlays()
	. = ..()

	if(isnull(sign_face))
		set_light(l_on = FALSE)
		return

	set_light(l_color = sign_color, l_on = TRUE)
	. += emissive_appearance(icon, "[sign_face]_e", alpha = src.alpha, offset_spokesman = src)

/obj/machinery/transport/destination_sign/indicator/power_change()
	. = ..()
	var/datum/transport_controller/linear/tram/tram = transport_ref?.resolve()
	if(!tram)
		return

	update_sign(src, tram, tram.controller_active, tram.controller_status, tram.travel_direction, tram.destination_platform)

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/transport/destination_sign/indicator, 32)
