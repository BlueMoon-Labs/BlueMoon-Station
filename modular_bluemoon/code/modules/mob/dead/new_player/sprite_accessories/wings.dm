/datum/sprite_accessory/deco_wings/wyvern
	icon = 'modular_bluemoon/icons/mob/human/wings_96x34.dmi'
	icon_state = "wyvern"
	mutant_part_string = "wings"
	center = TRUE
	dimension_x = 96
	dimension_y = 34 // BRUH
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_FRONT_LAYER)
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
	upgrade_to = SPECIES_WINGS_WYVERN
	extra = TRUE
	extra2 = TRUE

/datum/sprite_accessory/deco_wings/wyvern/folded
	name = "Wyvern"

/datum/sprite_accessory/deco_wings/wyvern/spreaded
	name = "Wyvern (Spreaded)"
	mutant_part_string = "wingsopen"

/datum/sprite_accessory/deco_wings/wyvern/spreaded_alt
	name = "Wyvern (Spreaded Alt)"
	icon_state = "wyvern_alt"
	matrixed_sections = MATRIX_RED_GREEN
	extra2 = FALSE

/datum/sprite_accessory/wings/wyvern // Заглушка для зелий
	name = "Wyvern"
	icon = 'modular_bluemoon/icons/mob/human/wings_96x34.dmi'
	icon_state = "wyvern"
	center = TRUE
	dimension_x = 96
	dimension_y = 34
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
	extra = TRUE
	extra2 = TRUE
	locked = TRUE
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_FRONT_LAYER)

/datum/sprite_accessory/wings_open/wyvern
	name = "Wyvern"
	icon = 'modular_bluemoon/icons/mob/human/wings_96x34.dmi'
	icon_state = "wyvern"
	center = TRUE
	dimension_x = 96
	dimension_y = 34
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
	extra = TRUE
	extra2 = TRUE
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_FRONT_LAYER)

/datum/sprite_accessory/wings_open/wyvern

////////////////////////////////////////////////////////////////////

/datum/sprite_accessory/deco_wings/foxflames
	name = "Kitsune flames"
	icon_state = "foxflames"
	upgrade_to = list()

/datum/sprite_accessory/deco_wings/owl
	name = "owl"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "owl"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL

/datum/sprite_accessory/deco_wings/techarm
	name = "Tech Arm"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "techarm"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/pinioned
	name = "Pinioned Wings"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "pinioned" // Start of by @Sweettoothart
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/mantis/up
	name = "Mantis (Aloft)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "mantis_up"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN // USE_ONE_COLOR

/datum/sprite_accessory/deco_wings/mantis/down
	name = "Mantis (Sunken)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "mantis_down"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/top/mantis
	name = "Mantis (Top)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "mantis_top"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/tarantula
	name = "Tarantula"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "tarantula"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/spiderlegs/thin
	name = "Spiderlegs (Thin)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "spiderlegs_thin"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED // USE_ONE_COLOR

/datum/sprite_accessory/deco_wings/spiderlegs/striped
	name = "Spiderlegs (Striped)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "spiderlegs_striped"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/spiderlegs/thick
	name = "Spiderlegs (Thick)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "spiderlegs_thick"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL

/datum/sprite_accessory/deco_wings/spiderlegs/half_thick
	name = "Half Spiderlegs (Thick)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "half_spiderlegs_thick"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_GREEN

/datum/sprite_accessory/deco_wings/spiderlegs/segmented
	name = "Spiderlegs (Segmented)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "spiderlegs_segmented"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL

/datum/sprite_accessory/deco_wings/spiderlegs/mechanical
	name = "Spiderlegs (Mechanical)"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "spiderlegs_mechanical"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL

/datum/sprite_accessory/deco_wings/dragonfly
	name = "Dragonfly Wings"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "dragonfly"
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL

/datum/sprite_accessory/deco_wings/beetle_elytra
	name = "Beetle Elytra"
	icon = 'modular_bluemoon/icons/mob/wings.dmi'
	icon_state = "beetle_elytra" // End of by @Sweettoothart
	mutant_part_string = "wings"
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
