#define CONSTRUCTION_COMPLETE 0 //No construction done - functioning as normal
#define CONSTRUCTION_PANEL_OPEN 1 //Maintenance panel is open, still functioning
#define CONSTRUCTION_WIRES_EXPOSED 2 //Cover plate is removed, wires are available
#define CONSTRUCTION_GUTTED 3 //Wires are removed, circuit ready to remove
#define CONSTRUCTION_NOCIRCUIT 4 //Circuit board removed, can safely weld apart

/obj/machinery/door/firedoor
	name = "firelock"
	desc = "Воспользуйтесь ломом."
	icon = 'icons/obj/doors/Doorfireglass.dmi'
	icon_state = "door_open"
	opacity = FALSE
	density = FALSE
	max_integrity = 100
	resistance_flags = FIRE_PROOF
	heat_proof = TRUE
	glass = TRUE
	sub_door = TRUE
	explosion_block = 1
	safe = FALSE
	layer = BELOW_OPEN_DOOR_LAYER
	closingLayer = CLOSED_FIREDOOR_LAYER
	assemblytype = /obj/structure/firelock_frame
	armor_type = /datum/armor/firedoor
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON | INTERACT_MACHINE_REQUIRES_SILICON | INTERACT_MACHINE_OPEN
	air_tight = TRUE
	attack_hand_is_action = TRUE
	attack_hand_speed = CLICK_CD_MELEE
	can_open_with_hands = FALSE
	opening_passable_delay = DOOR_OPENING_PASSABLE_DELAY
	var/emergency_close_timer = 0
	var/automatic_close_timer
	var/nextstate = null
	var/list/affecting_areas
	///Shared by every touching firelock in the merger group: turf -> alarm type.
	var/list/issue_turfs
	///Turfs this firelock holds exposure registrations on (center + cardinals).
	var/list/turf/watched_atmos_turfs
	var/alarm_type
	// Последний нарисованный оверлей: изменения датчика не должны перерисовывать неизменную лампу.
	var/displayed_alarm_state
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
	// Перекрывающиеся локдауны запрещают автооткрытие до снятия последнего.
	var/lockdown_count = 0
	// Зоны, для которых дверь входит в подтверждённую границу изоляции пробоины.
	var/list/decompression_seal_areas
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
	if(welded)
		. += span_notice("Дверь <i>заварена</i>. Для разборки открутите крепёжные болты <b>гаечным ключом</b>.")
	else if(!density)
		. += span_notice("Дверь открыта. Её можно закрыть <b>ломом</b>.")
	else
		. += span_notice("Дверь закрыта. Её можно открыть <i>ломом</i>. Для разборки её необходимо <b>заварить</b>.")
	if(alarm_type == FIRELOCK_ALARM_TYPE_COLD)
		. += span_notice("Атмосферный датчик сообщает: за дверью холоднее, чем задумано для этой комнаты. От холода дверь не закрывается - это предупреждение тому, кто собрался войти без скафандра.")
	else if(alarm_type)
		. += span_warning("Атмосферный датчик сообщает: [alarm_type == FIRELOCK_ALARM_TYPE_HOT ? "опасный нагрев" : "общая угроза"].")
	if(!fire_detection)
		. += span_notice("Детекция снята проводом на пожарной сигнализации зоны: дверь слушает только ручное управление.")
	. += span_notice("Alt-клик позволяет открыть дверь ручным приводом. Упершись в закрытую дверь, можно попробовать открыть её вручную.")
	. += span_notice("Ручное открытие, в том числе ломом или при столкновении, блокирует автоматическое закрытие на [DisplayTimeText(FIRELOCK_MANUAL_OVERRIDE_GRACE)].")
	. += span_notice("Ctrl-клик [should_block_on_ctrl_click() ? "блокирует автоматическое закрытие ([DisplayTimeText(FIRELOCK_CTRL_CLICK_OVERRIDE_TIME)])" : "снимает блокировку автоматического закрытия"].")
	if(!can_auto_close())
		. += span_notice("Автоматическое закрытие заблокировано ещё на [DisplayTimeText(emergency_close_timer - world.time)].")

/obj/machinery/door/firedoor/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, should_block_on_ctrl_click() ? "Блокировать автозакрытие" : "Разблокировать автозакрытие")
	. = CONTEXTUAL_SCREENTIP_SET

	if (isnull(held_item))
		if (density)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Постучать")
			return CONTEXTUAL_SCREENTIP_SET
		else
			return .

	switch (held_item.tool_behaviour)
		if (TOOL_CROWBAR)
			if(!welded)
				LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (density ? "Открыть" : "Закрыть"))
				return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_WELDER)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, (welded ? "Разварить" : "Заварить"))
			return CONTEXTUAL_SCREENTIP_SET
		if (TOOL_WRENCH)
			if (welded)
				LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_ANY, "Открутить болты")
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
	var/was_decompression_seal = is_decompression_seal()
	for(var/area/base as anything in decompression_seal_areas)
		var/datum/decompression_seal/seal = SSair?.decompression_seals[base]
		seal?.doors.Remove(src)
	decompression_seal_areas = null
	if(was_decompression_seal && !QDELING(src))
		refresh_alarm_overlay()
	if(affecting_areas)
		for(var/I in affecting_areas)
			var/area/A = I
			LAZYREMOVE(A.firedoors, src)
