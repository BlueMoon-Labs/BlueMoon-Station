/obj/item/clothing/suit/armor
	allowed = null
	cold_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	strip_delay = 60
	equip_delay_other = 40
	max_integrity = 250
	resistance_flags = NONE
	tail_state = "none"
	armor = list(MELEE = 35, BULLET = 30, LASER = 30, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/Initialize(mapload)
	. = ..()
	if(!allowed)
		allowed = GLOB.security_vest_allowed

/obj/item/clothing/suit/armor/secjacket
	name = "Black Security Jacket"
	desc = "A sturdy black jacket with reinforced fabric. Bears insignia of NT corporate security."
	icon_state = "secjacket"
	item_state = "hos"
	togglename = "buttons"
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS
	heat_protection = CHEST|GROIN|ARMS
	armor = list(MELEE = 20, BULLET = 20, LASER = 25, ENERGY = 20, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)

/obj/item/clothing/suit/armor/secjacket
	name = "security officer's jacket"
	desc = "This jacket is for those special occasions when a security officer isn't required to wear their armor."
	icon_state = "officerbluejacket"
	item_state = "officerbluejacket"
	body_parts_covered = CHEST|ARMS

/obj/item/clothing/suit/armor/vest
	name = "armor vest"
	desc = "A slim Type I armored vest that provides decent protection against most types of damage."
	icon_state = "armoralt"
	item_state = "armoralt"
	blood_overlay_type = "armor"
	clothing_flags = THICKMATERIAL
	dog_fashion = /datum/dog_fashion/back

/obj/item/clothing/suit/armor/vest/alt
	desc = "A Type I armored vest that provides decent protection against most types of damage."
	icon_state = "armor"
	item_state = "armor"
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "armor",
			RESKIN_ITEM_STATE = "armor"
		),
		"Old" = list(
			RESKIN_ICON_STATE = "armorold",
			RESKIN_ITEM_STATE = "armorold"
		),
		"Alternative" = list(
			RESKIN_ICON_STATE = "armoralt",
			RESKIN_ITEM_STATE = "armoralt"
		),
		"Bloody" = list(
			RESKIN_ICON_STATE = "bloody_armor",
			RESKIN_ITEM_STATE = "bloody_armor"
		),
	)

/obj/item/clothing/suit/armor/vest/old
	name = "degrading armor vest"
	desc = "Older generation Type 1 armored vest. Due to degradation over time the vest is far less maneuverable to move in."
	icon_state = "armor"
	item_state = "armor"
	slowdown = 1

/obj/item/clothing/suit/armor/vest/blueshirt
	name = "large armor vest"
	desc = "A large, yet comfortable piece of armor, protecting you from some threats."
	icon_state = "blueshift"
	item_state = "blueshift"
	custom_premium_price = PRICE_ABOVE_EXPENSIVE

/obj/item/clothing/suit/armor/hos
	name = "armored greatcoat"
	desc = "A greatcoat enhanced with a special alloy for some extra protection and style for those with a commanding presence."
	icon_state = "hos"
	item_state = "greatcoat"
	tail_state = "none"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 50, BOMB = 25, BIO = 0, RAD = 0, FIRE = 70, ACID = 90, WOUND = 20)
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	clothing_flags = THICKMATERIAL
	strip_delay = 80

/obj/item/clothing/suit/armor/hos/navyblue
	name = "head of security's jacket"
	desc = "This piece of clothing was specifically designed for asserting superior authority."
	icon_state = "hosbluejacket"
	item_state = "hosbluejacket"
	body_parts_covered = CHEST|ARMS
	cold_protection = CHEST|ARMS
	heat_protection = CHEST|ARMS

/obj/item/clothing/suit/armor/hos/trenchcoat
	name = "armored trenchcoat"
	desc = "A trenchcoat enhanced with a special lightweight kevlar. The epitome of tactical plainclothes."
	icon_state = "hostrench"
	item_state = "hostrench"
	flags_inv = 0
	strip_delay = 80
	unique_reskin = list(
		"Coat" = list("icon_state" = "hostrench"),
		"Cloak" = list("icon_state" = "trenchcloak")
	)

