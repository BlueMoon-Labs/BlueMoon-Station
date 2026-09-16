/obj/item/kirbyplants
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

/obj/item/kirbyplants/proc/change_visual()
	var/list/trim_states = generate_trim_states()
	var/current = trim_states.Find(icon_state)
	var/next = current ? WRAP(current + 1, 1, length(trim_states) + 1) : pick(trim_states)
	icon_state = trim_states[next]

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