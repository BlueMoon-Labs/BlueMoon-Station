/// Drains the three lighting work queues (sources -> corners -> objects) synchronously, in order.
/// Each queue is claimed atomically (Copy + Cut with no yield between) and processed from the private
/// snapshot. This is interleave-safe: the drain sleeps in CHECK_TICK on an async stack, and a
/// concurrent SSlighting.fire() (or second drain) only ever sees entries it owns - unlike an
/// index/prefix-cut over the SHARED list, where a fire() Cut during the yield shifts elements under
/// the saved cursor and the closing Cut discards sources nobody processed (needs_update stays
/// non-NO_UPDATE, so the EFFECT_UPDATE re-append guard then refuses to re-enqueue them - permanently
/// stale lights). A source dirtied DURING the drain either sits later in the snapshot (we process it)
/// or re-enters the live queue for fire() (its needs_update was already reset). Each queue fully
/// drains before the next is claimed, so the cascade lights->corners->objects is covered.
/proc/drain_lighting_queues_snapshot()
	if(GLOB.lighting_update_lights.len)
		var/list/pending_sources = GLOB.lighting_update_lights.Copy()
		GLOB.lighting_update_lights.Cut()
		for(var/datum/light_source/queued_source as anything in pending_sources)
			if(!QDELETED(queued_source))
				queued_source.update_corners()
				queued_source.needs_update = LIGHTING_NO_UPDATE
			CHECK_TICK

	if(GLOB.lighting_update_corners.len)
		var/list/pending_corners = GLOB.lighting_update_corners.Copy()
		GLOB.lighting_update_corners.Cut()
		// Слот гасим сразу: угол, снёсший себя в начале прохода, иначе висел бы ссылкой в снимке
		// до конца драйна, а тот на инициализации мира длиннее окна сборщика.
		for(var/corner_index in 1 to pending_corners.len)
			var/datum/lighting_corner/queued_corner = pending_corners[corner_index]
			pending_corners[corner_index] = null
			if(QDELETED(queued_corner))
				continue
			queued_corner.update_objects()
			queued_corner.needs_update = FALSE
			CHECK_TICK

	if(GLOB.lighting_update_objects.len)
		var/list/pending_objects = GLOB.lighting_update_objects.Copy()
		GLOB.lighting_update_objects.Cut()
		for(var/atom/movable/lighting_object/queued_object as anything in pending_objects)
			if(!QDELETED(queued_object))
				queued_object.update(use_animate = FALSE)
				queued_object.needs_update = FALSE
			CHECK_TICK

/**
 * Поднимаем ли свет этого уровня сразу, или ждём первого посетителя.
 *
 * Единственный источник правды на две стороны отсрочки: пропуск уровня в
 * create_all_lighting_objects() и парковку источников в /atom/update_light(). Разъедься
 * они - и на пропущенном уровне живые источники сами достроят себе углы через
 * generate_missing_corners(), то есть отсрочка перестанет экономить хоть что-нибудь.
 *
 * ZTRAIT_AWAY тут по данным прода 25.08. Эвей-миссия и VR - это отдельные z, куда на
 * старте раунда не заходит НИКТО, а нередко не заходит и вовсе никогда, но свет им
 * строился наравне со станцией. Разброс их содержимого при этом восьмикратный:
 * Academy - 10 402 движимых, ihategordon - 88 942. Раунд 10114 вытянул ihategordon
 * вместе с тяжёлым VR, стартовал с базой на 1150 МБ выше обычного для той же карты и
 * упёрся в потолок адресного пространства на 61-й минуте.
 */
/proc/zlevel_lighting_deferred(datum/space_level/level)
	if(!level)
		return FALSE
	return level.traits[ZTRAIT_RESERVED] || level.traits[ZTRAIT_MINING] || level.traits[ZTRAIT_AWAY]

/**
 * Можно ли сносить свет этого уровня, когда он опустел.
 *
 * Уже, чем zlevel_lighting_deferred(): транзитно-резервный уровень отложить на старте
 * можно и нужно, а вот сносить бессмысленно. Его постоянно перерабатывают шаттлы и
 * резервации, docking.dm сам зовёт create_lighting_for_zlevel() на стыковке, а освобождение
 * резервации и так гасит свет поштучно через lighting_clear_overlay(). Снос уровня под
 * этим оборотом только гонялся бы наперегонки со стыковкой и не освобождал бы ничего.
 *
 * Остаются те, ради кого всё и затевалось: шахтёрские уровни (два Лаваланда, 167-253 МБ
 * и 66 300 объектов на каждый) и эвей-миссия с VR, куда за раунд может не зайти никто.
 */
