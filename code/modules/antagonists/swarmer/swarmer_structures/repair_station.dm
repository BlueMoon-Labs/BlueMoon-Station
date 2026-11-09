#define SWARMER_REPAIR_STATION_DELAY 2 SECONDS
#define SWARMER_REPAIR_STATION_HEAL 5

/obj/structure/swarmer/repair_station
	name = "swarmer repair station"
	desc = "Ремонтная станция \"Свармеров\"."
	icon_state = "repair_station"
	swarmer_examine = "Войти в ремонтную станцию можно с помощью нажатия на него в интенте \"Помощь\"."
	max_integrity = 100
	var/mob/living/simple_animal/occupant
	var/turf/enter_turf
	var/heal_per_tick = SWARMER_REPAIR_STATION_HEAL

/obj/structure/swarmer/repair_station/Destroy(force)
	go_out()
	if(datum_flags & DF_ISPROCESSING)
		STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/swarmer/repair_station/emp_act(severity)
	..()
	if(!occupant)
		return
	if(severity <= 1)
		go_out()

/obj/structure/swarmer/repair_station/update_icon_state()
	icon_state = occupant ? "[initial(icon_state)]_a" : initial(icon_state)

/obj/structure/swarmer/repair_station/update_overlays()
	. = ..()
	if(!occupant)
		return .
	var/image/swarmer_image = image(icon = occupant.icon, icon_state = occupant.icon_state, layer = ABOVE_MOB_LAYER, dir = SOUTH)
	var/image/repair_image = image(icon = 'icons/effects/swarmer.dmi', icon_state = "repair_effect", layer = ABOVE_ALL_MOB_LAYER)
	. += swarmer_image
	. += repair_image

/obj/structure/swarmer/repair_station/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	. = ..()
	if(!.)
		return

	if(occupant)
		swarmer.balloon_alert(swarmer, "занято!")
		return

	swarmer.balloon_alert(swarmer, "входим...")
	if(!do_after(swarmer, SWARMER_REPAIR_STATION_DELAY, src, extra_checks = CALLBACK(src, PROC_REF(check_if_not_busy))))
		swarmer.balloon_alert(swarmer, "сбито!")
		return

	enter_turf = get_turf(swarmer)
	swarmer.forceMove(src)
	occupant = swarmer
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
	START_PROCESSING(SSobj, src)

/obj/structure/swarmer/repair_station/proc/check_if_not_busy()
	return !occupant

/obj/structure/swarmer/repair_station/swarmer_disarm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!occupant)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не починить!")

/obj/structure/swarmer/repair_station/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!occupant)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не открепить!")

/obj/structure/swarmer/repair_station/swarmer_harm_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!occupant)
		return ..()

	swarmer.balloon_alert(swarmer, "занято, не уничтожить!")

/obj/structure/swarmer/repair_station/process(seconds_per_tick)
	if(QDELETED(occupant) || occupant.loc != src)
		occupant = null
		enter_turf = null
		update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
		return PROCESS_KILL

	if(occupant.health == occupant.maxHealth)
		to_chat(occupant, span_notice("Мы полностью вылечены! Выходим из ремонтной станции..."))
		go_out()
		return
	occupant.adjustHealth(-heal_per_tick)

/obj/structure/swarmer/repair_station/relaymove()
	go_out()

/obj/structure/swarmer/repair_station/proc/go_out()
	if(!occupant)
		enter_turf = null
		return
	occupant.forceMove(enter_turf)
	occupant = null
	enter_turf = null
	update_icon(UPDATE_ICON_STATE | UPDATE_OVERLAYS)
	STOP_PROCESSING(SSobj, src)

#undef SWARMER_REPAIR_STATION_DELAY
#undef SWARMER_REPAIR_STATION_HEAL
