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
		var/expected_x = (blade.route in list(PATH_TIDE, PATH_GLASS, PATH_BLOOD, PATH_SAND, PATH_WAX, PATH_SPIRIT)) ? 0 : -9
		var/expected_y = (blade.route in list(PATH_TIDE, PATH_GLASS, PATH_BLOOD, PATH_SAND, PATH_WAX, PATH_SPIRIT)) ? 0 : -8
		if(blade.route == PATH_ECHO)
			expected_x = 0
			expected_y = -4
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

/// Оба медальона принимают путь носителя и сохраняют его после снятия без выдачи лишнего зрения.
/datum/unit_test/heretic_medallion_path_appearance/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	for(var/amulet_type in list(/obj/item/clothing/neck/eldritch_amulet, /obj/item/clothing/neck/eldritch_amulet/piercing))
		var/obj/item/clothing/neck/eldritch_amulet/amulet = allocate(amulet_type, run_loc_floor_bottom_left)
		for(var/path_id in GLOB.heretic_paths)
			heretic.selected_path = path_id
			var/prefix = "[lowertext(path_id)]_"
			for(var/asset in list(amulet.icon, amulet.mob_overlay_icon, amulet.lefthand_file, amulet.righthand_file))
				var/list/states = icon_states(asset)
				for(var/state in list("watching_eye_closed", "watching_eye", "watching_eye_open"))
					TEST_ASSERT("[prefix][state]" in states, "У медальона [path_id] есть состояние [state] в каждом представлении.")
			TEST_ASSERT(wearer.equip_to_slot_if_possible(amulet, ITEM_SLOT_NECK), "Еретик надевает медальон.")
			TEST_ASSERT_EQUAL(amulet.amulet_path, path_id, "Медальон принимает новый путь при надевании.")
			var/active_state = amulet.trait == TRAIT_XRAY_VISION ? "watching_eye_open" : "watching_eye"
			TEST_ASSERT_EQUAL(amulet.icon_state, "[prefix][active_state]", "Рисунок показывает путь и вид зрения.")
			TEST_ASSERT(HAS_TRAIT_FROM(wearer, amulet.trait, REF(amulet)), "Новый облик сохраняет зрение медальона.")
			var/mutable_appearance/worn = wearer.overlays_standing[NECK_LAYER]
			TEST_ASSERT_EQUAL(worn.icon_state, amulet.icon_state, "Надетая подвеска сразу обновляется.")
			TEST_ASSERT(wearer.transferItemToLoc(amulet, run_loc_floor_bottom_left), "Медальон снимается.")
			TEST_ASSERT_EQUAL(amulet.icon_state, "[prefix]watching_eye_closed", "На полу остаётся спящий медальон выбранного пути.")
			TEST_ASSERT(!HAS_TRAIT_FROM(wearer, amulet.trait, REF(amulet)), "Снятый медальон больше не даёт зрение.")
			for(var/hand_icon in list(amulet.lefthand_file, amulet.righthand_file))
				var/mutable_appearance/held = amulet.build_worn_icon(default_icon_file = hand_icon, isinhands = TRUE)
				TEST_ASSERT_EQUAL(held.icon_state, amulet.icon_state, "В руках сохраняется облик спящей подвески.")
				TEST_ASSERT(held.icon_state in icon_states(held.icon), "Медальон виден в каждой руке.")
			TEST_ASSERT(bystander.equip_to_slot_if_possible(amulet, ITEM_SLOT_NECK), "Обычный человек может надеть подвеску.")
			TEST_ASSERT_EQUAL(amulet.amulet_path, path_id, "Непосвящённый сохраняет прежний рисунок.")
			TEST_ASSERT_EQUAL(amulet.icon_state, "[prefix]watching_eye_closed", "На непосвящённом медальон не просыпается.")
			TEST_ASSERT(!HAS_TRAIT_FROM(bystander, amulet.trait, REF(amulet)), "Изменение рисунка не выдаёт силу непосвящённому.")
			TEST_ASSERT(bystander.transferItemToLoc(amulet, run_loc_floor_bottom_left), "Подвеска освобождает слот.")

