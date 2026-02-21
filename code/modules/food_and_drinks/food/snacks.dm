/** # Snacks

Items in the "Snacks" subcategory are food items that people actually eat. The key points are that they are created
already filled with reagents and are destroyed when empty. Additionally, they make a "munching" noise when eaten.

Notes by Darem: Food in the "snacks" subtype can hold a maximum of 50 units. Generally speaking, you don't want to go over 40
total for the item because you want to leave space for extra condiments. If you want effect besides healing, add a reagent for
it. Try to stick to existing reagents when possible (so if you want a stronger healing effect, just use omnizine). On use
effect (such as the old officer eating a donut code) requires a unique reagent (unless you can figure out a better way).

The nutriment reagent and bitesize variable replace the old heal_amt and amount variables. Each unit of nutriment is equal to
2 of the old heal_amt variable. Bitesize is the rate at which the reagents are consumed. So if you have 6 nutriment and a
bitesize of 2, then it'll take 3 bites to eat. Unlike the old system, the contained reagents are evenly spread among all
the bites. No more contained reagents = no more bites.

Food formatting and crafting examples.
```
/obj/item/reagent_containers/food/snacks/saltedcornchips						//Identification path for the object.
	name = "salted corn chips"													//Name that displays when hovered over.
	desc = "Manufactured in a far away factory."								//Description on examine.
	icon_state = "saltychip"													//Refers to an icon, usually in food.dmi
	bitesize = 3																//How many reagents are consumed in each bite.
	list_reagents = list(/datum/reagent/consumable/nutriment = 6,				//What's inside the snack, but only if spawned. For example, from a chemical reaction, vendor, or slime core spawn.
						/datum/reagent/consumable/nutriment/vitamin = 2)
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 1,				//What's -added- to the food, in addition to the reagents contained inside the foods used to craft it. Basically, a reward for cooking.
						/datum/reagent/consumable/nutriment/vitamin = 1)		^^For example. Egg+Egg = 2Egg + Bonus Reagents.
	filling_color = "#F4A460"													//What color it will use if put in a custom food.
	tastes = list("salt" = 1, "oil" = 1)										//Descriptive flavoring displayed when eaten. IE: "You taste a bit of salt and a bit of oil."
	foodtype = GRAIN | JUNKFOOD													//Tag for racial or custom food preferences. IE: Most Lizards cannot have GRAIN.

Crafting Recipe (See files in code/modules/food_and_drinks/recipes/tablecraft/)

/datum/crafting_recipe/food/nachos
	name ="Salted Corn Chips"													//Name that displays in the Crafting UI
	reqs = list(																//The list of ingredients to make the food.
		/obj/item/reagent_containers/food/snacks/tortilla = 1,
		/datum/reagent/consumable/sodiumchloride = 1							//As a note, reagents and non-food items don't get added to the food. If you
	)																			^^want the reagents, make sure the food item has it listed under bonus_reagents.
	result = /obj/item/reagent_containers/food/snacks/saltedcornchips			//Resulting object.
	subcategory = CAT_MISCFOOD													//Subcategory the food falls under in the Food Tab of the crafting menu.
```

All foods are distributed among various categories. Use common sense.
*/
/obj/item/reagent_containers/food/snacks
	name = "snack"
	desc = "Yummy."
	icon = 'icons/obj/food/food.dmi'
	icon_state = null
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'
	obj_flags = UNIQUE_RENAME
	grind_results = list() //To let them be ground up to transfer their reagents
	consume_sound = 'sound/items/eatfood.ogg'
	var/bitesize = 2
	var/bitecount = 0
	var/trash = null
	var/slice_path    // for sliceable food. path of the item resulting from the slicing
	var/slices_num
	var/eatverb
	var/dried_type = null
	var/dry = 0
	var/cooked_type = null  //for microwave cooking. path of the resulting item after microwaving
	var/filling_color = "#FFFFFF" //color to use when added to custom food.
	var/custom_food_type = null  //for food customizing. path of the custom food to create
	var/junkiness = 0  //for junk food. used to lower human satiety.
	var/list/bonus_reagents //the amount of reagents (usually nutriment and vitamin) added to crafted/cooked snacks, on top of the ingredients reagents.
	var/customfoodfilling = 1 // whether it can be used as filling in custom food
	var/list/tastes  // for example list("crisps" = 2, "salt" = 1)
	var/dunkable = FALSE // for dunkable food, make true
	var/dunk_amount = 10 // how much reagent is transferred per dunk

	//Placeholder for effect that trigger on eating that aren't tied to reagents.