/obj/item/clothing/suit/armor/hos/platecarrier
	name = "plate carrier"
	desc = "An armor vest with attached pockets for holding and sorting equipment or ammo."
	icon_state = "platecarrier"
	item_state = "platecarrier"
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|ARMS
	heat_protection = CHEST|ARMS
	strip_delay = 80
	armor = list(MELEE = 40, BULLET = 35, LASER = 35, ENERGY = 45, BOMB = 25, BIO = 0, RAD = 0, FIRE = 60, ACID = 60, WOUND = 15)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Black" = list("icon_state" = "platecarrier"),
		"Blue" = list("icon_state" = "pcarrier_blue"),
		"Navy" = list("icon_state" = "pcarrier_navy"),
		"Green" = list("icon_state" = "pcarrier_green"),
		"Tan" = list("icon_state" = "pcarrier_tan"),
		"Flektarn" = list("icon_state" = "pcarrier_flektarn"),
		"Harness" = list("icon_state" = "pcarrier_harness"),
		"Harness White" = list("icon_state" = "pcarrier_harness_w")
	)

/obj/item/clothing/suit/armor/hos/platecarrier/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/storage = AddComponent(/datum/component/storage/concrete)
	storage.max_items = 5

//Commander
/obj/item/clothing/suit/armor/hos/command
	name = "Emergency Response Team commander Armor"
	desc = "A set of armor worn by the commander of a Nanotrasen Emergency Response Team. Has blue highlights."
	icon_state = "ertarmor_cmd"
	item_state = "armor"

//Security
/obj/item/clothing/suit/armor/hos/security
	name = "Emergency Response Team security Armor"
	desc = "A set of armor worn by security members of the Nanotrasen Emergency Response Team. Has red highlights."
	icon_state = "ertarmor_sec"

//Engineer
/obj/item/clothing/suit/armor/hos/engineer
	name = "Emergency Response Team engineer Armor"
	desc = "A set of armor worn by engineering members of the Nanotrasen Emergency Response Team. Has orange highlights."
	icon_state = "ertarmor_eng"

//Medical
/obj/item/clothing/suit/armor/hos/medical
	name = "Emergency Response Team medical Armor"
	desc = "A set of armor worn by medical members of the Nanotrasen Emergency Response Team. Has red and white highlights."
	icon_state = "ertarmor_med"

//Janitorial
/obj/item/clothing/suit/armor/hos/janitor
	name = "Emergency Response Team janitor Armor"
	desc = "A set of armor worn by janitorial members of the Nanotrasen Emergency Response Team. Has red and white highlights."
	icon_state = "ertarmor_jan"

/obj/item/clothing/suit/armor/vest/warden
	name = "Warden's Jacket"
	desc = "A navy-blue armored jacket with blue shoulder designations and '/Warden/' stitched into one of the chest pockets."
	icon_state = "warden_alt"
	item_state = "armor"
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS|HANDS
	heat_protection = CHEST|GROIN|ARMS|HANDS
	strip_delay = 70
	resistance_flags = FLAMMABLE
	dog_fashion = null
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/suit/armor/vest/warden/alt
	name = "warden's armored jacket"
	desc = "A red jacket with silver rank pips and body armor strapped on top."
	icon_state = "warden_jacket"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Jacket" = list("icon_state" = "warden_jacket"),
		"Vest" = list("icon_state" = "warden_jacket_newtg"),
		"Syndie Warden Jacket" = list("icon_state" = "warden_syndie")
	)

/obj/item/clothing/suit/armor/vest/warden/navyblue
	name = "warden's jacket"
	desc = "Perfectly suited for the warden that wants to leave an impression of style on those who visit the brig."
	icon_state = "wardenbluejacket"
	item_state = "wardenbluejacket"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/vest/warden/syndicate
	name = "Master at Arms' Vest"
	desc = "Stunning. Menacing. Perfect for the man who gets bullied for leaving the brig."
	icon_state = "warden_syndie"

