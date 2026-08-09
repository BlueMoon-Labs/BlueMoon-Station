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

	///Позиция турфа в SSair.active_turfs, 1-based; 0 - не числится. Это подсказка
	///для снятия за O(1), а не источник истины о членстве: истину держит
	////turf/open/var/excited. См. SSair.unlist_active_turf().
	var/tmp/active_turf_index = 0
	///Assoc list of opt-in COMSIG_TURF_EXPOSE listeners (listener -> handler proc).
	///Lazy: null when nobody listens, so process_cell reads one var as its send
	///gate. Maintained by /datum/proc/register_turf_exposure() and carried across
	///ChangeTurf (walls keep dormant registrations until the tile opens again).
	var/tmp/list/atmos_exposure_listeners
	//approximation of MOLES_O2STANDARD and MOLES_N2STANDARD pending byond allowing constant expressions to be embedded in constant strings
	// If someone will place 0 of some gas there, SHIT WILL BREAK. Do not do that.

/turf/open
	//used for spacewind
	var/pressure_difference = 0
	var/pressure_direction = 0
	///Accumulated pressure-gradient vector; opposing gradients cancel naturally.
	var/pressure_vector_x = 0
	var/pressure_vector_y = 0
	///TRUE, пока турф стоит в SSair.high_pressure_delta. Сам вектор флагом
	///членства служить не может: встречные вклады умеют схлопнуть его в ноль,
	///пока турф ещё в очереди, и следующий вклад ставил запись второй раз.
	var/tmp/high_pressure_queued = FALSE
	///world.time, раньше которого новый визуал ветра на этом турфе не создаётся:
	///затяжная разгерметизация плодила его каждый проход SSair поверх ещё живого
	///и раздувала очередь GC (47 тысяч в раунде 9911).
	var/tmp/next_space_wind_at = 0
	var/turf/pressure_specific_target

	var/datum/excited_group/excited_group
	var/excited = FALSE
	var/equalize_cycle = 0
	var/datum/gas_mixture/air

	var/obj/effect/hotspot/active_hotspot
	var/atmos_cooldown = 0
	var/planetary_atmos = FALSE //air will revert to initial_gas_mix over time

	var/list/atmos_overlay_types //gas IDs of current active gas overlays
	///Vents/scrubbers that want an instant wake-up when air on this turf changes.
	///Maintained by /obj/machinery/atmospherics/register_turf_wake().
	var/tmp/list/atmos_wake_machines
	///Sleeping edges (идея ZAS ConnectionGroup): осевшие пары соседей. Ключ -
	///сосед, значение - list(наша ревизия, его ревизия) на момент compare(),
	///сказавшего "разницы нет". Пока обе mutation_rev не изменились, пара
	///пропускает compare/share целиком. Гейтится SSair.sleeping_edges_enabled;
	///сбрасывается при пересчёте соседства (ImmediateCalculateAdjacentTurfs).
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
			// Losing a neighbor changes who they can share with, not what they
			// hold: one cycle to re-compare, no fresh stall budget.
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
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air(datum/gas_mixture/taker, moles)
	if(!taker || !return_air()) // shouldn't transfer from space
		return FALSE
	if(!air.transfer_to(taker, moles))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/transfer_air_ratio(datum/gas_mixture/taker, ratio)
	if(!taker || !return_air())
		return FALSE
	if(!air.transfer_ratio_to(taker, ratio))
		return FALSE
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

/turf/open/remove_air(amount)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove(amount)
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return removed

/turf/open/remove_air_ratio(ratio)
	var/datum/gas_mixture/ours = return_air()
	var/datum/gas_mixture/removed = ours.remove_ratio(ratio)
	update_visuals()
	if(SSair)
		SSair.add_to_active(src)
	return removed

/turf/open/proc/copy_air_with_tile(turf/open/T)
	if(istype(T))
		air.copy_from(T.air)

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

/// `cycle` is the SSair fire this snapshot belongs to. process_cell() is handed
/// its fire count as an argument and gates both its own archive and its
/// neighbours' on it, so the stamp has to come from the same number rather than
/// from SSair directly - otherwise the guards compare against a value nothing
/// ever wrote.
/turf/open/archive(cycle = SSair.times_fired)
	if(!air)
		return
	air.archive()
	temperature_archived = air.return_temperature()
	archived_cycle = cycle

