#define CONSTRUCTION_COMPLETE 0 //No construction done - functioning as normal
#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_WIRES_EXPOSED 2 //Cover plate is removed, wires are available
#define CONSTRUCTION_GUTTED 3 //Wires are removed, circuit ready to remove
#define CONSTRUCTION_NOCIRCUIT 4 //Circuit board removed, can safely weld apart

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Apply crowbar."
	icon = 'icons/obj/doors/Doorfireglass.dmi'
	icon_state = "door_open"
	opacity = FALSE
	density = FALSE
	max_integrity = 300
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor = list(MELEE = 30, BULLET = 30, LASER = 20, ENERGY = 20, BOMB = 10, BIO = 100, RAD = 100, FIRE = 95, ACID = 70)
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_REQUIRES_SILICON | INTERACT_MACHINE_OPEN
	air_tight = TRUE
	attack_hand_is_action = TRUE
	attack_hand_speed = CLICK_CD_MELEE
	can_open_with_hands = FALSE
	var/emergency_close_timer = 0
	var/nextstate = null
	var/boltslocked = TRUE
	var/list/affecting_areas
	///Shared by every touching firelock in the merger group: turf -> alarm type.
	var/list/issue_turfs
	///Turfs this firelock holds exposure registrations on (center + cardinals).
	var/list/turf/watched_atmos_turfs
	var/alarm_type
	///Area fire alarms contribute the generic priority below hot/cold turf alarms.
	var/generic_alarm = FALSE
	///Агрегат "слушают ли датчики во всех зонах двери" - только для осмотра и
	///проводов. Сам вердикт по турфу считается от area.fire_detect зоны ЭТОГО
	///турфа: журнал общий на группу, и решение по агрегату конкретной двери
	///заставляло бы двери с разными агрегатами драться за одну запись.
	var/fire_detection = TRUE
	///Дверь закрыта автоматикой, а не руками. Только такую автоматика имеет право
	///открыть обратно: закрытая на карте или ломом остаётся закрытой.
	var/auto_closed = FALSE
	///Таймер отложенной попытки открыться, см. try_auto_reopen().
	var/reopen_timer
	var/merger_id = "firelocks"
	var/static/list/merger_typecache

/obj/machinery/door/firedoor/Initialize(mapload)
	. = ..()
	CalculateAffectingAreas(TRUE)
	if(!merger_typecache)
		merger_typecache = typecacheof(list(/obj/machinery/door/firedoor))
	RegisterSignal(src, COMSIG_MERGER_ADDING, PROC_REF(merger_adding))
	RegisterSignal(src, COMSIG_MERGER_REMOVING, PROC_REF(merger_removing))
	var/datum/merger/group = GetMergeGroup(merger_id, merger_typecache)
	// На мапе группу основывает первая инициализированная дверь: её флад-филл
	// шлёт COMSIG_MERGER_ADDING остальным дверям ДО того, как их Initialize
	// подпишет обработчик выше, а повторного AddMember для них не будет. Без
	// явной подписки здесь такая дверь никогда не слышит Refresh группы, и после
	// смерти основательницы журнал тревог не пересобирает уже никто.
	if(group)
		RegisterSignal(group, COMSIG_MERGER_REFRESH_COMPLETE, PROC_REF(refresh_firelock_group), override = TRUE)
	register_atmos_turfs()

/obj/machinery/door/firedoor/examine(mob/user)
	. = ..()
	if(!density)
		. += "<span class='notice'>It is open, but could be <b>pried</b> closed.</span>"
	else if(!welded)
		. += "<span class='notice'>It is closed, but could be <i>pried</i> open. Deconstruction would require it to be <b>welded</b> shut.</span>"
	else if(boltslocked)
		. += "<span class='notice'>It is <i>welded</i> shut. The floor bolts have been locked by <b>screws</b>.</span>"
	else
		. += "<span class='notice'>The bolt locks have been <i>unscrewed</i>, but the bolts themselves are still <b>wrenched</b> to the floor.</span>"
	if(alarm_type == FIRELOCK_ALARM_TYPE_COLD)
		. += "<span class='notice'>Синяя лампа датчика: за дверью холоднее, чем задумано для этой комнаты. От холода дверь не закрывается - это предупреждение тому, кто собрался войти без скафандра.</span>"
	else if(alarm_type)
		. += "<span class='warning'>Атмосферный датчик сообщает: [alarm_type == FIRELOCK_ALARM_TYPE_HOT ? "опасный нагрев" : "общая угроза"].</span>"
	if(!fire_detection)
		. += "<span class='notice'>Детекция снята проводом на пожарной сигнализации зоны: дверь слушает только ручное управление.</span>"
	. += span_notice("Alt-click the door to use the manual override.")

/obj/machinery/door/firedoor/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()

	if (isnull(held_item))
		if (density)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Knock")
			return CONTEXTUAL_SCREENTIP_SET
		else
			return .

	switch (held_item.tool_behaviour)
		if (TOOL_CROWBAR)
			if(!welded)
				LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (density ? "Open" : "Close"))
				return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_WELDER)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (welded ? "Unweld shut" : "Weld shut"))
			return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_WRENCH)
			if (welded && !boltslocked)
				LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Unfasten bolts")
				return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_SCREWDRIVER)
			if (welded)
				LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (boltslocked ? "Unlock bolts" : "Lock bolts"))
				return CONTEXTUAL_SCREENTIP_SET
	return .

/// initializing = TRUE только из Initialize: датчики турфов там ещё не
/// зарегистрированы и пересматривать нечего, а группа файрлоков ещё не собрана.
/obj/machinery/door/firedoor/proc/CalculateAffectingAreas(initializing = FALSE)
	remove_from_areas()
	affecting_areas = get_adjacent_open_areas(src) | get_base_area(src)
	for(var/I in affecting_areas)
		var/area/A = I
		LAZYADD(A.firedoors, src)
	refresh_fire_detection(!initializing)

