/obj/item/projectile/bullet/reusable/arrow
	name = "wooden arrow"
	desc = "Woosh!"
	damage = 15
	armour_penetration = BULLET_BR0   // BLUEMOON ADD: дерево = BR0
	icon_state = "arrow"
	ammo_type = /obj/item/ammo_casing/caseless/arrow/wood

/obj/item/projectile/bullet/reusable/arrow/ash
	name = "ashen arrow"
	desc = "Fire harderned arrow."
	damage = 25
	armour_penetration = BULLET_BR0   // BLUEMOON ADD
	ammo_type = /obj/item/ammo_casing/caseless/arrow/ash

/obj/item/projectile/bullet/reusable/arrow/bone //AP for ashwalkers
	name = "bone arrow"
	desc = "Arrow made of bone and sinew."
	damage = 35
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: было 40 → BR3(35), без изменений
	ammo_type = /obj/item/ammo_casing/caseless/arrow/bone

/obj/item/projectile/bullet/reusable/arrow/bronze //Just some AP shots
	name = "bronze arrow"
	desc = "Bronze tipped arrow."
	armour_penetration = BULLET_BR1   // BLUEMOON EDIT: было 10 → BR1(10)
	ammo_type = /obj/item/ammo_casing/caseless/arrow/bronze