// обнуление affecting_areas в firedoor для надёжности. тк возможная утечка
/obj/machinery/door/firedoor/Destroy()
	if(automatic_close_timer)
		deltimer(automatic_close_timer)
		automatic_close_timer = null
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
		door.refresh_alarm_overlay()
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
		door.refresh_alarm_overlay()
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

// Жар и тревога зоны закрывают дверь, холод лишь индицируется на уже закрытой.
// Разгерметизацию по-прежнему ловит перепад давления, а не температурная тревога.
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
	recompute_atmos_alarm(source)

/obj/machinery/door/firedoor/proc/recompute_atmos_alarm(turf/changed_turf)
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
		// Общий вердикт группы мог остаться прежним, хотя местная угроза изменилась.
		if(changed_turf)
			for(var/obj/machinery/door/firedoor/door as anything in group_members)
				if(changed_turf in door.watched_atmos_turfs)
					door.refresh_alarm_overlay()
		else
			refresh_alarm_overlay()
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
			if(!area_alarm && door.density && door.auto_closed && !door.welded && !door.operating && door.can_auto_reopen() && !door.is_holding_pressure())
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
	if(iscarbon(AM))
		var/mob/living/carbon/L = AM
		if(!density || (src in L.do_afters))
			return FALSE
		var/obj/item/crowbar = L.is_holding_tool_quality(TOOL_CROWBAR)
		if(crowbar)
			try_to_crowbar(crowbar, L)
		else
			try_manual_override(L, DOOR_BUMP_OVERRIDE_TIME)
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

	user.visible_message(span_notice("[user] стучит по [src]."), span_notice("Вы стучите по [src]."))
	playsound(loc, 'sound/effects/glassknock.ogg', 10, FALSE, frequency = 32000)

/obj/machinery/door/firedoor/attackby(obj/item/C, mob/user, params)
	add_fingerprint(user)
	if(operating)
		return

	if(welded && C.tool_behaviour == TOOL_WRENCH)
		C.play_tool_sound(src)
		user.visible_message(span_notice("[user] начинает откручивать крепёжные болты [src]..."), span_notice("Вы начинаете откручивать крепёжные болты [src]..."))
		if(!C.use_tool(src, user, 3 SECONDS))
			return
		if(!welded || operating)
			return
		playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
		user.visible_message(span_notice("[user] откручивает крепёжные болты [src]."), span_notice("Вы откручиваете крепёжные болты [src]."))
		deconstruct(TRUE)
		return

	return ..()

/obj/machinery/door/firedoor/try_to_activate_door(mob/user, access_bypass = FALSE)
	return

/obj/machinery/door/firedoor/try_to_weld(obj/item/W, mob/user)
	if(!W.tool_behaviour == TOOL_WELDER)
		return
	if(!W.tool_start_check(user, amount=0))
		return
	user.visible_message(span_notice("[user] начинает [welded ? "разваривать" : "заваривать"] [src]."), span_notice("Вы начинаете [welded ? "разваривать" : "заваривать"] [src]."))
	if(W.use_tool(src, user, 40, volume=50))
		welded = !welded
		user.visible_message(span_danger("[user] [welded ? "заваривает" : "разваривает"] [src]."), span_notice("Вы [welded ? "завариваете" : "развариваете"] [src]."))
		update_icon()

/obj/machinery/door/firedoor/try_to_crowbar(obj/item/I, mob/user)
	if(welded || operating)
		if(user)
			balloon_alert(user, "не удалось открыть!")
		return

	if(density)
		if(is_holding_pressure())
			// Предупреждаем, но не задерживаем. Ломом файрлок вскрывают ровно во
			// время разгерметизации, то есть пауза срабатывала тогда, когда мешала
			// сильнее всего, и ничем не заканчивалась: ни урона, ни отмены за ней
			// не следовало. Разгерметизацию сдерживает whack_a_mole ниже.
			to_chat(user, span_warning("Из щели [src] бьёт воздух - с той стороны другое давление."))
			log_game("[key_name_admin(user)] has opened a firelock with a pressure difference at [AREACOORD(loc)]") // there bibby I made it logged just for you. Enjoy.
			// Ищем соседние заслонки, способные отсечь открываемую утечку.
			whack_a_mole()
		if(welded || operating || !density)
			return // whack_a_mole мог задеть и эту дверь
		// Защищаем и саму анимацию, и полный интервал после открытия.
		block_automatic_closing(FIRELOCK_MANUAL_OVERRIDE_GRACE)
		if(open())
			block_automatic_closing(FIRELOCK_MANUAL_OVERRIDE_GRACE)
	else
		// Закрыл человек - автоматика открывать обратно не лезет.
		auto_closed = FALSE
		nextstate = null
		close(manual = TRUE)

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
	nextstate = null
	var/was_closed = density
	if(density)
		open()
	else
		close(manual = TRUE)
	if(density != was_closed)
		log_remote_use(user, was_closed ? "opened" : "closed", "firelock interface")
	return TRUE

