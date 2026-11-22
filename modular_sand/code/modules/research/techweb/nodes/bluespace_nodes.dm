/datum/techweb_node/cryptominer
	id = "cryptominer"
	display_name = "Cryptocurrency Mining"
	description = "Используйте силу криптовалюты, чтобы добывать кредиты для грузовой службы — медленно."
	informing_radio_channels = list(RADIO_CHANNEL_SUPPLY)
	prereq_ids = list("bluespace_mining")
	design_ids = list("cryptominer")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/cryptominersyndie
	id = "cryptominersyndie"
	display_name = "Illegal Cryptocurrency Mining"
	description = "Используйте силу блюспейса, чтобы добывать кредиты для грузовой службы — медленно."
	informing_radio_channels = list(RADIO_CHANNEL_SUPPLY)
	prereq_ids = list("cryptominer","syndicate_basic")
	design_ids = list("cryptominersyndie")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/computermath
	id = "computermath"
	display_name = "Problem Computer"
	description = "Решайте проблемы ради грузовых кредитов или очков исследований."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_SUPPLY)
	prereq_ids = list("base")
	design_ids = list("computermath")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)

/datum/techweb_node/bs_mining
	id = "bluespace_mining"
	display_name = "Bluespace Mining Technology"
	description = "Используйте силу блюспейса, чтобы создавать материалы из ничего, медленно. Для работы требуется ядро блюспейса."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("practical_bluespace", "adv_mining", "anomaly_research")
	design_ids = list("bluespace_miner")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/shuttle_route_upgrade_hyper/New()
	design_ids += "disk_shuttle_smoothsail"
	. = ..()

/datum/techweb_node/bluespace_portal/New()
	design_ids += "borg_upgrade_bsrpd"
	design_ids += "bsrpd"
	. = ..()

/datum/techweb_node/basic_shuttle_tech/New()
	design_ids += "borg_upgrade_shuttlemaking"
	. = ..()
