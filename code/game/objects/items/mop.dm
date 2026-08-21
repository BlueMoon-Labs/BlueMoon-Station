#define MOP_AFTER_LIQUID_CONTINUE 1
#define MOP_AFTER_LIQUID_CONTINUE_ANIMATE 2
#define MOP_AFTER_LIQUID_STOP 3
#define MOP_AFTER_LIQUID_STOP_ANIMATE 4

/obj/item/mop
	desc = "The world of janitalia wouldn't be complete without a mop."
	name = "mop"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 3
	throwforce = 5
	throw_speed = 3
	throw_range = 7
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb = list("mopped", "bashed", "bludgeoned", "whacked")
	resistance_flags = FLAMMABLE
	var/mopping = 0
	var/mopcount = 0
	var/mopcap = 5
	var/stamusage = 2
	force_string = "robust... against germs"
	var/insertable = TRUE

/obj/item/mop/Initialize(mapload)
	. = ..()
	create_reagents(mopcap, NONE, NO_REAGENTS_VALUE)
	GLOB.janitor_devices += src
	RegisterSignal(src, COMSIG_TWOHANDED_WIELD, PROC_REF(on_wield))
	RegisterSignal(src, COMSIG_TWOHANDED_UNWIELD, PROC_REF(on_unwield))

/obj/item/mop/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/two_handed, force_unwielded=3, force_wielded=6)

/obj/item/mop/Destroy(force)
	GLOB.janitor_devices -= src
	return ..()

/obj/item/mop/examine(mob/user)
	. = ..()
	. += span_notice("Можно взяться двумя руками, чтобы мыть пол на ходу.")

/obj/item/mop/proc/on_wield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.add_movespeed_modifier(/datum/movespeed_modifier/mop_broom_slowdown)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(do_mop))

/obj/item/mop/proc/on_unwield(obj/item/source, mob/user)
	SIGNAL_HANDLER
	user.remove_movespeed_modifier(/datum/movespeed_modifier/mop_broom_slowdown)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)

/obj/item/mop/proc/do_mop(mob/user, OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	user.face_atom(OldLoc)
	var/turf/T = get_turf(OldLoc)
	if(user.CanReach(T) && isfloorturf(T))
		afterattack(T, user, TRUE)

/obj/item/mop/proc/clean(turf/A, mob/user)
	if(reagents.has_reagent(/datum/reagent/water, 1) || reagents.has_reagent(/datum/reagent/water/holywater, 1) || reagents.has_reagent(/datum/reagent/consumable/ethanol/vodka, 1) || reagents.has_reagent(/datum/reagent/space_cleaner, 1))
		SEND_SIGNAL(A, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_MEDIUM)
		A.clean_blood()
		var/cleaned_something = FALSE
		for(var/obj/effect/O in A)
			if(is_cleanable(O))
				cleaned_something = TRUE
				qdel(O)
		if(cleaned_something && user && user.client)
			user.client.increment_progress("janitor", 1)
	reagents.reaction(A, TOUCH, 10)	//Needed for proper floor wetting.
	reagents.remove_any(1)			//reaction() doesn't use up the reagents

/obj/item/mop/afterattack(atom/A, mob/user, proximity, click_parameters)
	. = ..()
	if(!proximity)
		return

	var/mob/living/L = user

	if(istype(L) && IS_STAMCRIT(L))
		to_chat(user, span_danger("You're too exhausted for that."))
		return

	if(istype(A, /obj/item/reagent_containers/glass/bucket) || istype(A, /obj/structure/janitorialcart) || istype(A, /obj/structure/sink))
		return

	if(istype(A, /obj/item/reagent_containers)) // BLUEMOON ADD: wring the mop out into any container with Ctrl+click or harm intent
		var/list/modifiers = params2list(click_parameters)
		if(A.is_refillable() && (modifiers["ctrl"] || user.a_intent == INTENT_HARM))
			if(A.reagents.total_volume >= A.reagents.maximum_volume)
				to_chat(user, span_warning("[A] is full!"))
				return
			reagents.remove_all(reagents.total_volume * SQUEEZING_DISPERSAL_RATIO)
			reagents.trans_to(A, reagents.total_volume)
			to_chat(user, span_notice("You squeeze [src] out into [A]."))
			playsound(A, 'sound/effects/slosh.ogg', 25, 1)
			return

	var/turf/T = get_turf(A)
	if(T)
		if(!L.UseStaminaBuffer(stamusage, warn = TRUE))
			return
		var/try_clean = TRUE
		var/need_animate = FALSE
		if(T.liquids)
			var/liquid_result = attack_liquids_turf(A, user, T.liquids)
			try_clean = liquid_result == MOP_AFTER_LIQUID_CONTINUE || liquid_result == MOP_AFTER_LIQUID_CONTINUE_ANIMATE
			need_animate = liquid_result == MOP_AFTER_LIQUID_CONTINUE_ANIMATE || liquid_result == MOP_AFTER_LIQUID_STOP_ANIMATE

		if(try_clean)
			if(reagents.total_volume >= 1)
				user.visible_message("[user] cleans \the [T] with [src].", span_notice("You clean \the [T] with [src]."))
				clean(T, user)
				need_animate = TRUE
			else if(!need_animate)
				to_chat(user, span_warning("Your mop is dry!"))
		if(need_animate)
			user.DelayNextAction(CLICK_CD_MELEE)
			user.do_attack_animation(T, used_item = src)
			playsound(T, "slosh", 50, 1)

/obj/effect/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/mop) || istype(I, /obj/item/soap))
		return
	else
		return ..()

