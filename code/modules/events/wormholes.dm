/datum/round_event_control/wormholes
	name = "Wormholes"
	typepath = /datum/round_event/wormholes
	max_occurrences = 3
	weight = 25
	min_players = 20
	category = EVENT_CATEGORY_ANOMALIES
	severity = DIRECTOR_SEVERITY_MODERATE

/datum/round_event/wormholes
	announce_when = 10
	end_when = 60

	var/list/pick_turfs = list()
	var/list/wormholes = list()
	var/shift_frequency = 3
	var/number_of_wormholes = 400

/datum/round_event/wormholes/setup()
	announce_when = rand(0, 20)
	end_when = rand(40, 80)

/datum/round_event/wormholes/start()
	// Только станционные z: `in world` перебирал турфы ВСЕХ уровней (руины, шахта, резервы),
	// хотя не-станционные тут же отсеивались - на большом мире это секунды лишнего CPU.
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		for(var/turf/open/floor/T in block(locate(1, 1, z), locate(world.maxx, world.maxy, z)))
			CHECK_TICK
			var/area/A = get_area(T)
			if(A.outdoors)
				continue
			pick_turfs += T
	if(!length(pick_turfs))
		return kill()

	for(var/i = 1, i <= number_of_wormholes, i++)
		var/turf/T = pick(pick_turfs)
		wormholes += new /obj/effect/portal/wormhole(T, 0, null, FALSE)

/datum/round_event/wormholes/announce(fake)
	priority_announce("На станции обнаружены пространственно-временные аномалии. Нет никаких дополнительных данных.", "ВНИМАНИЕ: АНОМАЛИЯ", "spanomalies", has_important_message = TRUE)

/datum/round_event/wormholes/tick()
	// Прыжок всех 400 порталов одним куском каждые shift_frequency тиков - это атомарные
	// 100+мс внутри фаера директора (раннер не может прервать tick() посреди). Вместо этого
	// каждый тик прыгает срез в 1/shift_frequency списка: каждый портал по-прежнему прыгает
	// раз в shift_frequency тиков, но кусок в фаере кратно меньше.
	if(!length(wormholes) || !length(pick_turfs))
		return
	var/slice_size = CEILING(length(wormholes) / shift_frequency, 1)
	var/slice_start = (activeFor % shift_frequency) * slice_size
	for(var/i in slice_start + 1 to min(slice_start + slice_size, length(wormholes)))
		var/obj/effect/portal/wormhole/hole = wormholes[i]
		if(QDELETED(hole))
			continue
		var/turf/T = pick(pick_turfs)
		if(T)
			hole.forceMove(T)

/datum/round_event/wormholes/end()
	QDEL_LIST(wormholes)
	wormholes = null

/obj/effect/portal/wormhole
	name = "wormhole"
	desc = "It looks highly unstable; It could close at any moment."
	icon = 'icons/obj/objects.dmi'
	icon_state = "anom"
	mech_sized = TRUE

/obj/effect/portal/wormhole/teleport(atom/movable/M)
	if(iseffect(M))	//sparks don't teleport
		return
	if(M.anchored)
		if(!(ismecha(M) && mech_sized))
			return

	if(ismovable(M))
		if(GLOB.portals.len)
			var/obj/effect/portal/P = pick(GLOB.portals)
			if(P && isturf(P.loc))
				hard_target = P.loc
		if(!hard_target)
			return
		do_teleport(M, hard_target, 1, 1, 0, 0, channel = TELEPORT_CHANNEL_WORMHOLE) ///You will appear adjacent to the beacon
