/obj/item/projectile/bullet/c45 // Yes I know I am changing how .45 weapons work by making the basic ammo less-than-lethal. This just makes this easier in the long run with mags
	name = ".45 rubber bullet"
	damage = 2 //10 before
	stamina = 33
	sharpness = NONE

//I am an idiot, fucking coding oversights. If one ever makes a child of a object, MAKE SURE TO ADD IN VALUES TO ADJUST FROM PARENT 	stamina = 30 will be a reminder to that.

/obj/item/projectile/bullet/c45/lethal
	name = ".45 bullet"
	damage = 25 // 30 before
	wound_bonus = 6 // 6 before
	stamina = 0
	wound_falloff_tile = -10
	sharpness = NONE // AHUY


/obj/item/projectile/bullet/c45/hydra
	name = ".45 Hydra-shock bullet"
	damage = 30 // BLUEMOON CHANGE balancing, was 15
	stamina = 0
	armour_penetration = -20 // BLUEMOON CHANGE balancing, was -65
	sharpness = SHARP_EDGED
	wound_bonus = 30 // 30 WTF
	bare_wound_bonus = 30 // 30 WTF
	embedding = list(embed_chance=75, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)
	wound_falloff_tile = -5
	embed_falloff_tile = -15

/obj/item/projectile/bullet/c45/trac
	name = ".45 TRAC bullet"
	damage = 15 // 15 before
	stamina = 0

/obj/item/projectile/bullet/c45/ion
	projectile_type = /obj/item/projectile/ion/weak

/obj/item/projectile/bullet/c45/trac/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/mob/living/carbon/M = target
	var/obj/item/implant/tracking/c38/imp
	for(var/obj/item/implant/tracking/c38/TI in M.implants) //checks if the target already contains a tracking implant
		imp = TI
		return
	if(!imp)
		imp = new /obj/item/implant/tracking/c38(M)
		imp.implant(M)

/obj/item/projectile/bullet/c45/hotshot //similar to incendiary bullets, but do not leave a flaming trail
	name = ".45 Hot Shot bullet"
	damage = 20 // 20 before
	stamina = 0
	sharpness = SHARP_EDGED

/obj/item/projectile/bullet/c45/hotshot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(6)
		M.IgniteMob()

/obj/item/projectile/bullet/c45_cleaning
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
	sharpness = NONE
	embedding = null
