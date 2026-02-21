/obj/item/reagent_containers/food/snacks/customizable/pet_bowl
	name = "pet bowl"
	desc = "Металлическая посуда для питомцев."
	icon = 'modular_bluemoon/icons/obj/food/pet_bowl.dmi'
	icon_state = "pet_bowl"
	// interaction_flags_item = NONE
	resistance_flags = NONE
	possible_transfer_amounts = list(5, 10, 15, 20, 25, 30, 40, 50, 80)
	reagent_flags = OPENCONTAINER
	spillable = TRUE
	trash = /obj/item/reagent_containers/food/snacks/customizable/pet_bowl
	ingMax = 6
	custom_materials = list(/datum/material/iron = 500)
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/Initialize(mapload)
	. = ..()
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y
	item_flags |= NO_PIXEL_RANDOM_DROP
	register_context()

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(iscarbon(user) && isnull(held_item))
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, "Eat")
		return CONTEXTUAL_SCREENTIP_SET

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/examine(mob/user)
	. = ..()
	. += span_notice("Поднять миску можно незеленым интентом или перетаскиванием на модельку персонажа.")

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/equipped(mob/user, slot, initial)
	. = ..()
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(isturf(loc) && iscarbon(user) && act_intent == INTENT_HELP) // временно убираем подбирание на клик
		interaction_flags_item &= ~INTERACT_ITEM_ATTACK_HAND_PICKUP
	else
		interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP
	. = ..()
	if(user.CheckActionCooldown(CLICK_CD_MELEE) && !istype(loc, /obj/item/storage) && !(interaction_flags_item & INTERACT_ITEM_ATTACK_HAND_PICKUP))
		var/mob/living/carbon/C = user  // /attempt_forcefeed() работает только на карбонов
		var/bowl_is_on_table = (locate(/obj/structure/table) in get_turf(src)) ? TRUE : FALSE
		var/eater_is_on_table = (locate(/obj/structure/table) in get_turf(C)) ? TRUE : FALSE
		var/bowl_and_eater_on_same_lvl = bowl_is_on_table == eater_is_on_table
		var/is_lying = C.lying != 0
		if((!bowl_is_on_table && eater_is_on_table) || \
			(bowl_and_eater_on_same_lvl != is_lying) || \
			(is_lying && \
				(C.y != y || \
				(C.x > x && C.lying == 90) || \
				(C.x < x && C.lying == 270))))
			to_chat(C, span_danger("Тебе нужно быть лицом ближе к миске, чтобы дотянуться до неё ртом."))
		else
			INVOKE_ASYNC(src, PROC_REF(attempt_forcefeed), C, C)
			user.DelayNextAction(CLICK_CD_MELEE)
			if(is_lying)
				C.setDir(NORTH)
		interaction_flags_item |= INTERACT_ITEM_ATTACK_HAND_PICKUP

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/MouseDrop(atom/over)
	. = ..()
	var/mob/living/M = usr
	if(!istype(M) || M.incapacitated() || !Adjacent(M))
		return
	if(over == M && loc != M)
		M.put_in_hands(src)
	else if(istype(over, /atom/movable/screen/inventory/hand))
		var/atom/movable/screen/inventory/hand/H = over
		M.putItemFromInventoryInHandIfPossible(src, H.held_index)

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return
	if(isturf(target) && user.a_intent != INTENT_HARM)
		user.transferItemToLoc(src, target)
		return
	// копипаст с /obj/item/reagent_containers/glass (мне похуй)
	if(!check_allowed_items(target,target_self=1))
		return
	if(target.is_refillable()) //Something like a glass. Player probably wants to transfer TO it.
		if(!reagents.total_volume)
			to_chat(user, "<span class='warning'>Внутри [src] пусто!</span>")
			return
		if(target.reagents.holder_full())
			to_chat(user, "<span class='warning'>[target] is full.</span>")
			return
		var/trans = reagents.trans_to(target, amount_per_transfer_from_this, log = "reagentcontainer-pet_bowl afterattack transfer to")
		to_chat(user, "<span class='notice'>Вы перелили [trans] u веществ в [target].</span>")
	else if(target.is_drainable()) //A dispenser. Transfer FROM it TO us.
		if(!target.reagents.total_volume)
			to_chat(user, "<span class='warning'>[target] пуст и не может быть заправлен!</span>")
			return
		if(reagents.holder_full())
			to_chat(user, "<span class='warning'>[src] is full.</span>")
			return
		var/trans = target.reagents.trans_to(src, amount_per_transfer_from_this, log = "reagentcontainer-pet_bowl afterattack fill from")
		to_chat(user, "<span class='notice'>Вы заполнили [src] на [trans] u содержимого [target].</span>")
	else if(reagents.total_volume && reagent_flags & OPENCONTAINER && spillable)
		if(user.a_intent == INTENT_HARM)
			user.visible_message("<span class='danger'>[user] опрокидывает содержимое [src] на [target]!</span>", \
								"<span class='notice'>Вы опрокинули содержимое [src] на [target].</span>")
			reagents.reaction(target, TOUCH)
			eject_snacks(target = target)
			reagents.clear_reagents()

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/attempt_forcefeed(mob/living/M, mob/living/user)
	if(!reagents?.total_volume)
		to_chat(user, "Увы, но миска пуста.")
		return FALSE
	if(reagents?.has_reagent(/datum/reagent/consumable/nutriment))
		consume_sound = initial(consume_sound)
	else
		consume_sound = 'sound/items/drink.ogg'
	. = ..()
	if(isemptylist(ingredients))
		bitecount = 0

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/On_Consume(mob/living/eater)
	return

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/SplashReagents(atom/target, thrown)
	var/list/I = ingredients.Copy()
	var/datum/reagents/R = new
	reagents.copy_to(R, reagents.total_volume)
	. = ..()
	if(!reagents?.total_volume)
		eject_snacks(I, R)
	qdel(R)

