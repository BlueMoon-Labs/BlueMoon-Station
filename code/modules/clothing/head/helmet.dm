/obj/item/clothing/head/helmet
	name = "Helmet"
	desc = "Standard Security gear. Protects the head from impacts."
	icon_state = "helmet"
	item_state = "helmet"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)
	cold_protection = HEAD
	min_cold_protection_temperature = HELMET_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = HELMET_MAX_TEMP_PROTECT
	strip_delay = 60
	resistance_flags = NONE
	clothing_flags = THICKMATERIAL
	flags_cover = HEADCOVERSEYES
	flags_inv = HIDEHAIR|HIDEEARS
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""

	dog_fashion = /datum/dog_fashion/head/helmet

	var/can_flashlight = FALSE //if a flashlight can be mounted. if it has a flashlight and this is false, it is permanently attached.
	var/obj/item/flashlight/seclite/attached_light
	var/datum/action/item_action/toggle_helmet_flashlight/alight

/obj/item/clothing/head/helmet/Initialize(mapload)
	. = ..()
	if(attached_light)
		alight = new(src)

/obj/item/clothing/head/helmet/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/wearertargeting/earprotection, list(ITEM_SLOT_HEAD))

/obj/item/clothing/head/helmet/examine(mob/user)
	. = ..()
	if(attached_light)
		. += "It has \a [attached_light] [can_flashlight ? "" : "permanently "]mounted on it."
		if(can_flashlight)
			. += "<span class='info'>[attached_light] looks like it can be <b>unscrewed</b> from [src].</span>"
	else if(can_flashlight)
		. += "It has a mounting point for a <b>seclite</b>."

/obj/item/clothing/head/helmet/Destroy()
	QDEL_NULL(attached_light)
	return ..()

/obj/item/clothing/head/helmet/handle_atom_del(atom/A)
	if(A == attached_light)
		attached_light = null
		update_helmlight()
		update_icon()
		QDEL_NULL(alight)
	return ..()

/obj/item/clothing/head/helmet/sec
	can_flashlight = 1
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "helmet",
			RESKIN_ITEM_STATE = "helmet"
		),
		"Old" = list(
			RESKIN_ICON_STATE = "helmetold",
			RESKIN_ITEM_STATE = "helmetold"
		),
		// BLUEMOON ADD START - RESKINS-ICON-FILE-ADDITION - ACRADORS - версия шлема для ушей акрадоров
		"Acrador/Long-Eared" = list(
			RESKIN_ICON_STATE = "acrador_helmet",
			RESKIN_ITEM_STATE = "acrador_helmet",
			RESKIN_ICON_STATE_FILE = 'modular_bluemoon/icons/obj/clothing/hats.dmi',
			RESKIN_WORN_STATE_FILE = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
		),
		// BLUEMOON ADD END
	)

/obj/item/clothing/head/helmet/sec/attackby(obj/item/I, mob/user, params)
	if(issignaler(I))
		var/obj/item/assembly/signaler/S = I
		if(attached_light) //Has a flashlight. Player must remove it, else it will be lost forever.
			to_chat(user, "<span class='warning'>The mounted flashlight is in the way, remove it first!</span>")
			return

		if(S.secured)
			qdel(S)
			var/obj/item/bot_assembly/secbot/A = new
			user.put_in_hands(A)
			to_chat(user, "<span class='notice'>You add the signaler to the helmet.</span>")
			qdel(src)
			return
	return ..()

GLOBAL_LIST_INIT(aventail_detail_colors, list(
	"Red" = "#8b2323",
	"Purple" = "#8747b1",
	"Black" = "#2b292e",
	"Brown" = "#61462c",
	"Green" = "#428138",
	"Blue" = "#173266",
	"Yellow" = "#ffcd43",
	"Teal" = "#249589",
	"Azure" = "#007fff",
	"White" = "#ffffff",
	"Orange" = "#df8405",
	"Magenta" = "#962e5c",
	"Gold" = "#f9a602",
	"Scarlet" = "#cc0000",
))
GLOBAL_PROTECT(aventail_detail_colors)