/// Первое исследование меняет медальоны на шее и в сумке, сохраняя различие между надетым и снятым.
/datum/unit_test/heretic_medallion_first_research/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/wearer = heretic.owner.current
	var/obj/item/clothing/neck/eldritch_amulet/worn = allocate(/obj/item/clothing/neck/eldritch_amulet)
	var/obj/item/storage/backpack/backpack = allocate(/obj/item/storage/backpack, wearer)
	var/obj/item/clothing/neck/eldritch_amulet/piercing/carried = allocate(/obj/item/clothing/neck/eldritch_amulet/piercing, backpack)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(worn, ITEM_SLOT_NECK), "Медальон надевается до выбора пути.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, wearer), "Первое знание выбирает Пепел.")
	TEST_ASSERT_EQUAL(worn.amulet_path, PATH_ASH, "Медальон на шее принимает Пепел.")
	TEST_ASSERT_EQUAL(worn.icon_state, "ash_watching_eye", "Надетый медальон остаётся активным.")
	var/mutable_appearance/neck = wearer.overlays_standing[NECK_LAYER]
	TEST_ASSERT_EQUAL(neck.icon_state, worn.icon_state, "Исследование обновляет подвеску на теле.")
	TEST_ASSERT_EQUAL(carried.amulet_path, PATH_ASH, "Медальон в сумке принимает тот же путь.")
	TEST_ASSERT_EQUAL(carried.icon_state, "ash_watching_eye_closed", "Снятый медальон остаётся спящим.")
	TEST_ASSERT(!HAS_TRAIT_FROM(wearer, carried.trait, REF(carried)), "Исследование не активирует медальон в сумке.")

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

