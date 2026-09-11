/obj/item/ammo_box/magazine/internal/cylinder
	name = "revolver cylinder"
	ammo_type = /obj/item/ammo_casing/a357
	caliber = list("357","38")
	max_ammo = 7

/obj/item/ammo_box/magazine/internal/cylinder/jackal
	name = "Jackal revolver cylinder"
	ammo_type = /obj/item/ammo_casing/a357/jackal
	caliber = list("357")
	max_ammo = 7
	var/enhanced = FALSE

/obj/item/ammo_box/magazine/internal/cylinder/jackal/Initialize(mapload)
	. = ..()
	enhanced = FALSE

/obj/item/ammo_box/magazine/internal/cylinder/jackal/proc/upgrade()
	enhanced = TRUE
	ammo_type = /obj/item/ammo_casing/a357/jackal/enhanced
	// Upgrade existing ammo
	for(var/obj/item/ammo_casing/casing in stored_ammo)
		if(istype(casing, /obj/item/ammo_casing/a357/jackal))
			if(!casing.BB)
				continue
			qdel(casing.BB)
			casing.BB = new /obj/item/projectile/bullet/a357/jackal/enhanced(casing)
			casing.projectile_type = /obj/item/projectile/bullet/a357/jackal/enhanced
			casing.update_icon()

/obj/item/ammo_box/magazine/internal/cylinder/jackal/give_round(obj/item/ammo_casing/R, replace_spent = 0)
	// Accept jackal casings only — regular and blood-mask enhanced subtypes
	if(!R || !istype(R, /obj/item/ammo_casing/a357/jackal))
		return FALSE
	if(caliber && !(R.caliber in caliber))
		return FALSE

	// If we're enhanced, upgrade regular jackal ammo when loaded
	if(enhanced && istype(R, /obj/item/ammo_casing/a357/jackal) && !istype(R, /obj/item/ammo_casing/a357/jackal/enhanced))
		if(R.BB)
			qdel(R.BB)
		R.BB = new /obj/item/projectile/bullet/a357/jackal/enhanced(R)
		R.projectile_type = /obj/item/projectile/bullet/a357/jackal/enhanced
		R.update_icon()

	// Ensure stored_ammo has enough slots (pad with nulls up to max_ammo)
	while(stored_ammo.len < max_ammo)
		stored_ammo += null

	for(var/i in 1 to stored_ammo.len)
		var/obj/item/ammo_casing/bullet = stored_ammo[i]
		if(!bullet || !bullet.BB || replace_spent) // found a spent or empty slot (or forced replace)
			stored_ammo[i] = R
			R.forceMove(src)

			if(bullet)
				bullet.forceMove(drop_location())
			return TRUE

	return FALSE

/obj/item/ammo_box/magazine/internal/cylinder/jackal/ammo_box_reload(obj/item/ammo_box/A, mob/user, params, silent = FALSE, replace_spent = 0)
	var/num_loaded = 0
	if(!can_load(user))
		return
	if(istype(A, /obj/item/ammo_box/a357/jackal))
		// Speedloader for Jackal: replace ALL rounds in one go
		// Take a SNAPSHOT of the speedloader's ammo first (before mutating lists)
		var/list/speedloader_snapshot = A.stored_ammo.Copy()
		var/list/old_ammo = stored_ammo.Copy()
		stored_ammo.Cut()
		// Ensure we have enough slots
		while(stored_ammo.len < max_ammo)
			stored_ammo += null

		var/slot_idx = 1
		for(var/obj/item/ammo_casing/AC as anything in speedloader_snapshot)
			if(!AC || slot_idx > max_ammo)
				continue
			if(!istype(AC, /obj/item/ammo_casing/a357/jackal))
				continue
			// Upgrade if needed
			if(enhanced && istype(AC, /obj/item/ammo_casing/a357/jackal) && !istype(AC, /obj/item/ammo_casing/a357/jackal/enhanced))
				if(AC.BB)
					qdel(AC.BB)
				AC.BB = new /obj/item/projectile/bullet/a357/jackal/enhanced(AC)
				AC.projectile_type = /obj/item/projectile/bullet/a357/jackal/enhanced
				AC.update_icon()
			stored_ammo[slot_idx] = AC
			AC.forceMove(src)
			num_loaded++
			slot_idx++

		// Clear the speedloader (all live ammo moved to cylinder)
		for(var/obj/item/ammo_casing/loaded as anything in speedloader_snapshot)
			if(loaded && !QDELETED(loaded) && (loaded in A.stored_ammo))
				A.stored_ammo -= loaded

		// Drop old unspent casings
		for(var/obj/item/ammo_casing/old_casing as anything in old_ammo)
			if(!old_casing || QDELETED(old_casing))
				continue
			if(old_casing.BB)
				old_casing.forceMove(drop_location())
			else
				old_casing.forceMove(drop_location()) // отстрелянные гильзы тоже обязаны покинуть цилиндр
	else
		// Fallback for non-jackal boxes: load one by one
		. = ..(A, user, params, silent, replace_spent)
		return

	if(num_loaded)
		A.update_icon()
		update_icon()

	return num_loaded


/obj/item/ammo_box/magazine/internal/cylinder/proc/ammo_box_reload(obj/item/ammo_box/A, mob/user, params, silent = FALSE, replace_spent = 0)
	var/num_loaded = 0
	if(!can_load(user))
		return
	if(A.stored_ammo.len > 0)
		var/obj/item/ammo_casing/AC = A.stored_ammo[1]
		var/did_load = give_round(AC, replace_spent)
		if(did_load)
			A.stored_ammo -= AC
			num_loaded++

	if(num_loaded)
		A.update_icon()
		update_icon()

	return num_loaded

/obj/item/ammo_box/magazine/internal/cylinder/ammo_count(countempties = 1)
	var/boolets = 0
	for(var/obj/item/ammo_casing/bullet in stored_ammo)
		if(bullet && (bullet.BB || countempties))
			boolets++

	return boolets

/obj/item/ammo_box/magazine/internal/cylinder/get_round(keep = 0)
	rotate()

	var/b = stored_ammo[1]
	if(!keep)
		stored_ammo[1] = null

	return b

/obj/item/ammo_box/magazine/internal/cylinder/proc/rotate()
	var/b = stored_ammo[1]
	stored_ammo.Cut(1,2)
	stored_ammo.Insert(0, b)

/obj/item/ammo_box/magazine/internal/cylinder/proc/spin()
	for(var/i in 1 to rand(0, max_ammo*2))
		rotate()

/obj/item/ammo_box/magazine/internal/cylinder/give_round(obj/item/ammo_casing/R, replace_spent = 0)
	if(!R || (caliber && !(R.caliber in caliber)) || (!caliber && R.type != ammo_type))
		return FALSE

	for(var/i in 1 to stored_ammo.len)
		var/obj/item/ammo_casing/bullet = stored_ammo[i]
		if(!bullet || !bullet.BB) // found a spent ammo
			stored_ammo[i] = R
			R.forceMove(src)

			if(bullet)
				bullet.forceMove(drop_location())
			return TRUE

	return FALSE
