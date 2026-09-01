//MODULAR SPLURT CHANGES OF ALREADY EXISTING NODES
/datum/techweb_node/light_apps/New()
	var/list/extra_designs = list(
		"rld",
		"flashdark",
	)
	LAZYADD(design_ids, extra_designs)
	. = ..()