/obj/item/reagent_containers/food/snacks/ComponentInitialize()
	. = ..()
	if(dunkable)
		AddElement(/datum/element/dunkable, dunk_amount)

/obj/item/reagent_containers/food/snacks/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_MICROWAVE_COOKED, PROC_REF(on_microwave_cooked))
	make_microwaveable()
	make_processable()

/obj/item/reagent_containers/food/snacks/Destroy()
	UnregisterSignal(src, COMSIG_ITEM_MICROWAVE_COOKED)
	if(contents)
		for(var/atom/movable/something in contents)
			something.forceMove(drop_location())
	return ..()

/// This proc handles the microwave component. Overwrite if you want special microwave results.
/// By default, all food is microwavable. However, they will be microwaved into a bad recipe (burnt mess).
/obj/item/reagent_containers/food/snacks/proc/make_microwaveable()
	if(!cooked_type)
		AddElement(/datum/element/microwavable, /obj/item/reagent_containers/food/snacks/badrecipe, bad_recipe = TRUE)
	else
		AddElement(/datum/element/microwavable, cooked_type)

///This proc handles processable elements, overwrite this if you want to add behavior such as slicing, forking, spooning, whatever, to turn the item into something else
/obj/item/reagent_containers/food/snacks/proc/make_processable()
	if(slice_path)
		AddElement(/datum/element/processable, TOOL_KNIFE, slice_path, slices_num,  3 SECONDS, table_required = TRUE, screentip_verb = "Cut", sound_to_play = SFX_KNIFE_SLICE)
	return

/obj/item/reagent_containers/food/snacks/add_initial_reagents()
	if(tastes && tastes.len)
		if(list_reagents)
			for(var/rid in list_reagents)
				var/amount = list_reagents[rid]
				if(rid == /datum/reagent/consumable/nutriment || rid == /datum/reagent/consumable/nutriment/vitamin)
					reagents.add_reagent(rid, amount, tastes.Copy())
				else
					reagents.add_reagent(rid, amount)
		if(bonus_reagents)
			for(var/rid in bonus_reagents)
				var/amount = bonus_reagents[rid]
				if(rid == /datum/reagent/consumable/nutriment || rid == /datum/reagent/consumable/nutriment/vitamin)
					reagents.add_reagent(rid, amount, tastes.Copy())
				else
					reagents.add_reagent(rid, amount)
	else
		..()

/obj/item/reagent_containers/food/snacks/proc/On_Consume(mob/living/eater)
	if(!eater)
		return
	if(!reagents.total_volume)
		var/mob/living/location = loc
		var/obj/item/trash_item = generate_trash(location)
		qdel(src)
		if(istype(location))
			location.put_in_hands(trash_item)

/obj/item/reagent_containers/food/snacks/attack_self(mob/user)
	return