/// Снимает вердикт зон о детекции. rescan просят все, кроме первичного расчёта
/// зон: на нём датчики ещё не зарегистрированы и пересматривать нечего.
/obj/machinery/door/firedoor/proc/refresh_fire_detection(rescan = TRUE)
	var/new_state = TRUE
	for(var/area/affected as anything in affecting_areas)
		if(!affected.fire_detect)
			new_state = FALSE
			break
	fire_detection = new_state
	if(!rescan)
		return
	// Выключенная детекция обязана СНЯТЬ уже поднятые вердикты, а не только не
	// поднимать новые: иначе дверь остаётся закрытой навсегда, а провод, который
	// её и должен был отпустить, ничего не меняет. Пересматриваем даже когда
	// агрегат не шелохнулся: вердикт считается по зоне самого турфа, и щелчок
	// провода во ВТОРОЙ зоне двери меняет её турфы, не трогая агрегат.
	rescan_atmos_turfs()
	recompute_atmos_alarm()

/obj/machinery/door/firedoor/proc/UpdateAdjacencyFlags()
	var/turf/T = get_turf(src)
	if(flags_1 & ON_BORDER_1)
		for(var/t in T.atmos_adjacent_turfs)
			if(get_dir(loc, t) == dir)
				var/turf/open/T2 = t
				if(T2 in T.atmos_adjacent_turfs)
					T.atmos_adjacent_turfs[T2] |= ATMOS_ADJACENT_FIRELOCK
				if(T in T2.atmos_adjacent_turfs)
					T2.atmos_adjacent_turfs[T] |= ATMOS_ADJACENT_FIRELOCK
	else
		for(var/t in T.atmos_adjacent_turfs)
			var/turf/open/T2 = t
			if(T2 in T.atmos_adjacent_turfs)
				T.atmos_adjacent_turfs[T2] |= ATMOS_ADJACENT_FIRELOCK
			if(T in T2.atmos_adjacent_turfs)
				T2.atmos_adjacent_turfs[T] |= ATMOS_ADJACENT_FIRELOCK

/obj/machinery/door/firedoor/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

//see also turf/AfterChange for adjacency shennanigans

/obj/machinery/door/firedoor/proc/remove_from_areas()
	if(affecting_areas)
		for(var/I in affecting_areas)
			var/area/A = I
			LAZYREMOVE(A.firedoors, src)
// обнуление affecting_areas в firedoor для надёжности. тк возможная утечка
/obj/machinery/door/firedoor/Destroy()
	if(reopen_timer)
		deltimer(reopen_timer)
		reopen_timer = null
	unregister_atmos_turfs()
	remove_from_areas()
	if(affecting_areas)
		affecting_areas.Cut()
	affecting_areas = null
	return ..()

/obj/machinery/door/firedoor/proc/merger_adding(obj/machinery/door/firedoor/us, datum/merger/new_merger)
	SIGNAL_HANDLER
	if(new_merger.id == merger_id)
		RegisterSignal(new_merger, COMSIG_MERGER_REFRESH_COMPLETE, PROC_REF(refresh_firelock_group))

/obj/machinery/door/firedoor/proc/merger_removing(obj/machinery/door/firedoor/us, datum/merger/old_merger)
	SIGNAL_HANDLER
	if(old_merger.id == merger_id)
		UnregisterSignal(old_merger, COMSIG_MERGER_REFRESH_COMPLETE)

/obj/machinery/door/firedoor/proc/refresh_firelock_group(datum/source, list/leaving_members, list/joining_members)
	SIGNAL_HANDLER
	var/datum/merger/group = source
	if(group.origin != src)
		return
	// Rebuild from scratch: rescanning every member's own watch window is the
	// only way entries contributed by doors that LEFT the group (or turfs no
	// survivor watches) can drop out, instead of latching the alarm forever.
	var/list/shared_issues = list()
	for(var/obj/machinery/door/firedoor/door as anything in group.members)
		door.issue_turfs = shared_issues
	for(var/obj/machinery/door/firedoor/door as anything in group.members)
		door.rescan_atmos_turfs()
	recompute_atmos_alarm()
	// Ушедшие двери всё ещё держат ПРЕЖНИЙ общий журнал с чужими записями и
	// защёлкнутую по нему тревогу, а собственного фронта, который бы их
	// пересчитал, у них может не случиться до конца раунда. Пересобираем их в их
	// новых группах; несколько ушедших из одного куска дают повторную пересборку
	// той же группы - это дёшево и бывает только на разрыве кластера.
	for(var/obj/machinery/door/firedoor/leaver as anything in leaving_members)
		if(QDELETED(leaver))
			continue
		leaver.rebuild_alarm_ledger()

/obj/machinery/door/firedoor/proc/register_atmos_turfs()
	unregister_atmos_turfs()
	var/turf/open/center = get_turf(src)
	if(!istype(center))
		return
	register_turf_exposure(center, PROC_REF(process_atmos_alarm))
	LAZYADD(watched_atmos_turfs, center)
	for(var/direction in GLOB.cardinals)
		var/turf/open/checked = get_step(center, direction)
		if(istype(checked))
			register_turf_exposure(checked, PROC_REF(process_atmos_alarm))
			LAZYADD(watched_atmos_turfs, checked)

/// Unregisters exactly what was registered, not whatever happens to surround
/// the door right now - the two sets differ after wall work or a shuttle move.
/obj/machinery/door/firedoor/proc/unregister_atmos_turfs()
	for(var/turf/watched as anything in watched_atmos_turfs)
		unregister_turf_exposure(watched)
	watched_atmos_turfs = null

/// Перемещённая дверь (forceMove, телепорт - любой не-шаттловый перенос) обязана
/// пересчитать зоны и пересобрать журнал, как это делает afterShuttleMove() ниже:
/// иначе записи, ключом которых стоят покинутые турфы, не снимет уже никто, и
/// тревога группы защёлкивается навсегда, а affecting_areas продолжает слушать
/// пожарные тревоги прежнего места.
/obj/machinery/door/firedoor/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!isturf(loc))
		return
	CalculateAffectingAreas()
	register_atmos_turfs()
	rebuild_alarm_ledger()

