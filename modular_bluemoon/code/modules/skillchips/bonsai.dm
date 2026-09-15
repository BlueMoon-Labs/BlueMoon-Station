// TRAIT_BONSAI (skillchip "Hedge 3") lets you trim live potted plants into new shapes with any sharp item.
/obj/item/kirbyplants
	/// Whether this plant can be trimmed by someone with TRAIT_BONSAI.
	var/trimmable = TRUE

/obj/item/kirbyplants/dead
	trimmable = FALSE

/obj/item/kirbyplants/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(!trimmable || !HAS_TRAIT(user, TRAIT_BONSAI) || !isturf(loc) || !I.get_sharpness())
		return
	to_chat(user, span_notice("You start trimming [src]."))
	if(do_after(user, 3 SECONDS, target = src))
		to_chat(user, span_notice("You finish trimming [src]."))
		change_visual()

/// Cycles the plant sprite to the next one.
/obj/item/kirbyplants/proc/change_visual()
	var/list/trim_states = generate_trim_states()
	var/current = trim_states.Find(icon_state)
	var/next = current ? WRAP(current + 1, 1, length(trim_states) + 1) : pick(trim_states)
	icon_state = trim_states[next]

/// All the potted plant icon states available in the base plants.dmi.
/obj/item/kirbyplants/proc/generate_trim_states()
	. = list()
	for(var/i in 1 to 34)
		var/number
		if(i < 10)
			number = "0[i]"
		else
			number = "[i]"
		. += "plant-[number]"
	. += "applebush"