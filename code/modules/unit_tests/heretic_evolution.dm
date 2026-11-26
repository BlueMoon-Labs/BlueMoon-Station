/// Подставные листы облика пути на время теста: стейты схемы по именам, без настоящего арта.
/datum/heretic_evolution_test_sheet
	var/datum/heretic_path/path
	var/list/saved

/datum/heretic_evolution_test_sheet/New(path_id)
	path = GLOB.heretic_paths[path_id]
	saved = list(path.evolution_icon, path.evolution_icon_64, path.evolution_states, path.evolution_states_64)

/datum/heretic_evolution_test_sheet/proc/install(list/states, list/big_states)
	path.evolution_icon = heretic_evolution_test_icon(states, 1)
	path.evolution_icon_64 = heretic_evolution_test_icon(big_states, 2)
	path.evolution_states = null
	path.evolution_states_64 = null

/datum/heretic_evolution_test_sheet/Destroy()
	path.evolution_icon = saved[1]
	path.evolution_icon_64 = saved[2]
	path.evolution_states = saved[3]
	path.evolution_states_64 = saved[4]
	path = null
	return ..()

/proc/heretic_evolution_test_icon(list/states, scale)
	var/icon/sheet = new
	for(var/state in states)
		var/icon/frame = icon('icons/effects/effects.dmi', "nothing")
		if(scale > 1)
			frame.Crop(1, 1, world.icon_size * scale, world.icon_size * scale)
		sheet.Insert(frame, state)
	return sheet

/// Все стейты схемы для трёх ступеней; крупный лист - только поверх одежды и всплеск.
/datum/unit_test/proc/evolution_sheet(path_id, list/extra_states)
	var/key = lowertext(path_id)
	var/list/states = list()
	for(var/tier in 1 to 3)
		states += list("[key]_evo[tier]", "[key]_evo[tier]_open", "[key]_evo[tier]_face")
	states += list("[key]_evo3_over", "[key]_evo2_burst_face")
	if(extra_states)
		states += extra_states
	var/datum/heretic_evolution_test_sheet/sheet
	for(var/datum/heretic_evolution_test_sheet/existing in allocated)
		if(existing.path.id == path_id)
			sheet = existing
	if(!sheet)
		sheet = new(path_id)
		allocated += sheet
	sheet.install(states, list("[key]_evo2_burst", "[key]_evo3_over"))
	return sheet

/// Изучает ступени пути по порядку, как кодекс.
/datum/unit_test/proc/evolution_research(datum/antagonist/heretic/heretic, stage)
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic.selected_path]
	heretic.knowledge_points = 100
	for(var/attempt in 1 to length(path.knowledge))
		if(heretic.path_stage >= stage)
			return
		heretic.research_knowledge(path.knowledge[heretic.path_stage + 1], heretic.owner.current)

/// Слои облика, которые сейчас действительно лежат на теле, по имени стейта.
/proc/heretic_evolution_test_looks(mob/living/carbon/human/user)
	. = list()
	var/list/managed = islist(user.managed_overlays) ? user.managed_overlays : list(user.managed_overlays)
	for(var/mutable_appearance/look as anything in managed)
		if(look)
			.[look.icon_state] = look

/proc/heretic_evolution_test_seen(mob/living/carbon/human/user, mob/witness)
	return jointext(user.examine(witness), " ")