GLOBAL_LIST_INIT(aventail_pride_colors, list(
	"Rainbow" = "#fcfcfc",
))
GLOBAL_PROTECT(aventail_pride_colors)

/obj/item/clothing/head/helmet/military
	name = "Hounskull With Aventail"
	desc = "A steel hounskull bascinet with a thick maille aventail secured to the inside. Just as a froggemund befits a knight in the tournaments, an \
	aventailed bascinet befits a knight on the battlefield; unmatched in coverage, durability, and weight."
	icon_state = "visaventail"
	item_state = "visaventail"
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	strip_delay = 80
	dog_fashion = null
	armor = list(MELEE = 20, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 10, ACID = 50, WOUND = 50)
	can_toggle = TRUE
	toggle_message = "You pull the visor down on"
	alt_toggle_message = "You push the visor up on"
	actions_types = list(/datum/action/item_action/toggle)
	visor_flags_inv = HIDEEYES|HIDEFACE|HIDESNOUT
	visor_flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	toggle_cooldown = 0
	active_sound = 'sound/machines/closet_open.ogg'
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	var/detail_tag
	var/detail_color
	var/altdetail_tag
	var/altdetail_color

/obj/item/clothing/head/helmet/military/examine(mob/user)
	. = ..()
	. += span_notice("You can add a <b>feather</b> for a colored plume, or a sheet of <b>cloth</b> for an orle.")

/obj/item/clothing/head/helmet/military/attack_self(mob/user)
	if(can_toggle && !user.incapacitated())
		if(world.time > cooldown + toggle_cooldown)
			cooldown = world.time
			up = !up
			flags_inv ^= visor_flags_inv
			flags_cover ^= visor_flags_cover
			icon_state = "[initial(icon_state)][up ? "_t" : ""]"
			to_chat(user, "[up ? alt_toggle_message : toggle_message] \the [src]")
			update_icon()
			user.update_inv_head()
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.head_update(src, forced = 1)
			if(active_sound && up)
				playsound(src.loc, active_sound, 100, 0, 4)

/obj/item/clothing/head/helmet/military/attackby(obj/item/W, mob/living/user, params)
	. = ..()
	if(istype(W, /obj/item/feather) && !detail_tag)
		var/choice = input(user, "Choose a color.", "Plume") as anything in GLOB.aventail_detail_colors + GLOB.aventail_pride_colors
		if(!choice)
			return
		detail_color = (choice in GLOB.aventail_pride_colors) ? GLOB.aventail_pride_colors[choice] : GLOB.aventail_detail_colors[choice]
		detail_tag = "_detail"
		user.visible_message(span_warning("[user] adds [W] to [src]."))
		user.transferItemToLoc(W, src, FALSE, FALSE)
		qdel(W)
		update_icon()
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
	if(istype(W, /obj/item/stack/sheet/cloth) && !altdetail_tag)
		var/obj/item/stack/sheet/cloth/C = W
		if(C.amount < 1)
			return
		var/choicealt = input(user, "Choose a color.", "Orle") as anything in GLOB.aventail_detail_colors + GLOB.aventail_pride_colors
		if(!choicealt)
			return
		user.visible_message(span_warning("[user] adds [W] to [src]."))
		altdetail_color = (choicealt in GLOB.aventail_pride_colors) ? GLOB.aventail_pride_colors[choicealt] : GLOB.aventail_detail_colors[choicealt]
		// Орле не имеет права трогать detail_tag: это слот плюмажа, и запись в него блокировала
		// добавление пера, а уже вставленное перо подменяла спрайтом, которого в dmi нет вовсе.
		altdetail_tag = "_detailalt"
		C.use(1)
		update_icon()
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()

/obj/item/clothing/head/helmet/military/update_icon_state()
	icon_state = "[initial(icon_state)][up ? "_t" : ""]"

