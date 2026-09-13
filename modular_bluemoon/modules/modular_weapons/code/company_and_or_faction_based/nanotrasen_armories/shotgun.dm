/obj/item/gun/ballistic/automatic/shotgun/katyusha
	name = "\improper Katyusha Shotgun"
	desc = "A mag-fed shotgun for combat in narrow corridors, \
		nicknamed 'Katyusha' by the blueshields for its versatility. Compatible only with specialized 10-shell drum magazines."

	icon = 'modular_bluemoon/modules/modular_weapons/icons/obj/company_and_or_faction_based/nanotrasen_armories/ballistic48x.dmi'
	icon_state = "spikewall"
	item_state = "spikewall"
	mob_overlay_icon = 'modular_bluemoon/modules/modular_weapons/icons/mob/company_and_or_faction_based/nanotrasen_armories/guns_worn.dmi'
	lefthand_file = 'modular_bluemoon/modules/modular_weapons/icons/mob/company_and_or_faction_based/nanotrasen_armories/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/modules/modular_weapons/icons/mob/company_and_or_faction_based/nanotrasen_armories/guns_righthand.dmi'

	pixel_x = -8
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	obj_flags = UNIQUE_RENAME
	weapon_weight = WEAPON_HEAVY
	slot_flags = ITEM_SLOT_BACK
	mag_type = /obj/item/ammo_box/magazine/katyusha
	var/spawned_magazine_type = /obj/item/ammo_box/magazine/katyusha/buckshot

	can_suppress = FALSE
	fire_delay = 8
	fire_sound = 'modular_bluemoon/sound/weapons/shotgun_nova.ogg'

	burst_size = 1
	automatic_burst_overlay = FALSE
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	actions_types = list()

	var/mag_display = TRUE
	var/mag_display_ammo = FALSE
	var/empty_indicator = TRUE

/obj/item/gun/ballistic/automatic/shotgun/katyusha/Initialize(mapload)
	if(spawnwithmagazine && !magazine)
		magazine = new spawned_magazine_type(src)
		chamber_round()
	return ..()

/obj/item/gun/ballistic/automatic/shotgun/katyusha/update_icon_state()
	icon_state = "[initial(icon_state)]"

/obj/item/gun/ballistic/automatic/shotgun/katyusha/update_overlays()
	. = ..()

	if(!chambered && empty_indicator)
		. += "[icon_state]_empty"

	if(!magazine || !mag_display)
		return

	. += "[icon_state]_mag"

	if(!mag_display_ammo)
		return

	var/capacity_number
	switch(get_ammo() / magazine.max_ammo)
		if(1 to INFINITY)
			capacity_number = 100
		if(0.8 to 1)
			capacity_number = 80
		if(0.6 to 0.8)
			capacity_number = 60
		if(0.4 to 0.6)
			capacity_number = 40
		if(0.2 to 0.4)
			capacity_number = 20
		else
			capacity_number = 0

	if(capacity_number)
		. += "[icon_state]_mag_[capacity_number]"

/obj/item/gun/ballistic/automatic/shotgun/katyusha/afterattack()
	. = ..()
	empty_alarm()

/obj/item/gun/ballistic/automatic/shotgun/katyusha/jager
	name = "\improper Jäger Shotgun"
	desc = "A mag-fed shotgun for combat in narrow corridors, \
		nicknamed 'Jäger' by the Solar Federation Marines for its versatility in clearing tight corridors, and special operations in hunting individuals."

	icon_state = "jager"
	item_state = "jager"

	mag_type = /obj/item/ammo_box/magazine/jager
	spawned_magazine_type = /obj/item/ammo_box/magazine/jager/rubbershot

/obj/item/gun/ballistic/automatic/shotgun/katyusha/jager/empty
	spawnwithmagazine = FALSE