/// Облик меняется после четвёртого и седьмого знания пути, с вознесением становится явным.
/datum/unit_test/heretic_evolution_stages/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	evolution_sheet(PATH_ASH)
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE - 1)
	TEST_ASSERT_EQUAL(heretic.path_stage, HERETIC_EVOLUTION_FIRST_STAGE - 1, "Ступени изучаются по порядку.")
	TEST_ASSERT_EQUAL(heretic.evolution_tier(), 0, "До четвёртого знания облик не меняется.")
	TEST_ASSERT(!length(heretic_evolution_test_looks(user) & list("ash_evo1", "ash_evo1_open", "ash_evo1_face")), "До первой ступени облика на теле ничего нет.")
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE)
	var/list/looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(("ash_evo1" in looks) && ("ash_evo1_open" in looks) && ("ash_evo1_face" in looks), "Четвёртое знание даёт первую ступень облика.")
	TEST_ASSERT(!("ash_evo2" in looks), "Вторая ступень ещё не наступила.")
	evolution_research(heretic, HERETIC_EVOLUTION_SECOND_STAGE)
	looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(("ash_evo2" in looks) && !("ash_evo1" in looks), "Седьмое знание сменяет первую ступень второй.")
	TEST_ASSERT(!("ash_evo3_over" in looks), "До вознесения поверх одежды ничего нет.")
	user.apply_status_effect(/datum/status_effect/heretic_ascended)
	looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(!("ash_evo3" in looks), "Без вознесения роли статус ступень не поднимает.")
	heretic.ascended = TRUE
	user.remove_status_effect(/datum/status_effect/heretic_ascended)
	user.apply_status_effect(/datum/status_effect/heretic_ascended)
	looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(("ash_evo3" in looks) && ("ash_evo3_face" in looks), "Вознесение даёт третью ступень.")
	var/mutable_appearance/over = looks["ash_evo3_over"]
	TEST_ASSERT(over?.pixel_x == HERETIC_EVOLUTION_BIG_OFFSET && over.pixel_y == HERETIC_EVOLUTION_BIG_OFFSET, "Поверх одежды крупный лист 64x64 берётся первым и стоит по центру тела.")
	TEST_ASSERT_EQUAL(over.layer, -BODY_FRONT_LAYER, "Третья ступень поверх одежды.")
	user.remove_status_effect(/datum/status_effect/heretic_ascended)