/obj/machinery/door/firedoor/attack_robot(mob/user)
	return attack_ai(user)

/obj/machinery/door/firedoor/attack_alien(mob/user)
	add_fingerprint(user)
	if(welded)
		to_chat(user, span_warning("[src] не поддаётся!"))
		return
	auto_closed = FALSE
	open()

/obj/machinery/door/firedoor/do_animate(animation, from_bump = FALSE)
	switch(animation)
		if("opening")
			icon_state = "door_open"
			refresh_alarm_overlay()
			flick("door_opening", src)
		if("closing")
			icon_state = "door_closed"
			flick("door_closing", src)

// Общий журнал управляет группой, но индикация показывает местные датчики
// и защитную работу конкретной двери. Открытие сразу гасит все оверлеи угроз.
/obj/machinery/door/firedoor/proc/alarm_overlay_state()
	if(!density || (operating && icon_state == "door_open") || (machine_stat & NOPOWER))
		return null
	var/local_alarm
	for(var/turf/checked as anything in watched_atmos_turfs)
		var/issue = issue_turfs?[checked]
		if(issue == FIRELOCK_ALARM_TYPE_HOT)
			return FIRELOCK_ALARM_TYPE_HOT
		if(issue == FIRELOCK_ALARM_TYPE_COLD)
			local_alarm = FIRELOCK_ALARM_TYPE_COLD
	if(generic_alarm || auto_closed || lockdown_count || is_decompression_seal())
		return FIRELOCK_ALARM_TYPE_GENERIC
	return local_alarm

/obj/machinery/door/firedoor/proc/refresh_alarm_overlay()
	if(alarm_overlay_state() != displayed_alarm_state)
		update_icon()

/obj/machinery/door/firedoor/update_icon()
	cut_overlays()
	if(!operating)
		icon_state = density ? "door_closed" : "door_open"
	if(welded)
		add_overlay(density ? "welded" : "welded_open")
	var/lamp_state = alarm_overlay_state()
	displayed_alarm_state = lamp_state
	if(lamp_state)
		add_overlay(lamp_state)

/obj/machinery/door/firedoor/open()
	playsound(loc, door_open_sound, 100, TRUE)
	. = ..()
	latetoggle()

// Команда игрока через сигнализацию равнозначна ручному открытию с короткой защитой.
/obj/machinery/door/firedoor/proc/open_manually()
	if(welded)
		return FALSE
	auto_closed = FALSE
	block_automatic_closing(FIRELOCK_ALARM_OVERRIDE_GRACE)
	if(operating)
		nextstate = FIREDOOR_OPEN_MANUAL
		return TRUE
	. = open()
	if(.)
		block_automatic_closing(FIRELOCK_ALARM_OVERRIDE_GRACE)

// Команда игрока через сигнализацию не снимает блокировку, но закрывает дверь вручную.
/obj/machinery/door/firedoor/proc/close_manually()
	if(welded)
		return FALSE
	auto_closed = FALSE
	if(operating)
		nextstate = FIREDOOR_CLOSED_MANUAL
		return TRUE
	nextstate = null
	return close(manual = TRUE)

/obj/machinery/door/firedoor/hostile_lockdown(mob/origin)
	lockdown_count++
	if(machine_stat)
		return
	// Убираем старое открытие; уже идущую анимацию завершаем закрытием.
	nextstate = operating ? FIREDOOR_CLOSED : null
	if(!density || (operating && icon_state == "door_open"))
		mark_auto_closed()
	refresh_alarm_overlay()
	if(!operating)
		close()

/obj/machinery/door/firedoor/disable_lockdown()
	lockdown_count = max(0, lockdown_count - 1)
	refresh_alarm_overlay()
	// Снятие события не отменяет пробоину, пожар или ручное закрытие двери.
	if(!lockdown_count && !machine_stat)
		try_auto_reopen()

// alarm_checked действует только в текущей цепочке вызовов до начала анимации.
// Отложенное закрытие через nextstate всегда проверяет состояние заново.
/obj/machinery/door/firedoor/close(manual = FALSE, alarm_checked = FALSE)
	if(!manual && (!can_auto_close() || (!alarm_checked && !can_close_for_alarm())))
		return FALSE
	playsound(loc, door_close_sound, 100, TRUE)
	. = ..()
	latetoggle()

/obj/machinery/door/firedoor/proc/can_auto_close()
	return world.time >= emergency_close_timer

