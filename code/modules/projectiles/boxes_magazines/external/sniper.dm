/obj/item/ammo_box/magazine/sniper_rounds
	name = "sniper rounds (.50)"
	icon_state = ".50mag"
	ammo_type = /obj/item/ammo_casing/p50
	max_ammo = 6
	caliber = ".50"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammo_box/magazine/sniper_rounds/update_icon()
	. = ..()
	if(ammo_count())
		icon_state = "[initial(icon_state)]-ammo"
	else
		icon_state = "[initial(icon_state)]"

/obj/item/ammo_box/magazine/sniper_rounds/soporific
	name = "sniper rounds (Zzzzz)"
	desc = "Усыпляющие патроны, созданные специально для милой дрёмы и мертвенно-тихих ночей..."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = ".50soporific"
	ammo_type = /obj/item/ammo_casing/p50/soporific
	max_ammo = 3
	caliber = ".50"

/obj/item/ammo_box/magazine/sniper_rounds/penetrator
	name = "sniper rounds (penetrator)"
	desc = "Чрезвычайно мощные оболоченные ураном патроны со способностью прошивать стены насквозь и любую цель за ней."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = ".50penetrator"
	ammo_type = /obj/item/ammo_casing/p50/penetrator
	max_ammo = 5
