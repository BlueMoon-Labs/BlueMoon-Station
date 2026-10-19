//Contains: Engineering department jumpsuits
/obj/item/clothing/under/rank/engineering/chief_engineer
	desc = "It's a high-visibility jumpsuit given to those engineers insane enough to achieve the rank of \"Chief Engineer\". It has minor radiation shielding."
	name = "chief engineer's jumpsuit"
	icon_state = "chiefengineer"
	item_state = "gy_suit"
	armor_type = /datum/armor/under_chief_engineer
	resistance_flags = NONE

/obj/item/clothing/under/rank/engineering/chief_engineer/skirt
	name = "chief engineer's jumpskirt"
	desc = "It's a high-visibility jumpskirt given to those engineers insane enough to achieve the rank of \"Chief Engineer\". It has minor radiation shielding."
	icon_state = "chiefengineer_skirt"
	item_state = "gy_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	can_adjust = FALSE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	alternate_worn_layer = DRESS_LAYER

/obj/item/clothing/under/rank/engineering/atmospheric_technician
	desc = "It's a jumpsuit worn by atmospheric technicians. It provides decent fire protection."
	name = "atmospheric technician's jumpsuit"
	icon_state = "atmos"
	item_state = "atmos_suit"
	armor_type = /datum/armor/atmospheric_technician
	resistance_flags = NONE

/obj/item/clothing/under/rank/engineering/atmospheric_technician/skirt
	name = "atmospheric technician's jumpskirt"
	desc = "It's a jumpskirt worn by atmospheric technicians."
	icon_state = "atmos_skirt"
	item_state = "atmos_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	can_adjust = FALSE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	alternate_worn_layer = DRESS_LAYER

/obj/item/clothing/under/rank/engineering/engineer
	desc = "It's an orange high-visibility jumpsuit worn by engineers. It has minor radiation shielding."
	name = "engineer's jumpsuit"
	icon_state = "engine"
	item_state = "engi_suit"
	armor_type = /datum/armor/engineer
	resistance_flags = NONE
	unique_reskin = list(
		"Alt" = list("icon_state" = "eng_alt")
	)

/obj/item/clothing/under/rank/engineering/engineer/mechanic
	name = "mechanic's jumpsuit"
	desc = "an old mechanic's jumpsuit"
	icon_state = "mechanic"
	item_state = "mechanic"
	can_adjust = FALSE

/obj/item/clothing/under/rank/engineering/engineer/util
	name = "engineering utility uniform"
	desc = "a utility jumpsuit for engineering personnel"
	icon_state = "utileng"
	item_state = "utileng"
	can_adjust = FALSE

/obj/item/clothing/under/rank/engineering/engineer/util/syndicate
	armor_type = /datum/armor/command_and_syndicate_utility
	has_sensor = NO_SENSORS

/obj/item/clothing/under/rank/engineering/engineer/hazard
	name = "engineer's hazard jumpsuit"
	desc = "A high-visibility jumpsuit made from heat and radiation resistant materials."
	icon_state = "hazard_orange"
	item_state = "engi_suit"
	alt_covers_chest = TRUE

/obj/item/clothing/under/rank/engineering/engineer/hazard/green
	icon_state = "hazard_green"
	item_state = "g_suit"

/obj/item/clothing/under/rank/engineering/engineer/hazard/white
	icon_state = "hazard_white"
	item_state = "gy_suit"

/obj/item/clothing/under/rank/engineering/engineer/skirt
	name = "engineer's jumpskirt"
	desc = "It's an orange high-visibility jumpskirt worn by engineers."
	icon_state = "engine_skirt"
	item_state = "engi_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	can_adjust = FALSE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	alternate_worn_layer = DRESS_LAYER