/obj/machinery/door/firedoor/proc/can_close_for_alarm()
	if(!can_auto_close())
		return FALSE
	if(alarm_type != FIRELOCK_ALARM_TYPE_GENERIC)
		return TRUE
	// Общая тревога не дублирует уже герметичную преграду. Проверяем её текущее
	// состояние: открытый шлюз или откреплённое окно должны пропускать воздух.
	var/turf/door_turf = get_turf(src)
	var/unsealed_directions = (flags_1 & ON_BORDER_1) ? dir : (NORTH|SOUTH|EAST|WEST)
	for(var/obj/blocker in door_turf)
		if(blocker == src || blocker.CanAtmosPass == ATMOS_PASS_YES)
			continue
		for(var/direction in GLOB.cardinals)
			if(!(unsealed_directions & direction))
				continue
			var/turf/neighbor = get_step(door_turf, direction)
			if(!neighbor || !CANATMOSPASS(blocker, neighbor))
				unsealed_directions &= ~direction
		if(!unsealed_directions)
			return FALSE
	return TRUE

/obj/machinery/door/firedoor/proc/should_block_on_ctrl_click()
	return emergency_close_timer - world.time <= FIRELOCK_MANUAL_OVERRIDE_GRACE

/obj/machinery/door/firedoor/proc/block_automatic_closing(duration)
	emergency_close_timer = max(emergency_close_timer, world.time + duration)
	nextstate = null
	// Уже закрытая автоматикой дверь должна сохранять возможность открыться сама.
	if(!density)
		auto_closed = FALSE
	automatic_close_timer = addtimer(CALLBACK(src, PROC_REF(resume_automatic_closing)), emergency_close_timer - world.time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT|TIMER_STOPPABLE)

/obj/machinery/door/firedoor/proc/unblock_automatic_closing()
	if(automatic_close_timer)
		deltimer(automatic_close_timer)
		automatic_close_timer = null
	emergency_close_timer = 0
	resume_automatic_closing()

/obj/machinery/door/firedoor/proc/resume_automatic_closing()
	automatic_close_timer = null
	if(!can_auto_close() || density || welded)
		return
	if(operating)
		automatic_close_timer = addtimer(CALLBACK(src, PROC_REF(resume_automatic_closing)), 1 SECONDS, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT|TIMER_STOPPABLE)
		return
	var/should_close = firelock_alarm_seals(alarm_type)
	for(var/area/affected as anything in affecting_areas)
		if(affected.fire)
			should_close = TRUE
			break
	if(should_close || is_holding_pressure(include_open = TRUE))
		emergency_pressure_stop()

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
	// Обход не спит и не закрывает двери до конца сбора: результат здесь неизменен.
	var/list/close_checks = list()
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
				if(isnull(close_checks[FD]))
					close_checks[FD] = FD.can_close_for_alarm()
				if(!close_checks[FD])
					continue
				doors_to_close[FD] = TRUE
				is_cut_by_unopen_door = TRUE

			for(var/obj/machinery/door/firedoor/FD in T)
				if((FD.flags_1 & ON_BORDER_1) && get_dir(T, T2) != FD.dir)
					continue
				if(FD.operating || FD == src || FD.welded || FD.density)
					continue
				if(isnull(close_checks[FD]))
					close_checks[FD] = FD.can_close_for_alarm()
				if(!close_checks[FD])
					continue
				doors_to_close[FD] = TRUE
				is_cut_by_unopen_door= TRUE
			if(!is_cut_by_unopen_door)
				turfs[T2] = 1
	if(turfs.len > 10)
		return // too big, don't bother
	for(var/obj/machinery/door/firedoor/FD in doors_to_close)
		FD.emergency_pressure_stop()
		if(reconsider_immediately)
			var/turf/open/T = FD.loc
			if(istype(T))
				T.ImmediateCalculateAdjacentTurfs()

/obj/machinery/door/firedoor/proc/emergency_pressure_stop()
	set waitfor = 0
	if(density || operating || welded || !can_close_for_alarm())
		return
	mark_auto_closed(alarm_checked = TRUE)
	close(alarm_checked = TRUE)

/// Отмечает закрытие как сделанное автоматикой и взводит отложенную проверку на
/// открытие. Без неё дверь, закрытую мимо системы тревог, открыть было некому:
/// recompute_atmos_alarm() ходит только по фронту тревоги, а у такого закрытия
/// фронта нет вовсе - тревога как была пустой, так и осталась.
/obj/machinery/door/firedoor/proc/mark_auto_closed(alarm_checked = FALSE)
	if(!can_auto_close() || (!alarm_checked && !can_close_for_alarm()))
		return
	auto_closed = TRUE
	refresh_alarm_overlay()
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
	if(!can_auto_reopen() || is_holding_pressure())
		schedule_auto_reopen()
		return
	auto_closed = FALSE
	// door/open() спит анимацию целую секунду, а этот прок - таймерный колбек:
	// синхронное открытие держало SStimer по 300-350мс на дверь в разгар
	// станционного пожара (раунд 9911).
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/machinery/door/firedoor, open))

// Локализация уже проверила связность до пробоины; таймеру не нужен новый обход карты.
/obj/machinery/door/firedoor/proc/is_decompression_seal()
	return length(decompression_seal_areas) > 0

// Общие запреты для таймера, снятия тревоги и отложенных команд открытия.
/obj/machinery/door/firedoor/proc/can_auto_reopen()
	return !lockdown_count && !is_decompression_seal()

