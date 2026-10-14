#define TREND_RISING "rising"
#define TREND_FALLING "falling"

#define DISPLAY_PIXEL_1_W 21
#define DISPLAY_PIXEL_1_Z -2
#define DISPLAY_PIXEL_2_W 16
#define DISPLAY_PIXEL_2_Z -2
#define DISPLAY_BASE_ALPHA 64
#define DISPLAY_PIXEL_ALPHA 96

#define LIGHT_COLOR_NORMAL "#4b4290"

/// Shows how many times the tram ran someone over this shift
/obj/machinery/incident_display
	name = "tram incident display"
	desc = "Табло со счётчиком происшествий с трамваем за смену."
	icon = 'modular_bluemoon/icons/obj/machines/incident_display.dmi'
	icon_state = "display_normal"
	verb_say = "пищит"
	verb_ask = "пиликает"
	verb_exclaim = "трезвонит"
	idle_power_usage = 450
	max_integrity = 150
	integrity_failure = 0.75
	init_process = FALSE
	custom_materials = list(/datum/material/titanium = MINERAL_MATERIAL_AMOUNT * 4, /datum/material/glass = MINERAL_MATERIAL_AMOUNT * 4)
	/// Tram hits digits color
	var/tram_display_color = COLOR_DISPLAY_BLUE
	/// Tram hits
	var/hit_count = 0

/obj/machinery/incident_display/tram

MAPPING_DIRECTIONAL_HELPERS(/obj/machinery/incident_display/tram, 32)

/obj/machinery/incident_display/Initialize(mapload)
	. = ..()
	register_context()

/obj/machinery/incident_display/LateInitialize()
	. = ..()
	RegisterSignal(SStransport, COMSIG_TRAM_COLLISION, PROC_REF(update_tram_count))
	update_tram_count(SStransport, SSpersistence.tram_hits_this_round)

/obj/machinery/incident_display/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	if(held_item?.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM && obj_integrity < max_integrity)
		context[SCREENTIP_CONTEXT_LMB] = "Починить табло"
		return CONTEXTUAL_SCREENTIP_SET

/obj/machinery/incident_display/welder_act(mob/living/user, obj/item/tool)
	if(user.a_intent == INTENT_HARM)
		return FALSE

	if(obj_integrity >= max_integrity && !(machine_stat & BROKEN))
		balloon_alert(user, "чинить нечего!")
		return TRUE

	if(!tool.tool_start_check(user, amount = 0))
		return TRUE

	balloon_alert(user, "чиним табло...")
	if(!tool.use_tool(src, user, 4 SECONDS, volume = 50))
		return TRUE

	balloon_alert(user, "починено")
	obj_integrity = max_integrity
	set_machine_stat(machine_stat & ~BROKEN)
	update_appearance()
	return TRUE

// EMP causes the display to display random numbers or outright break.
/obj/machinery/incident_display/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(prob(50))
		set_machine_stat(machine_stat | BROKEN)
		update_appearance()
		return

	hit_count = rand(1, 99)
	update_appearance()

/obj/machinery/incident_display/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/mineral/titanium(drop_location(), 2)
		new /obj/item/shard(drop_location())
		new /obj/item/shard(drop_location())
	qdel(src)

/**
 * Update the tram hit count on the display
 *
 * Sign receives a signal from SStransport that the tram has hit someone, and updates the count.
 */
/obj/machinery/incident_display/proc/update_tram_count(datum/source, tram_collisions)
	SIGNAL_HANDLER

	hit_count = min(tram_collisions, 199)
	update_appearance()

/obj/machinery/incident_display/on_stat_update(old_value)
	. = ..()
	update_appearance()

/obj/machinery/incident_display/update_appearance(updates = ALL)
	. = ..()
	if(machine_stat & NOPOWER)
		icon_state = "display_normal"
		set_light(l_on = FALSE)
		return

	icon_state = (machine_stat & BROKEN) ? "display_broken" : "display_normal"
	set_light(1.7, 1.5, LIGHT_COLOR_NORMAL, l_on = TRUE)

/obj/machinery/incident_display/update_overlays()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		return

	. += emissive_appearance(icon, "display_emissive", alpha = DISPLAY_BASE_ALPHA, offset_spokesman = src)

	. += mutable_appearance(icon, "overlay_tram")
	. += emissive_appearance(icon, "overlay_tram", alpha = DISPLAY_PIXEL_ALPHA, offset_spokesman = src)

	. += display_digit(hit_count % 10, DISPLAY_PIXEL_1_W, DISPLAY_PIXEL_1_Z)
	. += display_digit(round(hit_count / 10) % 10, DISPLAY_PIXEL_2_W, DISPLAY_PIXEL_2_Z)

	if(hit_count >= 100)
		. += mutable_appearance(icon, "num_100_blue")
		. += emissive_appearance(icon, "num_100_blue", alpha = DISPLAY_BASE_ALPHA, offset_spokesman = src)

	var/trend = hit_count > SSpersistence.tram_hits_last_round ? TREND_RISING : TREND_FALLING
	var/mutable_appearance/trend_overlay = mutable_appearance(icon, trend)
	trend_overlay.color = trend == TREND_RISING ? COLOR_DISPLAY_RED : COLOR_DISPLAY_GREEN
	. += trend_overlay
	. += emissive_appearance(icon, trend, alpha = DISPLAY_PIXEL_ALPHA, offset_spokesman = src)

/// A single display digit and its glow
/obj/machinery/incident_display/proc/display_digit(digit, pixel_w, pixel_z)
	var/mutable_appearance/digit_overlay = mutable_appearance(icon, "num_[digit]")
	var/mutable_appearance/digit_emissive = emissive_appearance(icon, "num_[digit]", alpha = DISPLAY_PIXEL_ALPHA, offset_spokesman = src)
	digit_overlay.color = tram_display_color
	digit_overlay.pixel_x = pixel_w
	digit_emissive.pixel_x = pixel_w
	digit_overlay.pixel_y = pixel_z
	digit_emissive.pixel_y = pixel_z
	return list(digit_overlay, digit_emissive)

/obj/machinery/incident_display/examine(mob/user)
	. = ..()
	if(obj_integrity < max_integrity)
		. += span_notice("Его можно починить [EXAMINE_HINT("сваркой")].")

	. += span_info("Происшествий с трамваем за эту смену: [hit_count].")
	switch(hit_count)
		if(0)
			. += span_info("Потрясающе! Чемпионы безопасности.<br/>")
		if(1)
			. += span_info("Завтра постараемся лучше.<br/>")
		if(2 to 5)
			. += span_info("Есть куда расти.<br/>")
		if(6 to 10)
			. += span_info("Отличная работа! Лучшие люди Нанотрейзен!<br/>")
		if(69)
			. += span_info("Мило.<br/>")
		else
			. += span_info("Невероятно! Наверное, вы читаете это из медотсека.<br/>")

#undef TREND_RISING
#undef TREND_FALLING

#undef DISPLAY_PIXEL_1_W
#undef DISPLAY_PIXEL_1_Z
#undef DISPLAY_PIXEL_2_W
#undef DISPLAY_PIXEL_2_Z
#undef DISPLAY_BASE_ALPHA
#undef DISPLAY_PIXEL_ALPHA

#undef LIGHT_COLOR_NORMAL
