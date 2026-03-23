// Red kill lasers for the big gun (~20 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_big_kill
	projectile_type = /obj/item/projectile/beam/cybersun_laser
	e_cost = 500
	select_name = "Kill"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/laser.ogg'

/obj/item/projectile/beam/cybersun_laser
	icon = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/projectiles.dmi'
	icon_state = "kill_large"
	damage = 25
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	light_color = COLOR_SOFT_RED
	wound_falloff_tile = -1

// Speedy sniper lasers for the big gun (15 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_big_sniper
	projectile_type = /obj/item/projectile/beam/cybersun_laser/marksman
	e_cost = 1000
	select_name = "Marksman"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/vaporize.ogg'

/obj/item/projectile/beam/cybersun_laser/marksman
	icon_state = "sniper"
	damage = 80
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	pixels_per_second = TILES_TO_PIXELS(30)
	light_range = 2
	light_color = COLOR_VERY_SOFT_YELLOW
	wound_falloff_tile = -0.1
	armour_penetration = 15

// Disabler machinegun for the big gun (50 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_big_disabler
	projectile_type = /obj/item/projectile/beam/cybersun_laser/disable
	e_cost = 200
	select_name = "Disable"
	harmful = FALSE

/obj/item/projectile/beam/cybersun_laser/disable
	icon_state = "disable_large"
	damage = 0
	stamina = 20
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = COLOR_BRIGHT_BLUE

// Plasma burst grenade for the big gun (10 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_big_launcher
	projectile_type = /obj/item/projectile/beam/cybersun_laser/granata
	e_cost = 1000
	select_name = "Launcher"

/obj/item/projectile/beam/cybersun_laser/granata
	name = "plasma grenade"
	icon_state = "grenade"
	damage = 75
	pixels_per_second = TILES_TO_PIXELS(10)
	range = 6
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	light_color = COLOR_PALE_GREEN_GRAY
	pass_flags = PASSTABLE | PASSGRILLE // His ass does NOT pass through glass!
	/// What type of casing should we put inside the bullet to act as shrapnel later
	var/casing_to_spawn = /obj/item/grenade/c980payload/plasma_grenade

/obj/item/projectile/beam/cybersun_laser/granata/on_hit(atom/target, blocked = 0, pierce_hit)
	..()
	fuse_activation(target)
	return BULLET_ACT_HIT

/obj/item/projectile/beam/cybersun_laser/granata/on_range()
	fuse_activation(get_turf(src))
	return ..()

