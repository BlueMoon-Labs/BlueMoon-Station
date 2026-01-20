/obj/item/clothing/suit/donator/bm
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/hooded/bm
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'

/obj/item/clothing/head/hooded/bm
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'

/obj/item/clothing/suit/donator/bm/lightning_holocloak
	name = "lightning holo-cloak"
	desc = "When equipped, a strange hologram is activated, and the fabric of the cloak itself disappears, and lightning starts projecting all over the body."
	icon_state = "lightning_holo"
	item_state = "welding-g"
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Blue" = list(
			"icon_state" = "lightning_holo_blue",
			"item_state" = "lightning_holo_blue",
			"name" = "blue lightning holo-cloak"
		),
		"Pink" = list(
			"icon_state" = "lightning_holo_pink",
			"item_state" = "lightning_holo_pink",
			"name" = "pink lightning holo-cloak"
		),
		"Red" = list(
			"icon_state" = "lightning_holo_red",
			"item_state" = "lightning_holo_red",
			"name" = "red lightning holo-cloak"
		),
		"Yellow" = list(
			"icon_state" = "lightning_holo_yellow",
			"item_state" = "lightning_holo_yellow",
			"name" = "yellow lightning holo-cloak"
		)
	)

/obj/item/clothing/suit/donator/bm/cerberus_suit
	name = "Cerberus Coat"
	desc = "Бронированое пальто болотного цвета с кучей пуговиц. Ходят слухи, что новых уже давно не делают, а те что имеются - снимают с трупов для дальнейшего ношения. От него пованивает тухлым мясом."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "cerberussuit_mob"
	item_state = "greatcoat"

/obj/item/clothing/suit/donator/bm/bishop_mantle
	name = "Bishop Mantle"
	desc = "Несмотря на бирку с ценником в девяноста девять, выглядит достаточно убедительно, чтобы считать носителя проповедником."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "bishop_mantle"
	item_state = "greatcoat"

/obj/item/clothing/suit/donator/bm/censor_fem_suit
	name = "censor coat"
	desc = "Бронированная шинель... Или то что от неё осталось? Наручи и поножи отсутствуют, хотя должны иметься в комплекте. На всю грудь раскинуто красное полотно с рисунком чёрной птицы на нём."
	icon = 'modular_bluemoon/krashly/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/krashly/icons/mob/clothing/suits.dmi'
	icon_state = "censor_fem"
	item_state = "censor_fem"

/obj/item/modkit/Dina_Kit
	name = "Kikimora Suit Kit"
	desc = "A modkit for making a Elite Syndicate Hardsuit into a Kikimora MK1."
	product = /obj/item/clothing/suit/space/hardsuit/security/kikimora
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/security)

/obj/item/clothing/head/helmet/space/hardsuit/security/kikimora
	name = "ACS.Kikimora-MK2 Helmet"
	desc = "Модифицированный штатный Бронескафандр Лорданианских пилотов для ВКД даже в боевых условиях. Выполняет все необходимые от него функции."
	icon_state = "hardsuit0-kikimora"
	hardsuit_type = "kikimora"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/space/hardsuit/security/kikimora
	name = "ACS.Kikimora-MK2 Hardsuit"
	desc = "Модифицированный штатный Бронескафандр Лорданианских пилотов для ВКД даже в боевых условиях. Выполняет все необходимые от него функции."
	icon_state = "hardsuit0-kikimora"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/kikimora
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/angelo
	name = "angelo's trenchcoat"
	desc = "Thick leather trench coat with stitched red edges on the collar. The right shoulder is decorated with an aiguillette. On the sleeves, patterns in the form of a three-headed hydra can be distinguished. Without a doubt, this cloak went to the owner as a reward from the higher command, as confirmation of his status. Interesting."
	icon_state = "angelo"
	item_state = "angelo"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/flektarn_montur
	name = "flektarn montur"
	desc = "A five-color, -explosive- uniform in camouflage colors, decorated with gold shoulder straps and various combat awards. Initials tell you that it belongs to Koruhaundo Adoriana O."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "flektarn_montur"
	item_state = "flektarn_montur"

