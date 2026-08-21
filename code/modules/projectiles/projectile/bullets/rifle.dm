// 5.56mm (M-90gl Carbine)

/obj/item/projectile/bullet/a556
	name = "5.56mm bullet"
	damage = 35
	armour_penetration = BULLET_BR2
	wound_bonus = 7

// 7.62 Nagant Rifle — BR3 (винтовочный)
/obj/item/projectile/bullet/a762
	name = "7.62 bullet"
	damage = 60
	armour_penetration = BULLET_BR3   // BLUEMOON ADD
	wound_bonus = 8
	wound_falloff_tile = 0


/obj/item/projectile/bullet/a762_enchanted
	name = "enchanted 7.62 bullet"
	damage = 5
	armour_penetration = BULLET_BR0   // магический — не про пробитие
	stamina = 80
