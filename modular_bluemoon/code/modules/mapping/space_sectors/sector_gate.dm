/// gate_id -> список гейтов с этим id. Пар должно быть ровно по два.
GLOBAL_LIST_EMPTY(sector_gates)

/// Сколько времени прибывший через гейт не замечает гейт, на который приземлился.
#define SECTOR_GATE_GRACE (1 SECONDS)

/// Переход между секторами не по краю уровня: два гейта с одним gate_id ведут друг в друга.
/// Пара ищется по id после инициализации, поэтому гейты грузятся в любом порядке.
/obj/effect/sector_gate
	name = "переход между секторами"
	desc = "Пространство здесь ощущается неправильно."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	anchored = TRUE
	layer = MID_LANDMARK_LAYER
	invisibility = INVISIBILITY_ABSTRACT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/gate_id
	var/obj/effect/sector_gate/pair
	/// "[REF(движимое)]" -> время прибытия. Строки, а не ссылки: ссылка на моба тут - готовый harddel.
	var/list/recent_arrivals = list()
	/// Пришёл с карты: у такого гейта пара обязана сложиться сразу.
	var/from_mapload = FALSE

/obj/effect/sector_gate/Initialize(mapload)
	. = ..()
	if(!gate_id)
		log_mapping("Гейт секторов на [AREACOORD(src)] без gate_id - работать не будет.")
		return INITIALIZE_HINT_QDEL
	from_mapload = mapload
	LAZYADD(GLOB.sector_gates[gate_id], src)
	return INITIALIZE_HINT_LATELOAD

/obj/effect/sector_gate/LateInitialize()
	. = ..()
	find_pair()
	var/turf/our_turf = get_turf(src)
	if(our_turf)
		RegisterSignal(our_turf, COMSIG_ATOM_ENTERED, PROC_REF(on_turf_entered))

/obj/effect/sector_gate/Destroy()
	if(gate_id)
		LAZYREMOVE(GLOB.sector_gates[gate_id], src)
	if(pair)
		pair.pair = null
		pair = null
	recent_arrivals = null
	return ..()

/obj/effect/sector_gate/proc/find_pair()
	var/list/candidates = GLOB.sector_gates[gate_id]
	if(length(candidates) != 2)
		//Поставленный посреди раунда гейт найдёт пару сам, с карты она обязана быть сразу.
		if(from_mapload || length(candidates) > 2)
			log_mapping("Гейт секторов '[gate_id]' на [AREACOORD(src)]: гейтов с этим id [length(candidates)], а нужно ровно два.")
		return
	pair = (candidates[1] == src) ? candidates[2] : candidates[1]
	pair.pair = src

/obj/effect/sector_gate/proc/on_turf_entered(datum/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(QDELETED(pair) || QDELETED(arrived) || !ismovable(arrived))
		return
	if(arrived == src || arrived == pair)
		return
	//Только что приехал через нас же, иначе пара перекидывала бы его туда-сюда.
	if(recently_arrived(arrived))
		return
	INVOKE_ASYNC(src, PROC_REF(send_through), arrived)

/obj/effect/sector_gate/proc/recently_arrived(atom/movable/traveller)
	var/key = "[REF(traveller)]"
	var/stamp = recent_arrivals[key]
	if(!stamp)
		return FALSE
	if(world.time - stamp > SECTOR_GATE_GRACE)
		recent_arrivals -= key
		return FALSE
	return TRUE

/obj/effect/sector_gate/proc/mark_arrival(atom/movable/traveller)
	var/key = "[REF(traveller)]"
	recent_arrivals[key] = world.time
	addtimer(CALLBACK(src, PROC_REF(forget_arrival), key), SECTOR_GATE_GRACE + 1, TIMER_UNIQUE|TIMER_OVERRIDE)

/obj/effect/sector_gate/proc/forget_arrival(key)
	recent_arrivals -= key

/// Переносит на клетку за парным гейтом по направлению движения, а если она занята - на сам гейт.
/obj/effect/sector_gate/proc/send_through(atom/movable/traveller)
	if(QDELETED(traveller) || QDELETED(pair))
		return

	var/turf/exit_turf = get_step(pair, traveller.dir)
	if(!exit_turf || exit_turf.is_blocked_turf(TRUE))
		exit_turf = get_turf(pair)
	if(!exit_turf)
		return

	pair.mark_arrival(traveller)
	//Дрейф переживает перенос: пролетающего мимо переход не должен останавливать.
	var/drift = traveller.inertia_dir
	var/heading = traveller.dir
	traveller.forceMove(exit_turf)
	traveller.setDir(heading)
	traveller.inertia_dir = drift

#undef SECTOR_GATE_GRACE
