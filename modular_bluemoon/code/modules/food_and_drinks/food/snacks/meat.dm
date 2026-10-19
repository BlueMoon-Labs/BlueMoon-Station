

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

/obj/item/reagent_containers/food/condiment/red_bay // Это тоже под заказ с ЦК
	name = "\improper Red Bay seasoning"
	icon = 'modular_bluemoon/icons/obj/food/containers.dmi'
	desc = "Mars' favourite seasoning."
	icon_state = "red_bay"
	list_reagents = list(/datum/reagent/consumable/red_bay = 50,)
	foodtype = SAUCE

/obj/item/reagent_containers/food/snacks/meat/rawshrimp
	name = "raw shrimp"
	desc = "A small, peeled shrimp. Best cooked before eating."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp"
	bitesize = 2
	list_reagents = list(/datum/reagent/consumable/nutriment = 1)
	cooked_type = /obj/item/reagent_containers/food/snacks/meat/shrimp
	filling_color = "#E8A0A0"
	tastes = list("raw shrimp" = 1)
	foodtype = RAW | SEAFOOD
	w_class = WEIGHT_CLASS_TINY

/obj/item/reagent_containers/food/snacks/meat/shrimp
	name = "fried shrimp"
	desc = "A shrimp fried to a crisp golden brown."
	icon = 'modular_bluemoon/icons/obj/food/food.dmi'
	icon_state = "shrimp_cooked"
	bitesize = 2
	list_reagents = list(/datum/reagent/consumable/nutriment = 1)
	bonus_reagents = list(/datum/reagent/consumable/nutriment/protein = 2, /datum/reagent/consumable/nutriment/vitamin = 2)
	filling_color = "#D97B4F"
	tastes = list("shrimp" = 1)
	foodtype = MEAT | SEAFOOD | FRIED
	w_class = WEIGHT_CLASS_TINY


/obj/item/reagent_containers/food/snacks/surstromming
	name = "Surstromming"
	desc = "Oh no... this is so bad... Like Michael Jackson Bad, so it's pretty good, maybe."
	icon = 'modular_bluemoon/icons/obj/toys/plushes.dmi'
	icon_state = "surstromming"
	list_reagents = list(
		/datum/reagent/consumable/nutriment = 1,
		/datum/reagent/surstromming_juice = 1
	)
	tastes = list("fish" = 1, "dried meat" = 1)
	foodtype = SEAFOOD
	w_class = WEIGHT_CLASS_SMALL
	grind_results = list(/datum/reagent/consumable/bonito = 20)

/datum/reagent/surstromming_juice
	name = "Surstromming Juice"
	description = "Концентрированный сок тухлой рыбы. Пахнет как химическое оружие."
	reagent_state = LIQUID
	color = "#778844"

/datum/reagent/surstromming_juice/on_mob_add(mob/living/carbon/M, amount)
	..()
	if(!iscarbon(M) || M.stat == DEAD)
		return

	var/turf/T = get_turf(M)
	if(!T)
		return

	var/list/sur_sounds = list('modular_bluemoon/sound/plush/surstromming1.ogg', 'modular_bluemoon/sound/plush/surstromming2.ogg', 'modular_bluemoon/sound/plush/surstromming3.ogg', 'modular_bluemoon/sound/plush/surstromming4.ogg', 'modular_bluemoon/sound/plush/surstromming5.ogg')
	playsound(T, pick(sur_sounds), 60, TRUE)

	M.SetStun(20) 
	
	new /obj/effect/decal/cleanable/vomit(T)
	
	to_chat(M, span_warning("Вас выворачивает наизнанку от ужасного вкуса сюрстрёмминга!"))
	M.visible_message(span_danger("[M] начинает бурно тошнить!"))
