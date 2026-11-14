/obj/item/projectile/beam
	name = "laser"
	icon_state = "laser"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	damage = 20
	light_range = 2
	light_power = 0.9
	damage_type = BURN
	hitsound = 'sound/weapons/sear.ogg'
	hitsound_wall = 'sound/weapons/effects/searwall.ogg'
	flag = LASER
	eyeblur = 2
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	light_color = "#FF3B3B" // красноватый для лазеров
	ricochets_max = 50	//Honk!
	ricochet_chance = 80
	is_reflectable = TRUE
	wound_bonus = 6
	bare_wound_bonus = 8
	armour_penetration = 15
	glow_icon = 'icons/obj/projectiles.dmi'
	glow_icon_state = "laser"
	var/fire_hazard = FALSE

/obj/item/projectile/beam/laser
	tracer_type = /obj/effect/projectile/tracer/laser
	muzzle_type = /obj/effect/projectile/muzzle/laser
	impact_type = /obj/effect/projectile/impact/laser
	wound_bonus = 8
	bare_wound_bonus = 12

/obj/item/projectile/beam/laser/lasgun
	damage = 12.5
	armour_penetration = 10

/obj/item/projectile/beam/laser/musket
	name = "musket laser"
	icon_state = "laser_musket"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	damage = 25
	stamina = 25
	light_color = COLOR_STRONG_VIOLET

/obj/item/projectile/beam/laser/musket/prime
	name = "heroic musket laser"
	damage = 60
	stamina = 60
	eyeblur = 10
	ricochet_chance = 100

/obj/item/projectile/beam/laser/mutation
	name = "ocular laser"
	desc = "Focused burn from mutated eye tissue — mirrors real laser projectile rules so reflective plating can send it back."
	icon = 'icons/effects/genetics.dmi'
	icon_state = "eyelasers"

//overclocked laser, does a bit more damage but has much higher wound power (-0 vs -20)
/obj/item/projectile/beam/laser/hellfire
	name = "hellfire laser"
	wound_bonus = 15
	damage = 25
	fire_hazard = TRUE

/obj/item/projectile/beam/laser/hellfire/Initialize(mapload)
	. = ..()
	transform *= 2

/obj/item/projectile/beam/laser/hellfire/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.IgniteMob()

/obj/item/projectile/beam/laser/heavylaser
	name = "heavy laser"
	icon_state = "heavylaser"
	damage = 40
	fire_hazard = TRUE
	tracer_type = /obj/effect/projectile/tracer/heavy_laser
	muzzle_type = /obj/effect/projectile/muzzle/heavy_laser
	impact_type = /obj/effect/projectile/impact/heavy_laser

/obj/item/projectile/beam/laser/on_hit(atom/target, blocked = FALSE)
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.IgniteMob()
	else if(isturf(target))
		impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser/wall
	if(fire_hazard)
		var/turf/open/target_turf = get_turf(target)
		if(istype(target_turf))
			target_turf.IgniteTurf(rand(8, 16))
	return ..()

/obj/item/projectile/beam/weak
	damage = 15

/obj/item/projectile/beam/weak/penetrator
	armour_penetration = 50

/obj/item/projectile/beam/practice
	name = "practice laser"
	damage = 0
	nodamage = 1

/obj/item/projectile/beam/scatter
	name = "laser pellet"
	icon_state = "scatterlaser"
	damage = 12.5

/obj/item/projectile/beam/xray
	name = "\improper X-ray beam"
	icon_state = "xray"
	damage = 15
	irradiate = 100
	range = 30
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE | PASSCLOSEDTURF | PASSMACHINE | PASSSTRUCTURE
	projectile_piercing = ALL
	is_reflectable = TRUE
	var/damage_dropoff_multiplier = 0.9

	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	light_color = LIGHT_COLOR_GREEN
	tracer_type = /obj/effect/projectile/tracer/xray
	muzzle_type = /obj/effect/projectile/muzzle/xray
	impact_type = /obj/effect/projectile/impact/xray

/obj/item/projectile/beam/xray/Range()
	if(damage > 1)
		damage = max(1, damage * damage_dropoff_multiplier)
	return ..()

/obj/item/projectile/beam/disabler
	name = "disabler beam"
	icon_state = "omnilaser"
	damage = 30
	damage_type = STAMINA
	flag = ENERGY
	hitsound = 'sound/weapons/tap.ogg'
	eyeblur = 0
	pixels_per_second = TILES_TO_PIXELS(16.667)
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_range = 2
	light_power = 0.9
	light_color = LIGHT_COLOR_LIGHTBLUE // синий для станнеров/дизбайлеров
	glow_icon = 'icons/obj/projectiles.dmi'
	glow_icon_state = "omnilaser"
	tracer_type = /obj/effect/projectile/tracer/disabler
	muzzle_type = /obj/effect/projectile/muzzle/disabler
	impact_type = /obj/effect/projectile/impact/disabler

