#define GRAVITY_FAILURE_MIN_MINUTES 4
#define GRAVITY_FAILURE_MAX_MINUTES 5
#define GRAVITY_FAILURE_MIN_DURATION (GRAVITY_FAILURE_MIN_MINUTES MINUTES)
#define GRAVITY_FAILURE_MAX_DURATION (GRAVITY_FAILURE_MAX_MINUTES MINUTES)
#define GRAVITY_FAILURE_CYCLE_SECONDS 40
#define GRAVITY_FAILURE_DROP_SECONDS 15
#define GRAVITY_FAILURE_DROP_TIME (GRAVITY_FAILURE_DROP_SECONDS SECONDS)
#define GRAVITY_FAILURE_HOLD_TIME ((GRAVITY_FAILURE_CYCLE_SECONDS - GRAVITY_FAILURE_DROP_SECONDS) SECONDS)
#define GRAVITY_FAILURE_RESTART_TIME (6 SECONDS)
/// Длина анимации compensator_restore: блок перезапускается и уходит под палубу.
#define GRAVITY_FAILURE_RETRACT_TIME (2.4 SECONDS)
#define GRAVITY_FAILURE_SPARK_MIN (6 SECONDS)
#define GRAVITY_FAILURE_SPARK_MAX (14 SECONDS)
#define GRAVITY_FAILURE_LOUD_VOLUME 70
#define GRAVITY_FAILURE_DIP_VOLUME 45

/datum/round_event_control/station_incident/gravity_failure
	weight = 15
	name = "Local Gravity Failure"
	typepath = /datum/round_event/station_incident/gravity_failure
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MINOR
	family = "local_gravity"
	intensity_linger = 3 MINUTES
	allowed_area_types = list(
		/area/commons/arcade,
		/area/commons/fitness/recreation,
		/area/commons/locker,
		/area/commons/lounge,
		/area/commons/storage/primary,
		/area/hallway/primary,
		/area/hallway/secondary/civilian,
		/area/hallway/secondary/service,
	)
	announcement_title = "Служба гравитационной безопасности NanoTrasen"

/datum/round_event_control/station_incident/gravity_failure/New()
	description = "В одном коридоре или общей зоне на [GRAVITY_FAILURE_MIN_MINUTES]-[GRAVITY_FAILURE_MAX_MINUTES] минут сбоит контур местной гравитации: из-под палубы выдвигается искрящий компенсатор, и каждые [GRAVITY_FAILURE_CYCLE_SECONDS] секунд поле проваливается примерно на [GRAVITY_FAILURE_DROP_SECONDS] секунд. Инженер может перезапустить блок мультитулом раньше срока."
	incident_message = "В отсеке сбоит контур местной гравитации. Аварийный компенсатор выдвинут из-под палубы, но держит поле с перебоями: каждые [GRAVITY_FAILURE_CYCLE_SECONDS] секунд гравитация пропадает примерно на [GRAVITY_FAILURE_DROP_SECONDS] секунд. Без ремонта поле стабилизируется само в течение [GRAVITY_FAILURE_MAX_MINUTES] минут; инженер может перезапустить компенсатор мультитулом раньше. Во время провалов держитесь за поручни и не бросайтесь предметами."
	return ..()

/datum/round_event_control/station_incident/gravity_failure/valid_target(turf/open/floor/target)
	if(!..() || !target.has_gravity())
		return FALSE
	return !(locate(/obj/structure/gravity_compensator) in target)

/datum/round_event/station_incident/gravity_failure/apply_effect(turf/open/floor/target)
	var/obj/structure/gravity_compensator/compensator = new(target)
	return !QDELETED(compensator) && compensator.failing

