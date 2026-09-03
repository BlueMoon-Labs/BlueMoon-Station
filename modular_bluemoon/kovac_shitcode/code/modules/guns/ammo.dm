// 9x39mm (ВСС, командирская) — BR3 (дозвуковой, но тяжёлая пуля)
/obj/item/projectile/bullet/a9x39
	name = "9x39 bullet"
	damage = 45
	armour_penetration = BULLET_BR3   // BLUEMOON ADD: BR3 — тяжёлая но дозвуковая
	wound_bonus = 15

/obj/item/ammo_casing/a9x39
	name = "9x39 bullet casing"
	desc = "A 9x39 bullet casing."
	icon_state = "s-casing"
	caliber = "9x39"
	projectile_type = /obj/item/projectile/bullet/a9x39

/obj/item/ammo_box/a9x39
	name = "ammo box (9x39)"
	icon_state = "10mmbox"
	ammo_type = /obj/item/ammo_casing/a9x39
	max_ammo = 20
