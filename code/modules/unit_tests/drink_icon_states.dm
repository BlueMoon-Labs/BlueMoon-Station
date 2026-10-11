/// Каждый тип напитка рисуется стейтом, который есть в его иконке: иначе предмет невидим.
/datum/unit_test/drink_icon_states

/datum/unit_test/drink_icon_states/Run()
	var/list/states_by_icon = list()
	var/list/missing = list()
	for(var/obj/item/reagent_containers/food/drinks/drink_type as anything in typesof(/obj/item/reagent_containers/food/drinks))
		var/icon_file = initial(drink_type.icon)
		var/state = initial(drink_type.icon_state)
		if(!icon_file || !state)
			continue
		var/list/present = states_by_icon["[icon_file]"]
		if(isnull(present))
			present = icon_states(icon_file)
			states_by_icon["[icon_file]"] = present
		if(!(state in present))
			missing += "[drink_type] ([icon_file]: [state])"
	TEST_ASSERT(!length(missing), "Нет стейтов: [jointext(missing, ", ")]")
