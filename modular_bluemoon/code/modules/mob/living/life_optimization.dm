/// Returns TRUE if any player is within given distance on the same z-level.
/// Used for Life() throttling of clientless mobs far from players.
/mob/living/proc/has_nearby_player(distance = NEARBY_LIVING_DISTANCE)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return FALSE
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
