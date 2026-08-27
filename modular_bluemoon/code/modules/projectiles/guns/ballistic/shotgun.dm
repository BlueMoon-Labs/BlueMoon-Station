#define KS23_HEAD_GIB_CLOSE_RANGE 2
#define KS23_HEAD_GIB_CHANCE 30
#define KS23_RUBBER_HEAD_EFFECT_CHANCE 25

// КС-23 слаг — BR4, огромный калибр
/obj/item/projectile/bullet/slug23
	name = "23 shotgun slug"
	damage = 70
	stamina = 70
	armour_penetration = BULLET_BR4   // BLUEMOON EDIT: было 50 → BR4(50), без изменений
	sharpness = SHARP_POINTY
	wound_bonus = 5

/obj/item/projectile/bullet/slug23/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(blocked >= 100)
		return .
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(def_zone == BODY_ZONE_HEAD && starting && get_dist(starting, get_turf(C)) <= KS23_HEAD_GIB_CLOSE_RANGE && prob(KS23_HEAD_GIB_CHANCE))
			C.gib_head()
	return .

// КС-23 резина — BR0
/obj/item/projectile/bullet/slug_rubber23
	name = "23 rubber slug"
	damage = 20
	stamina = 120
	armour_penetration = BULLET_BR0
	wound_bonus = 2
	sharpness = SHARP_NONE
	embedding = null

	nonlethal_headshot_chance = KS23_RUBBER_HEAD_EFFECT_CHANCE

/obj/item/projectile/bullet/pellet/rubbershot23
	name = "23 rubbershot pellet"
	icon_state = "pellet"
	damage = 3
	stamina = 18
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null

	nonlethal_headshot_chance = KS23_RUBBER_HEAD_EFFECT_CHANCE

// Стартовые AP для пеллетов — высокие, но быстро падают через Range()
// КС-23 боевая дробь — BR3 в упор (шьёт бронежилет), BR0 на 4+ тайлах
/obj/item/projectile/bullet/pellet/buckshot23
	name = "23 buckshot pellet"
	icon_state = "pellet"
	damage = 12
	stamina = 8
	armour_penetration = 35    // BLUEMOON EDIT: было BR1(10) → 35 (BR3 в упор, падает быстро)
	wound_bonus = 5
	bare_wound_bonus = 5
	wound_falloff_tile = -2.5

/obj/item/ammo_box/magazine/internal/shot/KS23
	name = "KS-23 shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/buckshot23
	caliber = "23"
	max_ammo = 3

/obj/item/gun/ballistic/shotgun/KS23
	name = "KS-23 shotgun"
	desc = "War crimes are fun!"
	icon = 'icons/obj/guns/ShotgunsReheated.dmi'
	icon_state = "Ks23"
	item_state = "ks23-wielded"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/back.dmi'
	fire_sound = 'sound/weapons/Shotguns_reheated/KS-23/Ks-23shot.ogg'
	pumpsound = 'sound/weapons/Shotguns_reheated/KS-23/Ks-23Pumpaction.ogg'
	loadshell_sound = 'sound/weapons/Shotguns_reheated/Shared/Shellinstertplastic.wav'
	empty_pumpsound_forward = "sound/weapons/Shotguns_reheated/Ks-23/Ks-23empty_forward.ogg"
	empty_pumpsound_back = "sound/weapons/Shotguns_reheated/Ks-23/Ks-23empty_back.ogg"
	empty_loadshell_sound = "sound/weapons/Shotguns_reheated/shared/chambershell.ogg"
	force = 15 //Дробовик тяжёлый, следовательно...
	empty_reload = TRUE
	fire_delay = 6
	mag_type = /obj/item/ammo_box/magazine/internal/shot/KS23

/obj/item/gun/ballistic/shotgun/KS23/update_icon()
    . = ..()
    if(current_skin)
        icon_state = unique_reskin[current_skin]["icon_state"] + (chambered ? "" : "-e")
    else
        icon_state = initial(icon_state) + (chambered ? "" : "-e")

/obj/item/gun/ballistic/shotgun/KS23/pump_unload(mob/M)
	if(chambered)//We have a shell in the chamber
		chambered.forceMove(drop_location())//Eject casing
		chambered.bounce_away()
		chambered = null

/obj/item/gun/ballistic/shotgun/KS23/Inquisitor
	name = "Праведный Гнев Верующих"
	desc = "Не бойся, Джон!"
	icon_state = "Ks23inq"
	item_state = "ks23inq-wielded"

// Вы ведь любите военные преступления?
/obj/item/projectile/bullet/ks23_round
	name = "KS23 pepper round"
	damage = 5
	sharpness = SHARP_NONE
	range = 4
	armour_penetration = 0

/obj/item/projectile/bullet/ks23_round/on_hit(atom/target, blocked = FALSE)
	. = ..()
	// Создание завессы при попадании
	var/turf/T = get_turf(target)
	if(!T)
		T = get_turf(src)
	var/datum/reagents/R = new/datum/reagents(200)
	R.add_reagent(/datum/reagent/consumable/condensedcapsaicin, 100)
	// Датум на создание дыма
	var/datum/effect_system/smoke_spread/pepper/SM = new /datum/effect_system/smoke_spread/pepper
	SM.set_up(R, 1, T, TRUE)
	SM.start()
	playsound(T, 'sound/effects/spray2.ogg', 40, 1)
	return BULLET_ACT_HIT
