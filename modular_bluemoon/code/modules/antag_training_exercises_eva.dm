#define ANTAG_TRAINING_EVA_RESERVE_MOLES 0.5
#define ANTAG_TRAINING_EVA_RESERVE_VOLUME 5
#define ANTAG_TRAINING_EVA_EMPTY_MOLES 0.01
#define ANTAG_TRAINING_EVA_BEACON_RANGE 12

/obj/item/tank/jetpack/oxygen/antag_training_reserve
	name = "reserve jetpack"
	volume = ANTAG_TRAINING_EVA_RESERVE_VOLUME

/obj/item/tank/jetpack/oxygen/antag_training_reserve/Initialize(mapload)
	. = ..()
	desc = "Учебный джетпак с малым запасом: [ANTAG_TRAINING_EVA_RESERVE_MOLES] моль кислорода и на полёт, и на дыхание. С включённой стабилизацией газ уходит на каждый шаг: коротко разгоняйтесь и тормозите, остальное пролетайте по инерции."

/obj/item/tank/jetpack/oxygen/antag_training_reserve/populate_gas()
	air_contents.set_moles(GAS_O2, ANTAG_TRAINING_EVA_RESERVE_MOLES)

/datum/antag_training_exercise/drill/eva
	sector = "eva"

/// Причина провала, если участник нарушил условие упражнения, иначе null.
/datum/antag_training_exercise/drill/eva/proc/violation(datum/antag_training_exercise_step/drill/eva/active, mob/living/carbon/human/body)
	return null

/datum/antag_training_exercise/drill/eva/outpost
	id = "eva_outpost"
	name = "До форпоста"
	desc = "Наденьте скафандр и джетпак, выйдите через шлюз и доберитесь до маяка в форпосте за отведённое время. Магнитные ботинки не включать: только джетпак, инерция и опоры."
	difficulty = 2
	par_time = 90 SECONDS
	time_limit = 3 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/eva/suit, /datum/antag_training_exercise_step/drill/eva/space, /datum/antag_training_exercise_step/drill/eva/beacon/outpost)

/datum/antag_training_exercise/drill/eva/outpost/setup(datum/antag_training_session/session)
	var/datum/antag_training_sector/eva_sector = session.arena.sectors[sector]
	var/turf/goal = eva_sector?.target_turf()
	if(!goal)
		return FALSE
	return session.exercise_run.add_prop(new /obj/effect/antag_training_beacon(goal))

/datum/antag_training_exercise/drill/eva/outpost/violation(datum/antag_training_exercise_step/drill/eva/active, mob/living/carbon/human/body)
	if(body.shoes?.negates_gravity())
		return "включены магнитные ботинки, а до форпоста нужно добраться без них"

/datum/antag_training_exercise/drill/eva/reserve
	id = "eva_reserve"
	name = "Возврат на остатке"
	difficulty = 3
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/eva/suit/reserve, /datum/antag_training_exercise_step/drill/eva/beacon, /datum/antag_training_exercise_step/drill/eva/chamber)

/datum/antag_training_exercise/drill/eva/reserve/New()
	. = ..()
	desc = "В выданном джетпаке всего [ANTAG_TRAINING_EVA_RESERVE_MOLES] моль кислорода на полёт и дыхание. Долетите до маяка в [ANTAG_TRAINING_EVA_BEACON_RANGE] клетках от шлюза и вернитесь в шлюзовую камеру, пока газ не кончился. Джетпак не менять."

/datum/antag_training_exercise/drill/eva/reserve/setup(datum/antag_training_session/session)
	if(!breathable(session.current_body))
		return "джетпак выдаётся там, где есть воздух: вернитесь в комнату снаряжения"
	var/datum/antag_training_sector/eva_sector = session.arena.sectors[sector]
	var/list/airlock = eva_sector && entry_airlock(eva_sector)
	if(!airlock)
		return FALSE
	var/turf/beacon_spot = beacon_spot(eva_sector, airlock["outer"])
	if(!beacon_spot)
		return FALSE
	var/datum/antag_training_exercise_run/run = session.exercise_run
	var/datum/antag_training_exercise_step/drill/eva/chamber/return_step = locate() in run.steps
	return_step.chamber = airlock["chamber"]
	return run.add_prop(new /obj/item/tank/jetpack/oxygen/antag_training_reserve(get_turf(session.current_body))) && run.add_prop(new /obj/effect/antag_training_beacon(beacon_spot))

