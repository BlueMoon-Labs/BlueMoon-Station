/obj/item/storage/basket
	name = "плетёная корзина"
	desc = "Настоящий образец классического подводного плетения корзин."
	icon = 'icons/mob/Easter.dmi'
	icon_state = "basket"
	force = 5

/datum/crafting_recipe/underwater_basket
	name = "Underwater Basket (Bamboo)"
	result = /obj/item/storage/basket
	time = 5 SECONDS
	reqs = list(/obj/item/stack/sheet/mineral/bamboo = 20)
	category = CAT_OTHER

/datum/crafting_recipe/underwater_basket/check_requirements(mob/user, list/collected_requirements)
	. = ..()
	if(!HAS_TRAIT(user, TRAIT_UNDERWATER_BASKETWEAVING_KNOWLEDGE))
		return FALSE
	var/turf/T = get_turf(user)
	if(istype(T, /turf/open/water))
		return TRUE
	var/obj/machinery/shower/S = locate() in T
	if(S?.on)
		return TRUE

/datum/crafting_recipe/underwater_basket/wheat
	name = "Underwater Basket (Wheat)"
	reqs = list(/obj/item/reagent_containers/food/snacks/grown/wheat = 50)
