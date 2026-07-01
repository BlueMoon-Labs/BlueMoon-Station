/obj/item/gun/ballistic/rebarxbow
	name = "heated rebar crossbow"
	desc = "A handcrafted crossbow. \
		Aside from conventional sharpened iron rods, it can also fire specialty ammo made from the atmos crystallizer — zaukerite, metallic hydrogen, healium, N2O, hypernoblium, nitrium, and proto nitrate bolts all work. \
		Very slow to reload - you can craft the crossbow with a crowbar to loosen the crossbar, but risk a misfire, or worse..."
	icon = 'modular_bluemoon/icons/obj/guns/ballistic.dmi'
	icon_state = "rebarxbow"
	item_state = "rebarxbow"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_HEAVY
	fire_sound = 'sound/items/xbow_lock.ogg'
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/normal
	magazine_wording = "rod"
	casing_ejector = FALSE
	can_suppress = FALSE
	spread = 0
	pin = null
	no_pin_required = TRUE
	/// Bowstring is loose; must be drawn before firing.
	var/bowstring_loose = TRUE
	var/draw_time = 3 SECONDS

/obj/item/gun/ballistic/rebarxbow/Initialize(mapload)
	. = ..()
	bowstring_loose = TRUE
	chambered = null

/obj/item/gun/ballistic/rebarxbow/attackby(obj/item/A, mob/user, params)
	if(!bowstring_loose)
		to_chat(user, span_notice("The bowstring is drawn! Loosen it before loading a rod."))
		return
	. = ..()
	if(.)
		return
	if(!magazine)
		return
	var/num_loaded = magazine.attackby(A, user, params, TRUE)
	if(num_loaded)
		to_chat(user, span_notice("You load [num_loaded] rod\s into [src]!"))
		playsound(user, 'sound/weapons/shotguninsert.ogg', 60, 1)
		A.update_icon()
		update_icon()

/obj/item/gun/ballistic/rebarxbow/attack_self(mob/living/user)
	rack(user)
	return

/obj/item/gun/ballistic/rebarxbow/proc/rack(mob/user = null)
	if(bowstring_loose)
		draw_bowstring(user)
		return
	bowstring_loose = TRUE
	chambered = null
	if(user)
		balloon_alert(user, "bowstring loosened")
	playsound(src, 'sound/weapons/shotgunpump.ogg', 60, 1)
	update_icon()

/obj/item/gun/ballistic/rebarxbow/proc/draw_bowstring(mob/user = null)
	if(!bowstring_loose)
		return
	if(!user)
		return
	if(!do_after(user, draw_time, target = src))
		return
	if(!bowstring_loose)
		return
	playsound(src, 'sound/weapons/gun_chamber_round.ogg', 60, 1)
	chamber_round()
	if(!chambered?.BB)
		if(user)
			to_chat(user, span_warning("The rod fails to seat in [src]."))
		return
	balloon_alert(user, "bowstring drawn")
	bowstring_loose = FALSE
	update_icon()

/obj/item/gun/ballistic/rebarxbow/shoot_live_shot(mob/living/user, pointblank = FALSE, mob/pbtarget, message = 1, stam_cost = 0)
	..()
	rack(user)

/obj/item/gun/ballistic/rebarxbow/can_shoot()
	if(bowstring_loose || !chambered?.BB)
		return FALSE
	return TRUE

/obj/item/gun/ballistic/rebarxbow/shoot_with_empty_chamber(mob/living/user)
	if(chambered && !chambered.BB)
		chambered = null
	if(chambered?.BB)
		return ..()
	if(!magazine || !magazine.ammo_count())
		return ..()
	if(bowstring_loose)
		draw_bowstring(user)
		return
	chamber_round()
	if(chambered?.BB)
		balloon_alert(user, "bolt seated")
		return
	return ..()

/obj/item/gun/ballistic/rebarxbow/examine(mob/user)
	. = ..()
	. += "The crossbow is [bowstring_loose ? "not ready" : (chambered?.BB ? "ready" : "not ready")] to fire."

/obj/item/gun/ballistic/rebarxbow/update_overlays()
	. = ..()
	if(!magazine || !magazine.ammo_count(0))
		. += "[initial(icon_state)]_empty"
	if(!bowstring_loose)
		. += "[initial(icon_state)]_bolt_locked"

/obj/item/gun/ballistic/rebarxbow/forced
	name = "stressed rebar crossbow"
	desc = "Some idiot decided that they would risk shooting themselves in the face if it meant they could draw this crossbow a bit faster. Hopefully, it was worth it."
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/force
	draw_time = 1.5 SECONDS
	var/can_misfire = TRUE
	var/misfire_probability = 25

/obj/item/gun/ballistic/rebarxbow/forced/do_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(can_misfire && target != user && chambered?.BB && prob(misfire_probability))
		to_chat(user, span_userdanger("[src] misfires!"))
		return ..(user, user, message, params, zone_override, bonus_spread, stam_cost)
	return ..()

/obj/item/gun/ballistic/rebarxbow/forced/examine(mob/user)
	. = ..()
	if(can_misfire && misfire_probability)
		. += span_danger("Given the state of the crossbow, there is a [misfire_probability]% chance it'll misfire.")

/obj/item/gun/ballistic/rebarxbow/syndie
	name = "syndicate rebar crossbow"
	desc = "The syndicate liked the bootleg rebar crossbow NT engineers made, so they showed what it could be if properly developed. \
		Holds three shots without a chance of exploding, and features a built in scope. Compatible with all known crossbow ammunition."
	icon_state = "rebarxbowsyndie"
	item_state = "rebarxbowsyndie"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/internal/boltaction/rebarxbow/syndie
	draw_time = 1 SECONDS // syndicate model: near-instant draw
	zoomable = TRUE
	zoom_amt = 2
