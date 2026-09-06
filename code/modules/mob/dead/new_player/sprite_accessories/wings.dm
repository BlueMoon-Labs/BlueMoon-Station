//Functional Wings

/datum/sprite_accessory/wings
	icon = 'icons/mob/wings_functional.dmi'
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_FRONT_LAYER)

/datum/sprite_accessory/wings/none
	name = "None"
	icon_state = "none"
	relevant_layers = null

/datum/sprite_accessory/wings/is_not_visible(var/mob/living/carbon/human/H, var/tauric)
	return (!H.dna.features["wings"] || H.dna.features["wings"] == "None" || (H.wear_suit && (H.wear_suit.flags_inv & HIDEJUMPSUIT) && (!H.wear_suit.species_exception || !is_type_in_list(src, H.wear_suit.species_exception))))

/datum/sprite_accessory/wings_open
	icon = 'icons/mob/wings_functional.dmi'
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_FRONT_LAYER)

/datum/sprite_accessory/wings_open/is_not_visible(var/mob/living/carbon/human/H, var/tauric)
	return (H.wear_suit && (H.wear_suit.flags_inv & HIDEJUMPSUIT) && (!H.wear_suit.species_exception || !is_type_in_list(src, H.wear_suit.species_exception)) || H.dna.species.mutant_bodyparts["wings"])

/datum/sprite_accessory/wings/angel
	name = "Angel"
	icon_state = "angel"
	dimension_x = 46
	center = TRUE
	dimension_y = 34
	locked = TRUE

/datum/sprite_accessory/wings_open/angel
	name = "Angel"
	icon_state = "angel"
	dimension_x = 46
	center = TRUE
	dimension_y = 34

/datum/sprite_accessory/wings/dragon
	name = "Dragon"
	icon_state = "dragon"
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/dragon
	name = "Dragon"
	icon_state = "dragon"
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/megamoth
	name = "Megamoth"
	icon_state = "megamoth"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/megamoth
	name = "Megamoth"
	icon_state = "megamoth"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/mothra
	name = "Mothra"
	icon_state = "mothra"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/mothra
	name = "Mothra"
	icon_state = "mothra"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/skeleton
	name = "Skeleton"
	icon_state = "skele"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/skeleton
	name = "Skeleton"
	icon_state = "skele"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/robotic
	name = "Robotic"
	icon_state = "robotic"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/robotic
	name = "Robotic"
	icon_state = "robotic"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

/datum/sprite_accessory/wings/fly
	name = "Fly"
	icon_state = "fly"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32
	locked = TRUE

/datum/sprite_accessory/wings_open/fly
	name = "Fly"
	icon_state = "fly"
	color_src = FALSE
	dimension_x = 96
	center = TRUE
	dimension_y = 32

// Decorative wings

/datum/sprite_accessory/deco_wings
	icon = 'icons/mob/wings.dmi'
	color_src = WINGCOLOR
	mutant_part_string = "insect_wings"
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_FRONT_LAYER)
	var/list/upgrade_to = list() //What the wings change to if the mob consumes a flight potion or gains true wings through other means. If it's an empty list, it will pick the species alternative instead.

/datum/sprite_accessory/deco_wings/is_not_visible(var/mob/living/carbon/human/H, var/tauric)
	return (H.dna.features["wings"] != "None") //true wings will override decorative wings

/datum/sprite_accessory/deco_wings/none
	name = "None"
	icon_state = "none"
	relevant_layers = null

/datum/sprite_accessory/deco_wings/angel
	name = "Angel"
	icon_state = "angel"
	dimension_x = 46
	center = TRUE
	dimension_y = 34
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_ADJ_LAYER, BODY_FRONT_LAYER)
	upgrade_to = SPECIES_WINGS_ANGEL //obviously

//nonmoth wings

/datum/sprite_accessory/deco_wings/bat
	name = "Bat"
	icon_state = "bat"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/deco_wings/bee
	name = "Bee"
	icon_state = "bee"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/deco_wings/bee2
	name = "Small Bee"
	icon_state = "beewings"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/deco_wings/dragon
	name = "Dragon"
	icon_state = "dragon"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_BLUE
	upgrade_to = SPECIES_WINGS_DRAGON //lol
	extra = TRUE //IF NOBODY CAN HAVE UNIQUE DUAL-COLOR DUE TO SHITCODE, I SHALL MAKE IT SO THAT THE MOST USELESS COLOR SLOT IS USED.
	extra_color_src = MUTCOLORS3

/datum/sprite_accessory/deco_wings/dragonfly
	name = "Dragonfly"
	icon_state = "dragonfly"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/deco_wings/fairy
	name = "Fairy"
	icon_state = "fairy"
	upgrade_to = SPECIES_WINGS_INSECT //rip people's sparkly wings until someone sprites in some huge fairy wings or something

