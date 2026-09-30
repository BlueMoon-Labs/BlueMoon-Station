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

/obj/item/ammo_box/magazine/internal/cylinder/cowboy
	name = "Old Revolvers 45 long cylinder"
	ammo_type = /obj/item/ammo_casing/g45l
	caliber = list(".45l")
	max_ammo = 6
	multiload = 1

/obj/item/ammo_box/magazine/internal/cylinder/apostle
	name = "Apostle cylinder"
	ammo_type = /obj/item/ammo_casing/cal41/rubber
	caliber = list(".41cal")
	max_ammo = 6
	multiload = 1

/obj/item/ammo_box/magazine/internal/cylinder/passing_bell
	name = "Passing Bell cylinder"
	ammo_type = /obj/item/ammo_casing/g4570
	caliber = list("45-70")
	max_ammo = 6
	multiload = 1

/obj/item/ammo_box/magazine/internal/cylinder/exorcist 
	name = "Exorcist cylinder"
	ammo_type = /obj/item/ammo_casing/cal410
	caliber = list(".410cal")
	max_ammo = 5
	multiload = 1

/obj/item/ammo_box/magazine/internal/cylinder/liturgy
	name = "Liturgy cylinder"
	ammo_type = /obj/item/ammo_casing/cal41/rubber
	caliber = list(".41cal")
	max_ammo = 18
	multiload = 1

/obj/item/ammo_box/magazine/internal/cylinder/dies_irae
	name = "Dies irae cylinder"
	ammo_type = /obj/item/ammo_casing/a308
	caliber = list("308")
	max_ammo = 6
	multiload = 1

