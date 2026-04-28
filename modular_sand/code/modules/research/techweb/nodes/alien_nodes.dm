/datum/techweb_node/alien_stockparts
	id = "alien_stockparts"
	display_name = "Theoretical Engineering"
	description = "A merging of unknown alien designs, bluespace mannagement, and xenobiology."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_ENGINEERING)
	prereq_ids = list("alientech", "emp_super", "alien_engi")
	design_ids = list("super_quadultra_micro_laser", "dark_matter_bin", "atto_mani", "unilatera_triphasic_scanning", "giga_capacitor", "ultimatebeaker")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
