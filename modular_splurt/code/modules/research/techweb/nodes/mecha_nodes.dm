/datum/techweb_node/savannah_ivanov
	id = "mecha_savannah_ivanov"
	display_name = "EXOSUIT: Savannah-Ivanov"
	description = "Savannah-Ivanov exosuit designs"
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("adv_mecha", "weaponry", "exp_tools")
	design_ids = list(
		"savannah_ivanov_chassis",
		"savannah_ivanov_torso",
		"savannah_ivanov_head",
		"savannah_ivanov_left_arm",
		"savannah_ivanov_left_leg",
		"savannah_ivanov_right_arm",
		"savannah_ivanov_right_leg",
		"savannah_ivanov_armor",
		"savannah_ivanov_main",
		"savannah_ivanov_peri",
		"savannah_ivanov_targ",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