/// Перелёт шаттла переносит содержимое присваиванием loc и Moved() не зовёт
/// (см. /atom/movable/onShuttleMove), поэтому хук выше по шаттлам не работает
/// вообще: у улетевшей двери оставались датчики на турфах прошлого дока, а
/// записи в issue_turfs по ним не мог снять уже никто - покинутый турф
/// становится космосом и сигналов больше не шлёт.
/obj/machinery/door/firedoor/afterShuttleMove(turf/oldT, list/movement_force, shuttle_dir, shuttle_preferred_direction, move_dir, rotation)
	. = ..()
	CalculateAffectingAreas()
	register_atmos_turfs()
	rebuild_alarm_ledger()

/// Пересобирает общий журнал тревог группы с нуля. Иначе запись, ключом которой
/// стоит турф, за которым больше никто не следит, висит в журнале вечно и держит
/// всю группу закрытой.
/obj/machinery/door/firedoor/proc/rebuild_alarm_ledger()
	var/datum/merger/group = GetMergeGroup(merger_id, merger_typecache)
	var/list/group_members = group?.members
	if(!length(group_members))
		group_members = list(src)
	var/list/shared_issues = list()
	for(var/obj/machinery/door/firedoor/door as anything in group_members)
		door.issue_turfs = shared_issues
	for(var/obj/machinery/door/firedoor/door as anything in group_members)
		// Кэш "зона горит" обновляется только обходом area.firedoors по фронту
		// тревоги, а дверь, сменившая зоны (перелёт шаттла, forceMove, распад
		// группы), из того списка выпала - перевыводим из ТЕКУЩИХ affecting_areas,
		// иначе улетевшая с непогашенной тревогой дверь печатает свою новую
		// группу GENERIC-тревогой до конца смены.
		door.derive_generic_alarm()
		door.rescan_atmos_turfs()
	recompute_atmos_alarm()

// /turf/return_temperature() is a null stub; the air mixture is the only
// truthful temperature source here, exactly like the live process_cell signal.
/obj/machinery/door/firedoor/proc/rescan_atmos_turfs()
	var/turf/center = get_turf(src)
	if(!center)
		return
	rescan_single_turf(center)
	for(var/direction in GLOB.cardinals)
		var/turf/checked = get_step(center, direction)
		if(checked)
			rescan_single_turf(checked)

/obj/machinery/door/firedoor/proc/rescan_single_turf(turf/checked)
	var/datum/gas_mixture/checked_air = checked.return_air()
	process_atmos_alarm(checked, checked_air, checked_air?.return_temperature())

/// Порог холодной лампы для конкретного турфа. Комната, которую МАПЯТ холодной,
/// светить лампой за собственный проект не должна: телекомы разложены при 80 K
/// (TCOMMS_ATMOS), холодильник кухни при 259 K, снег при 180 K. Поэтому берётся
/// меньшее из общего порога и проектной температуры самого турфа за вычетом
/// полосы возврата - лампа загорается, только когда стало холоднее задуманного.
/// Разбор строки кэширован в SSair, так что это чтение из готового списка.
/obj/machinery/door/firedoor/proc/cold_alarm_limit(turf/checked_turf)
	var/limit = FIRELOCK_COLD_ALARM_TEMPERATURE
	if(!SSair)
		return limit
	var/list/designed = SSair.get_parsed_gas_string(checked_turf.initial_gas_mix)
	var/designed_temperature = designed?[GAS_STRING_TEMP]
	if(!isnum(designed_temperature))
		return limit
	return min(limit, designed_temperature - FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS)

/// Закрывает ли дверь такая тревога. Жар и тревога зоны закрывают, холод только
/// светит лампой: холодом в этой кодовой базе живут телекомы, серверная, крио и
/// холодильник, и дверь, захлопнутая ими, не спасала никого - она просто не
/// открывалась. Разгерметизацию по-прежнему ловит перепад давления, а не это.
/obj/machinery/door/firedoor/proc/firelock_alarm_seals(alarm)
	return alarm && alarm != FIRELOCK_ALARM_TYPE_COLD

/// Стоит ли турф в комнате, спроектированной горячей. Читается один вар зоны,
/// так что проверку можно держать на горячем пути замера.
/obj/machinery/door/firedoor/proc/heat_exempt_turf(turf/checked)
	var/area/checked_area = checked.loc
	return isarea(checked_area) && checked_area.firelock_heat_exempt

