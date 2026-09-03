#define REBAR_BOLT_ICONS 'modular_bluemoon/icons/obj/guns/crossbowbolts.dmi'

/obj/item/projectile/bullet/rebar
	name = "rebar"
	icon = REBAR_BOLT_ICONS
	icon_state = "Sharpenedironrod"
	damage = 30
	pixels_per_second = TILES_TO_PIXELS(12.5)
	dismemberment = 1
	armour_penetration = 10
	wound_bonus = -20
	bare_wound_bonus = 20
	embed_falloff_tile = -5
	wound_falloff_tile = -2
	shrapnel_type = /obj/item/ammo_casing/rebar
	embedding = list(
		embed_chance = 60,
		fall_chance = 2,
		jostle_chance = 2,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.4,
		pain_mult = 4,
		jostle_pain_mult = 2,
		rip_time = 10,
	)

/obj/item/projectile/bullet/rebar/syndie
	icon = REBAR_BOLT_ICONS
	icon_state = "Jagged iron rod"
	damage = 45
	dismemberment = 2
	armour_penetration = 20
	wound_bonus = 10
	embed_falloff_tile = -3
	shrapnel_type = /obj/item/ammo_casing/rebar/syndie
	embedding = list(
		embed_chance = 80,
		fall_chance = 1,
		jostle_chance = 3,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.4,
		pain_mult = 3,
		jostle_pain_mult = 2,
		rip_time = 14,
	)

/obj/item/projectile/bullet/rebar/zaukerite
	name = "zaukerite shard"
	icon = REBAR_BOLT_ICONS
	icon_state = "Zaukerite sliver"
	damage = 60
	pixels_per_second = TILES_TO_PIXELS(8)
	dismemberment = 10
	damage_type = TOX
	eyeblur = 5
	armour_penetration = 20
	wound_bonus = 10
	bare_wound_bonus = 40
	embed_falloff_tile = 0
	shrapnel_type = /obj/item/ammo_casing/rebar/zaukerite
	embedding = list(
		embed_chance = 100,
		fall_chance = 0,
		jostle_chance = 5,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.8,
		pain_mult = 6,
		jostle_pain_mult = 2,
		rip_time = 30,
	)

/obj/item/projectile/bullet/rebar/zaukerite/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		zaukerite_shard_inject(target, ZAUKERITE_SHARD_ZAUKER_AMOUNT)

/obj/item/projectile/bullet/rebar/hydrogen
	name = "metallic hydrogen bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Metallic hydrogen bolt"
	damage = 35
	pixels_per_second = TILES_TO_PIXELS(8)
	projectile_piercing = PASSMOB
	dismemberment = 0
	armour_penetration = 30
	wound_bonus = -100
	bare_wound_bonus = 0
	shrapnel_type = /obj/item/ammo_casing/rebar/hydrogen
	embed_falloff_tile = -3
	embedding = list(embed_chance = 0)

/obj/item/projectile/bullet/rebar/hydrogen/prehit_pierce(atom/A)
	if(pierces >= 3)
		return ..()
	if(isliving(A) || istype(A, /obj/vehicle))
		return PROJECTILE_PIERCE_HIT
	return ..()

/obj/item/projectile/bullet/rebar/healium
	name = "healium bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Healium crystal bolt"
	damage = 0
	dismemberment = 0
	armour_penetration = 100
	wound_bonus = -100
	bare_wound_bonus = -100
	embed_falloff_tile = -3
	shrapnel_type = /obj/item/ammo_casing/rebar/healium
	embedding = list(
		embed_chance = 100,
		fall_chance = 0,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.9,
		rip_time = 15,
	)

/obj/item/projectile/bullet/rebar/healium/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		healium_shard_inject(target, HEALIUM_SHARD_HEALIUM_AMOUNT)

/obj/item/projectile/bullet/rebar/n2o
	name = "N2O bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "N2O crystal bolt"
	damage = 20
	armour_penetration = 15
	wound_bonus = -10
	embed_falloff_tile = -3
	shrapnel_type = /obj/item/ammo_casing/rebar/n2o
	embedding = list(
		embed_chance = 90,
		fall_chance = 1,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.5,
		pain_mult = 3,
		jostle_pain_mult = 2,
		rip_time = 12,
	)

/obj/item/projectile/bullet/rebar/n2o/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		n2o_shard_inject(target, N2O_SHARD_N2O_AMOUNT)

/obj/item/projectile/bullet/rebar/hypernoblium
	name = "hypernoblium bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Hypernoblium crystal bolt"
	damage = 30
	armour_penetration = 100
	wound_bonus = -100
	bare_wound_bonus = -100
	embed_falloff_tile = -3
	shrapnel_type = /obj/item/ammo_casing/rebar/hypernoblium
	embedding = list(
		embed_chance = 100,
		fall_chance = 0,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.4,
		rip_time = 12,
	)

/obj/item/projectile/bullet/rebar/hypernoblium/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		hypernoblium_shard_inject(target, HYPERNOBLIUM_SHARD_AMOUNT)

/obj/item/projectile/bullet/rebar/nitrium
	name = "nitrium bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Nitrium crystal bolt"
	damage = 25
	armour_penetration = 15
	wound_bonus = 0
	embed_falloff_tile = -3
	shrapnel_type = /obj/item/ammo_casing/rebar/nitrium
	embedding = list(
		embed_chance = 80,
		fall_chance = 2,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.5,
		pain_mult = 3,
		jostle_pain_mult = 2,
		rip_time = 12,
	)

/obj/item/projectile/bullet/rebar/nitrium/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		nitrium_shard_inject(target, NITRIUM_SHARD_AMOUNT)

/obj/item/projectile/bullet/rebar/proto_nitrate
	name = "proto nitrate bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Proto nitrate crystal bolt"
	damage = 25
	damage_type = TOX
	armour_penetration = 20
	wound_bonus = 5
	embed_falloff_tile = -2
	shrapnel_type = /obj/item/ammo_casing/rebar/proto_nitrate
	embedding = list(
		embed_chance = 85,
		fall_chance = 2,
		ignore_throwspeed_threshold = TRUE,
		pain_stam_pct = 0.6,
		pain_mult = 4,
		jostle_pain_mult = 2,
		rip_time = 14,
	)

/obj/item/projectile/bullet/rebar/proto_nitrate/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		proto_nitrate_shard_inject(target, PROTO_NITRATE_SHARD_AMOUNT)

/obj/item/projectile/bullet/rebar/supermatter
	name = "supermatter bolt"
	icon = REBAR_BOLT_ICONS
	icon_state = "Supermatter bolt"
	damage = 0
	dismemberment = 0
	damage_type = TOX
	embedding = null
	armour_penetration = 100
	shrapnel_type = /obj/item/ammo_casing/rebar/supermatter

/obj/item/projectile/bullet/rebar/supermatter/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		visible_message(span_danger("[target] is hit by [src], turning [target.p_them()] to dust in a brilliant flash of light!"))
		playsound(get_turf(src), 'sound/effects/supermatter.ogg', 10, TRUE)
		victim.dust()
	else if(!isturf(target))
		visible_message(span_danger("[target] is hit by [src], turning [target.p_them()] to dust in a brilliant flash of light!"))
		playsound(get_turf(src), 'sound/effects/supermatter.ogg', 10, TRUE)
		qdel(target)
	return BULLET_ACT_HIT

/obj/item/projectile/bullet/paperball
	desc = "Doink!"
	damage = 1
	range = 10
	shrapnel_type = null
	embedding = null
	name = "paper ball"
	damage_type = BRUTE
	icon = REBAR_BOLT_ICONS
	icon_state = "paperball"