/// Выданный джетпак удаляется вместе с прогоном: тот, кто летит и дышит из него, переносится к входу сектора.
/datum/antag_training_exercise/drill/eva/reserve/teardown(datum/antag_training_session/session)
	var/mob/living/carbon/human/body = session.current_body
	var/obj/item/tank/jetpack/jetpack = session.exercise_run?.find_prop(/obj/item/tank/jetpack)
	var/datum/antag_training_sector/eva_sector = session.arena?.sectors[sector]
	var/turf/entry = eva_sector?.spawn_turf()
	if(!istype(body) || !jetpack || !entry || (body.back != jetpack && body.internal != jetpack) || breathable(body))
		return
	body.forceMove(entry)
	to_chat(body, span_notice("Выданный джетпак убран вместе с упражнением, поэтому вы перенесены к входу сектора."))

/datum/antag_training_exercise/drill/eva/reserve/proc/breathable(mob/living/body)
	var/turf/spot = get_turf(body)
	var/datum/gas_mixture/air = spot?.return_air()
	return air && air.return_pressure() >= WARNING_LOW_PRESSURE

/datum/antag_training_exercise/drill/eva/reserve/violation(datum/antag_training_exercise_step/drill/eva/active, mob/living/carbon/human/body)
	if(istype(active, /datum/antag_training_exercise_step/drill/eva/suit))
		return null
	var/obj/item/tank/jetpack/jetpack = active.run.find_prop(/obj/item/tank/jetpack)
	if(!jetpack || body.back != jetpack || body.internal != jetpack)
		return "выданный джетпак снят или дыхание переключено на другой баллон"
	if(jetpack.air_contents.total_moles() < ANTAG_TRAINING_EVA_EMPTY_MOLES)
		return "газ в джетпаке кончился до возвращения"

/// Шлюз у входа в сектор: ближняя к точке входа пара связанных дверей и клетки камеры между ними.
/datum/antag_training_exercise/drill/eva/reserve/proc/entry_airlock(datum/antag_training_sector/eva_sector)
	var/turf/entry = eva_sector.spawn_turf()
	var/obj/machinery/door/airlock/inner
	for(var/turf/tile as anything in eva_sector.turfs)
		for(var/obj/machinery/door/airlock/door in tile)
			if(door.cyclelinkedairlock && (!inner || get_dist(entry, door) < get_dist(entry, inner)))
				inner = door
	if(!inner)
		return null
	var/turf/outer = get_turf(inner.cyclelinkedairlock)
	var/list/chamber = get_line(inner, outer) - list(get_turf(inner), outer)
	if(!length(chamber))
		return null
	return list("outer" = outer, "chamber" = chamber)

/// Клетка открытого космоса без опор в ANTAG_TRAINING_EVA_BEACON_RANGE от внешней двери шлюза, а если такой нет - самая дальняя ближе.
/datum/antag_training_exercise/drill/eva/reserve/proc/beacon_spot(datum/antag_training_sector/eva_sector, turf/outer)
	var/list/exact = list()
	var/turf/fallback
	for(var/turf/open/space/tile in eva_sector.turfs)
		if(locate(/obj) in tile)
			continue
		var/distance = get_dist(tile, outer)
		if(distance == ANTAG_TRAINING_EVA_BEACON_RANGE)
			exact += tile
		else if(distance < ANTAG_TRAINING_EVA_BEACON_RANGE && (!fallback || distance > get_dist(fallback, outer)))
			fallback = tile
	return length(exact) ? pick(exact) : fallback

/// Шаг EVA проверяется при каждом движении участника и смене снаряжения.
/datum/antag_training_exercise_step/drill/eva

/datum/antag_training_exercise_step/drill/eva/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/body = participant()
	if(body)
		RegisterSignals(body, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_EQUIPPED_ITEM), PROC_REF(on_participant_changed))

