// Атмосфера на DM (газ в gas_mixture.gases, реакции в react(), без Auxmos).

/// Sentinel temperature gate meaning "no temperature-gated reactions exist".
/// A plain huge constant because this file compiles before the INFINITY define.
#define ATMOS_NO_TEMPERATURE_GATE 1e30

// Подсистема и глобальные заглушки
/datum/controller/subsystem/air
	// Здесь лежал dm_registered_turfs - список "открытых турфов, участвующих в
	// симуляции". Наследие DLL auxmos, которая не грузится: по всему дереву он
	// имел пять упоминаний, и все пять были ЗАПИСЯМИ. Ни одного чтения, ни одной
	// итерации, ни одного замера. Стоил он при этом дорого: `|=` в
	// update_air_ref() - линейный скан, а update_air_ref() выполняется для
	// каждого открытого турфа на инициализации карты, то есть список давал
	// квадратичность на ровном месте. Плюс ещё один скан на каждом снятии турфа.
	/// Turfs currently participating in active atmos processing.
	var/list/turf/open/active_turfs = list()
	/// Groups of turfs with active gas exchange.
	var/list/datum/excited_group/excited_groups = list()
	/// Обход зоны эквалайзером, растянутый на несколько фаеров. Слот ровно один:
	/// пока обход в полёте, фаза не заводит второй, иначе два обхода двигали бы
	/// один и тот же газ. Держать состояние в currentrun нельзя - тот слот общий
	/// на все фазы подсистемы, и следующая фаза приняла бы турфы за свои
	/// сущности. См. /datum/atmos_zone_walk.
	var/datum/atmos_zone_walk/zone_walk
	/// Number of currently alive gas mixtures (for stat panel parity).
	var/dm_registered_gas_mixtures = 0
	/// Maximum number of simultaneously alive gas mixtures.
	var/dm_max_registered_gas_mixtures = 0
	/// Reaction pre-filter: gas id -> list of reactions keyed by that gas. A reaction
	/// can only run if its key gas is present, so mixtures without exotic gases skip
	/// the full 28-reaction requirement scan entirely. Built by auxtools_update_reactions().
	var/list/reactions_by_key_gas
	/// Пол требований по бакету: gas id -> минимальное по бакету min_requirements
	/// для этого же газа. Присутствия ключа мало - реакция не пойдёт, пока молей
	/// меньше её собственного порога, и цикл реакций это всё равно проверяет
	/// (см. react(), сравнение с min_reqs). Пол выносит ту же проверку в сбор
	/// кандидатов, до копии списка, total_moles() и сортировки. Реакция лежит
	/// ровно в одном бакете, пол - минимум по бакету, поэтому газ ниже пола не
	/// удовлетворяет ни одну его реакцию: отсечение точное, а не приближённое.
	/// Построен auxtools_update_reactions() вместе с индексом.
	var/list/reactions_key_gas_floor
	/// TRUE, если хоть у одной реакции проставлен synthesis_followup_gas. Гейт
	/// для дополнительного прохода по кандидатам в react(): реакций-производителей
	/// с потребителем ПОЗЖЕ себя в игре единицы, а проход стоял бы на каждом
	/// активном турфе, пайпнете и баллоне каждый фаер.
	var/reactions_have_synthesis_followups = FALSE
	/// Reactions with no gas requirement at all (assoc: reaction -> its TEMP gate).
	var/list/temp_gated_reactions
	/// Subset of the above that also requires FIRE_REAGENTS (assoc: reaction -> TRUE).
	/// Those cannot fire without a gas at its ignition temperature, which react()
	/// checks far more cheaply than assembling them as candidates.
	var/list/temp_gated_needs_fuel
	/// Lowest TEMP gate among temp_gated_reactions, for a single cheap precheck.
	var/temp_gated_min_temp = ATMOS_NO_TEMPERATURE_GATE

/datum/controller/subsystem/air/proc/get_max_gas_mixes()
	return dm_max_registered_gas_mixtures

/datum/controller/subsystem/air/proc/get_amt_gas_mixes()
	return dm_registered_gas_mixtures

/proc/equalize_all_gases_in_list(gas_list)
	if(!length(gas_list))
		return
	// Runs for every dirty pipenet every fire: accumulate totals into reused
	// static lists instead of allocating (and qdel-ing) a scratch gas_mixture.
	var/static/list/total_gases = list()
	var/static/list/datum/gas_mixture/participating = list()
	total_gases.Cut()
	participating.Cut()
	var/total_volume = 0
	var/total_heat_capacity = 0
	var/total_thermal_energy = 0
	var/list/specific_heats = GLOB.gas_data.specific_heats
	for(var/datum/gas_mixture/mix in gas_list)
		if(!mix || mix.gc_share)
			continue
		participating += mix
		total_volume += max(mix.volume, 0)
		var/mix_heat_capacity = 0
		var/list/mix_gases = mix.gases
		for(var/id, moles in mix_gases)
			total_gases[id] = (total_gases[id] || 0) + moles
			mix_heat_capacity += moles * (specific_heats[id] || 0)
		mix_heat_capacity = max(mix_heat_capacity, mix.min_heat_capacity)
		total_heat_capacity += mix_heat_capacity
		total_thermal_energy += mix.temperature * mix_heat_capacity
	if(!length(participating) || total_volume <= 0)
		participating.Cut()
		return
	// Sequential capacity-weighted merges collapse to total energy over total
	// capacity; TCMB matches the scratch mixture's default when nothing had heat.
	var/target_temperature = TCMB
	if(total_heat_capacity > 0)
		target_temperature = max(total_thermal_energy / total_heat_capacity, TCMB)
	var/inv_total_volume = 1 / total_volume
	for(var/datum/gas_mixture/mix as anything in participating)
		var/volume_ratio = max(mix.volume, 0) * inv_total_volume
		var/list/mix_gases = mix.gases
		mix_gases.Cut()
		for(var/id, total_moles in total_gases)
			var/moles = total_moles * volume_ratio
			if(moles > 0)
				mix_gases[id] = moles
		mix.temperature = target_temperature
		mix.mutation_rev++
	// Do not keep strong references to pipenet mixtures between calls.
	participating.Cut()
	total_gases.Cut()

///TRUE when any excited group has outgrown the zone-equalize valve threshold.
/datum/controller/subsystem/air/proc/has_zone_equalize_candidate()
	for(var/datum/excited_group/group as anything in excited_groups)
		if(group && length(group.turf_list) >= EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD)
			return TRUE
	return FALSE

/// Крутит обход зоны срезами, пока он не кончится или пока в тике не осталось
/// запаса на ещё один срез. `force_one_slice` гарантирует прогресс: МК выдаёт
/// фоновой подсистеме долю остатка тика, и она вполне может быть меньше порога
/// уже на входе в фазу - без этого обход встал бы навсегда.
/// Возвращает TRUE, когда обход завершён.
/datum/controller/subsystem/air/proc/advance_zone_walk(force_one_slice)
	if(!zone_walk)
		return TRUE
	while(zone_walk.stage)
		if(!force_one_slice && TICK_REMAINING_MS < ATMOS_EQUALIZE_ZONE_MIN_BUDGET_MS)
			return FALSE
		force_one_slice = FALSE
		zone_walk.advance(ATMOS_EQUALIZE_ZONE_SLICE)
	return TRUE