/obj/item/clothing/head/helmet/military/update_icon()
	cut_overlays()
	update_icon_state()
	if(detail_tag)
		var/mutable_appearance/pic = mutable_appearance(icon(icon, "[icon_state][detail_tag]"))
		pic.appearance_flags = RESET_COLOR
		if(detail_color)
			pic.color = detail_color
		add_overlay(pic)
	if(altdetail_tag)
		var/mutable_appearance/pic2 = mutable_appearance(icon(icon, "[icon_state][altdetail_tag]"))
		pic2.appearance_flags = RESET_COLOR
		if(altdetail_color)
			pic2.color = altdetail_color
		add_overlay(pic2)

/obj/item/clothing/head/helmet/military/worn_overlays(isinhands = FALSE, icon_file, used_state, style_flags = NONE)
	. = ..()
	if(isinhands)
		return
	if(detail_tag)
		var/mutable_appearance/pic = mutable_appearance(icon(icon_file, "[used_state][detail_tag]"))
		pic.appearance_flags = RESET_COLOR
		if(detail_color)
			pic.color = detail_color
		. += pic
	if(altdetail_tag)
		var/mutable_appearance/pic2 = mutable_appearance(icon(icon_file, "[used_state][altdetail_tag]"))
		pic2.appearance_flags = RESET_COLOR
		if(altdetail_color)
			pic2.color = altdetail_color
		. += pic2

/obj/item/clothing/head/helmet/knight/warlord
	name = "golden barbute helmet"
	desc = "There is no man behind the helmet, only a terrible thought."
	icon_state = "warlord"
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 50)
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEMASK|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	slowdown = 0.2

/obj/item/clothing/head/helmet/nvg
	name = "NVG Helmet"
	desc = "Standard Security gear. Protects the head from impacts. Equipped with a night vision apparatus on the front edge."
	icon_state = "helmetNVG"
	item_state = "helmetNVG"
	darkness_view = 8
	flash_protect = -1
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	color_cutoffs = list(10, 25, 10)

/obj/item/clothing/head/helmet/nvg/hecu
	name = "Powered Combat Helmet with NVG"
	desc = "A deprecated combat helmet developed during the early 21th century in Sol-3, with protections rated level III-A. Protects the head from impacts. Equipped with a night vision apparatus on the front edge."
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_muzzled.dmi'
	icon_state = "hecu_helm_nvg"
	item_state = "hecu_helm_nvg"
	darkness_view = 10
	flash_protect = -1
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
	color_cutoffs = list(10, 25, 10)
	mutantrace_variation = STYLE_MUZZLE
	armor = list(MELEE = 40, BULLET = 40, LASER = 40,ENERGY = 40, BOMB = 50, BIO = 90, RAD = 30, FIRE = 50, ACID = 50, WOUND = 20)
	cold_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_HELM_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE
	can_toggle = TRUE
	actions_types = list(/datum/action/item_action/toggle)
	active_sound = 'sound/machines/closet_open.ogg'
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "hecu_helm_nvg",
			RESKIN_ITEM_STATE = "hecu_helm_nvg"
		),
		"Basic Black" = list(
			RESKIN_ICON_STATE = "hecu_helm_nvg_black",
			RESKIN_ITEM_STATE = "hecu_helm_nvg_black"
		),
	)

/obj/item/clothing/head/helmet/nvg/hecu/attack_self(mob/user)
	if(can_toggle && !user.incapacitated())
		if(world.time > cooldown + toggle_cooldown)
			cooldown = world.time
			up = !up
			flags_1 ^= visor_flags
			flags_inv ^= visor_flags_inv
			flags_cover ^= visor_flags_cover
			icon_state = "[replacetext("[icon_state]", "_up", "")][up ? "_up" : ""]"
			darkness_view = 0
			to_chat(user, "[up ? alt_toggle_message : toggle_message] \the [src]")

			user.update_inv_head()
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.head_update(src, forced = 1)

			if(active_sound)
				if(up)
					playsound(src.loc, "[active_sound]", 100, 0, 4)