/proc/zlevel_lighting_teardownable(datum/space_level/level)
	if(!level || level.traits[ZTRAIT_RESERVED])
		return FALSE
	return level.traits[ZTRAIT_MINING] || level.traits[ZTRAIT_AWAY]

/**
 * Сколько времени пустующий отложенный уровень держит свет, прежде чем его разберут.
 *
 * Чистая функция от двух входов - её и проверяет юнит-тест: вызвать снос на настоящем
 * мире в тесте нельзя, а ошибиться порогом здесь стоит либо раунда (не разобрали), либо
 * вспышки белого в глаза каждому вошедшему (разобрали слишком рано).
 *
 * Квота ЖЁСТЧЕ давления: она про пик одновременно зажжённых уровней, то есть про ту самую
 * цифру, которой раунд и платит (см. LIGHTING_MAX_LIT_DEFERRED_Z). Давление - вторая линия,
 * для раундов, которые доезжают до потолка на двух уровнях.
 *
 * Но сверх кванта срок больше не ноль. Ноль означал "забрать уровень первым же сканом после
 * ухода последнего госта", и на проде это вышло качанием: раунд 10126 сделал 42 подъёма и
 * 41 снос, ни один из которых памяти не сэкономил (см. LIGHTING_TEARDOWN_IDLE_TIME_QUOTA).
 * Ноль остаётся ровно там, где он и был оправдан, - у критического давления: раунд, доехавший
 * до 88% потолка, иначе умирает молча, и там вспышка дешевле смерти процесса.
 *
 * Аргументы:
 * * pressure - доля потолка адресного пространства, 0 = не замерено (Windows, ранний старт)
 * * lit_deferred_count - сколько отложенных уровней сейчас горит, включая занятые
 */
/proc/lighting_teardown_idle_time(pressure, lit_deferred_count)
	var/idle_time = LIGHTING_TEARDOWN_IDLE_TIME
	if(pressure >= LIGHTING_TEARDOWN_PRESSURE_CRITICAL)
		idle_time = LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL
	else if(pressure >= LIGHTING_TEARDOWN_PRESSURE_HIGH)
		idle_time = LIGHTING_TEARDOWN_IDLE_TIME_HIGH
	if(lit_deferred_count <= LIGHTING_MAX_LIT_DEFERRED_Z)
		return idle_time
	if(pressure >= LIGHTING_TEARDOWN_PRESSURE_CRITICAL)
		return 0
	return min(idle_time, LIGHTING_TEARDOWN_IDLE_TIME_QUOTA)

/**
 * Рано ли сносить уровень, поднятый совсем недавно.
 *
 * Третья чистая функция решения о сносе, и единственная, которая смотрит на подъём, а не на
 * опустение. Простой отсчитывается с момента, когда уровень увидели пустым, поэтому пролетевший
 * гост обнуляет его каждый раз заново - сколько бы ни стоял срок простоя, частота качания им
 * сверху не ограничена. Кулдаун от подъёма ограничивает.
 *
 * Аргументы:
 * * lit_since - world.time подъёма уровня; null - момент подъёма неизвестен (уровень поднят
 *   до появления отметки, например на инициализации мира), кулдаун не действует
 * * now - world.time замера
 * * pressure - доля потолка; с критического давления кулдаун снимается
 */
/proc/zlevel_teardown_cooldown_active(lit_since, now, pressure)
	if(isnull(lit_since))
		return FALSE
	if(pressure >= LIGHTING_TEARDOWN_PRESSURE_CRITICAL)
		return FALSE
	return (now - lit_since) < LIGHTING_TEARDOWN_MIN_LIT_TIME

/**
 * Кого из пустующих уровней разбирать первым при этом сроке простоя.
 *
 * Вторая чистая половина решения (первая - lighting_teardown_idle_time). Разделены они
 * не ради красоты: scan_teardown_candidates() умеет только собирать данные о живом мире,
 * и всё, что в ней можно сломать молча, лежит здесь.
 *
 * Аргументы:
 * * idle_since_by_z - "[z]" -> world.time, когда уровень увидели пустым
 * * idle_time - выбранный срок простоя в тиках; ноль означает "отдавать немедленно"
 * * now - world.time замера
 */
