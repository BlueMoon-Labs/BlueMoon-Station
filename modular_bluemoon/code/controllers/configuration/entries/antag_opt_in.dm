/// Уровень согласия быть целью антагонистов у персонажа, который его не выбирал.
/datum/config_entry/number/antag_opt_in_default_level
	default = ANTAG_OPT_IN_ROUND_REMOVE
	integer = TRUE
	min_val = ANTAG_OPT_IN_NOT_TARGET
	max_val = ANTAG_OPT_IN_ROUND_REMOVE

/// Нижний порог для СБ на своей работе.
/datum/config_entry/number/antag_opt_in_security_min
	default = ANTAG_OPT_IN_KILL
	integer = TRUE
	min_val = ANTAG_OPT_IN_NOT_TARGET
	max_val = ANTAG_OPT_IN_ROUND_REMOVE

/// Нижний порог для командования на своей работе.
/datum/config_entry/number/antag_opt_in_command_min
	default = ANTAG_OPT_IN_KILL
	integer = TRUE
	min_val = ANTAG_OPT_IN_NOT_TARGET
	max_val = ANTAG_OPT_IN_ROUND_REMOVE

/// Нижний порог для игрока, который вышел из лобби с включённой антаг-ролью из экипажа.
/datum/config_entry/number/antag_opt_in_antag_enabled_min
	default = ANTAG_OPT_IN_KILL
	integer = TRUE
	min_val = ANTAG_OPT_IN_NOT_TARGET
	max_val = ANTAG_OPT_IN_ROUND_REMOVE