/obj/item/projectile/beam/disabler/on_hit(atom/target, blocked = FALSE)
	if(iscarbon(target) && HAS_TRAIT(target, TRAIT_DISABLER_RESISTANCE))
		do_sparks(1, TRUE, src)
		target.visible_message(span_warning("The [name] dissipates harmlessly against [target]!"))
		return
	return ..()

/obj/item/projectile/beam/disabler/swarmer
	name = "swarmer laser"
	icon = 'icons/obj/swarmer_projectiles.dmi'
	icon_state = "default_swarmer"
	glow_icon = null
	glow_icon_state = null
	damage = 23
	hit_prone_targets = TRUE

/obj/item/projectile/beam/disabler/swarmer/prehit_pierce(atom/A)
	if(isswarmer(A))
		return PROJECTILE_PIERCE_PHASE
	if(istype(A, /obj/structure/swarmer))
		var/obj/structure/swarmer/structure = A
		if(structure.projectiles_pass)
			return PROJECTILE_PIERCE_PHASE

	damage = initial(damage)
	damage_type = STAMINA
	if(ishuman(A) && !HAS_TRAIT(A, TRAIT_ROBOTIC_ORGANISM))
		damage *= SWARMER_STAMINA_SCALE
	else if(isliving(A) || istype(A, /obj/vehicle) || istype(A, /obj/durand_shield))
		damage_type = BURN
		if(istype(A, /obj/vehicle/sealed/mecha))
			// Сравниваем долю урона после энергетической брони «Дюранда» при попадании сбоку.
			damage = round(damage * (100 - max(0, 10 - armour_penetration)) / (100 - max(0, 30 - armour_penetration)), DAMAGE_PRECISION)
	return ..()

/obj/item/projectile/beam/disabler/swarmer/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(. && damage_type == STAMINA && ishuman(target) && blocked < 100 && !HAS_TRAIT(target, TRAIT_DISABLER_RESISTANCE))
		var/mob/living/human_target = target
		human_target.apply_status_effect(/datum/status_effect/swarmer_stamina_block)

/obj/item/projectile/beam/disabler/swarmer/generalist
	damage = 20

/obj/item/projectile/beam/disabler/swarmer/double
	name = "double swarmer laser"
	icon_state = "double_shot_swarmer"
	damage = 22

/obj/item/projectile/beam/disabler/swarmer/empowered
	name = "strong swarmer laser"
	icon_state = "charged_shot_swarmer"
	damage = 50
	knockdown = 1 SECONDS

/obj/item/projectile/beam/disabler/swarmer/minigun
	damage = 15

/obj/item/projectile/beam/disabler/swarmer/weak_turret
	name = "weak turret laser"
	damage = 10

/obj/item/projectile/beam/disabler/swarmer/strong_turret
	name = "strong turret laser"
	damage = 45
	armour_penetration = 30

/obj/item/projectile/beam/disabler/swarmer/strong_turret/prehit_pierce(atom/A)
	. = ..()
	if(. == PROJECTILE_PIERCE_NONE && pierces < 2)
		return PROJECTILE_PIERCE_HIT

/obj/item/projectile/beam/disabler/swarmer/sabotage
	name = "sabotage swarmer laser"
	icon_state = "sabotage_shot_swarmer"
	damage = 22

/obj/item/projectile/beam/disabler/swarmer/sabotage/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(!. || !isliving(target) || blocked >= 100)
		return
	var/mob/living/victim = target
	for(var/obj/item/gun/held_gun in victim.held_items)
		if(istype(held_gun, /obj/item/gun/energy))
			var/obj/item/gun/energy/energy_gun = held_gun
			var/ion_weapon = locate(/obj/item/ammo_casing/energy/ion) in energy_gun.ammo_type
			var/drain = ion_weapon ? 0.5 : 0.25
			var/obj/item/stock_parts/cell/cell = energy_gun.cell
			if(cell)
				cell.use(min(cell.charge, round(cell.maxcharge * drain)))
			energy_gun.set_firemode_to_type(/obj/item/ammo_casing/energy/disabler)
			energy_gun.update_icon()
			return
		if(istype(held_gun, /obj/item/gun/ballistic))
			var/obj/item/gun/ballistic/ballistic_gun = held_gun
			ballistic_gun.swarmer_unload(victim)
			return

/obj/item/projectile/beam/pulse
	name = "pulse"
	icon_state = "u_laser"
	damage = 50
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = LIGHT_COLOR_BLUE
	tracer_type = /obj/effect/projectile/tracer/pulse
	muzzle_type = /obj/effect/projectile/muzzle/pulse
	impact_type = /obj/effect/projectile/impact/pulse
	wound_bonus = 20

/obj/item/projectile/beam/pulse/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if (!QDELETED(target) && (isturf(target) || istype(target, /obj/structure)))
		target.ex_act(EXPLODE_HEAVY)
	var/turf/open/target_turf = get_turf(target)
	if(istype(target_turf))
		target_turf.IgniteTurf(rand(8, 22), "blue")

