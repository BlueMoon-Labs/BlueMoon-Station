/obj/item/projectile/bullet/c45 // Yes I know I am changing how .45 weapons work by making the basic ammo less-than-lethal. This just makes this easier in the long run with mags
	name = ".45 rubber bullet"
	damage = 2
	stamina = 33
	armour_penetration = BULLET_BR0   // BLUEMOON ADD: резина = BR0
	sharpness = SHARP_NONE


//I am an idiot, fucking coding oversights. If one ever makes a child of a object, MAKE SURE TO ADD IN VALUES TO ADJUST FROM PARENT 	stamina = 30 will be a reminder to that.

/obj/item/projectile/bullet/c45/lethal
	name = ".45 bullet"
	damage = 25
	armour_penetration = BULLET_BR1
	wound_bonus = 15
	bare_wound_bonus = 20 // Пуля тяжелая, должна делать бо-бо
	wound_falloff_tile = -10


/obj/item/projectile/bullet/c45/hydra
	name = ".45 Hydra-shock bullet"
	damage = 30
	stamina = 0
	armour_penetration = BULLET_BR0 - 20  // -20 (HP экспансивный)
	sharpness = SHARP_EDGED
	wound_bonus = 30
	bare_wound_bonus = 30
	embedding = list(embed_chance=75, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)
	wound_falloff_tile = -5
	embed_falloff_tile = -15

/obj/item/projectile/bullet/c45/trac
	name = ".45 TRAC bullet"
	damage = 15
	armour_penetration = BULLET_BR0   // трекер не про пробитие

/obj/item/projectile/bullet/c45/ion
	projectile_type = /obj/item/projectile/ion/weak

/obj/item/projectile/bullet/c45/trac/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!iscarbon(target))
		return

	var/mob/living/carbon/C = target
	if(locate(/obj/item/gps/embed_gps) in C)
		return

	var/obj/item/gps/embed_gps/gps = new(target)
	gps.tryEmbed(C, forced = TRUE, silent = TRUE)

	// var/obj/item/implant/tracking/c38/imp
	// for(var/obj/item/implant/tracking/c38/TI in M.implants) //checks if the target already contains a tracking implant
	// 	imp = TI
	// 	return
	// if(!imp)
	// 	imp = new /obj/item/implant/tracking/c38(M)
	// 	imp.implant(M)

/obj/item/projectile/bullet/c45/hotshot
	name = ".45 Hot Shot bullet"
	damage = 20
	armour_penetration = BULLET_BR1   // зажигательный как базовый летальный
	stamina = 0
	sharpness = SHARP_EDGED

/obj/item/projectile/bullet/c45/hotshot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(6)
		M.IgniteMob()

// .45 старый (не bluemoon) — BR1
/obj/item/projectile/bullet/c45_cleaning
	armour_penetration = BULLET_BR1
	sharpness = SHARP_EDGED

/obj/item/projectile/energy/electrode/c45
	tase_duration = 40
	knockdown = 10
	stamina = 15
	knockdown_stamoverride = 5
	knockdown_stam_max = 40
	strong_tase = FALSE

/obj/item/projectile/bullet/c9mm/rubber
	name = "9mm Rubber"
	damage = 2
	stamina = 33
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null
