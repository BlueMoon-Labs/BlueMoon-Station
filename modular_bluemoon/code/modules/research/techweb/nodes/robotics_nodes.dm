// Исследование для крутых роботехнических штук
/datum/techweb_node/superior_robotics
	id = "sup_robotics"
	display_name = "Superior Robotics"
	description = "Glory to Omnissiah!"
	prereq_ids = list("adv_biotech", "adv_bluespace", "adv_robotics")
	design_ids = list("roboliq")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

/datum/techweb_node/synthcooler_adv
	id = "cooler_adv"
	display_name = "Advanced PCU"
	description = "Now with uranium elements for your needs."
	prereq_ids = list("adv_power", "adv_robotics")
	design_ids = list("cooler_advanced")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

// Модули для киборгов

/datum/techweb_node/cyborg_upg_advmedtools
	id = "cyborg_upg_advmedtools"
	display_name = "Cyborg Upgrades: Advanced Surgery Tools"
	description = "We can advance their techonology while re-managing modules for space saving."
	prereq_ids = list("advance_surgerytools", "cyborg_upg_med")
	design_ids = list("borg_upgrade_advmedtools")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 4000)

/datum/techweb_node/cyborg_upg_syndircd
	id = "cyborg_upg_syndircd"
	display_name = "Cyborg Upgrades: Advanced RCD"
	description = "Utilizing Syndicate sabotaging technology, the RCD module of our engineering cyborgs can be improved."
	prereq_ids = list("cyborg_upg_util", "exp_tools", "syndicate_basic")
	design_ids = list("borg_upgrade_syndircd")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)

/datum/techweb_node/borg_upgrade_advgasanalyzer
	id = "borg_upgrade_advgasanalyzer"
	display_name = "Cyborg Upgrades: Advanced Gas Analyzer Module"
	description = "Atmospheric analyzer would implement efficiency into cyborg duty with ability to range-scan gas properties."
	prereq_ids = list("cyborg_upg_util", "exp_tools")
	design_ids = list("borg_upgrade_advgasanalyzer")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 3500)
