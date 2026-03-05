//Jay Sparrow
#define MOVESPEED_ID_LEASH      "LEASH"

// is not being used here anymore
/datum/movespeed_modifier/leash
	id = MOVESPEED_ID_LEASH
	multiplicative_slowdown = 1

/datum/status_effect/leash_pet
	id = "leashed"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

///// OBJECT /////
//The leash object itself
//The component variables are used for hooks, used later.

/obj/item/leash
	name = "leash"
	desc = "A simple tether that can easily be hooked onto a collar. Perfect for your pet."
	icon = 'modular_splurt/icons/obj/leash.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/leash/leash_righthand.dmi'
	lefthand_file = 'modular_bluemoon/icons/obj/leash/leash_lefthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/leash/leash_mob_overlay.dmi'
	icon_state = "leash"
	item_state = "leash"
	throw_range = 4
	slot_flags = ITEM_SLOT_BELT
	force = 1
	throwforce = 1
	w_class = WEIGHT_CLASS_SMALL
	var/mob/living/carbon/leash_pet = null
	var/mob/living/carbon/leash_master = null
	var/datum/beam/leash_beam = null

/obj/item/leash/examine(mob/user)
	. = ..()
	. += span_notice("You can clip it on your belt.")
	if(istype(leash_pet))
		. += span_notice("Activate in hand to tug the pet closer to you.")

/obj/item/leash/Destroy()
	sever_leash()
	. = ..()

