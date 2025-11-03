/obj/item/modkit/shigu_kit
	name = "Butcher Knife Kit"
	desc = "A modkit for making a Butcher Knife into a Shigu Knife."
	product = /obj/item/kitchen/knife/butcher/shigu_knife
	fromitem = list(/obj/item/kitchen/knife/butcher)

/obj/item/kitchen/knife/butcher/shigu_knife
	name = "Shigu Butcher Knife"
	desc = "A ultra-sharp butcher knife. Maybe his seemingly glaring surface can scare!"
	icon_state = "Shigu_Knife"

//////////////////////////////////////////////////

/obj/item/modkit/kukri_kit
	name = "Kukri Kit"
	desc = "A modkit for making an combat knife into a Kukri."
	product = /obj/item/kitchen/knife/combat/kukri
	fromitem = list(/obj/item/kitchen/knife/combat)

/obj/item/kitchen/knife/combat/kukri
	name = "Кукри-мачете"
	desc = "Традиционное кукри, с разительным отличием, что делает его похожим на мачете, благодаря своему изогнутому клинку и функционалу как режущего инструмента и оружия. Из-за той же формы лещвия с изгибом центр тяжести смещён к острию, что делает его более эффективным для рубки. На рукояти изображён логотип, напоминающий чёрную розу и круговая надпись Black Rose atelier"
	item_state = "kukri"
	icon_state = "kukri"
	icon = 'modular_bluemoon/fluffs/icons/obj/melee.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_righthand.dmi'
	unique_reskin = list(
		"Black" = list(
			RESKIN_ICON_STATE = "kukri",
			RESKIN_ITEM_STATE = "kukri"
		),
		"White" = list(
			RESKIN_ICON_STATE = "kukri_w",
			RESKIN_ITEM_STATE = "kukri_w"
		)
	)

//////////////////////////////////////////////////

/obj/item/modkit/impactbaton_kit
	name = "Impact Baton Kit"
	desc = "A modkit for making a police baton into a jitte baton."
	product = /obj/item/melee/classic_baton/impactbaton_jitte
	fromitem = list(/obj/item/melee/classic_baton)

/obj/item/melee/classic_baton/impactbaton_jitte
	name = "Impact Baton 1/62-H"
	desc = "Impact Baton model 1, year 62th \"Hardlight\". Standard carbon fiber baton of Yernela catcrin law enforcements with hardlight technology sword-cutter."
	icon = 'modular_bluemoon/fluffs/icons/obj/melee.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/belt.dmi'
	icon_state = "impactbaton"
	item_state = "impact_baton"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_righthand.dmi'

/obj/item/modkit/catcrinbaton_kit
	name = "3/51-H Telescopic Baton Kit"
	desc = "A modkit for making a telescopic baton into an impact baton."
	product = /obj/item/melee/classic_baton/telescopic/catcrin
	fromitem = list(/obj/item/melee/classic_baton/telescopic)

/obj/item/melee/classic_baton/telescopic/catcrin
	name = "Impact Baton 3/51-H"
	desc = "Impact Baton model 3, year 51th \"Hardlight\". Easy conсealable telescopic baton of hight-position catcrins with paralitic hardlight elements on the tip and as handguard."
	icon = 'modular_bluemoon/fluffs/icons/obj/melee.dmi'
	icon_state = "hardlightbaton_0"
	item_state = "hardlightbaton_0"
	on_icon_state = "hardlightbaton_1"
	off_icon_state = "hardlightbaton_0"
	on_item_state = "hardlightbaton_1"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_righthand.dmi'

////////////////////////////////////////////////////////////////////////////////////////

/obj/item/modkit/portalabomination_kit
	name = "Telescopic Abomination Tool Kit"
	desc = "A modkit for making an telescopic baton into a god forbidden weapon. Hold it tight."
	product = /obj/item/melee/classic_baton/telescopic/portal_abomination
	fromitem = list(/obj/item/melee/classic_baton/telescopic)

/obj/item/melee/classic_baton/telescopic/portal_abomination
	name = "Otherworld Portal Weapon"
	desc = "A portal tool, revealing some part of otherworld undescribable abomination. Use it carefully or it will use you. Who openned the gates to this thing?!"
	icon_state = "portalabomination"
	icon = 'modular_bluemoon/fluffs/icons/obj/UngodlyAbomination.dmi'
	item_state = "portalabomination"
	on_icon_state = "portalabomination_active"
	off_icon_state = "portalabomination"
	on_item_state = "portalabomination_active"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/guns_right.dmi'
	hitsound = 'modular_bluemoon/fluffs/sound/weapon/Abomination.ogg'

// /obj/item/modkit/esword_kit
// 	name = "Energy sword Kit"
// 	desc = "A modkit for making a plasma sword into an energy sword."
// 	product = /obj/item/melee/transforming/energy/sword/saber
// 	fromitem = list(/obj/item/melee/transforming/plasmasword)

// /obj/item/modkit/desword_kit
// 	name = "Double-bladed energy sword Kit"
// 	desc = "A modkit for making a plasma scythe into an double-bladed energy sword."
// 	product = /obj/item/dualsaber
// 	fromitem = list(/obj/item/plasmascythe)
