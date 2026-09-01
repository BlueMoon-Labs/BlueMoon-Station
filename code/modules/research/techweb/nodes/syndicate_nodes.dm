
/datum/techweb_node/syndicate_basic
	id = "syndicate_basic"
	display_name = "Illegal Technology"
	description = "Dangerous research used to create dangerous objects."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	prereq_ids = list("adv_engi", "adv_weaponry", "explosive_weapons")
	design_ids = list("decloner", "borg_syndicate_module", "suppressor", "largecrossbow", "donksofttoyvendor", "donksoft_refill", "syndiesleeper", "inducer_syn", "piercesyringe") // - ci-xray
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 10000)
	hidden = TRUE
	boost_item_paths = list(
		/obj/item/card/emag = null,
		/obj/item/card/id/inteq = null,
		/obj/item/melee/transforming/plasmasword = null,
		/obj/item/plasmascythe = null,
		/obj/item/melee/transforming/energy/sword/saber = null,
		/obj/item/dualsaber = null,
		/obj/item/dualsaber/hypereutactic = null,
		/obj/item/shield/energy = null,
		/obj/item/shield/inteq_energy = null,
		/obj/item/clothing/suit/space/hardsuit/syndi = null,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite = null,
		/obj/item/clothing/suit/space/hardsuit/shielded/syndi = null,
		/obj/item/clothing/suit/space/hardsuit/contractor = null,
		/obj/item/modular_computer/tablet/syndicate_contract_uplink = null,
		/obj/item/modular_computer/tablet/syndicate_contract_uplink/preset/uplink = null,
		/obj/item/melee/classic_baton/telescopic/contractor_baton = null,
	)

/datum/techweb_node/advanced_illegal_ballistics
	id = "advanced_illegal_ballistics"
	display_name = "Advanced Non-Standard Ballistics"
	description = "Ballistic ammunition for non-standard firearms. Usually the ones you don't have nor want to be involved with."
	informing_radio_channels = list(RADIO_CHANNEL_SECURITY)
	design_ids = list("10mm","10mmap","10mminc","10mmhp", /*"sl357","sl357ap", "sl357dumdum",*/ "m45","bolt_clip","m10apbox","m10firebox","m10hpbox", "10mm_large", "10mm_large_soporific", "combatinducer")
	prereq_ids = list("ballistic_weapons","syndicate_basic","explosive_weapons")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = 25000) //This gives sec lethal mags/clips for guns from traitors, space, or anything in between.

//Helpers for debugging/balancing the techweb in its entirety!

/proc/total_techweb_points()
	var/list/datum/techweb_node/processing = list()
	for(var/i in subtypesof(/datum/techweb_node))
		processing += new i
	var/datum/techweb/TW = new
	TW.research_points = list()
	for(var/i in processing)
		var/datum/techweb_node/TN = i
		TW.add_point_list(TN.research_costs)
	return TW.research_points

/proc/total_techweb_points_printout()
	var/list/datum/techweb_node/processing = list()
	for(var/i in subtypesof(/datum/techweb_node))
		processing += new i
	var/datum/techweb/TW = new
	TW.research_points = list()
	for(var/i in processing)
		var/datum/techweb_node/TN = i
		TW.add_point_list(TN.research_costs)
	return TW.printout_points()
