/// Смена владельца, капюшон и падение на пол не возвращают мантию к общему спрайту.
/datum/unit_test/heretic_robe_appearance/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	var/datum/armor/original_armor = robes.armor
	var/original_coverage = robes.body_parts_covered
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	for(var/path_id in GLOB.heretic_paths)
		heretic.selected_path = path_id
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(wearer.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантию можно надеть.")
		TEST_ASSERT_EQUAL(robes.robe_path, path_id, "Мантия принимает путь владельца.")
		TEST_ASSERT_EQUAL(robes.icon_state, path.robe_state, "Опущенный капюшон выбирает основной спрайт.")
		TEST_ASSERT_EQUAL(robes.hood.icon_state, path.robe_state, "Капюшон соответствует мантии.")
		TEST_ASSERT_EQUAL(robes.mob_overlay_icon, path.robe_worn_icon, "Мантия загружает только лист своего пути.")
		TEST_ASSERT_EQUAL(robes.hood.mob_overlay_icon, path.hood_worn_icon, "Капюшон загружает только лист своего пути.")
		var/mutable_appearance/worn = wearer.overlays_standing[SUIT_LAYER]
		TEST_ASSERT_EQUAL(worn.icon_state, path.robe_state, "На теле виден выбранный путь.")
		TEST_ASSERT(worn.icon_state in icon_states(worn.icon), "Спрайт мантии существует в используемом рендерером DMI.")
		robes.ToggleHood()
		TEST_ASSERT_EQUAL(wearer.head, robes.hood, "Капюшон действительно надет.")
		TEST_ASSERT_EQUAL(robes.icon_state, "[path.robe_state]_t", "Поднятый капюшон выбирает второй спрайт.")
		worn = wearer.overlays_standing[SUIT_LAYER]
		TEST_ASSERT_EQUAL(worn.icon_state, robes.icon_state, "Переключение обновляет спрайт на теле.")
		TEST_ASSERT(worn.icon_state in icon_states(worn.icon), "У поднятого капюшона есть спрайт мантии.")
		var/mutable_appearance/head = wearer.overlays_standing[HEAD_LAYER]
		TEST_ASSERT(head.icon_state in icon_states(head.icon), "Капюшон имеет спрайт на голове.")
		TEST_ASSERT(wearer.transferItemToLoc(robes, run_loc_floor_bottom_left), "Мантию можно снять.")
		TEST_ASSERT_EQUAL(robes.icon_state, path.robe_state, "На полу остаётся облик пути с опущенным капюшоном.")
		TEST_ASSERT_EQUAL(robes.hood.loc, robes, "Снятый капюшон хранится в мантии.")
		TEST_ASSERT_NULL(wearer.head, "Капюшон не остаётся на голове после снятия мантии.")
		TEST_ASSERT_EQUAL(robes.armor, original_armor, "Визуальный путь не меняет защиту.")
		TEST_ASSERT_EQUAL(robes.body_parts_covered, original_coverage, "Облик не меняет покрытие тела.")
		TEST_ASSERT(bystander.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантию можно передать обычному члену экипажа.")
		TEST_ASSERT_EQUAL(robes.robe_path, path_id, "Непосвящённый сохраняет последний облик.")
		TEST_ASSERT(bystander.transferItemToLoc(robes, run_loc_floor_bottom_left), "Мантию можно вернуть еретику.")

/// Уже надетая мантия меняется вместе с первым исследованием, включая поднятый капюшон.
/datum/unit_test/heretic_robe_first_research/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантию можно надеть до выбора пути.")
	robes.ToggleHood()
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, wearer), "Первое знание выбирает Пепел.")
	TEST_ASSERT_EQUAL(robes.robe_path, PATH_ASH, "Первое исследование меняет уже надетую мантию.")
	TEST_ASSERT_EQUAL(robes.icon_state, "ash_armor_t", "Настройка сохраняет поднятый капюшон.")
	TEST_ASSERT_EQUAL(robes.hood.icon_state, "ash_armor", "Капюшон получает тот же путь.")