/obj/item/clothing/head/helmet/alt
	name = "bulletproof Helmet"
	desc = "A bulletproof combat helmet that excels in protecting the wearer against traditional projectile weaponry and explosives to a minor extent."
	icon_state = "helmetalt"
	item_state = "helmetalt"
	armor = list(MELEE = 15, BULLET = 60, LASER = 10, ENERGY = 10, BOMB = 40, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 20)
	can_flashlight = 1
	dog_fashion = null
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "helmet",
			RESKIN_ITEM_STATE = "helmet"
		),
		"Old" = list(
			RESKIN_ICON_STATE = "helmetold",
			RESKIN_ITEM_STATE = "helmetold"
		),
		// BLUEMOON ADD START - RESKINS-ICON-FILE-ADDITION - ACRADORS - версия шлема для ушей акрадоров
		"Acrador/Long-Eared" = list(
			RESKIN_ICON_STATE = "acrador_helmetalt",
			RESKIN_ITEM_STATE = "acrador_helmetalt",
			RESKIN_ICON_STATE_FILE = 'modular_bluemoon/icons/obj/clothing/hats.dmi',
			RESKIN_WORN_STATE_FILE = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
		),
		// BLUEMOON ADD END
	)

/obj/item/clothing/head/helmet/old
	name = "degrading Helmet"
	desc = "Standard issue security helmet. Due to degradation the helmet's visor obstructs the users ability to see long distances."
	tint = 2
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	icon_state = "helmetold"
	item_state = "helmetold"

/obj/item/clothing/head/helmet/blueshirt
	name = "peacekeeper Helmet"
	desc = "A reliable, blue tinted helmet reminding you that you <i>still</i> owe that engineer a beer."
	icon_state = "peacekeeper"
	item_state = "peacekeeper"
	custom_premium_price = PRICE_ABOVE_EXPENSIVE
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""

/obj/item/clothing/head/helmet/riot
	name = "Riot Helmet"
	desc = "It's a helmet specifically designed to protect against close range attacks."
	icon_state = "riot"
	item_state = "helmet"
	toggle_message = "You pull the visor down on"
	alt_toggle_message = "You push the visor up on"
	can_toggle = 1
	armor = list(MELEE = 45, BULLET = 15, LASER = 5,ENERGY = 5, BOMB = 5, BIO = 2, RAD = 0, FIRE = 50, ACID = 50, WOUND = 30)
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	strip_delay = 80
	actions_types = list(/datum/action/item_action/toggle)
	visor_flags_inv = HIDEFACE
	toggle_cooldown = 0
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	visor_flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	clothing_flags = null
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	dog_fashion = null
	mutantrace_variation = STYLE_MUZZLE
	active_sound = 'sound/machines/closet_open.ogg'

/obj/item/clothing/head/helmet/attack_self(mob/user)
	if(can_toggle && !user.incapacitated())
		if(world.time > cooldown + toggle_cooldown)
			cooldown = world.time
			up = !up
			flags_1 ^= visor_flags
			flags_inv ^= visor_flags_inv
			flags_cover ^= visor_flags_cover
			icon_state = "[replacetext("[icon_state]", "_up", "")][up ? "_up" : ""]"
			to_chat(user, "[up ? alt_toggle_message : toggle_message] \the [src]")

			user.update_inv_head()
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.head_update(src, forced = 1)

			if(active_sound)
				if(up)
					playsound(src.loc, "[active_sound]", 100, 0, 4)

/obj/item/clothing/head/helmet/justice
	name = "helmet of justice"
	desc = "WEEEEOOO. WEEEEEOOO. WEEEEOOOO."
	icon_state = "justice"
	toggle_message = "You turn off the lights on"
	alt_toggle_message = "You turn on the lights on"
	actions_types = list(/datum/action/item_action/toggle_helmet_light)
	var/datum/looping_sound/siren/weewooloop
	can_toggle = TRUE
	toggle_cooldown = 20
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	dog_fashion = null

/obj/item/clothing/head/helmet/justice/Initialize(mapload)
	. = ..()
	weewooloop = new(src, FALSE, FALSE)

/obj/item/clothing/head/helmet/justice/Destroy()
	QDEL_NULL(weewooloop)
	return ..()

