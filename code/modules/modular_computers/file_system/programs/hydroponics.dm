/**
 * Hydroponics Monitor - PDA cartridge program
 *
 * Checks status of hydroponics trays.
 */
/datum/computer_file/program/hydroponics
	filename = "hydro"
	filedesc = "Hydro Monitor"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "generic"
	extended_desc = "This program monitors hydroponics trays and provides plant status information."
	requires_ntnet = FALSE
	transfer_access = null
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	available_on_ntnet = FALSE
	tgui_id = "NtosHydroponics"
	program_icon = "seedling"

/datum/computer_file/program/hydroponics/ui_data(mob/user)
	var/list/data = get_header_data()

	var/list/trays = list()
	for(var/obj/machinery/hydroponics/H in world)
		var/plant_name = "Empty"
		var/plant_health = 0
		var/plant_max = 0
		var/water = 0
		var/nutri = 0
		var/max_nutri = 0
		if(H.myseed)
			plant_name = H.myseed.plantname
			plant_health = H.plant_health
			plant_max = H.myseed.endurance
		water = H.waterlevel
		nutri = H.reagents.total_volume
		max_nutri = H.maxnutri

		trays += list(list(
			"name" = H.name,
			"area" = get_area_name(H, TRUE),
			"plant" = plant_name,
			"health" = plant_health,
			"max_health" = plant_max,
			"water" = water,
			"nutri" = nutri,
			"max_nutri" = max_nutri,
			"harvest" = H.harvest,
			"weed_level" = H.weedlevel,
			"pest_level" = H.pestlevel,
		))

	data["trays"] = trays
	return data
