// Одежда Кроликов

// Униформа
/obj/item/clothing/under/suit/lobotomy/rabbit
	name = "\improper r-corp uniform"
	desc = "A black uniform with a orange line worn by R-corps mercenaries."
	armor = list(MELEE = 10, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 10, BIO = 10, RAD = 10, FIRE = 100, ACID = 100)
	icon = 'modular_bluemoon/icons/obj/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniforms.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|USE_TAUR_CLIP_MASK|STYLE_NO_ANTHRO_ICON
	icon_state = "rabbit"

/obj/item/clothing/under/suit/lobotomy/rabbit/officer
	name = "\improper officer's uniform"
	desc = "A black uniform with a orange line worn by R-corps lieutenants. The rank boards on this are bronze."
	icon_state = "rabbitofficer"

// Шлем
/obj/item/clothing/head/rabbit_helmet //No armor since the ego-gears do it's job.
	name = "\improper rabbit team command helmet"
	desc = "An Combat helmet worn by R-Corporation mercenaries in the field, this one look rather unique"
	armor = list(MELEE = 50, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 50, BIO = 50, RAD = 50, FIRE = 100, ACID = 100)
	icon_state = "rabbit"
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDEEYES | HIDEEARS | HIDEHAIR | HIDESNOUT
	visor_flags_inv = 0
	dynamic_hair_suffix = ""

/obj/item/clothing/head/rabbit_helmet/grunt
	name = "\improper rabbit team helmet"
	desc = "An Combat helmet worn by R-Corporation mercenaries in the field."
	armor = list(MELEE = 50, BULLET = 50, LASER = 50,ENERGY = 50, BOMB = 50, BIO = 50, RAD = 50, FIRE = 100, ACID = 100)
	icon_state = "rabbit"

/obj/item/clothing/head/rabbit_helmet/grunt/Initialize(mapload)
	. = ..()
	icon_state = pick("rabbit_grunt", "rabbit_grunt_one", "rabbit_grunt_two", "rabbit_grunt_three")
	if(prob(1))
		desc = "I'm all ears, honestly."
		mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/large-worn-icons/32x64/head.dmi'
		icon_state = "rabbit_grunt_four"


// Верхняя одежда
/obj/item/clothing/suit/armor/ego_gear/rabbit
	name = "\improper rabbit team command suit"
	desc = "An armored combat suit worn by R-Corporation 4th pack infantry commanders. The orange cloak denotes the rank of 'Captain', as a beacon for the infantry to follow."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "rabbit"
	armor = list(MELEE = 50, BULLET = 50, LASER = 50,ENERGY = 50, BOMB = 50, BIO = 50, RAD = 50, FIRE = 100, ACID = 100)
	brc_mitigation_bonus = 15  // BLUEMOON ADD

/obj/item/clothing/suit/armor/ego_gear/rabbit/grunts
	name = "\improper rabbit suppressive suit"
	desc = "An armored combat suit worn by R-Corporation light infantry shocktroopers. It's cape is long, but the material catches shrapnel well."
	icon_state = "rabbit_grunt"
	armor = list(MELEE = 50, BULLET = 50, LASER = 50,ENERGY = 50, BOMB = 50, BIO = 50, RAD = 50, FIRE = 100, ACID = 100)