/obj/item/clothing/suit/donator/bm/sh_jacket
	name = "Shiro's Samurai Jacket"
	desc = "Iconic jacket of the Shiro Silverhand he wore in his Samurai days."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "SH_jacket"
	item_state = "SH_jacket"
	unique_reskin = list(
		"Default" = list("icon_state" = "SH_jacket"),
		"Black" = list("icon_state" = "SH_jacket_B")
	)

/obj/item/clothing/suit/toggle/noonar // Наследуем от suit/toggle, чтобы можно было переключать состояние
	name = "Syndicate Jacket"
	desc = "A syndicate jacket"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "noonar"
	item_state = "noonar"
	togglename = "buttons"

/obj/item/clothing/suit/toggle/noonarlong
	name = "A longer version of syndicate Jacket"
	desc = "A long syndicate jacket"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "noonarlong"
	item_state = "noonarlong"
	togglename = "buttons"

/obj/item/clothing/suit/donator/bm/sports_jacket
	name = "Sports Jacket"
	desc = "It's yellow."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "sports_jacket"
	item_state = "sports_jacket"

/////

/obj/item/modkit/harness_kit
	name = "Harness Armor Kit"
	desc = "A modkit for making an armor vest into a Harness Armor."
	product = /obj/item/clothing/suit/armor/vest/harness
	fromitem = list(/obj/item/clothing/suit/armor/vest/peacekeeper, /obj/item/clothing/suit/armor/vest/alt)


/obj/item/clothing/suit/armor/vest/harness // Наследуем от armor/vest, модифицируется только из комплекта для брони при клике по жилету
	name = "Harness Armor"
	desc = "A Modified armored vest."
	icon_state = "harness_armor"
	item_state = "harness_armor"
	dog_fashion = null
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/donator/bm/ellys_hoodie
	name = "Ellys Mantle"
	desc = "A hoodie in grey and white colors."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "ellys_hoodie"
	item_state = "hostrench"

/obj/item/clothing/suit/bm/monolith_armor
	name = "Granite M1"
	desc = "The vest of the jumpsuit Granite M1 from the Monolith group, the manufacturer is unknown. "
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "monolith_armor"
	item_state = "monolith_armor"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/rohai_armor
	name = "Rohai Infantry Armor"
	desc = "Standard protective set of infantryman of the Rohai Empire, made of polymers, usually tightly adjusted to its owner. On both shoulder pads you can see a symbol with two knives."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "rohai_armor"
	item_state = "rohai_armor"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/head/helmet/sec/rohai_helmet
	name = "Rohai Infantry helmet"
	desc = "The standard helmet of the Rohai Empire is made of polymer materials and has space for additional modules."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head32x48.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/acrador_helmet_32x48.dmi'
	icon_state = "rohai_helmet"
	item_state = "rohai_helmet"

/obj/item/clothing/suit/armor/rsa12
	name = "R-SA-12"
	desc = "The saboteur's lightweight armor is designed to provide sufficient protection while maintaining a high degree of freedom of movement and stealth, which is important for missions involving subversion, espionage, or stealthy infiltration. Once owned by the Asmalgan Church, but now bears the Rohai emblem on the chest."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "rsa12"
	item_state = "rsa12"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/head/helmet/sec/rhsa12
	name = "R-HSA-12"
	desc = "A helmet from a saboteur light armor. Has a semi-transparent visor to conceal the identity of the saboteur with almost no loss in protective properties. It has a flashlight mount on the side."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/acrador_helmet_32x48.dmi'
	icon_state = "rhsa12"
	item_state = "rhsa12"

/obj/item/clothing/under/rank/security/officer/acradorsuit
	name = "Underarmor suit"
	desc= "A dark, tight suit for wearing underneath hard plates. It does not restrict movement and protects the body from rubbing by armor plates."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/under.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/under.dmi'
	icon_state = "acradorsuit"
	item_state = "acradorsuit"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	can_adjust = FALSE