/obj/item/clothing/head/helmet/justice/attack_self(mob/user)
	. = ..()
	if(up)
		weewooloop.start()
	else
		weewooloop.stop()

/obj/item/clothing/head/helmet/justice/escape
	name = "alarm Helmet"
	desc = "WEEEEOOO. WEEEEEOOO. STOP THAT MONKEY. WEEEOOOO."
	icon_state = "justice2"
	toggle_message = "You turn off the light on"
	alt_toggle_message = "You turn on the light on"
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""

/obj/item/clothing/head/helmet/swat
	name = "\improper SWAT Helmet"
	desc = "An extremely robust, space-worthy helmet in a nefarious red and black stripe pattern."
	icon_state = "swatsyndie"
	item_state = "swatsyndie"
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 30, BOMB = 50, BIO = 90, RAD = 20, FIRE = 50, ACID = 50, WOUND = 20)
	cold_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_HELM_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	strip_delay = 80
	dog_fashion = null

/obj/item/clothing/head/helmet/swat/nanotrasen
	name = "\improper SWAT Helmet"
	desc = "An extremely robust, space-worthy helmet with the Nanotrasen logo emblazoned on the top."
	icon_state = "swat"
	item_state = "swat"
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""

/obj/item/clothing/head/helmet/swat/nanotrasen/altyn
	name = "Altyn Helmet"
	desc = "Баллистический шлем герметичного типа. Имеет стилистическое украшение."
	icon_state = "altyn"
	actions_types = list(/datum/action/item_action/toggle)
	can_toggle = TRUE
	active_sound = 'sound/machines/closet_open.ogg'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Black Variant" = list(
			RESKIN_ICON_STATE = "altyn_black"
		),
		"Brown Variant" = list(
			RESKIN_ICON_STATE = "altyn_brown"
		),
		"Tri Poloski Variant" = list(
			RESKIN_ICON_STATE = "altyn_tripoloski"
		),
	)

/obj/item/clothing/head/helmet/swat/nanotrasen/altyn/attack_self(mob/user)
	if(can_toggle && !user.incapacitated())
		if(world.time > cooldown + toggle_cooldown)
			cooldown = world.time
			up = !up
			flags_1 ^= visor_flags
			flags_inv ^= visor_flags_inv
			flags_cover ^= visor_flags_cover
			icon_state = "[replacetext("[icon_state]", "_up", "")][up ? "_up" : ""]"
			to_chat(user, "[up ? alt_toggle_message : toggle_message] \the [src]")

			user.update_inv_head()
			if(iscarbon(user))
				var/mob/living/carbon/C = user
				C.head_update(src, forced = 1)

			if(active_sound)
				if(up)
					playsound(src.loc, "[active_sound]", 100, 0, 4)

//Commander
/obj/item/clothing/head/helmet/swat/command
	name = "\improper Emergency Response Team commander Helmet"
	desc = "An in-atmosphere helmet worn by the commander of a Nanotrasen Emergency Response Team. Has blue highlights."
	icon_state = "erthelmet_cmd"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//Security
/obj/item/clothing/head/helmet/swat/security
	name = "\improper Emergency Response Team security Helmet"
	desc = "An in-atmosphere helmet worn by security members of the Nanotrasen Emergency Response Team. Has red highlights."
	icon_state = "erthelmet_sec"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//Engineer
/obj/item/clothing/head/helmet/swat/engineer
	name = "\improper Emergency Response Team engineer Helmet"
	desc = "An in-atmosphere helmet worn by engineering members of the Nanotrasen Emergency Response Team. Has orange highlights."
	icon_state = "erthelmet_eng"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//Medical
/obj/item/clothing/head/helmet/swat/medical
	name = "\improper Emergency Response Team medical Helmet"
	desc = "A set of armor worn by medical members of the Nanotrasen Emergency Response Team. Has red and white highlights."
	icon_state = "erthelmet_med"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

//Janitorial
/obj/item/clothing/head/helmet/swat/janitor
	name = "\improper Emergency Response Team janitor Helmet"
	desc = "A set of armor worn by janitorial members of the Nanotrasen Emergency Response Team. Has red and white highlights."
	icon_state = "erthelmet_jan"

