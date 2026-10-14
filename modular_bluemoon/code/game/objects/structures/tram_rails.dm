/obj/structure/fluff/tram_rail
	name = "tram rail"
	desc = "Отлично подходит трамваю и совсем не годится для скейта."
	icon = 'icons/obj/hellgate/tram_rails.dmi'
	icon_state = "rail"
	layer = TRAM_RAIL_LAYER
	plane = FLOOR_PLANE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	deconstructible = FALSE
	can_buckle = TRUE
	buckle_requires_restraints = TRUE
	buckle_lying = 90

/// The tram subfloor is mostly holes, so clicks on a tram floor often land on the rail below it
/obj/structure/fluff/tram_rail/attackby(obj/item/attacking_item, mob/user, params)
	var/turf/open/rail_turf = loc
	if(!istype(rail_turf))
		return ..()
	if(istype(attacking_item, /obj/item/stack/thermoplastic))
		rail_turf.build_with_transport_tiles(attacking_item, user)
		return STOP_ATTACK_PROC_CHAIN
	if(istype(attacking_item, /obj/item/stack/sheet/mineral/titanium))
		rail_turf.build_with_titanium(attacking_item, user)
		return STOP_ATTACK_PROC_CHAIN
	return ..()

/obj/structure/fluff/tram_rail/post_buckle_mob(mob/living/target)
	. = ..()
	target.pixel_y += dir == SOUTH ? -3 : 14
	RegisterSignal(target, COMSIG_LIVING_HIT_BY_TRAM, PROC_REF(on_buckled_tram_smashed))

/obj/structure/fluff/tram_rail/post_unbuckle_mob(mob/living/target)
	. = ..()
	target.pixel_y -= dir == SOUTH ? -3 : 14
	UnregisterSignal(target, COMSIG_LIVING_HIT_BY_TRAM)

/// If someone gets hit by the tram while buckled to us (mission accomplished) unbuckle them so that they can fly away
/obj/structure/fluff/tram_rail/proc/on_buckled_tram_smashed(mob/living/smashed)
	SIGNAL_HANDLER
	unbuckle_mob(smashed, force = TRUE)

/obj/structure/fluff/tram_rail/floor
	name = "tram rail protective cover"
	icon_state = "rail_floor"

/obj/structure/fluff/tram_rail/end
	icon_state = "railend"

/obj/structure/fluff/tram_rail/anchor
	name = "tram rail anchor"
	icon_state = "anchor"

/obj/structure/fluff/tram_rail/electric
	desc = "Отлично подходит трамваю и совсем не годится для скейта. Этот рельс - контактный, под напряжением."
	/// What power channel from the APC do we check for power?
	var/power_channel = ENVIRON
	/// Timer of the next shock to whoever is buckled to us
	var/shock_timer

/obj/structure/fluff/tram_rail/electric/anchor
	name = "tram rail anchor"
	icon_state = "anchor"

/obj/structure/fluff/tram_rail/electric/Destroy()
	deltimer(shock_timer)
	return ..()

/obj/structure/fluff/tram_rail/electric/proc/is_powered()
	var/area/our_area = get_area(src)
	return our_area?.powered(power_channel)

/obj/structure/fluff/tram_rail/electric/post_buckle_mob(mob/living/target)
	. = ..()
	shock_buckled()

/obj/structure/fluff/tram_rail/electric/proc/shock_buckled()
	shock_timer = null
	if(!has_buckled_mobs())
		return
	if(is_powered())
		for(var/mob/living/buckled_mob as anything in buckled_mobs)
			buckled_mob.electrocute_act(5, src, 1, SHOCK_NOSTUN)
	shock_timer = addtimer(CALLBACK(src, PROC_REF(shock_buckled)), 8 SECONDS, TIMER_STOPPABLE | TIMER_UNIQUE)

/obj/structure/fluff/tram_rail/electric/on_attack_hand(mob/living/user, act_intent = user?.a_intent, unarmed_attack_flags)
	. = ..()
	if(!isliving(user) || !is_powered())
		return
	if(user.electrocute_act(75, src))
		do_sparks(5, TRUE, src)
