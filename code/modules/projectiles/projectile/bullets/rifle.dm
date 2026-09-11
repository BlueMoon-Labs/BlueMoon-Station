/* /obj/item/projectile/bullet/a556
	name = "5.56mm bullet"
	damage = 35
	armour_penetration = BULLET_BR6	//штурмовки должны быть штурмовками - а не прикольным рескином ППшек
	wound_bonus = 7 */ //- это уже есть в другом файле

/obj/item/projectile/bullet/a762
	name = "7.62 bullet"
	damage = 60
	armour_penetration = BULLET_BR10
	wound_bonus = 8
	wound_falloff_tile = 0


/obj/item/projectile/bullet/a762_enchanted
	name = "enchanted 7.62 bullet"
	damage = 5
	armour_penetration = BULLET_BR0
	stamina = 80