/datum/sprite_accessory/deco_wings/featheredwing
	name = "Feathery"
	icon_state = "feathery"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/featheredwingmedium
	name = "Medium Feathered"
	icon_state = "feathered3"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/featheredwinglarge
	name = "Large Feathered"
	icon_state = "feathered2"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/harpywings
	name = "Harpy"
	icon_state = "harpywings"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/harpywingsalt
	name = "Harpy (Alt)"
	icon_state = "harpywingsalt"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/harpywingsaltcollar
	name = "Harpy (Alt Collar)"
	icon_state = "harpywingsaltcollar"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/harpywingsbat
	name = "Harpy (Bat)"
	icon_state = "harpywingsbat"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/harpywingsbatcollar
	name = "Harpy (Bat Collar)"
	icon_state = "harpywingsbatcollar"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/deco_wings/roboticwing
	name = "Robotic"
	icon_state = "drago"
	upgrade_to = SPECIES_WINGS_ROBOT

/datum/sprite_accessory/deco_wings/succubusblack
	name = "Succubus Black"
	icon_state = "succubusblack"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/deco_wings/succubuspurple
	name = "Succubus Purple"
	icon_state = "succubuspurple"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/deco_wings/succubusred
	name = "Succubus Red"
	icon_state = "succubusred"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/deco_wings/xenobackplate
	name = "Xenomorph Backplate"
	icon_state = "snagbackplate"
	upgrade_to = list()

//moth wings - NovaSector transfer (ordinary + greyscale) for nian
// ==================== ORDINARY (WINGCOLOR, moth_wings.dmi) ====================

/datum/sprite_accessory/deco_wings/atlas
	name = "Moth (Atlas)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "atlas"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/brown
	name = "Moth (Brown)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "brown"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/deathhead
	name = "Moth (Deathshead)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "deathhead"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/featherymoth
	name = "Moth (Feathery)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "feathery"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/firewatch
	name = "Moth (Firewatch)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "firewatch"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/gothic
	name = "Moth (Gothic)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "gothic"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/jungle
	name = "Moth (Jungle)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "jungle"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/lovers
	name = "Moth (Lovers)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "lovers"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/luna
	name = "Moth (Luna)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "luna"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/monarch
	name = "Moth (Monarch)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "monarch"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/moonfly
	name = "Moth (Moon Fly)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "moonfly"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/oakworm
	name = "Moth (Oak Worm)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "oakworm"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/plain
	name = "Moth (Plain)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "plain"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/plasmafire
	name = "Moth (Plasmafire)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "plasmafire"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/poison
	name = "Moth (Poison)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "poison"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/punished
	name = "Burnt Off"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "burnt_off"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/ragged
	name = "Moth (Ragged)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "ragged"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/reddish
	name = "Moth (Reddish)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "redish"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/rosy
	name = "Moth (Rosy)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "rosy"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/royal
	name = "Moth (Royal)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "royal"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/snow
	name = "Moth (Snow)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "snow"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/whitefly
	name = "Moth (White Fly)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "whitefly"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/witchwing
	name = "Moth (Witch Wing)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "witchwing"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/moffra
	name = "Moth (Moffra)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "moffra"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/lightbearer
	name = "Moth (Lightbearer)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "lightbearer"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/bluespace
	name = "Moth (Bluespace)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "bluespace"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/strawberry
	name = "Moth (Strawberry)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "strawberry"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/clockwork
	name = "Moth (Clockwork)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "clockwork"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/citheronia
	name = "Moth (Citheronia)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "citheroniagrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/whiteflygrey
	name = "Moth (Whitefly Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "whiteflygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/browngrey
	name = "Moth (Brown Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "browngrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/deathheadgrey
	name = "Moth (Deathshead Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "deathheadgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/atlasgrey
	name = "Moth (Atlas Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "atlasgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/poisongrey
	name = "Moth (Poison Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "poisongrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/raggedgrey
	name = "Moth (Ragged Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "raggedgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/featherygrey
	name = "Moth (Feathery Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "featherygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/firewatchgrey
	name = "Moth (Firewatch Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "firewatchgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/loversgrey
	name = "Moth (Lovers Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "loversgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/junglegrey
	name = "Moth (Jungle Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "junglegrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/rosygrey
	name = "Moth (Rosy Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "rosygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/moffragrey
	name = "Moth (Moffra Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "moffragrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/oakwormgrey
	name = "Moth (Oakworm Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "oakwormgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/plasmafiregrey
	name = "Moth (Plasmafire Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "plasmafiregrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/monarchgrey
	name = "Moth (Monarch Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "monarchgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/royalgrey
	name = "Moth (Royal Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "royalgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/plaingrey
	name = "Moth (Plain Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "plaingrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/lunagrey
	name = "Moth (Luna Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "lunagrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/deco_wings/witchwinggrey
	name = "Moth (Witchwing Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "witchwinggrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings
	icon = 'icons/mob/wings.dmi'
	color_src = WINGCOLOR
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_FRONT_LAYER)
	mutant_part_string = "insect_wings"
	var/list/upgrade_to = list()