/obj/item/clothing/suit/armor/vest/leather
	name = "security overcoat"
	desc = "Lightly armored leather overcoat meant as casual wear for high-ranking officers. Bears the crest of Nanotrasen Security."
	icon_state = "leathercoat-sec"
	item_state = "hostrench"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	dog_fashion = null

/obj/item/clothing/suit/armor/vest/capcarapace
	name = "captain's carapace"
	desc = "A fireproof armored chestpiece reinforced with ceramic plates and plasteel pauldrons to provide additional protection whilst still offering maximum mobility and flexibility. Issued only to the station's finest, although it does chafe your nipples."
	icon_state = "capcarapace"
	item_state = "armor"
	body_parts_covered = CHEST|GROIN
	armor = list(MELEE = 50, BULLET = 40, LASER = 50, ENERGY = 50, BOMB = 25, BIO = 0, RAD = 0, FIRE = 100, ACID = 90, WOUND = 30)
	dog_fashion = null
	resistance_flags = FIRE_PROOF

/obj/item/clothing/suit/armor/vest/capcarapace/centcom
	name = "CentCom Officer Vest"
	desc = "A sinister looking vest of advanced armor worn over a green and black fireproof jacket. The gold collar and shoulders denote that this belongs to a high ranking officer."
	icon_state = "centcom_vest"

/obj/item/clothing/suit/toggle/captains_parade
	name = "captain's parade jacket"
	desc = "For when an armoured vest isn't fashionable enough."
	icon_state = "capformal"
	item_state = "capspacesuit"
	body_parts_covered = CHEST|GROIN|ARMS
	armor = list(MELEE = 50, BULLET = 40, LASER = 50, ENERGY = 50, BOMB = 25, BIO = 0, RAD = 0, FIRE = 100, ACID = 90, WOUND = 30)
	togglename = "buttons"

/obj/item/clothing/suit/toggle/captains_parade/Initialize(mapload)
	. = ..()
	allowed = GLOB.security_wintercoat_allowed

/obj/item/clothing/suit/toggle/captains_parade/centcom_formal
	name = "\improper CentCom formal coat"
	desc = "A stylish coat given to CentCom Commanders. Perfect for sending ERTs to suicide missions with style!"
	icon_state = "centcom_formal"
	item_state = "centcom"

/obj/item/clothing/suit/toggle/captains_parade/hos_formal
	name = "\improper Head of Security's Parade Jacket"
	desc = "For when an armoured vest isn't fashionable enough."
	icon_state = "hosformal"
	item_state = "hostrench"

/obj/item/clothing/suit/armor/riot
	name = "riot suit"
	desc = "A suit of semi-flexible polycarbonate body armor with heavy padding to protect against melee attacks. Helps the wearer resist shoving in close quarters."
	icon_state = "riot"
	item_state = "riot"
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	armor = list(MELEE = 60, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 0, BIO = 0, RAD = 0, FIRE = 80, ACID = 80, WOUND = 30)
	blocks_shove_knockdown = TRUE
	mutantrace_variation = STYLE_DIGITIGRADE
	strip_delay = 80
	equip_delay_other = 60
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "riot",
			RESKIN_ITEM_STATE = "riot"
		),
		"Without Any Mark" = list(
			RESKIN_ICON_STATE = "riot-wm",
			RESKIN_ITEM_STATE = "riot"
		),
	)

/obj/item/clothing/suit/armor/riot/wm
	icon_state = "riot-wm"

