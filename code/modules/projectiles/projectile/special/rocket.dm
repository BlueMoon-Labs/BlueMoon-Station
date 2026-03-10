/obj/item/projectile/bullet/gyro
	name ="explosive bolt"
	icon_state= "bolter"
	damage = 50

/obj/item/projectile/bullet/gyro/on_hit(atom/target, blocked = FALSE)
	..()
	explosion(target, -1, 0, 2)
	return BULLET_ACT_HIT

/// PM9 standard HE rocket
/obj/item/projectile/bullet/a84mm
	name = "\improper HE rocket"
	desc = "Boom."
	icon_state= "missile"
	damage = 60
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	ricochets_max = 0
	/// Whether we do extra damage when hitting a mech or silicon
	var/anti_armour_damage = 150
	/// Whether the rocket is capable of instantly killing a living target
	var/random_crits_enabled = TRUE // Worst thing Valve ever added

/obj/item/projectile/bullet/a84mm/on_hit(atom/target, blocked = 0, pierce_hit)
	var/random_crit_gib = FALSE
	if(isliving(target) && prob(5) && random_crits_enabled)
		var/mob/living/gibbed_dude = target
		// if(gibbed_dude.stat < UNCONSCIOUS)
		gibbed_dude.say("ЭТО ЁБАННАЯ РАКЕТ-", forced = "hit by rocket")
		random_crit_gib = TRUE
	..()

	do_boom(target, random_crit_gib)
	if(anti_armour_damage && ismecha(target))
		var/obj/vehicle/sealed/mecha/M = target
		M.take_damage(anti_armour_damage)
	if(issilicon(target))
		var/mob/living/silicon/S = target
		S.take_overall_damage(anti_armour_damage*0.75, anti_armour_damage*0.25)
	return BULLET_ACT_HIT

/** This proc allows us to customize the conditions necesary for the rocket to detonate, allowing for different explosions for living targets, turf targets,
among other potential differences. This granularity is helpful for things like the special rockets mechs use. */
/obj/item/projectile/bullet/a84mm/proc/do_boom(atom/target, random_crit_gib = FALSE)
	if(!isliving(target)) //if the target isn't alive, so is a wall or something
		explosion(target, heavy_impact_range = 1, light_impact_range = 2, flame_range = 3, flash_range = 4)
	else
		explosion(target, light_impact_range = 2, flame_range = 3, flash_range = 4)
		if(random_crit_gib)
			var/mob/living/gibbed_dude = target
			new /obj/effect/temp_visual/crit(get_turf(gibbed_dude))
			gibbed_dude.gib(DROP_ALL_REMAINS)

/// PM9 HEAP rocket - the anti-anything missile you always craved.
/obj/item/projectile/bullet/a84mm/he
	name = "\improper HEAP rocket"
	desc = "I am become death."
	icon_state = "84mm-heap"
	damage = 120
	armour_penetration = 100
	dismemberment = 100
	anti_armour_damage = 50

/obj/item/projectile/bullet/a84mm/he/do_boom(atom/target, blocked=0)
	explosion(target, devastation_range = -1, heavy_impact_range = 1, light_impact_range = 3, flame_range = 4, flash_range = 1, adminlog = FALSE)

/obj/item/projectile/bullet/a84mm/br
	name ="\improper HE missile"
	desc = "Boom."
	icon_state = "missile"
	damage = 60
	dismemberment = 50
	anti_armour_damage = 100

/obj/item/projectile/bullet/a84mm/br/on_hit(atom/target, blocked=0)
	..()
	new /obj/item/broken_missile(get_turf(src))

/obj/item/broken_missile
	name = "\improper broken missile"
	desc = "A missile that did not detonate. The tail has snapped and it is in no way fit to be used again."
	icon = 'icons/obj/item/projectiles.dmi'
	icon_state = "missile_broken"
	w_class = WEIGHT_CLASS_TINY
