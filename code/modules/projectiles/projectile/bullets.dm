/obj/item/projectile/bullet
	name = "bullet"
	icon_state = "bullet"
	damage = 60
	damage_type = BRUTE
	nodamage = FALSE
	candink = TRUE
	flag = BULLET
	hitsound_wall = "ricochet"
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	sharpness = SHARP_POINTY
	shrapnel_type = /obj/item/shrapnel/bullet
	embedding = list(embed_chance=15, fall_chance=2, jostle_chance=0, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.5, pain_mult=3, rip_time=10)
	wound_falloff_tile = -5
	embed_falloff_tile = -5
	wound_bonus = 4
	bare_wound_bonus = 6
	/// Brain damage applied on headshots when nonlethal_headshot_chance procs.
	var/nonlethal_headshot_brain_damage = 0
	/// Percent chance for nonlethal_headshot_brain_damage on headshots.
	var/nonlethal_headshot_chance = 0

/obj/item/projectile/bullet/smite
	name = "divine retribution"
	damage = 10
