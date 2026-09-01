/// Браузер всех серверных логов в data/logs/.
/client/proc/getserverlogs()
	set name = "Get Server Logs"
	set desc = "View/retrieve logfiles."
	set category = "Admin.Game"

	open_log_viewer(list())

/// Браузер логов текущего раунда.
/client/proc/getcurrentlogs()
	set name = "Get Current Logs"
	set desc = "View/retrieve logfiles for the current round."
	set category = "Admin.Game"

	open_log_viewer(admin_log_segments_for_current_round())