/obj/item/clothing/suit/bm/nri_mundir
	name = "Old mundir NRI"
	desc = "Desc: Old mundir of the New Russian Empire. Worn out but still ready for battle just like in the old days... The name is embroidered on it - Zlatchek."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "nrimundir"
	item_state = "nrimundir"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/armor/hos/dread_armor
	name = "Броня Судьи"
	desc = "Стандартный  бронежилет судьи из Мега-Города Солнечной Федерации. Броня покрывает плечи и большую часть тела. На наплечниках красуются орлы из скорее всего золота как и на левой части груди с ремнём где красуется значок с потертым именем Дредд. Вам кажется это имя знакомым. Эта броня так и веет чуством что вас защищает Закон."
	icon_state = "dread_armor"
	item_state = "dread_armor"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/armor/renegat
	name = "Peacekeeper Officer's Armor Renegat"
	desc = "The armor of the Adler peacekeepers. There are several patches indicating rank, it looks like it's a uniform for commanders. It is produced by the Adler Military-Industrial complex of the same name. It seems that it can only be worn by high-ranking officials and it is marked with an appropriate alphanumeric code."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "renegat"
	item_state = "renegat"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/head/helmet/sec/renegat
	name = "Peacekeeper Officer's Helmet Renegat"
	desc = "The helmet of the Adler peacekeepers. There are several patches indicating rank, it looks like it's a uniform for commanders. It is produced by the Adler Military-Industrial complex of the same name. It seems that it can only be worn by high-ranking officials, it looks like it has a special friend-foe identification interface built into it."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "renegat"
	item_state = "renegat"

/obj/item/clothing/suit/armor/armor_shield
	name = "Heavy Peacekeeper Armor Shield"
	desc = "The heavy armored suit of the Adler peacekeepers. It is more durable than the regular version, the identification code is indicated under one of the plates on the armor, each plate seems to be designed to reflect the impact, signaling the force on several accompanying plates, reducing the force of impact and damage inflicted. The armor fits well on the body, but it is relatively heavy for an ordinary person, wearing it without implants and training does not seem to be the best option. The Adler encoding on the armor also makes it easier for their owners to identify them using the same access code and poses a danger to opponents and looters."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "shield"
	item_state = "shield"
	blood_overlay_type = "armor"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/head/helmet/sec/helmet_shield
	name = "Heavy Peacekeeper Helmet Shield"
	desc = "The heavy, armored helmet of Adler's Peacekeepers. It seems to be adapted for long and complex operations, inside there is a soft lining under the armor, outside there are durable plates and a friend-foe identification system. Additional plates are located on the front to protect the head."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "shield"
	item_state = "shield"

/obj/item/clothing/head/helmet/sec/adler_skull
	name = "Tactical Skull Helmet"
	desc = "The tactical helmet of desert hunters from the Russian Empire planet Tyrana-1, a lightweight helmet for action in hot conditions, relatively protects against sandstorms, bullets and monster strikes, but slightly narrows the view. It seems that this option is more like an anthropomorphic, but it is also suitable for an ordinary person. Usually the hunters themselves scratch their initials on them, but this one is not marked in any way."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	icon_state = "adler_skull"
	item_state = "adler_skull"

/obj/item/clothing/suit/bm/aki_les
	name = "L.E.S."
	desc = "Lightweight Exo Skeleton. An exoskeleton for performing simple jobs using pneumatic amplifiers and engineering magic. No, it does not connect to your spine, but it is also adapted to this. It is sometimes used for medical purposes after spinal or lower limb injuries. It can completely replace your old piece of meat with a modern equivalent."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "les"
	item_state = "les"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/soviet_coat
    name = "Soviet coat"
    desc = "Красивая красная кожанная шуба, которая пахнет старостью, она довольно тёплая, но кажется её комфортно носить везде."
    icon_state = "soviet_trench"
    item_state = "soviet_trench"

/obj/item/clothing/suit/donator/bm/agentcape
    name = "Marketing agent's cape"
    desc = "The advertising agent's cape is saturated with the smell of instant noodles."
    icon_state = "agentcape"
    item_state = "agentcape"


/obj/item/clothing/suit/donator/bm/agentcape
	name = "Marketing agent's cape"
	desc = "The advertising agent's cape is saturated with the smell of instant noodles."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "agentcape"
	item_state = "agentcape"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/SyndAngelicJaket
	name = "Angelic-made Syndicate parade Jacket"
	desc = "Custom designed Syndicate parade jacket. Specially created to maintain the body features of the jacket for long \
			time comfortable stay in it, and also it is quite small in size, with graceful look and shine. Glory Syndicate!"
	icon_state = "SyndAngelicJaket"
	item_state = "SyndAngelicJaket"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON


