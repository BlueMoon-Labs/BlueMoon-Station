/// A soft limit for player-built fans used as atmos barriers. The clutch fails
/// open after a sustained excessive pressure difference, then resets after a
/// stable safe interval. Monitoring lives in SSobj so the core atmos loops do
/// no extra work.
/datum/component/atmos_fan_safety
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/max_pressure_differential
	var/tripped = FALSE
	var/overload_started_at = 0
	var/recovery_started_at = 0
	var/last_pressure_differential = 0
	///Consecutive settled process() passes; at ATMOS_FAN_IDLE_STREAK we stop
	///polling SSobj and rely on turf exposure to wake us.
	var/idle_streak = 0
	///Turfs we hold exposure registrations on (fan tile + cardinals).
	var/list/turf/watched_turfs

/datum/component/atmos_fan_safety/Initialize(max_pressure_differential)
	if(!istype(parent, /obj/structure/fans/tiny) && !istype(parent, /obj/machinery/poweredfans))
		return COMPONENT_INCOMPATIBLE
	if(!isnum(max_pressure_differential) || max_pressure_differential <= 0)
		return COMPONENT_INCOMPATIBLE
	src.max_pressure_differential = max_pressure_differential
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))
	register_watched_turfs()
	START_PROCESSING(SSobj, src)

/datum/component/atmos_fan_safety/Destroy(force, silent)
	STOP_PROCESSING(SSobj, src)
	unregister_watched_turfs()
	UnregisterSignal(parent, list(COMSIG_PARENT_EXAMINE, COMSIG_MOVABLE_MOVED))
	return ..()

/datum/component/atmos_fan_safety/proc/register_watched_turfs()
	unregister_watched_turfs()
	var/turf/open/origin = get_turf(parent)
	if(istype(origin))
		register_turf_exposure(origin, PROC_REF(on_watched_exposure))
		LAZYADD(watched_turfs, origin)
	for(var/direction in GLOB.cardinals)
		var/turf/open/neighbour = get_step(parent, direction)
		if(istype(neighbour))
			register_turf_exposure(neighbour, PROC_REF(on_watched_exposure))
			LAZYADD(watched_turfs, neighbour)

/datum/component/atmos_fan_safety/proc/unregister_watched_turfs()
	for(var/turf/watched as anything in watched_turfs)
		unregister_turf_exposure(watched)
	watched_turfs = null

/datum/component/atmos_fan_safety/proc/on_parent_moved()
	SIGNAL_HANDLER
	register_watched_turfs()
	wake_up()

/datum/component/atmos_fan_safety/proc/on_watched_exposure(turf/source, datum/gas_mixture/exposed_air, exposed_temperature)
	SIGNAL_HANDLER
	wake_up()

/datum/component/atmos_fan_safety/proc/wake_up()
	idle_streak = 0
	START_PROCESSING(SSobj, src)

/datum/component/atmos_fan_safety/process()
	if(pressure_differential_exceeds_rating())
		idle_streak = 0
		recovery_started_at = 0
		if(tripped)
			return
		if(!overload_started_at)
			overload_started_at = world.time
			// Муфта, которая распахивается молча, читается как "вентилятор
			// сгорел". Она дребезжит заранее: у того, кто стоит рядом, есть
			// ATMOS_FAN_OVERLOAD_DELAY на то, чтобы сбросить давление или уйти.
			var/atom/movable/fan = parent
			fan.visible_message("<span class='warning'>Предохранительная муфта [fan] дребезжит от перепада давления.</span>")
			playsound(fan, 'sound/machines/warning-buzzer.ogg', 20, TRUE)
			return
		if(world.time >= overload_started_at + ATMOS_FAN_OVERLOAD_DELAY)
			set_tripped(TRUE)
		return
	overload_started_at = 0
	if(!tripped)
		// A standing sub-rating differential still needs polling (it can grow
		// without any write to OUR turfs), but a settled field cannot change
		// without air changing on a watched turf - exposure wakes us for that.
		if(last_pressure_differential <= ATMOS_FAN_IDLE_PRESSURE_DELTA)
			idle_streak++
			if(idle_streak >= ATMOS_FAN_IDLE_STREAK)
				STOP_PROCESSING(SSobj, src)
		else
			idle_streak = 0
		return
	idle_streak = 0
	if(last_pressure_differential > max_pressure_differential * ATMOS_FAN_RESET_PRESSURE_RATIO)
		recovery_started_at = 0
		return
	if(!recovery_started_at)
		recovery_started_at = world.time
		return
	if(world.time >= recovery_started_at + ATMOS_FAN_RESET_DELAY)
		set_tripped(FALSE)

/// Samples the pressure difference across each edge blocked by the fan. This
/// is public so the focused test and benchmark exercise the exact live path.
/datum/component/atmos_fan_safety/proc/pressure_differential_exceeds_rating()
	last_pressure_differential = 0
	var/turf/open/origin = get_turf(parent)
	if(!istype(origin))
		return FALSE
	var/datum/gas_mixture/origin_air = origin.return_air()
	if(!origin_air)
		return FALSE
	var/origin_pressure = origin_air.return_pressure()
	for(var/direction in GLOB.cardinals)
		var/turf/open/neighbour = get_step(origin, direction)
		if(!istype(neighbour))
			continue
		var/datum/gas_mixture/neighbour_air = neighbour.return_air()
		if(!neighbour_air)
			continue
		last_pressure_differential = max(last_pressure_differential, abs(origin_pressure - neighbour_air.return_pressure()))
	return last_pressure_differential > max_pressure_differential

/datum/component/atmos_fan_safety/proc/set_tripped(new_state, silent = FALSE)
	if(tripped == new_state)
		return
	tripped = new_state
	overload_started_at = 0
	recovery_started_at = 0
	var/atom/movable/fan = parent
	if(istype(fan, /obj/structure/fans/tiny))
		var/obj/structure/fans/tiny/tiny_fan = fan
		tiny_fan.refresh_atmos_barrier()
	else
		var/obj/machinery/poweredfans/powered_fan = fan
		powered_fan.refresh_atmos_barrier()
	if(silent)
		return
	if(tripped)
		fan.visible_message("<span class='warning'>Предохранительная муфта [fan] распахивается от перепада давления!</span>")
		playsound(fan, 'sound/machines/warning-buzzer.ogg', 35, TRUE)
	else
		fan.visible_message("<span class='notice'>Предохранительная муфта [fan] возвращается в рабочее положение.</span>")
		playsound(fan, 'sound/machines/click.ogg', 30, TRUE)

/datum/component/atmos_fan_safety/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/rounded_rating = round(max_pressure_differential, 0.1)
	var/rounded_reset_pressure = round(max_pressure_differential * ATMOS_FAN_RESET_PRESSURE_RATIO, 0.1)
	examine_list += "<span class='notice'>Предохранительная муфта открывается через [ATMOS_FAN_OVERLOAD_DELAY / 10] секунд при перепаде давления выше <b>[rounded_rating] кПа</b>. Температура на неё не влияет.</span>"
	examine_list += "<span class='notice'>Сбрасывается через [ATMOS_FAN_RESET_DELAY / 10] секунд при перепаде ниже [rounded_reset_pressure] кПа.</span>"
	if(tripped)
		examine_list += "<span class='warning'>Муфта открыта; воздух проходит насквозь.</span>"
