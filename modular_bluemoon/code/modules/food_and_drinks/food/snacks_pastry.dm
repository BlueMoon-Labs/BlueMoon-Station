/obj/item/reagent_containers/food/snacks/glazed_curd
	name = "glazed curd"
	desc = "A delicious and glazed curd."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "glazed_curd"
	var/ground_state = "glazed_curd"
	var/inhand_state = "glazed_curd_inhand"
	bitesize = 6
	bonus_reagents = list(/datum/reagent/consumable/nutriment/vitamin = 1)
	list_reagents = list(/datum/reagent/consumable/nutriment = 6)
	filling_color = "#512516"
	tastes = list("glazed curd" = 1)
	foodtype = DAIRY | SUGAR | BREAKFAST

/obj/item/reagent_containers/food/snacks/glazed_curd/pickup()
	. = ..()
	icon_state = inhand_state

/obj/item/reagent_containers/food/snacks/glazed_curd/dropped()
	. = ..()
	icon_state = ground_state

/obj/item/reagent_containers/food/snacks/glazed_curd/strawberry
	name = "glazed curd"
	desc = "A delicious and glazed curd."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "glazed_curd_strawberry"
	ground_state = "glazed_curd_strawberry"
	inhand_state = "glazed_curd_strawberry_inhand"
	bonus_reagents = list(/datum/reagent/consumable/nutriment/vitamin = 2)
	filling_color = "#914556"
	tastes = list("glazed curd" = 1, "strawberry" = 1)

/obj/item/reagent_containers/food/snacks/shrimpbun
	name = "shrimp bun"
	desc = "A soft bun baked around a whole fried shrimp, its tail peeking out the end."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimpbun"
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 3, /datum/reagent/consumable/nutriment = 4, /datum/reagent/consumable/nutriment/vitamin = 2)
	filling_color = "#F0D8A0"
	tastes = list("bun" = 2, "shrimp" = 3)
	foodtype = GRAIN | SEAFOOD