/obj/item/clothing/head/helmet/thunderdome
	name = "\improper Thunderdome Helmet"
	desc = "<i>'Let the battle commence!'</i>"
	flags_inv = HIDEEARS|HIDEHAIR
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	icon_state = "thunderdome"
	item_state = "thunderdome"
	armor = list(MELEE = 40, BULLET = 30, LASER = 25,ENERGY = 10, BOMB = 25, BIO = 10, RAD = 0, FIRE = 50, ACID = 50)
	cold_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	heat_protection = HEAD
	max_heat_protection_temperature = SPACE_HELM_MAX_TEMP_PROTECT
	strip_delay = 80
	dog_fashion = null

/obj/item/clothing/head/helmet/roman
	name = "\improper Roman Helmet"
	desc = "An ancient helmet made of bronze and leather."
	flags_inv = HIDEEARS|HIDEHAIR
	flags_cover = HEADCOVERSEYES
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	armor = list(MELEE = 25, BULLET = 0, LASER = 25, ENERGY = 10, BOMB = 10, BIO = 0, RAD = 0, FIRE = 100, ACID = 50)
	resistance_flags = FIRE_PROOF
	clothing_flags = null
	icon_state = "roman"
	item_state = "roman"
	strip_delay = 100
	dog_fashion = null

/obj/item/clothing/head/helmet/roman/fake
	desc = "An ancient helmet made of plastic and leather."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/head/helmet/roman/legionnaire
	name = "\improper Roman legionnaire Helmet"
	desc = "An ancient helmet made of bronze and leather. Has a red crest on top of it."
	icon_state = "roman_c"
	item_state = "roman_c"

/obj/item/clothing/head/helmet/roman/legionnaire/fake
	desc = "An ancient helmet made of plastic and leather. Has a red crest on top of it."
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/head/helmet/gladiator
	name = "gladiator Helmet"
	desc = "Ave, Imperator, morituri te salutant."
	icon_state = "gladiator"
	item_state = "gladiator"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEHAIR
	flags_cover = HEADCOVERSEYES
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	dog_fashion = null

/obj/item/clothing/head/helmet/redtaghelm
	name = "red laser tag Helmet"
	desc = "They have chosen their own end."
	icon_state = "redtaghelm"
	flags_cover = HEADCOVERSEYES
	clothing_flags = null
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	item_state = "redtaghelm"
	armor = list(MELEE = 15, BULLET = 10, LASER = 20,ENERGY = 10, BOMB = 20, BIO = 0, RAD = 0, FIRE = 0, ACID = 50)
	// Offer about the same protection as a hardhat.
	dog_fashion = null

/obj/item/clothing/head/helmet/bluetaghelm
	name = "blue laser tag Helmet"
	desc = "They'll need more men."
	icon_state = "bluetaghelm"
	clothing_flags = null
	flags_cover = HEADCOVERSEYES
	item_state = "bluetaghelm"
	armor = list(MELEE = 15, BULLET = 10, LASER = 20,ENERGY = 10, BOMB = 20, BIO = 0, RAD = 0, FIRE = 0, ACID = 50)
	// Offer about the same protection as a hardhat.
	dog_fashion = null

/obj/item/clothing/head/helmet/knight
	name = "medieval Helmet"
	desc = "A classic metal helmet."
	icon_state = "knight_green"
	item_state = "knight_green"
	armor = list(MELEE = 60, BULLET = 35, LASER = 5,ENERGY = 5, BOMB = 5, BIO = 2, RAD = 0, FIRE = 0, ACID = 50)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	clothing_flags = null
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	strip_delay = 80
	dog_fashion = null
	mutantrace_variation = STYLE_MUZZLE

/obj/item/clothing/head/helmet/knight/Initialize(mapload)
	. = ..()
	var/datum/component = GetComponent(/datum/component/wearertargeting/earprotection)
	qdel(component)

