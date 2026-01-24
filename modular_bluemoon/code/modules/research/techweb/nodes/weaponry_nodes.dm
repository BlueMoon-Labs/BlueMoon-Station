
/////////////////////////weaponry tech bluemoon module/////////////////////////
/*
/datum/techweb_node/military_ammo
	id = "military_ammo"
	display_name = "Military Ammunition"
	description = "Big guns were authorized."
	prereq_ids = list("adv_weaponry", "ballistic_weapons")
	design_ids = list("mag_acr5", "mag_acr5_empty", "box_acr5_ap", "box_acr5_hp", "box_acr5_hs")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)
*/
/datum/techweb_node/e45_drum
	id = "e45_drum"
	display_name = "Enlarged ammunition storage"
	description = "When situation requires more then 12 shots."
	prereq_ids = list("advc45_ammo")
	design_ids = list("e45_drum", "e45_drum_empty", "e45_drum_taser", "e45_drum_lethal", "e45_drum_hydra", "e45_drum_ion", "e45_drum_stun", "e45_drum_laser", "e45_drum_hot", "e45_drum_trac")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

////////////////////////Upgraded weapon technology////////////////////////
/datum/techweb_node/advanced_weaponry
	id = "advanced_weaponry"
	display_name = "advanced weaponry theory"
	description = "Impresive new technoligies, just in theory."
	prereq_ids = list("adv_weaponry")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 2500)
	hidden = TRUE // Оставляю пустую ноду на будущие, буду использовать эту отправную точку для всех новых улучшений

/datum/techweb_node/advanced_weaponry/New()
	. = ..()
	boost_item_paths = typesof(/obj/item/disk/weapon_blueprint)

/////////////////////////////
//Enforcer MK59-MK62 design//
/////////////////////////////

// /datum/techweb_node/mk59
//	id = "mk59"
//	display_name = "Enhanced stabilization tools."
//	description = "Comfort in a price of size."
//	design_ids = list("mk59")
//	prereq_ids = list("advanced_weaponry", "adv_weaponry")
//	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 5000)

/datum/techweb_node/mk60
	id = "mk60"
	display_name = "Advanced guidance systems."
	description = "Replacing the bolt carrier with an improved one with a pre-installed collimator sight."
	design_ids = list("mk60")
	prereq_ids = list("advanced_weaponry", "adv_weaponry")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 7500)

/datum/techweb_node/mk62
	id = "mk62"
	display_name = "Advanced gas extraction system."
	description = "Replacing the receiver, which converts the enforcer from a pistol to a submachine gun."
	design_ids = list("mk62")
	prereq_ids = list("mk60")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)

/datum/techweb_node/vector
	id = "vector"
	display_name = "Advanced gas extraction system."
	description = "A gift from Ligt Gear & Balistic Tech. Mostly - just whole new gun in a pack."
	design_ids = list("vector")
	prereq_ids = list("mk60")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