/obj/item/mop/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	if(insertable)
		J.put_in_cart(src, user)
		J.mymop=src
		J.update_icon()
	else
		to_chat(user, span_warning("You are unable to fit your [name] into the [J.name]."))
		return

// Remove liquids from a turf using a mop.
/obj/item/mop/attack_liquids_turf(turf/target_turf, mob/living/user, obj/effect/abstract/liquid_turf/liquids)
	if(liquids.fire_state)
		return MOP_AFTER_LIQUID_STOP

	var/free_space = reagents.maximum_volume - reagents.total_volume
	if(free_space <= 0)
		to_chat(user, span_warning("Your [src] can't absorb any more liquid!"))
		return MOP_AFTER_LIQUID_CONTINUE

	var/datum/reagents/tempr = liquids.take_reagents_flat(free_space)
	tempr.trans_to(reagents, tempr.total_volume)
	to_chat(user, span_notice("You soak \the [src] with some liquids."))
	qdel(tempr)
	return MOP_AFTER_LIQUID_STOP_ANIMATE

/obj/item/mop/cyborg
	insertable = FALSE

/obj/item/mop/advanced
	desc = "The most advanced tool in a custodian's arsenal, complete with a condenser for self-wetting! Just think of all the viscera you will clean up with this!"
	name = "advanced mop"
	mopcap = 10
	icon_state = "advmop"
	item_state = "advmop"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	force = 6
	throwforce = 8
	throw_range = 4
	stamusage = 1
	var/refill_enabled = TRUE //Self-refill toggle for when a janitor decides to mop with something other than water.
	var/refill_rate = 1 //Rate per process() tick mop refills itself
	var/refill_reagent = /datum/reagent/water //Determins what reagent to use for refilling, just in case someone wanted to make a HOLY MOP OF PURGING

// Advanced mop has a self-refilling condenser, so it has no room to soak up
// liquids into its reagents. Instead it straight up removes the whole puddle.
/obj/item/mop/advanced/attack_liquids_turf(turf/target_turf, mob/living/user, obj/effect/abstract/liquid_turf/liquids)
	. = MOP_AFTER_LIQUID_CONTINUE_ANIMATE
	if(liquids.fire_state)
		return MOP_AFTER_LIQUID_STOP

	liquids.liquid_simple_delete_flat(liquids.total_reagents)

/obj/item/mop/advanced/supermatter
	name = "Supermatter Mop"
	icon_state = "adv_smmop"
	item_state = "smmop"
	force = 128

/obj/item/mop/advanced/Initialize(mapload)
	. = ..()
	// Processing must not start before Initialize: the parent creates reagents
	// here, and a map-loaded mop otherwise gets process() calls with null
	// reagents for the whole deferred-init window of the map load.
	if(refill_enabled)
		START_PROCESSING(SSobj, src)

/obj/item/mop/advanced/AltClick(mob/user)
	refill_enabled = !refill_enabled
	if(refill_enabled)
		START_PROCESSING(SSobj, src)
	else
		STOP_PROCESSING(SSobj,src)
	to_chat(user, span_notice("You set the condenser switch to the '[refill_enabled ? "ON" : "OFF"]' position."))
	playsound(user, 'sound/machines/click.ogg', 30, 1)

/obj/item/mop/advanced/process()
	if(reagents.total_volume < mopcap)
		reagents.add_reagent(refill_reagent, refill_rate)

/obj/item/mop/advanced/examine(mob/user)
	. = ..()
	. += span_notice("The condenser switch is set to <b>[refill_enabled ? "ON" : "OFF"]</b>. Alt-Click to toggle.")

/obj/item/mop/advanced/Destroy()
	// Unconditional: refill_enabled can change over the item's lifetime
	// (AltClick, VV), and STOP_PROCESSING on a non-processing item is a no-op.
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/mop/advanced/cyborg
	insertable = FALSE

#undef MOP_AFTER_LIQUID_CONTINUE
#undef MOP_AFTER_LIQUID_CONTINUE_ANIMATE
#undef MOP_AFTER_LIQUID_STOP
#undef MOP_AFTER_LIQUID_STOP_ANIMATE