/// Кожа лежит под одеждой, кисти - под перчатками, лицо прячут маска, капюшон, забрало и очки.
/datum/unit_test/heretic_evolution_cover/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	evolution_sheet(PATH_ASH)
	evolution_research(heretic, HERETIC_EVOLUTION_SECOND_STAGE)
	var/list/looks = heretic_evolution_test_looks(user)
	var/mutable_appearance/skin = looks["ash_evo2"]
	TEST_ASSERT_EQUAL(skin?.layer, -BODY_ADJ_LAYER, "Кожа облика под одеждой.")
	var/mutable_appearance/hands = looks["ash_evo2_open"]
	TEST_ASSERT_EQUAL(hands?.layer, -HERETIC_EVOLUTION_HANDS_LAYER, "Кисти облика над кистями тела и под перчатками.")
	var/mutable_appearance/face = looks["ash_evo2_face"]
	TEST_ASSERT_EQUAL(face?.layer, -HERETIC_EVOLUTION_FACE_LAYER, "Лицо облика над волосами и под маской.")
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	TEST_ASSERT(user.equip_to_slot_if_possible(gloves, ITEM_SLOT_GLOVES), "Перчатки надеты.")
	TEST_ASSERT(!("ash_evo2_open" in heretic_evolution_test_looks(user)), "Перчатки прячут кисти целиком.")
	TEST_ASSERT("ash_evo2" in heretic_evolution_test_looks(user), "Кожа под одеждой остаётся.")
	user.dropItemToGround(gloves)
	TEST_ASSERT("ash_evo2_open" in heretic_evolution_test_looks(user), "Снятые перчатки открывают кисти.")
	var/obj/item/clothing/mask/gas/gas_mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(user.equip_to_slot_if_possible(gas_mask, ITEM_SLOT_MASK), "Противогаз надет.")
	TEST_ASSERT(!("ash_evo2_face" in heretic_evolution_test_looks(user)), "Противогаз прячет лицо.")
	user.dropItemToGround(gas_mask)
	TEST_ASSERT("ash_evo2_face" in heretic_evolution_test_looks(user), "Снятый противогаз открывает лицо.")
	var/obj/item/clothing/mask/breath/breath = allocate(/obj/item/clothing/mask/breath)
	TEST_ASSERT(user.equip_to_slot_if_possible(breath, ITEM_SLOT_MASK), "Дыхательная маска надета.")
	TEST_ASSERT(!("ash_evo2_face" in heretic_evolution_test_looks(user)), "Маска на рту прячет лицо.")
	breath.adjustmask(user)
	TEST_ASSERT("ash_evo2_face" in heretic_evolution_test_looks(user), "Сдвинутая маска открывает лицо.")
	user.dropItemToGround(breath)
	var/obj/item/clothing/head/welding/welding = allocate(/obj/item/clothing/head/welding)
	TEST_ASSERT(user.equip_to_slot_if_possible(welding, ITEM_SLOT_HEAD), "Сварочная маска надета.")
	TEST_ASSERT(!("ash_evo2_face" in heretic_evolution_test_looks(user)), "Опущенное забрало прячет лицо.")
	welding.weldingvisortoggle(user)
	TEST_ASSERT("ash_evo2_face" in heretic_evolution_test_looks(user), "Поднятое забрало открывает лицо.")
	user.dropItemToGround(welding)
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	TEST_ASSERT(user.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантия надета.")
	TEST_ASSERT("ash_evo2_face" in heretic_evolution_test_looks(user), "Мантия без капюшона лицо не прячет.")
	robes.ToggleHood()
	TEST_ASSERT(!("ash_evo2_face" in heretic_evolution_test_looks(user)), "Поднятый капюшон прячет лицо.")
	robes.ToggleHood()
	TEST_ASSERT("ash_evo2_face" in heretic_evolution_test_looks(user), "Опущенный капюшон открывает лицо.")
	user.dropItemToGround(robes)
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	TEST_ASSERT(user.equip_to_slot_if_possible(shades, ITEM_SLOT_EYES), "Очки надеты.")
	TEST_ASSERT(!("ash_evo2_face" in heretic_evolution_test_looks(user)), "Глаза в общем лице прячут и очки.")
	evolution_sheet(PATH_ASH, list("ash_evo2_eyes"))
	heretic.refresh_evolution()
	looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(("ash_evo2_face" in looks) && !("ash_evo2_eyes" in looks), "Отдельные глаза уходят под очки, а лицо остаётся.")
	user.dropItemToGround(shades)
	TEST_ASSERT("ash_evo2_eyes" in heretic_evolution_test_looks(user), "Снятые очки открывают глаза.")

/// Макушка (шапка воска и фитиль) прячется под капюшоном, но не под противогазом, который закрывает только лицо.
/datum/unit_test/heretic_evolution_head/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	evolution_sheet(PATH_ASH, list("ash_evo2_head"))
	evolution_research(heretic, HERETIC_EVOLUTION_SECOND_STAGE)
	var/mutable_appearance/head = heretic_evolution_test_looks(user)["ash_evo2_head"]
	TEST_ASSERT_EQUAL(head?.layer, -HERETIC_EVOLUTION_FACE_LAYER, "Макушка облика лежит слоем лица, под уборами.")
	var/obj/item/clothing/mask/gas/gas_mask = allocate(/obj/item/clothing/mask/gas)
	TEST_ASSERT(user.equip_to_slot_if_possible(gas_mask, ITEM_SLOT_MASK), "Противогаз надет.")
	var/list/looks = heretic_evolution_test_looks(user)
	TEST_ASSERT(!("ash_evo2_face" in looks) && ("ash_evo2_head" in looks), "Противогаз прячет лицо, но не макушку.")
	TEST_ASSERT(!heretic.evolution.part_hidden(HERETIC_EVOLUTION_HAIR), "Строка осмотра макушки видна над противогазом.")
	user.dropItemToGround(gas_mask)
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	TEST_ASSERT(user.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантия надета.")
	robes.ToggleHood()
	TEST_ASSERT(!("ash_evo2_head" in heretic_evolution_test_looks(user)), "Поднятый капюшон прячет макушку.")
	robes.ToggleHood()
	TEST_ASSERT("ash_evo2_head" in heretic_evolution_test_looks(user), "Опущенный капюшон открывает макушку.")

/// Всплеск ступени держится миг, идёт только от способностей пути и не чаще отката.
/datum/unit_test/heretic_evolution_burst/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	evolution_sheet(PATH_ASH)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	evolution_research(heretic, HERETIC_EVOLUTION_SECOND_STAGE)
	var/datum/eldritch_knowledge/spell/basic/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/ashen_shift/shift = heretic.get_knowledge(/datum/eldritch_knowledge/spell/ashen_shift)
	TEST_ASSERT(grasp?.granted_spell && shift?.granted_spell, "У еретика есть хватка и Пепельный переход.")
	SEND_SIGNAL(user, COMSIG_MOB_CAST_SPELL, grasp.granted_spell)
	TEST_ASSERT(!("ash_evo2_burst" in heretic_evolution_test_looks(user)), "Общая хватка - не способность пути.")
	SEND_SIGNAL(user, COMSIG_MOB_CAST_SPELL, shift.granted_spell)
	var/list/looks = heretic_evolution_test_looks(user)
	var/mutable_appearance/burst = looks["ash_evo2_burst"]
	TEST_ASSERT(burst?.pixel_x == HERETIC_EVOLUTION_BIG_OFFSET, "Способность пути даёт всплеск из крупного листа.")
	TEST_ASSERT("ash_evo2_burst_face" in looks, "Всплеск лица идёт вместе со всплеском тела.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_evolution_test_burst_gone), user), HERETIC_EVOLUTION_BURST_TIME + 2 SECONDS, "всплеск облика"), "Всплеск гаснет сам.")
	TEST_ASSERT("ash_evo2" in heretic_evolution_test_looks(user), "После всплеска облик остаётся.")
	SEND_SIGNAL(user, COMSIG_MOB_CAST_SPELL, shift.granted_spell)
	TEST_ASSERT(!("ash_evo2_burst" in heretic_evolution_test_looks(user)), "Второй всплеск ждёт отката.")

/proc/heretic_evolution_test_burst_gone(mob/living/carbon/human/user)
	return !("ash_evo2_burst" in heretic_evolution_test_looks(user))

/// Первую ступень видно только вплотную, вторую - с пары клеток, обе только на открытых частях; вознёсшегося видно всегда.
/datum/unit_test/heretic_evolution_examine/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	var/first_line = path.evolution_examine[1][HERETIC_EVOLUTION_EYES]
	var/second_line = path.evolution_examine[2][HERETIC_EVOLUTION_HANDS]
	var/third_line = path.evolution_examine[3][HERETIC_EVOLUTION_ANY]
	user.forceMove(heretic_lead_test_spot(0, 0))
	var/mob/living/carbon/human/near = heretic_lead_test_crew(heretic_lead_test_spot(1, 0))
	var/mob/living/carbon/human/pair = heretic_lead_test_crew(heretic_lead_test_spot(2, 0))
	var/mob/living/carbon/human/far = heretic_lead_test_crew(heretic_lead_test_spot(4, 0))
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE - 1)
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, near), first_line), "До первой ступени примет нет.")
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE)
	TEST_ASSERT(findtext(heretic_evolution_test_seen(user, near), first_line), "Вплотную видна первая примета.")
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, pair), first_line), "С двух клеток первую примету не видно.")
	var/obj/item/clothing/glasses/sunglasses/shades = allocate(/obj/item/clothing/glasses/sunglasses)
	TEST_ASSERT(user.equip_to_slot_if_possible(shades, ITEM_SLOT_EYES), "Очки надеты.")
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, near), first_line), "Очки прячут примету глаз.")
	user.dropItemToGround(shades)
	evolution_research(heretic, HERETIC_EVOLUTION_SECOND_STAGE)
	var/seen = heretic_evolution_test_seen(user, pair)
	TEST_ASSERT(findtext(seen, second_line) && !findtext(seen, first_line), "С двух клеток видна вторая ступень, но не первая.")
	TEST_ASSERT(findtext(heretic_evolution_test_seen(user, near), first_line), "Вплотную на второй ступени видна и первая примета.")
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, far), second_line), "Издали вторую ступень не видно.")
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	TEST_ASSERT(user.equip_to_slot_if_possible(gloves, ITEM_SLOT_GLOVES), "Перчатки надеты.")
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, pair), second_line), "Перчатки прячут приметы кистей.")
	heretic.ascended = TRUE
	user.apply_status_effect(/datum/status_effect/heretic_ascended)
	seen = heretic_evolution_test_seen(user, far)
	TEST_ASSERT(findtext(seen, third_line) && !findtext(seen, second_line), "Вознёсшегося видно издали и в перчатках.")
	user.death()
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, near), third_line), "У трупа облик не виден.")
	user.remove_status_effect(/datum/status_effect/heretic_ascended)

