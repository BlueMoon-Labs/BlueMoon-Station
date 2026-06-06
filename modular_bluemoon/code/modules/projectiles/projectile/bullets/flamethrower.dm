/// Shared energy flamethrower projectile (Zealstar Phoenix, M2A100, etc.)
/obj/item/projectile/bullet/flamethrower
	name = "Fire"
	damage = 7
	var/fire_stacks = 10
	damage_type = BURN
	icon_state = ""
	hitsound_wall = ""
	projectile_piercing = PASSMOB
	range = 15

/obj/item/projectile/bullet/flamethrower/on_hit(atom/target, blocked = FALSE)
	. = call(/obj/item/projectile/proc/on_hit)(src, target, blocked)
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(fire_stacks)
		M.IgniteMob()
	var/turf/open/target_turf = get_turf(target)
	if(istype(target_turf))
		target_turf.IgniteTurf(rand(12, 22))

/obj/item/projectile/bullet/flamethrower/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!fired)
		return
	var/turf/open/location = get_turf(src)
	if(istype(location))
		location.IgniteTurf(rand(8, 15))
