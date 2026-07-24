/// Returns TRUE if any player is within given distance on the same z-level.
/// Used for Life() throttling of clientless mobs far from players.
/mob/living/proc/has_nearby_player(distance = NEARBY_LIVING_DISTANCE)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return FALSE

	if(SSspatial_grid.initialized)
		// Спатиал-грид: перебираем клиент-мобов из ячеек вокруг нас вместо
		// всех игроков z-уровня. В CLIENTS-канале есть и обсерверы - для
		// паритета со старой семантикой (clients_by_zlevel хранил только
		// живых) фильтруем по isliving.
		for(var/mob/player as anything in SSspatial_grid.orthogonal_range_search(our_turf, SPATIAL_GRID_CONTENTS_TYPE_CLIENTS, distance))
			if(!isliving(player))
				continue
			if(get_dist(our_turf, player) <= distance)
				return TRUE
		return FALSE

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
