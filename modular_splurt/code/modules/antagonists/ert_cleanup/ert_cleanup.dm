//This file contains everything to spawn ERT for cleaning up a nuclear reactor meltdown, if those things could actually explode

//ERT
/obj/item/clothing/gloves/color/yellow/nuclear_sanitation
	name = "thick gloves"
	desc = "A pair of yellow gloves. They help protect from radiation."
	siemens_coefficient = 0.85
	permeability_coefficient = 0.7
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = GLOVES_MAX_TEMP_PROTECT
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 20, "rad" = 100, "fire" = 0, "acid" = 50)

/obj/item/clothing/shoes/jackboots/nuclear_sanitation
	desc = "A pair of jackboots, sewn with special material to help protect from radiation."
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 5, "bomb" = 5, "bio" = 0, "rad" = 100, "fire" = 10, "acid" = 70)

/obj/item/clothing/suit/space/hardsuit/rd/hev/no_sound/nuclear_sanitation
	name = "improved radiation suit"
	desc = "A radiation suit that's been manufactured for being a hardsuit. It provides complete protection from radiation and bio contaminants."
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/rd/hev/no_scanner/nuclear_sanitation
	slowdown = 0.25		//removes 30% of the slowness. This is actually a considerable amount

/obj/item/clothing/head/helmet/space/hardsuit/rd/hev/no_scanner/nuclear_sanitation
	name = "improved radiation hood"
	desc = "It protects from radiation and bio contaminants."