/// Оба спрайта в руках соответствуют собственному клинку, а не общему серпу или Пустоте.
/datum/unit_test/heretic_blade_inhand_appearance/Run()
	for(var/blade_type in subtypesof(/obj/item/melee/sickly_blade))
		var/obj/item/melee/sickly_blade/blade = allocate(blade_type)
		var/expected_x = (blade.route in list(PATH_TIDE, PATH_GLASS, PATH_BLOOD)) ? 0 : -9
		var/expected_y = (blade.route in list(PATH_TIDE, PATH_GLASS, PATH_BLOOD)) ? 0 : -8
		for(var/hand_icon in list(blade.lefthand_file, blade.righthand_file))
			var/mutable_appearance/held = blade.build_worn_icon(default_icon_file = hand_icon, isinhands = TRUE)
			TEST_ASSERT_EQUAL(held.icon_state, blade.icon_state, "Спрайт [blade.type] в руках должен соответствовать предмету.")
			TEST_ASSERT(held.icon_state in icon_states(held.icon), "Спрайт [blade.type] существует для каждой руки.")
			TEST_ASSERT_EQUAL(held.pixel_x, expected_x, "Спрайт сохраняет горизонтальное положение клинка в руке.")
			TEST_ASSERT_EQUAL(held.pixel_y, expected_y, "Спрайт сохраняет высоту клинка в руке.")

/// Глаз показывает действие именно этого амулета, а не чужого источника зрения.
/datum/unit_test/heretic_medallion_appearance/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	for(var/amulet_type in list(/obj/item/clothing/neck/eldritch_amulet, /obj/item/clothing/neck/eldritch_amulet/piercing))
		var/obj/item/clothing/neck/eldritch_amulet/amulet = allocate(amulet_type, run_loc_floor_bottom_left)
		TEST_ASSERT_EQUAL(amulet.icon_state, "watching_eye_closed", "На полу медальон спит.")
		TEST_ASSERT(wearer.equip_to_slot_if_possible(amulet, ITEM_SLOT_NECK), "Еретик надевает медальон.")
		TEST_ASSERT(HAS_TRAIT_FROM(wearer, amulet.trait, REF(amulet)), "Медальон даёт своё прежнее зрение.")
		var/expected_state = amulet.trait == TRAIT_XRAY_VISION ? "watching_eye_open" : "watching_eye"
		TEST_ASSERT_EQUAL(amulet.icon_state, expected_state, "Степень раскрытия глаза соответствует виду зрения.")
		var/mutable_appearance/worn = wearer.overlays_standing[NECK_LAYER]
		TEST_ASSERT_EQUAL(worn.icon_state, expected_state, "Глаз раскрывается на шее сразу после надевания.")
		TEST_ASSERT(worn.icon_state in icon_states(worn.icon), "Новая иконка в инвентаре не делает подвеску невидимой на теле.")
		TEST_ASSERT(wearer.transferItemToLoc(amulet, run_loc_floor_bottom_left), "Медальон можно снять.")
		TEST_ASSERT_EQUAL(amulet.icon_state, "watching_eye_closed", "Снятый глаз закрывается.")
		TEST_ASSERT(!HAS_TRAIT_FROM(wearer, amulet.trait, REF(amulet)), "Снятый медальон больше не даёт зрение.")
		TEST_ASSERT(bystander.equip_to_slot_if_possible(amulet, ITEM_SLOT_NECK), "Медальон можно передать обычному члену экипажа.")
		TEST_ASSERT_EQUAL(amulet.icon_state, "watching_eye_closed", "У непосвящённого глаз остаётся закрыт.")
		TEST_ASSERT(!HAS_TRAIT_FROM(bystander, amulet.trait, REF(amulet)), "Облик не даёт непосвящённому силу амулета.")
		TEST_ASSERT(bystander.transferItemToLoc(amulet, run_loc_floor_bottom_left), "Подвеска освобождает слот для следующего медальона.")

/// Убираем временную печать и при перемещении компонента, и при уничтожении самой руны.
/datum/unit_test/heretic_ritual_visual_cleanup
	var/obj/effect/temp_visual/heretic_ritual/observed_visual

/datum/unit_test/heretic_ritual_visual_cleanup/proc/interrupt_ritual(obj/effect/eldritch/rune, obj/item/ingredient, destroy_rune)
	observed_visual = rune.ritual_visual
	if(destroy_rune)
		qdel(rune)
	else
		ingredient.forceMove(get_step(run_loc_floor_bottom_left, NORTH))