/datum/antag_training_exercise_step/drill/eva/proc/on_participant_changed(mob/living/carbon/human/source)
	SIGNAL_HANDLER
	if(source != participant() || !ishuman(source))
		return
	var/datum/antag_training_exercise/drill/eva/exercise = run.exercise
	var/reason = exercise.violation(src, source)
	if(reason)
		run.finish(FALSE, reason)
	else if(goal_reached(source))
		complete()

/datum/antag_training_exercise_step/drill/eva/proc/goal_reached(mob/living/carbon/human/body)
	return FALSE

/datum/antag_training_exercise_step/drill/eva/suit
	name = "Наденьте скафандр и джетпак"
	hint = "Скафандры и джетпаки лежат в шкафах EVA у входа, тот же набор выдаёт комплект «Выход в космос» на вкладке «Начать». Снимите рюкзак, наденьте скафандр, шлем и джетпак на спину, затем откройте подачу воздуха кнопкой джетпака."
	/// Засчитывается только джетпак, выданный упражнением.
	var/issued_jetpack = FALSE

/datum/antag_training_exercise_step/drill/eva/suit/goal_reached(mob/living/carbon/human/body)
	var/obj/item/tank/jetpack/jetpack = body.back
	if(!istype(body.wear_suit, /obj/item/clothing/suit/space) || !istype(body.head, /obj/item/clothing/head/helmet/space) || !istype(jetpack) || !body.internal)
		return FALSE
	return !issued_jetpack || (jetpack == run.find_prop(/obj/item/tank/jetpack) && body.internal == jetpack)

/datum/antag_training_exercise_step/drill/eva/suit/reserve
	name = "Наденьте скафандр и выданный джетпак"
	hint = "Джетпак с малым запасом лежит у ваших ног, скафандр и шлем - в шкафах EVA. Снимите рюкзак, наденьте джетпак на спину и откройте подачу воздуха из него. Другой баллон или джетпак не засчитывается."
	issued_jetpack = TRUE

/datum/antag_training_exercise_step/drill/eva/space
	name = "Выйдите через шлюз"
	hint = "Двери шлюза связаны: войдите в камеру, дождитесь, пока закроется внутренняя дверь, и откройте внешнюю. Снаружи опоры нет: включите джетпак кнопкой действия."

/datum/antag_training_exercise_step/drill/eva/space/goal_reached(mob/living/carbon/human/body)
	return isspaceturf(get_turf(body))

/datum/antag_training_exercise_step/drill/eva/beacon
	name = "Долетите до маяка"
	hint = "Маяк мигает в открытом космосе. С выключенной стабилизацией джетпак тратит газ только на разгон: разгонитесь, долетите по инерции и включите её перед маяком, чтобы остановиться."

/datum/antag_training_exercise_step/drill/eva/beacon/goal_reached(mob/living/carbon/human/body)
	return antag_training_reached(body, run.find_prop(/obj/effect/antag_training_beacon))

/datum/antag_training_exercise_step/drill/eva/beacon/outpost
	name = "Доберитесь до маяка в форпосте"
	hint = "Форпост - герметичная комната со своим шлюзом в дальнем углу сектора, маяк внутри. Без магнитных ботинок по полу не пройти: отталкивайтесь от стен или летите на джетпаке."

/datum/antag_training_exercise_step/drill/eva/chamber
	name = "Вернитесь в шлюз"
	hint = "Шлюзовая камера - между двумя дверями у комнаты снаряжения. Следите за запасом: осмотр включённого джетпака показывает, сколько газа осталось."
	var/list/turf/chamber = list()

/datum/antag_training_exercise_step/drill/eva/chamber/goal_reached(mob/living/carbon/human/body)
	return get_turf(body) in chamber

#undef ANTAG_TRAINING_EVA_RESERVE_MOLES
#undef ANTAG_TRAINING_EVA_RESERVE_VOLUME
#undef ANTAG_TRAINING_EVA_EMPTY_MOLES
#undef ANTAG_TRAINING_EVA_BEACON_RANGE
