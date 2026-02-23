/obj/machinery/power/floodlight/lamppost
	name = "lamppost"
	desc = "Освещает окружающее пространство. Или не освещает."
	icon = 'modular_bluemoon/icons/obj/lamppost96x160.dmi'
	icon_state = "base"
	plane = GAME_PLANE
	layer = SPACEVINE_LAYER
	var/number_of_lamps
	var/lamps_active = 0
	pixel_w = -32
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	active_power_usage = 0
	var/lamp_power_usage = 150
	var/list/lamp_lights = list()
	use_power = NO_POWER_USE
	var/has_power = FALSE
	var/last_power_state = TRUE
	var/last_interaction = 0
	var/interaction_cooldown = 5
	var/power_update_delay = 2
	var/light_on_init = TRUE

/obj/machinery/power/floodlight/lamppost/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Альт-клик выключает все активные лампы.</span>"

/obj/machinery/power/floodlight/lamppost/wrench_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/power/floodlight/lamppost/crowbar_act(mob/living/user, obj/item/I)
	return FALSE

/obj/machinery/power/floodlight/lamppost/proc/check_power(var/power_needed)
	. = FALSE
	if(!powernet)
		return
	var/available_power = surplus()
	if(available_power >= power_needed)
		. = TRUE

/obj/machinery/power/floodlight/lamppost/attack_hand(mob/user)
	if(.)
		return
	if(!anchored)
		return
	if(world.time < last_interaction + interaction_cooldown)
		return
	last_interaction = world.time

	playsound(src, 'sound/machines/button4.ogg', 50, TRUE)

	if(lamps_active == number_of_lamps)
		turn_off()
		balloon_alert(user, "выключено")
		return

	var/next_power_usage = lamp_power_usage * (lamps_active + 1)
	if(check_power(next_power_usage))
		lamps_active++
		active_power_usage = next_power_usage
		balloon_alert(user, "щёлк!")
		update_icon()
		adjust_lamppost_light()
		add_load(active_power_usage)
	else
		balloon_alert(user, "нет питания!")

/obj/machinery/power/floodlight/lamppost/proc/turn_off()
	lamps_active = 0
	active_power_usage = 0
	update_icon()
	adjust_lamppost_light()

/obj/machinery/power/floodlight/lamppost/proc/adjust_lamppost_light()
	for(var/i in 1 to lamp_lights.len)
		var/obj/effect/dummy/lighting_obj/light_source = lamp_lights[i]
		if(i <= lamps_active)
			light_source.set_light(6, 1, "#ffde9b")
		else
			light_source.set_light(0, 0, "#ffde9b")

/obj/machinery/power/floodlight/lamppost/Initialize()
	. = ..()
	connect_to_network()
	for(var/i in 1 to number_of_lamps)
		var/obj/effect/dummy/lighting_obj/light_source = new(loc)
		light_source.set_light(0, 0, "#ffde9b")
		lamp_lights += light_source
	update_lamp_positions()

	if(light_on_init)
		addtimer(CALLBACK(src, PROC_REF(try_initial_lighting)), 10)

/obj/machinery/power/floodlight/lamppost/proc/try_initial_lighting()
	var/total_power_needed = lamp_power_usage * number_of_lamps
	if(check_power(total_power_needed))
		lamps_active = number_of_lamps
		active_power_usage = total_power_needed
		adjust_lamppost_light()
		add_load(active_power_usage)

/obj/machinery/power/floodlight/lamppost/proc/update_lamp_positions()
	var/obj/effect/dummy/lighting_obj/light_source
	var/cur_dir = 0
	for (var/i in 1 to length(lamp_lights))
		light_source = lamp_lights[i]
		if (i > 1)
			cur_dir += 90
			if (i == length(lamp_lights))
				cur_dir += 90
		light_source.forceMove(get_step(get_step(src, turn(dir, cur_dir)), turn(dir, cur_dir)))

/obj/machinery/power/floodlight/lamppost/one
	icon_state = "one"
	number_of_lamps = 1

/obj/machinery/power/floodlight/lamppost/two
	icon_state = "two"
	number_of_lamps = 2

/obj/machinery/power/floodlight/lamppost/three
	icon_state = "three"
	number_of_lamps = 3

/obj/machinery/power/floodlight/lamppost/four
	icon_state = "four"
	number_of_lamps = 4

/obj/machinery/power/floodlight/lamppost/sidewalk
	icon_state = "civ"
	number_of_lamps = 4

/obj/machinery/power/floodlight/lamppost/snow/one
	icon_state = "one-snow"
	number_of_lamps = 1

/obj/machinery/power/floodlight/lamppost/snow/two
	icon_state = "two-snow"
	number_of_lamps = 2

/obj/machinery/power/floodlight/lamppost/snow/three
	icon_state = "three-snow"
	number_of_lamps = 3

/obj/machinery/power/floodlight/lamppost/snow/four
	icon_state = "four-snow"
	number_of_lamps = 4

/obj/machinery/power/floodlight/lamppost/snow/sidewalk
	icon_state = "civ-snow"
	number_of_lamps = 4

/obj/structure/lamppost/sidewalk/chinese
	icon_state = "chinese"

/obj/machinery/power/floodlight/lamppost/Destroy()
	for(var/obj/effect/dummy/lighting_obj/light_source in lamp_lights)
		qdel(light_source)
	lamp_lights.Cut()
	return ..()

/obj/machinery/power/floodlight/lamppost/setDir(new_dir)
	. = ..()
	update_lamp_positions()

/obj/machinery/power/floodlight/lamppost/process()
	if(!lamps_active)
		return

	if(world.time < last_interaction + power_update_delay)
		return

	if(!check_power(active_power_usage))
		turn_off()
		balloon_alert_to_viewers("нет питания!")
		return

	add_load(active_power_usage)

/obj/machinery/power/floodlight/lamppost/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(!lamps_active)
		balloon_alert(user, "уже выключено")
		return
	turn_off()
	balloon_alert(user, "выключено")
	playsound(src, 'sound/machines/button4.ogg', 50, TRUE)