/// Сброс пути, снятие роли, смерть, гиб и смена тела снимают облик или переносят его.
/datum/unit_test/heretic_evolution_removal/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ASH)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	var/first_line = path.evolution_examine[1][HERETIC_EVOLUTION_EYES]
	evolution_sheet(PATH_ASH)
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE)
	TEST_ASSERT("ash_evo1" in heretic_evolution_test_looks(user), "Облик на теле.")
	TEST_ASSERT(heretic.reset_path(user), "Путь сбрасывается в окне смены.")
	TEST_ASSERT(!("ash_evo1" in heretic_evolution_test_looks(user)), "Сброс пути снимает облик.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Путь выбирается заново.")
	evolution_research(heretic, HERETIC_EVOLUTION_FIRST_STAGE)
	TEST_ASSERT("ash_evo1" in heretic_evolution_test_looks(user), "Облик возвращается с новыми ступенями.")
	user.death()
	TEST_ASSERT(!("ash_evo1" in heretic_evolution_test_looks(user)), "Смерть гасит облик.")
	user.revive(full_heal = TRUE)
	TEST_ASSERT("ash_evo1" in heretic_evolution_test_looks(user), "Ожившее тело снова в облике.")
	user.forceMove(heretic_lead_test_spot(0, 0))
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, heretic_lead_test_spot(1, 0))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(!("ash_evo1" in heretic_evolution_test_looks(user)), "Старое тело теряет облик.")
	TEST_ASSERT("ash_evo1" in heretic_evolution_test_looks(new_body), "Облик переходит в новое тело.")
	TEST_ASSERT(!findtext(heretic_evolution_test_seen(user, new_body), first_line), "Старое тело не описывает облик.")
	TEST_ASSERT(findtext(heretic_evolution_test_seen(new_body, user), first_line), "Новое тело описывает облик.")
	new_body.gib()
	TEST_ASSERT(QDELETED(new_body), "Тело разорвано.")
	TEST_ASSERT_NULL(heretic.evolution.body, "Гиб отпускает тело.")
	var/mob/living/brain_mob = heretic.owner.current
	var/atom/movable/brain_holder = brain_mob?.loc
	heretic.owner.transfer_to(user)
	qdel(istype(brain_holder, /obj/item/organ/brain) ? brain_holder : brain_mob)
	TEST_ASSERT("ash_evo1" in heretic_evolution_test_looks(user), "Вернувшись в тело, облик снова на нём.")
	heretic.clear_heretic()
	TEST_ASSERT_NULL(heretic.evolution, "Снятие роли убирает облик.")
	TEST_ASSERT(!("ash_evo1" in heretic_evolution_test_looks(user)), "Снятая роль не оставляет слоёв.")
