// Стандартная дробь 12g — BR4 в упор, BR0 на дистанции (Splurt-оверрайд)
/obj/item/projectile/bullet/pellet/shotgun_buckshot
	name = "buckshot pellet"
	damage = 12.5
	armour_penetration = BULLET_BR4    // BLUEMOON EDIT: BR4 в упор, падает через tile_dropoff_ap
	wound_bonus = 5
	bare_wound_bonus = 5
	wound_falloff_tile = -2.5
	tile_dropoff_ap = 4

// rubbershot / beanbag / slug уже покрыты базовой declaration — тут не дублируем
