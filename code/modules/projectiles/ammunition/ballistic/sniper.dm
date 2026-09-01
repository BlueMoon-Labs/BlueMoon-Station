// .50 (Sniper)

/obj/item/ammo_casing/p50
	name = ".50 bullet casing"
	desc = "Гильза патрона калибром .50, он же 12.7 мм."
	caliber = ".50"
	projectile_type = /obj/item/projectile/bullet/p50
	icon_state = ".50"

/obj/item/ammo_casing/p50/soporific
	name = ".50 soporific bullet casing"
	desc = "Гильза патрона калибром .50, специализированная для отправки цели к Морфею, а не Господу."
	projectile_type = /obj/item/projectile/bullet/p50/soporific
	icon = 'modular_bluemoon/icons/obj/ammo.dmi' // BLUEMOON CHANGE custom states
	icon_state = ".50_sleeper" // BLUEMOON ADD custom state
	harmful = FALSE

/obj/item/ammo_casing/p50/penetrator
	name = ".50 penetrator round bullet casing"
	desc = "Гильза патрона калибром .50 \"пенетратор\", предназначенная для пробивания брони."
	projectile_type = /obj/item/projectile/bullet/p50/penetrator
