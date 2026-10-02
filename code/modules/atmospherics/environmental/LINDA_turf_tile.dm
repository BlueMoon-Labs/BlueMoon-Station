/turf
	//conductivity is divided by 10 when interacting with air for balance purposes
	var/thermal_conductivity = 0.05
	var/heat_capacity = 1
	var/temperature_archived = TCMB
	var/archived_cycle = 0
	var/current_cycle = 0

	//list of open turfs adjacent to us
	var/list/atmos_adjacent_turfs
	//bitfield of dirs in which we thermal conductivity is blocked
	var/conductivity_blocked_directions = NONE

	//used for mapping and for breathing while in walls (because that's a thing that needs to be accounted for...)
	//string parsed by /datum/gas/proc/copy_from_turf
	var/initial_gas_mix = OPENTURF_DEFAULT_ATMOS

	///Позиция в SSair.active_turfs (0 - нет). Только подсказка для снятия за O(1): членство держит /turf/open/var/excited.
	var/tmp/active_turf_index = 0
	///Подписчики COMSIG_TURF_EXPOSE (listener -> proc), null без подписчиков - по нему process_cell гейтит отправку. Ведёт /datum/proc/register_turf_exposure(), переживает ChangeTurf.
	var/tmp/list/atmos_exposure_listeners

/turf/open
	//used for spacewind
	var/pressure_difference = 0
	var/pressure_direction = 0
	///Accumulated pressure-gradient vector; opposing gradients cancel naturally.
	var/pressure_vector_x = 0
	var/pressure_vector_y = 0
	///TRUE, пока турф стоит в SSair.high_pressure_delta. Вектор флагом служить не может: встречные вклады обнуляют его, пока турф в очереди.
	var/tmp/high_pressure_queued = FALSE
	///world.time, раньше которого новый визуал ветра на турфе не создаётся.
	var/tmp/next_space_wind_at = 0
	var/tmp/obj/effect/temp_visual/dir_setting/space_wind/space_wind_visual
	var/turf/pressure_specific_target

	var/datum/excited_group/excited_group
	var/excited = FALSE
	var/equalize_cycle = 0
	var/datum/gas_mixture/air

	var/obj/effect/hotspot/active_hotspot
	var/atmos_cooldown = 0
	var/planetary_atmos = FALSE //air will revert to initial_gas_mix over time

	var/list/atmos_overlay_types //gas IDs of current active gas overlays
	/// air.mutation_rev, по которой посчитан atmos_overlay_types. Сбрасывать в -1 при подмене датума смеси (ChangeTurf, update_air_ref): ревизия новой смеси может совпасть.
	var/tmp/atmos_visual_rev = -1
	///Vents/scrubbers that want an instant wake-up when air on this turf changes.
	///Maintained by /obj/machinery/atmospherics/register_turf_wake().
	var/tmp/list/atmos_wake_machines
	///Осевшие пары: сосед -> list(наша mutation_rev, его mutation_rev) на момент compare() без разницы. Сбрасывается в ImmediateCalculateAdjacentTurfs.
	var/tmp/list/settled_edge_revs

/turf/open/Initialize(mapload, inherited_virtual_z)
	air = new(2500,src)
	air.copy_from_turf(src)
	update_air_ref(planetary_atmos ? AIR_REF_PLANETARY_TURF : AIR_REF_OPEN_TURF)
	return ..()

/turf/open/Destroy()
	if(active_hotspot)
		QDEL_NULL(active_hotspot)
	for(var/turf/open/T as anything in atmos_adjacent_turfs)
		if(SSair)
			// Газ соседа не менялся: один цикл на пересравнение, без свежего бюджета простоя.
			ATMOS_BENCH_WAKE(T, "turf_destroy")
			SSair.add_to_active(T, FALSE, reset_stall = FALSE)
	update_air_ref(-1)
	air = null
	return ..()

/////////////////GAS MIXTURE PROCS///////////////////

/turf/open/assume_air(datum/gas_mixture/giver) //use this for machines to adjust air
	return assume_air_ratio(giver, 1)

/turf/open/assume_air_moles(datum/gas_mixture/giver, moles)
	if(!giver)
		return FALSE
	if(air?.gc_share)
		if(!giver.vent_moles(moles))
			return FALSE
	else if(!giver.transfer_to(air, moles))
		return FALSE
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return TRUE