/obj/item/clothing/suit/armor/bone
	name = "bone armor"
	desc = "A tribal armor plate, crafted from animal bone."
	icon_state = "bonearmor"
	item_state = "bonearmor"
	tail_state = ""
	blood_overlay_type = "armor"
	armor = list(MELEE = 35, BULLET = 25, LASER = 25, ENERGY = 35, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS

/obj/item/clothing/suit/armor/bulletproof
	name = "bulletproof armor"
	desc = "A Type III heavy bulletproof vest that excels in protecting the wearer against traditional projectile weaponry and explosives to a minor extent."
	icon_state = "bulletproof"
	item_state = "armor"
	blood_overlay_type = "armor"
	armor = list(MELEE = 15, BULLET = 60, LASER = 10, ENERGY = 10, BOMB = 40, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 20)
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	strip_delay = 70
	equip_delay_other = 50
	clothing_flags = THICKMATERIAL
	mutantrace_variation = STYLE_DIGITIGRADE
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "bulletproof",
			RESKIN_ITEM_STATE = "armor"
		),
		"Without Any Mark" = list(
			RESKIN_ICON_STATE = "bulletproof-wm",
			RESKIN_ITEM_STATE = "armor"
		),
	)

/obj/item/clothing/suit/armor/bulletproof/wm
	icon_state = "bulletproof-wm"

/obj/item/clothing/suit/armor/vest/det_suit
	name = "detective's armor vest"
	desc = "An armored vest with a detective's badge on it."
	icon_state = "detective-armor"
	resistance_flags = FLAMMABLE
	dog_fashion = null

/obj/item/clothing/suit/armor/vest/det_suit/Initialize(mapload)
	. = ..()
	allowed = GLOB.detective_vest_allowed

/obj/item/clothing/suit/armor/vest/infiltrator
	name = "insidious combat vest"
	desc = "An insidious combat vest designed using Syndicate nanofibers to absorb the supreme majority of kinetic blows. Although it doesn't look like it'll do too much for energy impacts."
	icon_state = "infiltrator"
	item_state = "infiltrator"
	armor = list(MELEE = 40, BULLET = 40, LASER = 30, ENERGY = 40, BOMB = 70, BIO = 0, RAD = 0, FIRE = 100, ACID = 100, WOUND = 20)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	strip_delay = 80

//All of the armor below is mostly unused

/obj/item/clothing/suit/armor/centcom
	name = "\improper CentCom armor"
	desc = "A suit that protects against some damage."
	icon_state = "centcom"
	item_state = "centcom"
	w_class = WEIGHT_CLASS_BULKY
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	allowed = list(/obj/item/gun/energy, /obj/item/melee/baton, /obj/item/restraints/handcuffs, /obj/item/tank/internals/emergency_oxygen, /obj/item/tank/internals/plasmaman)
	clothing_flags = THICKMATERIAL
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	cold_protection = CHEST | GROIN | LEGS | FEET | ARMS | HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	max_heat_protection_temperature = SPACE_SUIT_MAX_TEMP_PROTECT
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 50, BOMB = 100, BIO = 100, RAD = 100, FIRE = 90, ACID = 90, WOUND = 90)

/obj/item/clothing/suit/armor/heavy
	name = "heavy armor"
	desc = "A heavily armored suit that protects against moderate damage."
	icon_state = "heavy"
	item_state = "swat_suit"
	w_class = WEIGHT_CLASS_BULKY
	gas_transfer_coefficient = 0.9
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	slowdown = 3
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 50, BOMB = 100, BIO = 100, RAD = 100, FIRE = 90, ACID = 90, WOUND = 50)

/obj/item/clothing/suit/armor/tdome
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT|HIDETAUR
	clothing_flags = THICKMATERIAL
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	armor = list(MELEE = 80, BULLET = 80, LASER = 50, ENERGY = 50, BOMB = 100, BIO = 100, RAD = 100, FIRE = 90, ACID = 90)

/obj/item/clothing/suit/armor/tdome/red
	name = "thunderdome suit"
	desc = "Reddish armor."
	icon_state = "tdred"
	item_state = "tdred"
	tail_state = "syndicate-blood"

