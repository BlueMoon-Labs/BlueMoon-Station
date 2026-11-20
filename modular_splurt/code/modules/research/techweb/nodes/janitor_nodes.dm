/datum/techweb_node/ultispray
	id = "ultispray"
	display_name = "Alien Janitoring"
	description = "Убирайте беспорядок так, как похитители убирают свидетелей"
	informing_radio_channels = list(RADIO_CHANNEL_SERVICE)
	prereq_ids = list("alien_stockparts", "bspspray")
	design_ids = list("ultimatespray")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1500)
