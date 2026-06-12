// Оружие Отряда Кроликов
/obj/item/gun/energy/e_gun/rabbit
	name = "R-Corporation R-3000 'Mark 2'"
	desc = "An energy gun produced specifically to suppress threats within Lobotomy Corporation, it has four firing modes to switch between."
	icon = 'modular_bluemoon/icons/obj/guns/energy.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "rabbit"
	cell_type = /obj/item/stock_parts/cell/high
	can_charge = TRUE
	weapon_weight = WEAPON_HEAVY // No dual wielding
	pin = /obj/item/firing_pin/implant/mindshield

/obj/item/gun/energy/e_gun/rabbit/Initialize()
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.16 SECONDS)

/obj/item/gun/energy/e_gun/rabbit/captain
	name = "R-Corporation R-4000 'Mark 3'"
	desc = "An energy gun produced especially for the rabbit captain. This weapon can be fired with one hand."
	color = COLOR_SILVER
	weapon_weight = WEAPON_LIGHT
	pin = /obj/item/firing_pin
	cell_type = /obj/item/stock_parts/cell/high/plus

// Гравпульсер
// Два режима:
// heavy - Дамажит
// weak - Станит
// На лавебе heavy ломал нахуй кости а weak дамажил просто
// Тут я решил переделать чутка ибо дохуя имба когда тебя с нескольких выстрелов ломают пополам
/obj/item/gun/energy/taser/legax
	name = "Legax Gravpulser"
	desc = "An experimental handcannon with a catch."
	icon = 'modular_bluemoon/icons/obj/guns/energy.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	icon_state = "gravpulser"
	ammo_type = list(/obj/item/ammo_casing/energy/electrode/legax, /obj/item/ammo_casing/energy/bolt/legax)

/obj/item/gun/energy/xray
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_HEAVY
	slot_flags = ITEM_SLOT_BACK