/obj/machinery/door/firedoor/proc/process_atmos_alarm(turf/source, datum/gas_mixture/exposed_air, exposed_temperature)
	SIGNAL_HANDLER
	if(!issue_turfs)
		issue_turfs = list()
	var/new_alarm
	// Only open, non-space turfs can raise an alarm. Walls have no air (their
	// bare turf temperature would read as a permanent COLD via rescans), and
	// vacuum around an exterior firelock is the decompression path's business;
	// treating space's 2.7 K as a cold-room alarm would permanently close it.
	var/turf/open/checked_turf = source
	var/area/source_area = source.loc
	if(isarea(source_area) && !source_area.fire_detect)
		// Провод детекции в пожарной сигнализации зоны перерезан: комнату греют
		// или морозят намеренно, и дверь в это не лезет. Читается зона САМОГО
		// замеряемого турфа, а не агрегат зон двери: журнал общий на группу, и
		// две двери с разными агрегатами иначе дерутся за одну запись - одна
		// снимает вердикт, другая тут же возвращает, группа хлопает створками.
		new_alarm = null
	else if(!isopenturf(source) || istype(source, /turf/open/space))
		new_alarm = null
	else if(heat_exempt_turf(source))
		// Камера сгорания и турбина живут горячими по проекту, а порог тревоги их
		// рабочую температуру не догоняет и близко. Проверка идёт по зоне САМОГО
		// замеряемого турфа, а не по агрегату двери: створка на входе обязана
		// по-прежнему ловить пожар со стороны коридора.
		new_alarm = null
	else if(checked_turf.planetary_atmos)
		// Улица планеты холодна или горяча по устройству и остыть/нагреться ей
		// некуда: снег ледяной луны живёт при 180 K, то есть на восемьдесят
		// кельвинов ниже порога холода. Без этой проверки файрлок на выходе из
		// шахтёрского аванпоста захлопывается при первом же замере и остаётся
		// закрытым навсегда - тревога не может сняться, а без снятия тревоги
		// ветка переоткрытия ниже не выполняется вообще.
		new_alarm = null
	else if(isnull(exposed_temperature))
		// null is NOT 0 in DM, but it still compares below the cold limit;
		// an unknown temperature must never read as a cold alarm.
		new_alarm = null
	else
		// Взведённая тревога держится до выхода за полосу возврата. С одним
		// порогом на вход и на выход турф у кромки пожара щёлкает тревогой
		// по нескольку раз в секунду, и каждый щелчок стоит перерисовки ламп
		// всей группы плюс закрытия-открытия двери со звуком.
		var/previous_alarm = issue_turfs[source]
		// Тот же порог, что у пожарной сигнализации. На "тут может гореть"
		// (FIRE_MINIMUM_TEMPERATURE_TO_EXIST, 373 K) двери захлопывались на сто
		// кельвинов раньше, чем зона поднимала тревогу: в полосе между порогами
		// ни сирены, ни тревоги зоны - значит и сбрасывать экипажу нечего, а
		// турбинный зал живёт выше 373 K по устройству.
		var/hot_limit = ATMOS_HEAT_ALARM_TEMPERATURE
		var/cold_limit = cold_alarm_limit(checked_turf)
		if(previous_alarm == FIRELOCK_ALARM_TYPE_HOT)
			hot_limit -= FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS
		else if(previous_alarm == FIRELOCK_ALARM_TYPE_COLD)
			cold_limit += FIRELOCK_ALARM_TEMPERATURE_HYSTERESIS
		if(exposed_temperature >= hot_limit)
			new_alarm = FIRELOCK_ALARM_TYPE_HOT
		else if(exposed_temperature <= cold_limit)
			new_alarm = FIRELOCK_ALARM_TYPE_COLD
		// У почти вакуума температура ничего не значит: разрежённый газ не
		// обожжёт и не заморозит, а сама разгерметизация уже обрабатывается
		// перепадом давления. Свежеразваканный турф читается как 2.7 K и иначе
		// намертво вешает холодную тревогу на дверь шлюза или пода.
		// Давление считается только у турфа, уже выпавшего из полосы: у
		// обычной комнаты при 293 K эта ветка не выполняется никогда.
		if(new_alarm && (!exposed_air || exposed_air.return_pressure() < WARNING_LOW_PRESSURE))
			new_alarm = null
	// A hot turf stays hot for hundreds of consecutive fires; only actual
	// classification transitions may pay the group recompute below.
	if(issue_turfs[source] == new_alarm)
		return
	if(new_alarm)
		issue_turfs[source] = new_alarm
	else
		issue_turfs -= source
	recompute_atmos_alarm()

/obj/machinery/door/firedoor/proc/recompute_atmos_alarm()
	if(!issue_turfs)
		issue_turfs = list()
	var/datum/merger/group = GetMergeGroup(merger_id, merger_typecache)
	var/list/group_members = group?.members
	if(!length(group_members))
		group_members = list(src)
	var/new_alarm
	for(var/turf/problem as anything in issue_turfs)
		var/problem_type = issue_turfs[problem]
		if(problem_type == FIRELOCK_ALARM_TYPE_HOT)
			new_alarm = problem_type
			break
		if(problem_type == FIRELOCK_ALARM_TYPE_COLD && !new_alarm)
			new_alarm = problem_type
	// Тревога зоны обгоняет холод: холод дверь не закрывает, а тревога зоны
	// закрывает, и лампа обязана показывать ту причину, по которой дверь стоит.
	if(new_alarm != FIRELOCK_ALARM_TYPE_HOT)
		for(var/obj/machinery/door/firedoor/door as anything in group_members)
			if(door.generic_alarm)
				new_alarm = FIRELOCK_ALARM_TYPE_GENERIC
				break
	if(new_alarm == alarm_type)
		return
	var/seals = firelock_alarm_seals(new_alarm)
	for(var/obj/machinery/door/firedoor/door as anything in group_members)
		door.alarm_type = new_alarm
		door.update_icon() // the lamps are the only readout the crew gets
		if(seals)
			// Keep the crowbar escape grace: try_to_crowbar arms
			// emergency_close_timer so a player forcing a firelock open is not
			// instantly shut in again by the next alarm transition.
			door.emergency_pressure_stop()
		else
			var/area_alarm = FALSE
			for(var/area/affected as anything in door.affecting_areas)
				if(affected.fire)
					area_alarm = TRUE
					break
			// auto_closed обязателен: закрытую ломом или замапленную закрытой
			// дверь автоматика открывать не имеет права (см. док у вара), иначе
			// любой проходной фронт тревоги в группе распахивает ручную заслонку.
			if(!area_alarm && door.density && door.auto_closed && !door.welded && !door.operating && !door.is_holding_pressure())
				// door/open() sleeps through its animation, and this proc runs
				// from SIGNAL_HANDLER paths inside SSair's process_cell.
				door.auto_closed = FALSE
				INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/firedoor, open))

/// Re-evaluates every affected area because a firedoor can border more than one
/// alarm zone and clearing one must not override another active alarm.
/obj/machinery/door/firedoor/proc/refresh_generic_alarm()
	derive_generic_alarm()
	recompute_atmos_alarm()

/// Перевывод кэша "зона горит" из ТЕКУЩИХ affecting_areas, без пересчёта группы.
/// Отдельным проком, чтобы пересборка журнала могла перевывести кэш каждому
/// члену группы до единственного общего recompute_atmos_alarm().
/obj/machinery/door/firedoor/proc/derive_generic_alarm()
	generic_alarm = FALSE
	for(var/area/affected as anything in affecting_areas)
		if(affected.fire)
			generic_alarm = TRUE
			break

