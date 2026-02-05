// Watermelon
/obj/item/seeds/watermelon
	name = "pack of watermelon seeds"
	desc = "These seeds grow into watermelon plants."
	icon_state = "seed-watermelon"
	species = "watermelon"
	plantname = "Watermelon Vines"
	product = /obj/item/reagent_containers/food/snacks/grown/watermelon
	lifespan = 50
	endurance = 40
	instability = 20
	growing_icon = 'icons/obj/hydroponics/growing_fruits.dmi'
	icon_dead = "watermelon-dead"
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	mutatelist = list(/obj/item/seeds/watermelon/holy)
	reagents_add = list(/datum/reagent/water = 0.2, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.2)

/obj/item/seeds/watermelon/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is swallowing [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	user.gib()
	new product(drop_location())
	qdel(src)
	return MANUAL_SUICIDE

/obj/item/reagent_containers/food/snacks/grown/watermelon
	seed = /obj/item/seeds/watermelon
	name = "watermelon"
	desc = "It's full of watery goodness."
	icon_state = "watermelon"
	slice_path = /obj/item/reagent_containers/food/snacks/watermelonslice
	slices_num = 5
	dried_type = null
	w_class = WEIGHT_CLASS_NORMAL
	filling_color = "#008000"
	bitesize_mod = 3
	foodtype = FRUIT
	juice_results = list(/datum/reagent/consumable/watermelonjuice = 0)
	wine_power = 40

// Holymelon
/obj/item/seeds/watermelon/holy
	name = "pack of holymelon seeds"
	desc = "These seeds grow into holymelon plants."
	icon_state = "seed-holymelon"
	species = "holymelon"
	plantname = "Holy Melon Vines"
	product = /obj/item/reagent_containers/food/snacks/grown/holymelon
	genes = list(/datum/plant_gene/trait/glow/yellow)
	mutatelist = list()
	reagents_add = list(/datum/reagent/water/holywater = 0.2, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.1)
	rarity = 20

/obj/item/reagent_containers/food/snacks/grown/holymelon
	seed = /obj/item/seeds/watermelon/holy
	name = "holymelon"
	desc = "The water within this melon has been blessed by some deity that's particularly fond of watermelon."
	icon_state = "holymelon"
	filling_color = "#FFD700"
	dried_type = null
	wine_power = 70 //Water to wine, baby.
	wine_flavor = "divinity"

/obj/item/reagent_containers/food/snacks/grown/holymelon/examine(user)
	. = ..()
	. += span_notice("Святость арбуза постепенно уходит...")

/obj/item/reagent_containers/food/snacks/grown/holymelon/Initialize(mapload)
	. = ..()
	var/uses = 1
	var/const/charges_expire_time = 2 MINUTES
	if(seed)
		uses = round(seed.potency / 20)
	if(uses)
		AddComponent(/datum/component/anti_magic, TRUE, TRUE, FALSE, ITEM_SLOT_HANDS, uses, TRUE, CALLBACK(src, PROC_REF(block_magic)), CALLBACK(src, PROC_REF(expire)), charges_expire_time, CALLBACK(src, PROC_REF(on_charges_change))) //deliver us from evil o melon god
	icon_state = icon_state + "-[clamp(uses, 1, 5)]"

/obj/item/reagent_containers/food/snacks/grown/holymelon/proc/block_magic(mob/user, major)
	if(major)
		to_chat(user, span_warning("[src] hums slightly, and seems to decay a bit."))

/obj/item/reagent_containers/food/snacks/grown/holymelon/proc/expire(mob/user)
	if(istype(user))
		to_chat(user, span_warning("[src] rapidly turns into ash!"))
	new /obj/effect/decal/cleanable/ash(drop_location())
	qdel(src)

/obj/item/reagent_containers/food/snacks/grown/holymelon/proc/on_charges_change(mob/user, current_charges)
	icon_state = initial(icon_state) + "-[clamp(current_charges, 1, 5)]"

// BLUEMOON ADD START || melon
/obj/item/seeds/melon
	name = "pack of melon seeds"
	desc = "These seeds grow into melon plants."
	icon_state = "seed-melon"
	species = "melon"
	plantname = "melon Vines"
	product = /obj/item/reagent_containers/food/snacks/grown/melon
	lifespan = 50
	endurance = 40
	instability = 20
	growing_icon = 'icons/obj/hydroponics/growing_fruits.dmi'
	icon_dead = "melon-dead"
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	mutatelist = list(/obj/item/seeds/melon/space)
	reagents_add = list(/datum/reagent/water = 0.1, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.2)

/obj/item/seeds/melon/suicide_act(mob/user)
	user.visible_message("<span class='suicide'>[user] is swallowing [src]! It looks like [user.p_theyre()] trying to commit suicide!</span>")
	user.gib()
	new product(drop_location())
	qdel(src)
	return MANUAL_SUICIDE

/obj/item/reagent_containers/food/snacks/grown/melon
	seed = /obj/item/seeds/melon
	name = "melon"
	desc = "It's full of watery goodness."
	icon_state = "melon-1"
	slice_path = /obj/item/reagent_containers/food/snacks/melonslice
	slices_num = 5
	dried_type = null
	w_class = WEIGHT_CLASS_NORMAL
	filling_color = "#FFCC00"
	bitesize_mod = 3
	foodtype = FRUIT
	juice_results = list(/datum/reagent/consumable/melonjuice = 0)
	wine_power = 40

/obj/item/reagent_containers/food/snacks/grown/melon/Initialize(mapload, obj/item/seeds/new_seed)
	. = ..()
	update_icon()

/obj/item/reagent_containers/food/snacks/grown/melon/update_icon(updates)
	. = ..()
	var/state = copytext(icon_state, 1, length(icon_state) - 1) // обрезаем последние 2 символа
	if(seed)
		switch(clamp(seed.potency, 0, 100))
			if(0 to 25)      icon_state = state + "-4"
			if(26 to 50)     icon_state = state + "-3"
			if(51 to 75)     icon_state = state + "-2"
			if(76 to 100)    icon_state = state + "-1"
	else
		icon_state = state + "-1"

// Spacemelon
/obj/item/seeds/melon/space
	name = "pack of spacemelon seeds"
	desc = "These seeds grow into spacemelon plants."
	icon_state = "seed-spacemelon"
	species = "spacemelon"
	plantname = "Space Melon Vines"
	product = /obj/item/reagent_containers/food/snacks/grown/melon/space
	genes = list(/datum/plant_gene/trait/glow/blue)
	mutatelist = list()
	reagents_add = list(/datum/reagent/space_cleaner = 0.2, /datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.1)
	rarity = 20

/obj/item/reagent_containers/food/snacks/grown/melon/space
	seed = /obj/item/seeds/melon/space
	name = "spacemelon"
	desc = "It's full of something strange, like a liquid void."
	icon_state = "spacemelon-1"
	slice_path = /obj/item/reagent_containers/food/snacks/melonslice/space
	filling_color = "#147cb9"
	wine_power = 50
	wine_flavor = "void"
// BLUEMOON ADD END
