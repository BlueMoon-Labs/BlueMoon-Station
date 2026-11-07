#define ANTAG_TRAINING_DARK_ROOM_SPOTS 4
#define ANTAG_TRAINING_AMBUSH_RANGE 3
#define ANTAG_TRAINING_AMBUSH_LIGHT 0.2

/obj/structure/antag_training_mannequin
	name = "training mannequin"
	desc = "Учебный манекен в полный рост. В темноте его выдаёт только свет или прикосновение."
	icon = 'icons/obj/cardboard_cutout.dmi'
	icon_state = "cutout_basic"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF

/datum/antag_training_exercise/drill/dark
	sector = "dark"
	human_only = FALSE

/// Связные участки пола сектора между стенами, дверями и окнами; первым идёт участок точки входа.
/datum/antag_training_exercise/drill/dark/proc/rooms(datum/antag_training_sector/dark_sector)
	. = list()
	var/list/seen = list()
	for(var/turf/start as anything in list(dark_sector.spawn_turf()) + dark_sector.turfs)
		if(seen[start] || !room_floor(start))
			continue
		var/list/room = list(start)
		seen[start] = TRUE
		var/index = 0
		while(index < length(room))
			var/turf/current = room[++index]
			for(var/direction in GLOB.cardinals)
				var/turf/next = get_step(current, direction)
				if(next && !seen[next] && dark_sector.arena.inside_bounds(next, dark_sector.bounds) && room_floor(next))
					seen[next] = TRUE
					room += next
		. += list(room)

/datum/antag_training_exercise/drill/dark/proc/room_floor(turf/tile)
	return isopenturf(tile) && !(locate(/obj/machinery/door) in tile) && !(locate(/obj/structure/window) in tile) && !(locate(/obj/structure/grille) in tile)

/datum/antag_training_exercise/drill/dark/find
	id = "dark_find"
	name = "Найди цель в темноте"
	desc = "В случайной комнате тёмного сектора стоит учебный манекен. Найдите его, коснитесь и вернитесь к светящемуся маяку у входа."
	par_time = 1 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/mannequin, /datum/antag_training_exercise_step/drill/entry_return)

/datum/antag_training_exercise/drill/dark/find/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/dark_sector = session.arena.sectors[sector]
	var/turf/entry = dark_sector?.spawn_turf()
	if(!entry)
		return FALSE
	var/list/candidates = list()
	for(var/list/room as anything in rooms(dark_sector))
		if(entry in room)
			continue
		var/list/spots = list()
		for(var/turf/tile as anything in room)
			if(!tile.is_blocked_turf(exclude_mobs = FALSE))
				spots += tile
		if(length(spots) >= ANTAG_TRAINING_DARK_ROOM_SPOTS)
			candidates += list(spots)
	if(!length(candidates))
		return FALSE
	var/datum/antag_training_exercise_run/run = session.exercise_run
	return run.add_prop(new /obj/structure/antag_training_mannequin(pick(pick(candidates)))) && run.add_prop(new /obj/effect/antag_training_beacon/lit(entry))

/datum/antag_training_exercise_step/drill/mannequin
	name = "Найдите манекен"
	hint = "Манекен стоит в одной из комнат за дверями коридоров. Он плотный: на него можно наткнуться и в темноте. Коснитесь его рукой или упритесь в него."

/datum/antag_training_exercise_step/drill/mannequin/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/structure/antag_training_mannequin/mannequin = owner.find_prop(/obj/structure/antag_training_mannequin)
	if(mannequin)
		RegisterSignals(mannequin, list(COMSIG_ATOM_ATTACK_HAND, COMSIG_ATOM_BUMPED), PROC_REF(on_touched))

/datum/antag_training_exercise_step/drill/mannequin/proc/on_touched(datum/source, mob/living/toucher)
	SIGNAL_HANDLER
	if(toucher == participant())
		complete()

/datum/antag_training_exercise_step/drill/entry_return
	name = "Вернитесь ко входу"
	hint = "Вход сектора отмечен светящимся маяком. Дойдите до него."

/datum/antag_training_exercise_step/drill/entry_return/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/body = participant()
	if(body)
		RegisterSignal(body, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/antag_training_exercise_step/drill/entry_return/proc/on_moved(mob/living/source)
	SIGNAL_HANDLER
	if(source == participant() && antag_training_reached(source, run.find_prop(/obj/effect/antag_training_beacon)))
		complete()

/datum/antag_training_exercise/drill/dark/ambush
	id = "dark_ambush"
	name = "Засада"
	difficulty = 2
	par_time = 1 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/knockdown/ambush)

/datum/antag_training_exercise/drill/dark/ambush/New()
	. = ..()
	desc = "Учебная цель ходит по коридору тёмного сектора. Дождитесь её и сбейте с ног. Если вы стоите на свету в [ANTAG_TRAINING_AMBUSH_RANGE] клетках от неё или ближе, цель вас заметит и засада сорвётся."

/datum/antag_training_exercise/drill/dark/ambush/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/dark_sector = session.arena.sectors[sector]
	var/turf/route = dark_sector && runner_route(dark_sector)
	if(!route || !target_slot_free(session))
		return FALSE
	prepare_target(session, "runner", route)
	return TRUE

/// Середина самого длинного прохода с севера на юг у точки входа: бегущая цель ходит только по вертикали.
/datum/antag_training_exercise/drill/dark/ambush/proc/runner_route(datum/antag_training_sector/dark_sector)
	var/list/rooms = rooms(dark_sector)
	if(!length(rooms))
		return null
	var/list/hall = list()
	for(var/turf/tile as anything in rooms[1])
		if(!tile.is_blocked_turf())
			hall[tile] = TRUE
	var/turf/best
	var/best_length = 0
	for(var/turf/start as anything in hall)
		if(hall[get_step(start, SOUTH)])
			continue
		var/run_length = 0
		var/turf/current = start
		while(hall[current])
			run_length++
			current = get_step(current, NORTH)
		if(run_length > best_length)
			best = start
			best_length = run_length
	if(best)
		return locate(best.x, best.y + round(best_length / 2), best.z)

/datum/antag_training_exercise_step/drill/knockdown/ambush
	name = "Сбейте цель с ног из засады"
	hint = "Встаньте в темноте у коридора, по которому ходит цель, и ждите её шагов. Фонарь или лампа рядом выдадут вас: бейте вплотную в темноте или издалека дизейблером и болой."

/datum/antag_training_exercise_step/drill/knockdown/ambush/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_target_moved))

/datum/antag_training_exercise_step/drill/knockdown/ambush/proc/on_target_moved(mob/living/source)
	SIGNAL_HANDLER
	var/mob/living/body = participant()
	var/turf/spot = get_turf(body)
	if(!spot || source.stat != CONSCIOUS || spot.z != source.z || get_dist(spot, source) > ANTAG_TRAINING_AMBUSH_RANGE)
		return
	if(spot.get_lumcount() >= ANTAG_TRAINING_AMBUSH_LIGHT && can_see(source, spot, ANTAG_TRAINING_AMBUSH_RANGE))
		run.finish(FALSE, "цель заметила вас на свету")

#undef ANTAG_TRAINING_DARK_ROOM_SPOTS
#undef ANTAG_TRAINING_AMBUSH_RANGE
#undef ANTAG_TRAINING_AMBUSH_LIGHT
