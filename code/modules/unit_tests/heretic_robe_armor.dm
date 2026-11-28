/// У каждого пути своя броня мантии в общем бюджете и пределах.
/datum/unit_test/heretic_robe_armor_budget/Run()
	var/list/seen_profiles = list()
	var/datum/armor/base = new_tg_get_armor_by_type(/datum/armor/eldritch)
	for(var/path_id in GLOB.heretic_paths)
		var/armor_type = GLOB.heretic_robe_armor[path_id]
		TEST_ASSERT(ispath(armor_type, /datum/armor), "У пути [path_id] есть профиль брони мантии.")
		var/datum/armor/profile = new_tg_get_armor_by_type(armor_type)
		TEST_ASSERT_EQUAL(profile.melee + profile.bullet + profile.laser + profile.energy, HERETIC_ROBE_ARMOR_BUDGET, "Броня пути [path_id] укладывается в общий бюджет.")
		for(var/rating in list(MELEE, BULLET, LASER, ENERGY))
			var/value = profile.vars[rating]
			TEST_ASSERT(value >= HERETIC_ROBE_ARMOR_MIN && value <= HERETIC_ROBE_ARMOR_MAX, "[rating] пути [path_id] = [value], вне [HERETIC_ROBE_ARMOR_MIN]-[HERETIC_ROBE_ARMOR_MAX].")
		TEST_ASSERT(profile.bullet <= HERETIC_ROBE_BULLET_MAX, "Защита от пуль пути [path_id] выше [HERETIC_ROBE_BULLET_MAX].")
		TEST_ASSERT(profile != base, "Броня пути [path_id] отличается от общей.")
		TEST_ASSERT(!(profile in seen_profiles), "Броня пути [path_id] повторяет броню пути [seen_profiles[profile]].")
		seen_profiles[profile] = path_id
		TEST_ASSERT(findtext(heretic_robe_armor_traits(path_id), "против"), "У пути [path_id] есть строка о сильной и слабой стороне мантии.")
	var/datum/eldritch_knowledge/armor/knowledge = new
	var/expected = "Путь делит [HERETIC_ROBE_ARMOR_BUDGET]% защиты между ударами, пулями, лазерами и энергией: от [HERETIC_ROBE_ARMOR_MIN] до [HERETIC_ROBE_ARMOR_MAX]% на каждое."
	var/actual = knowledge.details[1]
	qdel(knowledge)
	TEST_ASSERT_EQUAL(actual, expected, "Кодекс называет бюджет и пределы брони из дефайнов.")

/// Броня мантии следует за путём надевшего еретика, у неверного и без пути она общая; капюшон держит свою.
/datum/unit_test/heretic_robe_armor_follows_path/Run()
	var/datum/antagonist/heretic/ash = allocate_heretic()
	ash.selected_path = PATH_ASH
	var/datum/antagonist/heretic/glass = allocate_heretic(run_loc_floor_top_right)
	glass.selected_path = PATH_GLASS
	var/datum/antagonist/heretic/pathless = allocate_heretic(run_loc_floor_top_right)
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	var/datum/armor/base = new_tg_get_armor_by_type(/datum/armor/eldritch)
	TEST_ASSERT_EQUAL(robes.armor, base, "Новая мантия носит общую броню.")
	var/datum/armor/hood_armor = new_tg_get_armor_by_type(/datum/armor/cult_shield)
	TEST_ASSERT_EQUAL(robes.hood.armor, hood_armor, "Капюшон носит свою броню.")

	var/mob/living/carbon/human/ash_body = ash.owner.current
	TEST_ASSERT(ash_body.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Еретик Пепла надевает мантию.")
	var/datum/armor/ash_armor = new_tg_get_armor_by_type(/datum/armor/heretic_ash)
	TEST_ASSERT_EQUAL(robes.armor, ash_armor, "Мантия получает броню Пепла.")
	TEST_ASSERT_EQUAL(robes.hood.armor, hood_armor, "Путь не меняет броню капюшона.")
	TEST_ASSERT_EQUAL(ash_body.run_armor_check(ash_body.get_bodypart(BODY_ZONE_CHEST), LASER, silent = TRUE), ash_armor.laser, "Броня пути действует на теле.")
	var/datum/heretic_path/ash_path = GLOB.heretic_paths[PATH_ASH]
	TEST_ASSERT(findtext(jointext(robes.examine(ash_body), "\n"), "«[ash_path.name]»"), "Осмотр называет путь брони.")
	TEST_ASSERT(ash_body.transferItemToLoc(robes, run_loc_floor_bottom_left), "Мантию снимают.")
	TEST_ASSERT_EQUAL(robes.armor, ash_armor, "Брошенная мантия хранит броню последнего еретика.")

	var/mob/living/carbon/human/glass_body = glass.owner.current
	TEST_ASSERT(glass_body.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Еретик Стекла надевает чужую мантию.")
	var/datum/armor/glass_armor = new_tg_get_armor_by_type(/datum/armor/heretic_glass)
	TEST_ASSERT_EQUAL(robes.armor, glass_armor, "Мантия перекраивается под Стекло.")
	TEST_ASSERT_EQUAL(robes.hood.armor, hood_armor, "Смена пути не трогает капюшон.")
	TEST_ASSERT(glass_body.transferItemToLoc(robes, run_loc_floor_bottom_left), "Мантию снимают снова.")

	TEST_ASSERT(bystander.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантию надевает неверный.")
	TEST_ASSERT_EQUAL(robes.armor, base, "На неверном броня общая.")
	TEST_ASSERT_EQUAL(robes.hood.armor, hood_armor, "На неверном капюшон тот же.")
	TEST_ASSERT_EQUAL(robes.robe_path, PATH_GLASS, "Облик при этом остаётся прежним.")
	TEST_ASSERT(bystander.transferItemToLoc(robes, run_loc_floor_bottom_left), "Неверный снимает мантию.")

	TEST_ASSERT(glass_body.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Еретик Стекла возвращает мантию.")
	TEST_ASSERT(glass_body.transferItemToLoc(robes, run_loc_floor_bottom_left), "И снимает её.")
	var/mob/living/carbon/human/pathless_body = pathless.owner.current
	TEST_ASSERT(pathless_body.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Еретик без пути надевает мантию.")
	TEST_ASSERT_EQUAL(robes.armor, base, "Без пути броня общая.")
	TEST_ASSERT_NULL(robes.armor_path, "Без пути броня не привязана к пути.")

	pathless.selected_path = PATH_RUST
	pathless.attune_robes(pathless_body)
	TEST_ASSERT_EQUAL(robes.armor, new_tg_get_armor_by_type(/datum/armor/heretic_rust), "Выбор пути перекраивает уже надетую мантию.")

/// Смена пути меняет только вклад профиля: вшитая прибавка остаётся.
/datum/unit_test/heretic_robe_armor_keeps_modifiers/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLADE
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	robes.normal_set_armor(robes.armor.modifyRating(melee = 10, rad = 5))
	robes.attune_robes(heretic.owner.current)
	var/datum/armor/blade_armor = new_tg_get_armor_by_type(/datum/armor/heretic_blade)
	TEST_ASSERT_EQUAL(robes.armor.melee, blade_armor.melee + 10, "Прибавка к ударам переживает настройку.")
	TEST_ASSERT_EQUAL(robes.armor.rad, blade_armor.rad + 5, "Прибавка к радиации переживает настройку.")
	TEST_ASSERT_EQUAL(robes.armor.laser, blade_armor.laser, "Остальное берётся из профиля пути.")
