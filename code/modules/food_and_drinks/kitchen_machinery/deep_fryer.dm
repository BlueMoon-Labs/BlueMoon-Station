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
	desc = "Фритюрит <i>что угодно</i>."
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
		. += "Вы можете разглядеть [frying] в масле."

/obj/machinery/deepfryer/examine_display_content(mob/user)
	. += "– Фритюр работает на скорости <b>[fry_speed*100]%</b>.\n\
	– Выкипает <b>[oil_use*10]</b>u масла в секунду."

/obj/machinery/deepfryer/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/reagent_containers/pill))
		if(!reagents.total_volume)
			to_chat(user, span_warning("Внутри [I] ничего нет, чтобы растворить!"))
			return
		user.visible_message(span_notice("[user] опускает [I] внутрь [src]."), span_notice("Вы растворяете [I] внутри [src]."))
		I.reagents.trans_to(src, I.reagents.total_volume, log = "pill into deep fryer")
		qdel(I)
		return
	if(istype(I,/obj/item/clothing/head/mob_holder))
		to_chat(user, span_warning("Это не поместится внутри фритюрницы.")) // TODO: Deepfrying instakills mobs, spawns a whole deep-fried mob.
		return
	if(!reagents.has_reagent(/datum/reagent/consumable/cooking_oil))
		to_chat(user, span_warning("Внутри [src] нет масла для обжарки!"))
		return
	if(I.resistance_flags & INDESTRUCTIBLE)
		to_chat(user, span_warning("Вам кажется, что фритюрить [I] не было бы разумно..."))
		return
	if(I.GetComponent(/datum/component/fried))
		to_chat(user, span_userdanger("Вашим поварским навыкам далеко до легендарных техник Морона Пузан Казана."))
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
			to_chat(user, span_notice("Вы положили [I] внутрь [src]."))
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
		audible_message(span_notice("[src] звенит!"))
	else if (cook_time >= 60 && !frying_burnt)
		frying_burnt = TRUE
		visible_message(span_warning("[src] источает едкую вонь!"))


/obj/machinery/deepfryer/attack_ai(mob/user)
	return

/obj/machinery/deepfryer/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(frying)
		if(frying.loc == src)
			to_chat(user, span_notice("Вы вытаскиваете [frying] из [src]."))
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
			to_chat(user, span_warning("Вам понадобится хватка покрепче для этого!"))
			return
		var/mob/living/carbon/C = user.pulling
		user.visible_message(span_danger("[user] окунает лицо [C] внутрь [src]!"))
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
