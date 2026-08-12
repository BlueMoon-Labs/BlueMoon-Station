// 5.8mm (ACR-5m30) — BR2 FMJ, BR4 AP, BR0+5 HP
/obj/item/projectile/bullet/a58
	name = "5.8mm bullet"
	damage = 22
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 5 → BR2(20)
	wound_bonus = 8                    // BLUEMOON EDIT: было -2 → 8
	bare_wound_bonus = 3

/obj/item/projectile/bullet/a58/ap
	name = "5.8mm armor-piercing bullet"
	damage = 18
	armour_penetration = BULLET_BR4   // BLUEMOON EDIT: было 50 → BR4(50), без изменений
	wound_bonus = 2                    // BLUEMOON EDIT: было -5 → 2
	embedding = null

/obj/item/projectile/bullet/incendiary/a58
	name = "5.8mm incendiary bullet"
	damage = 19
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 0 → BR2
	fire_stacks = 2

/obj/item/projectile/bullet/a58/hp
	name = "5.8mm hollow-point bullet"
	damage = 32
	armour_penetration = 5            // BLUEMOON EDIT: было -40 → 5 (HP плохо пробивает, но не -40)
	wound_bonus = 35                   // BLUEMOON EDIT: было 8 → 35
	embedding = list(embed_chance = 60, fall_chance = 4, jostle_chance = 3, pain_stam_pct = 0.6)

/obj/item/projectile/bullet/a58/he
	name = "5.8mm high-explosive bullet"
	damage = 25
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 10 → BR2
	wound_bonus = 15
	embedding = list(embed_chance = 60, fall_chance = 4, jostle_chance = 3, pain_stam_pct = 0.6)
	knockdown = 5

////////////////////////////////////////////////////////////////////
// 5.56mm — BR2 FMJ, BR4 AP
/obj/item/projectile/bullet/a556
	name = "5.56mm bullet"
	damage = 22                        // BLUEMOON NOTE: в файле есть дублирующий блок с damage=35
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: было 0/10 → BR3(35)
	wound_bonus = 9

/obj/item/projectile/bullet/a556_ap
	name = "5.56mm armor-piercing bullet"
	damage = 18
	armour_penetration = BULLET_BR4   // BLUEMOON EDIT: было 40 → BR4(50)
	wound_bonus = 6

/obj/item/projectile/bullet/a556_hp
	name = "5.56mm hollow-point bullet"
	damage = 26
	armour_penetration = 5            // BLUEMOON EDIT: было -50 → 5
	wound_bonus = 10

/obj/item/projectile/bullet/a556_rubber
	name = "5.56mm rubber bullet"
	damage = 1
	stamina = 35
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null

////////////////////////////////////////////////////////////////////
// 7.62x39mm

// 7.62x39mm (AK) — BR3 FMJ, BR4 AP
/obj/item/projectile/bullet/a762x39
	name = "7.62x39 bullet"
	damage = 28
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: было 0 → BR3(35)
	wound_bonus = 10

/obj/item/projectile/bullet/a762x39_ap
	name = "7.62x39 armor-piercing bullet"
	damage = 24
	armour_penetration = BULLET_BR4   // BLUEMOON EDIT: было 40 → BR4(50)
	wound_bonus = 7

/obj/item/projectile/bullet/a762x39_hp
	name = "7.62x39 hollow-point bullet"
	damage = 25
	armour_penetration = 15           // BLUEMOON EDIT: было -50 → 15
	wound_bonus = 15

/obj/item/projectile/bullet/a762x39_rubber
	name = "7.62x39 rubber bullet"
	damage = 1
	stamina = 40
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null