/obj/machinery/door/firedoor/Bumped(atom/movable/AM)
	if(panel_open || operating || welded)
		return
	return FALSE

/obj/machinery/door/firedoor/power_change()
	if(powered(power_channel))
		set_machine_stat(machine_stat & ~NOPOWER)
		INVOKE_ASYNC(src, PROC_REF(latetoggle))
	else
		set_machine_stat(machine_stat | NOPOWER)
	update_icon() // alarm lamps are powered indicators and must go dark with the door

/obj/machinery/door/firedoor/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(operating || !density)
		return

	user.visible_message("[user] bangs on \the [src].",
						 "You bang on \the [src].")
	playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return

	if(welded)
		if(C.tool_behaviour == TOOL_WRENCH)
			if(boltslocked)
				to_chat(user, "<span class='notice'>There are screws locking the bolts in place!</span>")
				return
			C.play_tool_sound(src)
			user.visible_message("<span class='notice'>[user] starts undoing [src]'s bolts...</span>", \
								"<span class='notice'>You start unfastening [src]'s floor bolts...</span>")
			if(!C.use_tool(src, user, 50))
				return
			playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
			user.visible_message("<span class='notice'>[user] unfastens [src]'s bolts.</span>", \
								"<span class='notice'>You undo [src]'s floor bolts.</span>")
			deconstruct(TRUE)
			return
		if(C.tool_behaviour == TOOL_SCREWDRIVER)
			user.visible_message("<span class='notice'>[user] [boltslocked ? "unlocks" : "locks"] [src]'s bolts.</span>", \
								 "<span class='notice'>You [boltslocked ? "unlock" : "lock"] [src]'s floor bolts.</span>")
			C.play_tool_sound(src)
			boltslocked = !boltslocked
			return

	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user, access_bypass = FALSE)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/W, mob/user)
	if(!W.tool_behaviour == TOOL_WELDER)
		return
	if(!W.tool_start_check(user, amount=0))
		return
	user.visible_message("<span class='notice'>[user] starts [welded ? "unwelding" : "welding"] [src].</span>", "<span class='notice'>You start welding [src].</span>")
	if(W.use_tool(src, user, 40, volume=50))
		welded = !welded
		to_chat(user, "<span class='danger'>[user] [welded?"welds":"unwelds"] [src].</span>", "<span class='notice'>You [welded ? "weld" : "unweld"] [src].</span>")
		update_icon()

/obj/machinery/door/firedoor/try_to_crowbar(obj/item/I, mob/user)
	if(welded || operating)
		if(user)
			balloon_alert(user, "opening failed!")
		return

	if(density)
		if(is_holding_pressure())
			// Предупреждаем, но не задерживаем. Ломом файрлок вскрывают ровно во
			// время разгерметизации, то есть пауза срабатывала тогда, когда мешала
			// сильнее всего, и ничем не заканчивалась: ни урона, ни отмены за ней
			// не следовало. Разгерметизацию сдерживает whack_a_mole ниже.
			to_chat(user, "<span class='warning'>Из щели [src] бьёт воздух - с той стороны другое давление.</span>")
			log_game("[key_name_admin(user)] has opened a firelock with a pressure difference at [AREACOORD(loc)]") // there bibby I made it logged just for you. Enjoy.
			// since we have high-pressure-ness, close all other firedoors on the tile
			whack_a_mole()
		if(welded || operating || !density)
			return // whack_a_mole мог задеть и эту дверь
		// Ломом дверь открывают осознанно и обычно затем, чтобы через неё пройти
		// или протащить баллон. Шести секунд на это не хватало: любой следующий
		// переход тревоги захлопывал дверь прямо в проходе.
		emergency_close_timer = world.time + FIRELOCK_MANUAL_OVERRIDE_GRACE
		auto_closed = FALSE
		open()
	else
		// Закрыл человек - автоматика открывать обратно не лезет.
		auto_closed = FALSE
		close()

/obj/machinery/door/firedoor/proc/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if(A && A.fire)
		return FALSE
	return !is_holding_pressure()

/obj/machinery/door/firedoor/attack_ai(mob/user)
	add_fingerprint(user)
	if(welded || operating || machine_stat & NOPOWER)
		return TRUE
	// Ручное управление, пусть и силиконовое: автоматика в его решение не лезет.
	auto_closed = FALSE
	if(density)
		open()
	else
		close()
	return TRUE

/obj/machinery/door/firedoor/attack_robot(mob/user)
	return attack_ai(user)

/obj/machinery/door/firedoor/attack_alien(mob/user)
	add_fingerprint(user)
	if(welded)
		to_chat(user, "<span class='warning'>[src] refuses to budge!</span>")
		return
	auto_closed = FALSE
	open()

/obj/machinery/door/firedoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("door_opening", src)
		if("closing")
			flick("door_closing", src)

/// Which alarm lamp this firelock should be showing, or null for dark. The
/// alarm type doubles as the icon state name, so the sensor's own verdict is
/// what the crew sees on the door.
/obj/machinery/door/firedoor/proc/alarm_overlay_state()
	if(!alarm_type || (machine_stat & NOPOWER))
		return null
	return alarm_type

/obj/machinery/door/firedoor/update_icon()
	cut_overlays()
	if(density)
		icon_state = "door_closed"
		if(welded)
			add_overlay("welded")
	else
		icon_state = "door_open"
		if(welded)
			add_overlay("welded_open")
	var/lamp_state = alarm_overlay_state()
	if(lamp_state)
		add_overlay(lamp_state)