/proc/pick_lighting_teardown_zlevel(list/idle_since_by_z, idle_time, now)
	var/best_z = 0
	var/best_since = INFINITY
	for(var/key in idle_since_by_z)
		var/since = idle_since_by_z[key]
		if(now - since < idle_time)
			continue
		// Пустует дольше всех - его и разбираем первым.
		if(since < best_since)
			best_since = since
			best_z = text2num(key)
	return best_z

/**
 * Почему снос света начался именно сейчас - в человеческом виде, для строки лога.
 *
 * Отдельным проком, потому что разбор прод-логов читает эту строку как улику: до квоты у
 * неё был один-единственный текст про четверть часа, и по нему нельзя было отличить
 * "уровень честно простоял свой срок" от "его выбили сверх кванта". А это разные выводы
 * о раунде: во втором случае пик одновременно зажжённых уровней был выше кванта, и цифра
 * из перф-CSV (light_lit_deferred_z) должна это подтверждать.
 */
/proc/zlevel_teardown_reason_line(idle_time, lit_deferred, pressure)
	var/pressure_note = pressure > 0 ? " при [round(pressure * 100)]% потолка" : ""
	var/idle_note = "пусто дольше [round(idle_time / (1 MINUTES), 0.1)] мин"
	if(lit_deferred > LIGHTING_MAX_LIT_DEFERRED_Z)
		return "сверх кванта: горело [lit_deferred] отложенных уровней при квоте [LIGHTING_MAX_LIT_DEFERRED_Z], [idle_note][pressure_note]"
	return "[idle_note][pressure_note]"

/proc/create_all_lighting_objects()
	SSlighting.begin_lighting_build()

	// Build set of z-levels to skip (reserved/transit/mining/away — deferred until player visits)
	var/list/skip_z = list()
	if(SSmapping?.initialized)
		for(var/datum/space_level/level as anything in SSmapping.z_list)
			if(zlevel_lighting_deferred(level))
				skip_z["[level.z_value]"] = TRUE

	for(var/area/A in world)
		if(!IS_DYNAMIC_LIGHTING(A))
			continue

		for(var/turf/T in A)
			if(!TURF_IS_DYNAMIC_LIGHTING(T))
				continue
			// Skip reserved z-levels — will be initialized on demand
			if(skip_z["[T.z]"])
				continue

			new /atom/movable/lighting_object(T)
			CHECK_TICK
		CHECK_TICK

	// Process deferred starlight (deduplicated via assoc list keys)
	for(var/turf/open/space/S as anything in GLOB.lighting_deferred_starlight)
		S.update_starlight()
		CHECK_TICK
	GLOB.lighting_deferred_starlight.Cut()
	SSlighting.end_lighting_build()

	// Batch process all queued sources/corners/objects directly during init — instant lighting, no
	// adaptive cap or animate(). Prefix-cut inside the helper keeps any cascade tail dirtied during a
	// CHECK_TICK yield in the queue for SSlighting.fire() instead of blanket-discarding it.
	drain_lighting_queues_snapshot()

	// Mark initialized z-levels and queue deferred ones for background init
	if(SSmapping?.initialized)
		SSlighting.bg_queued_zlevels = list()
		for(var/datum/space_level/level as anything in SSmapping.z_list)
			if(!skip_z["[level.z_value]"])
				level.lighting_initialized = TRUE
			else
				SSlighting.bg_queued_zlevels += level.z_value

/// TRUE if any parked deferred light atom still belongs to z_level. An interrupted on-demand init
/// can leave the level flagged lighting_initialized with its sources never flushed; this lets
/// create_lighting_for_zlevel detect and recover that stuck state instead of staying black forever.
/proc/zlevel_has_deferred_lighting(z_level)
	for(var/atom/deferred_atom as anything in GLOB.lighting_deferred_atoms)
		if(QDELETED(deferred_atom))
			continue
		var/turf/atom_turf = get_turf(deferred_atom)
		if(atom_turf?.z == z_level)
			return TRUE
	return FALSE

/// Synchronous gate shared by /mob/living and /mob/dead update_z: should a client entering new_z
/// schedule on-demand lighting init? TRUE only when lighting/mapping are ready, no bulk op owns
/// lighting, and the level exists but is not yet initialized. Bounds-guards the z_list index instead
/// of SSmapping.get_level() (which CRASHes on an unmanaged z).
/proc/should_ondemand_init_zlevel(new_z)
	if(!new_z || !SSlighting?.initialized || !SSmapping?.initialized || GLOB.lighting_defer_active)
		return FALSE
	var/datum/space_level/level = SSmapping.z_list.len >= new_z ? SSmapping.z_list[new_z] : null
	return level && !level.lighting_initialized