/obj/item/clothing/suit/armor/tdome/green
	name = "thunderdome suit"
	desc = "Pukish armor."	//classy.
	icon_state = "tdgreen"
	item_state = "tdgreen"
	tail_state = "syndicate-elite"

/obj/item/clothing/suit/armor/riot/knight
	name = "plate armour"
	desc = "A classic suit of plate armour, highly effective at stopping melee attacks."
	icon_state = "knight_green"
	item_state = "knight_green"
	armor = list(MELEE = 80, BULLET = 40, LASER = 10, ENERGY = 10, BOMB = 10, BIO = 0, RAD = 0, FIRE = 80, ACID = 80, WOUND = 30)
	slowdown = 0.5
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT

/obj/item/clothing/suit/armor/riot/knight/yellow
	icon_state = "knight_yellow"
	item_state = "knight_yellow"

/obj/item/clothing/suit/armor/riot/knight/blue
	icon_state = "knight_blue"
	item_state = "knight_blue"

/obj/item/clothing/suit/armor/riot/knight/red
	icon_state = "knight_red"
	item_state = "knight_red"

/obj/item/clothing/suit/armor/riot/knight/greyscale
	name = "knight armour"
	desc = "A classic suit of armour, able to be made from many different materials."
	icon_state = "knight_greyscale"
	item_state = "knight_greyscale"
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS //Can change color and add prefix

/obj/item/clothing/suit/armor/vest/durathread
	name = "makeshift vest"
	desc = "A vest made of durathread with strips of leather acting as trauma plates."
	icon_state = "durathread"
	item_state = "durathread"
	strip_delay = 60
	equip_delay_other = 40
	max_integrity = 200
	resistance_flags = FLAMMABLE
	clothing_flags = null
	armor = list(MELEE = 20, BULLET = 10, LASER = 30, ENERGY = 20, BOMB = 15, BIO = 0, RAD = 0, FIRE = 40, ACID = 50, WOUND = 10)

/obj/item/clothing/suit/armor/vest/russian
	name = "russian vest"
	desc = "A bulletproof vest with forest camo. Good thing there's plenty of forests to hide in around here, right?"
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_armor"
	item_state = "rus_armor"
	//armor = list(MELEE = 25, BULLET = 30, LASER = 0, ENERGY = 15, BOMB = 10, BIO = 0, RAD = 20, FIRE = 20, ACID = 50, WOUND = 10)

/obj/item/clothing/suit/armor/vest/russian_winter_coat
	name = "Russian Winter Coat"
	desc = "Used in extremly cold fronts, made out of real bears."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_winter_vsr93"
	item_state = "rus_winter_vsr93"
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	//armor = list(MELEE = 25, BULLET = 20, LASER = 20, ENERGY = 10, BOMB = 20, BIO = 50, RAD = 20, FIRE = -10, ACID = 50,  WOUND = 10)
	unique_reskin = list(
		"Default" = list("icon_state" = "rus_winter_vsr93"),
		"Unbuttoned" = list("icon_state" = "rus_winter_vsr93_t")
	)

/obj/item/clothing/suit/armor/vest/russian_coat
	name = "Russian Battle Coat"
	desc = "Used in extremly cold fronts, made out of real bears."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_coat"
	item_state = "rus_coat"
	clothing_flags = THICKMATERIAL
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	//armor = list(MELEE = 55, BULLET = 65, LASER = 65, ENERGY = 65, BOMB = 40, BIO = 50, RAD = 100, FIRE = 40, ACID = 50,  WOUND = 40)

/obj/item/clothing/suit/armor/vest/russian_coat/liquidator
	name = "Костюм Ликвидатора"
	desc = "Костюм, используемый для борьбы со всяким дерьмом."
	icon_state = "sov_offcoat"
	item_state = "sov_offcoat"
	//armor = list(MELEE = 25, BULLET = 20, LASER = 20, ENERGY = 10, BOMB = 20, BIO = 50, RAD = 50, FIRE = -10, ACID = 50,  WOUND = 10)