/obj/machinery/door/firedoor/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(the_rcd.mode != RCD_DECONSTRUCT || (flags_1 & NODECONSTRUCT_1) || (resistance_flags & INDESTRUCTIBLE))
		return FALSE
	return list("mode" = RCD_DECONSTRUCT, "delay" = 2 SECONDS, "cost" = 16)

/obj/machinery/door/firedoor/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	if(passed_mode != RCD_DECONSTRUCT || (flags_1 & NODECONSTRUCT_1) || (resistance_flags & INDESTRUCTIBLE))
		return FALSE
	to_chat(user, span_notice("Вы разбираете [src]."))
	qdel(src)
	return TRUE

/obj/machinery/door/firedoor/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/turf/targetloc = get_turf(src)
		if(disassembled || prob(40))
			var/obj/structure/firelock_frame/unbuilt_lock = new assemblytype(targetloc)
			unbuilt_lock.setDir(dir)
			transfer_fingerprints_to(unbuilt_lock)
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
		if(FIREDOOR_OPEN, FIREDOOR_OPEN_MANUAL)
			var/manual_open = nextstate == FIREDOOR_OPEN_MANUAL
			nextstate = null
			if(manual_open)
				open_manually()
			else if(can_auto_reopen())
				open()
		if(FIREDOOR_CLOSED)
			nextstate = null
			close()
		if(FIREDOOR_CLOSED_MANUAL)
			nextstate = null
			close_manually()

/obj/machinery/door/firedoor/border_only
	icon = 'icons/obj/doors/edge_Doorfire.dmi'
	flags_1 = ON_BORDER_1|DEFAULT_RICOCHET_1
	CanAtmosPass = ATMOS_PASS_PROC

/obj/machinery/door/firedoor/border_only/closed
	icon_state = "door_closed"
	opacity = TRUE
	density = TRUE

/obj/machinery/door/firedoor/border_only/close(manual = FALSE, alarm_checked = FALSE)
	if(!manual && !can_close_for_alarm())
		return FALSE
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
				to_chat(M, span_notice("Вы успеваете протащить [M.pulling] через [src] перед закрытием."))
				M.pulling.forceMove(T1)
				M.start_pulling(M2)

	for(var/mob/living/M in T2)
		if(M.stat == CONSCIOUS && M.pulling && M.pulling.loc == T1 && !M.pulling.anchored && M.pulling.move_resist <= M.move_force)
			var/mob/living/M2 = M.pulling
			if(!istype(M2) || !M2.buckled || !M2.buckled.buckle_prevents_pull)
				to_chat(M, span_notice("Вы успеваете протащить [M.pulling] через [src] перед закрытием."))
				M.pulling.forceMove(T2)
				M.start_pulling(M2)
	// Перетаскивание могло изменить преграды на тайле: родитель проверяет их заново.
	. = ..(manual)

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
		to_chat(user, span_warning("Доступ запрещён. Попробуйте закрыть другой пожарный шлюз, чтобы уменьшить разгерметизацию, или используйте лом."))
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
	max_integrity = 250

/obj/machinery/door/firedoor/window
	name = "window shutter"
	icon = 'icons/obj/doors/doorfirewindow.dmi'
	desc = "Резервная оконная заслонка, закрывающая проём при разрушении окна для защиты от разгерметизации. Поистине гениальное изобретение инженеров НТ."
	glass = TRUE
	explosion_block = 0
	max_integrity = 50
	resistance_flags = 0 // not fireproof
	heat_proof = FALSE
	assemblytype = /obj/structure/firelock_frame/window

/obj/machinery/door/firedoor/window/allow_hand_open()
	return TRUE

/obj/machinery/door/firedoor/window/can_close_for_alarm()
	if(!..())
		return FALSE
	if(density)
		return TRUE
	var/turf/open/door_turf = get_turf(src)
	if(!isopenturf(door_turf) || door_turf.blocks_air)
		return FALSE
	// Читаем текущую проходимость без перестройки смежности, сброса кэшей атмосферы
	// и обновления нативных привязок. Это также видит уже разбитое, но ещё не удалённое окно.
	var/can_pass = CANATMOSPASS(door_turf, door_turf)
	var/can_vertical_pass = CANVERTICALATMOSPASS(door_turf, door_turf)
	var/list/neighbors = list()
	for(var/direction in GLOB.cardinals_multiz)
		var/turf/neighbor = get_step_multiz(door_turf, direction)
		if(!isopenturf(neighbor) || neighbor.blocks_air)
			continue
		if(direction & (UP|DOWN))
			if(!can_vertical_pass || !CANVERTICALATMOSPASS(neighbor, door_turf))
				continue
		else if(!can_pass || !CANATMOSPASS(neighbor, door_turf))
			continue
		// Прямой выход в космос нужно перекрывать даже при соседней открытой шторке.
		if(isspaceturf(door_turf) || isspaceturf(neighbor))
			return TRUE
		neighbors += neighbor
	// Шторка в тупике изолирует только собственный тайл.
	if(length(neighbors) < 2)
		return FALSE
	for(var/turf/neighbor as anything in neighbors)
		for(var/obj/machinery/door/firedoor/other in neighbor)
			if(!other.welded && other.can_auto_close())
				return TRUE
	var/list/pending = list(neighbors[1])
	var/list/seen = list()
	seen[door_turf] = TRUE
	seen[neighbors[1]] = TRUE
	neighbors -= neighbors[1]
	// Если все стороны связаны коротким обходом, закрытие шторки ничего не отсечёт.
	// Другие заслонки могут закрыться вместе: обход через них не считаем надёжным.
	for(var/index = 1; index <= length(pending) && index <= FIRELOCK_PASSAGE_CHECK_LIMIT; index++)
		var/turf/current = pending[index]
		for(var/turf/next as anything in current.atmos_adjacent_turfs)
			if(seen[next])
				continue
			seen[next] = TRUE
			var/blocked_by_firelock = FALSE
			for(var/obj/machinery/door/firedoor/other in next)
				if(!other.welded && other.can_auto_close())
					blocked_by_firelock = TRUE
					break
			if(blocked_by_firelock)
				continue
			pending += next
			neighbors -= next
			if(!length(neighbors))
				return FALSE
	// Если локальная проверка не доказала наличие обхода, сохраняем защиту прохода.
	return TRUE