/// Пока блок сбоит, поле его отсека на этом уровне периодически проваливается до нуля.
/obj/structure/gravity_compensator
	name = "local gravity compensator"
	desc = "Аварийный блок местного гравитационного контура. Выдвигается из-под палубы при сбое поля и убирается обратно, когда поле восстановлено."
	icon = 'modular_bluemoon/icons/obj/minor_incidents/gravity_compensator.dmi'
	icon_state = "compensator_fault"
	anchored = TRUE
	density = FALSE
	layer = BELOW_OBJ_LAYER
	move_resist = MOVE_FORCE_OVERPOWERING
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// Сбой ещё не устранён: поле то держится, то проваливается.
	var/failing = FALSE
	var/field_down = FALSE
	var/restarting = FALSE
	var/restore_at = 0
	var/list/turf/affected_turfs = list()

/obj/structure/gravity_compensator/Initialize(mapload)
	. = ..()
	affected_turfs = collect_turfs()
	if(!length(affected_turfs))
		return INITIALIZE_HINT_QDEL
	for(var/turf/affected as anything in affected_turfs)
		RegisterSignal(affected, COMSIG_TURF_HAS_GRAVITY, PROC_REF(suppress_gravity))
	failing = TRUE
	flick("compensator_rise", src)
	var/duration = rand(GRAVITY_FAILURE_MIN_DURATION, GRAVITY_FAILURE_MAX_DURATION)
	restore_at = world.time + duration
	addtimer(CALLBACK(src, PROC_REF(restore_field)), duration)
	addtimer(CALLBACK(src, PROC_REF(spark)), rand(GRAVITY_FAILURE_SPARK_MIN, GRAVITY_FAILURE_SPARK_MAX))
	drop_field(GRAVITY_FAILURE_LOUD_VOLUME)
	log_game("DIRECTOR: Local Gravity Failure, отсек [get_area_name(src, TRUE)], сбой поля на [length(affected_turfs)] клетках в [AREACOORD(src)].")

/obj/structure/gravity_compensator/Destroy()
	if(failing)
		log_game("DIRECTOR: Local Gravity Failure, компенсатор удалён в [AREACOORD(src)], гравитация возвращена.")
		release_field()
	affected_turfs = null
	return ..()

/// Пол отсека на уровне блока; клетки без опоры не трогаем, чтобы падение в шахты работало как обычно.
/obj/structure/gravity_compensator/proc/collect_turfs()
	var/list/result = list()
	var/area/location = get_area(src)
	if(!location)
		return result
	for(var/turf/open/candidate in location)
		if(candidate.z != z || isspaceturf(candidate) || isgroundlessturf(candidate))
			continue
		result += candidate
	return result

/obj/structure/gravity_compensator/proc/suppress_gravity(turf/source, atom/checker, list/gravities)
	SIGNAL_HANDLER
	if(field_down)
		gravities += 0

/// Стоящие на месте мобы держат гравитацию в кэше до следующего шага: пересчитываем её сразу.
/obj/structure/gravity_compensator/proc/refresh_residents()
	for(var/turf/affected as anything in affected_turfs)
		for(var/mob/living/resident in affected)
			resident.refresh_gravity()

/obj/structure/gravity_compensator/proc/drop_field(volume = GRAVITY_FAILURE_DIP_VOLUME)
	if(!failing || field_down)
		return FALSE
	field_down = TRUE
	refresh_residents()
	playsound(src, 'modular_bluemoon/sound/minor_incidents/gravity_failure_down.ogg', volume, FALSE)
	do_sparks(2, TRUE, src)
	addtimer(CALLBACK(src, PROC_REF(hold_field)), GRAVITY_FAILURE_DROP_TIME)
	return TRUE

/obj/structure/gravity_compensator/proc/hold_field()
	if(!failing || !field_down)
		return FALSE
	field_down = FALSE
	refresh_residents()
	playsound(src, 'modular_bluemoon/sound/minor_incidents/gravity_failure_up.ogg', GRAVITY_FAILURE_DIP_VOLUME, FALSE)
	if(world.time + GRAVITY_FAILURE_HOLD_TIME < restore_at)
		addtimer(CALLBACK(src, PROC_REF(drop_field)), GRAVITY_FAILURE_HOLD_TIME)
	return TRUE

