/proc/show_individual_logging_panel(mob/M, source = LOGSRC_CLIENT, type = INDIVIDUAL_ATTACK_LOG)
	if(!M || !ismob(M))
		return

	var/ntype = text2num(type)

	//Add client links
	var/list/dat = list()
	if(M.client)
		dat += "<center><p>Client</p></center>"
		dat += "<center>"
		dat += individual_logging_panel_link(M, INDIVIDUAL_ATTACK_LOG, LOGSRC_CLIENT, "Attack Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_SAY_LOG, LOGSRC_CLIENT, "Say Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_EMOTE_LOG, LOGSRC_CLIENT, "Emote Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_COMMS_LOG, LOGSRC_CLIENT, "Comms Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_OOC_LOG, LOGSRC_CLIENT, "OOC Log", source, ntype)
		dat += " | "
		dat += individual_logging_panel_link(M, INDIVIDUAL_SHOW_ALL_LOG, LOGSRC_CLIENT, "Show All", source, ntype)
		dat += "</center>"
	else
		dat += "<p> No client attached to mob </p>"

	dat += "<hr style='background:#000000; border:0; height:1px'>"
	dat += "<center><p>Mob</p></center>"
	//Add the links for the mob specific log
	dat += "<center>"
	dat += individual_logging_panel_link(M, INDIVIDUAL_ATTACK_LOG, LOGSRC_MOB, "Attack Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_SAY_LOG, LOGSRC_MOB, "Say Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_EMOTE_LOG, LOGSRC_MOB, "Emote Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_COMMS_LOG, LOGSRC_MOB, "Comms Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_OOC_LOG, LOGSRC_MOB, "OOC Log", source, ntype)
	dat += " | "
	dat += individual_logging_panel_link(M, INDIVIDUAL_SHOW_ALL_LOG, LOGSRC_MOB, "Show All", source, ntype)
	dat += "</center>"

	dat += "<hr style='background:#000000; border:0; height:1px'>"

	var/log_source = M.logging;
	if(source == LOGSRC_CLIENT && M.client)
		log_source = M.client.player_details.logging
	var/list/concatenated_logs = list()
	for(var/log_type in log_source)
		var/nlog_type = text2num(log_type)
		if(nlog_type & ntype)
			var/list/all_the_entries = log_source[log_type]
			for(var/entry in all_the_entries)
				if(entry["time"])
					var/health_info = entry["health"] ? " (HP: [entry["health"]])" : ""
					var/line = "<b>[entry["time"]] [entry["who"]]</b>[health_info]<br>[entry["what"]]<br><small>[entry["where"]]</small>"
					concatenated_logs += line
				else if(islist(entry))
					for(var/key in entry)
						concatenated_logs += "<b>[key]</b><br>[entry[key]]"
				else
					concatenated_logs += "<b>[entry]</b>"
	if(length(concatenated_logs))
		sortTim(concatenated_logs, cmp = GLOBAL_PROC_REF(cmp_text_dsc))
		dat += "<font size=2px>"
		dat += concatenated_logs.Join("<br>")
		dat += "</font>"

	var/datum/browser/popup = new(usr, "invidual_logging_[key_name(M)]", "Individual Logs", 600, 600)
	popup.set_content(dat.Join())
	popup.open()

/proc/individual_logging_panel_link(mob/M, log_type, log_src, label, selected_src, selected_type)
	var/slabel = label
	if(selected_type == log_type && selected_src == log_src)
		slabel = "<b>\[[label]\]</b>"
	//This is necessary because num2text drops digits and rounds on big numbers. If more defines get added in the future it could break again.
	log_type = num2text(log_type, MAX_BITFLAG_DIGITS)
	return "<a href='?_src_=holder;[HrefToken()];individuallog=[REF(M)];log_type=[log_type];log_src=[log_src]'>[slabel]</a>"
