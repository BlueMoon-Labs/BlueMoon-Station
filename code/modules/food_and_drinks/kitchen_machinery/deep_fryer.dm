/*
April 3rd, 2014 marks the day this machine changed the face of the kitchen on NTStation13
God bless America.
          ___----------___
        _--                ----__
       -                         ---_
      -___    ____---_              --_
  __---_ .-_--   _ O _-                -
 -      -_-       ---                   -
-   __---------___                       -
- _----                                  -
 -     -_                                 _
 `      _-                                 _
       _                           _-_  _-_ _
      _-                   ____    -_  -   --
      -   _-__   _    __---    -------       -
     _- _-   -_-- -_--                        _
     -_-                                       _
    _-                                          _
    -
*/

/obj/machinery/deepfryer
	name = "deep fryer"
	desc = "Deep fried <i>everything</i>."
	icon = 'icons/obj/machines/kitchen.dmi'
	icon_state = "fryer_off"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 5
	layer = BELOW_OBJ_LAYER
	var/obj/item/frying	//What's being fried RIGHT NOW?
	var/cook_time = 0
	var/oil_use = 0.05 //How much cooking oil is used per tick
	var/fry_speed = 1 //How quickly we fry food
	var/frying_fried //If the object has been fried; used for messages
	var/frying_burnt //If the object has been burnt
	var/grease_level = 0
	/// The chance (%) of grease_level increase on process()
	var/grease_increase_chance = 50
	/// The amount of grease_level increase on process()
	var/grease_increase_amount = 0.1
	var/static/list/deepfry_blacklisted_items = typecacheof(list(
		/obj/item/screwdriver,
		/obj/item/crowbar,
		/obj/item/wrench,
		/obj/item/wirecutters,
		/obj/item/multitool,
		/obj/item/weldingtool,
		/obj/item/reagent_containers/glass,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/food/condiment,
		/obj/item/storage/part_replacer,
		/obj/item/his_grace))
	var/datum/looping_sound/deep_fryer/fry_loop

/obj/machinery/deepfryer/Initialize(mapload)
	. = ..()
	create_reagents(50, OPENCONTAINER)
	reagents.add_reagent(/datum/reagent/consumable/cooking_oil, 25)
	component_parts = list()
	component_parts += new /obj/item/circuitboard/machine/deep_fryer(null)
	component_parts += new /obj/item/stock_parts/micro_laser(null)
	RefreshParts()
	fry_loop = new(src, FALSE)
	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_cleaned))

/obj/machinery/deepfryer/Destroy()
	QDEL_NULL(fry_loop)
	UnregisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT)
	return ..()

/obj/machinery/deepfryer/RefreshParts()
	var/oil_efficiency
	for(var/obj/item/stock_parts/micro_laser/M in component_parts)
		oil_efficiency += M.rating
	oil_use = initial(oil_use) - (oil_efficiency * 0.0095)
	oil_use = max(oil_use, 0.001)
	fry_speed = oil_efficiency

/obj/machinery/deepfryer/update_overlays()
	. = ..()
	if(grease_level >= 1)
		. += "fryer_greasy"

/obj/machinery/deepfryer/examine(mob/user)
	. = ..()
	if(frying)
		. += "You can make out \a [frying] in the oil."
	if(in_range(user, src) || isobserver(user))
		. += "<span class='notice'>The status display reads: Frying at <b>[fry_speed*100]%</b> speed.<br>Using <b>[oil_use*10]</b> units of oil per second.</span>"