/obj/machinery/door/firedoor/open()
	playsound(loc, door_open_sound, 100, TRUE)
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/close()
	playsound(loc, door_close_sound, 100, TRUE)
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/proc/whack_a_mole(reconsider_immediately = FALSE)
	set waitfor = 0
	for(var/cdir in GLOB.cardinals)
		if((flags_1 & ON_BORDER_1) && cdir != dir)
			continue
		whack_a_mole_part(get_step(src, cdir), reconsider_immediately)
	if(flags_1 & ON_BORDER_1)
		whack_a_mole_part(get_turf(src), reconsider_immediately)

/obj/machinery/door/firedoor/proc/whack_a_mole_part(turf/start_point, reconsider_immediately)
	set waitfor = 0
	var/list/doors_to_close = list()
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			if(turfs[T2])
				continue
			var/is_cut_by_unopen_door = FALSE
			for(var/obj/machinery/door/firedoor/FD in T2)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T2, T) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door = TRUE

			for(var/obj/machinery/door/firedoor/FD in T)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T, T2) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				doors_to_close += FD
				is_cut_by_unopen_door= TRUE
			if(!is_cut_by_unopen_door)
				turfs[T2] = 1
	if(turfs.len > 10)
		return // too big, don't bother
	for(var/obj/machinery/door/firedoor/FD in doors_to_close)
		FD.emergency_pressure_stop(FALSE)
		if(reconsider_immediately)
			var/turf/open/T = FD.loc
			if(istype(T))
				T.ImmediateCalculateAdjacentTurfs()

/obj/machinery/door/firedoor/proc/emergency_pressure_stop(consider_timer = TRUE)
	set waitfor = 0
	if(density || operating || welded)
		return
	if(world.time >= emergency_close_timer || !consider_timer)
		mark_auto_closed()
		close()

/// Отмечает закрытие как сделанное автоматикой и взводит отложенную проверку на
/// открытие. Без неё дверь, закрытую мимо системы тревог, открыть было некому:
/// recompute_atmos_alarm() ходит только по фронту тревоги, а у такого закрытия
/// фронта нет вовсе - тревога как была пустой, так и осталась.
/obj/machinery/door/firedoor/proc/mark_auto_closed()
	auto_closed = TRUE
	schedule_auto_reopen()

/obj/machinery/door/firedoor/proc/schedule_auto_reopen()
	if(!auto_closed)
		return
	// Одноразовый таймер с самоперевзводом: TIMER_LOOP тут не годится, из него
	// нельзя сняться собственным deltimer. Джиттер разводит двери, закрытые
	// одной волной разгерметизации: без него сотни is_holding_pressure()
	// ретраились в один тик каждые десять секунд до конца пожара.
	reopen_timer = addtimer(CALLBACK(src, PROC_REF(try_auto_reopen)), FIRELOCK_AUTO_REOPEN_RETRY + rand(0, FIRELOCK_AUTO_REOPEN_JITTER), TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_STOPPABLE)

/// Причина автоматического закрытия могла уйти без единого события на
/// наблюдаемых турфах: зона сняла пожарную тревогу, перепад давления рассосался,
/// шаттл улетел от пробоины. Пока причина держится - перевзводимся и ждём дальше.
/obj/machinery/door/firedoor/proc/try_auto_reopen()
	reopen_timer = null
	if(!auto_closed)
		return
	if(!density || welded)
		auto_closed = FALSE
		return
	if(operating || firelock_alarm_seals(alarm_type))
		schedule_auto_reopen()
		return
	for(var/area/affected as anything in affecting_areas)
		if(affected.fire)
			schedule_auto_reopen()
			return
	if(is_holding_pressure())
		schedule_auto_reopen()
		return
	auto_closed = FALSE
	// door/open() спит анимацию целую секунду, а этот прок - таймерный колбек:
	// синхронное открытие держало SStimer по 300-350мс на дверь в разгар
	// станционного пожара (раунд 9911).
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/machinery/door/firedoor, open))

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/targetloc = get_turf(src)
		if(disassembled || prob(40))
			var/obj/structure/firelock_frame/unbuilt_lock = new assemblytype(targetloc)
			if(disassembled)
				unbuilt_lock.constructionStep = CONSTRUCTION_PANEL_OPEN
			else
				unbuilt_lock.constructionStep = CONSTRUCTION_WIRES_EXPOSED
				unbuilt_lock.obj_integrity = unbuilt_lock.max_integrity * 0.5
			unbuilt_lock.update_appearance()
	qdel(src)

/obj/machinery/door/firedoor/proc/latetoggle()
	if(operating || machine_stat & NOPOWER || !nextstate)
		return
	switch(nextstate)
		if(FIREDOOR_OPEN)
			nextstate = null
			open()
		if(FIREDOOR_CLOSED)
			nextstate = null
			close()

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	flags_1 = ON_BORDER_1|DEFAULT_RICOCHET_1
	CanAtmosPass = ATMOS_PASS_PROC

/obj/machinery/door/firedoor/border_only/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

/obj/machinery/door/firedoor/border_only/close()
	if(density)
		return TRUE
	if(operating || welded)
		return
	var/turf/T1 = get_turf(src)
	var/turf/T2 = get_step(T1, dir)
	for(var/mob/living/M in T1)
		if(M.stat == CONSCIOUS && M.pulling && M.pulling.loc == T2 && !M.pulling.anchored && M.pulling.move_resist <= M.move_force)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, "<span class='notice'>You pull [M.pulling] through [src] right as it closes</span>")
				M.pulling.forceMove(T1)
				M.start_pulling(M2)

	for(var/mob/living/M in T2)
		if(M.stat == CONSCIOUS && M.pulling && M.pulling.loc == T1 && !M.pulling.anchored && M.pulling.move_resist <= M.move_force)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, "<span class='notice'>You pull [M.pulling] through [src] right as it closes</span>")
				M.pulling.forceMove(T2)
				M.start_pulling(M2)
	. = ..()

