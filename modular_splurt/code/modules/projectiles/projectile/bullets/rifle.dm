/obj/item/ammo_casing/a308
	name = ".308 bullet casing"
	desc = "A .308 bullet casing."
	icon_state = "762-casing"
	caliber = ".308"
	projectile_type = /obj/item/projectile/bullet/a308
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400)

/obj/item/projectile/bullet/a308
	name = ".308 bullet"
	damage = 45
	armour_penetration = BULLET_BR8   // .308 = 7,62x51, натовский снайперский калибр
	wound_bonus = 15
	wound_falloff_tile = 0

/obj/item/ammo_casing/a308/sleepy
	name = ".308 bullet casing (Soporific)"
	desc = "A .308 bullet soporific casing."
	projectile_type = /obj/item/projectile/bullet/a308/sleepy
	can_be_printed = FALSE

/obj/item/projectile/bullet/a308/sleepy
	name =".308 Soporific bullet"
	armour_penetration = 0
	damage = 0
	dismemberment = 0
	knockdown = 0

/obj/item/projectile/bullet/a308/sleepy/on_hit(atom/target, blocked = FALSE)
	if((blocked != 100) && isliving(target))
		var/mob/living/L = target
		L.Sleeping(200)
	return ..()

/obj/item/ammo_casing/a308/rubber
	name = ".308 bullet casing (Rubber)"
	desc = "A .308 bullet casing."
	icon_state = "762-casing"
	caliber = ".308"
	projectile_type = /obj/item/projectile/bullet/a308/rubber //bluemoon change
	harmful = FALSE
	advanced_print_req = FALSE
	custom_materials = list(/datum/material/glass = 400)

/obj/item/projectile/bullet/a308/rubber
	name = ".308 Rubber bullet"
	damage = 3
	armour_penetration = BULLET_BR0
	wound_bonus = 5
	stamina = 50
	sharpness = SHARP_NONE
	embedding = null

/obj/item/projectile/bullet/kaiju
	name = "8.83 Kaiju Bullet"
	damage = 100
	armour_penetration = BULLET_BR7   // всё равно - щитспавн
	wound_bonus = 5
	wound_falloff_tile = 0

/obj/item/ammo_casing/kaiju
	name = "8.83 Kaiju bullet casing"
	desc = "A Kaiju bullet casing."
	icon_state = "762-casing"
	caliber = "kaiju"
	projectile_type = /obj/item/projectile/bullet/kaiju

/obj/item/projectile/bullet/a543
	name = "5.43mm bullet"
	damage = 35
	armour_penetration = BULLET_BR7   // Винтовочный калибр розовой пушки из гейта
	wound_bonus = 12
	wound_falloff_tile = 0

/obj/item/ammo_casing/a543
	name = "5.43mm bullet casing"
	desc = "A 5.43mm bullet casing."
	icon_state = "762-casing"
	caliber = ".543"
	projectile_type = /obj/item/projectile/bullet/a543

/obj/item/projectile/bullet/a543/rubber
	name = "5.43mm Rubber bullet"
	damage = 1
	armour_penetration = BULLET_BR0
	wound_bonus = 5
	stamina = 30
	sharpness = SHARP_NONE
	embedding = null

/obj/item/ammo_casing/a543/rubber
	name = "5.43mm bullet casing"
	desc = "A 5.43mm bullet casing."
	icon_state = "762-casing"
	caliber = ".543"
	projectile_type = /obj/item/projectile/bullet/a543/rubber
	harmful = FALSE

/obj/item/ammo_casing/g45l
	name= ".45 Long bullet casing (Rubber)"
	desc = "An .45 Long bullet casing."
	caliber = ".45l"
	projectile_type = /obj/item/projectile/bullet/g45l
	harmful = FALSE

/obj/item/ammo_casing/g45l/lehtal
	name= ".45 Long bullet casing (Lethal)"
	projectile_type = /obj/item/projectile/bullet/g45l/lethal

// .45 Long — BR0 резина, BR1 летальный
/obj/item/projectile/bullet/g45l
	name = ".45 Long Rubber bullet"
	damage = 3
	armour_penetration = BULLET_BR0
	wound_bonus = 5
	stamina = 35
	sharpness = SHARP_NONE
	embedding = null

/obj/item/projectile/bullet/g45l/lethal
	name = ".45 Long Lethal bullet"
	damage = 35
	armour_penetration = BULLET_BR7
	wound_bonus = 15
	stamina = 0
	sharpness = SHARP_EDGED

/datum/ammo/bullet/rifle/lok_smart
	name = "guide rounds"
	damage = 30
	penetration = 25
	shell_speed = 2
	max_range = 30
	damage_falloff = 0.1
	bullet_color = COLOR_PULSE_BLUE
	matter_cost = 0

/atom/movable/projectile/lok
	name = "guide rounds"
	icon_state = "bullet"

	var/mob/living/locked_target
	var/homing_turn_rate = 25

/atom/movable/projectile/lok/process()
	if(locked_target)
		if(QDELETED(locked_target) || locked_target.stat == DEAD)
			locked_target = null
		else
			var/turf/target_turf = get_turf(locked_target)
			if(target_turf && target_turf.z == z)
				var/dx = ABS_COOR(target_turf.x) - apx
				var/dy = ABS_COOR(target_turf.y) - apy
				if(dx || dy)
					var/current_angle = dir_angle
					var/desired_angle = Get_Pixel_Angle(dx, dy)
					var/angle_diff = desired_angle - current_angle
					while(angle_diff > 180)
						angle_diff -= 360
					while(angle_diff < -180)
						angle_diff += 360
					var/turn_amount = clamp(angle_diff, -homing_turn_rate, homing_turn_rate)
					var/new_angle = current_angle + turn_amount
					while(new_angle < 0)
						new_angle += 360
					while(new_angle >= 360)
						new_angle -= 360
					dir_angle = new_angle
					x_offset = round(sin(new_angle), 0.01)
					y_offset = round(cos(new_angle), 0.01)
					setDir(angle2dir(new_angle))
					var/matrix/rotate = matrix()
					rotate.Turn(new_angle)
					transform = rotate
