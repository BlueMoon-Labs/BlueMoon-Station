GLOBAL_VAR_INIT(admin_notice, "") // Admin notice that all clients see when joining the server

GLOBAL_VAR_INIT(timezoneOffset, 0) // The difference betwen midnight (of the host computer) and 0 world.ticks.

GLOBAL_VAR_INIT(year, time2text(world.realtime,"YYYY"))
GLOBAL_VAR_INIT(year_integer, text2num(year)) // = 2013???


	// For FTP requests. (i.e. downloading runtime logs.)
	// However it'd be ok to use for accessing attack logs and such too, which are even laggier.
GLOBAL_VAR_INIT(fileaccess_timer, 0)

GLOBAL_DATUM_INIT(data_core, /datum/datacore, new)

/// Общий множитель выработки солнечных панелей. Ведут его явления космической погоды:
/// ионная буря кратно поднимает, поле микрообломков сажает осевшей пылью.
/// Множитель, а не проход по панелям: список панелей пришлось бы хранить и чистить,
/// а построенная посреди явления панель всё равно осталась бы вне его.
GLOBAL_VAR_INIT(solar_output_multiplier, 1)

/// Разброс точки прибытия, который космическая погода добавляет блюспейс-телепортации.
/// Ноль вне явления. Ведёт его блюспейс-шторм.
GLOBAL_VAR_INIT(bluespace_teleport_noise, 0)
/// Заглушен ли блюспейс-канал целиком. Ведёт его блюспейс-интерфаза.
/// Принудительная телепортация (forced) проходит и через неё: ей затыкают дыры вроде
/// вытаскивания игрока из сломанной геометрии, и глушить её значило бы менять баг на баг.
GLOBAL_VAR_INIT(bluespace_teleport_blocked, FALSE)

GLOBAL_VAR_INIT(CELLRATE, 0.002)  // conversion ratio between a watt-tick and kilojoule, dimensionless, kilojoules/watt-tick
GLOBAL_VAR_INIT(CHARGELEVEL, 0.001) // Cap for how fast cells charge, as a percentage-per-tick (.001 means cellcharge is capped to 1% per second)

GLOBAL_LIST_EMPTY(powernets)

GLOBAL_VAR_INIT(bsa_unlock, FALSE)	//BSA unlocked by head ID swipes

GLOBAL_LIST_EMPTY(player_details)	// ckey -> /datum/player_details

GLOBAL_LIST_EMPTY(clientless_round_timeouts)	// ckey -> time that ckey can rejoin round

// All religion stuff
GLOBAL_VAR(religion)
GLOBAL_VAR(deity)
GLOBAL_VAR(bible_name)
GLOBAL_VAR(bible_icon_state)
GLOBAL_VAR(bible_item_state)


GLOBAL_VAR_INIT(internal_tick_usage, 0.2 * world.tick_lag)
