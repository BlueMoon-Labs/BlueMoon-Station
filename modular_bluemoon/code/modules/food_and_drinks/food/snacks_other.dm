/obj/item/reagent_containers/food/snacks/spaghetti/rawnoodles
	name = "fresh noodles"
	desc = "Rice noodles, made fresh. Remember, there is no secret ingredient."
	icon = 'modular_bluemoon/icons/obj/food/food_ingredients.dmi'
	icon_state = "raw_noodles"
	list_reagents = list(
		/datum/reagent/consumable/nutriment = 3,
	)
	tastes = list("rice" = 1)
	foodtype = GRAIN

/obj/item/reagent_containers/food/snacks/curd
	name = "curd"
	desc = "A piece of curd."
	icon = 'modular_bluemoon/icons/obj/food/food_ingredients.dmi'
	icon_state = "curd"
	list_reagents = list(/datum/reagent/consumable/nutriment = 6)
	tastes = list("curd" = 1)
	foodtype = DAIRY

// Rice Dough
/obj/item/reagent_containers/food/snacks/rice_dough
	name = "rice dough"
	desc = "A piece of dough made with equal parts rice flour and wheat flour, for a unique flavour."
	icon = 'modular_bluemoon/icons/obj/food/food_ingredients.dmi'
	icon_state = "rice_dough"
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 6)
	list_reagents = list(/datum/reagent/consumable/nutriment = 6)
	tastes = list("rice" = 1)
	foodtype = GRAIN
	cooked_type = /obj/item/reagent_containers/food/snacks/store/bread/reispan

/obj/item/reagent_containers/food/snacks/tonkatsuwurst
	name = "tonkatsuwurst"
	desc = "A cultural fusion between German and Japanese cooking, tonkatsuwurst blends the currywurst and tonkatsu sauce into something familiar, yet new."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "tonkatsuwurst"
	bonus_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/worcestershire = 2,
	)
	list_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 3,
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/worcestershire = 2,
	)
	tastes = list("sausage" = 1, "spicy sauce" = 1, "fries" = 1)
	foodtype = MEAT | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL
