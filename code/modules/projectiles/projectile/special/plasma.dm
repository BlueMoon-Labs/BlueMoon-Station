/obj/item/projectile/plasma
	name = "plasma blast"
	icon_state = "plasmacutter"
	damage_type = BRUTE
	damage = 13
	range = 4
	dismemberment = 20
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	var/pressure_decrease_active = FALSE
	var/pressure_decrease = 0.25
	var/pressure_decrease_delimb = 0.5
	var/mine_range = 3 //mines this many additional tiles of rock
	var/simplemob_damage_bonus = 1
	tracer_type = /obj/effect/projectile/tracer/plasma_cutter
	muzzle_type = /obj/effect/projectile/muzzle/plasma_cutter
	impact_type = /obj/effect/projectile/impact/plasma_cutter

/obj/item/projectile/plasma/prehit_pierce(atom/target)
	. = ..()
	var/hit_turt = get_turf(src)
	if(!pressure_decrease_active && !lavaland_equipment_pressure_check(hit_turt))
		name = "weakened [name]"
		var/pressure_mult = get_pressure_damage_multiplier(hit_turt, LAVALAND_EQUIPMENT_EFFECT_PRESSURE, pressure_decrease)
		damage = round(damage * pressure_mult, 0.5) // Округляем к ближайшему целому 0.5
		dismemberment *= pressure_decrease_delimb
		pressure_decrease_active = TRUE

/obj/item/projectile/plasma/on_hit(atom/target)
	. = ..()
	if(ismineralturf(target))
		var/turf/closed/mineral/M = target
		M.gets_drilled(firer)
		if(mine_range)
			mine_range--
			range++
		if(range > 0)
			return BULLET_ACT_FORCE_PIERCE
	if(isanimal(target))
		var/mob/living/simple_animal/S = target
		S.apply_damage(round(damage * simplemob_damage_bonus), BRUTE)

/obj/item/projectile/plasma/adv
	damage = 19
	range = 5
	mine_range = 5
	dismemberment = 40
	simplemob_damage_bonus = 0.75

/obj/item/projectile/plasma/adv/mech
	damage = 25
	range = 9
	mine_range = 3
	dismemberment = 60
	simplemob_damage_bonus = 1.25

/obj/item/projectile/plasma/turret
	//Between normal and advanced for damage, made a beam so not the turret does not destroy glass
	name = "plasma beam"
	damage = 24
	range = 7
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE

/obj/item/projectile/plasma/weak
	dismemberment = 0
	damage = 10
	range = 4
	mine_range = 0
	simplemob_damage_bonus = 1.5