/// Called when the projectile reaches its max range, or hits something
/obj/item/projectile/beam/cybersun_laser/granata/proc/fuse_activation(atom/target)
	var/obj/item/grenade/shrapnel_maker = new casing_to_spawn(get_turf(target))
	shrapnel_maker.prime()
	playsound(src, 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/grenade_burst.ogg', 50, TRUE, -3)
	qdel(shrapnel_maker)

/obj/item/projectile/beam/cybersun_laser/granata_shrapnel
	name = "plasma globule"
	icon_state = "flare"
	damage = 10
	pixels_per_second = TILES_TO_PIXELS(10)
	wound_bonus = -50
	bare_wound_bonus = 55
	range = 2
	pass_flags = PASSTABLE | PASSGRILLE
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	light_color = COLOR_PALE_GREEN_GRAY
	wound_falloff_tile = -3

/obj/item/grenade/c980payload/plasma_grenade
	shrapnel_type = /obj/item/projectile/beam/cybersun_laser/granata_shrapnel
	shrapnel_radius = 3

// Shotgun casing for the big gun (20 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_big_shotgun
	projectile_type = /obj/item/projectile/beam/cybersun_laser/granata_shrapnel/shotgun_pellet
	e_cost = 500
	pellets = 7
	variance = 30
	select_name = "Shotgun"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/melt.ogg'

/obj/item/projectile/beam/cybersun_laser/granata_shrapnel/shotgun_pellet
	icon_state = "because_it_doesnt_miss"
	damage = 12
	impact_effect_type = /obj/effect/temp_visual/impact_effect/purple_laser
	pixels_per_second = TILES_TO_PIXELS(15)
	light_color = COLOR_PINK
	range = 9
	wound_falloff_tile = -3
// Hellfire lasers for the little guy / carbine (10 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_small_hellfire
	projectile_type = /obj/item/projectile/beam/cybersun_laser/hellfire
	e_cost = 1000
	select_name = "Incinerate"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/melt.ogg'

/obj/item/projectile/beam/cybersun_laser/hellfire
	icon_state = "hellfire"
	damage = 20
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	pixels_per_second = TILES_TO_PIXELS(20)
	wound_bonus = 0
	light_color = COLOR_SOFT_RED

// Bounce disabler lasers for the little guy / carbine (20 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_small_disabler
	projectile_type = /obj/item/projectile/beam/cybersun_laser/disable_bounce
	e_cost = 500
	select_name = "Disable"
	harmful = FALSE

/obj/item/projectile/beam/cybersun_laser/disable_bounce
	icon_state = "disable_bounce"
	damage = 0
	stamina = 30
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser
	light_color = COLOR_BRIGHT_BLUE
	ricochet_auto_aim_angle = 30
	ricochet_auto_aim_range = 5
	ricochets_max = 2
	ricochet_incidence_leeway = 100
	ricochet_chance = 130
	ricochet_decay_damage = 0.8

/obj/item/projectile/beam/cybersun_laser/disable_bounce/check_ricochet_flag(atom/reflecting_atom)
	if((reflecting_atom.flags_ricochet & RICOCHET_HARD) || (reflecting_atom.flags_ricochet & RICOCHET_SHINY))
		return TRUE
	return FALSE

// Flare launcher / carbine (10 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_small_launcher
	projectile_type = /obj/item/projectile/beam/cybersun_laser/flare
	e_cost = 1000
	select_name = "Flare"

/obj/item/projectile/beam/cybersun_laser/flare
	name = "plasma flare"
	icon_state = "flare"
	damage = 30
	pixels_per_second = TILES_TO_PIXELS(10)
	range = 6
	impact_effect_type = /obj/effect/temp_visual/impact_effect/green_laser
	light_color = COLOR_PALE_GREEN_GRAY
	pass_flags = PASSTABLE | PASSGRILLE // His ass does NOT pass through glass!
	/// How many firestacks the bullet should impart upon a target when impacting
	var/firestacks_to_give = 2
	/// What we spawn when we range out
	var/obj/illumination_flare = /obj/item/flashlight/flare/plasma_projectile

/obj/item/projectile/beam/cybersun_laser/flare/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/gaslighter = target
		gaslighter.adjust_fire_stacks(firestacks_to_give)
		gaslighter.IgniteMob()
	else
		new illumination_flare(get_turf(target))

/obj/item/projectile/beam/cybersun_laser/flare/on_range()
	new illumination_flare(get_turf(src))
	return ..()

/obj/item/flashlight/flare/plasma_projectile
	name = "plasma flare"
	desc = "A burning glob of green plasma, makes an effective temporary lighting source."
	light_range = 4
	anchored = TRUE
	icon = 'modular_bluemoon/code/modules/modular_laser_rifle/icons/projectiles.dmi'
	icon_state = "flare_burn"
	light_color = COLOR_PALE_GREEN_GRAY
	light_power = 2

/obj/item/flashlight/flare/plasma_projectile/Initialize(mapload)
	. = ..()
	fuel = rand(3 MINUTES, 5 MINUTES)
	on = TRUE
	force = on_damage
	damtype = "fire"
	START_PROCESSING(SSobj, src)
	update_brightness(null)

/obj/item/flashlight/flare/plasma_projectile/turn_off()
	. = ..()
	qdel(src)

// Shotgun casing for the small gun / carbine (10 shots from 10k cell)

/obj/item/ammo_casing/energy/cybersun_small_shotgun
	projectile_type = /obj/item/projectile/beam/cybersun_laser/granata_shrapnel/shotgun_pellet
	e_cost = 1000
	pellets = 5
	variance = 20
	select_name = "Shotgun"
	fire_sound = 'modular_bluemoon/code/modules/modular_laser_rifle/sounds/melt.ogg'

// Dummy casing that does nothing but have a projectile that looks like a sword / carbine (100 hits from 10k cell)

/obj/item/ammo_casing/energy/cybersun_small_blade
	projectile_type = /obj/item/projectile/beam/cybersun_laser/blade
	e_cost = 100
	select_name = "Blade"

/obj/item/projectile/beam/cybersun_laser/blade
	icon_state = "blade"