/obj/item/electronics/firelock
	name = "firelock circuitry"
	custom_price = PRICE_CHEAP
	desc = "Плата управления для сборки фаерлоков."
	icon_state = "mainboard"

/obj/structure/firelock_frame
	name = "firelock frame"
	desc = "Частично собранный фаерлок."
	icon = 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame1"
	anchored = FALSE
	density = TRUE
	var/constructionStep = CONSTRUCTION_NOCIRCUIT
	var/reinforced = 0
	// Один лист стекла превращает обычный каркас в оконный.
	var/windowed = FALSE

/obj/structure/firelock_frame/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/structure/firelock_frame/examine(mob/user)
	. = ..()
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			. += span_notice("Крепёжные болты <i>откручены</i>. Панель над проводами можно открыть <b>отвёрткой</b>, а каркас закрепить <b>гаечным ключом</b>.")
			if(!reinforced && !windowed)
				. += span_notice("Каркас можно укрепить пласталью.")
		if(CONSTRUCTION_WIRES_EXPOSED)
			. += span_notice("Панель обслуживания <i>открыта</i>, наружу свисают <b>провода</b>. Панель можно закрыть <b>отвёрткой</b>.")
		if(CONSTRUCTION_GUTTED)
			. += span_notice("В панели обслуживания отсутствуют <i>провода</i>, а плата управления <b>не закреплена</b>.")
		if(CONSTRUCTION_NOCIRCUIT)
			if(windowed)
				. += span_notice("В каркасе отсутствует <i>электроника фаерлока</i>.")
				. += span_notice("<b>Сваркой</b> можно выварить лист стекла и превратить каркас в обычный.")
			else
				. += span_notice("В каркасе отсутствует <i>электроника фаерлока</i>. Каркас можно <b>разрезать</b>.")
				if(!reinforced)
					. += span_notice("Добавьте <b>один лист стекла</b>, чтобы собрать оконный фаерлок.")

/obj/structure/firelock_frame/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(windowed)
			new /obj/item/stack/sheet/glass(drop_location(), 1)
		if(reinforced)
			new /obj/item/stack/sheet/plasteel(loc, 5)
			new /obj/item/electronics/firelock(loc)
		else
			new /obj/item/stack/sheet/metal(loc, 5)
			new /obj/item/electronics/firelock(loc)
	qdel(src)

/obj/structure/firelock_frame/update_icon_state()
	icon = windowed ? 'icons/obj/doors/doorfirewindow.dmi' : 'icons/obj/doors/Doorfire.dmi'
	icon_state = "frame[constructionStep]"

