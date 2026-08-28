/obj/item/ammo_casing
	name = "bullet casing"
	desc = "A bullet casing."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "s-casing"
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	var/fire_sound = null						//What sound should play when this ammo is fired
	var/caliber = list()							//Which kind of guns it can be loaded into
	var/projectile_type = null					//The bullet type to create when New() is called
	var/obj/item/projectile/BB = null 			//The loaded bullet
	var/pellets = 1								//Pellets for spreadshot
	var/variance = 0							//Variance for inaccuracy fundamental to the casing
	var/randomspread = 0						//Randomspread for automatics
	var/delay = 0								//Delay for energy weapons
	/// Override this to make the gun check for a different cooldown rather than CLICK_CD_RANGE, which is 4 deciseconds.
	var/click_cooldown_override
	var/firing_effect_type = /obj/effect/temp_visual/dir_setting/firing_effect	//the visual effect appearing when the ammo is fired.
	var/heavy_metal = TRUE
	var/harmful = TRUE //pacifism check for boolet, set to FALSE if bullet is non-lethal
	var/can_be_printed = TRUE
	/// If it can be printed, does this casing require an advanced ammunition datadisk? Mainly for specialized ammo.
	/// Rubbers aren't advanced. Standard ammo (or FMJ if you're particularly pedantic) isn't advanced.
	/// Think more specialized or weird, niche ammo, like armor-piercing, incendiary, hollowpoint, or God forbid, phasic.
	var/advanced_print_req = FALSE

// whatever goblin decided to spread out bullets over like 3 files and god knows however many overrides i wish you a very stubbed toe


/obj/item/ammo_casing/proc/get_br_level()
	var/obj/item/projectile/P = BB
	if(!P)
		return -1

	var/ap = P.armour_penetration

	if(ap >= BULLET_BR6) return 6
	if(ap >= BULLET_BR5) return 5
	if(ap >= BULLET_BR4) return 4
	if(ap >= BULLET_BR3) return 3
	if(ap >= BULLET_BR2) return 2
	if(ap >= BULLET_BR1) return 1
	return 0

/obj/item/ammo_casing/examine(mob/user)
	. = ..()
	//у стреляной гильзы BB уже нет - осмотр такой падал на armour_penetration
	if(!BB)
		. += span_notice("Пробитие: гильза стреляная.")
		return
	. += span_notice("Пробитие: BR[get_br_level()] ([BB.armour_penetration]% AP)")

/obj/item/ammo_casing/spent
	name = "spent bullet casing"
	BB = null

/obj/item/ammo_casing/Initialize(mapload)
	. = ..()
	if(projectile_type)
		BB = new projectile_type(src)
	pixel_x = rand(-10, 10)
	pixel_y = rand(-10, 10)
	setDir(pick(GLOB.alldirs))
	update_icon()

/obj/item/ammo_casing/Destroy()
	// Ejected casings use SpinAnimation(). Stop the native animation before the
	// casing and its pellet-cloud component enter the garbage queue.
	animate(src, alpha = 0, time = 0, flags = ANIMATION_END_NOW)
	if(BB)
		QDEL_NULL(BB)
	return ..()

/obj/item/ammo_casing/update_icon_state()
	icon_state = "[initial(icon_state)][BB ? "-live" : ""]"
	desc = "[initial(desc)][BB ? "" : " This one is spent."]"

//proc to magically refill a casing with a new projectile
/obj/item/ammo_casing/proc/newshot() //For energy weapons, syringe gun, shotgun shells and wands (!).
	if(!BB)
		BB = new projectile_type(src, src)

/obj/item/ammo_casing/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/ammo_box))
		var/obj/item/ammo_box/box = I
		if(isturf(loc))
			var/boolets = 0
			for(var/obj/item/ammo_casing/bullet in loc)
				if (box.stored_ammo.len >= box.max_ammo)
					break
				if (bullet.BB)
					if (box.give_round(bullet, 0))
						boolets++
				else
					continue
			if (boolets > 0)
				box.update_icon()
				to_chat(user, "<span class='notice'>You collect [boolets] shell\s. [box] now contains [box.stored_ammo.len] shell\s.</span>")
			else
				to_chat(user, "<span class='warning'>You fail to collect anything!</span>")
	else
		return ..()

/obj/item/ammo_casing/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(heavy_metal)
		bounce_away(FALSE, NONE)
	. = ..()

/obj/item/ammo_casing/proc/bounce_away(still_warm = FALSE, bounce_delay = 3)
	update_icon()
	SpinAnimation(10, 1)
	var/matrix/M = matrix(transform)
	M.Turn(rand(-170,170))
	transform = M
	pixel_x = rand(-12, 12)
	pixel_y = rand(-12, 12)
	var/turf/T = get_turf(src)
	if(still_warm && T && (T.turf_flags & TURF_BULLET_SIZZLE))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, 'sound/items/welder.ogg', 20, 1), bounce_delay) //If the turf is made of water and the shell casing is still hot, make a sizzling sound when it's ejected.
	else if(T && T.bullet_bounce_sound)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), src, T.bullet_bounce_sound, 60, 1), bounce_delay) //Soft / non-solid turfs that shouldn't make a sound when a shell casing is ejected over them.
