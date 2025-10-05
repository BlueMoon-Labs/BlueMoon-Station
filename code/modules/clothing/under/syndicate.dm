/obj/item/clothing/under/syndicate
	name = "tactical turtleneck"
	desc = "A non-descript and slightly suspicious looking turtleneck with digital camouflage cargo pants."
	icon_state = "syndicate"
	item_state = "bl_suit"
	has_sensor = NO_SENSORS
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 50, ACID = 40, WOUND = 10)
	alt_covers_chest = TRUE

/obj/item/clothing/under/syndicate/skirt
	name = "tactical skirtleneck"
	desc = "A non-descript and slightly suspicious looking skirtleneck."
	icon_state = "syndicate_skirt"
	item_state = "bl_suit"
	has_sensor = NO_SENSORS
	body_parts_covered = CHEST|GROIN|ARMS
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 50, ACID = 40, WOUND = 10)
	alt_covers_chest = TRUE
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/bloodred
	name = "blood-red sneaksuit"
	desc = "An insidious armored jumpsuit lined with Syndicate nanofibers and prototype platings, slightly resistant to most forms of damage, but is far too bulky to have anything attached to it. It still counts as stealth if there are no witnesses."
	icon_state = "bloodred_pajamas"
	item_state = "bl_suit"
	armor = list(MELEE = 10, BULLET = 10, LASER = 10,ENERGY = 10, BOMB = 0, BIO = 0, RAD = 10, FIRE = 100, ACID = 100, WOUND = 10)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	can_adjust = FALSE

/obj/item/clothing/under/syndicate/bloodred/sleepytime
	name = "blood-red pajamas"
	desc = "Do operatives dream of nuclear sheep?"
	icon_state = "bloodred_pajamas"
	item_state = "bl_suit"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100, WOUND = 5)

/obj/item/clothing/under/syndicate/tacticool
	name = "tacticool turtleneck"
	desc = "Just looking at it makes you want to buy an SKS, go into the woods, and -operate-."
	icon_state = "tactifool"
	item_state = "bl_suit"
	has_sensor = HAS_SENSORS //BLUEMOON CHANGE красота не должна требовать жертв
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 5)

/obj/item/clothing/under/syndicate/tacticool/skirt
	name = "tacticool skirtleneck"
	desc = "Just looking at it makes you want to buy an SKS, go into the woods, and -operate-."
	icon_state = "tactifool_skirt"
	item_state = "bl_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 5)
	fitted = FEMALE_UNIFORM_TOP
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/sniper
	name = "Tactical suit"
	desc = "A double seamed tactical fatigues disguised as a civilian grade silk suit. Intended for the most formal operator. The collar is really sharp."
	icon_state = "really_black_suit"
	item_state = "bl_suit"
	can_adjust = FALSE

/obj/item/clothing/under/syndicate/camo
	name = "camouflage fatigues"
	desc = "A green military camouflage uniform."
	icon_state = "camogreen"
	item_state = "g_suit"
	can_adjust = FALSE

/obj/item/clothing/under/syndicate/camo/cosmetic
	has_sensor = HAS_SENSORS //BLUEMOON CHANGE красота не должна требовать жертв
	armor = list(MELEE = 0, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/under/syndicate/soviet
	name = "Ratnik 5 tracksuit"
	desc = "Badly translated labels tell you to clean this in Vodka. Great for squatting in."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "trackpants"
	can_adjust = FALSE
	armor = list(MELEE = 10, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	resistance_flags = NONE

/obj/item/clothing/under/syndicate/combat
	name = "combat uniform"
	desc = "With a suit lined with this many pockets, you are ready to operate."
	icon_state = "syndicate_combat"
	can_adjust = FALSE
	mutantrace_variation = STYLE_DIGITIGRADE|USE_SNEK_CLIP_MASK|USE_QUADRUPED_CLIP_MASK

/obj/item/clothing/under/syndicate/combat/ert
	has_sensor = 3

/obj/item/clothing/under/syndicate/rus_army
	name = "Military Tracksuit"
	desc = "Military grade tracksuits for frontline squatting."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_under"
	can_adjust = FALSE
	armor = list(MELEE = 5, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	resistance_flags = NONE
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/rus_army_alt
	name = "Advanced Military Tracksuit"
	desc = "Advanced Military grade tracksuits for frontline squatting."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_under_alt"
	can_adjust = FALSE
	armor = list(MELEE = 5, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	resistance_flags = NONE
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/green_camo
	name = "green camouflage uniform"
	desc = "an green painted military suit, developed the Bibis&Co. Usually associated with CEHU and LonoMith PMC's"
	icon_state = "russian_green_uniform"
	alternate_screams = RUSSIAN_SCREAMS

/obj/item/clothing/under/syndicate/enclave
	name = "neo american sergeant uniform"
	desc = "Throughout the stars, rumors of mad scientists and angry drill sergeant run rampent, of creatures in armor black as night being led by men or women wearing this uniform, they share one thing, a deep, natonalistic zeal of the dream of America."
	icon_state = "enclave"
	armor = list(MELEE = 5, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	resistance_flags = NONE
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/enclave_alt
	name = "neo american officer uniform"
	desc = "Throughout the stars, rumors of mad scientists and angry drill sergeant run rampent, of creatures in armor black as night being led by men or women wearing this uniform, they share one thing, a deep, natonalistic zeal of the dream of America."
	icon_state = "enclaveo"
	armor = list(MELEE = 5, BULLET = 0, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 5)
	resistance_flags = NONE
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/under/syndicate/baseball
	name = "major league, number unknown"
	desc = "A major league outfit with the number faded number on the back. Seems rather robust for just a game..."
	icon_state = "syndicatebaseball"
	item_state = "syndicatebaseball"
	has_sensor = NO_SENSORS
	armor = list(MELEE = 15, BULLET = 5, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 40, WOUND = 10)
	alt_covers_chest = TRUE
	mutantrace_variation = USE_TAUR_CLIP_MASK

/obj/item/clothing/under/syndicate/scrubs
	name = "tactical scrubs"
	desc = "A deep burgundy set of scrubs, made tactically for tactical reasons."
	icon = 'icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'icons/mob/clothing/uniform.dmi'
	anthro_mob_worn_overlay = 'icons/mob/clothing/uniform_digi.dmi'
	icon_state = "scrubswine"
	item_state = "scrubswine"
	can_adjust = TRUE
	armor = list(MELEE = 10, BULLET = 5, LASER = 0,ENERGY = 0, BOMB = 0, BIO = 50, RAD = 0, FIRE = 50, ACID = 40, WOUND = 10)