/obj/structure/firelock_frame/attackby(obj/item/C, mob/user)
	switch(constructionStep)
		if(CONSTRUCTION_PANEL_OPEN)
			if(C.tool_behaviour == TOOL_SCREWDRIVER)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] начинает открывать панель [src]..."), span_notice("Вы начинаете открывать панель [src]..."))
				if(!C.use_tool(src, user, 1 SECONDS))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message(span_notice("[user] открывает панель [src], обнажая провода."), span_notice("Вы открываете панель [src], обнажая провода."))
				constructionStep = CONSTRUCTION_WIRES_EXPOSED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_WRENCH)
				if(locate(/obj/machinery/door/firedoor) in get_turf(src))
					to_chat(user, span_warning("Здесь уже установлен фаерлок."))
					return
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] начинает закреплять [src] болтами..."), \
									 span_notice("Вы начинаете закреплять [src] болтами..."))
				if(!C.use_tool(src, user, 2 SECONDS))
					return
				if(constructionStep != CONSTRUCTION_PANEL_OPEN || (locate(/obj/machinery/door/firedoor) in get_turf(src)))
					return
				user.visible_message(span_notice("[user] завершает сборку фаерлока."), \
									 span_notice("Вы завершаете сборку фаерлока."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				var/firelock_type = windowed ? /obj/machinery/door/firedoor/window : (reinforced ? /obj/machinery/door/firedoor/heavy : /obj/machinery/door/firedoor)
				var/obj/machinery/door/firedoor/built_firelock = new firelock_type(get_turf(src))
				built_firelock.setDir(dir)
				transfer_fingerprints_to(built_firelock)
				qdel(src)
				return
			if(istype(C, /obj/item/stack/sheet/plasteel))
				var/obj/item/stack/sheet/plasteel/P = C
				if(windowed)
					to_chat(user, span_warning("Оконный каркас нельзя укрепить пласталью."))
					return
				if(reinforced)
					to_chat(user, span_warning("[src] уже укреплён."))
					return
				if(P.get_amount() < 2)
					to_chat(user, span_warning("Для укрепления [src] нужно два листа пластали."))
					return
				user.visible_message(span_notice("[user] начинает укреплять [src]..."), \
									 span_notice("Вы начинаете укреплять [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 1 SECONDS, target = src))
					if(constructionStep != CONSTRUCTION_PANEL_OPEN || reinforced || P.get_amount() < 2 || !P)
						return
					user.visible_message(span_notice("[user] укрепляет [src]."), \
										 span_notice("Вы укрепляете [src]."))
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					P.use(2)
					reinforced = 1
				return

		if(CONSTRUCTION_WIRES_EXPOSED)
			if(C.tool_behaviour == TOOL_WIRECUTTER)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] начинает вырезать провода из [src]..."), \
									 span_notice("Вы начинаете вырезать провода из [src]..."))
				if(!C.use_tool(src, user, 1  SECONDS))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				user.visible_message(span_notice("[user] вырезает провода из [src]."), \
									 span_notice("Вы вырезаете провода из [src], открывая доступ к плате управления."))
				new/obj/item/stack/cable_coil(get_turf(src), 5)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(C.tool_behaviour == TOOL_SCREWDRIVER)
				C.play_tool_sound(src)
				user.visible_message(span_notice("[user] начинает закрывать панель [src]..."), span_notice("Вы начинаете закрывать панель [src]..."))
				if(!C.use_tool(src, user, 1 SECONDS))
					return
				if(constructionStep != CONSTRUCTION_WIRES_EXPOSED)
					return
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				user.visible_message(span_notice("[user] закрывает панель [src]."), span_notice("Вы закрываете панель [src]."))
				constructionStep = CONSTRUCTION_PANEL_OPEN
				update_icon()
				return
		if(CONSTRUCTION_GUTTED)
			if(C.tool_behaviour == TOOL_CROWBAR)
				user.visible_message(span_notice("[user] начинает извлекать плату управления из [src]..."), \
									 span_notice("Вы начинаете извлекать плату управления из [src] ломом..."))
				if(!C.use_tool(src, user, 1 SECONDS, volume=50))
					return
				if(constructionStep != CONSTRUCTION_GUTTED)
					return
				user.visible_message(span_notice("[user] извлекает плату управления из [src]."), \
									 span_notice("Вы извлекаете плату управления из [src]."))
				new /obj/item/electronics/firelock(drop_location())
				constructionStep = CONSTRUCTION_NOCIRCUIT
				update_icon()
				return
			if(istype(C, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/B = C
				if(B.get_amount() < 5)
					to_chat(user, span_warning("Для подключения проводки к [src] нужно пять отрезков кабеля."))
					return
				user.visible_message(span_notice("[user] начинает подключать проводку к [src]..."), \
									 span_notice("Вы начинаете подключать проводку к [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(do_after(user, 1 SECONDS, target = src))
					if(constructionStep != CONSTRUCTION_GUTTED || B.get_amount() < 5 || !B)
						return
					user.visible_message(span_notice("[user] подключает проводку к [src]."), \
										 span_notice("Вы подключаете проводку к [src]."))
					playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
					constructionStep = CONSTRUCTION_WIRES_EXPOSED
					update_icon()
				return
		if(CONSTRUCTION_NOCIRCUIT)
			if(istype(C, /obj/item/stack/sheet/glass))
				if(windowed || reinforced)
					to_chat(user, span_warning("Стекло можно установить только в обычный каркас без стекла."))
					return
				var/obj/item/stack/sheet/glass/glass_sheet = C
				balloon_alert(user, "установка стекла...")
				if(!do_after(user, 1 SECONDS, target = src))
					return
				if(QDELETED(glass_sheet) || constructionStep != CONSTRUCTION_NOCIRCUIT || windowed || reinforced || !glass_sheet.use(1))
					return
				windowed = TRUE
				update_appearance()
				return
			if(windowed && C.tool_behaviour == TOOL_WELDER)
				if(!C.tool_start_check(user, amount = 1))
					return
				balloon_alert(user, "вываривание стекла...")
				if(!C.use_tool(src, user, 1.5 SECONDS, volume = 50, amount = 1))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT || !windowed)
					return
				windowed = FALSE
				new /obj/item/stack/sheet/glass(drop_location(), 1)
				update_appearance()
				return
			if(C.tool_behaviour == TOOL_WELDER)
				if(!C.tool_start_check(user, amount=1))
					return
				user.visible_message(span_notice("[user] начинает разрезать каркас [src]..."), \
									 span_notice("Вы начинаете разрезать каркас [src]..."))

				if(C.use_tool(src, user, 2 SECONDS, volume=50, amount=1))
					if(constructionStep != CONSTRUCTION_NOCIRCUIT || windowed)
						return
					user.visible_message(span_notice("[user] разрезает каркас [src]!"), \
										 span_notice("Вы разрезаете каркас [src] на листы металла."))
					var/turf/T = get_turf(src)
					new /obj/item/stack/sheet/metal(T, 3)
					if(reinforced)
						new /obj/item/stack/sheet/plasteel(T, 2)
					qdel(src)
				return
			if(istype(C, /obj/item/electronics/firelock))
				user.visible_message(span_notice("[user] начинает устанавливать [C] в [src]..."), \
									 span_notice("Вы начинаете устанавливать плату управления в [src]..."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				if(!do_after(user, 1 SECONDS, target = src))
					return
				if(constructionStep != CONSTRUCTION_NOCIRCUIT)
					return
				qdel(C)
				user.visible_message(span_notice("[user] устанавливает плату управления в [src]."), \
									 span_notice("Вы устанавливаете и закрепляете [C]."))
				playsound(get_turf(src), 'sound/items/deconstruct.ogg', 50, 1)
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
			if(istype(C, /obj/item/electroadaptive_pseudocircuit))
				var/obj/item/electroadaptive_pseudocircuit/P = C
				if(!P.adapt_circuit(user, 30))
					return
				user.visible_message(span_notice("[user] создаёт плату управления и устанавливает её в [src]."), \
				span_notice("Вы создаёте плату управления фаерлока и устанавливаете её в каркас."))
				constructionStep = CONSTRUCTION_GUTTED
				update_icon()
				return
	return ..()

/obj/structure/firelock_frame/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if(constructionStep == CONSTRUCTION_NOCIRCUIT)
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/structure/firelock_frame/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			if(constructionStep != CONSTRUCTION_NOCIRCUIT)
				return FALSE
			user.visible_message(span_notice("[user] создаёт плату управления и устанавливает её в [src]."), \
			span_notice("Вы создаёте плату управления фаерлока и устанавливаете её в каркас."))
			constructionStep = CONSTRUCTION_GUTTED
			update_icon()
			return TRUE
	return FALSE

/obj/structure/firelock_frame/heavy
	name = "heavy firelock frame"
	reinforced = TRUE

/obj/structure/firelock_frame/window
	icon = 'icons/obj/doors/doorfirewindow.dmi'
	windowed = TRUE

#undef CONSTRUCTION_COMPLETE
#undef CONSTRUCTION_PANEL_OPEN
#undef CONSTRUCTION_WIRES_EXPOSED
#undef CONSTRUCTION_GUTTED
#undef CONSTRUCTION_NOCIRCUIT

/obj/machinery/door/firedoor
	name = "Emergency Shutter"
	desc = "Аварийная герметичная заслонка со стеклянной панелью для изоляции разгерметизированных отсеков. Её можно открыть ломом или ручным приводом."
	icon = 'modular_bluemoon/icons/obj/aesthetics/firedoor/firedoor_glass.dmi'
	var/door_open_sound = 'modular_bluemoon/sound/machines/firedoor_open.ogg'
	var/door_close_sound = 'modular_bluemoon/sound/machines/firedoor_open.ogg'

/obj/machinery/door/firedoor/heavy
	name = "Heavy Emergency Shutter"
	desc = "Тяжёлая аварийная герметичная заслонка для изоляции разгерметизированных отсеков. Её можно открыть ломом или ручным приводом."
	icon = 'modular_bluemoon/icons/obj/aesthetics/firedoor/firedoor.dmi'

/obj/effect/spawner/structure/window/reinforced/no_firelock
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/fulltile)

/obj/machinery/door/firedoor/heavy/closed
	icon_state = "door_closed"
	density = TRUE

/obj/machinery/door/firedoor/solid
	name = "Solid Emergency Shutter"
	desc = "Глухая аварийная герметичная заслонка для изоляции разгерметизированных отсеков. Её можно открыть ломом или ручным приводом."
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

/obj/machinery/door/firedoor/CtrlClick(mob/user)
	if(!user.canUseTopic(src, be_close = TRUE))
		return
	add_fingerprint(user)
	if(should_block_on_ctrl_click())
		block_automatic_closing(FIRELOCK_CTRL_CLICK_OVERRIDE_TIME)
		balloon_alert(user, "фаерлок заблокирован")
	else
		unblock_automatic_closing()
		balloon_alert(user, "блокировка снята")

/obj/machinery/door/firedoor/proc/try_manual_override(mob/user, override_time = FIRELOCK_MANUAL_OVERRIDE_TIME)
	if(density && !welded && !operating && !(src in user.do_afters))
		balloon_alert(user, "открывание...")
		if(do_after(user, override_time, target = src))
			try_to_crowbar(null, user)
			return TRUE
	return FALSE