/obj/item/clothing/suit/armor/riot/chaplain/wh_armor
	name = "The Armor of the Dark Apostle"
	desc = "Beautifully crafted armor for the apostles. Inscribed with unholy runes and containing writings for hideous rituals. From the armor itself, an aura of blood and the influence of demons emanates"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "wh_armor"
	item_state = "wh_armor"
	mutantrace_variation = NOT_DIGITIGRADE

/obj/item/modkit/wharmor_kit
	name = "The Armor of the Dark Apostle modkit"
	desc = "A modkit for making an chaplain armor into The Armor of the Dark Apostle"
	product = /obj/item/clothing/suit/armor/riot/chaplain/wh_armor
	fromitem = list(/obj/item/clothing/suit/armor/riot/chaplain, /obj/item/clothing/suit/armor/riot/chaplain/teutonic, /obj/item/clothing/suit/armor/riot/chaplain/teutonic/alt, /obj/item/clothing/suit/armor/riot/chaplain/hospitaller)

////////////////////////

/obj/item/clothing/suit/hazardvest/hahun_vest
	name = "field technician suit"
	desc = "A modified Irellian engineering suit with extra layers to protect wearer from electrical shock and cold weather, have a built-in third arm and a welding hood"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "hahun_vest"
	item_state = "hahun_vest"

/obj/item/clothing/suit/hooded/wintercoat/medical/hahun_exosuit
	name = "praxil Mk.6"
	desc = "A lightweight exosuit designed for high agility and rapid response. The Praxil Mk.6 is coated in a matte green bio-reactive material that adjusts its \
			texture for optimal movement and environmental adaptation. The suit is streamlined, with minimal external seams, creating a seamless look that enhances \
			the wearer’s speed and flexibility. Integrated neural interfaces allow for direct mind-to-suit control, making every action instinctual."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x48/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	tail_suit_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/tails_digi.dmi'
	tail_state = "hahun_exosuit"
	icon_state = "hahun_exosuit"
	item_state = "hahun_exosuit"
	flags_inv = HIDESHOES|HIDEJUMPSUIT|HIDETAUR
	hoodtype = /obj/item/clothing/head/hooded/winterhood/hahun_exohood

/obj/item/clothing/head/hooded/winterhood/hahun_exohood
	name = "Praxil exosuit hood"
	desc = "An Praxil exosuit hood, coloured green."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = null
	icon_state = "hahun_exosuit_hood"
	alternate_worn_layer = ABOVE_HEAD_LAYER

////////////////////////

/obj/item/clothing/suit/armor/hos/trenchcoat/white
	name = "white armored trenchcoat"
	desc = "White armored coat. Armored coat in white colors for good boys and girls of NanoTrasen."
	icon_state = "hos_trench_white"
	item_state = "hos_trench_white"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	unique_reskin = list()
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/echoes_jacket
    name = "Technical Jacket"
    desc = "Exoskeleton with Triglav's Syndicate officer jacket."
    icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
    mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
    icon_state = "echoes_jacket"
    item_state = "echoes_jacket"
    body_parts_covered = CHEST
    mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/dark_montur
	name = "Dark Montur"
	desc = "Reserved yet commanding, this uniform of MI13 is tailored from a heavy, matte fabric of deep coal-blue, absorbing ambient light. \
			The form-fitting cut enhances the wearer’s silhouette without restricting movement."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	icon_state = "dark_montur"
	body_parts_covered = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/donator/bm/noxscoutcoat
    name = "Military-Civilian Scout Coat"
    desc = "Specialized military-civilian coat with protection of the first class category, for solving various types of tasks. There is a number sewn in inside - 228321."
    icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
    mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
    icon_state = "noxscoutcoat"
    item_state = "noxscoutcoat"
    body_parts_covered = CHEST
    mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/hooded/bm/cybercoat // Спрайты принадлежат cnaperdodo
	name = "Cybercoat"
	desc = "Странный халат с кибернетикой. Около него чуствуется странный металический привкус."
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "cybercoat"
	item_state = "cybercoat"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	hoodtype = /obj/item/clothing/head/hooded/bm/cybercoat

/obj/item/clothing/head/hooded/bm/cybercoat // Спрайты принадлежат cnaperdodo
	name = "Cybercoat hood"
	icon_state = "hood_cybercoat"
	item_state = "hood_cybercoat"
	body_parts_covered = HEAD
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	rad_flags = RAD_NO_CONTAMINATE