/obj/machinery/door/firedoor/border_only/allow_hand_open(mob/user)
	var/area/A = get_area(src)
	if((!A || !A.fire) && !is_holding_pressure())
		return TRUE
	whack_a_mole(TRUE) // WOOP WOOP SIDE EFFECTS
	var/turf/T = loc
	var/turf/T2 = get_step(T, dir)
	if(!T || !T2)
		return
	var/status1 = check_door_side(T)
	var/status2 = check_door_side(T2)
	if((status1 == 1 && status2 == -1) || (status1 == -1 && status2 == 1))
		to_chat(user, "<span class='warning'>Доступ запрещён. Попробуйте закрыть другой пожарный шлюз, чтобы уменьшить разгерметизацию, или используйте лом.</span>")
		return FALSE
	return TRUE

/obj/machinery/door/firedoor/border_only/proc/check_door_side(turf/open/start_point)
	var/list/turfs = list()
	turfs[start_point] = 1
	for(var/i = 1; (i <= turfs.len && i <= 11); i++) // check up to 11 turfs.
		var/turf/open/T = turfs[i]
		if(istype(T, /turf/open/space))
			return -1
		for(var/T2 in T.atmos_adjacent_turfs)
			turfs[T2] = 1
	if(turfs.len <= 10)
		return FALSE // not big enough to matter
	return start_point.air.return_pressure() < 20 ? -1 : 1

/obj/machinery/door/firedoor/border_only/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!(get_dir(loc, target) == dir)) //Make sure looking at appropriate border
		return TRUE

/obj/machinery/door/firedoor/border_only/CanAStarPass(obj/item/card/id/ID, to_dir)
	return !density || (dir != to_dir)

/obj/machinery/door/firedoor/border_only/CheckExit(atom/movable/mover as mob|obj, turf/target)
	if(get_dir(loc, target) == dir)
		return !density
	return TRUE

/obj/machinery/door/firedoor/border_only/CanAtmosPass(turf/T)
	if(get_dir(loc, T) == dir)
		return !density
	else
		return TRUE

/obj/machinery/door/firedoor/heavy
	name = "heavy firelock"
	icon = 'icons/obj/doors/Doorfire.dmi'
	glass = FALSE
	explosion_block = 2
	assemblytype = /obj/structure/firelock_frame/heavy
	max_integrity = 550

/obj/machinery/door/firedoor/window
	name = "window shutter"
	icon = 'icons/obj/doors/doorfirewindow.dmi'
	desc = "A second window that slides in when the original window is broken, designed to protect against hull breaches. Truly a work of genius by NT engineers."
	glass = TRUE
	explosion_block = 0
	max_integrity = 50
	resistance_flags = 0 // not fireproof
	heat_proof = FALSE

/obj/machinery/door/firedoor/window/allow_hand_open()
	return TRUE

/obj/item/electronics/firelock
	name = "firelock circuitry"
	custom_price = PRICE_CHEAP
	desc = "A circuit board used in construction of firelocks."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "A partially completed firelock."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame1"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NOCIRCUIT
	var/reinforced = 0

/obj/structure/firelock_frame/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += "<span class='notice'>It is <i>unbolted</i> from the floor. A small <b>loosely connected</b> metal plate is covering the wires.</span>"
			if(!reinforced)
				. += "<span class='notice'>It could be reinforced with plasteel.</span>"
		if(CONSTRUCTION_WIRES_EXPOSED)
			. += "<span class='notice'>The maintenance plate has been <i>pried away</i>, and <b>wires</b> are trailing.</span>"
		if(CONSTRUCTION_GUTTED)
			. += "<span class='notice'>The maintenance panel is missing <i>wires</i> and the circuit board is <b>loosely connected</b>.</span>"
		if(CONSTRUCTION_NOCIRCUIT)
			. += "<span class='notice'>There are no <i>firelock electronics</i> in the frame. The frame could be <b>cut</b> apart.</span>"

/obj/structure/firelock_frame/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(reinforced)
			new /obj/item/stack/sheet/plasteel(loc, 5)
			new /obj/item/electronics/firelock(loc)
		else
			new /obj/item/stack/sheet/metal(loc, 5)
			new /obj/item/electronics/firelock(loc)
	qdel(src)

/obj/structure/firelock_frame/update_icon_state()
	icon_state = "frame[constructionStep]"