/obj/machinery/deepfryer/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/reagent_containers/pill))
		if(!reagents.total_volume)
			to_chat(user, "<span class='warning'>There's nothing to dissolve [I] in!</span>")
			return
		user.visible_message("<span class='notice'>[user] drops [I] into [src].</span>", "<span class='notice'>You dissolve [I] in [src].</span>")
		I.reagents.trans_to(src, I.reagents.total_volume, log = "pill into deep fryer")
		qdel(I)
		return
	if(istype(I,/obj/item/clothing/head/mob_holder))
		to_chat(user, "<span class='warning'>This does not fit in the fryer.</span>") // TODO: Deepfrying instakills mobs, spawns a whole deep-fried mob.
		return
	if(!reagents.has_reagent(/datum/reagent/consumable/cooking_oil))
		to_chat(user, "<span class='warning'>[src] has no cooking oil to fry with!</span>")
		return
	if(I.resistance_flags & INDESTRUCTIBLE)
		to_chat(user, "<span class='warning'>You don't feel it would be wise to fry [I]...</span>")
		return
	if(I.GetComponent(/datum/component/fried))
		to_chat(user, "<span class='userdanger'>Your cooking skills are not up to the legendary Doublefry technique.</span>")
		return
	if(default_unfasten_wrench(user, I))
		return
	else if(default_deconstruction_screwdriver(user, "fryer_off", "fryer_off" ,I))	//where's the open maint panel icon?!
		return
	else if(I.reagents && !isfood(I))
		return
	else
		if(is_type_in_typecache(I, deepfry_blacklisted_items) || HAS_TRAIT(I, TRAIT_NODROP) || (I.item_flags & (ABSTRACT | DROPDEL)))
			return ..()
		else if(!frying && user.transferItemToLoc(I, src))
			frying = I
			to_chat(user, "<span class='notice'>You put [I] into [src].</span>")
			flick("fryer_start", src)
			icon_state = "fryer_on"
			fry_loop.start()

/obj/machinery/deepfryer/process()
	..()
	var/datum/reagent/consumable/cooking_oil/C = reagents.has_reagent(/datum/reagent/consumable/cooking_oil)
	if(!C)
		return
	reagents.chem_temp = C.fry_temperature
	if(!frying)
		return

	reagents.trans_to(frying, oil_use, multiplier = fry_speed * 3) //Fried foods gain more of the reagent thanks to space magic
	grease_level += prob(grease_increase_chance) * grease_increase_amount
	cook_time += fry_speed
	if(cook_time >= 30 && !frying_fried)
		frying_fried = TRUE //frying... frying... fried
		playsound(src.loc, 'sound/machines/ding.ogg', 50, 1)
		audible_message("<span class='notice'>[src] dings!</span>")
	else if (cook_time >= 60 && !frying_burnt)
		frying_burnt = TRUE
		visible_message("<span class='warning'>[src] emits an acrid smell!</span>")


/obj/machinery/deepfryer/attack_ai(mob/user)
	return

/obj/machinery/deepfryer/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(frying)
		if(frying.loc == src)
			to_chat(user, "<span class='notice'>You eject [frying] from [src].</span>")
			frying.fry(cook_time)
			flick("fryer_stop", src)
			icon_state = "fryer_off"
			update_appearance(UPDATE_OVERLAYS)
			frying.forceMove(drop_location())
			if(Adjacent(user) && !issilicon(user))
				user.put_in_hands(frying)
			frying = null
			cook_time = 0
			frying_fried = FALSE
			frying_burnt = FALSE
			fry_loop.stop()
			return
	else if(user.pulling && user.a_intent == "grab" && iscarbon(user.pulling) && reagents.total_volume)
		if(!user.CheckActionCooldown(CLICK_CD_MELEE))
			return
		if(user.grab_state < GRAB_AGGRESSIVE)
			to_chat(user, "<span class='warning'>You need a better grip to do that!</span>")
			return
		var/mob/living/carbon/C = user.pulling
		user.visible_message("<span class = 'danger'>[user] dunks [C]'s face in [src]!</span>")
		reagents.reaction(C, TOUCH)
		C.apply_damage(min(30, reagents.total_volume), BURN, BODY_ZONE_HEAD)
		reagents.remove_any((reagents.total_volume/2))
		C.DefaultCombatKnockdown(60)
		user.DelayNextAction()
	return ..()

/obj/machinery/deepfryer/proc/on_cleaned(obj/source_component, obj/source)
	SIGNAL_HANDLER

	. = NONE

	grease_level = 0
	update_appearance(UPDATE_OVERLAYS)
	. |= COMPONENT_CLEANED //|COMPONENT_CLEANED_GAIN_XP
