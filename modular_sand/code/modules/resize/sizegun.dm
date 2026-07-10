/obj/item/projectile/sizelaser
	name = "sizeray laser"
	icon_state = "omnilaser"
	hitsound = null
	damage = 5
	damage_type = STAMINA
	flag = "laser"
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE

/obj/item/projectile/sizelaser/shrinkray
	icon_state = "bluelaser"

/obj/item/projectile/sizelaser/growthray
	icon_state = "laser"

/obj/item/projectile/sizelaser/shrinkray/on_hit(atom/target, blocked = 0)
	if(isliving(target))
		var/mob/living/living = target
		var/new_size = RESIZE_NORMAL
		var/size = get_size(target)
		if(size >= RESIZE_MACRO)
			new_size = RESIZE_HUGE
		else if(size >= RESIZE_HUGE)
			new_size = RESIZE_BIG
		else if(size >= RESIZE_BIG)
			new_size = RESIZE_NORMAL
		else if(size >= RESIZE_NORMAL)
			new_size = RESIZE_SMALL
		else if(size >= RESIZE_SMALL)
			new_size = RESIZE_TINY
		else
			new_size = RESIZE_MICRO
		living.update_size(new_size)
	return TRUE

/obj/item/projectile/sizelaser/growthray/on_hit(atom/target, blocked = 0 )
	if(isliving(target))
		var/mob/living/living = target
		var/new_size = RESIZE_NORMAL
		var/size = get_size(target)
		if(size >= RESIZE_HUGE)
			new_size = RESIZE_MACRO
		else if(size >= RESIZE_BIG)
			new_size = RESIZE_HUGE
		else if(size >= RESIZE_NORMAL)
			new_size = RESIZE_BIG
		else if(size >= RESIZE_SMALL)
			new_size = RESIZE_NORMAL
		else if(size >= RESIZE_TINY)
			new_size = RESIZE_SMALL
		else if(size >= RESIZE_MICRO)
			new_size = RESIZE_TINY
		else
			new_size = RESIZE_MICRO

		living.update_size(new_size)
	return TRUE

/obj/item/ammo_casing/energy/laser/growthray
	projectile_type = /obj/item/projectile/sizelaser/growthray
	select_name = "Growth"

/obj/item/ammo_casing/energy/laser/shrinkray
	projectile_type = /obj/item/projectile/sizelaser/shrinkray
	select_name = "Shrink"

//Gun
/obj/item/gun/energy/laser/sizeray
	name = "size ray"
	icon_state = "bluetag"
	desc = "Debug size manipulator. You probably shouldn't have this!"
	item_state = null
	ammo_type = list(/obj/item/ammo_casing/energy/laser/shrinkray, /obj/item/ammo_casing/energy/laser/growthray)
	selfcharge = EGUN_SELFCHARGE
	charge_delay = 5
	ammo_x_offset = 2
	clumsy_check = 1
	custom_premium_price = 4500

/obj/item/gun/energy/laser/sizeray/update_overlays()
	. = ..()
	var/current_index = current_firemode_index
	if(current_index == 1)
		icon_state = "redtag"
	else
		icon_state = "bluetag"