/obj/item/clothing/head/helmet/knight/blue
	icon_state = "knight_blue"
	item_state = "knight_blue"

/obj/item/clothing/head/helmet/knight/yellow
	icon_state = "knight_yellow"
	item_state = "knight_yellow"

/obj/item/clothing/head/helmet/knight/red
	icon_state = "knight_red"
	item_state = "knight_red"

/obj/item/clothing/head/helmet/knight/greyscale
	name = "knight Helmet"
	desc = "A classic medieval helmet, if you hold it upside down you could see that it's actually a bucket."
	icon_state = "knight_greyscale"
	item_state = "knight_greyscale"
	armor = list(MELEE = 35, BULLET = 10, LASER = 10, ENERGY = 10, BOMB = 10, BIO = 10, RAD = 10, FIRE = 40, ACID = 40, WOUND = 20)
	material_flags = MATERIAL_ADD_PREFIX | MATERIAL_COLOR | MATERIAL_AFFECT_STATISTICS //Can change color and add prefix

/obj/item/clothing/head/helmet/skull
	name = "skull Helmet"
	desc = "An intimidating tribal helmet, it doesn't look very comfortable."
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE
	flags_cover = HEADCOVERSEYES
	armor = list(MELEE = 25, BULLET = 25, LASER = 25, ENERGY = 10, BOMB = 10, BIO = 5, RAD = 20, FIRE = 40, ACID = 20, WOUND = 15)
	icon_state = "skull"
	item_state = "skull"
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	strip_delay = 100
	mutantrace_variation = STYLE_MUZZLE

/obj/item/clothing/head/helmet/infiltrator
	name = "insidious Helmet"
	desc = "An insidious armored combat helmet signed with Syndicate insignia. The visor is coated with a resistant paste guaranteed to withstand bright flashes perfectly."
	icon_state = "infiltrator"
	item_state = "infiltrator"
	armor = list(MELEE = 40, BULLET = 40, LASER = 30, ENERGY = 40, BOMB = 70, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 35)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flash_protect = 2
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	strip_delay = 80
	mutantrace_variation = STYLE_MUZZLE

//LightToggle

/obj/item/clothing/head/helmet/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/clothing/head/helmet/update_icon_state()
	var/state = "[initial(icon_state)]"
	if(attached_light)
		if(attached_light.on)
			state += "-flight-on" //"helmet-flight-on" // "helmet-cam-flight-on"
		else
			state += "-flight" //etc.

	icon_state = state

/obj/item/clothing/head/helmet/ui_action_click(mob/user, action)
	if(istype(action, alight))
		toggle_helmlight()
	else
		..()

/obj/item/clothing/head/helmet/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/flashlight/seclite))
		var/obj/item/flashlight/seclite/S = I
		if(can_flashlight && !attached_light)
			if(!user.transferItemToLoc(S, src))
				return
			to_chat(user, "<span class='notice'>You click [S] into place on [src].</span>")
			if(S.on)
				set_light(0)
			attached_light = S
			update_icon()
			update_helmlight()
			alight = new(src)
			if(loc == user)
				alight.Grant(user)
		return
	return ..()

/obj/item/clothing/head/helmet/screwdriver_act(mob/living/user, obj/item/I)
	..()
	if(can_flashlight && attached_light) //if it has a light but can_flashlight is false, the light is permanently attached.
		I.play_tool_sound(src)
		to_chat(user, "<span class='notice'>You unscrew [attached_light] from [src].</span>")
		attached_light.forceMove(drop_location())
		if(Adjacent(user) && !issilicon(user))
			user.put_in_hands(attached_light)

		var/obj/item/flashlight/removed_light = attached_light
		attached_light = null
		update_helmlight()
		removed_light.update_brightness(user)
		update_icon()
		user.update_inv_head()
		QDEL_NULL(alight)
		return TRUE

