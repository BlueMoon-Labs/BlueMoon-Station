#define STARGAZER_RANGE 3 //How many tiles the stargazer can see out to
#define STARGAZER_POWER 7 //How many watts will be produced per second when the stargazer sees starlight

//Stargazer: A very fragile but cheap generator that creates power from starlight.
/obj/structure/destructible/clockwork/stargazer
	name = "stargazer"
	desc = "Большая машина в форме фонаря, изготовленная из тонкой латуни. Она выглядит хрупкой."
	clockwork_desc = "Генератор в форме фонаря, который вырабатывает энергию вблизи звездного света."
	icon_state = "stargazer"
	unanchored_icon = "stargazer_unwrenched"
	max_integrity = 40
	construction_value = 5
	layer = WALL_OBJ_LAYER
	break_message = "<span class='warning'>Хрупкое тело старгейзера разлетается на куски!</span>"
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	light_color = "#DAAA18"
	var/star_light_star_bright = FALSE //If this stargazer can see starlight

/obj/structure/destructible/clockwork/stargazer/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSprocessing, src)

/obj/structure/destructible/clockwork/stargazer/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	. = ..()

/obj/structure/destructible/clockwork/stargazer/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user))
		. += "<span class='nzcrentr_small'>Генерирует <b>[DisplayPower(STARGAZER_POWER)]</b> единиц энергии в секунду, пока наблюдает звёздный свет в радиусе [STARGAZER_RANGE] клеток.</span>"
		. += "<span class='nzcrentr_small'>Он работает только внутри помещения с видом на космос - он не может работать в открытом космосе или снаружи.</span>"
	if(star_light_star_bright)
		. += "[is_servant_of_ratvar(user) ? "<span class='nzcrentr_small'>Он может видеть звездный свет!</span>" : "Он ослепительно сияет!"]"

/obj/structure/destructible/clockwork/stargazer/process()
	star_light_star_bright = check_starlight()
	if(star_light_star_bright)
		adjust_clockwork_power(STARGAZER_POWER)

/obj/structure/destructible/clockwork/stargazer/update_anchored(mob/living/user, damage)
	. = ..()
	star_light_star_bright = check_starlight()

/obj/structure/destructible/clockwork/stargazer/proc/check_starlight()
	var/old_status = star_light_star_bright
	var/has_starlight
	if(!anchored)
		has_starlight = FALSE
	else
		for(var/turf/T in view(3, src))
			if(isspaceturf(T))
				has_starlight = TRUE
				break
	if(has_starlight && anchored)
		var/area/A = get_area(src)
		if(A.outdoors || A.map_name == "Space" || !(A?.area_flags & CULT_PERMITTED))
			has_starlight = FALSE
	if(old_status != has_starlight)
		if(has_starlight)
			visible_message("<span class='nzcrentr_small'>[src] жужжит и ослепительно сияет!</span>")
			playsound(src, 'sound/machines/clockcult/stargazer_activate.ogg', 50, TRUE)
			add_overlay("stargazer_light")
			set_light(1.5, 5)
		else
			if(anchored) //We lost visibility somehow
				visible_message("<span class='danger'>[src] мерцает, и становится темным.</span>")
			else
				visible_message("<span class='danger'>[src] с тихим свистом он принимает менее громоздкую форму.</span>")
			cut_overlays()
			set_light(0)
	return has_starlight
