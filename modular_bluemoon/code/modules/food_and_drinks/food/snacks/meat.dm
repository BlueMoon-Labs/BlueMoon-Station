

// Заказывайте с ЦК данные вида мяс, ибо чтобы разводить особые рыбки и получать
// с них мясо требуется ввеси целый подмодуль... _fish.dm с ARK
/obj/item/reagent_containers/food/snacks/dried_fish
	name = "dried fish fillet"
	desc = "Technically fish jerky?"
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "driedfish"
	list_reagents = list(
		/datum/reagent/consumable/nutriment = 4,
		/datum/reagent/consumable/nutriment/vitamin = 2,
	)
	tastes = list("fish" = 1, "dried meat" = 1)
	foodtype = SEAFOOD
	w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/consumable/bonito = 20)

/obj/item/reagent_containers/food/snacks/katsu_fillet
	name = "katsu fillet"
	desc = "Breaded and deep fried meat, used for a variety of dishes."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "katsu_fillet"
	list_reagents = list(
		/datum/reagent/consumable/nutriment/vitamin = 2,
		/datum/reagent/consumable/nutriment = 2,
	)
	tastes = list("meat" = 1, "breadcrumbs" = 1)
	foodtype = MEAT | GRAIN
	w_class = WEIGHT_CLASS_SMALL

/obj/item/reagent_containers/food/red_bay // Это тоже под заказ с ЦК
	name = "\improper Red Bay seasoning"
	icon = 'modular_bluemoon/icons/obj/food/containers.dmi'
	desc = "Mars' favourite seasoning."
	icon_state = "red_bay"
	list_reagents = list(/datum/reagent/consumable/red_bay = 50,)
	foodtype = SAUCE
