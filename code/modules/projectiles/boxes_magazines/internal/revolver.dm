/obj/item/ammo_box/magazine/internal/cylinder/rev38
	name = "detective revolver cylinder"
	ammo_type = /obj/item/ammo_casing/c38
	caliber = list("38")
	max_ammo = 6

/obj/item/ammo_box/magazine/internal/cylinder/rev762
	name = "\improper Nagant revolver cylinder"
	ammo_type = /obj/item/ammo_casing/n762
	caliber = list("n762")
	max_ammo = 7
	multiload = 0 //заряжание через камору

/obj/item/ammo_box/magazine/internal/cylinder/rus357
	name = "\improper Russian revolver cylinder"
	ammo_type = /obj/item/ammo_casing/a357
	caliber = list("357")
	max_ammo = 6
	multiload = 0

/// 12.7x55mm — The Central Requiem (5-shot); only accepts a357/requiem casings.
/obj/item/ammo_box/magazine/internal/cylinder/requiem127
	name = "Requiem 12.7x55mm cylinder"
	ammo_type = /obj/item/ammo_casing/a357/requiem
	caliber = list("12.7x55mm")
	max_ammo = 5
	multiload = 1

/obj/item/ammo_box/magazine/internal/rus357/Initialize(mapload)
	stored_ammo += new ammo_type(src)
	. = ..()
