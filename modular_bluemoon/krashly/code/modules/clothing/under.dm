/obj/item/clothing/under/rank/blueshield/formal/pmc_leader_jumpsuit
	name = "PMC command fatigues"
	desc = "A white set of fatigues, designed for private security operators. The symbol of the Nanotrasen corporation is emblazed on the suit. This particular suit looks like it belongs to a high-ranking officer."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "officer_jumpsuit"
	item_state = "officer_jumpsuit"

/obj/item/clothing/under/aesculapius
	name = "aesculapius uniform"
	desc = "Shirt with trousers with suspenders."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "esculap"
	item_state = "esculap"

/obj/item/clothing/under/butler
	name = "butler uniform"
	desc = "Bright butler formal wear."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "butler_s"
	item_state = "butler_s"

/obj/item/clothing/under/common
	name = "ridiculous clothes"
	desc = "Looks very old."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "common"
	item_state = "common"

/obj/item/clothing/under/baron
	name = "rich clothes"
	desc = "Decorated with precious stones and chains."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "baron"
	item_state = "baron"

/obj/item/clothing/under/chaplain/krashly_ver
	name = "chaplain clothes"
	desc = "Black uniform with an embroidered cross on it."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "chaplain"
	item_state = "chaplain"


//Plasmaman outfit
	//centcom//
/obj/item/clothing/under/plasmaman/captain/centcom
	name = "central command envirosuit"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "centcom_envirosuit"
	item_state = "centcom_envirosuit"

//InteQ

/obj/item/clothing/under/inteq
	name = "brown combat turtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under_digidrated.dmi'
	icon_state = "inteq"
	item_state = "inteq"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 50, ACID = 40, WOUND = 10)
	has_sensor = NO_SENSORS

/obj/item/clothing/under/inteq/Initialize(mapload)
	. = ..()
	var/obj/item/clothing/accessory/indiv_number/A = new (src)
	attach_accessory(A)

/obj/item/clothing/under/inteq/honorable_vanguard
	name = "black combat turtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under_digidrated.dmi'
	icon_state = "inteq_honorable"
	item_state = "inteq_honorable"

/obj/item/clothing/under/inteq/skirt
	name = "brown combat skirtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "inteq_skirt"
	item_state = "inteq_skirt"
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/inteq/eng
	name = "brown engineering turtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under_digidrated.dmi'
	icon_state = "inteqeng"
	item_state = "inteqeng"

/obj/item/clothing/under/inteq/eng_skirt
	name = "brown engineering skirtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "inteqeng_skirt"
	item_state = "inteqeng_skirt"
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/inteq/maid
	name = "brown combat maidsuit"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish. Battle maids!"
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "inteqmaid"
	item_state = "inteqmaid"
	body_parts_covered = CHEST|GROIN
	fitted = FEMALE_UNIFORM_TOP
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/under/inteq/maid/Initialize(mapload)
	. = ..()
	var/obj/item/clothing/accessory/maidapron/inteq/A = new (src)
	attach_accessory(A)

/obj/item/clothing/accessory/maidapron/inteq
	name = "InteQ maid apron"
	desc = "The best part of a maid costume."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "maidapron"
	item_state = "maidapron"

/obj/item/clothing/under/inteq/med
	name = "white combat turtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish. Designed for field medics."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under_digidrated.dmi'
	icon_state = "inteqmed"
	item_state = "inteqmed"

/obj/item/clothing/under/inteq/med_skirt
	name = "white combat skirtleneck"
	desc = "It sits comfortably, does not hinder movement, and most importantly, it is very stylish. Designed for field medics."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/krashly/icons/mob/clothing/under.dmi'
	icon_state = "inteqmed_skirt"
	item_state = "inteqmed_skirt"
	mutantrace_variation = STYLE_DIGITIGRADE