/**
 * Creates lighting infrastructure for a single z-level on demand (synchronous fallback).
 * Called when a player enters a z-level before background init reaches it.
 *
 * Аргумент reason уходит В ЛОГ и больше никуда: в раунде 10126 подъёмов было 42, и по строке
 * "On-demand init for z-level 15 (background preempted)" нельзя было сказать, кто их
 * запускает - гост, живой игрок, стыковка шаттла или сейфнет-скан. Разбор упёрся ровно в это.
 */
/proc/create_lighting_for_zlevel(z_level, reason = LIGHTING_INIT_REASON_UNKNOWN)
	var/datum/space_level/level = SSmapping.get_level(z_level)
	// Self-heal: also re-run when a prior (possibly interrupted) init left deferred light atoms for
	// this z unflushed — otherwise the level stays flagged "initialized" yet permanently black.
	if(level.lighting_initialized && !zlevel_has_deferred_lighting(z_level))
		return
	// Проход по УЖЕ поднятому уровню объектов почти не создаёт: фаза 0 пропускает турфы, у
	// которых объект есть, и вся его работа - флаш запаркованных атомов. Строка обязана
	// называть себя иначе, иначе читатель лога считает такой проход постройкой целого z.
	// Раунд 10121: одиннадцать строк "On-demand init", включая z1 CentCom, который вообще
	// не отложен (ZTRAITS_CENTCOM не даёт ни MINING, ни AWAY, ни RESERVED) - при двух
	// РЕАЛЬНЫХ постройках по шагам instances в перф-CSV. Разбор раунда ушёл в эту ложную
	// улику дважды, в 10119 и в 10121.
	var/self_heal = level.lighting_initialized
	level.lighting_initialized = TRUE
	// Снос света этого уровня отменяем первым делом: он спит между срезами, и его
	// следующий срез иначе разобрал бы ровно то, что мы сейчас построим. Сам снос тоже
	// смотрит на lighting_initialized, но снять его состояние здесь дешевле и честнее.
	if(SSlighting.teardown_zlevel == z_level)
		SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.zlevel_empty_since -= "[z_level]"
	if(!self_heal)
		SSlighting.mark_zlevel_lit(z_level)
	// Cancel background init if it was working on this z-level
	if(SSlighting.bg_current_zlevel == z_level)
		SSlighting.bg_current_zlevel = 0
		SSlighting.bg_phase = 0
		SSlighting.bg_turfs = null
		SSlighting.bg_turf_index = 0
	else if(SSlighting.bg_queued_zlevels)
		SSlighting.bg_queued_zlevels -= z_level
	log_world(zlevel_lighting_pass_line(z_level, level.name, self_heal, reason))

	// Свет целого z-уровня - самая крупная разовая аллокация идущего раунда: в 10119 три
	// таких постройки стоили 466 МБ из 4094 потолка, и восстанавливать эту цифру пришлось
	// вручную по ступенькам перф-CSV. Меряем прямо здесь и записываем на СВОЙ счёт, чтобы
	// прибор подключения не выставлял её счётом игроку, спящему в acquire_dpi().
	// Окно честно только пока внутри него нет второй такой постройки. Пустой повторный
	// проход по этому же z отсечён ниже по objects_created, а вот параллельный подъём
	// ДРУГОГО z в окно попадёт и будет посчитан дважды - на проде такое видно по сумме
	// строк, заметно превышающей реальный шаг VmSize.
	var/list/memory_before = get_process_memory_mb()

	SSlighting.begin_lighting_build()

	// Phase 0: Create lighting objects FIRST — corners must be active before sources process
	// Objects make corners active; without them, update_corners() stores effect_str[C]=0 and skips APPLY_CORNER
	var/list/zlevel_turfs = block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level))
	var/objects_created = 0
	for(var/turf/T as anything in zlevel_turfs)
		var/area/A = T.loc
		if(!IS_DYNAMIC_LIGHTING(A))
			continue
		if(!TURF_IS_DYNAMIC_LIGHTING(T))
			continue
		if(T.lighting_object)
			continue
		new /atom/movable/lighting_object(T)
		objects_created++
		// Activate corners created during init with active=FALSE (no objects existed then)
		if(T.lighting_flags & TURF_LIGHTING_CORNERS_INITIALISED)
			if(T.lc_topright) T.lc_topright.active = TRUE
			if(T.lc_bottomright) T.lc_bottomright.active = TRUE
			if(T.lc_bottomleft) T.lc_bottomleft.active = TRUE
			if(T.lc_topleft) T.lc_topleft.active = TRUE
		CHECK_TICK

	SSlighting.end_lighting_build()

	// Phase 1: Create deferred light sources — objects exist now, corners are active
	// Sources get queued to GLOB.lighting_update_lights; fire() processes them with active corners.
	// Живой список мутируем ТОЛЬКО in place (удаление до ближайшего CHECK_TICK): переприсваивание
	// глобала устаревшим снапшотом теряло атомы, запаркованные во время сна параллельным прогоном
	// (второй игрок на другом отложенном z, фоновый краул) - такой атом навсегда выпадал из
	// отложки и был невидим для сейфнет-скана.
	for(var/atom/A as anything in GLOB.lighting_deferred_atoms.Copy())
		if(QDELETED(A))
			GLOB.lighting_deferred_atoms -= A
			continue
		var/turf/T = get_turf(A)
		if(T?.z == z_level)
			GLOB.lighting_deferred_atoms -= A
			A.update_light()
		CHECK_TICK
	GLOB.lighting_deferred_z_cache = null

	// Phase 2: Queue deferred starlight for fire() Phase -1 instead of processing synchronously.
	// Тот же инвариант: только in-place удаление, никаких переприсваиваний глобала.
	for(var/turf/open/space/S in GLOB.lighting_deferred_starlight.Copy())
		if(S.z == z_level)
			GLOB.lighting_starlight_queue |= S
			GLOB.lighting_deferred_starlight -= S
		CHECK_TICK

	// Drain the work this on-demand init just queued so the z a player is standing on lights up
	// immediately, instead of leaving the backlog under fire()'s dilation-adaptive source cap (which
	// collapses to ~20-40 sources/fire under atmospherics load: tens of seconds of black, far longer
	// on heavy away-maps). fire() Phase -1 still creates the queued starlight sources separately.
	drain_lighting_queues_snapshot()

	log_zlevel_lighting_cost(z_level, level.name, memory_before, objects_created)

