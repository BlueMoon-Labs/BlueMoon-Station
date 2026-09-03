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

/obj/item/reagent_containers/food/snacks/shrimpwrap
	name = "shrimp wrap"
	desc = "A soft tortilla wrapped around fried shrimps, cheese, and shredded cabbage."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp_wrap"
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 4, /datum/reagent/consumable/nutriment = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	filling_color = "#F0D8A0"
	tastes = list("tortilla" = 2, "shrimp" = 3, "cheese" = 1, "leaves" = 1)
	foodtype = SEAFOOD | DAIRY | GRAIN | VEGETABLES
	w_class = WEIGHT_CLASS_SMALL

// Shrimp pizza
/obj/item/reagent_containers/food/snacks/pizza/shrimp
	name = "shrimp pizza"
	desc = "Greasy pizza topped with fried shrimp, cheese and tomato."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimppizza"
	slice_path = /obj/item/reagent_containers/food/snacks/pizzaslice/shrimp
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 5, /datum/reagent/consumable/nutriment/vitamin = 8)
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 30, /datum/reagent/consumable/tomatojuice = 6, /datum/reagent/consumable/nutriment/vitamin = 8)
	tastes = list("crust" = 1, "tomato" = 1, "cheese" = 1, "shrimp" = 2)
	foodtype = GRAIN | VEGETABLES | DAIRY | SEAFOOD

/obj/item/reagent_containers/food/snacks/pizzaslice/shrimp
	name = "shrimp pizza slice"
	desc = "A savory slice of shrimp pizza."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimppizzaslice"
	filling_color = "#F0D8A0"
	tastes = list("crust" = 1, "tomato" = 1, "cheese" = 1, "shrimp" = 2)
	foodtype = GRAIN | VEGETABLES | DAIRY | SEAFOOD

// Ebi Hosomaki
/obj/item/reagent_containers/food/snacks/shrimp_sushi
	name = "Ebi Hosomaki"
	desc = "A small cylinder of rice and seaweed, rolled around fried shrimp."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp_sushi"
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/nutriment = 1)
	bitesize = 1
	filling_color = "#F2EEEA"
	tastes = list("shrimp" = 2, "rice" = 1, "seaweed" = 1)
	foodtype = SEAFOOD | VEGETABLES | GRAIN

// Shrimp Onigiri
/obj/item/reagent_containers/food/snacks/shrimp_onigiri
	name = "Shrimp Onigiri"
	desc = "Shrimp in a rice ball with a seaweed garnish."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp_onigiri"
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment = 6, /datum/reagent/consumable/sodiumchloride = 2)
	tastes = list("shrimp" = 1, "rice" = 3, "salt" = 1)
	foodtype = SEAFOOD | GRAIN

// Shrimp skewer
/obj/item/reagent_containers/food/snacks/kebab/shrimp
	name = "shrimp skewer"
	desc = "Fried shrimps on a metal skewer."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimpskewer"
	tastes = list("shrimp" = 3, "metal" = 1)
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/nutriment/vitamin = 4)
	foodtype = SEAFOOD
