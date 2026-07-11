/// Сколько урн отрыгнёт содержимое
#define DISPOSALS_CLOG_MIN_BINS 4
#define DISPOSALS_CLOG_MAX_BINS 7
/// Сколько мусора вылетает из одной урны
#define DISPOSALS_CLOG_MIN_TRASH 4
#define DISPOSALS_CLOG_MAX_TRASH 8
/// Сколько живности вылезает из последней урны
#define DISPOSALS_CLOG_MIN_VERMIN 2
#define DISPOSALS_CLOG_MAX_VERMIN 4
/// Дальность разлёта мусора от урны
#define DISPOSALS_CLOG_SCATTER 3

/// Засор мусоропровода (порт с Paradise): обратное давление в пневмосети - несколько
/// урн по станции с грохотом извергают веер мусора, а из последней вдобавок выбирается
/// прижившаяся в трубах живность. Честная работа уборщику и повод для баек про то,
/// что живёт в трубах.
/datum/round_event_control/disposals_clog
	name = "Disposals Clog"
	typepath = /datum/round_event/disposals_clog
	weight = 40
	max_occurrences = 3
	earliest_start = 10 MINUTES
	min_players = 5
	category = EVENT_CATEGORY_JANITORIAL
	family = "disposals"
	description = "Disposal bins across the station belch trash; the last one also spits out vermin."

/datum/round_event/disposals_clog
	fakeable = FALSE
	announce_chance = 75

/datum/round_event/disposals_clog/announce(fake)
	priority_announce("Автоматика пневмоутилизационной сети сообщает об обратном давлении в магистралях. Возможен выброс содержимого через приёмные узлы.", "Служба Утилизации Нанотрейзен")

/datum/round_event/disposals_clog/start()
	var/list/obj/machinery/disposal/bin/candidates = list()
	for(var/obj/machinery/disposal/bin/unit in GLOB.machines)
		var/turf/unit_turf = get_turf(unit)
		if(!unit_turf || !is_station_level(unit_turf.z))
			continue
		candidates += unit
		CHECK_TICK
	if(!length(candidates))
		return kill()
	var/bin_count = min(rand(DISPOSALS_CLOG_MIN_BINS, DISPOSALS_CLOG_MAX_BINS), length(candidates))
	for(var/i in 1 to bin_count)
		var/obj/machinery/disposal/bin/unit = pick_n_take(candidates)
		spew(unit, with_vermin = (i == bin_count))
		CHECK_TICK

/// Одна урна отрыгивает веер мусора; последняя - ещё и живность
/datum/round_event/disposals_clog/proc/spew(obj/machinery/disposal/bin/unit, with_vermin = FALSE)
	var/turf/origin = get_turf(unit)
	unit.visible_message(span_warning("[unit] содрогается и извергает содержимое трубопровода!"))
	playsound(origin, 'sound/machines/disposalflush.ogg', 60, TRUE)
	var/static/list/trash_types = subtypesof(/obj/item/trash)
	for(var/i in 1 to rand(DISPOSALS_CLOG_MIN_TRASH, DISPOSALS_CLOG_MAX_TRASH))
		var/junk_type = pick(trash_types)
		var/obj/item/junk = new junk_type(origin)
		junk.throw_at(get_offset_target_turf(origin, rand(-DISPOSALS_CLOG_SCATTER, DISPOSALS_CLOG_SCATTER), rand(-DISPOSALS_CLOG_SCATTER, DISPOSALS_CLOG_SCATTER)), DISPOSALS_CLOG_SCATTER, 1)
	if(!with_vermin)
		return
	var/mob/first_spawned
	for(var/i in 1 to rand(DISPOSALS_CLOG_MIN_VERMIN, DISPOSALS_CLOG_MAX_VERMIN))
		var/vermin_type = prob(60) ? /mob/living/simple_animal/mouse : /mob/living/simple_animal/cockroach
		var/mob/living/vermin = new vermin_type(origin)
		vermin.throw_at(get_offset_target_turf(origin, rand(-DISPOSALS_CLOG_SCATTER, DISPOSALS_CLOG_SCATTER), rand(-DISPOSALS_CLOG_SCATTER, DISPOSALS_CLOG_SCATTER)), DISPOSALS_CLOG_SCATTER, 1)
		if(!first_spawned)
			first_spawned = vermin
	announce_to_ghosts(first_spawned)

#undef DISPOSALS_CLOG_MIN_BINS
#undef DISPOSALS_CLOG_MAX_BINS
#undef DISPOSALS_CLOG_MIN_TRASH
#undef DISPOSALS_CLOG_MAX_TRASH
#undef DISPOSALS_CLOG_MIN_VERMIN
#undef DISPOSALS_CLOG_MAX_VERMIN
#undef DISPOSALS_CLOG_SCATTER