/turf/open/assume_air_ratio(datum/gas_mixture/giver, ratio)
	if(!giver)
		return FALSE
	if(air?.gc_share)
		if(!giver.vent_ratio(ratio))
			return FALSE
	else if(!giver.transfer_ratio_to(air, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air(datum/gas_mixture/taker, moles)
	if(!taker || !return_air()) // shouldn't transfer from space
		return FALSE
	if(!air.transfer_to(taker, moles))
		return FALSE
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air_ratio(datum/gas_mixture/taker, ratio)
	if(!taker || !return_air())
		return FALSE
	if(!air.transfer_ratio_to(taker, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return TRUE

/turf/open/remove_air(amount)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove(amount)
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return removed

/turf/open/remove_air_ratio(ratio)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove_ratio(ratio)
	update_visuals()
	if(SSair)
		ATMOS_BENCH_WAKE(src, "gas_write")
		SSair.add_to_active(src)
	return removed

/turf/open/proc/copy_air(datum/gas_mixture/copy)
	if(copy)
		air.copy_from(copy)

/turf/return_air()
	RETURN_TYPE(/datum/gas_mixture)
	var/datum/gas_mixture/GM = new
	GM.copy_from_turf(src)
	return GM

/turf/open/return_air()
	RETURN_TYPE(/datum/gas_mixture)
	return air

/turf/open/return_analyzable_air()
	return return_air()

/turf/temperature_expose()
	if(return_temperature() > heat_capacity)
		to_be_destroyed = TRUE

/turf/proc/archive(cycle)
	temperature_archived = return_temperature()

/// Снимок начала цикла; process_cell разворачивает его у себя для своего турфа и соседа.
#define ARCHIVE_OPEN_TURF(target_turf, target_air, fire_cycle) target_air.archive(); target_turf.temperature_archived = target_air.temperature; target_turf.archived_cycle = fire_cycle

/// `cycle` - номер фаера SSair: process_cell гейтит по нему и свой архив, и архив соседей.
/turf/open/archive(cycle = SSair.times_fired)
	if(!air)
		return
	ARCHIVE_OPEN_TURF(src, air, cycle)

////////////////////////SUPERCONDUCTIVITY/////////////////////////////
// Тепло через твёрдое: стены, окна, закрытые двери. Только при SSair.heat_enabled (гейт в consider_superconductivity()).

/turf/proc/conductivity_directions()
	if(archived_cycle < SSair.times_fired)
		archive()
	return (NORTH|SOUTH|EAST|WEST) & ~conductivity_blocked_directions

/turf/open/conductivity_directions()
	if(blocks_air)
		return ..()
	for(var/direction in GLOB.cardinals)
		var/turf/checked_turf = get_step(src, direction)
		if(!checked_turf)
			continue
		// Directions we already share air with are handled by ordinary LINDA;
		// conduction covers the solid borders heat can still creep through.
		if(!(checked_turf in atmos_adjacent_turfs) && !(conductivity_blocked_directions & direction))
			. |= direction

/turf/proc/neighbor_conduct_with_src(turf/open/other)
	if(!other.blocks_air) //Solid src, open neighbor
		other.temperature_share_open_to_solid(src)
	else //Both solid
		other.share_temperature_mutual_solid(src, thermal_conductivity)
	temperature_expose(null, return_temperature(), null)

/turf/open/neighbor_conduct_with_src(turf/other)
	if(blocks_air)
		return ..()
	if(!air) // смеси нет - нечем ни принять тепло, ни проснуться
		return
	// Без реальной дельты не будим: иначе горячие стены держали бы осевший воздух активным вечно.
	if(!other.blocks_air) //Both open: heat-permeable border that does not pass air
		var/turf/open/open_other = other
		if(abs(air.return_temperature() - open_other.air.return_temperature()) < MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			return
		open_other.air.temperature_share(air, WINDOW_HEAT_TRANSFER_COEFFICIENT)
	else //Open src, solid neighbor
		if(abs(air.return_temperature() - other.return_temperature()) < MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			return
		temperature_share_open_to_solid(other)
	ATMOS_BENCH_WAKE(src, "conduct")
	SSair.add_to_active(src)

/turf/proc/super_conduct()
	var/conduction_dirs = conductivity_directions()
	if(conduction_dirs)
		//Conduct with tiles around me
		for(var/direction in GLOB.cardinals)
			if(!(conduction_dirs & direction))
				continue
			var/turf/neighbor = get_step(src, direction)
			if(!neighbor || !neighbor.thermal_conductivity)
				continue
			if(neighbor.archived_cycle < SSair.times_fired)
				neighbor.archive()
			neighbor.neighbor_conduct_with_src(src)
			neighbor.consider_superconductivity()
	radiate_to_spess()
	finish_superconduction()

/turf/proc/finish_superconduction(temp = temperature)
	//Make sure still hot enough to continue conducting heat
	if(temp < MINIMUM_TEMPERATURE_FOR_SUPERCONDUCTION)
		SSair.active_super_conductivity -= src
		return FALSE

/turf/open/finish_superconduction()
	//Conduct with air on my tile if I have it
	if(!blocks_air && air)
		temperature = air.temperature_share(null, thermal_conductivity, temperature, heat_capacity)
	// Пустая смесь не остывает (теплоёмкость 0), поэтому выход читается по температуре самого турфа.
	if(blocks_air || !air || !length(air.gases))
		return ..(temperature)
	return ..(air.return_temperature())

/turf/proc/consider_superconductivity()
	if(!SSair.heat_enabled)
		return FALSE
	if(!thermal_conductivity)
		return FALSE
	SSair.active_super_conductivity[src] = TRUE
	return TRUE

/turf/open/consider_superconductivity(starting)
	if(planetary_atmos) //an infinite uniform sky has nothing to conduct anywhere
		return FALSE
	if(!air)
		return FALSE
	if(air.return_temperature() < (starting ? MINIMUM_TEMPERATURE_START_SUPERCONDUCTION : MINIMUM_TEMPERATURE_FOR_SUPERCONDUCTION))
		return FALSE
	if(air.heat_capacity() < M_CELL_WITH_RATIO)
		return FALSE
	return ..()

/turf/closed/consider_superconductivity(starting)
	if(temperature < (starting ? MINIMUM_TEMPERATURE_START_SUPERCONDUCTION : MINIMUM_TEMPERATURE_FOR_SUPERCONDUCTION))
		return FALSE
	return ..()

/turf/proc/radiate_to_spess() //Radiate excess tile heat to space
	if(temperature <= T0C) //Considering 0 degC as the break even point for radiation in and out
		return
	var/delta_temperature = temperature_archived - TCMB //hardcoded space temperature
	if(heat_capacity <= 0 || abs(delta_temperature) <= MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		return
	var/heat = thermal_conductivity * delta_temperature * (heat_capacity * HEAT_CAPACITY_VACUUM / (heat_capacity + HEAT_CAPACITY_VACUUM))
	temperature -= heat / heat_capacity
	temperature = max(temperature, T0C) //otherwise we just sorta get stuck at super cold temps forever

/turf/open/proc/temperature_share_open_to_solid(turf/sharer)
	sharer.temperature = air.temperature_share(null, sharer.thermal_conductivity, sharer.temperature, sharer.heat_capacity)

/turf/proc/share_temperature_mutual_solid(turf/sharer, conduction_coefficient) //to be understood
	var/delta_temperature = temperature_archived - sharer.temperature_archived
	if(abs(delta_temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER && heat_capacity && sharer.heat_capacity)
		var/heat = conduction_coefficient * delta_temperature * (heat_capacity * sharer.heat_capacity / (heat_capacity + sharer.heat_capacity))
		temperature -= heat / heat_capacity
		sharer.temperature += heat / sharer.heat_capacity
		// Пол TCMB, а не T0C: страховка от перелёта через равновесие, которая не греет холодные стены.
		temperature = max(temperature, TCMB)
		sharer.temperature = max(sharer.temperature, TCMB)


/// Тик живого очага для группы, из /obj/effect/hotspot/process(). breakdown_cooldown не трогается: иначе потолок EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING недостижим.
/turf/open/proc/eg_hotspot_tick()
	var/datum/excited_group/group = excited_group
	if(group)
		// Начатый до поджога брейкдаун дописал бы усреднённый газ поверх огня.
		group.cancel_breakdown()
		group.turf_reactions |= VOLATILE_REACTION
		group.dismantle_cooldown = 0
	atmos_cooldown = 0

/////////////////////////GAS OVERLAYS//////////////////////////////


/turf/open/proc/update_visuals()
	// Оверлей зависит только от состава смеси, поэтому mutation_rev - точный ключ мемо.
	var/datum/gas_mixture/our_air = air
	if(our_air && atmos_visual_rev == our_air.mutation_rev)
		ATMOS_TPROF_COUNT("vis_memo")
		return

	var/list/atmos_overlay_types = src.atmos_overlay_types // Cache for free performance
	var/static/list/nonoverlaying_gases = typecache_of_gases_with_no_overlays()

	// Ключ мемо ставится на каждом выходе и только после работы: рантайм посередине не должен оставить штамп.
	var/memo_rev = our_air?.mutation_rev

	if(!air) // 2019-05-14: was not able to get this path to fire in testing. Consider removing/looking at callers -Naksu
		if (atmos_overlay_types)
			for(var/overlay in atmos_overlay_types)
				vis_contents -= overlay
			src.atmos_overlay_types = null
		atmos_visual_rev = memo_rev
		return

	var/list/cached_gases = air.gases
	// O2 and N2 have no overlay: skip the visibility scan for clean air once no old overlay needs removal.
	if(!atmos_overlay_types && length(cached_gases) == 2 && cached_gases[GAS_O2] && cached_gases[GAS_N2])
		ATMOS_TPROF_COUNT("vis_clean_air")
		atmos_visual_rev = memo_rev
		return
	var/list/gas_overlays = GLOB.gas_data.overlays
	var/list/gas_visibility = GLOB.gas_data.visibility
	// Один оверлей на турф - от доминирующего газа: смешение цветов стёрло бы газы без color (плазма, тритий, пар, N2O).
	var/visible_moles = 0
	var/list/dominant_overlays
	var/dominant_score = 0
	for(var/gas_id, moles in cached_gases)
		if (nonoverlaying_gases[gas_id])
			continue
		var/list/gas_overlay = gas_overlays[gas_id]
		if(!gas_overlay)
			continue
		var/threshold = gas_visibility[gas_id]
		if(moles <= threshold)
			continue
		visible_moles += moles
		// Ranked by how far past its own visibility threshold the gas is: a whiff of miasma must not outrank a plasma cloud.
		var/score = moles / threshold
		if(score > dominant_score)
			dominant_score = score
			dominant_overlays = gas_overlay

	var/new_overlay
	if(dominant_overlays)
		new_overlay = dominant_overlays[min(FACTOR_GAS_VISIBLE_MAX, CEILING(visible_moles / MOLES_GAS_VISIBLE_STEP, 1))]

	if(isnull(new_overlay) && !atmos_overlay_types)
		ATMOS_TPROF_COUNT("vis_no_overlay")
		atmos_visual_rev = memo_rev
		return
	if(!isnull(new_overlay) && length(atmos_overlay_types) == 1 && atmos_overlay_types[1] == new_overlay)
		ATMOS_TPROF_COUNT("vis_unchanged")
		atmos_visual_rev = memo_rev
		return
	var/list/new_overlay_types = isnull(new_overlay) ? list() : list(new_overlay)
	ATMOS_TPROF_COUNT("vis_commits")

	if (atmos_overlay_types)
		for(var/overlay in atmos_overlay_types-new_overlay_types) //doesn't remove overlays that would only be added
			vis_contents -= overlay

	if (length(new_overlay_types))
		if (atmos_overlay_types)
			vis_contents += new_overlay_types - atmos_overlay_types //don't add overlays that already exist
		else
			vis_contents += new_overlay_types

	UNSETEMPTY(new_overlay_types)
	src.atmos_overlay_types = new_overlay_types
	atmos_visual_rev = memo_rev

/turf/open/proc/set_visuals(list/new_overlay_types)
	if (atmos_overlay_types)
		for(var/overlay in atmos_overlay_types-new_overlay_types) //doesn't remove overlays that would only be added
			vis_contents -= overlay

	if (length(new_overlay_types))
		if (atmos_overlay_types)
			vis_contents += new_overlay_types - atmos_overlay_types //don't add overlays that already exist
		else
			vis_contents += new_overlay_types
	UNSETEMPTY(new_overlay_types)
	src.atmos_overlay_types = new_overlay_types
	// Оверлей выставлен в обход update_visuals(): ключ мемо больше не описывает турф.
	atmos_visual_rev = -1

/proc/typecache_of_gases_with_no_overlays()
	. = list()
	for (var/gastype in subtypesof(/datum/gas))
		var/datum/gas/gasvar = gastype
		if (!initial(gasvar.gas_overlay))
			.[initial(gasvar.id)] = TRUE

/////////////////////////////SIMULATION///////////////////////////////////

// Значимый шер будит и отдыхающего соседа: члены группы получают газ пассивно и должны вернуться в актив, чтобы делиться дальше.
#define LAST_SHARE_CHECK \
	var/last_share = our_air.last_share; \
	ATMOS_TPROF_WAKE_RATIO(last_share, our_move_threshold) \
	if(last_share > our_suspend_threshold){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			ATMOS_BENCH_WAKE(enemy_tile, "pair_share") \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	} else if(last_share > our_move_threshold) { \
		our_excited_group.dismantle_cooldown = 0; \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			ATMOS_BENCH_WAKE(enemy_tile, "pair_share") \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	}

// Same cooldown handling for the template share; there is no enemy tile here.
#define PLANET_SHARE_CHECK \
	var/planet_last_share = our_air.last_share; \
	ATMOS_TPROF_WAKE_RATIO(planet_last_share, our_move_threshold) \
	if(planet_last_share > our_suspend_threshold){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
	} else if(planet_last_share > our_move_threshold) { \
		our_excited_group.dismantle_cooldown = 0; \
		cached_atmos_cooldown = 0; \
	}

/turf/proc/process_cell(fire_count)
	if(SSair)
		SSair.remove_from_active(src)
// Стадии обхода зоны. Сбор и активация газ не двигают и рвутся между фаерами; MIX (кромка и усреднение) идёт одним куском, иначе моли зоны не сойдутся.
#define EQ_WALK_COLLECT 1
#define EQ_WALK_MIX 2
#define EQ_WALK_ACTIVATE 3
#define EQ_WALK_RIP 4

/// Обход зоны эквалайзером, растянутый на несколько фаеров SSair. Состояние живёт в датуме, а не в SSair.currentrun: тот слот общий для всех фаз подсистемы.
/datum/atmos_zone_walk
	/// Текущая стадия, 0 - обхода в полёте нет.
	var/stage = 0
	/// Номер фаера, которым обход штампует захваченные турфы (гард "одна зона на турф за фаер").
	var/cyclenum = 0
	/// Связное множество зоны, в порядке обхода.
	var/list/turf/open/zone_turfs = list()
	/// Ассоциативно (для проверки за O(1)): члены зоны, граничащие с космосом.
	var/list/turf/open/space_edge_turfs = list()
	/// Стек BFS.
	var/list/turf/open/pending = list()
	/// Ассоциативно: турфы, уже попавшие в стек.
	var/list/seen = list()
	/// Снимок молей и температуры членов ДО усреднения, по индексу zone_turfs.
	var/list/moles_before = list()
	var/list/temperature_before = list()
	/// Курсор внутри текущей стадии.
	var/cursor = 1
	var/pressure_high = 0
	var/pressure_low = 0
	/// Суммарное падение давления на кромке: вход handle_decompression_floor_rip.
	var/total_pressure_drop = 0
	/// Давление турфа-затравки, для счётчиков high/low_pressure_turfs.
	var/seed_pressure = 0
	/// Обход прошёл гейт по разбросу давления, то есть реально двигал газ.
	var/did_work = FALSE

/// Полная очистка перед новым обходом.
/datum/atmos_zone_walk/proc/reset()
	stage = 0
	cyclenum = 0
	cursor = 1
	pressure_high = 0
	pressure_low = 0
	total_pressure_drop = 0
	seed_pressure = 0
	did_work = FALSE
	zone_turfs.Cut()
	space_edge_turfs.Cut()
	pending.Cut()
	seen.Cut()
	moles_before.Cut()
	temperature_before.Cut()

/// Заводит обход от турфа-затравки. FALSE - затравка не годится (не открытый турф, без смеси, небо или зону уже обошли в этом фаере).
/datum/atmos_zone_walk/proc/begin(turf/open/seed, walk_cycle)
	// Проверки до reset(): почти все кандидаты большой зоны уже помечены её обходом, отказ должен быть дешевле шести Cut().
	if(!istype(seed) || seed.blocks_air || !seed.air)
		return FALSE
	// Небо не эквализится: шаблон сотрёт сдвинутый газ, и обход находил бы ту же дельту каждый фаер.
	if(seed.planetary_atmos)
		return FALSE
	if(seed.equalize_cycle >= walk_cycle)
		return FALSE
	reset()
	cyclenum = walk_cycle
	seed_pressure = seed.air.return_pressure()
	pressure_high = seed_pressure
	pressure_low = seed_pressure
	pending += seed
	seen[seed] = TRUE
	stage = EQ_WALK_COLLECT
	return TRUE

/// Завершение обхода. Члены перештамповываются фаером завершения: со штампом фаера захвата следующий фаер завёл бы повторный обход и стравил кромку дважды.
/datum/atmos_zone_walk/proc/finish()
	if(SSair && SSair.times_fired > cyclenum)
		var/finish_cycle = SSair.times_fired
		for(var/turf/open/member as anything in zone_turfs)
			if(istype(member))
				member.equalize_cycle = finish_cycle
	stage = 0
	cursor = 1
	// did_work переживает finish(): его читает equalize_pressure_in_zone().
	zone_turfs.Cut()
	space_edge_turfs.Cut()
	pending.Cut()
	seen.Cut()
	moles_before.Cut()
	temperature_before.Cut()

/// Один срез обхода. `slice_budget` - сколько членов зоны разрешено тронуть, 0 - без ограничения. TRUE, когда обход завершён.
/datum/atmos_zone_walk/proc/advance(slice_budget = 0)
	if(!stage)
		return TRUE
	var/remaining = slice_budget > 0 ? max(1, slice_budget) : INFINITY
	var/hard_limit = SSair ? SSair.equalize_hard_turf_limit : 2000
	while(stage)
		switch(stage)
			if(EQ_WALK_COLLECT)
				while(pending.len && zone_turfs.len < hard_limit && remaining > 0)
					var/turf/open/current_turf = pending[pending.len]
					pending.len--
					remaining--
					if(!istype(current_turf) || current_turf.blocks_air || !current_turf.air)
						continue
					if(current_turf.equalize_cycle >= cyclenum)
						continue

					current_turf.equalize_cycle = cyclenum
					zone_turfs += current_turf

					// Давление на месте, без двух вызовов return_pressure()/total_moles() на каждый член.
					var/datum/gas_mixture/current_air = current_turf.air
					var/current_volume = current_air.volume
					var/current_pressure = 0
					if(current_volume > 0)
						var/current_moles = 0
						var/list/current_gases = current_air.gases
						for(var/gas_id in current_gases)
							current_moles += current_gases[gas_id]
						current_pressure = current_moles * R_IDEAL_GAS_EQUATION * current_air.temperature / current_volume
					if(current_pressure > pressure_high)
						pressure_high = current_pressure
					if(current_pressure < pressure_low)
						pressure_low = current_pressure

					for(var/turf/neighbor as anything in current_turf.atmos_adjacent_turfs)
						if(istype(neighbor, /turf/open/space))
							space_edge_turfs[current_turf] = TRUE
							continue
						var/turf/open/open_neighbor = neighbor
						if(!istype(open_neighbor) || open_neighbor.blocks_air || !open_neighbor.air)
							continue
						// Граница с небом - стена для обхода (см. begin()), её обслуживает sky-ветка process_cell.
						if(open_neighbor.planetary_atmos)
							continue
						if(seen[open_neighbor])
							continue
						seen[open_neighbor] = TRUE
						pending += open_neighbor
				if(pending.len && zone_turfs.len < hard_limit)
					return FALSE
				if(!zone_turfs.len)
					finish()
					return TRUE
				if((pressure_high - pressure_low) < EQUALIZE_MIN_PRESSURE_DELTA && !space_edge_turfs.len)
					finish()
					return TRUE
				did_work = TRUE
				if(SSair)
					SSair.num_equalize_processed++
					if(seed_pressure >= ONE_ATMOSPHERE)
						SSair.high_pressure_turfs++
					else
						SSair.low_pressure_turfs++
				cursor = 1
				stage = EQ_WALK_MIX
				if(remaining <= 0)
					return FALSE

			if(EQ_WALK_MIX)
				// Единственная неделимая стадия (см. EQ_WALK_*), фаза заходит сюда только с запасом тика.
				vent_space_edges()
				mix_zone()
				remaining -= zone_turfs.len
				cursor = 1
				stage = EQ_WALK_ACTIVATE
				if(remaining <= 0)
					return FALSE

			if(EQ_WALK_ACTIVATE)
				// Будим только сдвинутых: после сведения члены зоны одинаковы, и будить всю зону значило бы держать её активной без работы.
				var/snapshot_taken = moles_before.len
				while(cursor <= zone_turfs.len && remaining > 0)
					var/index = cursor
					cursor++
					remaining--
					var/turf/open/group_turf = zone_turfs[index]
					if(!istype(group_turf) || group_turf.blocks_air || !group_turf.air)
						continue
					// Перерисовка всем: сведение меняет состав и при равной сумме молей. Фильтр ниже гейтит только пробуждение.
					group_turf.update_visuals()
					// Кромка космоса всегда сдвинута: она стравила свою долю в вакуум.
					if(snapshot_taken && !space_edge_turfs[group_turf])
						var/datum/gas_mixture/group_air = group_turf.air
						var/old_moles = moles_before[index]
						if(isnull(old_moles))
							continue
						var/new_moles = 0
						var/list/group_gases = group_air.gases
						for(var/gas_id in group_gases)
							new_moles += group_gases[gas_id]
						var/moles_delta = abs(new_moles - old_moles)
						// Пороги gas_mixture.compare(): вердикт обязан совпадать с LINDA.
						if(moles_delta <= MINIMUM_MOLES_DELTA_TO_MOVE || moles_delta <= old_moles * MINIMUM_AIR_RATIO_TO_MOVE)
							if(abs(group_air.temperature - temperature_before[index]) <= MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
								continue
					if(SSair)
						ATMOS_BENCH_WAKE(group_turf, "equalize")
						SSair.add_to_active(group_turf, FALSE)
				if(cursor <= zone_turfs.len)
					return FALSE
				cursor = 1
				stage = EQ_WALK_RIP
				if(remaining <= 0)
					return FALSE

			if(EQ_WALK_RIP)
				if(total_pressure_drop > 0)
					while(cursor <= space_edge_turfs.len && remaining > 0)
						var/turf/open/edge_turf = space_edge_turfs[cursor]
						cursor++
						remaining--
						if(istype(edge_turf))
							edge_turf.handle_decompression_floor_rip(total_pressure_drop)
					if(cursor <= space_edge_turfs.len)
						return FALSE
				finish()
				return TRUE

			else
				finish()
				return TRUE

/// Стравливание кромки зоны в вакуум: файрлоки на каждой стороне к космосу, доля газа за борт, теплообмен с вакуумом и вклад в ветер.
/datum/atmos_zone_walk/proc/vent_space_edges()
	total_pressure_drop = 0
	for(var/turf/open/edge_turf as anything in space_edge_turfs)
		// Сбор растянут на несколько фаеров: член зоны мог смениться (ChangeTurf) или потерять смесь.
		if(!istype(edge_turf) || edge_turf.blocks_air || !edge_turf.air)
			continue
		var/space_sides = 0
		var/turf/open/space/first_space
		for(var/turf/neighbor as anything in edge_turf.atmos_adjacent_turfs)
			if(!istype(neighbor, /turf/open/space))
				continue
			var/turf/open/space/space_neighbor = neighbor
			space_sides++
			if(!first_space)
				first_space = space_neighbor
			edge_turf.consider_firelocks(space_neighbor)
		if(!space_sides)
			continue

		var/starting_pressure = edge_turf.air.return_pressure()
		var/ratio = min(1, 0.25 * space_sides)
		edge_turf.air.vent_ratio(ratio)
		edge_turf.air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, TCMB, HEAT_CAPACITY_VACUUM)

		var/pressure_drop = max(0, starting_pressure - edge_turf.air.return_pressure())
		total_pressure_drop += pressure_drop
		if(pressure_drop > 0 && first_space)
			edge_turf.consider_pressure_difference(first_space, pressure_drop)

/// Сведение газа зоны к среднему и снимок молей/температуры для фильтра активации. Специализация equalize_all_gases_in_list() без промежуточных списков.
/datum/atmos_zone_walk/proc/mix_zone()
	var/list/turf/open/members = zone_turfs
	var/member_count = members.len
	// Пустой снимок: стадия активации будит единственного члена безусловно.
	if(member_count <= 1)
		return
	moles_before.len = member_count
	temperature_before.len = member_count
	var/list/total_gases = list()
	var/total_volume = 0
	var/total_heat_capacity = 0
	var/total_thermal_energy = 0
	var/list/specific_heats = GLOB.gas_data.specific_heats
	var/participants = 0
	for(var/index in 1 to member_count)
		var/turf/open/member = members[index]
		if(!istype(member) || member.blocks_air)
			continue
		var/datum/gas_mixture/member_air = member.air
		if(!member_air || member_air.gc_share)
			continue
		participants++
		total_volume += max(member_air.volume, 0)
		var/member_heat_capacity = 0
		var/member_moles = 0
		var/list/member_gases = member_air.gases
		for(var/gas_id, moles in member_gases)
			member_moles += moles
			total_gases[gas_id] = (total_gases[gas_id] || 0) + moles
			member_heat_capacity += moles * (specific_heats[gas_id] || 0)
		member_heat_capacity = max(member_heat_capacity, member_air.min_heat_capacity)
		total_heat_capacity += member_heat_capacity
		total_thermal_energy += member_air.temperature * member_heat_capacity
		moles_before[index] = member_moles
		temperature_before[index] = member_air.temperature
	if(!participants || total_volume <= 0)
		return
	// Полная энергия на полную теплоёмкость; TCMB - то, что дала бы пустая смесь.
	var/target_temperature = TCMB
	if(total_heat_capacity > 0)
		target_temperature = max(total_thermal_energy / total_heat_capacity, TCMB)
	var/inv_total_volume = 1 / total_volume
	for(var/index in 1 to member_count)
		var/turf/open/member = members[index]
		if(!istype(member) || member.blocks_air)
			continue
		var/datum/gas_mixture/member_air = member.air
		if(!member_air || member_air.gc_share)
			continue
		var/volume_ratio = max(member_air.volume, 0) * inv_total_volume
		var/list/member_gases = member_air.gases
		member_gases.Cut()
		for(var/gas_id, total_moles in total_gases)
			var/moles = total_moles * volume_ratio
			if(moles > 0)
				member_gases[gas_id] = moles
		member_air.temperature = target_temperature
		member_air.mutation_rev++

/// Атомарный прогон обхода зоны целиком, для тестов и внешних вызовов. Фаза SSair ходит по стадиям сама (process_turf_equalize_auxtools).
/turf/open/proc/equalize_pressure_in_zone(cyclenum)
	if(!SSair)
		return FALSE
	// Подвешенный обход фазы доедаем до собственного: иначе кромка зоны стравится дважды, а его MIX затрёт членов устаревшим средним.
	var/datum/atmos_zone_walk/in_flight = SSair.zone_walk
	if(in_flight?.stage)
		in_flight.advance(0)
	var/datum/atmos_zone_walk/walk = new
	if(!walk.begin(src, cyclenum))
		return FALSE
	walk.advance(0)
	return walk.did_work

/turf/proc/consider_firelocks(turf/T2)

/// Только мгновенный захлоп створок по перепаду. Тревогу ареала поднимает SSair.queue_decompression_area() на подтверждённой разгерметизации.
/turf/open/consider_firelocks(turf/T2)
	if(blocks_air)
		return
	for(var/obj/machinery/door/firedoor/FD in src)
		FD.emergency_pressure_stop()
	for(var/obj/machinery/door/firedoor/FD in T2)
		FD.emergency_pressure_stop()

/turf/proc/handle_decompression_floor_rip()

/turf/open/floor/handle_decompression_floor_rip(sum)
	if(!blocks_air && sum > 20 && prob(clamp(sum / 10, 0, 30)))
		remove_tile()

/// Космос не симулируется: его смесь - общий неизменяемый вакуум, соседи стравливаются в него сами.
/turf/open/space/process_cell(fire_count)
	if(SSair)
		SSair.remove_from_active(src)
	return

/turf/open/process_cell(fire_count)
	var/datum/controller/subsystem/air/air_controller = SSair
	var/datum/gas_mixture/our_air = air
	if(blocks_air || !our_air)
		if(air_controller)
			air_controller.remove_from_active(src)
		return

	ATMOS_TPROF_VARS
	ATMOS_TPROF_COUNT("turfs")

	ATMOS_TPROF_MARK
	if(archived_cycle < fire_count)
		ARCHIVE_OPEN_TURF(src, our_air, fire_count)
	ATMOS_TPROF_ADD("archive")

	current_cycle = fire_count

	var/list/adjacent_turfs = atmos_adjacent_turfs
	if(!LAZYLEN(adjacent_turfs))
		// Соседство могло протухнуть (препятствие ушло без air update): без пересчёта турф копит газ вечно.
		CALCULATE_ADJACENT_TURFS(src)
	var/datum/excited_group/our_excited_group = excited_group
	var/adjacent_turfs_length = max(1, LAZYLEN(adjacent_turfs))
	var/our_share_coeff = 1 / (adjacent_turfs_length + 1)
	var/cached_atmos_cooldown = atmos_cooldown + 1
	// Кэш спящих рёбер работает только у турфа, который уже несколько фаеров ничего не двигал.
	var/edge_sleep_enabled = air_controller?.sleeping_edges_enabled && cached_atmos_cooldown > air_controller.edge_sleep_min_quiet_fires

	var/planet_atmos = planetary_atmos

	// Пороги в молях откалиброваны на стандартную клетку, на баллонных тайлах они масштабируются по содержимому (1%, чтобы не гасить реальный поток).
	var/our_cycle_moles = our_air.total_moles()
	var/our_suspend_threshold = max(MINIMUM_AIR_TO_SUSPEND, our_cycle_moles * SIGNIFICANT_SHARE_CONTENT_RATIO)
	var/our_move_threshold = max(MINIMUM_MOLES_DELTA_TO_MOVE, our_cycle_moles * MINIMUM_AIR_RATIO_TO_MOVE)
	var/turf/open/space_neighbor

	ATMOS_TPROF_MARK
	for(var/turf/open/enemy_tile as anything in adjacent_turfs)
		ATMOS_TPROF_DEEP_COUNT("nb_pairs")
		if(!istype(enemy_tile) || enemy_tile.blocks_air)
			continue
		// Пару обрабатывает тот, кто пришёл первым. Космос и спящее небо не обрабатываются, их current_cycle протухший.
		if(fire_count <= enemy_tile.current_cycle)
			continue
		var/datum/gas_mixture/enemy_air = enemy_tile.air
		if(!enemy_air)
			continue

		// Космос - единственная смесь с gc_share. Сброс в него идёт после цикла пар, по живым значениям.
		if(enemy_air.gc_share)
			ATMOS_TPROF_COUNT("space_pairs")
			// Небо с космосом не меняется: шаблон восполняет унесённое, и пара качала бы газ вечно.
			if(!planet_atmos)
				space_neighbor = enemy_tile
			continue

		// Два разных неба не обмениваются: оба прибиты к своим шаблонам, градиент между ними вечный.
		var/enemy_planet_atmos = enemy_tile.planetary_atmos
		if(planet_atmos && enemy_planet_atmos && enemy_tile.initial_gas_mix != initial_gas_mix)
			continue

		// Спящее небо - бесконечный резервуар своего шаблона: меняемся с шаблоном, не будя турф.
		if(enemy_planet_atmos && !enemy_tile.excited && air_controller)
			var/datum/gas_mixture/sky_template = air_controller.get_planetary_template(enemy_tile)
			if(sky_template)
				ATMOS_TPROF_COUNT("sky_pairs")
				ATMOS_TPROF_DEEP_MARK
				var/sky_differs = our_air.compare(sky_template)
				ATMOS_TPROF_DEEP_ADD("nb_sky_compare")
				if(!sky_differs)
					continue
				ATMOS_TPROF_COUNT("sky_shares")
				var/sky_temperature_delta = abs(our_air.temperature_archived - sky_template.temperature_archived)
				our_air.share_with_template(sky_template, our_share_coeff)
				// Группу держит сам факт compare(), а не last_share: чисто температурный поток двигает ноль молей.
				if(!our_excited_group)
					var/datum/excited_group/sky_group = new
					sky_group.add_turf(src)
					our_excited_group = excited_group
				if(our_air.last_share > our_suspend_threshold)
					our_excited_group.reset_cooldowns()
				else
					our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
				if(our_air.last_share > our_move_threshold || sky_temperature_delta > MINIMUM_TEMPERATURE_TO_MOVE)
					var/sky_pressure_delta = our_air.return_pressure() - sky_template.return_pressure()
					if(sky_pressure_delta > 0)
						consider_pressure_difference(enemy_tile, sky_pressure_delta)
					else if(sky_pressure_delta < 0)
						enemy_tile.consider_pressure_difference(src, -sky_pressure_delta)
				continue

		var/datum/excited_group/enemy_excited_group = enemy_tile.excited_group
		if(edge_sleep_enabled && our_excited_group && our_excited_group == enemy_excited_group)
			var/list/edge_state_early = settled_edge_revs?[enemy_tile]
			if(edge_state_early && edge_state_early[1] == our_air.mutation_rev && edge_state_early[2] == enemy_air.mutation_rev)
				ATMOS_TPROF_COUNT("edge_sleeps")
				continue

		var/should_share_air = FALSE

		if(our_excited_group && enemy_excited_group)
			if(our_excited_group != enemy_excited_group)
				our_excited_group.merge_groups(enemy_excited_group)
				our_excited_group = excited_group
				ATMOS_TPROF_COUNT("group_merges")
			// Общая группа - это связность, а не градиент: пара без разницы не шерит, остаток выравнивает self_breakdown.
			ATMOS_TPROF_DEEP_MARK
			should_share_air = !!our_air.compare(enemy_air)
			ATMOS_TPROF_DEEP_ADD("nb_compare")
			ATMOS_TPROF_DEEP_COUNT("nb_compares")
			// Пока ревизии обоих концов не менялись, гейт выше пропускает пару. Протухшую запись не чистим: она просто не совпадёт.
			if(edge_sleep_enabled && !should_share_air)
				ATMOS_TPROF_COUNT("edge_writes")
				var/list/settled = settled_edge_revs
				if(!settled)
					settled = list()
					settled_edge_revs = settled
				var/list/edge_state = settled[enemy_tile]
				if(edge_state)
					edge_state[1] = our_air.mutation_rev
					edge_state[2] = enemy_air.mutation_rev
				else
					settled[enemy_tile] = list(our_air.mutation_rev, enemy_air.mutation_rev)
		else if(our_air.compare(enemy_air))
			ATMOS_TPROF_COUNT("group_creates")
			if(!enemy_tile.excited && air_controller)
				ATMOS_BENCH_WAKE(enemy_tile, "pair_new_group")
				air_controller.add_to_active(enemy_tile)
			var/datum/excited_group/EG = our_excited_group || enemy_excited_group || new
			if(!our_excited_group)
				EG.add_turf(src)
			if(!enemy_excited_group)
				EG.add_turf(enemy_tile)
			our_excited_group = excited_group
			should_share_air = TRUE

		if(should_share_air)
			ATMOS_TPROF_COUNT("shares")
			// Архив соседа снимается лениво, один раз за цикл: до шера ни compare(), ни слияние групп газ не трогают.
			ATMOS_TPROF_DEEP_MARK
			if(enemy_tile.archived_cycle < fire_count)
				ARCHIVE_OPEN_TURF(enemy_tile, enemy_air, fire_count)
			ATMOS_TPROF_DEEP_ADD("nb_archive")
			var/enemy_share_coeff = 1 / (max(1, LAZYLEN(enemy_tile.atmos_adjacent_turfs)) + 1)
			ATMOS_TPROF_DEEP_MARK
			var/difference = our_air.share(enemy_air, our_share_coeff, enemy_share_coeff)
			ATMOS_TPROF_DEEP_ADD("nb_share")
			// compare() смотрит живые значения, share() - архивные, поэтому шер может не сдвинуть ничего.
			ATMOS_TPROF_COUNT_IF(!our_air.last_share, "shares_noop")
			if(difference)
				if(difference > 0)
					consider_pressure_difference(enemy_tile, difference)
				else
					enemy_tile.consider_pressure_difference(src, -difference)
				// Опасный перепад через проём с файрлоком (бит в значении соседства) захлопывает створку сразу.
				if(abs(difference) >= DECOMPRESSION_FIRELOCK_PRESSURE_DELTA && (adjacent_turfs[enemy_tile] & ATMOS_ADJACENT_FIRELOCK))
					consider_firelocks(enemy_tile)
			LAST_SHARE_CHECK

	ATMOS_TPROF_ADD("neighbors")

	ATMOS_TPROF_MARK
	if(space_neighbor)
		// Как share_end у tg: кромка отдаёт космосу всё за фаер, по живым значениям после парных шеров.
		var/moles_before = our_air.total_moles()
		var/temperature_before = our_air.temperature
		if(moles_before > MINIMUM_MOLES_DELTA_TO_MOVE || abs(temperature_before - TCMB) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			ATMOS_TPROF_COUNT("space_vents")
			var/volume_cache = our_air.volume
			var/pressure_before = volume_cache > 0 ? (moles_before * R_IDEAL_GAS_EQUATION * temperature_before / volume_cache) : 0
			// HAZARD_LOW, а не WARNING_LOW: при затяжном сливе давление у дыры быстро уходит ниже 50 кПа, а тревога должна перевзводиться.
			if(pressure_before >= HAZARD_LOW_PRESSURE && air_controller)
				air_controller.queue_decompression_area(src)
			our_air.vent_ratio(1)
			our_air.set_temperature(TCMB)
			// Группа держит опустевшую кромку активной, пока соседи её докармливают.
			if(!our_excited_group)
				var/datum/excited_group/space_group = new
				space_group.add_turf(src)
				our_excited_group = excited_group
			our_excited_group.vented_to_space = TRUE
			if(moles_before > MINIMUM_AIR_TO_SUSPEND)
				our_excited_group.reset_cooldowns()
				cached_atmos_cooldown = 0
			else if(moles_before > MINIMUM_MOLES_DELTA_TO_MOVE)
				our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
			if(pressure_before > 0)
				consider_pressure_difference(space_neighbor, pressure_before)
	ATMOS_TPROF_ADD("space")

	ATMOS_TPROF_MARK
	if(planet_atmos && air_controller)
		var/datum/gas_mixture/template = air_controller.get_planetary_template(src)
		if(our_air.compare(template))
			ATMOS_TPROF_COUNT("planet_shares")
			if(!our_excited_group)
				var/datum/excited_group/EG = new
				EG.add_turf(src)
				our_excited_group = excited_group
			// Ре-архив: по снимку начала цикла сильная тяга плюс парные шеры увели бы турф ниже шаблона.
			our_air.archive()
			our_air.share_with_template(template, PLANET_SHARE_RATIO)
			// Как у upstream: теплообмен с раздутой теплоёмкостью шаблона, иначе температура сходится сотни циклов.
			our_air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, template.temperature_archived, template.immutable_heat_capacity * PLANET_SHARE_TEMPERATURE_CAPACITY)
			PLANET_SHARE_CHECK
	ATMOS_TPROF_ADD("planet")

	ATMOS_TPROF_MARK
	var/reaction_result = our_air.react(src)
	ATMOS_TPROF_ADD("react")
	ATMOS_TPROF_COUNT_IF(reaction_result & REACTING, "reactions")

	// Живая реакция или хотспот помечают группу, и tick_lifecycle откладывает брейкдаун/расформирование.
	if(our_excited_group)
		our_excited_group.turf_reactions |= reaction_result
		// genericfire без хотспота тоже волатилен: он пишет reaction_results["fire"], но hotspot не создаёт.
		if(active_hotspot || ((reaction_result & REACTING) && our_air.reaction_results["fire"]))
			our_excited_group.turf_reactions |= VOLATILE_REACTION

	ATMOS_TPROF_MARK
	ATMOS_TPROF_COUNT_IF(atmos_visual_rev == our_air.mutation_rev, "vis_memo")
	if(atmos_visual_rev != our_air.mutation_rev)
		update_visuals()
	ATMOS_TPROF_ADD("visuals")

	ATMOS_TPROF_MARK
	if(atmos_exposure_listeners)
		ATMOS_TPROF_COUNT("expose_signals")
		SEND_SIGNAL(src, COMSIG_TURF_EXPOSE, our_air, our_air.temperature)
	ATMOS_TPROF_ADD("expose")

	ATMOS_TPROF_MARK
	if(air_controller?.heat_enabled && our_air.temperature > MINIMUM_TEMPERATURE_START_SUPERCONDUCTION)
		ATMOS_TPROF_COUNT("superconduct_starts")
		consider_superconductivity(starting = TRUE)
	ATMOS_TPROF_ADD("superconduct")

	ATMOS_TPROF_MARK
	if(!active_hotspot && !(reaction_result & (REACTING | STOP_REACTIONS)))
		if(!our_excited_group)
			ATMOS_TPROF_COUNT("deactivations")
			if(air_controller)
				air_controller.remove_from_active(src)
		else if(air_controller && cached_atmos_cooldown > air_controller.individual_rest_cycles)
			ATMOS_TPROF_COUNT("solo_rests")
			// Отдых в одиночку: remove_from_active разобрала бы всю группу, а её усреднение продолжает покрывать турф.
			air_controller.sleep_active_turf(src)

	ATMOS_TPROF_COUNT_IF(cached_atmos_cooldown > 0, "turfs_quiet")
	ATMOS_TPROF_COUNT_IF(cached_atmos_cooldown >= 3, "turfs_quiet3")
	ATMOS_TPROF_COUNT_IF(cached_atmos_cooldown >= 6, "turfs_quiet6")
	atmos_cooldown = cached_atmos_cooldown
	ATMOS_TPROF_ADD("lifecycle")

//////////////////////////SPACEWIND/////////////////////////////

/turf/proc/consider_pressure_difference(turf/T, difference)
	return

/turf/open/consider_pressure_difference(turf/T, difference)
	if(difference <= 0)
		return
	// Флаг вместо `|=` по очереди в тысячи записей (см. high_pressure_queued).
	if(!high_pressure_queued)
		high_pressure_queued = TRUE
		SSair.high_pressure_delta += src
	var/direction = get_dir(src, T)
	if(direction & EAST)
		pressure_vector_x += difference
	else if(direction & WEST)
		pressure_vector_x -= difference
	if(direction & NORTH)
		pressure_vector_y += difference
	else if(direction & SOUTH)
		pressure_vector_y -= difference

/turf/open/proc/high_pressure_movements()
	// ChangeTurf может поставить клетку в очередь второй раз; пустой проход обходится даром.
	if(blocks_air || (!pressure_vector_x && !pressure_vector_y))
		return
	var/absolute_x = abs(pressure_vector_x)
	var/absolute_y = abs(pressure_vector_y)
	pressure_difference = sqrt(pressure_vector_x * pressure_vector_x + pressure_vector_y * pressure_vector_y)
	if(pressure_difference <= 0)
		return
	pressure_direction = NONE
	if(absolute_x >= absolute_y * 0.5)
		pressure_direction |= pressure_vector_x > 0 ? EAST : WEST
	if(absolute_y >= absolute_x * 0.5)
		pressure_direction |= pressure_vector_y > 0 ? NORTH : SOUTH
	if(length(contents))
		var/multiplier = 1
		if(locate(/obj/structure/rack) in src)
			multiplier *= 0.1
		else if(locate(/obj/structure/table) in src)
			multiplier *= 0.2
		var/push_force = pressure_difference * multiplier
		var/air_cycle = SSair.times_fired
		// Копия: experience_pressure_difference() может спать (throw_at/step) и менять contents.
		// Бюджет на турф и TICK_CHECK: шаг в соседнюю кучу зовёт Crossed на каждом её предмете, остаток дожуют следующие проходы.
		var/budget = HIGH_PRESSURE_MOVES_PER_TURF
		for(var/atom/movable/M as anything in contents.Copy())
			if(!M.anchored && !M.pulledby && M.last_high_pressure_movement_air_cycle < air_cycle && (M.flags_1 & INITIALIZED_1) && !QDELETED(M))
				M.experience_pressure_difference(push_force, pressure_direction, 0, pressure_specific_target)
				budget--
				if(budget <= 0 || TICK_CHECK)
					break

	if(pressure_difference > 100 && world.time >= next_space_wind_at)
		next_space_wind_at = world.time + SPACE_WIND_VISUAL_COOLDOWN
		var/wind_alpha = clamp(round(sqrt(pressure_difference) * 2), 10, 255)
		if(QDELETED(space_wind_visual))
			space_wind_visual = new(src, pressure_direction, wind_alpha)
		else
			space_wind_visual.gust(pressure_direction, wind_alpha)

/atom/movable/var/pressure_resistance = 10
/atom/movable/var/last_high_pressure_movement_air_cycle = 0

/atom/movable/proc/experience_pressure_difference(pressure_difference, direction, pressure_resistance_prob_delta = 0, throw_target)
	var/const/PROBABILITY_OFFSET = 40
	var/const/PROBABILITY_BASE_PRECENT = 10
	var/max_force = sqrt(pressure_difference)*(MOVE_FORCE_DEFAULT / 5)
	set waitfor = 0
	var/move_prob = 100
	if (pressure_resistance > 0)
		move_prob = (pressure_difference/pressure_resistance*PROBABILITY_BASE_PRECENT)-PROBABILITY_OFFSET
	move_prob += pressure_resistance_prob_delta
	if (move_prob > PROBABILITY_OFFSET && prob(move_prob) && (move_resist != INFINITY) && (!anchored && (max_force >= (move_resist * MOVE_FORCE_PUSH_RATIO))) || (anchored && (max_force >= (move_resist * MOVE_FORCE_FORCEPUSH_RATIO))))
		var/move_force = max_force * clamp(move_prob, 0, 100) / 100
		if(ismob(src))
			var/mob/M = src
			if(M.mob_negates_gravity())
				move_force = 0
		if(move_force > 6000)
			// WALLSLAM HELL TIME OH BOY
			var/turf/throw_turf = get_ranged_target_turf(get_turf(src), direction, round(move_force / 2000))
			if(throw_target && (get_dir(src, throw_target) & direction))
				throw_turf = get_turf(throw_target)
			var/throw_speed = clamp(round(move_force / 3000), 1, 10)
			throw_at(throw_turf, move_force / 3000, throw_speed, quickstart = FALSE)
		else if(move_force > 0)
			step(src, direction)
		last_high_pressure_movement_air_cycle = SSair.times_fired

///////////////////////////EXCITED GROUPS/////////////////////////////

#define EG_BREAKDOWN_COLLECT 1
#define EG_BREAKDOWN_AVERAGE 2
#define EG_BREAKDOWN_WRITE 3
#define EG_BREAKDOWN_SPACE_WRITE 4
#define EG_BREAKDOWN_EVICT 5
#define EG_BREAKDOWN_POKE_COLLECT 6
#define EG_BREAKDOWN_POKE 7

/datum/excited_group
	var/list/turf_list = list()
	var/breakdown_cooldown = 0
	var/dismantle_cooldown = 0
	/// Reaction flags OR-ed in by members during process_cell this air pass;
	/// consumed and reset by tick_lifecycle (tg turf_reactions port).
	var/turf_reactions = NO_REACTION
	/// Members currently excited. Maintained incrementally on every excited-flag
	/// transition and recounted exactly by self_breakdown, so the dismantle
	/// decision does not scan the whole turf_list every group-stage tick.
	var/awake_members = 0
	/// Хотя бы один член стравливался в космос: snap_vented_wisp() остужает подпороговые остатки таких групп. Не снимается до смерти датума.
	var/vented_to_space = FALSE
	/// Persistent resumable breakdown state. No turf air is written until the
	/// collection and average phases have completed for the membership snapshot.
	var/breakdown_stage = 0
	var/list/turf/open/breakdown_members
	var/breakdown_cursor = 1
	var/list/breakdown_bucket_mixes
	var/list/breakdown_bucket_counts
	var/list/breakdown_bucket_keys
	var/list/turf/open/breakdown_retained_members
	var/list/turf/open/breakdown_to_evict
	var/list/turf/open/breakdown_to_poke
	var/breakdown_awake_recount = 0
	var/breakdown_space_in_group = FALSE
	var/breakdown_space_is_all_consuming = FALSE
	var/breakdown_poke_resting = FALSE
	var/datum/gas_mixture/breakdown_space_mix
	#ifdef ATMOS_HEADLESS_BENCH
	var/headless_breakdown_started = 0
	var/headless_breakdown_slices = 0
	var/headless_breakdown_members = 0
	#endif

/datum/excited_group/New()
	if(SSair)
		SSair.excited_groups += src

/datum/excited_group/proc/add_turf(turf/open/T)
	if(!istype(T))
		return
	// Отмена брейкдауна первой: посреди выселения она убирает отвязанных из turf_list, после чего членство в нём равно обратной ссылке.
	reset_cooldowns()
	if(T.excited_group != src || !T.excited)
		awake_members++
	if(T.excited_group != src)
		turf_list += T
		T.excited_group = src
	// excited - флаг членства в active_turfs, на нём стоит быстрый путь add_to_active(): поднятый флаг обязан значить запись в списке.
	if(!T.excited)
		T.excited = TRUE
		if(SSair)
			SSair.list_active_turf(T)

/datum/excited_group/proc/merge_groups(datum/excited_group/E)
	if(!E || E == src)
		return
	cancel_breakdown()
	E.cancel_breakdown()
	// The loser keeps no state: its awake count moves to the winner, and its
	// turf_list empties so the dropped datum neither pins turf references nor
	// misjudges a lifecycle tick should anything still hold it.
	if(turf_list.len >= E.turf_list.len)
		if(SSair)
			SSair.excited_groups -= E
		for(var/turf/open/T as anything in E.turf_list)
			T.excited_group = src
		// Groups are disjoint by construction (every unhook also delists), so the lists are joined without a |= scan.
		turf_list += E.turf_list
		awake_members += E.awake_members
		E.awake_members = 0
		turf_reactions |= E.turf_reactions // a burning group keeps its volatile gate through merges
		vented_to_space |= E.vented_to_space // зона с выходом в космос остаётся такой и после слияния
		E.turf_list.Cut()
		reset_cooldowns()
	else
		if(SSair)
			SSair.excited_groups -= src
		for(var/turf/open/T as anything in turf_list)
			T.excited_group = E
		E.turf_list += turf_list
		E.awake_members += awake_members
		awake_members = 0
		turf_list.Cut()
		E.turf_reactions |= turf_reactions // a burning group keeps its volatile gate through merges
		E.vented_to_space |= vented_to_space // зона с выходом в космос остаётся такой и после слияния
		E.reset_cooldowns()

/datum/excited_group/proc/reset_cooldowns()
	cancel_breakdown()
	breakdown_cooldown = 0
	dismantle_cooldown = 0

/// Drops an in-flight accumulator without changing lifecycle cooldowns. External
/// gas writes use this to make the next slice restart from current air instead
/// of overwriting the write with a stale average.
/datum/excited_group/proc/cancel_breakdown()
	// Ноль стадии значит "нечего сбрасывать": сюда через reset_cooldowns() идёт каждый значимый шер.
	if(!breakdown_stage)
		return
	// Посреди выселения turf_list ещё держит выселенных, а вступившие за это время не попали ни в одну половину разбиения: истину держит обратная ссылка excited_group.
	if(breakdown_stage == EG_BREAKDOWN_EVICT && breakdown_retained_members)
		var/list/turf/open/still_ours = list()
		for(var/turf/open/T as anything in turf_list)
			if(istype(T) && T.excited_group == src)
				still_ours += T
		turf_list = still_ours
	drop_breakdown_state(FALSE)

/datum/excited_group/proc/finish_breakdown()
	drop_breakdown_state(TRUE)
	breakdown_cooldown = 0

/// Поля аккумулятора пишутся в self_breakdown() одним блоком вместе с breakdown_stage и снимаются только здесь.
/datum/excited_group/proc/drop_breakdown_state(completed)
	#ifdef ATMOS_HEADLESS_BENCH
	if(breakdown_stage && SSair)
		SSair.atmos_headless_bench_record_breakdown(headless_breakdown_members, world.time - headless_breakdown_started, headless_breakdown_slices, completed)
	#endif
	if(breakdown_bucket_mixes)
		for(var/bucket_key in breakdown_bucket_mixes)
			qdel(breakdown_bucket_mixes[bucket_key])
	if(breakdown_space_mix)
		qdel(breakdown_space_mix)
	breakdown_stage = 0
	breakdown_members = null
	breakdown_cursor = 1
	breakdown_bucket_mixes = null
	breakdown_bucket_counts = null
	breakdown_bucket_keys = null
	breakdown_retained_members = null
	breakdown_to_evict = null
	breakdown_to_poke = null
	breakdown_awake_recount = 0
	breakdown_space_in_group = FALSE
	breakdown_space_is_all_consuming = FALSE
	breakdown_poke_resting = FALSE
	breakdown_space_mix = null

/// One SSair group-stage step: advance both cooldowns and run whichever
/// lifecycle event is due. Kept as a proc so tests can drive the exact
/// stage behavior.
/datum/excited_group/proc/tick_lifecycle()
	if(breakdown_stage)
		// Волатильный гейт ниже проверяется только на старте: пожар, вспыхнувший посреди возобновляемого брейкдауна, отменяет его.
		if(turf_reactions & VOLATILE_REACTION)
			turf_reactions = NO_REACTION
			cancel_breakdown()
			return TRUE
		turf_reactions = NO_REACTION
		return self_breakdown(slice_budget = EXCITED_GROUP_BREAKDOWN_SLICE)
	// Без бодрых членов группа новых дельт не даст. Счётчик инкрементальный, дрейф чинит пересчёт в self_breakdown.
	if(awake_members <= 0)
		dismantle()
		return TRUE
	// Живой огонь откладывает усреднение (tg VOLATILE_REACTION), на потолке осевшие выселяются без усреднения. Любая реакция блокирует dismantle.
	var/volatile_reaction = turf_reactions & VOLATILE_REACTION
	breakdown_cooldown++
	if(!volatile_reaction)
		dismantle_cooldown++
	if(breakdown_cooldown >= EXCITED_GROUP_BREAKDOWN_CYCLES)
		if(!volatile_reaction)
			turf_reactions = NO_REACTION
			return self_breakdown(poke_resting = TRUE, slice_budget = length(turf_list) >= EXCITED_GROUP_RESUMABLE_THRESHOLD ? EXCITED_GROUP_BREAKDOWN_SLICE : 0)
		else if(breakdown_cooldown >= EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING)
			evict_settled_members()
	else if(dismantle_cooldown >= EXCITED_GROUP_DISMANTLE_CYCLES && !(turf_reactions & (REACTING | STOP_REACTIONS)))
		dismantle()
	turf_reactions = NO_REACTION
	return TRUE

/// Волатильный потолок: осевшие члены вечно горящей группы выселяются с их газом, без усреднения. Заодно точный пересчёт awake_members.
/datum/excited_group/proc/evict_settled_members()
	var/awake_recount = 0
	var/kept = 0
	var/list/members = turf_list
	for(var/index in 1 to length(members))
		var/turf/open/T = members[index]
		if(istype(T))
			if(!T.excited)
				if(T.excited_group == src)
					T.excited_group = null
				continue
			awake_recount++
		kept++
		members[kept] = T
	members.len = kept
	awake_members = awake_recount
	breakdown_cooldown = 0

/// Подпороговый тёплый остаток стравленной зоны приводится к TCMB: compare() его не видит, остыть ему нечем. Зовётся до слияния в бакет брейкдауна и из dismantle(); небо не трогается.
/datum/excited_group/proc/snap_vented_wisp(turf/open/member)
	if(!vented_to_space || member.planetary_atmos)
		return
	var/datum/gas_mixture/wisp_air = member.air
	if(wisp_air.total_moles() > MINIMUM_MOLES_DELTA_TO_MOVE)
		return
	if(wisp_air.return_temperature() <= TCMB)
		return
	wisp_air.set_temperature(TCMB)

/datum/excited_group/proc/self_breakdown(space_is_all_consuming = FALSE, poke_resting = FALSE, slice_budget = 0)
	if(!breakdown_stage)
		if(!length(turf_list))
			garbage_collect()
			return TRUE
		// Small groups complete in this call, so sharing the source list avoids an
		// allocation. Large resumable groups need a stable membership snapshot.
		breakdown_members = slice_budget > 0 ? turf_list.Copy() : turf_list
		breakdown_cursor = 1
		breakdown_bucket_mixes = list()
		breakdown_bucket_counts = list()
		breakdown_awake_recount = 0
		breakdown_space_in_group = FALSE
		breakdown_space_is_all_consuming = space_is_all_consuming
		breakdown_poke_resting = poke_resting
		breakdown_stage = EG_BREAKDOWN_COLLECT
		#ifdef ATMOS_HEADLESS_BENCH
		headless_breakdown_started = world.time
		headless_breakdown_slices = 0
		headless_breakdown_members = length(breakdown_members)
		#endif
	#ifdef ATMOS_HEADLESS_BENCH
	headless_breakdown_slices++
	#endif

	var/remaining = slice_budget > 0 ? max(1, slice_budget) : INFINITY
	while(breakdown_stage)
		switch(breakdown_stage)
			if(EG_BREAKDOWN_COLLECT)
				while(breakdown_cursor <= length(breakdown_members) && remaining > 0)
					var/turf/open/T = breakdown_members[breakdown_cursor++]
					remaining--
					if(!istype(T) || T.excited_group != src)
						continue
					if(T.excited)
						breakdown_awake_recount++
					var/datum/gas_mixture/member_air = T.air
					if(!member_air)
						continue
					if(breakdown_space_is_all_consuming && istype(member_air, /datum/gas_mixture/immutable/space))
						breakdown_space_in_group = TRUE
					if(vented_to_space)
						snap_vented_wisp(T)
					// Осевшее небо не усредняется: его держит шаблон, а запись среднего держала бы его в turf_list вечно. Бодрое небо идёт в бакет своего шаблона.
					if(T.planetary_atmos && !T.excited)
						continue
					var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
					var/datum/gas_mixture/bucket_mix = breakdown_bucket_mixes[bucket_key]
					if(!bucket_mix)
						bucket_mix = new
						breakdown_bucket_mixes[bucket_key] = bucket_mix
					bucket_mix.merge(member_air)
					breakdown_bucket_counts[bucket_key]++
				if(breakdown_cursor <= length(breakdown_members))
					return FALSE
				awake_members = breakdown_awake_recount
				breakdown_cursor = 1
				if(breakdown_space_in_group)
					breakdown_space_mix = new /datum/gas_mixture/immutable/space
					breakdown_stage = EG_BREAKDOWN_SPACE_WRITE
				else
					breakdown_bucket_keys = list()
					for(var/bucket_key in breakdown_bucket_mixes)
						breakdown_bucket_keys += list(bucket_key)
					breakdown_stage = EG_BREAKDOWN_AVERAGE
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_AVERAGE)
				while(breakdown_cursor <= length(breakdown_bucket_keys) && remaining > 0)
					var/bucket_key = breakdown_bucket_keys[breakdown_cursor++]
					var/datum/gas_mixture/bucket_mix = breakdown_bucket_mixes[bucket_key]
					bucket_mix.divide(breakdown_bucket_counts[bucket_key])
					remaining--
				if(breakdown_cursor <= length(breakdown_bucket_keys))
					return FALSE
				breakdown_retained_members = list()
				breakdown_to_evict = list()
				breakdown_cursor = 1
				breakdown_stage = EG_BREAKDOWN_WRITE
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_WRITE)
				while(breakdown_cursor <= length(breakdown_members) && remaining > 0)
					var/turf/open/T = breakdown_members[breakdown_cursor++]
					remaining--
					if(!istype(T) || T.excited_group != src)
						continue
					if(!T.air)
						breakdown_retained_members += T
						continue
					// Осевшее небо выселяется (см. стадию сбора), бодрое получает среднее своего бакета.
					if(T.planetary_atmos && !T.excited)
						breakdown_to_evict += T
						continue
					var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
					var/datum/gas_mixture/bucket_mix = breakdown_bucket_mixes[bucket_key]
					// Турф мог сменить тип или обрести воздух между слайсами.
					if(!bucket_mix)
						breakdown_retained_members += T
						continue
					var/air_changed = T.air.compare(bucket_mix)
					T.air.copy_from(bucket_mix)
					T.update_visuals()
					if(air_changed)
						breakdown_retained_members += T
						if(T.atmos_wake_machines)
							for(var/obj/machinery/atmospherics/machine as anything in T.atmos_wake_machines)
								machine.atmos_wake()
					else if(!T.excited)
						breakdown_to_evict += T
					else
						breakdown_retained_members += T
				if(breakdown_cursor <= length(breakdown_members))
					return FALSE
				breakdown_cursor = 1
				breakdown_stage = EG_BREAKDOWN_EVICT
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_SPACE_WRITE)
				while(breakdown_cursor <= length(breakdown_members) && remaining > 0)
					var/turf/open/T = breakdown_members[breakdown_cursor++]
					remaining--
					if(!istype(T) || T.excited_group != src || !T.air)
						continue
					// Небо космосом не выедается: шаблон восстановит унос.
					if(T.planetary_atmos)
						continue
					T.air.copy_from(breakdown_space_mix)
					T.update_visuals()
				if(breakdown_cursor <= length(breakdown_members))
					return FALSE
				breakdown_cursor = 1
				breakdown_stage = EG_BREAKDOWN_POKE_COLLECT
				if(!breakdown_poke_resting)
					finish_breakdown()
					return TRUE
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_EVICT)
				while(breakdown_cursor <= length(breakdown_to_evict) && remaining > 0)
					var/turf/open/T = breakdown_to_evict[breakdown_cursor++]
					remaining--
					if(istype(T) && T.excited_group == src)
						T.excited_group = null
				if(breakdown_cursor <= length(breakdown_to_evict))
					return FALSE
				turf_list = breakdown_retained_members
				breakdown_cursor = 1
				if(!breakdown_poke_resting)
					finish_breakdown()
					return TRUE
				breakdown_to_poke = list()
				breakdown_stage = EG_BREAKDOWN_POKE_COLLECT
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_POKE_COLLECT)
				if(!breakdown_to_poke)
					breakdown_to_poke = list()
				while(breakdown_cursor <= length(turf_list) && remaining > 0)
					var/turf/open/T = turf_list[breakdown_cursor++]
					remaining--
					if(!istype(T) || !T.air || T.excited)
						continue
					// Небо среднее не получало, сверять ему нечего (сюда оно доживает только через space-ветку без выселения).
					if(T.planetary_atmos)
						continue
					for(var/turf/open/neighbor as anything in T.atmos_adjacent_turfs)
						if(!istype(neighbor) || neighbor.excited_group == src)
							continue
						breakdown_to_poke += T
						break
				if(breakdown_cursor <= length(turf_list))
					return FALSE
				breakdown_cursor = 1
				breakdown_stage = EG_BREAKDOWN_POKE
				if(remaining <= 0)
					return FALSE

			if(EG_BREAKDOWN_POKE)
				while(breakdown_cursor <= length(breakdown_to_poke) && remaining > 0)
					var/turf/open/T = breakdown_to_poke[breakdown_cursor++]
					remaining--
					if(SSair)
						ATMOS_BENCH_WAKE(T, "breakdown_poke")
						SSair.add_to_active(T, FALSE, wake_machines = FALSE)
						// Тот же порог, по которому process_cell укладывает члена группы: бюджет одноразовый.
						T.atmos_cooldown = SSair.individual_rest_cycles

					else
						T.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES
				if(breakdown_cursor <= length(breakdown_to_poke))
					return FALSE
				finish_breakdown()
				return TRUE

			else
				cancel_breakdown()
				return TRUE

/datum/excited_group/proc/dismantle()
	cancel_breakdown()
	for(var/turf/open/T as anything in turf_list)
		if(!istype(T))
			continue
		// Остатки остужаем и здесь: группа может расформироваться, не дожив до брейкдауна.
		if(vented_to_space && T.air)
			snap_vented_wisp(T)
		// Снятие до сброса флага: unlist_active_turf читает excited как истину о членстве, если индекс разошёлся.
		if(T.excited)
			if(SSair)
				SSair.unlist_active_turf(T)
			T.excited = FALSE
		// Upstream parity: a dismantled turf must not carry its stall counter
		// into the next activation, or it rests again after a single cycle.
		T.atmos_cooldown = 0
		T.excited_group = null
	garbage_collect()

/datum/excited_group/proc/garbage_collect()
	cancel_breakdown()
	for(var/turf/open/T as anything in turf_list)
		if(istype(T))
			T.excited_group = null
	turf_list.Cut()
	awake_members = 0
	if(SSair)
		SSair.excited_groups -= src

#undef ARCHIVE_OPEN_TURF
#undef LAST_SHARE_CHECK
#undef PLANET_SHARE_CHECK
#undef EQ_WALK_COLLECT
#undef EQ_WALK_MIX
#undef EQ_WALK_ACTIVATE
#undef EQ_WALK_RIP
#undef EG_BREAKDOWN_COLLECT
#undef EG_BREAKDOWN_AVERAGE
#undef EG_BREAKDOWN_WRITE
#undef EG_BREAKDOWN_SPACE_WRITE
#undef EG_BREAKDOWN_EVICT
#undef EG_BREAKDOWN_POKE_COLLECT
#undef EG_BREAKDOWN_POKE
