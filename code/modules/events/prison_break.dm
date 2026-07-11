/datum/round_event_control/grey_tide
	name = "Grey Tide"
	typepath = /datum/round_event/grey_tide
	max_occurrences = 1
	min_players = 10
	weight = 45
	category = EVENT_CATEGORY_AI
	severity = DIRECTOR_SEVERITY_MINOR
	family = "door_malf" // общая пауза с Door Runtime: два ивента "все двери сошли с ума" подряд - перебор
	disruption = DIRECTOR_DISRUPTION_DISRUPTIVE

/datum/round_event/grey_tide
	announce_when = 50
	end_when = 20
	var/list/area/areasToOpen = list()
	var/list/potential_areas = list(/area/command,
									/area/engineering,
									/area/medical,
									/area/security,
									/area/cargo,
									/area/science)
	var/severity = 1

/datum/round_event/grey_tide/setup()
	announce_when = rand(50, 60)
	end_when = rand(20, 30)
	severity = rand(1,3)
	for(var/i in 1 to severity)
		var/picked_area = pick_n_take(potential_areas)
		for(var/area/A in world)
			if(istype(A, picked_area))
				areasToOpen += A


/datum/round_event/grey_tide/announce(fake)
	if(areasToOpen && areasToOpen.len > 0)
		if(prob(50))
			priority_announce("Gr3y.T1d3 вирус обнаружен в дверных подпрограммах [station_name()]. Уровень тяжести [severity]. Рекомендуется участие ИИ для решения проблемы.", "Нарушение Безопасности")
		else
			print_command_report("Gr3y.T1d3 вирус обнаружен в дверных подпрограммах [station_name()]. Уровень тяжести [severity]. Рекомендуется участие ИИ для решения проблемы.", "Нарушение Безопасности")
	else
		log_world("ERROR: Could not initate grey-tide. No areas in the list!")
		kill()


/datum/round_event/grey_tide/start()
	for(var/area/A in areasToOpen)
		for(var/obj/machinery/light/L in A)
			L.flicker(10)

/datum/round_event/grey_tide/end()
	for(var/area/A in areasToOpen)
		for(var/obj/O in A)
			if(istype(O, /obj/machinery/power/apc))
				var/obj/machinery/power/apc/temp = O
				temp.overload_lighting()
			else if(istype(O, /obj/structure/closet/secure_closet))
				var/obj/structure/closet/secure_closet/temp = O
				temp.locked = FALSE
				temp.update_icon()
			else if(istype(O, /obj/machinery/door/airlock))
				var/obj/machinery/door/airlock/temp = O
				// critical_machine - двери в критических позициях (камера СМ). id_tag - двери под внешним
				// контроллером шлюзования: турбина, сжигатель, миксинг токсинов, внешние циклы. Распахнуть
				// такую пару - выпустить горящую смесь или космос в отдел, событие так делать не должно.
				if(temp.critical_machine || temp.id_tag)
					continue
				temp.prison_open()
			else if(istype(O, /obj/machinery/door_timer))
				var/obj/machinery/door_timer/temp = O
				temp.timer_end()
