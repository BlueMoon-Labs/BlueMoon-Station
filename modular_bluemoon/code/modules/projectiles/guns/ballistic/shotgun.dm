/obj/item/projectile/bullet/slug23
	name = "23 shotgun slug"
	damage = 70
	stamina = 70
	armour_penetration = 50
	sharpness = SHARP_POINTY
	wound_bonus = 5

/obj/item/projectile/bullet/slug_rubber23
	name = "23 rubber slug"
	damage = 20
	stamina = 120
	wound_bonus = 2
	sharpness = SHARP_NONE
	embedding = null

/obj/item/projectile/bullet/pellet/buckshot23
	name = "23 buckshot pellet"
	damage = 12
	stamina = 8
	wound_bonus = 5
	bare_wound_bonus = 5
	wound_falloff_tile = -2.5

/obj/item/projectile/bullet/pellet/rubbershot23
	name = "23 rubbershot pellet"
	damage = 3
	stamina = 18
	sharpness = SHARP_NONE
	embedding = null

/obj/item/ammo_box/magazine/internal/shot/KS23
	name = "KS-23 shotgun internal magazine"
	ammo_type = /obj/item/ammo_casing/buckshot23
	caliber = "23"
	max_ammo = 3

/obj/item/gun/ballistic/shotgun/KS23
	name = "KS-23 shotgun"
	desc = "War crimes are fun!"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/back.dmi'
	fire_sound = 'modular_bluemoon/sound/weapons/fire_KS23.ogg'
	icon_state = "KS-23"
	item_state = "KS-23"
	fire_delay = 7
	mag_type = /obj/item/ammo_box/magazine/internal/shot/KS23

/obj/item/gun/ballistic/shotgun/KS23/pump_unload(mob/M)
	if(chambered)//We have a shell in the chamber
		chambered.forceMove(drop_location())//Eject casing
		chambered.bounce_away()
		chambered = null
		playsound(src, 'modular_bluemoon/sound/weapons/shell_fall_KS23.ogg', 45, 1)

/obj/item/gun/ballistic/shotgun/KS23/Inquisitor
	name = "Righteous Wrath of the Faithful"
	desc = "Don't be afraid, John!"
	icon_state = "KS-23TheInquisitor"
	item_state = "KS-23TheInquisitor"