/obj/item/leash/process(delta_time)
	if(QDELETED(leash_pet) || !istype(leash_pet)) // carbons only
		sever_leash()
		return PROCESS_KILL
	if(!(leash_pet.get_item_by_slot(ITEM_SLOT_NECK))) //The pet has slipped their collar and is not the pet anymore.
		leash_pet.visible_message(
			span_warning("[leash_pet] has slipped out of their collar!"),
			span_warning("You have slipped out of your collar!"),
			target = leash_master,
			target_message = span_warning("[leash_pet] has slipped out of their collar!")
		)
		sever_leash()
		return PROCESS_KILL
	// if(!QDELETED(leash_master)) // is being processed through signals
	// 	var/turf/m_t = get_turf(leash_master)
	// 	var/turf/p_t = get_turf(leash_pet)
	// 	if(m_t.z != p_t.z)
	// 		if(!leash_pet.forceMove(m_t))
	// 			leash_pet.visible_message(
	// 				span_warning("[leash_pet] has severed the leash!"),
	// 				span_warning("You have severed the leash!"),
	// 				target = leash_master,
	// 				target_message = span_warning("[leash_pet] has severed the leash!")
	// 			)
	// 			sever_leash()
	// 			return PROCESS_KILL
	// 		return
	if(leash_pet.z != loc.z)
		leash_pet.visible_message(
			span_warning("[leash_pet] has severed the leash!"),
			span_warning("You have severed the leash!"),
			target = leash_master,
			target_message = span_warning("[leash_pet] has severed the leash!")
		)
		sever_leash()
		return PROCESS_KILL
	if(leash_beam?.finished)
		if(!QDELETED(leash_master))
			leash_beam = leash_master.Beam(leash_pet, icon_state="leash", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
		else if(loc != leash_pet)
			leash_beam = Beam(leash_pet, icon_state="leash", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)

/obj/item/leash/proc/sever_leash()
	STOP_PROCESSING(SSfastprocess, src)
	if(leash_pet)
		UnregisterSignal(leash_pet, COMSIG_MOVABLE_MOVED)
		if(!QDELETED(leash_pet))
			leash_pet.remove_status_effect(/datum/status_effect/leash_pet)
	if(leash_master)
		UnregisterSignal(leash_master, COMSIG_MOVABLE_MOVED)
	QDEL_NULL(leash_beam)
	leash_pet = null
	leash_master = null
	w_class = initial(w_class)

/obj/item/leash/proc/check_leash_mobs()
	if(QDELETED(leash_pet) || QDELETED(leash_master))
		return FALSE
	if(istype(leash_pet) && istype(leash_master))
		return TRUE
	else
		return FALSE

//Called when someone is clicked with the leash
/obj/item/leash/attack(mob/living/carbon/target, mob/living/carbon/user, attackchain_flags, damage_multiplier)
	if(!istype(target) || !istype(user))
		return
	if(target == leash_pet)	//we set our pet free.
		target.visible_message(
			span_warning("The leash on [target]'s collar is gone."),
			span_warning("Master frees you from the leash."),
			target = leash_master,
			target_message = span_warning("You free your pet.")
		)
		sever_leash()
		return
	else if(istype(leash_pet))	//we can't have 2 pets on the same leash.
		to_chat(user, "You already have a pet on that leath.")
		return
	if(target.has_status_effect(/datum/status_effect/leash_pet)) //If the pet is already leashed, do not leash them. For the love of god.
		to_chat(user, span_notice("[target] has already been leashed."))
		return
	if(!is_type_in_list(target.get_item_by_slot(ITEM_SLOT_NECK), list(/obj/item/clothing/neck/petcollar, /obj/item/electropack/shockcollar, /obj/item/clothing/neck/necklace/cowbell, /obj/item/clothing/neck/maid)))
		var/leash_message = pick("[target] needs a collar before you can attach a leash to it.")
		to_chat(user, span_notice("[leash_message]"))
		return
	var/leashtime = target.handcuffed ? 1 SECONDS : 5 SECONDS
	if(do_mob(user, target, leashtime))
		w_class = WEIGHT_CLASS_HUGE
		log_combat(user, target, "leashed", addition="playfully")
		target.apply_status_effect(/datum/status_effect/leash_pet)//Has now been leashed
		leash_pet = target
		if(target != user)
			leash_master = user
			RegisterSignal(leash_master, COMSIG_MOVABLE_MOVED, PROC_REF(on_master_move))
			leash_beam = user.Beam(leash_pet, icon_state="leash", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
		leash_pet.visible_message(
			span_warning("[leash_pet] has been leashed by [leash_master ? leash_master : "[leash_pet.p_them()]self"]."),
			span_userdanger("You have hooked a leash onto [leash_master ? leash_pet : "yourself"]!"),
		)
		RegisterSignal(leash_pet, COMSIG_MOVABLE_MOVED, PROC_REF(on_pet_move))
		START_PROCESSING(SSfastprocess, src)

//Called when the leash is used in hand
//Tugs the pet closer
/obj/item/leash/attack_self(mob/living/user)
	if(QDELETED(leash_pet) || user == leash_pet) //No pet, no tug.
		return
	//Yank the pet. Yank em in close.
	apply_tug_mob_to_mob(leash_pet, leash_master, 1)
	leash_pet.adjustOxyLoss(2)

/obj/item/leash/proc/on_master_move()
	SIGNAL_HANDLER
	if(leash_pet == leash_master) //Pet is the master
		return
	if(check_leash_mobs())
		if(leash_master.z != leash_pet.z)
			if(!leash_pet.forceMove(leash_master.loc))
				leash_pet.visible_message(
					span_warning("[leash_pet] has severed the leash!"),
					span_warning("You have severed the leash!"),
					target = leash_master,
					target_message = span_warning("[leash_pet] has severed the leash!")
				)
				sever_leash()
			return
	addtimer(CALLBACK(src, PROC_REF(after_master_move)), 0.2 SECONDS)

/obj/item/leash/proc/after_master_move()
	//If the master moves, pull the pet in behind
	//Also, the timer means that the distance check for master happens before the pet, to prevent both from proccing.
	if(!check_leash_mobs())
		return
	apply_tug_mob_to_mob(leash_pet, leash_master, 2)
	//Knock the pet over if they get further behind. Shouldn't happen too often.
	stoplag(3) //This way running normally won't just yank the pet to the ground.
	if(!check_leash_mobs())
		return
	if(get_dist(leash_pet, leash_master) > 3)
		leash_pet.adjustOxyLoss(3)
		leash_pet.apply_effect(20, EFFECT_KNOCKDOWN, 0)
		if(get_dist(leash_pet, leash_master) > 5)
			leash_pet.visible_message(
				span_warning("The leash snaps free from [leash_pet]'s collar!"),
				span_warning("Your leash pops from your collar!"),
				target = leash_master,
				target_message = span_warning("The leash snaps free from your pet's collar!")
			)
			leash_pet.apply_effect(20, EFFECT_KNOCKDOWN, 0)
			leash_pet.adjustOxyLoss(6)
			sever_leash()
		else
			leash_pet.visible_message(
				span_warning("[leash_pet] is pulled to the ground by their leash!"),
				span_warning("You are pulled to the ground by your leash!"),
				target = leash_master,
				target_message = span_warning("Your pet can't keep up with you! Slow down a bit.")
			)

/obj/item/leash/proc/on_pet_move(mob/living/carbon/pet, atom/oldloc, dir, forced)
	SIGNAL_HANDLER
	if(!QDELETED(leash_master) && leash_master != pet)
		var/turf/m_t = get_turf(leash_master)
		var/turf/p_t = get_turf(leash_pet)
		if(m_t.z != p_t.z)  //we can't check beforehead with COMSIG_MOVABLE_PRE_MOVE because it doesn't work with multiz stairs and etc.
			if(leash_pet.forceMove(oldloc))
				to_chat(pet, span_warning("You can't leave this sector without your master."))
			else
				leash_pet.visible_message(
					span_warning("[leash_pet] has severed the leash!"),
					span_warning("You have severed the leash!"),
					target = leash_master,
					target_message = span_warning("[leash_pet] has severed the leash!")
				)
				sever_leash()
			return
	addtimer(CALLBACK(src, PROC_REF(after_pet_move)), 0.3 SECONDS) //A short timer so the pet kind of bounces back after they make the step

/obj/item/leash/proc/after_pet_move()
	if(QDELETED(leash_pet))
		return
	if(!QDELETED(leash_master))
		for(var/i in 3 to get_dist(leash_pet, leash_master)) // Move the pet to a minimum of 2 tiles away from the master, so the pet trails behind them.
			step_towards(leash_pet, leash_master)
	else if(!ismob(loc))
		if(leash_pet.loc.z != loc.z)
			forceMove(leash_pet.loc)
			return
		for(var/i in 3 to get_dist(src, leash_pet)) // Move us to a minimum of 2 tiles away from the pet, so we trail behind them.
			step_towards(src, leash_pet)
		if(get_dist(src, leash_pet) > 5)
			leash_pet.visible_message(span_warning("\The [src] snaps free from \the [leash_pet]!"), span_warning("Your leash pops free from your collar!"))
			leash_pet.apply_effect(20, EFFECT_KNOCKDOWN, 0)
			leash_pet.adjustOxyLoss(6)
			sever_leash()

/obj/item/leash/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!QDELETED(leash_pet) && !ismob(OldLoc) && !ismob(loc) && get_dist(src, leash_pet)>3)
		after_pet_move()

/obj/item/leash/equipped(mob/user)
	. = ..()
	if(QDELETED(leash_pet))
		return
	if(leash_master == user)
		return // Don't double-register.
	if(leash_pet == user) //Pet picked up their own leash.
		if(!QDELETED(leash_beam))
			QDEL_NULL(leash_beam)
		return
	leash_master = user
	RegisterSignal(leash_master, COMSIG_MOVABLE_MOVED, PROC_REF(on_master_move))
	QDEL_NULL(leash_beam)
	leash_beam = leash_master.Beam(leash_pet, icon_state="leash", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)

/obj/item/leash/dropped(mob/user, silent)
	. = ..()
	if(QDELETED(leash_pet))
		return
	if(!QDELETED(leash_master))
		if(leash_master.is_holding(src) || leash_master.get_item_by_slot(ITEM_SLOT_BELT) == src)
			return
		//DOM HAS DROPPED LEASH. PET IS FREE. SCP HAS BREACHED CONTAINMENT.
		UnregisterSignal(leash_master, COMSIG_MOVABLE_MOVED)
		leash_master = null
		QDEL_NULL(leash_beam)
	if(!ismob(loc))
		leash_beam = Beam(leash_pet, icon_state="leash", icon = "modular_bluemoon/icons/effects/beam.dmi", time = INFINITY, maxdistance = INFINITY, beam_sleep_time = 1)