/obj/structure/gravity_compensator/proc/release_field()
	failing = FALSE
	field_down = FALSE
	for(var/turf/affected as anything in affected_turfs)
		UnregisterSignal(affected, COMSIG_TURF_HAS_GRAVITY)
	refresh_residents()

/obj/structure/gravity_compensator/proc/restore_field(mob/living/user)
	if(!failing)
		return FALSE
	release_field()
	log_game("DIRECTOR: Local Gravity Failure, гравитация в отсеке [get_area_name(src, TRUE)] восстановлена: [user ? "перезапуск ([key_name(user)])" : "истёк срок"].")
	playsound(src, 'modular_bluemoon/sound/minor_incidents/gravity_failure_up.ogg', GRAVITY_FAILURE_LOUD_VOLUME, FALSE)
	visible_message(span_notice("[src] гудит всё выше и ровнее; поле стабилизировалось, и блок уходит под палубу."))
	icon_state = "compensator_restore"
	addtimer(CALLBACK(src, PROC_REF(retract)), GRAVITY_FAILURE_RETRACT_TIME)
	return TRUE

/obj/structure/gravity_compensator/proc/retract()
	qdel(src)

/obj/structure/gravity_compensator/proc/spark()
	if(!failing)
		return
	do_sparks(2, TRUE, src)
	addtimer(CALLBACK(src, PROC_REF(spark)), rand(GRAVITY_FAILURE_SPARK_MIN, GRAVITY_FAILURE_SPARK_MAX))

/obj/structure/gravity_compensator/examine(mob/user)
	. = ..()
	if(!failing)
		. += span_notice("Индикатор горит ровным зелёным: поле восстановлено.")
		return
	. += span_warning("Индикатор сбоя мигает красным, по корпусу пробегают искры. [field_down ? "Поле сейчас провалено." : "Поле пока держится, но проваливается каждые [GRAVITY_FAILURE_CYCLE_SECONDS] секунд примерно на [GRAVITY_FAILURE_DROP_SECONDS] секунд."]")
	. += span_notice("Инженер может перезапустить блок мультитулом. Иначе поле стабилизируется само примерно через [max(1, round((restore_at - world.time) / (1 SECONDS)))] с.")

/obj/structure/gravity_compensator/multitool_act(mob/living/user, obj/item/tool)
	if(!failing)
		to_chat(user, span_notice("[src] уже стабилизировал поле."))
		return TOOL_ACT_TOOLTYPE_SUCCESS
	if(restarting)
		to_chat(user, span_warning("Перезапуск уже идёт."))
		return TOOL_ACT_TOOLTYPE_SUCCESS
	restarting = TRUE
	user.visible_message(span_notice("[user] подключает [tool] к [src] и запускает перезагрузку контура."), span_notice("Вы запускаете перезагрузку контура."))
	var/success = tool.use_tool(src, user, GRAVITY_FAILURE_RESTART_TIME, volume = 50)
	restarting = FALSE
	if(success && !QDELETED(src))
		restore_field(user)
	return TOOL_ACT_TOOLTYPE_SUCCESS

#undef GRAVITY_FAILURE_MIN_MINUTES
#undef GRAVITY_FAILURE_MAX_MINUTES
#undef GRAVITY_FAILURE_MIN_DURATION
#undef GRAVITY_FAILURE_MAX_DURATION
#undef GRAVITY_FAILURE_CYCLE_SECONDS
#undef GRAVITY_FAILURE_DROP_SECONDS
#undef GRAVITY_FAILURE_DROP_TIME
#undef GRAVITY_FAILURE_HOLD_TIME
#undef GRAVITY_FAILURE_RESTART_TIME
#undef GRAVITY_FAILURE_RETRACT_TIME
#undef GRAVITY_FAILURE_SPARK_MIN
#undef GRAVITY_FAILURE_SPARK_MAX
#undef GRAVITY_FAILURE_LOUD_VOLUME
#undef GRAVITY_FAILURE_DIP_VOLUME