/obj/item/reagent_containers/food/snacks/attack(mob/living/M, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(user.a_intent == INTENT_HARM)
		return ..()
	INVOKE_ASYNC(src, PROC_REF(attempt_forcefeed), M, user)

/obj/item/reagent_containers/food/snacks/proc/attempt_forcefeed(mob/living/M, mob/living/user)
	if(!eatverb)
		eatverb = pick("bite","chew","nibble","gnaw","gobble","chomp")
	if(!reagents.total_volume)						//Shouldn't be needed but it checks to see if it has anything left in it.
		to_chat(user, "<span class='notice'>None of [src] left, oh no!</span>")
		On_Consume(M)
		return FALSE
	if(iscarbon(M))
		if(!canconsume(M, user))
			return FALSE

		var/fullness = M.nutrition + 10
		for(var/datum/reagent/consumable/C in M.reagents.reagent_list) //we add the nutrition value of what we're currently digesting
			fullness += C.nutriment_factor * C.volume / C.metabolization_rate

		if(M == user)								//If you're eating it yourself.
			if(junkiness && M.satiety < -150 && M.nutrition > NUTRITION_LEVEL_STARVING + 50 )
				to_chat(M, "<span class='notice'>You don't feel like eating any more junk food at the moment.</span>")
				return FALSE
			else if(fullness <= 50)
				user.visible_message("<span class='notice'>[user] hungrily takes a [eatverb] from \the [src], gobbling it down!</span>", "<span class='notice'>You hungrily take a [eatverb] from \the [src], gobbling it down!</span>")
			else if(fullness > 50 && fullness < 150)
				user.visible_message("<span class='notice'>[user] hungrily takes a [eatverb] from \the [src].</span>", "<span class='notice'>You hungrily take a [eatverb] from \the [src].</span>")
			else if(fullness > 150 && fullness < 500)
				user.visible_message("<span class='notice'>[user] takes a [eatverb] from \the [src].</span>", "<span class='notice'>You take a [eatverb] from \the [src].</span>")
			else if((fullness > 500 && fullness < 600) || HAS_TRAIT(user, TRAIT_BLUEMOON_DEVOURER))
				user.visible_message("<span class='notice'>[user] unwillingly takes a [eatverb] of a bit of \the [src].</span>", "<span class='warning'>You unwillingly take a [eatverb] of a bit of \the [src].</span>")
			else if(fullness > (600 * (1 + M.overeatduration / 2000)))	// The more you eat - the more you can eat
				user.visible_message("<span class='warning'>[user] cannot force any more of \the [src] to go down [user.p_their()] throat!</span>", "<span class='danger'>You cannot force any more of \the [src] to go down your throat!</span>")
				return FALSE
		else
			if(!isbrain(M))		//If you're feeding it to someone else.
				if(fullness <= (600 * (1 + M.overeatduration / 1000)))
					M.visible_message("<span class='danger'>[user] attempts to feed [M] [src].</span>", \
										"<span class='userdanger'>[user] attempts to feed [M] [src].</span>")
				else
					M.visible_message("<span class='warning'>[user] cannot force any more of [src] down [M]'s throat!</span>", \
										"<span class='warning'>[user] cannot force any more of [src] down [M]'s throat!</span>")
					return FALSE

				if(!do_mob(user, M))
					return
				log_combat(user, M, "fed", reagents.log_list())
				M.visible_message("<span class='danger'>[user] forces [M] to eat [src].</span>", \
									"<span class='userdanger'>[user] forces [M] to eat [src].</span>")

			else
				to_chat(user, "<span class='warning'>[M] doesn't seem to have a mouth!</span>")
				return

		if(reagents)								//Handle ingestion of the reagent.
			if(M.satiety > -200)
				M.satiety -= junkiness
			playsound(M.loc, consume_sound, rand(10,50), 1)
			if(reagents.total_volume)
				SEND_SIGNAL(src, COMSIG_FOOD_EATEN, M, user)
				var/fraction = min(bitesize / reagents.total_volume, 1)
				reagents.reaction(M, INGEST, fraction)
				reagents.trans_to(M, bitesize, log = TRUE)
				bitecount++
				On_Consume(M)
				checkLiked(fraction, M)
				return TRUE

	return FALSE

/obj/item/reagent_containers/food/snacks/CheckAttackCooldown(mob/user, atom/target)
	var/fast = HAS_TRAIT(user, TRAIT_VORACIOUS) && (user == target)
	return user.CheckActionCooldown(fast? CLICK_CD_RANGE : CLICK_CD_MELEE)

/obj/item/reagent_containers/food/snacks/examine(mob/user)
	. = ..()
	if(food_quality >= 70)
		. += "It is of a high quality."
	else
		if(food_quality <= 30)
			. += "It is of a low quality."

	if(bitecount == 0)
		return
	else if(bitecount == 1)
		. += "[src] was bitten by someone!"
	else if(bitecount <= 3)
		. += "[src] was bitten [bitecount] times!"
	else
		. += "[src] was bitten multiple times!"


/obj/item/reagent_containers/food/snacks/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/storage))
		..() // -> item/attackby()
		return FALSE
	if(istype(W, /obj/item/reagent_containers/food/snacks))
		var/obj/item/reagent_containers/food/snacks/S = W
		if(custom_food_type && ispath(custom_food_type))
			if(S.w_class > WEIGHT_CLASS_SMALL)
				to_chat(user, "<span class='warning'>[S] is too big for [src]!</span>")
				return FALSE
			if(!S.customfoodfilling || istype(W, /obj/item/reagent_containers/food/snacks/customizable) || istype(W, /obj/item/reagent_containers/food/snacks/pizzaslice/custom) || istype(W, /obj/item/reagent_containers/food/snacks/cakeslice/custom))
				to_chat(user, "<span class='warning'>[src] can't be filled with [S]!</span>")
				return FALSE
			if(contents.len >= 20)
				to_chat(user, "<span class='warning'>You can't add more ingredients to [src]!</span>")
				return FALSE
			var/obj/item/reagent_containers/food/snacks/customizable/C = new custom_food_type(get_turf(src))
			C.initialize_custom_food(src, S, user)
			return FALSE

	return ..()

