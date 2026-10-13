/// Мантия каждого пути, мантия без пути, плащ и маска Пустоты и кристалл завесы видны в обеих руках.
/datum/unit_test/heretic_fin_set_inhands/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/list/held_items = list(
		allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch),
		allocate(/obj/item/clothing/suit/hooded/cultrobes/void),
		allocate(/obj/item/clothing/mask/gas/void_mask),
		allocate(/obj/item/heretic_veil_crystal),
	)
	for(var/path_id in GLOB.heretic_paths)
		heretic.selected_path = path_id
		var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
		TEST_ASSERT(robes.attune_robes(wearer), "Мантия принимает путь [path_id].")
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT_EQUAL(robes.item_state, path.robe_state, "В руках свёрнута мантия пути [path_id].")
		held_items += robes
	for(var/obj/item/item as anything in held_items)
		for(var/hand_icon in list(item.lefthand_file, item.righthand_file))
			var/mutable_appearance/held = item.build_worn_icon(default_icon_file = hand_icon, isinhands = TRUE)
			TEST_ASSERT(held.icon_state in icon_states(held.icon), "[item.type] ([held.icon_state]) виден в руке из [hand_icon].")

/// Поднятый капюшон не трогает значок мантии, а на теле `_t` берётся только там, где он отличается от опущенного.
/datum/unit_test/heretic_fin_robe_raised_hood/Run()
	for(var/state in icon_states('modular_bluemoon/icons/obj/heretic_robes.dmi'))
		TEST_ASSERT(copytext(state, length(state) - 1) != "_t", "В листе мантий на полу нет копии [state] под поднятый капюшон.")
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантия надета.")
	robes.ToggleHood()
	TEST_ASSERT_EQUAL(wearer.head, robes.hood, "Капюшон поднят.")
	for(var/path_id in GLOB.heretic_paths)
		heretic.selected_path = path_id
		robes.attune_robes(wearer)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/list/worn_states = icon_states(path.robe_worn_icon)
		var/raised_state = "[path.robe_state]_t"
		TEST_ASSERT_EQUAL(robes.icon_state, path.robe_state, "Значок мантии [path_id] в слоте не замирает на кадре под капюшон.")
		TEST_ASSERT(robes.icon_state in icon_states(robes.icon), "Значок мантии [path_id] есть в листе на полу.")
		TEST_ASSERT_EQUAL(path.robe_raised_state, (raised_state in worn_states), "Флаг поднятого капюшона [path_id] совпадает с листом на теле.")
		var/mutable_appearance/worn = wearer.overlays_standing[SUIT_LAYER]
		TEST_ASSERT_EQUAL(worn.icon_state, path.robe_raised_state ? raised_state : path.robe_state, "На теле [path_id] виден спрайт под поднятый капюшон.")
		TEST_ASSERT(worn.icon_state in worn_states, "Спрайт [worn.icon_state] есть в листе на теле.")
