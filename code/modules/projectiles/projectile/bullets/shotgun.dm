// 12g слаг — BR2
/obj/item/projectile/bullet/shotgun_slug
	name = "12g shotgun slug"
	damage = 45
	armour_penetration = BULLET_BR2   // BLUEMOON EDIT: было 30 → BR2(20)... нет, было 30
// оставляем 30 как есть (между BR2 и BR3, допустимо)
	sharpness = SHARP_POINTY
	wound_bonus = 6

/obj/item/projectile/bullet/shotgun_slug/executioner
	name = "executioner slug" // admin only, can dismember limbs
	sharpness = SHARP_EDGED
	wound_bonus = 80

/obj/item/projectile/bullet/shotgun_slug/pulverizer
	name = "pulverizer slug" // admin only, can crush bones
	sharpness = SHARP_NONE
	wound_bonus = 80

#define NONLETHAL_HEAD_BRAIN_DAMAGE 50
#define NONLETHAL_HEAD_EFFECT_CHANCE 25

// Beanbag — BR0
/obj/item/projectile/bullet/shotgun_beanbag
	name = "beanbag slug"
	icon_state = "pellet"
	damage = 5
	stamina = 80                      // BLUEMOON EDIT: было 70 → 80
	armour_penetration = BULLET_BR0
	wound_bonus = 2
	sharpness = SHARP_NONE
	embedding = null
	nonlethal_headshot_brain_damage = NONLETHAL_HEAD_BRAIN_DAMAGE
	nonlethal_headshot_chance = NONLETHAL_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/incendiary/shotgun
	name = "incendiary slug"
	damage = 20

/obj/item/projectile/bullet/incendiary/shotgun/dragonsbreath
	name = "dragonsbreath pellet"
	icon_state = "pellet"
	damage = 5

/obj/item/projectile/bullet/shotgun_stunslug
	name = "stunslug"
	damage =  5
	armour_penetration = BULLET_BR0 // Stunslug — BR0
	stamina = 60 //30 - Для 12 калибра 30 это реально мало если сравнивать с более удобными аналогами
	knockdown = 5
	stutter = 5
	jitter = 20
	range = 7
	icon_state = "spark"
	color = "#FFFF00"
	var/tase_duration = 50

/obj/item/projectile/bullet/shotgun_stunslug/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!ismob(target) || blocked >= 100) //Fully blocked by mob or collided with dense object - burst into sparks!
		do_sparks(1, TRUE, src)
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		SEND_SIGNAL(C, COMSIG_ADD_MOOD_EVENT, "tased", /datum/mood_event/tased)
		SEND_SIGNAL(C, COMSIG_LIVING_MINOR_SHOCK)
		C.IgniteMob()
		if(C.dna && C.dna.check_mutation(HULK))
			C.say(pick(";RAAAAAAAARGH!", ";HNNNNNNNNNGGGGGGH!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGHH!", ";AAAAAAARRRGH!" ), forced = "hulk")
		else if(tase_duration && (C.status_flags & CANKNOCKDOWN) && !HAS_TRAIT(C, TRAIT_STUNIMMUNE) && !HAS_TRAIT(C, TRAIT_TASED_RESISTANCE))
			C.electrocute_act(15, src, 1, SHOCK_NOSTUN)
			C.apply_status_effect(STATUS_EFFECT_TASED_WEAK, tase_duration)

// Meteorslug — BR0 (нелетальный)
/obj/item/projectile/bullet/shotgun_meteorslug
	name = "meteorslug"
	icon = 'icons/obj/meteor.dmi'
	icon_state = "dust"
	damage = 20
	knockdown = 80
	armour_penetration = BULLET_BR0
	hitsound = 'sound/effects/meteorimpact.ogg'

/obj/item/projectile/bullet/shotgun_meteorslug/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(ismovable(target))
		var/atom/movable/M = target
		var/atom/throw_target = get_edge_target_turf(M, get_dir(src, get_step_away(M, src)))
		M.safe_throw_at(throw_target, 3, 2)

/obj/item/projectile/bullet/shotgun_meteorslug/Initialize(mapload)
	. = ..()
	SpinAnimation()

// frag12 — BR1
/obj/item/projectile/bullet/shotgun_frag12
	name ="frag12 slug"
	damage = 25
	knockdown = 50
	armour_penetration = BULLET_BR1

/obj/item/projectile/bullet/shotgun_frag12/on_hit(atom/target, blocked = FALSE)
	..()
	explosion(target, -1, 0, 1)
	return BULLET_ACT_HIT

/obj/item/projectile/bullet/pellet
	var/tile_dropoff = 0.45
	var/tile_dropoff_s = 1.25
	var/tile_dropoff_ap = 8    // BLUEMOON ADD

// Стандартная дробь 12g — BR1
/obj/item/projectile/bullet/pellet/shotgun_buckshot
	name = "buckshot pellet"
	icon_state = "pellet"
	damage = 12.5                     // BLUEMOON EDIT: было 7.5 → 12.5 (конкретно Bluemoon переопределение)
	armour_penetration = BULLET_BR1   // BLUEMOON ADD
	wound_bonus = 5
	bare_wound_bonus = 5
	wound_falloff_tile = -2.5  // low damage + additional dropoff will already curb wounding potential anything past point blank

// Резиновая дробь 12g — BR0
/obj/item/projectile/bullet/pellet/shotgun_rubbershot
	name = "rubbershot pellet"
	icon_state = "pellet"
	damage = 2
	stamina = 25                      // BLUEMOON EDIT: было 15 → 25
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null

/obj/item/projectile/bullet/pellet/Range()
	..()
	if(damage > 0)
		damage -= tile_dropoff
	if(stamina > 0)
		stamina -= tile_dropoff_s
	// BLUEMOON ADD START - AP дропофф: высокое пробитие в упор, падает до нуля на дистанции
	if(armour_penetration > 0)
		armour_penetration = max(0, armour_penetration - tile_dropoff_ap)
	// BLUEMOON ADD END
	if(damage < 0 && stamina < 0)
		qdel(src)

// Самодельная дробь — BR0 (ненадёжная, слабая)
/obj/item/projectile/bullet/pellet/shotgun_improvised
	icon_state = "pellet"
	armour_penetration = BULLET_BR0
	tile_dropoff = 0.35
	damage = 6
	wound_bonus = 0
	bare_wound_bonus = 7.5

/obj/item/projectile/bullet/pellet/shotgun_improvised/Initialize(mapload)
	. = ..()
	range = rand(1, 8)

/obj/item/projectile/bullet/pellet/shotgun_improvised/on_range()
	do_sparks(1, TRUE, src)
	..()

// Mech Scattershots

/obj/item/projectile/bullet/scattershot
	damage = 20
	armour_penetration = BULLET_BR1

/obj/item/projectile/bullet/seed
	armour_penetration = BULLET_BR0
	damage = 4
	stamina = 1

/obj/item/projectile/bullet/pellet/shotgun_incapacitate
	name = "incapacitating pellet"
	icon_state = "pellet"
	damage = 1
	stamina = 6
	armour_penetration = BULLET_BR0

#undef NONLETHAL_HEAD_BRAIN_DAMAGE
#undef NONLETHAL_HEAD_EFFECT_CHANCE