//Called when you finish tablecrafting a snack.
/obj/item/reagent_containers/food/snacks/CheckParts(list/parts_list, datum/crafting_recipe/food/R)
	..()
	reagents.clear_reagents()
	for(var/obj/item/reagent_containers/RC in contents)
		RC.reagents.trans_to(reagents, RC.reagents.maximum_volume)
	if(istype(R))
		contents_loop:
			for(var/A in contents)
				for(var/B in R.real_parts)
					if(istype(A, B))
						continue contents_loop
				qdel(A)
	SSblackbox.record_feedback("tally", "food_made", 1, type)

	if(bonus_reagents && bonus_reagents.len)
		for(var/r_id in bonus_reagents)
			var/amount = bonus_reagents[r_id]
			if(r_id == /datum/reagent/consumable/nutriment || r_id == /datum/reagent/consumable/nutriment/vitamin)
				reagents.add_reagent(r_id, amount, tastes)
			else
				reagents.add_reagent(r_id, amount)

///Called when food is created through processing (Usually this means it was sliced). We use this to pass the OG items reagents.
/obj/item/reagent_containers/food/snacks/OnCreatedFromProcessing(mob/living/user, obj/item/work_tool, list/chosen_option, atom/original_atom)
	..()

	if(!original_atom.reagents)
		return

	//Make sure we have a reagent container large enough to fit the original atom's reagents.
	var/volume = ROUND_UP(original_atom.reagents.maximum_volume / chosen_option[TOOL_PROCESSING_AMOUNT])

	create_reagents(volume, reagents?.reagents_holder_flags)
	original_atom.reagents.trans_to(src, original_atom.reagents.total_volume / chosen_option[TOOL_PROCESSING_AMOUNT])

	if(original_atom.name != initial(original_atom.name))
		name = "slice of [original_atom.name]"
		//It inherits the name of the original, which may already have a prefix
		//So we need to make sure we don't double up on prefixes
		//This is called before set_custom_materials() anyway
		material_flags &= ~MATERIAL_ADD_PREFIX
	if(original_atom.desc != initial(original_atom.desc))
		desc = "[original_atom.desc]"

