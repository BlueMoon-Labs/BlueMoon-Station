
/////////////////////////reactor + vortex cells tech/////////////////////////
/datum/techweb_node/joule_was_wrong
	id = "joule_was_wrong"
	display_name = "Infinite Power Theory"
	description = "Похоже, доктор Прескотт Джоуль ошибался. Мы получили данные о восстановлении энергии после исследований слизевых элементов питания. Потенциал большой, но работы ещё много."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("datatheory")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	hidden = TRUE

/datum/techweb_node/joule_was_wrong/New()
	. = ..()
	boost_item_paths = typesof(/obj/item/stock_parts/cell/high/slime, /obj/item/stock_parts/cell/high/slime/hypercharged)

/datum/techweb_node/vortex_cell
	id = "vortex_cell"
	display_name = "Vortex Power Cell"
	description = "Вершина науки о накоплении энергии. Та самая ячейка, которая может хранить и восполнять энергию из ничего — правда... и без недостатков."
	informing_radio_channels = list(RADIO_CHANNEL_SCIENCE)
	prereq_ids = list("bluespace_power_reactor", "alien_stockparts")
	design_ids = list("vortex_cell")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