/obj/item/projectile/beam/pulse/shotgun
	damage = 40

/obj/item/projectile/beam/pulse/heavy
	name = "heavy pulse laser"
	icon_state = "pulse1_bl"
	pixels_per_second = TILES_TO_PIXELS(25)
	var/life = 20

/obj/item/projectile/beam/pulse/heavy/on_hit(atom/target, blocked = FALSE)
	life -= 10
	if(life > 0)
		. = BULLET_ACT_FORCE_PIERCE
	return ..()

/obj/item/projectile/beam/emitter
	name = "emitter beam"
	icon_state = "emitter"
	damage = 45
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	light_color = LIGHT_COLOR_GREEN
	wound_bonus = 20
	bare_wound_bonus = 20

/obj/item/projectile/beam/emitter/singularity_pull()
	return

/obj/item/projectile/beam/emitter/hitscan
	hitscan = TRUE
	muzzle_type = /obj/effect/projectile/muzzle/laser/emitter
	tracer_type = /obj/effect/projectile/tracer/laser/emitter
	impact_type = /obj/effect/projectile/impact/laser/emitter
	wound_bonus = 0
	bare_wound_bonus = 0
	armour_penetration = 0
	impact_effect_type = null

/obj/item/projectile/beam/lasertag
	name = "laser tag beam"
	icon_state = "omnilaser"
	hitsound = null
	damage = 0
	damage_type = STAMINA
	flag = LASER
	var/suit_types = list(/obj/item/clothing/suit/redtag, /obj/item/clothing/suit/bluetag)
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = LIGHT_COLOR_BLUE

/obj/item/projectile/beam/lasertag/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(ishuman(target))
		var/mob/living/carbon/human/M = target
		if(istype(M.wear_suit))
			if(M.wear_suit.type in suit_types)
				M.adjustStaminaLoss(34)

/obj/item/projectile/beam/lasertag/mag		//the projectile, compatible with regular laser tag armor
	icon_state = "magjectile-toy"
	name = "lasertag magbolt"
	range = 5		//so it isn't super annoying
	light_range = 2
	light_color = LIGHT_COLOR_YELLOW
	eyeblur = 0

/obj/item/projectile/beam/lasertag/mag/prehit_pierce(atom/target)
	return PROJECTILE_PIERCE_HIT

/obj/item/projectile/beam/lasertag/redtag
	icon_state = "laser"
	suit_types = list(/obj/item/clothing/suit/bluetag)
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	light_color = LIGHT_COLOR_RED
	tracer_type = /obj/effect/projectile/tracer/laser
	muzzle_type = /obj/effect/projectile/muzzle/laser
	impact_type = /obj/effect/projectile/impact/laser

/obj/item/projectile/beam/lasertag/redtag/hitscan
	hitscan = TRUE

/obj/item/projectile/beam/lasertag/redtag/hitscan/holy
	name = "lasrifle beam"
	damage = 0.1
	damage_type = BURN

/obj/item/projectile/beam/lasertag/bluetag
	icon_state = "bluelaser"
	suit_types = list(/obj/item/clothing/suit/redtag)
	tracer_type = /obj/effect/projectile/tracer/laser/blue
	muzzle_type = /obj/effect/projectile/muzzle/laser/blue
	impact_type = /obj/effect/projectile/impact/laser/blue

/obj/item/projectile/beam/lasertag/bluetag/hitscan
	hitscan = TRUE

/obj/item/projectile/beam/instakill
	name = "instagib laser"
	icon_state = "purple_laser"
	damage = 200
	damage_type = BURN
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	light_color = LIGHT_COLOR_PURPLE

/obj/item/projectile/beam/instakill/blue
	icon_state = "blue_laser"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = LIGHT_COLOR_BLUE

/obj/item/projectile/beam/instakill/red
	icon_state = "red_laser"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	light_color = LIGHT_COLOR_RED

/obj/item/projectile/beam/instakill/on_hit(atom/target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.visible_message("<span class='danger'>[M] explodes into a shower of gibs!</span>")
		M.gib()

//a shrink ray that shrinks stuff, which grows back after a short while.
/obj/item/projectile/beam/shrink
	name = "shrink ray"
	icon_state = "blue_laser"
	hitsound = 'sound/weapons/shrink_hit.ogg'
	damage = 0
	damage_type = STAMINA
	flag = ENERGY
	impact_effect_type = /obj/effect/temp_visual/impact_effect/shrink
	light_color = LIGHT_COLOR_BLUE
	var/shrink_time = 90

/obj/item/projectile/beam/shrink/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isopenturf(target) || istype(target, /turf/closed/indestructible))//shrunk floors wouldnt do anything except look weird, i-walls shouldnt be bypassable
		return
	target.AddComponent(/datum/component/shrink, shrink_time)