/obj/item/reagent_containers/food/snacks/proc/generate_trash(atom/location)
	if(trash)
		if(ispath(trash, /obj/item))
			. = new trash(location)
			trash = null
			return
		else if(isitem(trash))
			var/obj/item/trash_item = trash
			trash_item.forceMove(location)
			. = trash
			trash = null
			return

/obj/item/reagent_containers/food/snacks/proc/update_snack_overlays(obj/item/reagent_containers/food/snacks/S)
	cut_overlays()
	var/mutable_appearance/filling = mutable_appearance(icon, "[initial(icon_state)]_filling")
	if(S.filling_color == "#FFFFFF")
		filling.color = pick("#FF0000","#0000FF","#008000","#FFFF00")
	else
		filling.color = S.filling_color

	add_overlay(filling)

// on_microwave_cooked() is called when microwaving the food
/obj/item/reagent_containers/food/snacks/proc/on_microwave_cooked(datum/source, atom/source_item, cooking_efficiency = 1)
	SIGNAL_HANDLER

	//adjust_food_quality(food_quality + microwave_source.quality_increase)
	if(!length(bonus_reagents))
		return

	for(var/r_id in bonus_reagents)
		var/amount = round(bonus_reagents[r_id] * cooking_efficiency)
		if(r_id == /datum/reagent/consumable/nutriment || r_id == /datum/reagent/consumable/nutriment/vitamin)
			reagents.add_reagent(r_id, amount, tastes)
		else
			reagents.add_reagent(r_id, amount)

/obj/item/reagent_containers/food/snacks/attack_animal(mob/M)
	if(isanimal(M))
		if(iscorgi(M))
			var/mob/living/L = M
			if(bitecount == 0 || prob(50))
				M.emote("me", EMOTE_VISIBLE, "nibbles away at \the [src]")
			bitecount++
			L.taste(reagents) // why should carbons get all the fun?
			if(bitecount >= 5)
				var/sattisfaction_text = pick("burps from enjoyment", "yaps for more", "woofs twice", "looks at the area where \the [src] was")
				if(sattisfaction_text)
					M.emote("me", EMOTE_VISIBLE, "[sattisfaction_text]")
				qdel(src)

// //////////////////////////////////////////////Store////////////////////////////////////////
/// All the food items that can store an item inside itself, like bread or cake.
/obj/item/reagent_containers/food/snacks/store
	w_class = WEIGHT_CLASS_NORMAL
	var/stored_item = 0

/obj/item/reagent_containers/food/snacks/store/attackby(obj/item/W, mob/user, params)
	..()
	if(W.w_class <= WEIGHT_CLASS_SMALL & !istype(W, /obj/item/reagent_containers/food/snacks)) //can't slip snacks inside, they're used for custom foods.
		if(W.get_sharpness())
			return FALSE
		if(stored_item)
			return FALSE
		if(!iscarbon(user))
			return FALSE
		if(contents.len >= 20)
			to_chat(user, "<span class='warning'>[src] is full.</span>")
			return FALSE
		to_chat(user, "<span class='notice'>You slip [W] inside [src].</span>")
		user.transferItemToLoc(W, src)
		add_fingerprint(user)
		contents += W
		stored_item = 1
		return TRUE // no afterattack here

/obj/item/reagent_containers/food/snacks/MouseDrop(atom/over)
	var/turf/T = get_turf(src)
	var/obj/structure/table/TB = locate(/obj/structure/table) in T
	if(TB)
		TB.MouseDrop(over)
	else
		return ..()

// //////////////////////////////////////////////Frying////////////////////////////////////////
/atom/proc/fry(cook_time = 30) //you can truly fry anything
	//don't fry reagent containers that aren't food items, indestructable items, or items that are already fried
	if(isitem(src))
		var/obj/item/fried_item = src
		if(fried_item.resistance_flags & INDESTRUCTIBLE)
			return
	if(!GetComponent(/datum/component/fried) && (!reagents || isfood(src) || ismob(src)))
		AddComponent(/datum/component/fried, frying_power = cook_time)
