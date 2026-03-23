/obj/item/clothing/under/rank/captain
	desc = "It's a blue jumpsuit with some gold markings denoting the rank of \"Captain\"."
	name = "captain's jumpsuit"
	icon_state = "captain"
	item_state = "b_suit"
	armor = list(MELEE = 10, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 30, ACID = 30, WOUND = 10)
	sensor_mode = SENSOR_COORDS
	sensor_flags = NONE

/obj/item/clothing/under/rank/captain/utility/syndicate
	armor = list(MELEE = 10, BULLET = 5, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 40, WOUND = 10)
	has_sensor = NO_SENSORS

/obj/item/clothing/under/rank/captain/util
	name = "command utility uniform"
	desc = "A utility uniform for command personnel."
	icon_state = "utilcom"
	item_state = "utilcom"
	armor = list(MELEE = 10, BULLET = 5, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 40, WOUND = 10)
	can_adjust = FALSE

/obj/item/clothing/under/rank/captain/skirt
	name = "captain's jumpskirt"
	desc = "It's a blue jumpskirt with some gold markings denoting the rank of \"Captain\"."
	icon_state = "captain_skirt"
	item_state = "b_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	can_adjust = FALSE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/rank/captain/suit
	name = "captain's suit"
	desc = "A green suit and yellow necktie. Exemplifies authority."
	icon_state = "green_suit"
	item_state = "dg_suit"
	can_adjust = FALSE

/obj/item/clothing/under/rank/captain/suit/skirt
	name = "green suitskirt"
	desc = "A green suitskirt and yellow necktie. Exemplifies authority."
	icon_state = "green_suit_skirt"
	item_state = "dg_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	can_adjust = FALSE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/rank/captain/parade
	name = "captain's parade uniform"
	desc = "A captain's luxury-wear, for special occasions."
	icon_state = "captain_parade"
	item_state = "by_suit"
	can_adjust = FALSE

/obj/item/clothing/under/rank/captain/femformal
	name = "captain's female formal outfit"
	desc = "An ironically skimpy blue dress with gold markings denoting the rank of \"Captain\"."
	icon_state = "lewdcap"
	item_state = "lewdcap"
	alt_covers_chest = TRUE
	mutantrace_variation = STYLE_DIGITIGRADE|USE_TAUR_CLIP_MASK


//Bridge officer

/obj/item/clothing/under/rank/bridgeofficer
	name = "bridge officer outfit"
	desc = "The uniform of a bridge officer. It makes you feel extremely important, even if you are not."
	icon_state = "bridgesec"
	item_state = "bridgesec"
	armor = list("melee" = 5, "bullet" = 0, "laser" = 5,"energy" = 5, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0, "wound" = 0)
	alt_covers_chest = TRUE
	can_adjust = FALSE
	sensor_flags = NONE
	sensor_mode = SENSOR_COORDS

/obj/item/clothing/under/rank/bridgeofficer/skirt
	name = "bridge officer skirt"
	icon_state = "bridgesecf"
	item_state = "bridgesecf"
	body_parts_covered = CHEST|GROIN|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/rank/bridgeofficer/formal
	name = "bridge officer formal outfit"
	desc = "The uniform of a bridge officer. Its a formal variant."
	icon_state = "bridgesecformal"
	item_state = "bridgesecformal"
