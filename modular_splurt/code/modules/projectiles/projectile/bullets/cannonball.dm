/obj/item/projectile/bullet/cannonball
	name = "cannonball"
	icon = 'modular_splurt/icons/obj/guns/projectiles.dmi'
	icon_state = "cannonball"
	damage = 110 //gets set to 100 before first mob impact.
	sharpness = NONE
	wound_bonus = 15
	dismemberment = 0
	knockdown = 5 SECONDS
	stutter = 10 SECONDS
	embedding = null
	hitsound = 'sound/effects/meteorimpact.ogg'
	hitsound_wall = 'sound/weapons/sonic_jackhammer.ogg'

/obj/item/projectile/bullet/cannonball/prehit_pierce(atom/A)
	damage -= 10
	if(damage < 40)
		return PROJECTILE_PIERCE_NONE
	return PROJECTILE_PIERCE_HIT

/obj/item/projectile/bullet/cannonball/on_hit(atom/target, blocked = FALSE)
	if(blocked == 100)
		return ..()
	if(isobj(target))
		var/obj/hit_object = target
		hit_object.take_damage(80, BRUTE)
	else if(isclosedturf(target))
		damage -= max(damage - 30, 10) //lose extra momentum from busting through a wall
		if(!isindestructiblewall(target))
			var/turf/closed/hit_turf = target
			hit_turf.ScrapeAway()
	return ..()

/obj/item/projectile/bullet/cannonball/explosive
	name = "explosive shell"
	color = "#FF0000"
	damage = 40 //set to 30 before first mob impact, but they're gonna be gibbed by the explosion

/obj/item/projectile/bullet/cannonball/explosive/prehit_pierce(atom/A)
	. = ..()
	explosion(A, devastation_range = 2, heavy_impact_range = 3, light_impact_range = 4)

/obj/item/projectile/bullet/cannonball/emp
	name = "malfunction shot"
	icon_state = "emp_cannonball"
	damage = 15 //very low

/obj/item/projectile/bullet/cannonball/emp/prehit_pierce(atom/A)
	. = ..()
	empulse(src, 4, 10)

/obj/item/projectile/bullet/cannonball/biggest_one
	name = "\"The Biggest One\""
	icon_state = "biggest_one"
	damage = 70 //low pierce

/obj/item/projectile/bullet/cannonball/biggest_one/prehit_pierce(atom/A)
	. = ..()
	if(damage < 50)
		explosion(A, GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE, GLOB.MAX_EX_FLASH_RANGE)

/obj/item/projectile/bullet/cannonball/trashball
	name = "trashball"
	icon_state = "trashball"
	damage = 90 //better than the biggest one but no explosion, so kinda just a worse normal cannonball