////////////////////////SUPERCONDUCTIVITY/////////////////////////////
// Heat moving through solids: walls, windows, closed doors. The auxmos
// migration left process_turf_heat() an empty stub for years - this is the
// native rebuild of the pre-auxmos implementation. The whole pass exists only
// when SSair.heat_enabled is set: consider_superconductivity() gates on it, so
// a server with the flag off never even accumulates the processing list.

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
	// Обмен с нулевой дельтой не переносит энергию, но безусловный add_to_active
	// на каждом проходе не давал осевшему соседу уснуть и обнулял его stall-
	// счётчик: после станционного пожара 2500+ горячих стен приколачивали 3-4
	// тысячи активных турфов до конца раунда (9911). Стена продолжает остывать
	// радиацией и разбудит воздух, как только дельта станет настоящей.
	if(!other.blocks_air) //Both open: heat-permeable border that does not pass air
		var/turf/open/open_other = other
		if(abs(air.return_temperature() - open_other.air.return_temperature()) < MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			return
		open_other.air.temperature_share(air, WINDOW_HEAT_TRANSFER_COEFFICIENT)
	else //Open src, solid neighbor
		if(abs(air.return_temperature() - other.return_temperature()) < MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			return
		temperature_share_open_to_solid(other)
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
	// An emptied mixture keeps whatever temperature it was last left with and can
	// never lose it: with no gas its heat capacity is zero, so temperature_share
	// declines to exchange anything. Reading the exit condition off that number
	// pins the tile in SSair.active_super_conductivity for the rest of the round,
	// and every pass over it also re-adds its neighbours. Tiles that share their
	// last gas away while hot (a fire front venting into a breach) hit this. The
	// tile's own temperature does cool - radiate_to_spess drives it to T0C, below
	// the sustain threshold - so read the exit off that instead.
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
		// Пол здесь - только страховка от ухода ниже реликтового фона при
		// перелёте через равновесие (дельта считается по архиву, а применяется к
		// живым температурам нескольких соседей за фаер). Пол T0C, скопированный
		// из radiate_to_spess() без её входного гейта temperature > T0C, ГРЕЛ
		// любой холодный монолит от первого же джоуля: стены ледяной луны при
		// 180 K и телекомы при 80 K скакали к 273 K из ниоткуда.
		temperature = max(temperature, TCMB)
		sharer.temperature = max(sharer.temperature, TCMB)


/turf/open/proc/eg_reset_cooldowns()
	if(excited_group)
		excited_group.reset_cooldowns()
	atmos_cooldown = 0
/turf/open/proc/eg_garbage_collect()
	if(excited_group)
		excited_group.garbage_collect()
/turf/open/proc/get_excited()
	return excited
/turf/open/proc/set_excited()
	// Must go through add_to_active: setting the flag first made the activation
	// a no-op for the fast path there, leaving a turf that claims to be active
	// while never appearing in the list.
	if(SSair)
		SSair.add_to_active(src, FALSE)

/////////////////////////GAS OVERLAYS//////////////////////////////


/turf/open/proc/update_visuals()

	var/list/atmos_overlay_types = src.atmos_overlay_types // Cache for free performance
	var/static/list/nonoverlaying_gases = typecache_of_gases_with_no_overlays()

	if(!air) // 2019-05-14: was not able to get this path to fire in testing. Consider removing/looking at callers -Naksu
		if (atmos_overlay_types)
			for(var/overlay in atmos_overlay_types)
				vis_contents -= overlay
			src.atmos_overlay_types = null
		return

	// Runs for every active turf every cycle: read the gas list directly and only
	// allocate the overlay list once a visible gas is actually found.
	var/list/new_overlay_types
	var/list/cached_gases = air.gases
	// O2 and N2 have no overlay. Avoid the per-gas visibility scan for the
	// overwhelmingly common clean-room mixture once no old overlay needs removal.
	if(!atmos_overlay_types && length(cached_gases) == 2 && cached_gases[GAS_O2] && cached_gases[GAS_N2])
		ATMOS_TPROF_COUNT("vis_clean_air")
		return
	var/list/gas_overlays = GLOB.gas_data.overlays
	var/list/gas_visibility = GLOB.gas_data.visibility
	// One overlay per turf instead of one per visible gas, and it belongs to the
	// gas that dominates the mixture. Blending the colours instead would erase
	// the cue entirely: plasma, tritium, water vapour and N2O declare no color
	// at all, their whole identity is the pre-tinted sprite, so a burning room
	// (plasma + tritium + vapour) would come out as a colourless grey haze.
	var/visible_moles = 0
	var/list/dominant_overlays
	var/dominant_score = 0
	for(var/gas_id as anything in cached_gases)
		if (nonoverlaying_gases[gas_id])
			continue
		var/list/gas_overlay = gas_overlays[gas_id]
		if(!gas_overlay)
			continue
		var/moles = cached_gases[gas_id]
		var/threshold = gas_visibility[gas_id]
		if(moles <= threshold)
			continue
		visible_moles += moles
		// Ranked by how far past its own visibility threshold the gas is, not by
		// raw moles: miasma only shows at sixty times the usual limit, so a whiff
		// of it must not outrank the plasma cloud it is floating in.
		var/score = moles / threshold
		if(score > dominant_score)
			dominant_score = score
			dominant_overlays = gas_overlay

	// The mixture ladder always yields exactly one overlay, so resolve it into a
	// plain value first. A settled cloud recomputes the same overlay every cycle
	// and the comparison below then costs nothing - wrapping it in a list first
	// (as this used to) allocated a throwaway list per smoke-filled turf per
	// fire only to discover nothing moved.
	var/new_overlay
	if(dominant_overlays)
		new_overlay = dominant_overlays[min(FACTOR_GAS_VISIBLE_MAX, CEILING(visible_moles / MOLES_GAS_VISIBLE_STEP, 1))]

	if(isnull(new_overlay) && !atmos_overlay_types)
		ATMOS_TPROF_COUNT("vis_no_overlay")
		return
	if(!isnull(new_overlay) && length(atmos_overlay_types) == 1 && atmos_overlay_types[1] == new_overlay)
		ATMOS_TPROF_COUNT("vis_unchanged")
		return
	new_overlay_types = isnull(new_overlay) ? list() : list(new_overlay)
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

/proc/typecache_of_gases_with_no_overlays()
	. = list()
	for (var/gastype in subtypesof(/datum/gas))
		var/datum/gas/gasvar = gastype
		if (!initial(gasvar.gas_overlay))
			.[initial(gasvar.id)] = TRUE

/////////////////////////////SIMULATION///////////////////////////////////

// Significant gas movement also resets the receiving tile's stall counter and
// wakes it if it was resting: resting turfs stay in their excited group and
// receive gas passively, so anything meaningfully fed by a neighbor must come
// back to the active list to re-share (and, for planetary turfs, re-equalize
// with their template).
#define LAST_SHARE_CHECK \
	var/last_share = our_air.last_share; \
	if(last_share > our_suspend_threshold){ \
		our_excited_group.reset_cooldowns(); \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	} else if(last_share > our_move_threshold) { \
		our_excited_group.dismantle_cooldown = 0; \
		cached_atmos_cooldown = 0; \
		enemy_tile.atmos_cooldown = 0; \
		if(!enemy_tile.excited && SSair){ \
			SSair.add_to_active(enemy_tile, FALSE); \
		} \
	}

// Same cooldown handling for the template share; there is no enemy tile here.
#define PLANET_SHARE_CHECK \
	var/planet_last_share = our_air.last_share; \
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
// Стадии возобновляемого обхода зоны. Разрез идёт ровно по границе "читаем" /
// "пишем": сбор связного множества и активация сдвинутых членов газ не двигают
// вовсе, поэтому их можно рвать между фаерами без последствий. Стравливание
// кромки и усреднение зоны, наоборот, обязаны остаться ОДНИМ куском: сумма
// собирается по всем членам, а записывается каждому - разорви её посередине, и
// запись ляжет поверх суммы, снятой до чужой правки, то есть моли зоны
// перестанут сходиться.
#define EQ_WALK_COLLECT 1
#define EQ_WALK_MIX 2
#define EQ_WALK_ACTIVATE 3
#define EQ_WALK_RIP 4

/// Обход зоны эквалайзером, растянутый на несколько фаеров SSair.
///
/// Прежде это был один атомарный прок: BFS до equalize_hard_turf_limit (2000)
/// турфов, стравливание кромки, сведение газа всей зоны и активация её членов -
/// всё в одном неделимом куске. Раунд 9869 (Delta, 89 игроков) намерил фазу в
/// 259 мс за проход, а МК в тот же момент - 1225% тика: два таких обхода
/// укладывались в один слот и давали спайк, который нечем было разорвать.
///
/// Состояние живёт в датуме, а не в SSair.currentrun: тот слот один на ВСЕ фазы
/// подсистемы, и запись турфов в нём следующая фаза приняла бы за свои сущности.
/// Списки переиспользуются между обходами - зона в две тысячи членов иначе
/// выделяла бы полдюжины списков такого размера на каждый вызов.
/datum/atmos_zone_walk
	/// Текущая стадия, 0 - обхода в полёте нет.
	var/stage = 0
	/// Номер фаера, которым обход штампует захваченные турфы (гард "одна зона на
	/// турф за фаер").
	var/cyclenum = 0
	/// Связное множество зоны, в порядке обхода.
	var/list/turf/open/zone_turfs = list()
	/// Ассоциативно: члены зоны, граничащие с космосом. Список обходится по
	/// ключам как обычный, а проверка членства становится O(1) вместо линейного
	/// скана по зоне в две тысячи турфов.
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

/// Заводит обход от турфа-затравки. FALSE - затравка не годится (не открытый
/// турф, без смеси, или его зону уже обошли в этом фаере).
/datum/atmos_zone_walk/proc/begin(turf/open/seed, walk_cycle)
	// Проверки идут ДО reset(): фаза зовёт begin() на каждого кандидата подряд, а
	// в большой зоне почти все они уже помечены её же обходом. Отказ обязан быть
	// дешевле шести Cut() по спискам.
	if(!istype(seed) || seed.blocks_air || !seed.air)
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

/// Завершение обхода: снять состояние и перештамповать членов.
///
/// Гард "одна зона на турф за фаер" держится на equalize_cycle, а обход,
/// растянувшийся на несколько фаеров, оставил бы своих членов со штампом фаера
/// ЗАХВАТА. В следующем фаере любой из них снова прошёл бы гейт фазы и завёл
/// повторный обход той же зоны - то есть стравил бы её кромку в космос второй
/// раз за проход. Переписать одно число у двух тысяч турфов дешевле любой из
/// стадий, поэтому штамп подтягивается к фаеру ЗАВЕРШЕНИЯ.
/datum/atmos_zone_walk/proc/finish()
	if(SSair && SSair.times_fired > cyclenum)
		var/finish_cycle = SSair.times_fired
		for(var/turf/open/member as anything in zone_turfs)
			if(istype(member))
				member.equalize_cycle = finish_cycle
	stage = 0
	cursor = 1
	// did_work намеренно переживает finish(): его читает атомарная обёртка уже
	// после завершения обхода.
	zone_turfs.Cut()
	space_edge_turfs.Cut()
	pending.Cut()
	seen.Cut()
	moles_before.Cut()
	temperature_before.Cut()

/// Один срез обхода. `slice_budget` - сколько членов зоны разрешено тронуть; 0
/// означает "без ограничения", то есть прогнать обход целиком. Возвращает TRUE,
/// когда обход завершён и состояние снято.
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

					// Давление считается на месте. return_pressure() тянет за
					// собой total_moles(), то есть два вызова прока на КАЖДЫЙ
					// турф зоны, а зона доходит до двух тысяч - четыре тысячи
					// вызовов ради одного числа, которое нужно только гейту
					// разброса ниже.
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
				// Единственная стадия, которую рвать нельзя, - см. шапку файла у
				// EQ_WALK_*. Стоимость её ограничена размером зоны и платится
				// целиком, поэтому фаза заходит сюда только с запасом тика.
				vent_space_edges()
				mix_zone()
				remaining -= zone_turfs.len
				cursor = 1
				stage = EQ_WALK_ACTIVATE
				if(remaining <= 0)
					return FALSE

			if(EQ_WALK_ACTIVATE)
				// Кого именно проход сдвинул. Активировать зону целиком нельзя:
				// эквалайзер сам делает всех своих членов ОДИНАКОВЫМИ, то есть
				// гарантирует, что шерить им между собой больше нечего, - и тут
				// же будил всю зону до двух тысяч турфов. Раунд 9868: 2555
				// активных турфов на станции при 307 реально шерящих, целые
				// области с разбросом 72.0-72.0 кПа / 288-288 К, которые не
				// засыпали часами. Снимок молей и температуры до записи - вся
				// цена вопроса; состав при равных молях и равной температуре
				// разойтись может только если он разошёлся у соседей, а те
				// разбудят турф обычным путём.
				var/snapshot_taken = moles_before.len
				while(cursor <= zone_turfs.len && remaining > 0)
					var/index = cursor
					cursor++
					remaining--
					var/turf/open/group_turf = zone_turfs[index]
					if(!istype(group_turf) || group_turf.blocks_air || !group_turf.air)
						continue
					// Перерисовка - каждому члену без фильтра: снимок сравнивает
					// СУММУ молей, а сведение к среднему меняет состав и при равной
					// сумме. Пропуск оставлял призрачное облако видимого газа там,
					// где эквалайзер его только что развёл. Фильтр ниже гейтит
					// только пробуждение.
					group_turf.update_visuals()
					// Кромка космоса всегда считается сдвинутой: она только что
					// стравила свою долю в вакуум на стадии сведения.
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
						// Те же пороги, что у gas_mixture.compare(): ниже них
						// LINDA считает движение газа несущественным, и наш
						// вердикт обязан совпадать.
						if(moles_delta <= MINIMUM_MOLES_DELTA_TO_MOVE || moles_delta <= old_moles * MINIMUM_AIR_RATIO_TO_MOVE)
							if(abs(group_air.temperature - temperature_before[index]) <= MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
								continue
					if(SSair)
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

/// Стравливание кромки зоны в вакуум. Ровно прежний блок, вынесенный из
/// монолита: файрлоки на каждой смежной с космосом стороне, доля газа за борт,
/// теплообмен с вакуумом и вклад в вектор ветра.
/datum/atmos_zone_walk/proc/vent_space_edges()
	total_pressure_drop = 0
	for(var/turf/open/edge_turf as anything in space_edge_turfs)
		// Сбор зоны теперь растянут во времени, поэтому член зоны мог за это
		// время смениться (ChangeTurf в стену) или потерять смесь.
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

/// Сведение газа зоны к общему среднему плюс снимок "было" для фильтра
/// активации.
///
/// Это специализация equalize_all_gases_in_list(): та строит промежуточный
/// список участников, а снимок молей поверх неё требовал ещё и отдельного
/// total_moles() на каждого члена зоны. Суммы молей здесь всё равно считаются по
/// дороге, так что снимок достаётся даром, а две тысячи вызовов прока и два
/// списка на две тысячи записей - нет.
/datum/atmos_zone_walk/proc/mix_zone()
	var/list/turf/open/members = zone_turfs
	var/member_count = members.len
	// Зона из одного турфа сводить нечего: снимок остаётся пустым, и стадия
	// активации будит такого члена безусловно (он либо кромка, либо не сдвинут).
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
	// Последовательные слияния с весом по теплоёмкости схлопываются в полную
	// энергию, делённую на полную теплоёмкость; TCMB - то же, что дала бы пустая
	// временная смесь, если тепла не было ни у кого.
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

/// Атомарный прогон обхода зоны целиком, от затравки до разрыва пола.
///
/// Фаза SSair ходит по стадиям сама (см. process_turf_equalize_auxtools), а этот
/// вход оставлен для тестов и внешних вызовов, которым нужен готовый ответ
/// одним вызовом.
/turf/open/proc/equalize_pressure_in_zone(cyclenum)
	if(!SSair)
		return FALSE
	// Слот обхода один на весь атмос (см. SSair.zone_walk): обход фазы,
	// подвешенный посреди стадий, доедаем до конца ДО собственного. Иначе два
	// обхода двигают газ одной зоны - кромка стравливается в космос дважды за
	// логический проход, а стадия MIX подвешенного при резюме затирает членов
	// зоны из уже устаревшего аккумулятора.
	var/datum/atmos_zone_walk/in_flight = SSair.zone_walk
	if(in_flight?.stage)
		in_flight.advance(0)
	var/datum/atmos_zone_walk/walk = new
	if(!walk.begin(src, cyclenum))
		return FALSE
	walk.advance(0)
	return walk.did_work

/turf/proc/consider_firelocks(turf/T2)
/turf/open/consider_firelocks(turf/T2)
	if(blocks_air)
		return
	for(var/obj/machinery/airalarm/alarm in src)
		alarm.handle_decomp_alarm()
	for(var/obj/machinery/door/firedoor/FD in src)
		FD.emergency_pressure_stop()
	for(var/obj/machinery/door/firedoor/FD in T2)
		FD.emergency_pressure_stop()

/turf/proc/handle_decompression_floor_rip()

/turf/open/floor/handle_decompression_floor_rip(sum)
	if(!blocks_air && sum > 20 && prob(clamp(sum / 10, 0, 30)))
		remove_tile()

/turf/open/process_cell(fire_count)
	if(blocks_air || !air)
		if(SSair)
			SSair.remove_from_active(src)
		return
	if(istype(src, /turf/open/space))
		if(SSair)
			SSair.remove_from_active(src)
		return

	ATMOS_TPROF_VARS
	ATMOS_TPROF_COUNT("turfs")

	ATMOS_TPROF_MARK
	if(archived_cycle < fire_count)
		archive(fire_count)
	ATMOS_TPROF_ADD("archive")

	current_cycle = fire_count

	var/list/adjacent_turfs = atmos_adjacent_turfs
	if(!LAZYLEN(adjacent_turfs))
		// An active turf nothing can flow out of: either genuinely walled in,
		// or stranded by a blocking object that left (moved, lost density)
		// without an air update. Re-verify the adjacency - the queue dedupes,
		// and for genuinely sealed tiles the recalculation is four cheap
		// neighbor checks. Without this a stranded tile fed by a rotting
		// corpse hoards pressure forever.
		CALCULATE_ADJACENT_TURFS(src)
	var/datum/excited_group/our_excited_group = excited_group
	var/adjacent_turfs_length = max(1, LAZYLEN(adjacent_turfs))
	var/our_share_coeff = 1 / (adjacent_turfs_length + 1)
	var/cached_atmos_cooldown = atmos_cooldown + 1
	// Гейт спящих рёбер по тишине: кэш пар смотрим и пишем только когда сам
	// турф уже несколько фаеров ничего не двигал. Активный фронт (cooldown
	// обнуляется каждым значимым шером) не платит ни лукап, ни запись.
	var/edge_sleep_enabled = SSair?.sleeping_edges_enabled && cached_atmos_cooldown > ATMOS_EDGE_SLEEP_MIN_QUIET_FIRES

	var/planet_atmos = planetary_atmos

	var/datum/gas_mixture/our_air = air
	// The share-significance defines are absolute moles calibrated for a
	// 104-mol standard cell. In a 400+ atm supply tank the same constants
	// read a 0.05% machinery ripple (dozens of moles) as "significant
	// movement" and kept whole engine rooms excited forever, because grouped
	// tiles share unconditionally and every share re-armed the cooldowns.
	// Scale the gates with tile content; at standard pressure the max()
	// resolves to the original constants. The scaled part must stay gentle
	// (1%, not the 10% the absolute define encodes at standard pressure):
	// canister-flood tiles hold thousands of moles, and gating their real
	// flows as insignificant lets breakdown average the flood flat mid-flow.
	var/our_cycle_moles = our_air.total_moles()
	var/our_suspend_threshold = max(MINIMUM_AIR_TO_SUSPEND, our_cycle_moles * SIGNIFICANT_SHARE_CONTENT_RATIO)
	var/our_move_threshold = max(MINIMUM_MOLES_DELTA_TO_MOVE, our_cycle_moles * MINIMUM_AIR_RATIO_TO_MOVE)
	var/turf/open/space_neighbor

	ATMOS_TPROF_MARK
	for(var/turf/open/enemy_tile as anything in adjacent_turfs)
		if(!istype(enemy_tile) || enemy_tile.blocks_air)
			continue
		// Пара обрабатывается один раз за цикл, и у ВТОРОЙ половины каждой пары
		// этот гейт срабатывает всегда - поэтому он стоит до чтения воздуха и
		// планетарных проверок, а не после них: под нагрузкой большинство пар
		// осевшие, и каждая платила четыре лишних чтения на своём B-обходе.
		// Космос и спящее небо гейт не задевает: их process_cell не выполняется,
		// current_cycle протухший, проверка их всегда пропускает.
		if(fire_count <= enemy_tile.current_cycle)
			continue
		var/datum/gas_mixture/enemy_air = enemy_tile.air
		if(!enemy_air)
			continue

		// Space is represented by a shared immutable mix (the only turf air with
		// gc_share set), so vent explicitly instead of mutating it. Сам сброс
		// отложен за цикл пар: он идёт по живым значениям, и здесь он снял бы
		// газ ДО того, как соседи закончили с нами меняться.
		if(enemy_air.gc_share)
			ATMOS_TPROF_COUNT("space_pairs")
			// A planetary turf never trades with space: the template refills
			// whatever the vacuum takes, so the pair is a perpetual vent/refill
			// pump that keeps the tile excited forever (space-ruin exteriors
			// mapped with planetary dirt: syndicate mothership, reactor ruin).
			// The sky wins - the tile just keeps its template air.
			if(!planet_atmos)
				space_neighbor = enemy_tile
			continue

		// Two different skies meeting (lava shore, jungle river bank): both
		// tiles are anchored to their own template, so anything exchanged here
		// regenerates next cycle - an endless gradient that keeps whole surface
		// bands excited forever. Each side keeps its own sky; spilled gas still
		// leaves through the 0.8-ratio template pull within a couple of cycles.
		if(planet_atmos && enemy_tile.planetary_atmos && enemy_tile.initial_gas_mix != initial_gas_mix)
			continue

		// Спящий планетарный сосед - бесконечный резервуар своего неба, ровно как
		// космос выше - бесконечный вакуум: обмениваемся с шаблоном напрямую, не
		// трогая турф-посредник. Обычный share() в него - работа, которую шаблон
		// сотрёт за пару циклов (PLANET_SHARE_RATIO), а разбуженный снег до нового
		// сна успевает поднять и своих соседей - так граница "тёплый интерьер -
		// улица" держала бодрыми ОБЕ стороны каждой открытой двери и каждого
		// шахтёрского тоннеля до конца раунда. Наша сторона честно продолжает
		// остывать и стравливаться к небу; планетарная спит, пока на неё не
		// напишут по-настоящему (канистра, хотспот, assume_air будят её обычными
		// путями, и до нового сна пара работает по-старому).
		if(enemy_tile.planetary_atmos && !enemy_tile.excited)
			var/datum/gas_mixture/sky_template = SSair.get_planetary_template(enemy_tile)
			if(sky_template)
				ATMOS_TPROF_COUNT("sky_pairs")
				if(!our_air.compare(sky_template))
					continue
				ATMOS_TPROF_COUNT("sky_shares")
				var/sky_temperature_delta = abs(our_air.temperature_archived - sky_template.temperature_archived)
				our_air.share_with_template(sky_template, our_share_coeff)
				// Compare прошёл - через границу реально движутся моли или тепло, и
				// тайл обязан пережить конец процедуры: без группы и без реакции его
				// снимет с актива безусловно. Мольный поток сходится сам, а чисто
				// температурный двигает НОЛЬ молей - гейтить группу по last_share
				// значило бы, что стравившаяся до состава неба, но ещё тёплая
				// комната у открытой на мороз двери отдохнёт один цикл и замрёт
				// тёплой навсегда. Парная ветка ниже в этом же положении держит
				// группу живой самим фактом compare-прохода - делаем так же.
				if(!our_excited_group)
					var/datum/excited_group/sky_group = new
					sky_group.add_turf(src)
					our_excited_group = excited_group
				if(our_air.last_share > our_suspend_threshold)
					our_excited_group.reset_cooldowns()
				else
					our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
				// Спейсвинд: как у пары - при реальном потоке или значимом
				// температурном перепаде (share() ставит тот же порог).
				if(our_air.last_share > our_move_threshold || sky_temperature_delta > MINIMUM_TEMPERATURE_TO_MOVE)
					var/sky_pressure_delta = our_air.return_pressure() - sky_template.return_pressure()
					if(sky_pressure_delta > 0)
						consider_pressure_difference(enemy_tile, sky_pressure_delta)
					else if(sky_pressure_delta < 0)
						enemy_tile.consider_pressure_difference(src, -sky_pressure_delta)
				continue

		// Sleeping edges: осевшая одногрупповая пара выходит ДО ленивого архива
		// соседа - иначе спящее ребро всё равно платило бы копию его газ-листа.
		// Отложенный архив безопасен: он нужен только реальному share(), и
		// первый же живой партнёр (или собственный process_cell соседа) снимет
		// его сам. Промах инвалидации самолечится breakdown-усреднением группы.
		var/datum/excited_group/enemy_group_early = enemy_tile.excited_group
		if(edge_sleep_enabled && our_excited_group && our_excited_group == enemy_group_early)
			var/list/edge_state_early = settled_edge_revs?[enemy_tile]
			if(edge_state_early && edge_state_early[1] == our_air.mutation_rev && edge_state_early[2] == enemy_air.mutation_rev)
				ATMOS_TPROF_COUNT("edge_sleeps")
				continue

		// Same guard the tile applies to its own archive at the top of the proc,
		// and for the same reason. A tile with several active neighbours used to
		// be re-archived by every one of them in turn, and each re-archive
		// snapshotted gas the previous neighbour had already moved - so the
		// second and third shares ran against a mid-cycle baseline and the
		// result depended on the order the active list happened to be in. That
		// is precisely what the archive exists to prevent. It also cost a fresh
		// gas list copy per neighbour: 326k turf archives per 135k processed
		// tiles in a live round, most of them redundant.
		if(enemy_tile.archived_cycle < fire_count)
			enemy_tile.archive(fire_count)

		var/should_share_air = FALSE
		var/datum/excited_group/enemy_excited_group = enemy_tile.excited_group

		if(our_excited_group && enemy_excited_group)
			if(our_excited_group != enemy_excited_group)
				our_excited_group.merge_groups(enemy_excited_group)
				our_excited_group = excited_group
				ATMOS_TPROF_COUNT("group_merges")
			// Тот же гейт, что и у негруппированной пары строкой ниже. Общая группа
			// означает только связность зоны, а не наличие градиента: пара, между
			// которой двигать нечего, всё равно гоняла полный share() каждый цикл
			// до самого распада группы. В раунде 9872 78% активных турфов не
			// двигали ни моля, а стоили 86% от работающего - это 82% всей фазы
			// турфов, то есть около двух третей процессорного времени атмоса.
			// Остаточное выравнивание внутри группы докрывает self_breakdown раз в
			// EXCITED_GROUP_BREAKDOWN_CYCLES, а пороги здесь ровно те, которые
			// LINDA сама считает незначимыми.
			//
			should_share_air = !!our_air.compare(enemy_air)
			// Sleeping edges: пара сказала "разницы нет" - запоминаем ревизии
			// обоих концов, и пока они не менялись, ранний гейт перед архивом
			// соседа пропускает пару целиком. Устаревшую запись не чистим: по
			// несовпавшим ревизиям она не сработает и перезапишется здесь же.
			if(edge_sleep_enabled && !should_share_air)
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
			if(!enemy_tile.excited && SSair)
				SSair.add_to_active(enemy_tile)
			var/datum/excited_group/EG = our_excited_group || enemy_excited_group || new
			if(!our_excited_group)
				EG.add_turf(src)
			if(!enemy_excited_group)
				EG.add_turf(enemy_tile)
			our_excited_group = excited_group
			should_share_air = TRUE

		if(should_share_air)
			ATMOS_TPROF_COUNT("shares")
			var/enemy_share_coeff = 1 / (max(1, LAZYLEN(enemy_tile.atmos_adjacent_turfs)) + 1)
			var/difference = our_air.share(enemy_air, our_share_coeff, enemy_share_coeff)
			if(difference)
				if(difference > 0)
					consider_pressure_difference(enemy_tile, difference)
				else
					enemy_tile.consider_pressure_difference(src, -difference)
				// Пер-парный захлоп (tg-шный consider_firelocks, вернувшийся из
				// зонного обхода в обычную LINDA): опасный перепад через проём с
				// файрлоком закрывает створку сам, не дожидаясь зонной тревоги.
				// Бит файрлока лежит в значении соседства, порог тот же, что у
				// декомп-события. Фронт быстрой разгерметизации отсекается на
				// первом же дверном проёме, а не когда стравится вся секция.
				if(abs(difference) >= DECOMPRESSION_FIRELOCK_PRESSURE_DELTA && (adjacent_turfs[enemy_tile] & ATMOS_ADJACENT_FIRELOCK))
					consider_firelocks(enemy_tile)
			LAST_SHARE_CHECK

	ATMOS_TPROF_ADD("neighbors")

	ATMOS_TPROF_MARK
	if(space_neighbor)
		// tg-паритет (их share_end: "We share 100% of our mix in this step"):
		// кромка пробоины отдаёт космосу ВСЁ за один фаер, а не 1/(n+1)-долю.
		// Экспоненциальный слив давал вялые разгермы (зал через 1-тайловую дыру
		// сосался десятки минут), спейсвинд в долю дельты и хвост из десятков
		// циклов на мизере. Сброс считается по живым значениям после парных
		// шеров - как ре-архив перед share(space, 1, 1) у tg: всё, что соседи
		// втолкнули в кромку этим фаером, уходит этим же фаером.
		var/moles_before = our_air.total_moles()
		var/temperature_before = our_air.temperature
		if(moles_before > MINIMUM_MOLES_DELTA_TO_MOVE || abs(temperature_before - TCMB) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
			ATMOS_TPROF_COUNT("space_vents")
			// Derive pressure from the known mole scaling instead of re-summing
			// the gas list through return_pressure().
			var/volume_cache = our_air.volume
			var/pressure_before = volume_cache > 0 ? (moles_before * R_IDEAL_GAS_EQUATION * temperature_before / volume_cache) : 0
			// Порог события - HAZARD_LOW, а не WARNING_LOW: раунд 9906 показал,
			// что при затяжном сливе зона у дыры быстро проседает ниже 50 кПа,
			// события глохнут, и створки без удерживаемого перепада тихо
			// переоткрываются - станция дренируется через них до конца смены.
			// Пока комната у пробоины держит выживаемое давление, тревога и
			// захлоп обязаны перевзводиться (кулдаун зоны - 30 секунд).
			if(pressure_before >= HAZARD_LOW_PRESSURE && SSair)
				SSair.queue_decompression_area(src)
			our_air.vent_ratio(1)
			our_air.set_temperature(TCMB)
			// Группа нужна и опустевшей кромке: соседи докармливают её каждый
			// фаер, и без группы конец процедуры снял бы одинокую утечку с
			// актива после первого же прохода.
			if(!our_excited_group)
				var/datum/excited_group/space_group = new
				space_group.add_turf(src)
				our_excited_group = excited_group
			// Метка "зона стравливается в космос": по ней брейкдаун/расформирование
			// приводят подпороговые тёплые остатки членов к TCMB (snap_vented_wisp).
			our_excited_group.vented_to_space = TRUE
			if(moles_before > MINIMUM_AIR_TO_SUSPEND)
				our_excited_group.reset_cooldowns()
				cached_atmos_cooldown = 0
			else if(moles_before > MINIMUM_MOLES_DELTA_TO_MOVE)
				our_excited_group.dismantle_cooldown = 0
				cached_atmos_cooldown = 0
			// Спейсвинд получает полную дельту - главный видимый эффект tg-разгерма:
			// у дыры рвёт и тянет, пока комнате есть что терять.
			if(pressure_before > 0)
				consider_pressure_difference(space_neighbor, pressure_before)
	ATMOS_TPROF_ADD("space")

	ATMOS_TPROF_MARK
	if(planet_atmos)
		var/datum/gas_mixture/template = SSair.get_planetary_template(src)
		if(our_air.compare(template))
			ATMOS_TPROF_COUNT("planet_shares")
			if(!our_excited_group)
				var/datum/excited_group/EG = new
				EG.add_turf(src)
				our_excited_group = excited_group
			// Neighbor shares above already moved gas this cycle: re-archive so
			// the template share works from current values. With the stale
			// cycle-start archive, an aggressive pull plus the neighbor shares
			// can overdraw the turf below the template.
			our_air.archive()
			our_air.share_with_template(template, PLANET_SHARE_RATIO)
			// Follow up with a conductive share against an inflated template
			// heat capacity (upstream behavior): pure temperature deltas are the
			// dominant planetary churn, and the weak in-share coupling alone
			// crawls toward the 4K suspend threshold for hundreds of cycles.
			our_air.temperature_share(null, OPEN_HEAT_TRANSFER_COEFFICIENT, template.temperature_archived, template.immutable_heat_capacity * PLANET_SHARE_TEMPERATURE_CAPACITY)
			PLANET_SHARE_CHECK
	ATMOS_TPROF_ADD("planet")

	ATMOS_TPROF_MARK
	var/reaction_result = our_air.react(src)
	ATMOS_TPROF_ADD("react")
	ATMOS_TPROF_COUNT_IF(reaction_result & REACTING, "reactions")

	// Feed the group lifecycle: a member with a live reaction or hotspot marks
	// the whole group so tick_lifecycle can hold off breakdown/dismantle
	// (averaging mid-burn smears the fire's heat across the group).
	if(our_excited_group)
		// Реакции сами возвращают VOLATILE_REACTION (нобиум, антинобиум,
		// фреоновое пламя) - бит доезжает сюда через OR в react().
		our_excited_group.turf_reactions |= reaction_result
		// Волатильным считается и generic combustion без хотспота (genericfire
		// пишет reaction_results["fire"], но hotspot не создаёт) - иначе
		// брейкдаун усреднит группу посреди такого горения.
		if(active_hotspot || ((reaction_result & REACTING) && our_air.reaction_results["fire"]))
			our_excited_group.turf_reactions |= VOLATILE_REACTION

	ATMOS_TPROF_MARK
	update_visuals()
	ATMOS_TPROF_ADD("visuals")

	ATMOS_TPROF_MARK
	if(atmos_exposure_listeners)
		ATMOS_TPROF_COUNT("expose_signals")
		SEND_SIGNAL(src, COMSIG_TURF_EXPOSE, our_air, our_air.return_temperature())
	ATMOS_TPROF_ADD("expose")

	// Hot enough air starts creeping through the surrounding solids. The proc
	// re-checks heat_enabled itself; with the flag off this is one var read.
	ATMOS_TPROF_MARK
	if(SSair.heat_enabled && our_air.return_temperature() > MINIMUM_TEMPERATURE_START_SUPERCONDUCTION)
		ATMOS_TPROF_COUNT("superconduct_starts")
		consider_superconductivity(starting = TRUE)
	ATMOS_TPROF_ADD("superconduct")

	ATMOS_TPROF_MARK
	if(!active_hotspot && !(reaction_result & (REACTING | STOP_REACTIONS)))
		if(!our_excited_group)
			ATMOS_TPROF_COUNT("deactivations")
			if(SSair)
				SSair.remove_from_active(src)
		else if(cached_atmos_cooldown > EXCITED_GROUP_INDIVIDUAL_REST_CYCLES)
			ATMOS_TPROF_COUNT("solo_rests")
			// Stalled for a full rest window inside a live group: rest this
			// turf alone. remove_from_active here would garbage-collect the whole
			// group, letting one churning member keep thousands of settled group
			// mates paying process_cell every fire. Resting early is safe: group
			// averaging keeps covering this turf, and anything meaningful wakes
			// it back through add_to_active or a boundary poke.
			if(SSair)
				SSair.sleep_active_turf(src)

	atmos_cooldown = cached_atmos_cooldown
	ATMOS_TPROF_ADD("lifecycle")

//////////////////////////SPACEWIND/////////////////////////////

/turf/proc/consider_pressure_difference(turf/T, difference)
	return

/turf/open/consider_pressure_difference(turf/T, difference)
	if(difference <= 0)
		return
	// `|=` это линейный скан по всей очереди, а зовут нас из process_cell на каждый
	// значимый шер - на разгерметизации очередь уходит в тысячи записей, и скан
	// списывается на фазу турфов. Явный флаг вместо проверки вектора: встречные
	// вклады умеют вернуть вектор ровно в ноль, пока турф ещё стоит в очереди.
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
	// ChangeTurf может подменить турф под уже стоящей в очереди записью, и тогда
	// та же клетка попадёт в очередь второй раз. Пустой проход обходится даром
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
	// Almost every tile in a decompression or fire front is bare floor. Both
	// locate() calls scan the contents list and the Copy() allocates, all for a
	// loop that has nothing to iterate - skip the lot on an empty tile.
	if(length(contents))
		var/multiplier = 1
		if(locate(/obj/structure/rack) in src)
			multiplier *= 0.1
		else if(locate(/obj/structure/table) in src)
			multiplier *= 0.2
		// Copied because experience_pressure_difference() sleeps (throw_at/step),
		// which can mutate the tile's contents mid-iteration.
		// Бюджет на проход: MC_TICK_CHECK стоит только между турфами, и завал из
		// сотен предметов после взрыва обрабатывался атомарным куском по 300+мс
		// (раунд 9911). Остаток дожуют следующие проходы - ветер держит турф в
		// очереди, пока перепад жив.
		var/budget = HIGH_PRESSURE_MOVES_PER_TURF
		for(var/atom/movable/M as anything in contents.Copy())
			if(!M.anchored && !M.pulledby && M.last_high_pressure_movement_air_cycle < SSair.times_fired && (M.flags_1 & INITIALIZED_1) && !QDELETED(M))
				M.experience_pressure_difference(pressure_difference * multiplier, pressure_direction, 0, pressure_specific_target)
				budget--
				if(budget <= 0)
					break

	if(pressure_difference > 100 && world.time >= next_space_wind_at)
		next_space_wind_at = world.time + SPACE_WIND_VISUAL_COOLDOWN
		new /obj/effect/temp_visual/dir_setting/space_wind(src, pressure_direction, clamp(round(sqrt(pressure_difference) * 2), 10, 255))

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
	/// Группа стравливалась в космос (хотя бы один член прошёл вент-ветку
	/// process_cell). Ниже порога видимости compare() (MINIMUM_MOLES_DELTA_TO_MOVE)
	/// пара больше не обменивается ничем, поэтому тёплые огрызки газа во
	/// внутренних турфах разгерметизированной комнаты сами остыть уже не могут, а
	/// брейкдаун, усредняя моль-взвешенно, размазал бы их тепло по всей зоне.
	/// Для таких групп snap_vented_wisp() приводит подпороговые остатки к TCMB -
	/// комната, открытая в космос, оседает холодной, как и до оптимизаций.
	/// Флаг не снимается до смерти датума: заваренная обратно комната либо
	/// пересобирает группу заново (флаг чистый), либо быстро выводит члены за
	/// порог молей, где snap не трогает ничего.
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
	// The turf leaves this proc awake: count it unless it is already an awake
	// member of this very group (re-adding one must not double count).
	if(T.excited_group != src || !T.excited)
		awake_members++
	turf_list |= T
	T.excited_group = src
	// `excited` is the membership flag SSair.add_to_active() trusts to skip its
	// linear rescan of the active list, so marking a turf awake here has to put
	// it in that list too. Every production caller already passes a turf that is
	// being processed (so it is listed and this is a no-op); the write exists so
	// the flag can never lie, which is exactly what the fast path depends on.
	if(!T.excited)
		T.excited = TRUE
		if(SSair)
			SSair.list_active_turf(T)
	reset_cooldowns()

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
			turf_list |= T
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
			E.turf_list |= T
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
	// Every accumulator field below is written in one block in self_breakdown()
	// together with breakdown_stage, and cleared in one block here and in
	// finish_breakdown(), so a zero stage means there is nothing to drop. The
	// early out matters because reset_cooldowns() funnels through here and is
	// called for every significant share of every active turf every fire - two
	// dozen pointless writes per call, thousands of calls per fire under a fire.
	if(!breakdown_stage)
		return
	#ifdef ATMOS_HEADLESS_BENCH
	if(breakdown_stage && SSair)
		SSair.atmos_headless_bench_record_breakdown(headless_breakdown_members, world.time - headless_breakdown_started, headless_breakdown_slices, FALSE)
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

/datum/excited_group/proc/finish_breakdown()
	#ifdef ATMOS_HEADLESS_BENCH
	if(breakdown_stage && SSair)
		SSair.atmos_headless_bench_record_breakdown(headless_breakdown_members, world.time - headless_breakdown_started, headless_breakdown_slices, TRUE)
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
	breakdown_cooldown = 0

/// One SSair group-stage step: advance both cooldowns and run whichever
/// lifecycle event is due. Kept as a proc so tests can drive the exact
/// stage behavior.
/datum/excited_group/proc/tick_lifecycle()
	if(breakdown_stage)
		// The VOLATILE_REACTION gate below only ran when this breakdown STARTED.
		// A resumable breakdown spans many real ticks, and a fire ignited
		// mid-flight (welder, spark, bomb) would still get averaged across the
		// group by the pending write stages - abort instead; cancel_breakdown
		// is built for exactly this (next attempt restarts from current air).
		if(turf_reactions & VOLATILE_REACTION)
			turf_reactions = NO_REACTION
			cancel_breakdown()
			return TRUE
		// Flags are per-air-pass (see var docs); consume them on this path too
		// so a reaction seen several fires ago cannot gate a decision made
		// after the breakdown completes.
		turf_reactions = NO_REACTION
		return self_breakdown(slice_budget = EXCITED_GROUP_BREAKDOWN_SLICE)
	// A group with no awake members can generate no new deltas on its own:
	// every member idled through a full rest window, and any external change
	// wakes its member back through add_to_active. Waiting out the rest of the
	// dismantle window would just keep re-averaging an already-quiet room.
	// The incremental counter replaces a full turf_list scan here - a permanent
	// O(N) per-fire tax once a perpetual group grows large. Drift from exotic
	// paths (turf type changes under a live group) only ever delays this
	// dismantle until self_breakdown recounts it exactly.
	if(awake_members <= 0)
		dismantle()
		return TRUE
	// A live fire on a member defers averaging (tg VOLATILE_REACTION gate):
	// breakdown mid-burn smears the hotspot's heat across the whole group and
	// can snuff or teleport the fire. A long burn still needs the settled-member
	// bookkeeping breakdown provides (giant-group churn control), so at the
	// ceiling we evict resting members WITHOUT averaging - the fire itself is
	// never touched (tg defers indefinitely; we only add the eviction).
	// Any reaction at all blocks dismantle.
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

/// Волатильный потолок: контроль роста turf_list без усреднения газа.
/// Вечное горение (горелка ТЭГ, плазменный пожар в коридоре) держит группу
/// живой бесконечно, а единственный штатный выход осевших членов из turf_list -
/// self_breakdown, который размазал бы топливо и жар по группе. Здесь осевшие
/// просто выселяются с их текущим газом: любой реальный будущий дельта-обмен
/// вернёт их через обычные share-пути. Заодно точный пересчёт awake_members
/// (самолечение дрейфа инкрементального счётчика, как в self_breakdown).
/datum/excited_group/proc/evict_settled_members()
	var/awake_recount = 0
	var/list/to_evict = list()
	for(var/turf/open/T as anything in turf_list)
		if(!istype(T))
			continue
		if(T.excited)
			awake_recount++
			continue
		to_evict += T
	awake_members = awake_recount
	for(var/turf/open/T as anything in to_evict)
		turf_list -= T
		if(T.excited_group == src)
			T.excited_group = null
	breakdown_cooldown = 0

/// Подпороговый тёплый остаток в стравленной в космос зоне приводится к TCMB.
///
/// Ниже MINIMUM_MOLES_DELTA_TO_MOVE compare() перестаёт видеть пару вовсе, то
/// есть у такого огрызка нет НИ ОДНОГО пути остыть: обычные share его не берут,
/// вент-ветка достаёт только турфы, граничащие с космосом напрямую. До
/// оптимизаций зону сходил в холод вечный черн (комната у пробоины не засыпала
/// никогда) - теперь его нет, и тепло надо снимать в точках оседания зоны.
/// Зовётся из обоих брейкдаунов ДО слияния в ведро (иначе моль-взвешенное
/// усреднение размажет тепло огрызка по пустым турфам всей комнаты) и из
/// dismantle() (группа может расформироваться и без финального брейкдауна).
/// Планетарные члены не трогаются: их держит шаблон неба, а не космос.
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
					if(!T.air)
						continue
					if(breakdown_space_is_all_consuming && istype(T.air, /datum/gas_mixture/immutable/space))
						breakdown_space_in_group = TRUE
					snap_vented_wisp(T)
					var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
					var/datum/gas_mixture/bucket_mix = breakdown_bucket_mixes[bucket_key]
					if(!bucket_mix)
						bucket_mix = new
						breakdown_bucket_mixes[bucket_key] = bucket_mix
					bucket_mix.merge(T.air)
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
					var/bucket_key = T.planetary_atmos ? T.initial_gas_mix : ""
					var/datum/gas_mixture/bucket_mix = breakdown_bucket_mixes[bucket_key]
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
						SSair.add_to_active(T, FALSE, wake_machines = FALSE)
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
		// Группа может расформироваться и не дожив до брейкдауна (awake_members
		// упал до нуля раньше EXCITED_GROUP_BREAKDOWN_CYCLES) - тёплые огрызки
		// стравленной зоны снимаем и здесь, иначе они заснут тёплыми навсегда.
		if(T.air)
			snap_vented_wisp(T)
		// dismantle вызывается ровно тогда, когда awake_members упал до нуля -
		// то есть спящих в группе подавляющее большинство, и заходить в снятие
		// за них холостой ход. excited снимается только вместе с удалением из
		// списка, поэтому пропуск при !excited не может оставить турф активным.
		// Снятие идёт ДО сброса флага: unlist_active_turf читает его как
		// последнее слово о членстве, если индекс-подсказка разошлась.
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
