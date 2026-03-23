// BLUEMOON ADD START редко возникает звук эмбиента сталкера
/obj/machinery/atmospherics/components/trinary/nuclear_reactor
	var/stalker_sound_timer

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/start_up()
	. = ..()
	stalker_schedule_sound()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/shut_down()
	deltimer(stalker_sound_timer)
	stalker_sound_timer = null
	. = ..()

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/meltdown()
	deltimer(stalker_sound_timer)
	stalker_sound_timer = null
	. = ..()

/// Планирует следующее воспроизведение атмосферного звука через случайный промежуток 15–30 минут.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/stalker_schedule_sound()
	var/delay = rand(15 MINUTES, 30 MINUTES)
	stalker_sound_timer = addtimer(CALLBACK(src, PROC_REF(stalker_play_sound)), delay, TIMER_DELETE_ME | TIMER_STOPPABLE)

/// Воспроизводит звук и сразу планирует следующий.
/obj/machinery/atmospherics/components/trinary/nuclear_reactor/proc/stalker_play_sound()
	if(!has_fuel() || slagged)
		stalker_schedule_sound()
		return
	playsound(src, 'sound/ambience/ambistalker.ogg', 18, FALSE, 14)
	stalker_schedule_sound()
// BLUEMOON ADD END

/obj/machinery/atmospherics/components/trinary/nuclear_reactor/syndicate
	id = "reactor_syndicate"
	engineering_channel = "DS-1"
	radio_key = /obj/item/encryptionkey/headset_syndicate/ds1
