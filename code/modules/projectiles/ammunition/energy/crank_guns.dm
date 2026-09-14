// Патроны для самодельных энергетических пушек: лазерного мушкета и термальных пистолетов.
/obj/item/ammo_casing/energy/laser/musket
	projectile_type = /obj/item/projectile/beam/laser/musket
	e_cost = STANDARD_CELL_CHARGE

/obj/item/ammo_casing/energy/laser/musket/prime
	projectile_type = /obj/item/projectile/beam/laser/musket/prime
	pellets = 3
	variance = 10

/obj/item/ammo_casing/energy/nanite
	projectile_type = /obj/item/projectile/bullet/c10mm //хах
	select_name = "nanite"
	e_cost = 1250 // LASER_SHOTS(8, STANDARD_CELL_CHARGE)
	fire_sound = 'sound/items/weapons/thermalpistol.ogg'

/obj/item/ammo_casing/energy/nanite/inferno
	projectile_type = /obj/item/projectile/energy/inferno
	name = "inferno nanite lens"
	select_name = "inferno"

/obj/item/ammo_casing/energy/nanite/inferno/emagged
	projectile_type = /obj/item/projectile/energy/inferno/emagged

/obj/item/ammo_casing/energy/nanite/cryo
	projectile_type = /obj/item/projectile/energy/cryo
	name = "cryo nanite lens"
	select_name = "cryo"
	firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect/energy

/obj/item/ammo_casing/energy/nanite/cryo/emagged
	projectile_type = /obj/item/projectile/energy/cryo/emagged