/obj/structure/firelock_frame/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(C.tool_behaviour == TOOL_CROWBAR)
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] starts prying something out from [src]...</span>", \
									 "<span class='notice'>You begin prying out the wire cover...</span>")
				if(!C.use_tool(src, user, 50))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message("<span class='notice'>[user] pries out a metal plate from [src], exposing the wires.</span>", \
									 "<span class='notice'>You remove the cover plate from [src], exposing the wires.</span>")
				constructionStep = CONSTRUCTION_WIRES_EXPOSED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_WRENCH)
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					to_chat(user, "<span class='warning'>There's already a firelock there.</span>")
					return
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] starts bolting down [src]...</span>", \
									 "<span class='notice'>You begin bolting [src]...</span>")
				if(!C.use_tool(src, user, 30))
					return
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					return
				user.visible_message("<span class='notice'>[user] finishes the firelock.</span>", \
									 "<span class='notice'>You finish the firelock.</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(reinforced)
					new /obj/machinery/door/firedoor/heavy(get_turf(src))
				else
					new /obj/machinery/door/firedoor(get_turf(src))
				qdel(src)
				return
			if(istype(C, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = C
				if(reinforced)
					to_chat(user, "<span class='warning'>[src] is already reinforced.</span>")
					return
				if(P.get_amount() < 2)
					to_chat(user, "<span class='warning'>You need more plasteel to reinforce [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] begins reinforcing [src]...</span>", \
									 "<span class='notice'>You begin reinforcing [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 60, target = src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || P.get_amount() < 2 || !P)
						return
					user.visible_message("<span class='notice'>[user] reinforces [src].</span>", \
										 "<span class='notice'>You reinforce [src].</span>")
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					P.use(2)
					reinforced = 1
				return

		if(CONSTRUCTION_WIRES_EXPOSED)
			if(C.tool_behaviour == TOOL_WIRECUTTER)
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] starts cutting the wires from [src]...</span>", \
									 "<span class='notice'>You begin removing [src]'s wires...</span>")
				if(!C.use_tool(src, user, 60))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				user.visible_message("<span class='notice'>[user] removes the wires from [src].</span>", \
									 "<span class='notice'>You remove the wiring from [src], exposing the circuit board.</span>")
				new/obj/item/stack/cable_coil(get_turf(src), 5)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_CROWBAR)
				C.play_tool_sound(src)
				user.visible_message("<span class='notice'>[user] starts prying a metal plate into [src]...</span>", \
									 "<span class='notice'>You begin prying the cover plate back onto [src]...</span>")
				if(!C.use_tool(src, user, 80))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message("<span class='notice'>[user] pries the metal plate into [src].</span>", \
									 "<span class='notice'>You pry [src]'s cover plate into place, hiding the wires.</span>")
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_icon()
				return
		if(CONSTRUCTION_GUTTED)
			if(C.tool_behaviour == TOOL_CROWBAR)
				user.visible_message("<span class='notice'>[user] begins removing the circuit board from [src]...</span>", \
									 "<span class='notice'>You begin prying out the circuit board from [src]...</span>")
				if(!C.use_tool(src, user, 50, volume=50))
					return
				if(constructionStep != CONSTRUCTION_GUTTED)
					return
				user.visible_message("<span class='notice'>[user] removes [src]'s circuit board.</span>", \
									 "<span class='notice'>You remove the circuit board from [src].</span>")
				new /obj/item/electronics/firelock(drop_location())
				constructionStep = CONSTRUCTION_NOCIRCUIT
				update_icon()
				return
			if(istype(C, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/B = C
				if(B.get_amount() < 5)
					to_chat(user, "<span class='warning'>You need more wires to add wiring to [src].</span>")
					return
				user.visible_message("<span class='notice'>[user] begins wiring [src]...</span>", \
									 "<span class='notice'>You begin adding wires to [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 60, target = src))
					if(constructionStep != CONSTRUCTION_GUTTED || B.get_amount() < 5 || !B)
						return
					user.visible_message("<span class='notice'>[user] adds wires to [src].</span>", \
										 "<span class='notice'>You wire [src].</span>")
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					constructionStep = CONSTRUCTION_WIRES_EXPOSED
					update_icon()
				return
		if(CONSTRUCTION_NOCIRCUIT)
			if(C.tool_behaviour == TOOL_WELDER)
				if(!C.tool_start_check(user, amount=1))
					return
				user.visible_message("<span class='notice'>[user] begins cutting apart [src]'s frame...</span>", \
									 "<span class='notice'>You begin slicing [src] apart...</span>")

				if(C.use_tool(src, user, 40, volume=50, amount=1))
					if(constructionStep != CONSTRUCTION_NOCIRCUIT)
						return
					user.visible_message("<span class='notice'>[user] cuts apart [src]!</span>", \
										 "<span class='notice'>You cut [src] into metal.</span>")
					var/turf/T = get_turf(src)
					new /obj/item/stack/sheet/metal(T, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(T, 2)
					qdel(src)
				return
			if(istype(C, /obj/item/electronics/firelock))
				user.visible_message("<span class='notice'>[user] starts adding [C] to [src]...</span>", \
									 "<span class='notice'>You begin adding a circuit board to [src]...</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(!do_after(user, 40, target = src))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT)
					return
				qdel(C)
				user.visible_message("<span class='notice'>[user] adds a circuit to [src].</span>", \
									 "<span class='notice'>You insert and secure [C].</span>")
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(istype(C, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = C
				if(!P.adapt_circuit(user, 30))
					return
				user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
				"<span class='notice'>You adapt a firelock circuit and slot it into the assembly.</span>")
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
	return ..()

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((constructionStep == CONSTRUCTION_NOCIRCUIT) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
			"<span class='notice'>You adapt a firelock circuit and slot it into the assembly.</span>")
			constructionStep = CONSTRUCTION_GUTTED
			update_icon()
			return TRUE
	return FALSE

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = TRUE

#undef CONSTRUCTION_COMPLETE
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_WIRES_EXPOSED
#undef CONSTRUCTION_GUTTED
#undef CONSTRUCTION_NOCIRCUIT

/obj/machinery/door/firedoor
	name = "Emergency Shutter"
	desc = "Emergency air-tight shutter, capable of sealing off breached areas. This one has a glass panel. It has a mechanism to open it with crowbar."
	icon = 'modular_bluemoon/icons/obj/aesthetics/firedoor/firedoor_glass.dmi'
	var/door_open_sound = 'modular_bluemoon/sound/machines/firedoor_open.ogg'
	var/door_close_sound = 'modular_bluemoon/sound/machines/firedoor_open.ogg'

/obj/machinery/door/firedoor/heavy
	name = "Heavy Emergency Shutter"
	desc = "Emergency air-tight shutter, capable of sealing off breached areas. It has a mechanism to open it with just your hands."
	icon = 'modular_bluemoon/icons/obj/aesthetics/firedoor/firedoor.dmi'

/obj/effect/spawner/structure/window/reinforced/no_firelock
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

/obj/machinery/door/firedoor/heavy/closed
	icon_state = "door_closed"
	density = TRUE

/obj/machinery/door/firedoor/solid
	name = "Solid Emergency Shutter"
	desc = "Emergency air-tight shutter, capable of sealing off breached areas. It has a mechanism to open it with just your hands."
	icon = 'modular_bluemoon/icons/obj/aesthetics/firedoor/firedoor.dmi'
	glass = FALSE

/obj/machinery/door/firedoor/solid/closed
	icon_state = "door_closed"
	density = TRUE
	opacity = TRUE

/obj/machinery/door/firedoor/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, be_close = TRUE))
		return
	try_manual_override(user)

/obj/machinery/door/firedoor/proc/try_manual_override(mob/user)
	if(density && !welded && !operating)
		balloon_alert(user, "opening...")
		if(do_after(user, 10 SECONDS, target = src))
			try_to_crowbar(null, user)
			return TRUE
	return FALSE
