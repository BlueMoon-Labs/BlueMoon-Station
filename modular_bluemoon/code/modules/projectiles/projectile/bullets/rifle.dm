// 5.8mm (ACR-5m30 Rifle)

/obj/item/projectile/bullet/a58
	name = "5.8mm bullet"
	damage = 22
	armour_penetration = 5
	wound_bonus = -2
	bare_wound_bonus = 3

/obj/item/projectile/bullet/a58/ap
	name = "5.8mm armor-piercing bullet"
	damage = 18
	armour_penetration = 50
	wound_bonus = -5 // Идут навылет
	embedding = null

/obj/item/projectile/bullet/incendiary/a58
	name = "5.8mm incendiary bullet"
	damage = 19
	armour_penetration = 0
	fire_stacks = 2

/obj/item/projectile/bullet/a58/hp
	name = "5.8mm hollow-point bullet"
	damage = 32
	armour_penetration = -40
	wound_bonus = 8
	embedding = list(embed_chance = 60, fall_chance = 4, jostle_chance = 3, pain_stam_pct = 0.6)

/obj/item/projectile/bullet/a58/he
	name = "5.8mm high-explosive bullet"
	damage = 25
	armour_penetration = 10
	wound_bonus = 15
	embedding = list(embed_chance = 60, fall_chance = 4, jostle_chance = 3, pain_stam_pct = 0.6)
	knockdown = 5

////////////////////////////////////////////////////////////////////
// 5.56mm

/obj/item/projectile/bullet/a556
	name = "5.56mm bullet"
	damage = 22
	wound_bonus = 9

/obj/item/projectile/bullet/a556_rubber
	name = "5.56mm rubber bullet"
	damage = 1
	stamina = 35
	sharpness = NONE
	embedding = null

/obj/item/projectile/bullet/a556_hp
	name = "5.56mm hollow-point bullet"
	damage = 26
	wound_bonus = 10
	armour_penetration = -50

/obj/item/projectile/bullet/a556_ap
	name = "5.56mm armor-piercing bullet"
	damage = 18
	wound_bonus = 6
	armour_penetration = 40

////////////////////////////////////////////////////////////////////
// 7.62x39mm

/obj/item/projectile/bullet/a762x39
	name = "7.62x39 bullet"
	damage = 28
	wound_bonus = 10

/obj/item/projectile/bullet/a762x39_rubber
	name = "7.62x39 rubber bullet"
	damage = 1
	stamina = 40
	sharpness = NONE
	embedding = null

/obj/item/projectile/bullet/a762x39_hp
	name = "7.62x39 hollow-point bullet"
	damage = 25
	wound_bonus = 15
	armour_penetration = -50

/obj/item/projectile/bullet/a762x39_ap
	name = "7.62x39 armor-piercing bullet"
	damage = 24
	wound_bonus = 7
	armour_penetration = 40
