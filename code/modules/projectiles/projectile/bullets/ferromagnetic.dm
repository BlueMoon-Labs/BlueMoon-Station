// Magnetic (ВТ-550 стандарт) — BR2
/obj/item/projectile/bullet/magnetic
	icon_state = "magjectile"
	damage = 25
	armour_penetration = BULLET_BR3   // BLUEMOON EDIT: поднимаем значимость
	fired_light_range = 3
	pixels_per_second = TILES_TO_PIXELS(16.667)
	range = 35
	fired_light_color = LIGHT_COLOR_RED

/obj/item/projectile/bullet/magnetic/disabler
	icon_state = "magjectile-nl"
	damage = 2
	armour_penetration = BULLET_BR0   // BLUEMOON EDIT: было 10 → BR0 (нелетальный)
	stamina = 20
	fired_light_color = LIGHT_COLOR_BLUE

/obj/item/projectile/bullet/magnetic/weak
	damage = 18
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: поднимаем значимость
	fired_light_range = 2
	range = 25

/obj/item/projectile/bullet/magnetic/weak/disabler
	damage = 2
	armour_penetration = BULLET_BR0   // нелетальный
	stamina = 25

/obj/item/projectile/bullet/magnetic/hyper
	damage = 10
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 20 → BR2
	stamina = 10
	range = 6

/obj/item/projectile/bullet/incendiary/mag_inferno
	icon_state = "magjectile-large"
	damage = 10
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 20 → BR2
	projectile_piercing = TRUE
	range = 20

/obj/item/projectile/bullet/magnetic/hyper/prehit_pierce(atom/target)
	return PROJECTILE_PIERCE_HIT

/obj/item/projectile/bullet/incendiary/mag_inferno
	icon_state = "magjectile-large"
	damage = 10
	armour_penetration = 20
	range = 20
	pixels_per_second = TILES_TO_PIXELS(12.5)
	fired_light_range = 4
	fired_light_color = LIGHT_COLOR_RED

/obj/item/projectile/bullet/incendiary/mag_inferno/prehit_pierce(atom/target)
	return PROJECTILE_PIERCE_HIT

/obj/item/projectile/bullet/incendiary/mag_inferno/on_hit(atom/target, blocked = FALSE)
	..()
	explosion(target, -1, 0, 0, 1, 2, flame_range = 2)
	return BULLET_ACT_HIT
