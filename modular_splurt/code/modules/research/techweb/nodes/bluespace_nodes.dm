//Jessie Added this
/datum/techweb_node/bluespace_power_reactor
	id = "bluespace_power_reactor"
	display_name = "Bluespace Power Reactor Technology"
	description = "Even more powerful.. RADIOACTIVE POWA!!!"
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_ENGINEERING)
	prereq_ids = list("adv_power", "bluespace_power", "bluespace_holding", "joule_was_wrong")
	design_ids = list("bluespace_cell_reactor")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