/// Листы руны содержат все состояния, у каждого пути есть знак и вспышка, руна красится чернилами пути, завершённое начертание не рассыпается пылью.
/datum/unit_test/heretic_rune_visual_states/Run()
	var/list/rune_states = icon_states('modular_bluemoon/icons/obj/heretic_rune.dmi')
	var/list/visual_states = icon_states('modular_bluemoon/icons/obj/heretic_rune_visuals.dmi')
	for(var/state in list("rune", "rune_active"))
		TEST_ASSERT(state in rune_states, "В листе руны нет состояния [state].")
	for(var/state in list(HERETIC_RUNE_VISUAL_TRACE, HERETIC_RUNE_VISUAL_RITUAL, HERETIC_RUNE_VISUAL_ERASE, HERETIC_RUNE_VISUAL_SCATTER, HERETIC_RUNE_VISUAL_RELEASE))
		TEST_ASSERT(state in visual_states, "В листе эффектов руны нет состояния [state].")
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/each_path = GLOB.heretic_paths[path_id]
		var/list/inscriptions = icon_states(each_path.rune_inscription_icon)
		var/list/casts = icon_states(each_path.rune_cast_icon)
		for(var/suffix in list("_draw", "_idle", "_erase"))
			TEST_ASSERT("[each_path.rune_inscription][suffix]" in inscriptions, "У пути [path_id] нет знака [each_path.rune_inscription][suffix].")
		TEST_ASSERT("[each_path.rune_inscription]_cast" in casts, "У пути [path_id] нет вспышки [each_path.rune_inscription]_cast.")
		var/mutable_appearance/mark = heretic_rune_inscription_overlay("[each_path.rune_inscription]_idle", each_path.rune_inscription_icon)
		TEST_ASSERT_EQUAL(mark.icon, each_path.rune_inscription_icon, "Знак пути [path_id] использует свой лист.")
	var/obj/effect/eldritch/big/rune = allocate(/obj/effect/eldritch/big, run_loc_floor_bottom_left)
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	rune.inscribe_path(PATH_ASH)
	TEST_ASSERT_EQUAL(rune.color, path.book_ink, "Руна принимает чернила пути.")
	var/found_mark = FALSE
	for(var/mutable_appearance/overlay in rune.update_overlays())
		if(overlay.icon_state != "[path.rune_inscription]_idle")
			continue
		found_mark = TRUE
		TEST_ASSERT_EQUAL(overlay.pixel_x, 16, "Знак пути стоит в центре полотна 96x96.")
		TEST_ASSERT_EQUAL(overlay.pixel_y, 16, "Знак пути стоит в центре полотна 96x96.")
		TEST_ASSERT(overlay.appearance_flags & RESET_COLOR, "Чернила руны не красят знак пути.")
	TEST_ASSERT(found_mark, "Руна несёт знак своего пути.")
	var/turf/trace_turf = get_step(run_loc_floor_bottom_left, NORTH)
	var/obj/effect/temp_visual/heretic_ritual/trace = new(trace_turf, PATH_ASH, 9 SECONDS, HERETIC_RUNE_VISUAL_TRACE)
	TEST_ASSERT_EQUAL(trace.icon_state, HERETIC_RUNE_VISUAL_TRACE, "Начертание показывает растекание смолы.")
	TEST_ASSERT_EQUAL(trace.color, path.book_ink, "Начертание идёт чернилами пути.")
	TEST_ASSERT_NULL(trace.inscription_state, "Знак пути не проступает в начале начертания.")
	trace.show_inscription("[path.rune_inscription]_draw")
	TEST_ASSERT_EQUAL(length(trace.overlays), 1, "После задержки поверх смолы прорисовывается знак пути.")
	trace.finish()
	TEST_ASSERT(QDELETED(trace), "Завершённое начертание исчезает сразу.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_ritual/erase) in trace_turf, "Завершённое начертание не оставляет пыли.")
	trace = new(trace_turf, PATH_ASH, 9 SECONDS, HERETIC_RUNE_VISUAL_TRACE)
	qdel(trace)
	var/obj/effect/temp_visual/heretic_ritual/erase/dust = locate() in trace_turf
	TEST_ASSERT_NOTNULL(dust, "Прерванное начертание рассыпается.")
	allocated += dust
	TEST_ASSERT_EQUAL(dust.icon_state, HERETIC_RUNE_VISUAL_SCATTER, "Прерванное начертание показывает разлёт пыли, а не стирание руны.")
	TEST_ASSERT_NULL(dust.inscription_state, "Пыль не стирает знак, которого ещё не было.")
	var/obj/effect/temp_visual/heretic_ritual/glow = new(trace_turf, PATH_ASH, 5 SECONDS, HERETIC_RUNE_VISUAL_RITUAL, rune)
	qdel(glow)
	var/found_release = FALSE
	for(var/obj/effect/temp_visual/heretic_ritual/erase/ending in trace_turf)
		if(ending.icon_state == HERETIC_RUNE_VISUAL_RELEASE)
			found_release = TRUE
		allocated |= ending
	TEST_ASSERT(found_release, "Конец обряда отпускает свет руны.")
	var/turf/erase_turf = get_step(run_loc_floor_bottom_left, EAST)
	var/obj/effect/temp_visual/heretic_ritual/erase/wipe = new(erase_turf, PATH_ASH, null, HERETIC_RUNE_VISUAL_ERASE, rune)
	allocated += wipe
	TEST_ASSERT_EQUAL(wipe.inscription_state, "[path.rune_inscription]_erase", "Стирание руны стирает и знак пути.")
	var/obj/effect/temp_visual/heretic_cast/cast = new(erase_turf, PATH_WAX, rune)
	allocated += cast
	TEST_ASSERT_EQUAL(cast.icon_state, "wax_seal_cast", "Вспышка берёт знак выбранного пути.")
	var/datum/heretic_path/wax_path = GLOB.heretic_paths[PATH_WAX]
	TEST_ASSERT_EQUAL(cast.icon, wax_path.rune_cast_icon, "Вспышка воска использует отдельный лист новых путей.")
