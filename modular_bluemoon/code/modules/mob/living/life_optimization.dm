/// Returns TRUE if any player is within given distance on the same z-level.
/// Used for Life() throttling of clientless mobs far from players.
/mob/living/proc/has_nearby_player(distance = NEARBY_LIVING_DISTANCE)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return FALSE

	if(SSspatial_grid.initialized)
		return SSspatial_grid.has_living_client_in_range(our_turf, distance)

	// Фолбэк до инициализации грида: старый обход игроков z-уровня
	var/our_z = our_turf.z
	if(!islist(SSmobs.clients_by_zlevel) || our_z > SSmobs.clients_by_zlevel.len)
		return FALSE
	var/list/players_on_z = SSmobs.clients_by_zlevel[our_z]
	if(!length(players_on_z))
		return FALSE
	for(var/mob/player as anything in players_on_z)
		if(get_dist(our_turf, player) <= distance)
			return TRUE
	return FALSE

// ============================================================================
// SSmobs Life() optimization helpers (levers 1 & 4). Kept here to isolate the
// change and keep the throttle in life.dm readable.
// ============================================================================

/// Lever 4: how many SSmobs fires a cached has_nearby_player() result is reused.
/// A player moving in shifts a clientless mob's Life granularity by at most this
/// many fires (2 fires = 4s); AI wake stays event-driven via grid signals.
#define NEARBY_PLAYER_CACHE_TTL_FIRES 2

/// TRUE if a player was near on the last recompute (see has_nearby_player_cached).
/mob/living/var/cached_nearby_player = FALSE
/// SSmobs times_fired at the last has_nearby_player() recompute (0 = never).
/mob/living/var/cached_nearby_player_fire = 0

/// Lever 4: memoized has_nearby_player(). has_nearby_player() hits the spatial
/// grid, but the SSmobs throttle only ACTS on the result every 4th/15th fire -
/// recomputing it every fire for hundreds of clientless mobs was pure overhead.
/// Caches for NEARBY_PLAYER_CACHE_TTL_FIRES fires. Uses the default range.
/mob/living/proc/has_nearby_player_cached(times_fired)
	if(!cached_nearby_player_fire || (times_fired - cached_nearby_player_fire) >= NEARBY_PLAYER_CACHE_TTL_FIRES)
		cached_nearby_player = has_nearby_player()
		cached_nearby_player_fire = times_fired
	return cached_nearby_player

/// Как часто кэтч-олл update_mobility() в Life прогоняется принудительно, даже
/// если подпись входов не изменилась. Страховка от источников, которые меняют
/// мобильность мимо и update_mobility(), и подписи (4 фаера = 8 секунд).
#define LIFE_MOBILITY_FORCE_CADENCE 4

/// Подпись входов update_mobility(): только прямые чтения переменных, никаких
/// вызовов процов - иначе проверка стоила бы столько же, сколько сам пересчёт.
/// Ловит смену stat, лежачести, пристёгнутости, захвата, боевых флагов, состава
/// статус-эффектов, трейтов и конечностей - то есть всё, из чего update_mobility
/// считает свои флаги. Остальное подбирает LIFE_MOBILITY_FORCE_CADENCE.
/mob/living/proc/mobility_input_signature()
	return "[stat];[resting];[lying];[buckled ? 1 : 0];[pulledby ? pulledby.grab_state : -1];[combat_flags];[mobility_flags];[length(status_effects)];[length(status_traits)]"

/// Кэтч-олл мобильности из Life: полный update_mobility() только когда подпись
/// входов поехала или подошёл принудительный прогон. Явные вызовы
/// update_mobility() из мест, которые меняют состояние, этим НЕ затрагиваются.
/mob/living/proc/update_mobility_if_dirty(times_fired)
	var/signature = mobility_input_signature()
	if(signature == cached_mobility_signature && ((times_fired + life_periodic_phase) % LIFE_MOBILITY_FORCE_CADENCE) != 0)
		return FALSE
	update_mobility()
	//подпись берём ПОСЛЕ пересчёта: update_mobility правит mobility_flags и lying,
	//иначе следующий тик считал бы её изменившейся и гейт не работал бы вовсе
	cached_mobility_signature = mobility_input_signature()
	return TRUE

/// Снимает бронь бакета: ближайший проход SSmobs обязан зайти в Life().
/// Зовётся из переходов, которые делают моба срочным для троттла в life.dm -
/// смена stat, поджиг, появление цели у ИИ. Без этого моб, отложенный на 4/15
/// фаеров вперёд, не заметил бы, что перестал быть "спокойным дальним".
/mob/living/proc/wake_life()
	life_next_fire = 0

/// Lever 1 exemption: TRUE when a dead body still needs full per-fire Life
/// because it carries chemistry that acts on the dead. Base living mobs never do.
/mob/living/proc/dead_life_is_time_sensitive()
	return FALSE

/// A dead carbon with a REAGENT_DEAD_PROCESS reagent - exactly what
/// handle_death() processes (revival/dead-body chemistry) - must not be
/// throttled. No BlueMoon reagent sets this flag today, so this is a
/// correct-by-construction guard that stays right if one ever does.
/mob/living/carbon/dead_life_is_time_sensitive()
	if(!reagents)
		return FALSE
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		if(reagent.chemical_flags & REAGENT_DEAD_PROCESS)
			return TRUE
	return FALSE
