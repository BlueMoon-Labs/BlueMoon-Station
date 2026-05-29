// Удаление рекорда тетриса
/datum/award/score/highscore/tetris/proc/admin_delete_record(mob/admin_mob, target_ckey)
	target_ckey = ckey(target_ckey)
	if(!target_ckey || !high_scores[target_ckey])
		return FALSE

	if(SSdbcore.Connect())
		var/datum/db_query/Q = SSdbcore.NewQuery(
			"DELETE FROM [format_table_name("achievements")] WHERE ckey = :ckey AND achievement_key = :achievement_key",
			list("ckey" = target_ckey, "achievement_key" = TETRIS_SCORE)
		)
		if(!Q.warn_execute())
			qdel(Q)
			return FALSE
		qdel(Q)
	else
		return FALSE

	high_scores.Remove(target_ckey)

	if(GLOB.player_details[target_ckey])
		var/datum/player_details/PD = GLOB.player_details[target_ckey]
		if(PD.achievements?.data)
			PD.achievements.data[/datum/award/score/highscore/tetris] = 0
			PD.achievements.original_cached_data[/datum/award/score/highscore/tetris] = 0

	log_admin("[key_name(admin_mob)] удалил рекорд тетриса игрока [target_ckey].")
	message_admins("[key_name_admin(admin_mob)] удалил рекорд тетриса игрока [target_ckey].")
	return TRUE
