#define NONLETHAL_HEAD_EFFECT_CHANCE 25

/obj/item/projectile/bullet/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	apply_nonlethal_headshot_effects(target, blocked)
	return .

/obj/item/projectile/bullet/proc/apply_nonlethal_headshot_effects(atom/target, blocked)
	if(blocked >= 100)
		return
	if(!nonlethal_headshot_chance)
		return
	if(!iscarbon(target) || def_zone != BODY_ZONE_HEAD)
		return
	if(!prob(nonlethal_headshot_chance))
		return
	var/mob/living/carbon/C = target
	C.flash_act(intensity = 10, override_protection = 1)
	SEND_SOUND(C, sound('sound/effects/headgibb.ogg', volume = 50))

/obj/item/projectile/bullet/c10mm/soporific
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/c38/rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/c38/trac
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/c22lr/rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/a357/rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

// Rifles
/obj/item/projectile/bullet/a556_rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/a762x39_rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/a308/rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/a543/rubber
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

// Sniper
/obj/item/projectile/bullet/p50/soporific
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

#undef NONLETHAL_HEAD_EFFECT_CHANCE
