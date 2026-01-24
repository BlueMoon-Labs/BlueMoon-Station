
/////////////////////////reactor + vortex cells tech/////////////////////////
/datum/techweb_node/joule_was_wrong
	id = "joule_was_wrong"
	display_name = "Infinite Power Theory"
	description = "Seems like Dr. Prescott Joule was wrong. We got energy-replenishment data after researching into slime power cells. It does have a lot of potential, but more to do."
	prereq_ids = list("datatheory")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 1000)
	hidden = TRUE

/datum/techweb_node/joule_was_wrong/New()
	. = ..()
	boost_item_paths = typesof(/obj/item/stock_parts/cell/high/slime, /obj/item/stock_parts/cell/high/slime/hypercharged)

/datum/techweb_node/vortex_cell
	id = "vortex_cell"
	display_name = "Vortex Power Cell"
	description = "The pinacle of power storage science. The One cell that can hold and replenish from nothing, for true... And without drawbacks."
	prereq_ids = list("bluespace_power_reactor", "alien_stockparts")
	design_ids = list("vortex_cell")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)
