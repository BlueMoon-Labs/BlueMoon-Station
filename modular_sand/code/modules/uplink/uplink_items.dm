/datum/uplink_item
	var/surplus_nullcrates //Chance of being included in null crates. null = pull from surplus

/datum/uplink_item/New()
	if(isnull(surplus_nullcrates))
		surplus_nullcrates = surplus
	. = ..()

/datum/uplink_item/device_tools/arm
	name = "Additional Arm"
	desc = "Дополнительная рука, собранная с рабов, захваченных Syndicate. В комплекте с имплантером."
	item = /obj/item/extra_arm
	cost = 8

// Made craftable, and no longer illegal
/datum/uplink_item/ammo/revolver
	illegal_tech = FALSE