/datum/sprite_accessory/insect_wings/is_not_visible(var/mob/living/carbon/human/H, var/tauric)
	return (H.dna.features["wings"] != "None") //true wings will override decorative wings

//non insect wings
/datum/sprite_accessory/insect_wings/bat
	name = "Bat"
	icon_state = "bat"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/insect_wings/bee
	name = "Bee"
	icon_state = "bee"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/insect_wings/bee2
	name = "Small Bee"
	icon_state = "beewings"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/insect_wings/dragon
	name = "Dragon"
	icon_state = "dragon"
	color_src = MATRIXED
	matrixed_sections = MATRIX_RED_BLUE
	upgrade_to = SPECIES_WINGS_DRAGON //lol
	extra = TRUE //IF NOBODY CAN HAVE UNIQUE DUAL-COLOR DUE TO SHITCODE, I SHALL MAKE IT SO THAT THE MOST USELESS COLOR SLOT IS USED.
	extra_color_src = MUTCOLORS3

/datum/sprite_accessory/insect_wings/dragonfly
	name = "Dragonfly"
	icon_state = "dragonfly"
	upgrade_to = SPECIES_WINGS_INSECT
/datum/sprite_accessory/insect_wings/fairy
	name = "Fairy"
	icon_state = "fairy"
	upgrade_to = SPECIES_WINGS_INSECT

/datum/sprite_accessory/insect_wings/featheredwing
	name = "Feathery"
	icon_state = "feathery"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/featheredwingmedium
	name = "Medium Feathered"
	icon_state = "feathered3"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/featheredwinglarge
	name = "Large Feathered"
	icon_state = "feathered2"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/harpywings
	name = "Harpy"
	icon_state = "harpywings"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/harpywingsalt
	name = "Harpy (Alt)"
	icon_state = "harpywingsalt"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/harpywingsaltcollar
	name = "Harpy (Alt Collar)"
	icon_state = "harpywingsaltcollar"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/harpywingsbat
	name = "Harpy (Bat)"
	icon_state = "harpywingsbat"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/harpywingsbatcollar
	name = "Harpy (Bat Collar)"
	icon_state = "harpywingsbatcollar"
	upgrade_to = SPECIES_WINGS_ANGEL

/datum/sprite_accessory/insect_wings/roboticwing
	name = "Robotic"
	icon_state = "drago"
	upgrade_to = SPECIES_WINGS_ROBOT

/datum/sprite_accessory/insect_wings/succubusblack
	name = "Succubus Black"
	icon_state = "succubusblack"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/insect_wings/succubuspurple
	name = "Succubus Purple"
	icon_state = "succubuspurple"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/insect_wings/succubusred
	name = "Succubus Red"
	icon_state = "succubusred"
	upgrade_to = SPECIES_WINGS_DRAGON

/datum/sprite_accessory/insect_wings/xenobackplate
	name = "Xenomorph Backplate"
	icon_state = "snagbackplate"
	upgrade_to = list()

//moth wings

/datum/sprite_accessory/insect_wings/none
	name = "None"
	icon_state = "none"
	relevant_layers = null
	upgrade_to = list()

/datum/sprite_accessory/insect_wings/atlas
	name = "Moth (Atlas)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "atlas"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/brown
	name = "Moth (Brown)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "brown"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/deathhead
	name = "Moth (Deathshead)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "deathhead"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/featherymoth
	name = "Moth (Feathery)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "feathery"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/firewatch
	name = "Moth (Firewatch)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "firewatch"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/gothic
	name = "Moth (Gothic)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "gothic"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/jungle
	name = "Moth (Jungle)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "jungle"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/lovers
	name = "Moth (Lovers)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "lovers"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/luna
	name = "Moth (Luna)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "luna"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/monarch
	name = "Moth (Monarch)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "monarch"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/moonfly
	name = "Moth (Moon Fly)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "moonfly"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/oakworm
	name = "Moth (Oak Worm)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "oakworm"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/plain
	name = "Moth (Plain)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "plain"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/plasmafire
	name = "Moth (Plasmafire)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "plasmafire"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/poison
	name = "Moth (Poison)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "poison"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/punished
	name = "Burnt Off"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "burnt_off"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/ragged
	name = "Moth (Ragged)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "ragged"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/reddish
	name = "Moth (Reddish)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "redish"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/rosy
	name = "Moth (Rosy)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "rosy"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/royal
	name = "Moth (Royal)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "royal"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/snow
	name = "Moth (Snow)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "snow"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/whitefly
	name = "Moth (White Fly)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "whitefly"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/witchwing
	name = "Moth (Witch Wing)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "witchwing"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/moffra
	name = "Moth (Moffra)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "moffra"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/lightbearer
	name = "Moth (Lightbearer)"
	icon = 'icons/mob/moth_wings.dmi'
	icon_state = "lightbearer"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/bluespace
	name = "Moth (Bluespace)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "bluespace"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/strawberry
	name = "Moth (Strawberry)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "strawberry"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/clockwork
	name = "Moth (Clockwork)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "clockwork"
	upgrade_to = SPECIES_WINGS_MOTH

