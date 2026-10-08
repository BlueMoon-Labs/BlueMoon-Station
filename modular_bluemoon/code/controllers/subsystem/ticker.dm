/**
 * Механика, введённая для того, чтобы краши сервера не вызывали бесконечные форсы одного и того же режима и карты.
 * Теперь при первом голосовании за шаттл или автоэвакуации по памяти, вне зависимости от результата, карта и режим будут записаны в SSPersistence.
 */

GLOBAL_VAR_INIT(midround_recorded, FALSE)
/// Онлайн и час при сборке бюллетеня прошли порог ротации: серия режимов применяется, тип раунда идёт в историю
GLOBAL_VAR_INIT(round_counts_for_rotation, FALSE)

/datum/controller/subsystem/ticker/proc/midround_record_check()
	if(GLOB.midround_recorded)
		return
	SSpersistence.RecordDynamicType()
	SSpersistence.RecordMaps()
	SSpersistence.CollectRoundtype(FALSE)
	GLOB.midround_recorded = TRUE
	var/message = "Час пробил."
	message += " [SSmapping.config.map_name] отжила своё."
	var/combo = SSvote.check_combo()
	var/rotation_condition = ", если онлайн будет не меньше [CONFIG_GET(number/roundtype_rotation_min_players)] и раунд начнётся не ночью..."
	if(combo == ROUNDTYPE_ROTATION_HEAVY)
		message += " Экста грядёт[rotation_condition]"
	else if(combo == ROUNDTYPE_ROTATION_LIGHT)
		message += " Динамик грядёт[rotation_condition]"
	to_chat(world, span_boldwarning(message))
	message_admins("Мидраундовая запись режима и карты произведена.")