/obj/item/clothing/head/helmet/proc/toggle_helmlight()
	set name = "Toggle Helmetlight"
	set category = "Object"
	set desc = "Click to toggle your helmet's attached flashlight."

	if(!attached_light)
		return

	var/mob/user = usr
	if(user.incapacitated())
		return
	attached_light.on = !attached_light.on
	to_chat(user, "<span class='notice'>You toggle the helmet-light [attached_light.on ? "on":"off"].</span>")

	playsound(user, 'sound/weapons/empty.ogg', 100, 1)
	update_helmlight(user)

/obj/item/clothing/head/helmet/proc/update_helmlight(mob/user = null)
	if(attached_light)
		if(attached_light.on)
			set_light(attached_light.brightness_on, attached_light.flashlight_power, attached_light.light_color)
		else
			set_light(0)
		update_icon()

	else
		set_light(0)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtons()

/obj/item/clothing/head/helmet/durathread
	name = "makeshift Helmet"
	desc = "A hardhat with strips of leather and durathread for additional blunt protection."
	icon_state = "durathread"
	item_state = "durathread"
	armor = list(MELEE = 25, BULLET = 10, LASER = 20,ENERGY = 10, BOMB = 30, BIO = 15, RAD = 20, FIRE = 100, ACID = 50)
	clothing_flags = null

/obj/item/clothing/head/helmet/rus_helmet
	name = "Russian Helmet"
	desc = "It can hold a bottle of vodka."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_helmet"
	item_state = "rus_helmet"
	flags_inv = HIDEEARS
	//armor = list(MELEE = 30, BULLET = 25, LASER = 20,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 20, FIRE = 30, ACID = 50)
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/small/rushelmet
	clothing_flags = null

/obj/item/clothing/head/helmet/rus_cap
	name = "Russian Officer's Hat"
	desc = "It can hold a bottle of vodka."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "ruscap"
	item_state = "ruscap"
	flags_inv = HIDEEARS
	armor = list(MELEE = 30, BULLET = 25, LASER = 20,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 20, FIRE = 30, ACID = 50)
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/small/rushelmet
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "ruscap",
			RESKIN_ITEM_STATE = "ruscap"
		),
		"Darker" = list(
			RESKIN_ICON_STATE = "rusoffcap",
			RESKIN_ITEM_STATE = "rusoffcap"
		),
	)

/obj/item/clothing/head/helmet/rus_ushanka
	name = "Battle Ushanka"
	desc = "100% bear."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "rus_ushanka"
	item_state = "rus_ushanka"
	clothing_flags = THICKMATERIAL
	body_parts_covered = HEAD
	cold_protection = HEAD
	flags_inv = HIDEEARS
	min_cold_protection_temperature = SPACE_SUIT_MIN_TEMP_PROTECT
	armor = list(MELEE = 10, BULLET = 5, LASER = 5,ENERGY = 5, BOMB = 5, BIO = 50, RAD = 20, FIRE = -10, ACID = 0)

/obj/item/clothing/head/helmet/police
	name = "police officer's hat"
	desc = "A police officer's Hat. This hat emphasizes that you are THE LAW."
	icon_state = "policehelm"
	dynamic_hair_suffix = ""
	flags_inv = HIDEEARS

// Elder Atmosian — шлем легендарного атмос-теха (спрайты из WhiteMoon modular_zubbers)
/obj/item/clothing/head/helmet/elder_atmosian
	name = "\improper Elder Atmosian Helmet"
	desc = "Вершина атмос-экипировки: огнезащитный шлем, усиленный металлическим водородом. Полная защита головы от огня и газов."
	icon = 'modular_bluemoon/icons/obj/clothing/head/helmet.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/head/helmet.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/head/helmet_teshari.dmi'
	icon_state = "h2helmet"
	item_state = "h2_helmet"
	armor = list(MELEE = 50, BULLET = 45, LASER = 55, ENERGY = 55, BOMB = 95, BIO = 100, RAD = 100, FIRE = 100, ACID = 90, WOUND = 30)
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	cold_protection = HEAD
	heat_protection = HEAD
	min_cold_protection_temperature = SPACE_HELM_MIN_TEMP_PROTECT
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL | BLOCK_GAS_SMOKE_EFFECT
	resistance_flags = FIRE_PROOF