/datum/unit_test/heretic_ritual_visual_cleanup/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	heretic.selected_path = PATH_BLADE
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen)
	recipe.result_atoms = list(/obj/item/pen)
	recipe.ritual_time = 0.5 SECONDS
	heretic.researched_knowledge[recipe.type] = recipe
	var/obj/item/pen/ingredient = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	for(var/destroy_rune in list(FALSE, TRUE))
		ingredient.forceMove(run_loc_floor_bottom_left)
		var/obj/effect/eldritch/big/visual_cleanup_fixture/rune = allocate(/obj/effect/eldritch/big/visual_cleanup_fixture, run_loc_floor_bottom_left)
		observed_visual = null
		rune.interruption = CALLBACK(src, PROC_REF(interrupt_ritual), rune, ingredient, destroy_rune)
		TEST_ASSERT(!rune.do_ritual(user, recipe), "Внешнее вмешательство прерывает обряд.")
		TEST_ASSERT_NOTNULL(observed_visual, "Во время обряда была видна временная печать.")
		TEST_ASSERT(QDELETED(observed_visual), "Прерванный обряд сразу освобождает временную печать.")
		TEST_ASSERT_NULL(rune.ritual_visual, "Руна не хранит ссылку на завершившийся эффект.")
		TEST_ASSERT(!QDELETED(ingredient), "Прерывание не расходует компонент.")
		if(!QDELETED(rune))
			qdel(rune)
	var/list/endings = list()
	for(var/obj/effect/temp_visual/heretic_ritual/erase/ending in run_loc_floor_bottom_left)
		endings += ending
	TEST_ASSERT(length(endings), "После прерывания знаки стираются.")
	for(var/obj/effect/temp_visual/heretic_ritual/erase/ending as anything in endings)
		TEST_ASSERT(wait_for_qdeleted(ending), "Стирание заканчивается и не оставляет объект на полу.")

/obj/effect/eldritch/big/visual_cleanup_fixture
	var/datum/callback/interruption

/obj/effect/eldritch/big/visual_cleanup_fixture/ritual_valid(mob/living/user, datum/eldritch_knowledge/ritual)
	if(interruption && ritual_visual)
		var/datum/callback/interrupt_now = interruption
		interruption = null
		interrupt_now.Invoke()
	return ..()

/obj/effect/eldritch/big/visual_cleanup_fixture/Destroy()
	interruption = null
	return ..()

/// Метка Ржавчины видна над телом, переживает обновление внешности и исчезает при снятии.
/datum/unit_test/heretic_rust_mark_appearance/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/status_effect/eldritch/rust/mark = victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	TEST_ASSERT(mark, "Живая цель получает метку Ржавчины.")
	TEST_ASSERT_EQUAL(mark.marked_underlay.icon_state, "sigil_rust", "Метка использует читаемый знак Ржавчины.")
	TEST_ASSERT(mark.marked_underlay.layer > MOB_LAYER, "Тело не закрывает знак метки.")
	victim.update_icon()
	var/mark_count = 0
	for(var/image/overlay as anything in victim.overlays)
		if(overlay.icon_state == "sigil_rust")
			mark_count++
	TEST_ASSERT_EQUAL(mark_count, 1, "Обновление внешности сохраняет ровно один знак.")
	TEST_ASSERT_EQUAL(mark.linked_alert?.name, "Метка Ржавчины", "HUD называет наложенную метку по-русски.")
	TEST_ASSERT_EQUAL(mark.linked_alert?.icon, 'modular_bluemoon/icons/obj/heretic_alerts.dmi', "HUD метки использует отдельный лист значков.")
	victim.remove_status_effect(/datum/status_effect/eldritch/rust)
	for(var/image/overlay as anything in victim.overlays)
		TEST_ASSERT(overlay.icon_state != "sigil_rust", "Снятая метка не оставляет ложный знак на теле.")

/// Перенесённая из слота без dropped() маска прекращает обработку до сканирования наблюдателей.
/datum/unit_test/heretic_mask_stale_wearer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/obj/item/clothing/mask/gas/void_mask/mask = allocate(/obj/item/clothing/mask/gas/void_mask)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Маска надевается и запоминает носителя.")
	TEST_ASSERT_EQUAL(mask.local_user, wearer, "Носитель записывается при надевании.")
	wearer.wear_mask = null
	TEST_ASSERT_EQUAL(mask.process(1), PROCESS_KILL, "Маска вне слота больше не действует от имени прежнего носителя.")
	TEST_ASSERT_NULL(mask.local_user, "Старая ссылка на носителя очищается.")

/// Удаление маски снимает выданный ею иммунитет до отмены таймеров.
/datum/unit_test/heretic_mask_destroy_clears_immunity/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/clothing/mask/gas/void_mask/mask = allocate(/obj/item/clothing/mask/gas/void_mask)
	ADD_TRAIT(target, TRAIT_VOID_MASK_IMMUNE, VOID_MASK_TRAIT)
	mask.cooldown_targets += target
	addtimer(CALLBACK(mask, TYPE_PROC_REF(/obj/item/clothing/mask/gas/void_mask, remove_immunity), target), 10 SECONDS, TIMER_STOPPABLE)
	qdel(mask)
	TEST_ASSERT(!HAS_TRAIT(target, TRAIT_VOID_MASK_IMMUNE), "Удалённая маска не оставляет постоянный иммунитет.")
