/datum/orbital_objective/nuclear_bomb
	name = "Ядерное Правосудие"
	var/generated = FALSE
	//The blackbox required to recover.
	var/obj/machinery/nuclearbomb/decomission/nuclear_bomb
	var/obj/item/disk/nuclear/decommission/nuclear_disk
	//Relatively easy mission.
	min_payout = 20 * CARGO_CRATE_VALUE
	max_payout = 40 * CARGO_CRATE_VALUE

/datum/orbital_objective/nuclear_bomb/generate_objective_stuff(turf/chosen_turf)
	generated = TRUE
	if(!nuclear_bomb)
		return
	nuclear_disk = new(chosen_turf)
	nuclear_bomb.target_z = chosen_turf.z
	nuclear_bomb.linked_objective = src

/datum/orbital_objective/nuclear_bomb/get_text()
	. = "Аванпост [station_name] требует немедленного уничтожения, так как хранит в себе информацию, которая не должна попасть в руки прессы. Добудьте диск ядерной аутентификации на аванпосте и взорвите там бомбу, которую мы доставили на ваш мостик."
	if(linked_beacon)
		. += " Станция находится в локации [linked_beacon.name]. Успехов."

/datum/orbital_objective/nuclear_bomb/on_assign(obj/machinery/computer/objective/objective_computer)
	var/turf/open/T
	//WHITE-STEEL PORT: зона /area/cargo/exploration_mission может отсутствовать на карте.
	//Без неё pick(null.get_unobstructed_turfs()) ронял рантайм, а бомба не создавалась вовсе,
	//из-за чего generate_objective_stuff() падал на nuclear_bomb.target_z.
	var/area/A = GLOB.areas_by_type[/area/cargo/exploration_mission]
	if(A)
		var/list/pickable_turfs = A.get_unobstructed_turfs()
		if(length(pickable_turfs))
			T = pick(pickable_turfs)
		else
			T = locate() in shuffle(A.contents)
	if(!T)
		T = get_turf(objective_computer)
	if(!T)
		return
	nuclear_bomb = new /obj/machinery/nuclearbomb/decomission(T)

/datum/orbital_objective/nuclear_bomb/check_failed()
	if((!QDELETED(nuclear_bomb) && !QDELETED(nuclear_disk) && !QDELETED(linked_beacon)) || !generated)
		return FALSE
	return TRUE

//==============
//The disk
//==============

/obj/item/disk/nuclear/decommission
	name = "устаревший диск ядерной аутентификации"
	desc = "Старый, изношенный диск, используемый в устаревшей термоядерной боеголовке X-7. NanoTrasen больше не использует эту модель аутентификации из-за ее плохой безопасности."
	fake = TRUE

/obj/item/disk/nuclear/decommission/ComponentInitialize()
	AddComponent(/datum/component/gps, "AUTH0", TRUE)

//==============
//The bomb
//==============

/obj/machinery/nuclearbomb/decomission
	desc = "Термоядерная бомба для уничтожения станций. Использует старую версию дисков ядерной аутентификации."
	proper_bomb = FALSE
	var/datum/orbital_objective/nuclear_bomb/linked_objective
	var/target_z

	var/obj/item/radio/radio	//	Говорящая бомба!
	var/radio_key = /obj/item/encryptionkey/headset_exp
	var/radio_channel = RADIO_CHANNEL_SCIENCE
	var/radio_talk = TRUE
	var/timer_radio = 10
	var/timer_speed = 1

/obj/machinery/nuclearbomb/decomission/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/gps, "BOMB0", TRUE)

/obj/machinery/nuclearbomb/decomission/Initialize()
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.subspace_transmission = TRUE
	radio.canhear_range = 3
	radio.recalculateChannels()

	GLOB.decomission_bombs += src
	r_code = "[rand(10000, 99999)]"
	print_command_report("Код взрыва ядерной бомбы: [r_code]")
	var/obj/structure/closet/supplypod/pod = podspawn(list(
		"target" = get_turf(src),
		"path" = /obj/structure/closet/supplypod
	))
	forceMove(pod)

/obj/machinery/nuclearbomb/decomission/Destroy()
	. = ..()
	GLOB.decomission_bombs -= src
	QDEL_NULL(radio)

/obj/machinery/nuclearbomb/decomission/process()
	if(z != target_z)
		timing = FALSE
		detonation_timer = null
		countdown?.stop()
		update_icon()
		return
	. = ..()


/obj/machinery/nuclearbomb/decomission/process(delta_time)
	var/msg = "Код активации ядерной бомбы: [r_code]."

	if(radio_talk)
		timer_radio = timer_radio - delta_time * timer_speed

		if(timer_radio < 0)
			radio.talk_into(src, msg, radio_channel)
			timer_radio = 10
			radio_talk = FALSE
	. = ..()


/obj/machinery/nuclearbomb/decomission/disk_check(obj/item/disk/nuclear/D)
	if(istype(D, /obj/item/disk/nuclear/decommission))
		return TRUE
	return FALSE

/obj/machinery/nuclearbomb/decomission/set_safety()
	safety = !safety
	if(safety)
		timing = FALSE
		detonation_timer = null
		countdown.stop()
	update_icon()

/obj/machinery/nuclearbomb/decomission/set_active()
	if(safety)
		to_chat(usr, span_danger("Механизм безопасности включен."))
		return
	timing = !timing
	if(timing)
		detonation_timer = world.time + (timer_set * 10)
		countdown.start()
		priority_announce("Ядерная бомба была запущена в отдалённом секторе, будьте осторожны.",null, 'sound/misc/notice1.ogg', "Priority")
		var/msg = "Инициирован финальный отсчет, до взрыва: [get_time_left()] секунд."
		radio.talk_into(src, msg, radio_channel)
	else
		detonation_timer = null
		countdown.stop()
	update_icon()

/obj/machinery/nuclearbomb/decomission/explode()
	if(z != target_z)
		timing = FALSE
		detonation_timer = null
		countdown?.stop()
		update_icon()
		return
	. = ..()

/obj/machinery/nuclearbomb/decomission/actually_explode()
	SSticker.roundend_check_paused = FALSE
	linked_objective.complete_objective()
	QDEL_NULL(linked_objective.linked_beacon)
	qdel(src)
