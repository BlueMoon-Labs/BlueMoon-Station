/obj/structure/chair/wooden_horse
	name = "Wooden horse"
	desc = "It provides pain."
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	var/icon_over = "whorse_over"
	icon_state = "whorse"
	anchored = TRUE
	flags_1 = NODECONSTRUCT_1
	custom_materials = list(/datum/material/iron = 5, /datum/material/wood = 10)
	var/base_lust = LOW_LUST
	var/kit = /obj/item/wooden_horse_kit
	var/timer = 0
	var/list/love = list(
		"Давление на промежность вызывает странное наслаждение!",
		"Боль внизу смешивается с приятным жжением!",
		"Внизу все горит от давления - это слишком приятно!",
		"Давление вызывает приятную дрожь!"
	)
	var/list/warning = list(
		"Деревянное ребро впивается в пах!",
		"Острый угол распирает меня между ног!",
		"Я чувствую нарастающую боль в гениталиях!",
		"Угол жестко впивается в гениталии - я не могу сидеть спокойно!",
	)

/obj/structure/chair/wooden_horse/New()
	..()
	add_overlay(mutable_appearance(icon, icon_over, MOB_LAYER + 1))

/obj/structure/chair/wooden_horse/Destroy()
	STOP_PROCESSING(SSobj,src)
	. = ..()

/obj/structure/chair/wooden_horse/attackby(obj/item/used_item, mob/user, params)
	add_fingerprint(user)
	if(istype(used_item, /obj/item/screwdriver))
		to_chat(user, span_notice("You unscrew the frame and begin to deconstruct it..."))
		playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
		if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
			to_chat(user, span_notice("You disassemble it."))
			new kit (src.loc)
			qdel(src)

/obj/structure/chair/wooden_horse/post_buckle_mob(mob/living/M)
	. = ..()
	timer = 0
	START_PROCESSING(SSobj,src)

/obj/structure/chair/wooden_horse/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj,src)
	. = ..()

/obj/structure/chair/wooden_horse/process(delta_time)
	timer -= delta_time
	if(timer > 0)
		return
	else
		timer = rand(5, 10) // SSobj give seconds as delta_time

	if(has_buckled_mobs())
		for(var/mob/living/carbon/human/M in buckled_mobs)
			var/message = ""
			var/lust = 0
			if(HAS_TRAIT(M, TRAIT_MASO))
				message = span_love(pick(love))
				lust = base_lust
			else
				message = span_warning(pick(warning))
				lust = base_lust / 2
			to_chat(M,message)
			M.handle_post_sex(lust, null, M)
	else
		STOP_PROCESSING(SSobj,src)



/obj/item/wooden_horse_kit
	name = "wooden horse construction kit"
	desc = "Construction requires a screwdriver. Put it on the ground first!"
	icon = 'modular_bluemoon/icons/obj/structures/lewd_devices.dmi'
	icon_state = "kit"
	var/builded = /obj/structure/chair/wooden_horse
	throwforce = 0
	var/unwrapped = 0
	w_class = WEIGHT_CLASS_HUGE

/obj/item/wooden_horse_kit/attackby(obj/item/used_item, mob/user, params)
	add_fingerprint(user)
	if(istype(used_item, /obj/item/screwdriver))
		if (!(item_flags & IN_INVENTORY) && !(item_flags & IN_STORAGE))
			to_chat(user, span_notice("You screw the frame to the floor and begin to construct it..."))
			playsound(loc, "'sound/items/screwdriver.ogg'", 30, 1)
			if(used_item.use_tool(src, user, 8 SECONDS, volume = 50))
				to_chat(user, span_notice("You assemble it."))
				new builded (src.loc)
				qdel(src)
			return
	else
		return ..()




/obj/structure/chair/wooden_horse/vibrator
	name = "Wooden vibro-horse"
	desc = "It provides pain and pleasure."
	icon_state = "vibhorse"
	icon_over = "vibhorse_over"
	var/on = FALSE
	var/datum/looping_sound/lewd/vibrator/medium/soundloop
	kit = /obj/item/wooden_horse_kit/vibrator
	custom_materials = list(/datum/material/iron = 10, /datum/material/wood = 10)
	var/vibro = list(
		"Я чувствую нарастающее наслаждение от вибрации внизу!",
		"Лёгкое жужжание внизу вызывает приятные мурашки!",
		"Вибрация покалывает промежность!"
	)

/obj/structure/chair/wooden_horse/vibrator/Initialize(mapload)
	. = ..()
	soundloop = new(src, FALSE)

/obj/structure/chair/wooden_horse/vibrator/Destroy()
	QDEL_NULL(soundloop)
	. = ..()

/obj/structure/chair/wooden_horse/vibrator/examine(mob/user)
	. = ..()
	. += span_notice("Ctrl-Click to toggle vibrator")

/obj/structure/chair/wooden_horse/vibrator/CtrlClick(mob/user)
	. = ..()
	if(!iscarbon(user) || !in_range(src, user))
		return
	toggle(user)

/obj/structure/chair/wooden_horse/vibrator/process(delta_time)
	timer -= delta_time
	if(timer > 0)
		return
	else
		timer = rand(5, 10) // SSobj give seconds as delta_time

	if(has_buckled_mobs())
		for(var/mob/living/carbon/human/M in buckled_mobs)
			var/message = ""
			var/lust = 0
			if(HAS_TRAIT(M, TRAIT_MASO))
				message = span_love(pick(love))
				lust = base_lust
			else
				message = span_warning(pick(warning))
				lust = base_lust / 2
			to_chat(M,message)
			if(on)
				to_chat(M, span_love(pick(vibro)))
				lust += NORMAL_LUST
			M.handle_post_sex(lust, null, M)
	else
		STOP_PROCESSING(SSobj,src)

/obj/structure/chair/wooden_horse/vibrator/proc/toggle(mob/user)
	on = !on
	if(on)
		soundloop.start()
	else
		soundloop.stop()
	src.balloon_alert(user, "Вибратор [on ? "включен" : "выключен"]")

/obj/item/wooden_horse_kit/vibrator
	name = "wooden vibro-horse construction kit"
	builded = /obj/structure/chair/wooden_horse/vibrator
