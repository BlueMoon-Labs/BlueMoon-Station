/obj/item/reagent_containers/food/snacks/salad/yakisoba_katsu
	name = "yakisoba katsu"
	desc = "Breaded and deep fried meat on a bed of fried noodles. Delicious, if unconventional."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "yakisoba_katsu"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 4,
		/datum/reagent/consumable/nutriment = 8
	)
	tastes = list("fried noodles" = 1, "meat" = 1, "breadcrumbs" = 1, "veggies" = 1)
	foodtype = MEAT | VEGETABLES | GRAIN
	w_class = WEIGHT_CLASS_SMALL

/obj/item/reagent_containers/food/snacks/salad/bulgogi_noodles
	name = "bulgogi noodles"
	desc = "Korean barbecue meat served with noodles! Made with gochujang, for extra spicy flavour."
	icon = 'modular_bluemoon/icons/obj/food/soupsalad.dmi'
	icon_state = "bulgogi_noodles"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 8,
		/datum/reagent/consumable/nutriment = 8,
		/datum/reagent/consumable/capsaicin = 2,
	)
	tastes = list("barbecue meat" = 1, "noodles" = 1, "chilli heat" = 1)
	foodtype = MEAT | GRAIN | VEGETABLES | FRUIT
	w_class = WEIGHT_CLASS_SMALL

/obj/item/reagent_containers/food/snacks/salad/shrimpcaesar
	name = "shrimp caesar salad"
	desc = "Crisp cabbage, tomato and garlic tossed with cheese and fried shrimp."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp_caesar"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/protein = 6,
		/datum/reagent/consumable/nutriment = 6,
		/datum/reagent/consumable/nutriment/vitamin = 3,
	)
	tastes = list("leaves" = 1, "shrimp" = 2, "garlic" = 1, "cheese" = 1)
	foodtype = VEGETABLES | SEAFOOD | DAIRY
	w_class = WEIGHT_CLASS_SMALL