/// иначе еда просто испарится из миски при опрокидывании содержимого
/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/proc/eject_snacks(list/I = ingredients, datum/reagents/R = reagents, target = src)
	for(var/obj/item/reagent_containers/food/snacks/S in I)
		var/snack_found = TRUE
		for(var/i in S.list_reagents)
			var/datum/reagent/r = i
			if(!R.has_reagent(r, S.list_reagents[r]))
				snack_found = FALSE // уже кто-то пожрал и остались только крошки - пусть пропадает
				break
		if(snack_found)
			for(var/i in S.list_reagents)
				var/datum/reagent/r = i
				R.remove_reagent(r, S.list_reagents[r])
			new S.type(get_turf(target))

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/proc/empty_bowl()
	name = initial(name)
	foodtype = initial(foodtype)
	total_quality = initial(total_quality)
	food_quality = initial(food_quality)
	for(var/i in ingredients)
		qdel(i)
	ingredients.Cut()
	bitecount = 0

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/on_reagent_change(changetype)
	. = ..()
	if(!reagents?.total_volume)
		empty_bowl()
	else
		if(!reagents?.has_reagent(/datum/reagent/consumable/nutriment))
			cut_overlays()
			var/datum/reagent/r = reagents.get_master_reagent()
			name = "[initial(name)] of [replacetext(r.glass_name, "glass of ", "")]"
	update_icon()

/obj/item/reagent_containers/food/snacks/customizable/pet_bowl/update_overlays()
	. = ..()
	if(reagents && reagents.total_volume && !reagents.has_reagent(/datum/reagent/consumable/nutriment))
		var/mutable_appearance/filling = mutable_appearance('modular_bluemoon/icons/obj/food/pet_bowl.dmi', "fullbowl")
		filling.color = mix_color_from_reagents(reagents.reagent_list)
		. += filling