// GREYSCALE

/datum/sprite_accessory/insect_wings/citheronia
	name = "Moth (Citheronia)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "citheroniagrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/whiteflygrey
	name = "Moth (Whitefly Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "whiteflygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/browngrey
	name = "Moth (Brown Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "browngrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/deathheadgrey
	name = "Moth (Deathshead Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "deathheadgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/atlasgrey
	name = "Moth (Atlas Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "atlasgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/poisongrey
	name = "Moth (Poison Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "poisongrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/raggedgrey
	name = "Moth (Ragged Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "raggedgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/featherygrey
	name = "Moth (Feathery Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "featherygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/firewatchgrey
	name = "Moth (Firewatch Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "firewatchgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/loversgrey
	name = "Moth (Lovers Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "loversgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/junglegrey
	name = "Moth (Jungle Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "junglegrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/rosygrey
	name = "Moth (Rosy Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "rosygrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/moffragrey
	name = "Moth (Moffra Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "moffragrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/oakwormgrey
	name = "Moth (Oakworm Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "oakwormgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/plasmafiregrey
	name = "Moth (Plasmafire Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "plasmafiregrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/monarchgrey
	name = "Moth (Monarch Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "monarchgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/royalgrey
	name = "Moth (Royal Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "royalgrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/plaingrey
	name = "Moth (Plain Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "plaingrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/lunagrey
	name = "Moth (Luna Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "lunagrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_wings/witchwinggrey
	name = "Moth (Witchwing Greyscale)"
	icon = 'icons/mob/moth_wings_greyscale.dmi'
	icon_state = "witchwinggrey"
	upgrade_to = SPECIES_WINGS_MOTH

/datum/sprite_accessory/insect_markings // Extra markings for insects ported from tg.
	icon = 'icons/mob/insect_markings.dmi'
	color_src = WINGCOLOR
	relevant_layers = list(BODY_ADJ_LAYER)

/datum/sprite_accessory/insect_markings/none
	name = "None"
	icon_state = "none"
	relevant_layers = null

/datum/sprite_accessory/insect_markings/deathhead
	name = "Deathshead"
	icon_state = "deathhead"

/datum/sprite_accessory/insect_markings/firewatch
	name = "Firewatch"
	icon_state = "firewatch"

/datum/sprite_accessory/insect_markings/gothic
	name = "Gothic"
	icon_state = "gothic"

/datum/sprite_accessory/insect_markings/jungle
	name = "Jungle"
	icon_state = "jungle"

/datum/sprite_accessory/insect_markings/lovers
	name = "Lovers"
	icon_state = "lovers"

/datum/sprite_accessory/insect_markings/moonfly
	name = "Moon Fly"
	icon_state = "moonfly"

/datum/sprite_accessory/insect_markings/oakworm
	name = "Oak Worm"
	icon_state = "oakworm"

/datum/sprite_accessory/insect_markings/poison
	name = "Poison"
	icon_state = "poison"

/datum/sprite_accessory/insect_markings/punished
	name = "Punished"
	icon_state = "punished"

/datum/sprite_accessory/insect_markings/ragged
	name = "Ragged"
	icon_state = "ragged"

/datum/sprite_accessory/insect_markings/reddish
	name = "Reddish"
	icon_state = "reddish"

/datum/sprite_accessory/insect_markings/royal
	name = "Royal"
	icon_state = "royal"

/datum/sprite_accessory/insect_markings/whitefly
	name = "White Fly"
	icon_state = "whitefly"

/datum/sprite_accessory/insect_markings/witchwing
	name = "Witch Wing"
	icon_state = "witchwing"

//DONATOR WINGS

/datum/sprite_accessory/deco_wings/eyestalks
	name = "gazer eyestalks"
	icon_state = "eyestalks"
	upgrade_to = list() //and suddenly flight potions become a lot more awkward when they gouge your tentacle eyes out.
	//ckeys_allowed = list("liquidfirefly","seiga") //At request.

/datum/sprite_accessory/insect_wings/eyestalks
	name = "gazer eyestalks"
	icon_state = "eyestalks"
	upgrade_to = list()
	//ckeys_allowed = list("liquidfirefly","seiga") //At request.