/datum/controller/subsystem/air/proc/process_turf_equalize_auxtools(remaining)
	// Обход, начатый на прошлом фаере, доигрывается ПЕРВЫМ и до конца. Пока он в
	// полёте, его члены помечены штампом фаера захвата, и обход из соседнего
	// турфа наложился бы на ту же зону - два обхода мутировали бы один газ.
	var/stepped_this_fire = FALSE
	if(zone_walk?.stage)
		if(!advance_zone_walk(TRUE))
			pause()
			return TRUE
		stepped_this_fire = TRUE
	if(!length(currentrun))
		// Valve recomputes on every fresh pass, not on resumes: a giant group
		// appearing mid-pass waits one fire, one disappearing costs one extra
		// filtered sweep. With the config flag on the valve is irrelevant.
		equalize_valve_mode = FALSE
		if(!equalize_enabled)
			if(!has_zone_equalize_candidate())
				num_equalize_processed = 0
				return FALSE
			equalize_valve_mode = TRUE
		currentrun = active_turfs.Copy()
		num_equalize_processed = 0
		high_pressure_turfs = 0
		low_pressure_turfs = 0
	var/list/currentrun_copy = currentrun
	var/fire_count = times_fired
	while(currentrun_copy.len)
		var/turf/open/T = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!istype(T) || T.blocks_air || !T.air)
			// `excited` is the membership flag add_to_active() trusts, so a turf
			// evicted here must stop claiming it is listed - otherwise a tile
			// that later reopens (ChangeTurf back to plating) could never be
			// activated again.
			if(istype(T))
				T.excited = FALSE
			evict_active_turf(T)
			continue
		// Небо затравкой не бывает (зеркало гарда в zone_walk.begin()): планетарный
		// турф прибит к шаблону, его "дельта" вечна - обход через него кормил бы
		// сам себя. Гард стоит до скана соседей: после массового пробуждения
		// планетарки кандидатов из неё - десятки тысяч за фаер.
		if(T.planetary_atmos)
			continue
		// Valve mode: only members of an oversized group qualify. Ordinary
		// rooms keep pure LINDA behavior with the config flag off.
		if(equalize_valve_mode)
			var/datum/excited_group/turf_group = T.excited_group
			if(!turf_group || length(turf_group.turf_list) < EXCITED_GROUP_ZONE_EQUALIZE_THRESHOLD)
				continue
		// Турф, уже захваченный чьим-то обходом в этом фаере, затравкой не станет
		// - тот же гард стоит внутри begin(). Значит и решать, стоит ли он зоны,
		// незачем: скан соседей ниже это пять return_pressure(), то есть десять
		// вызовов прока на турф, а после первого же обхода на две тысячи членов
		// такие турфы в очереди - подавляющее большинство.
		if(T.equalize_cycle >= fire_count)
			continue
		var/pressure = T.air.return_pressure()
		var/max_adjacent_delta = 0
		var/has_space_neighbor = FALSE
		for(var/turf/adjacent as anything in T.atmos_adjacent_turfs)
			if(istype(adjacent, /turf/open/space))
				has_space_neighbor = TRUE
				continue
			var/turf/open/open_adjacent = adjacent
			if(!istype(open_adjacent) || open_adjacent.blocks_air || !open_adjacent.air)
				continue
			max_adjacent_delta = max(max_adjacent_delta, abs(pressure - open_adjacent.air.return_pressure()))
		if(has_space_neighbor || max_adjacent_delta >= EQUALIZE_MIN_PRESSURE_DELTA)
			// Обход зоны теперь режется на срезы, но стадия сведения газа внутри
			// него всё равно атомарна, поэтому НАЧИНАТЬ обход на догорающем тике
			// по-прежнему нельзя: проверка бюджета ПОСЛЕ вызова узнаёт про
			// перерасход, когда он уже случился.
			if(stepped_this_fire && TICK_REMAINING_MS < ATMOS_EQUALIZE_ZONE_MIN_BUDGET_MS)
				// Турф уже снят с хвоста - вернуть его туда же, иначе его зона
				// не будет обработана в этом проходе вообще.
				currentrun_copy += T
				pause()
				return TRUE
			if(!zone_walk)
				zone_walk = new
			// Счётчики фазы ведёт сам обход: гейт по разбросу давления, который
			// решает "зона того стоила", живёт внутри него и может сработать уже
			// на следующем фаере.
			if(zone_walk.begin(T, fire_count))
				stepped_this_fire = TRUE
				if(!advance_zone_walk(TRUE))
					pause()
					return TRUE
		// See process_turfs_auxtools(): pausing on an emptied runlist restarts
		// the pass from a fresh Copy() on the next fire.
		if(currentrun_copy.len && world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	// Do not leak equalize runlist into the next SSAIR stage.
	// The subsystem uses a shared `currentrun` slot, and leaving turf entries here
	// makes the excited-group stage treat turfs as groups.
	currentrun = list()
	return FALSE

/datum/controller/subsystem/air/proc/process_excited_groups_auxtools(remaining)
	if(!length(currentrun))
		currentrun = excited_groups.Copy()
		num_group_turfs_processed = 0
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/datum/excited_group/EG = currentrun_copy[currentrun_copy.len]
		if(!EG)
			currentrun_copy.len--
			continue
		if(!EG.breakdown_stage)
			num_group_turfs_processed += length(EG.turf_list)
		var/group_finished = EG.tick_lifecycle()
		if(group_finished)
			currentrun_copy.len--
		// See process_turfs_auxtools(): pausing on an emptied runlist restarts
		// the pass from a fresh Copy() on the next fire, giving every group a
		// second lifecycle tick inside one logical pass.
		if(currentrun_copy.len && world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/// Queues one base area for the decompression phase. Associative membership
/// makes any number of leaking turfs in the same compartment one event.
/datum/controller/subsystem/air/proc/queue_decompression_area(atom/source)
	var/area/base = get_base_area(source)
	// Space can span an entire z-level; treating a mis-mapped pressurized turf
	// there as one compartment would close every registered firedoor on the
	// level instead of localizing the breach.
	if(!base || istype(base, /area/space))
		return
	queue_decompression_base(base)

/// Леджерная часть постановки зоны в декомп-очередь, отдельно от гарда космоса
/// выше: тестам нужна ровно она - зона юнит-тестовой резервации это /area/space.
/datum/controller/subsystem/air/proc/queue_decompression_base(area/base)
	// A breach keeps its edge turfs above the queue threshold for many fires;
	// the first handling already alarmed and pressure-stopped the compartment,
	// so re-sweeping it every SSair fire is pure waste.
	var/last_handled = decompression_handled_at[base]
	if(last_handled && world.time < last_handled + DECOMPRESSION_AREA_ALARM_COOLDOWN)
		return
	if(decompression_areas[base])
		return
	// Одиночный пшик - цикл наружного шлюза, мгновенно осушенный карман - не
	// пробоина: настоящая утечка перевзводит зону каждый фаер, пока кромку
	// кормят соседи. Тревога (полновесная пожарная тревога базового ареала,
	// которую никто не сбрасывает автоматически) ставится только по перевзводу
	// более поздним фаером внутри подтверждающего окна; протухший первый замер
	// считается новым первым разом.
	var/first_seen = decompression_pending[base]
	if(isnull(first_seen) || times_fired - first_seen > DECOMPRESSION_PENDING_WINDOW_FIRES)
		decompression_pending[base] = times_fired
		return
	if(first_seen == times_fired)
		return
	decompression_pending -= base
	decompression_areas[base] = TRUE

/// Raises the existing decompression alarm path once, then applies the same
/// pressure-stop close used by equalize to every firedoor bordering the area.
/datum/controller/subsystem/air/proc/handle_decompression_area(area/base)
	if(!base)
		return
	decompression_handled_at[base] = world.time
	var/alarm_handled = FALSE
	for(var/area/linked_area as anything in get_sub_areas(base))
		for(var/obj/machinery/airalarm/alarm as anything in linked_area.airalarms)
			if(!alarm.is_operational)
				continue
			alarm.handle_decomp_alarm()
			alarm_handled = TRUE
			break
		if(alarm_handled)
			break
	var/list/seen_firedoors
	for(var/area/linked_area as anything in get_sub_areas(base))
		for(var/obj/machinery/door/firedoor/firedoor as anything in linked_area.firedoors)
			if(!firedoor || seen_firedoors?[firedoor])
				continue
			if(!seen_firedoors)
				seen_firedoors = list()
			seen_firedoors[firedoor] = TRUE
			firedoor.emergency_pressure_stop()

/datum/controller/subsystem/air/proc/process_decompression_areas_auxtools(resumed)
	if(!resumed)
		// Отжившие записи кулдауна снимаются здесь же, раз фаза всё равно
		// трогает журнал: истёкший гейт уже ничего не блокирует, а без чистки
		// список растёт весь раунд и держит сильные ссылки на снесённые зоны
		// (шаттлы, руины, комнаты Гильберта) - им не собраться сборщиком.
		var/list/handled = decompression_handled_at
		for(var/i = length(handled); i > 0; i--)
			var/area/base = handled[i]
			if(world.time >= handled[base] + DECOMPRESSION_AREA_ALARM_COOLDOWN)
				handled.Cut(i, i + 1)
		// Та же уборка для неподтверждённых замеров: за пределами окна запись уже
		// ничего не подтвердит, а ссылку на снесённую зону держит.
		var/list/pending = decompression_pending
		for(var/i = length(pending); i > 0; i--)
			var/area/base = pending[i]
			if(times_fired - pending[base] > DECOMPRESSION_PENDING_WINDOW_FIRES)
				pending.Cut(i, i + 1)
		currentrun = decompression_areas.Copy()
		decompression_areas.Cut()
		num_decompression_areas = 0
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/area/base = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!base)
			continue
		handle_decompression_area(base)
		num_decompression_areas++
		if(world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/datum/controller/subsystem/air/proc/process_turfs_auxtools(remaining)
	if(!length(currentrun))
		currentrun = active_turfs.Copy()
		sharing_turfs = 0
	var/fire_count = times_fired
	var/list/currentrun_copy = currentrun
	while(currentrun_copy.len)
		var/turf/open/T = currentrun_copy[currentrun_copy.len]
		currentrun_copy.len--
		if(!istype(T) || T.blocks_air || !T.air)
			// See the equalize pass: the flag has to follow the list eviction.
			if(istype(T))
				T.excited = FALSE
			evict_active_turf(T)
			continue
		// last_share пишет только сама смесь и только в share() - никто его не
		// обнуляет. Без сброса турф, отшеривший десять фаеров назад и с тех пор
		// стоящий, продолжал считаться шерящим до конца раунда, и колонка
		// air_sharing_turfs завышала работу тем сильнее, чем дольше шёл раунд.
		// Сброс на входе делает её ровно тем, чем она заявлена: сколько активных
		// турфов реально двинули газ в СВОЁМ process_cell этого прохода (в раунде
		// 9868 таких было 307 из 2980). Симуляции сброс не виден: все читатели
		// last_share стоят сразу после своего share(), который его и записал.
		T.air.last_share = 0
		T.process_cell(fire_count)
		if(T.air.last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
			sharing_turfs++
		maybe_sleep_low_pressure_turf(T)
		// Only pause while there is still work left. Pausing on an emptied
		// runlist made the next fire see `!length(currentrun)` and re-Copy the
		// whole active list, running a second full turf pass inside what the
		// phase counters still called one pass.
		if(currentrun_copy.len && world.tick_usage > Master.current_ticklimit)
			pause()
			return TRUE
	return FALSE

/// The former finalize phase copied and scanned active_turfs a second time just
/// for this check. Running it beside process_cell keeps the same decision at the
/// point where the tile's gas has just settled, without another O(active) pass.
/datum/controller/subsystem/air/proc/maybe_sleep_low_pressure_turf(turf/open/T)
	if(!istype(T) || T.blocks_air || !T.air || T.excited_group || T.active_hotspot || T.planetary_atmos)
		return
	var/datum/gas_mixture/turf_air = T.air
	var/current_moles = turf_air.total_moles()
	if(current_moles > MINIMUM_MOLES_DELTA_TO_MOVE)
		return
	var/volume_cache = turf_air.volume
	var/current_pressure = volume_cache > 0 ? (current_moles * R_IDEAL_GAS_EQUATION * turf_air.temperature / volume_cache) : 0
	if(current_pressure <= (ONE_ATMOSPHERE * 0.05))
		sleep_active_turf(T)

/datum/controller/subsystem/air/proc/finish_turf_processing_auxtools(time_remaining)
	// Low-pressure sleeping is folded into process_turfs_auxtools(). Keep this
	// phase as the full-turf-cycle boundary used by the headless benchmark.
	return FALSE

/// Ставит турф в active_turfs и запоминает его позицию.
///
/// Защита от дубля здесь обязательна: голое `+=` посадило бы в список вторую
/// запись, стоит флагу `excited` хоть раз разойтись со списком, а снятие за O(1)
/// убрало бы только одну из двух. Но искать ради этого по всему списку не нужно
/// - подсказка позиции самопроверяема. `active_turf_index` пишут ровно три
/// прока (этот, drop_active_turf_at и снятия, которые его обнуляют), и
/// drop_active_turf_at всегда чинит индекс переехавшего элемента. Значит
/// "индекс указывает на нас" равносильно "мы уже в списке", а "не указывает" -
/// "нас в списке нет".
///
/// Цена вопроса как раз в эквалайзере: он будит спящих членов зоны сотнями за
/// обход, то есть шёл по НЕнайденной ветке, а список активных турфов под
/// разгерметизацией уходит в пять знаков. Скан по восьми тысячам записей на
/// каждое пробуждение - это и была основная стоимость стадии активации.
/datum/controller/subsystem/air/proc/list_active_turf(turf/T)
	var/hint = T.active_turf_index
	if(hint && hint <= length(active_turfs) && active_turfs[hint] == T)
		return
	active_turfs += T
	T.active_turf_index = length(active_turfs)

/// Снимает турф из active_turfs за O(1): на его место переезжает последний
/// элемент. Порядок списка не сохраняется, и это нормально - все фазы копируют
/// его целиком, порядок обхода ни на что не влияет.
///
/// `active_turfs -= T` это линейный скан по всему списку, а под станционным
/// пожаром список уходит в пятизначные размеры. Сольные засыпания внутри
/// гигантской excited-группы срабатывают сотнями за проход, и каждое платило
/// полный обход.
///
/// Индекс - только подсказка. Истину о членстве держит `excited`, поэтому если
/// подсказка разошлась с реальностью, снятие честно откатывается на линейный
/// поиск, а не оставляет в списке мусор.
/datum/controller/subsystem/air/proc/unlist_active_turf(turf/T)
	if(!isturf(T))
		return
	var/index = T.active_turf_index
	T.active_turf_index = 0
	if(index && index <= length(active_turfs) && active_turfs[index] == T)
		drop_active_turf_at(index)
		return
	// Подсказка не сработала. Открытый турф, который сам себя активным не
	// считает, в списке и не лежит - ровно на этом холостом вызове и
	// экономится скан. Всё прочее (турф сменил тип, потерял `excited` раньше
	// снятия) снимаем честно, иначе в списке останется мусор.
	var/turf/open/open_turf = T
	if(istype(open_turf) && !open_turf.excited)
		return
	drop_active_turf(T)

/// Аварийное снятие: турф уже не пригоден для симуляции (сменил тип, потерял
/// смесь), доверять его индексу нельзя, а типом он может быть и не открытым.
/datum/controller/subsystem/air/proc/evict_active_turf(turf/T)
	if(!isturf(T))
		drop_active_turf(T)
		return
	var/index = T.active_turf_index
	T.active_turf_index = 0
	if(index && index <= length(active_turfs) && active_turfs[index] == T)
		drop_active_turf_at(index)
		return
	drop_active_turf(T)

/// Снятие записи с известной позиции: на её место переезжает последний элемент,
/// и он узнаёт свою новую позицию. Дубликатов в списке нет по инварианту
/// (`excited` - флаг членства), поэтому одной записи достаточно.
/datum/controller/subsystem/air/proc/drop_active_turf_at(index)
	var/last_index = length(active_turfs)
	if(index != last_index)
		var/turf/moved_turf = active_turfs[last_index]
		active_turfs[index] = moved_turf
		moved_turf.active_turf_index = index
	active_turfs.len--

/// Снятие турфа, чью позицию пришлось искать. Позицию ищем и снимаем обменом, а
/// НЕ вычитанием списка.
///
/// `active_turfs -= T` сдвигает весь хвост на одну позицию влево, то есть разом
/// делает подсказки протухшими у КАЖДОГО турфа после снятого. Дальше каждое их
/// снятие проваливается в линейный откат и сдвигает хвост снова: снятие за O(1)
/// вырождается в O(n) с каскадом, который сам себя поддерживает. На проде это
/// стоило роста тяжёлых прогонов SSair (дольше 100 мс) с нуля за час на старой
/// сборке до пятисот за час на новой, на одной и той же карте.
/datum/controller/subsystem/air/proc/drop_active_turf(turf/T)
	var/index = active_turfs.Find(T)
	if(!index)
		return
	drop_active_turf_at(index)

/datum/controller/subsystem/air/proc/remove_from_active(turf/open/T)
	unlist_active_turf(T)
	if(istype(T))
		T.excited = FALSE
		if(T.excited_group)
			T.excited_group.garbage_collect()

/datum/controller/subsystem/air/proc/add_to_active(turf/open/T, blockchanges = TRUE, wake_machines = TRUE, reset_stall = TRUE)
	if(!istype(T) || T.blocks_air || !T.air)
		return
	// `excited` doubles as the membership flag of active_turfs: every path that
	// drops a turf out of the list clears it, and nothing marks a turf excited
	// without listing it (see /datum/excited_group/add_turf). The list add is
	// therefore only reachable for a turf that is genuinely asleep.
	//
	// This matters because `|=` is a linear scan of the WHOLE active list, and
	// the overwhelmingly common call is a poke at a tile that is already awake:
	// every assume_air/remove_air from a vent or a burning tile, every
	// superconduction neighbour, every equalize zone member. Under a station
	// fire the active list runs into five figures, so those pokes were paying a
	// full-list scan each - tens of milliseconds per fire spent proving the turf
	// was already there.
	if(!T.excited)
		// Group awake bookkeeping: only a resting member waking up takes a slot.
		if(T.excited_group)
			T.excited_group.awake_members++
		T.excited = TRUE
		list_active_turf(T)
	// Upstream parity: an activation that BROUGHT GAS grants a fresh stall
	// budget. Without this a turf that rested with a maxed counter (dismantle,
	// individual sleep) processes exactly one cell per activation and
	// immediately rests again, so a corpse drip-feeding miasma never pushed its
	// gas anywhere.
	//
	// reset_stall=FALSE is for activations that did NOT touch the tile's air:
	// an adjacency recalculation, a neighbor turf being deleted, a zone member
	// the equalizer left at the mix it already held. Those must NOT hand out a
	// budget, because atmos_cooldown is the only escape a settled member of a
	// pinned excited group has (the group's own reset_cooldowns is fired by any
	// churning member, so breakdown/dismantle never come). Round 9868: the zone
	// equalizer poked 2000 members per fire, so ~2500 station turfs at a
	// literal 72.0-72.0 kPa / 288-288 K spread never rested and 90% of the turf
	// phase went to tiles that could not move a single mole. The poke still
	// grants the turf one full process_cell - if it finds something to share,
	// LAST_SHARE_CHECK zeroes the counter and it stays awake on its own merit.
	if(reset_stall)
		T.atmos_cooldown = 0
	// wake_machines=FALSE is for activations that do not change the tile's air
	// (boundary pokes): the turf must re-compare against its neighbors, but its
	// registered vents/scrubbers have nothing new to react to. If the
	// comparison does move gas, the changed air wakes them through the regular
	// paths (neighbor activation, breakdown write-back, pipenet delta).
	if(wake_machines && T.atmos_wake_machines)
		for(var/obj/machinery/atmospherics/machine as anything in T.atmos_wake_machines)
			machine.atmos_wake()
	if(blockchanges && T.excited_group)
		// External gas changes must postpone group death but NOT group
		// averaging: self_breakdown spreading the gas across the whole group
		// is the only path gas has out of a drip-fed pocket whose per-cycle
		// shares stay under MINIMUM_MOLES_DELTA_TO_MOVE. Resetting
		// breakdown_cooldown here starved the group of averaging for as
		// long as the feed lasted. Destroying the group (the oldest behavior)
		// is still wrong - see the structural path in
		// /turf/air_update_turf(update = TRUE).
		if(T.excited_group.breakdown_stage)
			// A write between slices must not be overwritten by an average whose
			// accumulator predates that write. Keep the breakdown due so it
			// restarts from a fresh membership/air snapshot on resume.
			T.excited_group.cancel_breakdown()
		T.excited_group.dismantle_cooldown = 0

/// Rests a turf without touching its excited group: the turf stops paying
/// process_cell, but stays in the group's turf_list so breakdown/dismantle
/// bookkeeping continues. This is the individual escape hatch for settled
/// members of groups that are pinned awake by a few churning turfs
/// (planetary surfaces around a leak, space-edge drains).
/datum/controller/subsystem/air/proc/sleep_active_turf(turf/open/T)
	unlist_active_turf(T)
	if(istype(T))
		if(T.excited && T.excited_group)
			T.excited_group.awake_members = max(0, T.excited_group.awake_members - 1)
		T.excited = FALSE

/datum/controller/subsystem/air/proc/thread_running()
	return FALSE

/// Returns the shared immutable gas mixture a planetary turf regenerates toward.
/// Built once per unique gas string; replaces the old per-turf-per-cycle
/// `new + parse_gas_string + qdel` in process_cell. Keyed by the raw
/// initial_gas_mix string, matching what ashwalker lungs look up
/// (SSair.planetary[LAVALAND_DEFAULT_ATMOS]).
/datum/controller/subsystem/air/proc/get_planetary_template(turf/open/T)
	var/cache_key = T.initial_gas_mix
	var/datum/gas_mixture/template = planetary[cache_key]
	if(template)
		return template
	template = new(CELL_VOLUME)
	template.set_temperature(initial(T.initial_temperature))
	template.parse_gas_string(cache_key)
	template.mark_immutable()
	planetary[cache_key] = template
	return template

/proc/finalize_gas_refs()
	return

/datum/controller/subsystem/air/proc/auxtools_update_reactions()
	var/list/by_gas = list()
	var/list/floors = list()
	var/list/temp_gated = list()
	var/list/needs_fuel = list()
	var/gate_floor = ATMOS_NO_TEMPERATURE_GATE
	// Позиция ПОСЛЕДНЕЙ реакции бакета. Пол бакета читается на сборе кандидатов,
	// до цикла реакций, поэтому он верен только пока никакая реакция того же
	// вызова не может поднять газ над порогом. Пара freonformation (приоритет 33,
	// synthesis_gas = фреон) и freonfire (приоритет -12, бакет фреона) ровно
	// такая: производитель идёт РАНЬШЕ потребителя, и пол отложил бы горение на
	// один фаер SSair.
	var/list/bucket_last_index = list()
	var/index = 0
	for(var/datum/gas_reaction/reaction as anything in gas_reactions)
		index++
		reaction.sort_index = index
		reaction.synthesis_followup_gas = null
		var/list/reqs = reaction.min_requirements
		var/key_gas
		for(var/id in reqs)
			if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP" || id == "FIRE_REAGENTS" || id == REACTION_REQ_MIN_PRESSURE)
				continue
			if(isnull(key_gas))
				key_gas = id
			else if(key_gas == GAS_O2 || key_gas == GAS_N2 || key_gas == GAS_CO2 || key_gas == GAS_H2O)
				// Prefer a rarer key so common-air mixtures never pull this reaction
				// in as a candidate; any other requirement gas beats the air staples.
				key_gas = id
		if(key_gas)
			var/list/bucket = by_gas[key_gas]
			if(!bucket)
				bucket = list()
				by_gas[key_gas] = bucket
			bucket += reaction
			// Требование может быть нулевым или отсутствовать - тогда пол падает в
			// ноль и бакет не отсекается никогда, то есть поведение прежнее.
			var/reaction_floor = reqs[key_gas]
			if(isnull(reaction_floor))
				reaction_floor = 0
			var/bucket_floor = floors[key_gas]
			floors[key_gas] = isnull(bucket_floor) ? reaction_floor : min(bucket_floor, reaction_floor)
			bucket_last_index[key_gas] = index
		else
			var/temp_gate = reqs["TEMP"] || 0
			temp_gated[reaction] = temp_gate
			gate_floor = min(gate_floor, temp_gate)
			// Реакции, которым нужно горючее, отмечаются отдельно: react() умеет
			// отсеять их дешёвым присутствием топлива, не собирая кандидатов.
			// Остальные безгазовые реакции (если появятся) гейтом не задеваются.
			// Строго > 0, а не !isnull(). Цикл реакций сравнивает get_fuel_amount()
			// с порогом, и порог 0 проходит ВСЕГДА - такую реакцию гейт обязан
			// пропускать, а не отсекать по отсутствию горячего газа.
			if(reqs["FIRE_REAGENTS"] > 0)
				needs_fuel[reaction] = TRUE
	// Газ, который кто-то производит РАНЬШЕ, чем отработает последняя реакция его
	// бакета, требует двух поблажек сразу, и снятого пола мало.
	//
	// 1. Пол бакета снимается: моли на сборе кандидатов ещё нулевые, а к моменту
	//    потребителя их уже хватает. Бакет без пола ведёт себя как до гейта -
	//    полную проверку min_requirements всё равно делает цикл реакций.
	// 2. Производитель помечается followup-газом. Пол спасает только тот случай,
	//    когда газ в смеси УЖЕ есть, пусть и ниже порога: сбор кандидатов идёт
	//    по ключам gases, и бакет газа, которого в смеси нет вовсе, не заводится
	//    ни при каком поле. Обычный случай freonformation именно такой (плазма +
	//    CO2 + BZ, фреона ноль), и без метки freonfire откладывался бы на фаер.
	var/has_followups = FALSE
	for(var/datum/gas_reaction/reaction as anything in gas_reactions)
		var/produced = reaction.synthesis_gas
		if(!produced)
			continue
		var/last_consumer = bucket_last_index[produced]
		if(isnull(last_consumer) || reaction.sort_index >= last_consumer)
			continue
		floors -= produced
		reaction.synthesis_followup_gas = produced
		has_followups = TRUE
	reactions_by_key_gas = by_gas
	reactions_key_gas_floor = floors
	reactions_have_synthesis_followups = has_followups
	temp_gated_reactions = temp_gated
	temp_gated_needs_fuel = needs_fuel
	temp_gated_min_temp = gate_floor

/proc/auxtools_atmos_init(gas_data)
	return TRUE

/proc/_auxtools_register_gas(gas)
	return

/turf/proc/__update_auxtools_turf_adjacency_info()
	if(!SSair || !istype(src, /turf/open))
		return
	var/turf/open/open_turf = src
	if(open_turf.blocks_air || !open_turf.air)
		SSair.remove_from_active(open_turf)
		return
	// During world bootstrap adjacency is recalculated for every open turf; waking all of them
	// at once causes massive active-list churn and slows perceived flow dramatically.
	if(!SSair.initialized)
		return
	// A recalculation that confirms the turf is sealed must not wake it: there
	// is nothing to share with, so process_cell would queue yet another
	// recalculation and rest, and the SSair <-> SSadjacent_air bounce becomes
	// a permanent loop. Every fulltile-window turf poked once (a door cycling
	// next to it) joined that loop forever - with each recalculation also
	// waking its open neighbors, thousands of wake/drop pairs per fire.
	if(!length(open_turf.atmos_adjacent_turfs))
		return
	// A recalculation moves no gas: give the turf its cycle to re-compare, not a
	// fresh stall budget. A door cycling next to a settled room used to hand its
	// whole neighborhood a new rest window every time it opened.
	ATMOS_BENCH_WAKE(open_turf, "adjacency")
	SSair.add_to_active(open_turf, FALSE, reset_stall = FALSE)

/turf/proc/update_air_ref(flag)
	if(!SSair)
		return
	if(!istype(src, /turf/open))
		return
	var/turf/open/open_turf = src
	// Датум смеси у турфа мог смениться (ChangeTurf, маплоадер). Мемо оверлея
	// ключуется по mutation_rev, а у свежей смеси он начинается с нуля и может
	// совпасть с запомненным - сбрасываем ключ, чтобы гейт не дал ложное попадание.
	open_turf.atmos_visual_rev = -1
	if(flag == -1 || flag == 0 || open_turf.blocks_air || !open_turf.air)
		SSair.remove_from_active(open_turf)
		return
	if(!(flag & AIR_REF_PLANETARY_TURF) || istype(open_turf, /turf/open/space))
		return
	// Eagerly build the shared planetary template so consumers that read
	// SSair.planetary directly (ashwalker lungs) find it populated.
	SSair.get_planetary_template(open_turf)
	// А вот будить турф на загрузке карты нельзя, и по той же причине, по которой
	// этого не делает пересчёт смежности тремя проками выше. setup_allturfs()
	// идёт по ВСЕМУ миру, включая лаваленд, away-миссии, VR и руины, и клал сюда
	// каждый планетарный турф без единой проверки.
	//
	// Работы в этом ноль: воздух турфа собирается из того же самого
	// initial_gas_mix, что и шаблон, так что первый же process_cell видит
	// совпадение и выселяет турф обратно. Прод мерил 93533 турфа в очереди, из
	// которых оставалось около полутора тысяч - то есть 98% списка были
	// холостыми. Платил за них раунд дважды: SSair не фитится в лобби (runlevels
	// без RUNLEVEL_SETUP), поэтому очередь стояла нетронутой до старта и
	// разгребалась ровно в тот момент, когда спавнится сотня игроков - это и был
	// единственный спайк тайм-дилатации 110-120% каждого раунда.
	//
	// Турф, ставший планетарным уже в игре (ChangeTurf), гард не задевает.
	// Замапленные градиенты у планетарных границ (устье пещеры, пролом руины)
	// на роундстарте находит адресный проход в SSair.setup_allturfs() - по
	// расхождению строк initial_gas_mix соседей, без холостого хвоста.
	if(SSair.initialized && !SSair.map_loading)
		// Смена ссылки на смесь газ не двигала: один цикл на сверку с шаблоном
		// турфу нужен, свежее окно отдыха - нет.
		ATMOS_BENCH_WAKE(open_turf, "air_ref")
		SSair.add_to_active(open_turf, FALSE, reset_stall = FALSE)

/proc/_dm_atmos_should_process_pair(turf/open/source, turf/open/target)
	if(!source || !target || source == target)
		return FALSE
	if(source.z != target.z)
		return source.z < target.z
	if(source.y != target.y)
		return source.y < target.y
	return source.x < target.x

/datum/gas_mixture/proc/__gasmixture_register()
	if(dm_registered_to_ssair || !SSair)
		return FALSE
	dm_registered_to_ssair = TRUE
	SSair.dm_registered_gas_mixtures++
	SSair.dm_max_registered_gas_mixtures = max(SSair.dm_max_registered_gas_mixtures, SSair.dm_registered_gas_mixtures)
	return TRUE

/datum/gas_mixture/proc/__gasmixture_unregister()
	if(!dm_registered_to_ssair || !SSair)
		return FALSE
	dm_registered_to_ssair = FALSE
	SSair.dm_registered_gas_mixtures = max(0, SSair.dm_registered_gas_mixtures - 1)
	return TRUE

/datum/gas_mixture/proc/__auxtools_parse_gas_string(string)
	return parse_gas_string(string)

// gas_mixture: хранение в gases[gas_id] = moles, temperature, volume
/datum/gas_mixture/proc/get_moles(gas_id)
	return gases[gas_id] || 0

// Мутаторы ниже бампают mutation_rev - контракт sleeping edges и мемо обходов
// газ-листа (см. декларацию в gas_mixture.dm).
//
// Прямая запись в gases мимо этих проков в кодбазе допустима ровно в двух местах,
// и оба бампают ревизию сами: equalize_all_gases_in_list() выше и mix_zone() при
// разборе excited-группы (LINDA_turf_tile.dm). Любой НОВЫЙ прямой писатель обязан
// сделать то же - молчаливая правка списка оставит и сумму молей, и теплоёмкость,
// и архив, и оверлей турфа описывающими прежнее содержимое до конца раунда.
// Единственным нарушителем был диагностический GAS_GARBAGE_COLLECT в догборг-
// сканере: он подчищал околонулевые ключи ЖИВОЙ смеси турфа ради вывода в чат.
/datum/gas_mixture/proc/set_moles(gas_id, amt_val)
	if(gc_share)
		return FALSE
	gases[gas_id] = max(0, amt_val)
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/adjust_moles(id_val, num_val)
	if(gc_share)
		return FALSE
	set_moles(id_val, get_moles(id_val) + num_val)
	return TRUE

/datum/gas_mixture/proc/return_temperature()
	return temperature

/datum/gas_mixture/proc/set_temperature(arg_temp)
	if(gc_share)
		return FALSE
	arg_temp = max(arg_temp, TCMB)
	if(temperature != arg_temp)
		temperature = arg_temp
		mutation_rev++
	return TRUE

/datum/gas_mixture/proc/return_volume()
	return max(0, volume)

/datum/gas_mixture/proc/set_volume(vol_arg)
	if(gc_share)
		return FALSE
	volume = max(0, vol_arg)
	return TRUE

// Горячие циклы ниже ходят двухпеременной итерацией (tg 7312275a5fb): value
// приезжает вместе с ключом, без второго хеш-чтения list[id] на каждый шаг.
// Соглашение действует для всей секции; там, где значение не нужно вовсе
// (has_ignitable_fuel), однопеременная форма остаётся правильной.
//
// Свёртки газ-листа идут нативными редукциями BYOND 516 (values_sum/values_dot)
// вместо DM-цикла: редукция выполняется в движке за один вызов, тогда как цикл
// платит интерпретатором за каждый ключ. tg перевёл свои же три прока на них в
// #96448 и намерил около -20% на process_cell; у нас газ-лист уже плоский
// assoc "id -> моли", а GLOB.gas_data.specific_heats - готовый вектор
// коэффициентов, так что переносится ровно тело.
//
// Мемо по mutation_rev оставлено: оно закрывает ПОПАДАНИЯ (осевший турф, где
// свёртка не нужна вовсе), а редукция удешевляет ПРОМАХИ - двигающийся турф,
// у которого каждый шер бампает ревизию обоих концов. Это разные половины
// нагрузки, и убирать одну ради другой нечего.
//
// Контракт редукций (пустой список, ключ без коэффициента, порядок аргументов)
// закреплён тестом atmos_vector_reductions - он же поймает смену поведения в
// будущем BYOND.
/datum/gas_mixture/proc/total_moles()
	if(total_moles_rev == mutation_rev)
		return total_moles_cache
	. = values_sum(gases)
	total_moles_cache = .
	total_moles_rev = mutation_rev

/datum/gas_mixture/proc/heat_capacity()
	if(heat_capacity_rev == mutation_rev)
		return heat_capacity_cache
	// Ключ, которого нет в specific_heats, даёт нулевой вклад - ровно то, что
	// делал `cached_gasheats[id] || 0` в снятом цикле.
	. = max(values_dot(gases, GLOB.gas_data.specific_heats), min_heat_capacity)
	heat_capacity_cache = .
	heat_capacity_rev = mutation_rev

/datum/gas_mixture/proc/thermal_energy()
	return temperature * heat_capacity()

/datum/gas_mixture/proc/return_pressure()
	if(volume <= 0)
		return 0
	return total_moles() * R_IDEAL_GAS_EQUATION * temperature / volume

/datum/gas_mixture/proc/clear()
	if(gc_share)
		return FALSE
	gases.Cut()
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/archive()
	temperature_archived = temperature
	// Копия списка - аллокация на турф на цикл. Если с прошлого снимка смесь не
	// правили, прежний архив побайтово равен тому, что дал бы Copy() сейчас, и
	// пересниматься незачем. Температура пишется безусловно: она в архив входит
	// отдельным полем и от списка не зависит.
	if(gas_archive && archive_mutation_rev == mutation_rev)
		return TRUE
	gas_archive = gases.Copy()
	archive_mutation_rev = mutation_rev
	// Инвалидация мемо архивной теплоёмкости: она считается по gas_archive.
	archive_gen++
	return TRUE

/datum/gas_mixture/proc/get_gases()
	return gases

/datum/gas_mixture/proc/merge(datum/gas_mixture/giver)
	if(gc_share || !giver)
		return FALSE
	if(abs(temperature - giver.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()
		var/giver_heat_capacity = giver.heat_capacity()
		var/combined_heat_capacity = giver_heat_capacity + self_heat_capacity
		if(combined_heat_capacity > 0)
			temperature = (giver.temperature * giver_heat_capacity + temperature * self_heat_capacity) / combined_heat_capacity
	for(var/giver_id, giver_moles in giver.gases)
		gases[giver_id] = (gases[giver_id] || 0) + (giver_moles || 0)
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/copy_from(datum/gas_mixture/giver)
	if(gc_share || !giver)
		return FALSE
	gases.Cut()
	for(var/id, giver_moles in giver.gases)
		gases[id] = giver_moles
	temperature = giver.temperature
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/archived_heat_capacity()
	// Без архива значение зависит от живой смеси (LINDA_fire обнуляет gas_archive
	// намеренно) - тогда это обычная теплоёмкость с её собственным мемо.
	if(!gas_archive)
		return heat_capacity()
	if(archived_heat_capacity_gen == archive_gen)
		return archived_heat_capacity_cache
	. = max(values_dot(gas_archive, GLOB.gas_data.specific_heats), min_heat_capacity)
	archived_heat_capacity_cache = .
	archived_heat_capacity_gen = archive_gen

/datum/gas_mixture/proc/__remove(datum/gas_mixture/into, amount_arg)
	if(gc_share)
		return
	var/sum = total_moles()
	amount_arg = min(amount_arg, sum)
	if(amount_arg <= 0)
		return
	var/ratio = sum > 0 ? amount_arg / sum : 0
	into.temperature = temperature
	if(!into.gases)
		into.gases = list()
	for(var/id, current_moles in gases)
		var/amt = (current_moles || 0) * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (current_moles || 0) - amt
	mutation_rev++
	into.mutation_rev++
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/__remove_ratio(into, ratio_arg)
	if(gc_share)
		return
	ratio_arg = clamp(ratio_arg, 0, 1)
	__remove(into, total_moles() * ratio_arg)

/// Moves `ratio` (0..1) of every gas from src into other in place, with the same
/// temperature math as merge(remove(...)), without allocating a temporary mixture.
/// Callers guarantee ratio > 0 and both mixtures mutable.
/// Returns TRUE only when gas actually moved, matching vent_moles/vent_ratio, so
/// callers can treat the result as "did work" for idle accounting.
/datum/gas_mixture/proc/__transfer_ratio_direct(datum/gas_mixture/other, ratio)
	var/list/cached_gases = gases
	var/list/other_gases = other.gases
	var/heat_transfer = abs(other.temperature - temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER
	var/other_old_capacity = 0
	var/moved_heat_capacity = 0
	var/list/cached_gasheats
	if(heat_transfer)
		other_old_capacity = other.heat_capacity()
		cached_gasheats = GLOB.gas_data.specific_heats
	var/moved_any = FALSE
	for(var/id, current_moles in cached_gases)
		var/moved = current_moles * ratio
		if(moved <= 0)
			continue
		moved_any = TRUE
		other_gases[id] = (other_gases[id] || 0) + moved
		cached_gases[id] -= moved
		if(heat_transfer)
			moved_heat_capacity += moved * (cached_gasheats[id] || 0)
	if(!moved_any)
		return FALSE
	if(heat_transfer && moved_heat_capacity > 0)
		var/combined_heat_capacity = other_old_capacity + moved_heat_capacity
		other.temperature = (temperature * moved_heat_capacity + other.temperature * other_old_capacity) / combined_heat_capacity
	mutation_rev++
	other.mutation_rev++
	GAS_GARBAGE_COLLECT(cached_gases)
	return TRUE

/datum/gas_mixture/proc/transfer_to(datum/gas_mixture/other, moles)
	if(gc_share || !other || other.gc_share)
		return FALSE
	var/list/cached_gases = gases
	var/sum = 0
	for(var/id, gas_moles in cached_gases)
		sum += gas_moles
	moles = min(moles, sum)
	if(moles <= 0)
		// Nothing to move (empty source): report no-op so vents/pumps can idle
		// instead of counting a phantom transfer every fire.
		return FALSE
	return __transfer_ratio_direct(other, moles / sum)

/// Суммарная окислительная способность смеси при температуре temp.
///
/// threshold - необязательный порог для вызывающих, которым нужен только ответ
/// "хватает ли": сумма из неотрицательных слагаемых, поэтому как только она его
/// перевалила, добирать остаток газ-листа незачем и цикл выходит. Возвращённое
/// значение тогда усечено (оно >= threshold, но не полное) - сравнивать с ним
/// можно, использовать как число нельзя. Без аргумента поведение прежнее.
/// Мотив: гейт горящей плитки зовёт этот прок каждый проход на каждом очаге, а
/// в пожаре кислорода заведомо больше порога и он находится на первом-втором
/// газе из шести-девяти.
/datum/gas_mixture/proc/get_oxidation_power(temp, threshold)
	if(isnull(temp))
		temp = return_temperature()
	. = 0
	var/list/oxidation_temps = GLOB.gas_data.oxidation_temperatures
	var/list/oxidation_rates = GLOB.gas_data.oxidation_rates
	for(var/id, gas_moles in gases)
		var/t_ox = oxidation_temps[id]
		if(t_ox && temp >= t_ox)
			var/temperature_scale = max(0, 1 - (t_ox / max(temp, TCMB)))
			. += (gas_moles || 0) * (oxidation_rates[id] || 0) * temperature_scale
			if(threshold && . >= threshold)
				return .
	return .

/// TRUE when at least one gas in the mixture has reached its own ignition
/// temperature. Deliberately ignores moles and burn rates: this is a gate in
/// front of the fire reactions, so it must never answer FALSE where
/// get_fuel_amount() would have returned something positive.
/datum/gas_mixture/proc/has_ignitable_fuel(temp)
	if(isnull(temp))
		temp = return_temperature()
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	for(var/id in gases)
		var/t_f = fuel_temps[id]
		if(t_f && temp >= t_f)
			return TRUE
	return FALSE

/// Топливо смеси при температуре temp. threshold работает ровно как у
/// get_oxidation_power() выше: усечённая сумма для гейтов, полная - без него.
/datum/gas_mixture/proc/get_fuel_amount(temp, threshold)
	if(isnull(temp))
		temp = return_temperature()
	. = 0
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	var/list/fuel_rates = GLOB.gas_data.fire_burn_rates
	for(var/id, gas_moles in gases)
		var/t_f = fuel_temps[id]
		if(t_f && temp >= t_f)
			var/temperature_scale = max(0, 1 - (t_f / max(temp, TCMB)))
			. += ((gas_moles || 0) / max(fuel_rates[id], 0.01)) * temperature_scale
			if(threshold && . >= threshold)
				return .
	return .

/datum/gas_mixture/proc/equalize_with(datum/gas_mixture/total)
	if(gc_share || !total)
		return
	var/total_vol = volume + total.volume
	if(total_vol <= 0)
		return
	var/self_heat = heat_capacity()
	var/other_heat = total.heat_capacity()
	if(self_heat + other_heat > 0)
		temperature = (temperature * self_heat + total.temperature * other_heat) / (self_heat + other_heat)
		total.temperature = temperature
	for(var/id in gases | total.gases)
		var/our_m = gases[id] || 0
		var/their_m = total.gases[id] || 0
		var/combined = our_m + their_m
		gases[id] = combined * volume / total_vol
		total.gases[id] = combined * total.volume / total_vol
	mutation_rev++
	total.mutation_rev++

/datum/gas_mixture/proc/transfer_ratio_to(datum/gas_mixture/other, ratio)
	if(gc_share || !other || other.gc_share)
		return FALSE
	ratio = clamp(ratio, 0, 1)
	if(ratio <= 0)
		// See transfer_to(): a no-op must not read as a successful transfer.
		return FALSE
	return __transfer_ratio_direct(other, ratio)

/// Discards `ratio` (0..1) of every gas in place: venting into an infinite sink
/// (space). Equivalent to qdel(remove_ratio(ratio)) without the allocation.
/// Returns TRUE if any gas was actually discarded.
/datum/gas_mixture/proc/vent_ratio(ratio)
	if(gc_share)
		return FALSE
	ratio = clamp(ratio, 0, 1)
	if(ratio <= 0)
		return FALSE
	var/list/cached_gases = gases
	if(ratio >= 1)
		// Полный сброс - штатный путь кромки пробоины (tg-паритет), Cut()
		// дешевле поэлементного умножения в ноль с последующей чисткой.
		if(!length(cached_gases))
			return FALSE
		cached_gases.Cut()
		mutation_rev++
		return TRUE
	var/keep = 1 - ratio
	var/vented = 0
	for(var/id, current_moles in cached_gases)
		if(current_moles <= 0)
			continue
		vented += current_moles * ratio
		cached_gases[id] = current_moles * keep
	if(vented <= 0)
		return FALSE
	mutation_rev++
	GAS_GARBAGE_COLLECT(cached_gases)
	return TRUE

/// Discards `moles` of gas in place, proportionally across all gases.
/// Equivalent to qdel(remove(moles)) without the allocation.
/// Returns TRUE if any gas was actually discarded.
/datum/gas_mixture/proc/vent_moles(moles)
	if(gc_share)
		return FALSE
	var/list/cached_gases = gases
	var/sum = 0
	for(var/id, gas_moles in cached_gases)
		sum += gas_moles
	moles = min(moles, sum)
	if(moles <= 0)
		return FALSE
	return vent_ratio(moles / sum)

/datum/gas_mixture/proc/adjust_heat(heat)
	if(gc_share)
		return FALSE
	var/cap = heat_capacity()
	if(cap > MINIMUM_HEAT_CAPACITY)
		set_temperature(temperature + heat / cap)
	return TRUE

/datum/gas_mixture/proc/compare(datum/gas_mixture/other)
	if(!other)
		return "invalid"
	// Runs for every adjacent turf pair every cycle: iterate both key sets directly
	// instead of allocating a `gases | other.gases` union list per call.
	var/list/cached_gases = gases
	var/list/other_gases = other.gases
	var/our_moles = 0
	for(var/id, iter_moles in cached_gases)
		var/gas_moles = iter_moles || 0
		our_moles += gas_moles
		var/delta = abs(gas_moles - (other_gases[id] || 0))
		if(delta > MINIMUM_MOLES_DELTA_TO_MOVE)
			if(delta > gas_moles * MINIMUM_AIR_RATIO_TO_MOVE)
				return id
	for(var/id, other_moles in other_gases)
		// Key presence, O(1), same semantics as `in`: a key holding exactly zero
		// was already compared above and must not be re-tested here.
		if(!isnull(cached_gases[id]))
			continue
		// gas_moles is 0 for ids we lack, so the ratio gate is always passed.
		if(abs(other_moles || 0) > MINIMUM_MOLES_DELTA_TO_MOVE)
			return id
	if(our_moles > MINIMUM_MOLES_DELTA_TO_MOVE)
		if(abs(temperature - other.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
			return "temp"
	return ""

/datum/gas_mixture/proc/mark_immutable()
	gc_share = TRUE
	immutable_heat_capacity = heat_capacity()
	return TRUE

/// Moves `ratio_v` of the gases named in gas_list into `into` in place, with the
/// same temperature math as merge(removed portion). Returns TRUE only when gas
/// actually moved, so callers can skip turf/pipenet updates for clean rooms.
/datum/gas_mixture/proc/scrub_into(datum/gas_mixture/into, ratio_v, list/gas_list)
	if(gc_share || !into || into.gc_share)
		return FALSE
	ratio_v = clamp(ratio_v, 0, 1)
	if(ratio_v <= 0 || !length(gas_list))
		return FALSE
	var/list/cached_gases = gases
	var/list/into_gases = into.gases
	var/heat_transfer = abs(into.temperature - temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER
	var/into_old_capacity = 0
	var/moved_heat_capacity = 0
	var/list/cached_gasheats
	if(heat_transfer)
		into_old_capacity = into.heat_capacity()
		cached_gasheats = GLOB.gas_data.specific_heats
	var/moved_any = FALSE
	for(var/gid in gas_list)
		var/current_moles = cached_gases[gid] || 0
		if(current_moles <= 0)
			continue
		var/moved = current_moles * ratio_v
		if(moved <= 0)
			continue
		moved_any = TRUE
		into_gases[gid] = (into_gases[gid] || 0) + moved
		cached_gases[gid] = current_moles - moved
		if(heat_transfer)
			moved_heat_capacity += moved * (cached_gasheats[gid] || 0)
	if(!moved_any)
		return FALSE
	if(heat_transfer && moved_heat_capacity > 0)
		var/combined_heat_capacity = into_old_capacity + moved_heat_capacity
		into.temperature = (temperature * moved_heat_capacity + into.temperature * into_old_capacity) / combined_heat_capacity
	mutation_rev++
	into.mutation_rev++
	GAS_GARBAGE_COLLECT(cached_gases)
	return TRUE

/datum/gas_mixture/proc/get_by_flag(flag_val)
	. = list()
	var/list/flags = GLOB.gas_data.flags
	for(var/id, gas_moles in gases)
		if(flags[id] & flag_val)
			.[id] = gas_moles

/datum/gas_mixture/proc/__remove_by_flag(datum/gas_mixture/into, flag_val, amount_val)
	if(gc_share)
		return
	var/list/with_flag = get_by_flag(flag_val)
	var/sum = 0
	for(var/id, flag_moles in with_flag)
		sum += flag_moles
	if(sum <= 0)
		return
	var/ratio = min(1, amount_val / sum)
	into.temperature = temperature
	for(var/id, flag_moles in with_flag)
		var/amt = flag_moles * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (gases[id] || 0) - amt
	mutation_rev++
	into.mutation_rev++
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/divide(num_val)
	if(gc_share)
		return FALSE
	if(num_val <= 0)
		return FALSE
	for(var/id, gas_moles in gases)
		gases[id] = gas_moles / num_val
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/multiply(num_val)
	if(gc_share)
		return FALSE
	for(var/id, gas_moles in gases)
		gases[id] = gas_moles * num_val
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/subtract(num_val)
	if(gc_share)
		return FALSE
	for(var/id, gas_moles in gases)
		gases[id] = max(0, (gas_moles || 0) - num_val)
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/add(num_val)
	if(gc_share)
		return FALSE
	for(var/id, gas_moles in gases)
		gases[id] = (gas_moles || 0) + num_val
	mutation_rev++
	return TRUE

/datum/gas_mixture/proc/adjust_multi(...)
	if(gc_share)
		return FALSE
	var/list/arglist = args
	for(var/i in 2 to length(arglist))
		var/list/elem = arglist[i]
		if(length(elem) >= 2)
			adjust_moles(elem[1], elem[2])
	return TRUE

/datum/gas_mixture/proc/adjust_moles_temp(id_val, num_val, temp_val)
	if(gc_share)
		return FALSE
	adjust_moles(id_val, num_val)
	if(num_val != 0 && total_moles() > 0)
		var/cap = heat_capacity()
		if(cap > MINIMUM_HEAT_CAPACITY)
			var/list/cached_gasheats = GLOB.gas_data.specific_heats
			var/delta_heat = num_val * (cached_gasheats[id_val] || 0) * temp_val
			temperature = (temperature * cap + delta_heat) / heat_capacity()
			mutation_rev++
	return TRUE

/datum/gas_mixture/proc/partial_heat_capacity(gas_id)
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	return (gases[gas_id] || 0) * (cached_gasheats[gas_id] || 0)

/datum/gas_mixture/proc/set_min_heat_capacity(arg_min)
	if(gc_share)
		return FALSE
	min_heat_capacity = max(0, arg_min)
	// Пол теплоёмкости входит в её значение (max в конце heat_capacity), но
	// mutation_rev при этом не двигается - мемо надо сбить руками, иначе кэш
	// переживёт смену пола.
	heat_capacity_rev = -1
	archived_heat_capacity_gen = -1
	return TRUE

/datum/gas_mixture/proc/temperature_share(datum/gas_mixture/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	if(gc_share)
		if(sharer)
			return sharer.return_temperature()
		return sharer_temperature
	var/sharer_is_immutable = sharer?.gc_share
	if(sharer)
		sharer_temperature = sharer.temperature_archived
	var/temperature_delta = temperature_archived - sharer_temperature
	if(abs(temperature_delta) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = archived_heat_capacity()
		if(!sharer_heat_capacity && sharer)
			sharer_heat_capacity = sharer.archived_heat_capacity()
		if(self_heat_capacity > MINIMUM_HEAT_CAPACITY && sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
			var/heat = conduction_coefficient * temperature_delta * (self_heat_capacity * sharer_heat_capacity / (self_heat_capacity + sharer_heat_capacity))
			temperature = max(temperature - heat / self_heat_capacity, TCMB)
			mutation_rev++
			sharer_temperature = max(sharer_temperature + heat / sharer_heat_capacity, TCMB)
			if(sharer && !sharer_is_immutable)
				sharer.temperature = sharer_temperature
				sharer.mutation_rev++
	return sharer_temperature

/datum/gas_mixture/proc/react(datum/holder)
	. = NO_REACTION
	var/list/cached_gases = gases
	// Оба поля подсистемы читаются ниже второй раз (гейт температуры и сбор
	// кандидатов). Глобальное чтение SSair - не бесплатное, а прок зовут на каждый
	// активный турф, каждый пайпнет и каждый переносной баллон каждый фаер.
	var/datum/controller/subsystem/air/air_controller = SSair
	var/list/reaction_index = air_controller.reactions_by_key_gas
	var/gated_min_temp = air_controller.temp_gated_min_temp
	// The overwhelming turf case is cool O2/N2 air. The reaction index is
	// authoritative, so only skip when neither common gas owns a candidate and
	// no temperature-only reaction can be eligible.
	if(length(cached_gases) == 2 && cached_gases[GAS_O2] && cached_gases[GAS_N2] && temperature < gated_min_temp)
		if(reaction_index && !reaction_index[GAS_O2] && !reaction_index[GAS_N2])
			if(length(reaction_results))
				reaction_results.Cut()
			return
	// Gather candidates through the key-gas index instead of scanning every
	// registered reaction: a reaction can only fire if its key gas is present.
	// This runs for every active turf, pipenet and portable every SSair fire,
	// and ordinary o2/n2 air resolves to zero candidates.
	var/temp = temperature
	var/list/candidates
	// The single-bucket case (one keyed gas present, by far the most common)
	// borrows the prebuilt bucket read-only: buckets are already in sort_index
	// order and the reaction loop never mutates the list, so both the copy and
	// the re-sort below are only needed once a second source gets appended.
	var/candidates_owned = FALSE
	var/list/by_gas = reaction_index
	var/list/key_gas_floor = air_controller.reactions_key_gas_floor
	if(by_gas)
		for(var/id, gas_moles in cached_gases)
			var/list/bucket = by_gas[id]
			if(!bucket)
				continue
			// Ключ есть, но молей меньше самого мягкого требования бакета: ни одна
			// его реакция не пройдёт сравнение с min_reqs в цикле ниже, а до этого
			// цикла мы бы уже заплатили за копию кандидатов, total_moles(), Cut() и
			// сортировку вставками. Тот же отказ, вынесенный на несколько десятков
			// строк выше. Пустой пол читается как ноль и не отсекает ничего, так
			// что смесь без построенного индекса ведёт себя как прежде.
			//
			// ИНВАРИАНТ: моли читаются здесь, на СБОРЕ кандидатов, а цикл реакций
			// ниже перечитывает их заново. Реакция, чей ключевой газ переваливает
			// через порог благодаря другой реакции ТОГО ЖЕ вызова, откладывалась бы
			// на один фаер SSair. Такие газы пола не получают вовсе:
			// auxtools_update_reactions() сверяет позицию производителя
			// (synthesis_gas) с позицией последней реакции бакета и снимает пол,
			// если производитель идёт раньше. Случай "газа в смеси нет совсем"
			// пол не закрывает - его добирает проход по followup ниже. Новой
			// реакции достаточно объявить synthesis_gas - руками тут править нечего.
			var/bucket_floor = key_gas_floor?[id]
			if(bucket_floor && gas_moles < bucket_floor)
				continue
			if(!candidates)
				candidates = bucket
			else
				if(!candidates_owned)
					candidates = candidates.Copy()
					candidates_owned = TRUE
				candidates += bucket
		if(temp >= gated_min_temp)
			var/list/temp_gated = air_controller.temp_gated_reactions
			var/list/needs_fuel = air_controller.temp_gated_needs_fuel
			// Проверка топлива откладывается до первой реакции, которой оно нужно,
			// и делается один раз на вызов.
			var/fuel_checked = FALSE
			var/has_fuel = FALSE
			for(var/r, min_temp in temp_gated)
				if(temp < min_temp)
					continue
				// Реакция с требованием FIRE_REAGENTS не может сделать ничего, если
				// в смеси нет ни одного газа, доросшего до своей температуры
				// возгорания: get_fuel_amount() вернёт ноль, и реакция выйдет с
				// NO_REACTION, оплатив до этого сбор кандидатов, сортировку и ДВА
				// полных обхода газ-листа (топливо и окислитель).
				//
				// Почему это вообще происходит на обычной станции: единственная
				// безгазовая реакция - genericfire, её порог TEMP считается как
				// max(минимум по окислителям, минимум по топливу), а минимум по
				// топливу задаёт флогистон с fire_temperature = T20C+1 = 294.15 K.
				// Воздух турфа - 293.15 K, то есть запас ровно один градус, и любой
				// подогретый людьми или лампами тайл проваливался сюда.
				//
				// Гейт - консервативная надоценка того же условия, что и внутри
				// get_fuel_amount(): моли и скорость горения он не смотрит, поэтому
				// пропустить реакцию, которая бы сработала, он не может.
				if(needs_fuel?[r])
					if(!fuel_checked)
						fuel_checked = TRUE
						has_fuel = has_ignitable_fuel(temp)
					if(!has_fuel)
						continue
				if(!candidates)
					candidates = list()
					candidates_owned = TRUE
				else if(!candidates_owned)
					candidates = candidates.Copy()
					candidates_owned = TRUE
				candidates += r
		// Потребитель газа, которого в смеси ещё НЕТ, а производитель уже в
		// кандидатах и идёт раньше него. Сбор выше ходит по ключам gases, поэтому
		// бакет такого газа не заводится ни при каком поле - именно так пара
		// freonformation (плазма + CO2 + BZ) / freonfire теряла горение на один
		// фаер SSair, хотя фреон рождался строкой выше в этом же вызове. Цикл
		// реакций всё равно сверяет min_requirements по живым молям, так что
		// лишний кандидат не может ничего запустить раньше времени.
		if(candidates && air_controller.reactions_have_synthesis_followups)
			var/list/followup_gases
			for(var/datum/gas_reaction/producer as anything in candidates)
				var/followup_gas = producer.synthesis_followup_gas
				// Ключ в смеси уже есть - бакет собран основным циклом (пол с таких
				// газов снят там же, где ставится метка, поэтому не срезан).
				if(!followup_gas || !isnull(cached_gases[followup_gas]))
					continue
				if(!followup_gases)
					followup_gases = list(followup_gas)
				else if(!(followup_gas in followup_gases))
					followup_gases += followup_gas
			// Дописываем ПОСЛЕ обхода: candidates может быть одолженным бакетом, и
			// править список, по которому идёт цикл, нельзя в любом случае.
			for(var/followup_gas in followup_gases)
				var/list/bucket = by_gas[followup_gas]
				if(!length(bucket))
					continue
				if(!candidates_owned)
					candidates = candidates.Copy()
					candidates_owned = TRUE
				candidates += bucket
	else
		candidates = SSair.gas_reactions.Copy()
		candidates_owned = TRUE

	// Кандидатов нет - ни один газ смеси не владеет бакетом реакций и ни одна
	// температурная не подошла. Дальше делать нечего, и это подавляющее
	// большинство вызовов: react() бежит по каждому активному турфу, пайпнету и
	// переносному баллону каждый проход SSair.
	//
	// Проверка стоит ПЕРЕД суммой молей намеренно: у обеих ранних развилок исход
	// один и тот же (NO_REACTION с погашенными результатами), поэтому смеси без
	// кандидатов незачем платить ещё одним полным проходом по списку газов.
	// Результаты прошлого вызова гасим и здесь: их читают хотспоты сразу после
	// react(), и залипший "fire" поджёг бы плитку, на которой уже нечему гореть.
	if(!length(candidates))
		if(length(reaction_results))
			reaction_results.Cut()
		return

	// Через мемоизированный прок, а не своим циклом: на этом же фаере сумму уже
	// посчитал process_cell для порогов значимости (LINDA_turf_tile.dm), ревизия
	// с тех пор не менялась, и здесь это попадание в кэш вместо второго обхода.
	var/total = total_moles()
	if(!total)
		// A mixture that reacted on a previous call and has since been emptied
		// must not leave stale per-call results (hotspots read them after react()).
		if(length(reaction_results))
			reaction_results.Cut()
		return

	// Every react() past the moles gate must leave reaction_results reflecting
	// only this call: hotspots read reaction_results["fire"] right after react().
	if(length(reaction_results))
		reaction_results.Cut()
	else if(!reaction_results)
		reaction_results = new

	// Restore the priority order of the full-list scan (insertion sort; the
	// candidate list is nearly always 1-3 entries). A borrowed single bucket is
	// already sorted and must not be written to.
	if(candidates_owned && candidates.len > 1)
		for(var/i in 2 to candidates.len)
			var/datum/gas_reaction/shifted = candidates[i]
			var/hole = i - 1
			while(hole >= 1)
				var/datum/gas_reaction/other = candidates[hole]
				if(other.sort_index <= shifted.sort_index)
					break
				candidates[hole + 1] = other
				hole--
			candidates[hole + 1] = shifted

	var/ener = -1
	// Давление считается лениво и не больше одного раза за react(): реакций с
	// порогом по давлению в игре единицы, а цикл проходят все кандидаты подряд.
	var/reaction_pressure = -1
	reaction_loop:
		for(var/datum/gas_reaction/reaction as anything in candidates)
			var/list/min_reqs = reaction.min_requirements
			if(min_reqs["TEMP"] && temp < min_reqs["TEMP"])
				continue
			if(min_reqs["ENER"])
				if(ener < 0)
					ener = thermal_energy()
				if(ener < min_reqs["ENER"])
					continue
			if(min_reqs["MAX_TEMP"] && temp > min_reqs["MAX_TEMP"])
				continue
			if(min_reqs[REACTION_REQ_MIN_PRESSURE])
				if(reaction_pressure < 0)
					reaction_pressure = return_pressure()
				if(reaction_pressure < min_reqs[REACTION_REQ_MIN_PRESSURE])
					continue
			for(var/id in min_reqs)
				if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP" || id == REACTION_REQ_MIN_PRESSURE)
					continue
				if(id == "FIRE_REAGENTS")
					// Оба прока тут - чистый гейт "хватает ли", поэтому берут порог
					// и выходят на первом же газе, который его перекрыл.
					if(get_oxidation_power(temp, min_reqs[id]) < min_reqs[id] || get_fuel_amount(temp, min_reqs[id]) < min_reqs[id])
						continue reaction_loop
					continue
				if((cached_gases[id] || 0) < min_reqs[id])
					continue reaction_loop
			var/reaction_result = reaction.react(src, holder)
			. |= reaction_result
			// Первый за раунд синтез газа платит очками науки. Флаг взводится
			// после первой выплаты, поэтому дальше это одно чтение переменной, а
			// не поиск по списку техвеба на каждом активном турфе.
			if(!reaction.synthesis_reported && (reaction_result & REACTING) && !reaction.synthesis_self_reported)
				reaction.report_synthesis()
			if(. & STOP_REACTIONS)
				break