/obj/item/clothing/suit/donator/bm/long_fancy_kimono
	name = "Long Fancy Kimono"
	desc = "A traditional piece of clothing from Japan. Special edition."
	taur_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x64/suit_taur.dmi'
	icon_state = "long_fancy_kimono"
	item_state = "long_fancy_kimono"
	body_parts_covered = CHEST|GROIN|ARMS
	flags_inv = HIDEJUMPSUIT|HIDETAUR
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON|STYLE_PAW_TAURIC
	always_reskinnable = TRUE
	unique_reskin = list(
		"Standard" = list(
			RESKIN_ICON_STATE = "long_fancy_kimono"
		),
		"With butterfly" = list(
			RESKIN_ICON_STATE = "long_fancy_kimono_B"
		),
		"No belt" = list(
			RESKIN_ICON_STATE = "long_fancy_kimono_N"
		)
	)

/obj/item/clothing/suit/donator/bm/ranger_coat
	name = "Ranger Coat"
	desc = "This military-grade armor is a modification of combat armor and was originally designed for special police units. The armor consists of a bulletproof vest, familiar from previous versions of the armor, with multi-layered composite armor plates that are designed to allow for freedom of movement. A special collar made of the same composite material covers the wearer's neck. On the collar of the armor that protects the neck, you can see a number that is the officer's personal identification number."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "ranger_coat"
	item_state = "ranger_coat"

/obj/item/clothing/suit/armor/vest/bluesheid/mu88
	name = "M.U. 88 New hope coat"
	desc = "Длинный плащ полевого медицинского сотрудника службы безопасности. Внутренняя часть имеет прослойку подвижного кевлара, от чего не стесняет движения носителя, немного весит и обладает базовой защитой от пулевых, режущих и колющих видов повреждений. Дополнительно имеется множество карманов и различного рода ремешков для хранения и переноски разнообразного медицинских расходников и обороудования. В одном из внутренних карманов расположился логотип производителя, в виде чёрной розы, а также надпись - Black Rose atelier."
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "mu88"
	item_state = "mu88"

///////////////////////////////////////////////

/obj/item/clothing/suit/donator/bm/dm_pzgrnd_suit
	name = "motorized infantry jacket"
	desc = "A spacious jacket designed for vehicle escort units. It features numerous pockets, as well as a sturdy leather belt! The label inside shows the inscription \"DM Arms\"."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "pz_grenadierjacket"
	item_state = "pz_grenadierjacket"

///////////////////////////////////////////////

/obj/item/clothing/suit/donator/bm/apronchef_red
	name = "Gubby Family Apron"
	desc = "Ярко красный фартук с чёрно белыми узорами, немного потрёпан временем"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	blood_overlay_type = "armor"
	body_parts_covered = CHEST|GROIN
	icon_state = "apronchef_red"
	item_state = "apronchef_red"
	allowed = list(/obj/item/kitchen)

///////////////////////////////////////////////

/obj/item/clothing/suit/toggle/shark
	name = "Shark Pajamas"
	desc = "Soft shark-shaped pajamas, isn't it cute?"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/suit_digi.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE
	flags_inv = HIDEJUMPSUIT
	icon_state = "shark"
	item_state = "bluewizrobe"
	togglename = "buttons"

///////////////////////////////////////////////

/obj/item/clothing/suit/toggle/lsweater
	name = "Sweater"
	desc = "A sweater belonging to some fox"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	body_parts_covered = GROIN|ARMS
	icon_state = "lsweater"
	item_state = "lsweater"
	togglename = "buttons"
	alternate_worn_layer = SUIT_STORE_LAYER

///////////////////////////////////////////////

/obj/item/clothing/suit/donator/bm/cultist_poly
	name = "Aged Robe"
	desc = "Роба пахнующая пылью и до невозможного современна"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	blood_overlay_type = "armor"
	body_parts_covered = CHEST|GROIN|ARMS
	icon_state = "cultist_poly"
	item_state = "cultist_poly"
	var/list/poly_colors = list("#2A2A2A","#A52F29")

/obj/item/clothing/suit/donator/bm/cultist_poly/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, list("#2A2A2A", "#A52F29"), 2)
