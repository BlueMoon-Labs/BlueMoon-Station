/obj/item/projectile/bullet/pellet/shotgun_flechette
	name = "flechette pellet"
	damage = 10
	wound_bonus = 5
	bare_wound_bonus = 5
	armour_penetration = BULLET_BR8
	wound_falloff_tile = 2.5
	tile_dropoff = 0.4

/obj/item/projectile/bullet/frangible_slug
	name = "frangible slug"
	damage = 20
	sharpness = SHARP_POINTY
	wound_bonus = 10
	bare_wound_bonus = 10
	armour_penetration = BULLET_BR2 //основной смысл - снос дверей

/obj/item/projectile/bullet/frangible_slug/on_hit(atom/target, blocked, pierce_hit)
	if(is_type_in_list(target, list(/obj/structure/window, /obj/machinery/door, /obj/structure/grille, /obj/structure/door_assembly)))
		damage = 200 // airlock integrity is about 300, but on airlock destruction its assembly is spawned //слишком сильно для масс юза
		armour_penetration = 100
	. = ..()