/**
 * Есть ли смысл отчитываться о цене прохода постройки света.
 *
 * Пустой проход (ни одного созданного объекта) МОЛЧИТ. Повторный подъём уже поднятого
 * уровня - второй INVOKE_ASYNC на том же z, сейфнет-скан, стыковка шаттла - не создаёт
 * ничего: фаза 0 пропускает турфы, у которых объект уже есть. Но его окно замера
 * перекрывается с окном соседнего ЖИВОГО прохода, и одна и та же работа записалась бы
 * дважды: в раунде 10121 на z7 так вышли +83.9 и +109 МБ за один подъём, и обе цифры уехали
 * в счётчик, из которого прибор подключения вычитает фон у входящих игроков.
 */
/proc/should_report_zlevel_lighting_cost(objects_created, list/memory_before)
	return objects_created > 0 && !isnull(memory_before)

/**
 * Строка о начале прохода постройки света.
 *
 * Отдельным проком, потому что различие между настоящей постройкой отложенного уровня и
 * флашем запаркованных атомов на уже поднятом - это ровно то, на чём разбор прод-логов
 * ошибался: обе строки читались как "поднят целый z-уровень". Настоящих построек за
 * раунд 10121 было две, строк - одиннадцать.
 */
/proc/zlevel_lighting_pass_line(z_level, level_name, self_heal, reason = LIGHTING_INIT_REASON_UNKNOWN)
	if(self_heal)
		return "## LIGHTING: Self-heal pass for z-level [z_level] ([level_name]) - флаш отложенных атомов, уровень уже поднят (повод: [reason])"
	return "## LIGHTING: On-demand init for z-level [z_level] ([level_name]) (background preempted, повод: [reason])"

/// Записывает цену постройки света z-уровня в лог и на счёт фоновой работы. Отдельным
/// проком, потому что вызывать его придётся и из фонового краула, и из сноса.
/proc/log_zlevel_lighting_cost(z_level, level_name, list/memory_before, objects_created)
	if(!should_report_zlevel_lighting_cost(objects_created, memory_before))
		return
	var/list/memory_after = get_process_memory_mb()
	if(!memory_after)
		return
	var/spent = memory_after["vsz"] - memory_before["vsz"]
	attribute_memory_elsewhere_mb(spent)
	log_world("## MEMORY: свет z-уровня [z_level] ([level_name]) стоил [format_mb_delta(spent)] VmSize на [objects_created] объектов")
