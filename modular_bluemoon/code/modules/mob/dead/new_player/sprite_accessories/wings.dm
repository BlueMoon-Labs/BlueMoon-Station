/// РАСКРЫВАЕМЫЕ КРЫЛЬЯ

/datum/sprite_accessory/deco_wings/spreadable/big
	icon = 'modular_bluemoon/icons/mob/wingspreadable.dmi' // 96x64 size
	center = TRUE
	upgrade_to = list()

/datum/sprite_accessory/deco_wings/spreadable/big/spreaded
	icon = 'modular_bluemoon/icons/mob/wingspreadable.dmi'
	center = TRUE
	upgrade_to = list()

////

/datum/sprite_accessory/deco_wings/spreadable/big/wyvern
	name = "Wyvern"
	icon_state = "wyvern"
	dimension_x = 96
	dimension_y = -1
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
	extra = TRUE
	extra_color_src = MUTCOLORS2
	extra2 = TRUE
	extra2_color_src = MUTCOLORS3
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/deco_wings/spreadable/big/spreaded/wyvern
	name = "Wyvern (Spreaded)"
	icon_state = "wyvernspr"
	dimension_x = 96
	dimension_y = -1
	color_src = MATRIXED
	matrixed_sections = MATRIX_ALL
	extra = TRUE
	extra_color_src = MUTCOLORS2
	extra2 = TRUE
	extra2_color_src = MUTCOLORS3
	upgrade_to = SPECIES_WINGS_DRAGON

////////////////////////////////////////////////////////////////////

/datum/sprite_accessory/deco_wings/foxflames
	name = "Kitsune flames"
	icon_state = "foxflames"
	upgrade_to = list()
