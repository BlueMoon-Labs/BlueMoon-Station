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
