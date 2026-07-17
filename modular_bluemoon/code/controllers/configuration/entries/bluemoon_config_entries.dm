/datum/config_entry/flag/ssdecay_disabled

/// Roundstart decay: activation chance by config value (1=10%, 2=32%, 3=53%, 4=75%, 5=50% + random intensity 1-4).
/datum/config_entry/number/ssdecay_intensity
	default = 5
	max_val = 5
	min_val = 1

/// Defines whether or not mentors can see ckeys alongside mobnames.
/datum/config_entry/flag/mentors_mobname_only

/// Defines whether the server uses the legacy mentor system with mentors.txt or the SQL system.
/datum/config_entry/flag/mentor_legacy_system
	protection = CONFIG_ENTRY_LOCKED

/datum/config_entry/string/bot_name

/datum/config_entry/string/bot_icon

/datum/config_entry/string/roundend_status_enabled

/datum/config_entry/string/roundend_chat_command_enabled

/datum/config_entry/str_list/randomizing_message_for_video
	default = list()

/datum/config_entry/string/chat_suspect_login

/datum/config_entry/number/chaos_for_a_hard_dynamic
	default = 200
	integer = TRUE
	min_val = 0

/datum/config_entry/number/chaos_for_a_medium_dynamic
	default = 100
	integer = TRUE
	min_val = 0
