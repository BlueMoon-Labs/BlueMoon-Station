/obj/structure/blob/shield
	name = "strong blob"
	icon = 'icons/mob/blob.dmi'
	icon_state = "blob_shield"
	desc = "A solid wall of slightly twitching tendrils."
	var/damaged_desc = "A wall of twitching tendrils."
	max_integrity = 150
	brute_resist = 0.25
	explosion_block = 3
	point_return = 4
	atmosblock = TRUE
	flags_1 = DEFAULT_RICOCHET_1
	flags_ricochet = RICOCHET_HARD
	armor = list(MELEE = 25, BULLET = 50, LASER = 25, ENERGY = 10, BOMB = 20, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)
	var/weakened

/obj/structure/blob/shield/scannerreport()
	if(atmosblock)
		return "Will prevent the spread of atmospheric changes."
	return "N/A"

/obj/structure/blob/shield/core
	point_return = 0

/obj/structure/blob/shield/update_icon()
	..()
	if(obj_integrity < max_integrity * 0.5)
		icon_state = "[initial(icon_state)]_damaged"
		name = "weakened [initial(name)]"
		desc = "[damaged_desc]"
		atmosblock = FALSE
		if(!weakened)
			armor = armor.setRating(MELEE = 15, BULLET = 15, LASER = 5, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)
			weakened = TRUE
	else
		icon_state = initial(icon_state)
		name = initial(name)
		desc = initial(desc)
		atmosblock = TRUE
		if(weakened)
			armor = armor.setRating(MELEE = 25, BULLET = 25, LASER = 15, ENERGY = 10, BOMB = 20, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)
			weakened = FALSE
	air_update_turf(TRUE)

/obj/structure/blob/shield/check_projectile_ricochet(obj/item/projectile/P)
	return PROJECTILE_RICOCHET_FORCE

/obj/structure/blob/shield/handle_ricochet(obj/item/projectile/P)
	if(P.flag in list(BULLET, BOMB))
		// Bullets use ricochet_incidence_leeway in /atom/proc/handle_ricochet, which blocks most impacts.
		// Strong blob should always reflect bullets like reflective does for lasers.
		var/turf/p_turf = get_turf(P)
		var/face_direction = get_dir(src, p_turf)
		var/face_angle = dir2angle(face_direction)
		var/incidence_s = GET_ANGLE_OF_INCIDENCE(face_angle, (P.Angle + 180))
		var/a_incidence_s = abs(incidence_s)
		if(a_incidence_s > 90 && a_incidence_s < 270)
			return FALSE
		var/new_angle_s = SIMPLIFY_DEGREES(face_angle + incidence_s)
		P.setAngle(new_angle_s)
		P.hit_prone_targets = TRUE
		return TRUE
	. = ..()
	if(.)
		P.hit_prone_targets = TRUE

/obj/structure/blob/shield/reflective
	name = "reflective blob"
	desc = "A solid wall of slightly twitching tendrils with a reflective glow."
	damaged_desc = "A wall of twitching tendrils with a reflective glow."
	icon_state = "blob_glow"
	flags_1 = DEFAULT_RICOCHET_1
	flags_ricochet = RICOCHET_SHINY
	point_return = 8
	max_integrity = 100
	brute_resist = 1
	explosion_block = 2
	armor = list(MELEE = 25, BULLET = 25, LASER = 50, ENERGY = 10, BOMB = 20, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)

/obj/structure/blob/shield/reflective/check_projectile_ricochet(obj/item/projectile/P)
	return PROJECTILE_RICOCHET_FORCE
