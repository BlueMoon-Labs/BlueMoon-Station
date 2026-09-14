// C3D (Борги) — BR4 (технический)
/obj/item/projectile/bullet/c3d
	damage = 30
	armour_penetration = BULLET_BR8

// Mech LMG — BR4
/obj/item/projectile/bullet/lmg
	damage = 30
	armour_penetration = BULLET_BR9

// Mech FNX-99 — BR4
/obj/item/projectile/bullet/incendiary/fnx99
	damage = 30
	armour_penetration = BULLET_BR13

// Турели
/obj/item/projectile/bullet/manned_turret
	damage = 20
	armour_penetration = BULLET_BR5

/obj/item/projectile/bullet/syndicate_turret
	damage = 30
	armour_penetration = BULLET_BR7

/obj/item/projectile/bullet/mm712x82
	name = "7.12x82mm bullet"
	damage = 40
	armour_penetration = BULLET_BR7
	wound_bonus = -50
	wound_falloff_tile = 0

/obj/item/projectile/bullet/mm712x82_ap
	name = "7.12x82mm armor-piercing bullet"
	damage = 35
	armour_penetration = BULLET_BR10

/obj/item/projectile/bullet/mm712x82_hp
	name = "7.12x82mm hollow-point bullet"
	damage = 50
	armour_penetration = 15           // BLUEMOON EDIT: было -60 → 15
	sharpness = SHARP_EDGED
	wound_bonus = -65                  // BLUEMOON EDIT: было -40 → -65 (под exponent=1.6)
	bare_wound_bonus = 30
	wound_falloff_tile = -8

/obj/item/projectile/bullet/incendiary/mm712x82
	name = "7.12x82mm incendiary bullet"
	damage = 30
	armour_penetration = BULLET_BR7
	fire_stacks = 3

/obj/item/projectile/bullet/mm712x82/match
	name = "7.12x82mm match bullet"
	damage = 40
	armour_penetration = BULLET_BR7
	ricochets_max = 2
	ricochet_chance = 100
	ricochet_auto_aim_range = 4
	ricochet_incidence_leeway = 35
	wound_bonus = -50
