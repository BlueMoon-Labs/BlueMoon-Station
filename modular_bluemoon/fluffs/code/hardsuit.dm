// stasdvrz T-51 sec hardsuit reskin
/obj/item/clothing/head/helmet/space/hardsuit/security/t51power
	name = "T-51 Power Armor Helmet"
	desc = "Шлем силовой брони еще со старых времён, разработанный с довольно герметичной для нулевого давления, имеет встроенный фонарь \
	и внутренний дисплей показателей состояние брони. Технология довольно устарела и модификации какие либо уже невозможны."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "hardsuit0-sec_t51"
	item_state = "hardsuit0-sec_t51"
	hardsuit_type = "sec_t51"

/obj/item/clothing/head/helmet/space/hardsuit/security/t51power/reskin_obj(mob/user)
	if(current_skin == "T-60")
		hardsuit_type = "sec_t60"

/obj/item/clothing/suit/space/hardsuit/security/t51power
	name = "T-51 Power Armor"
	desc = "Силовая броня старого образца, довольно редко уже можно такой увидеть в рабочем состоянии однако те, что еще на ходу, \
	не уступают с современными моделями. Броня герметична и защищает от низкого давления и сохраняет температуру в оптимальном при \
	штатной работе в космосе, а ядерный блок что ранее питал экзоскелет брони, заменен на блюспейсовую батарею реакторного типа или же БСР. \
	Технология довольно устарела и модификации какие либо уже невозможны. "
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/suit_digi.dmi'
	taur_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/large-worn-icons/32x64/suit_taur.dmi'
	icon_state = "hardsuit-sec_t51"
	item_state = "hardsuit-sec_t51"
	tail_state = "syndicate-winter"
	hardsuit_type = "sec_t51"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/security/t51power
	unique_reskin = list(
		"T-60" = list(
			"name" = "T-60 Power Armor",
			RESKIN_ICON_STATE = "hardsuit-sec_t60",
			RESKIN_ITEM_STATE = "hardsuit-sec_t60",
		),
		"T-51" = list(
			RESKIN_ICON_STATE = "hardsuit-sec_t51",
			RESKIN_ITEM_STATE = "hardsuit-sec_t51",
		)
	)

/obj/item/clothing/suit/space/hardsuit/security/t51power/reskin_obj(mob/user)
	if(current_skin == "T-60")
		mutantrace_variation = STYLE_DIGITIGRADE|STYLE_SNEK_TAURIC
		tail_state = "hos"
		if(helmet)
			var/obj/item/clothing/head/helmet/space/hardsuit/Helm = helmet
			Helm.hardsuit_type = "sec_t60"
			Helm.name = "T-60 Power Armor Helmet"
			Helm.update_icon_state()

/obj/item/modkit/t51armor_kit
	name = "Old Power Armor Kit"
	desc = "A modkit for making a security hardsuit into a T-51 Power Armor."
	icon = 'icons/obj/device.dmi'
	icon_state = "modkit"
	product = /obj/item/clothing/suit/space/hardsuit/security/t51power
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/security)

////////////////////////////////////////////////////////////////

/obj/item/clothing/head/helmet/space/hardsuit/engine/fluff_praxil_seven
	name = "Praxil-7 Mark II helm"
	desc = "A robust, cutting-edge space suit designed for arirals, that are working in hazardous environments. \
			It features reinforced armor plating, modular tools for maintenance and construction, and a power-assisted \
			frame that enhances the wearer's strength and endurance. Ideal for high-risk operations in space or industrial zones, \
			the suit offers protection against extreme temperatures, radiation, and debris."
	icon_state = "hardsuit0-praxil_seven"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	hardsuit_type = "praxil_seven"
	mutantrace_variation = NONE

/obj/item/clothing/suit/space/hardsuit/engine/fluff_praxil_seven
	name = "Praxil-7 Mark II  suit"
	desc = "The ariral helmet is a sleek, high-tech design with an integrated visor that offers 360-degree vision and advanced HUD display. \
			Equipped with a filtration system for breathable air in toxic atmospheres, it also has reinforced shielding against impacts and radiation. \
			The helmet is compatible with a communication system for secure, real-time team coordination."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	tail_suit_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/tails_digi.dmi'
	icon_state = "praxil_seven_engi"
	tail_state = "praxil_seven_engi"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/engine/fluff_praxil_seven
	mutantrace_variation = NONE

/obj/item/modkit/fluff_praxil_seven_kit
	name = "Praxil-7 Mark II engi hardsuit Kit"
	desc = "A modkit for making a engineering hardsuit into a Praxil-7 Mark II."
	product = /obj/item/clothing/suit/space/hardsuit/engine/fluff_praxil_seven
	fromitem = list(/obj/item/clothing/suit/space/hardsuit/engine)

/obj/item/clothing/head/helmet/space/eva/paramedic/fluff_m_9922
	name = "M-9922 helmet"
	desc = "A medical-grade helmet designed to suit the unique physiology of the Ariral, this piece combines sleek aesthetics with advanced functionality. \
			Its smooth dome is finished in a radiant white with subtle accents of cool blue—a color associated with purity and care in Ariral culture.<br>\
			A semi-transparent visor, softly lit from within by a pale blue glow, adapts to varying light conditions and displays biometric readouts directly \
			onto its surface. Internally, integrated interfaces monitor vital signs and project critical data into the medic’s field of vision.<br>\
			Elegant blue lines trace the helmet’s sides—these are cooling channels and dispersal pathways for medical aerosols. \
			A sealed module at the rear houses communication systems, transmitting real-time data to the central medical hub aboard a ship or station."
	icon_state = "m_9922_medical"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/head.dmi'
	mutantrace_variation = NONE

/obj/item/modkit/fluff_m_9922_helmet_kit
	name = "M-9922 paramedic helmet Kit"
	desc = "A modkit for making a paramedic helmet into a M-9922."
	product = /obj/item/clothing/head/helmet/space/eva/paramedic/fluff_m_9922
	fromitem = list(/obj/item/clothing/head/helmet/space/eva/paramedic)

/obj/item/clothing/suit/space/eva/paramedic/fluff_m_9922
	name = "M-9922 space suit"
	desc = "Crafted for the medics of the Ariral, this suit is a seamless fusion of protection, mobility, and advanced support systems. \
			Its sleek silhouette follows the elegant contours of the wearer, accentuating the grace and biomechanics of the Ariral physique. \
			The primary hue is a sterile white, accented with iridescent blue panels tracing the joints, ribs, and spine."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	tail_suit_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/tails_digi.dmi'
	icon_state = "m_9922_medical"
	item_state = "m_9922_medical"
	tail_state = "m_9922_medical"
	mutantrace_variation = NONE

/obj/item/modkit/fluff_m_9922_suit_kit
	name = "M-9922 paramedic space suit Kit"
	desc = "A modkit for making a paramedic space suit into a M-9922."
	product = /obj/item/clothing/suit/space/eva/paramedic/fluff_m_9922
	fromitem = list(/obj/item/clothing/suit/space/eva/paramedic)

/obj/item/storage/box/fluff_m_9922_kit/PopulateContents()
	new /obj/item/modkit/fluff_m_9922_helmet_kit(src)
	new /obj/item/modkit/fluff_m_9922_suit_kit(src)
