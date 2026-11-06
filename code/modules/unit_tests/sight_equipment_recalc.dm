/// Зрение после снятия и надевания вещей зависит только от того, что надето сейчас, и от квирка.
/datum/unit_test/sight_equipment_recalc

/datum/unit_test/sight_equipment_recalc/Run()
	var/mob/living/carbon/human/wearer = make_viewer()
	var/obj/item/clothing/glasses/meson/mesons = allocate(/obj/item/clothing/glasses/meson)
	var/obj/item/clothing/glasses/thermal/thermals = allocate(/obj/item/clothing/glasses/thermal)
	var/obj/item/clothing/head/helmet/nvg/helmet = allocate(/obj/item/clothing/head/helmet/nvg)
	var/obj/item/clothing/gloves/color/black/gloves = allocate(/obj/item/clothing/gloves/color/black)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/clothing/mask/breath/mask = allocate(/obj/item/clothing/mask/breath)

	check_step(wearer, "квирк без снаряжения")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(mesons, ITEM_SLOT_EYES), "Мезоны надеты")
	check_step(wearer, "мезоны")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(gloves, ITEM_SLOT_GLOVES), "Перчатки надеты")
	check_step(wearer, "мезоны + перчатки")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Комбинезон надет")
	check_step(wearer, "мезоны + комбинезон")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Маска надета")
	check_step(wearer, "мезоны + маска")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(helmet, ITEM_SLOT_HEAD), "ПНВ-шлем надет")
	check_step(wearer, "мезоны + ПНВ-шлем")
	wearer.dropItemToGround(gloves)
	check_step(wearer, "сняты перчатки")
	wearer.dropItemToGround(mesons)
	check_step(wearer, "сняты мезоны")
	TEST_ASSERT(wearer.equip_to_slot_if_possible(thermals, ITEM_SLOT_EYES), "Термалы надеты")
	check_step(wearer, "термалы + ПНВ-шлем")
	wearer.dropItemToGround(helmet)
	check_step(wearer, "снят ПНВ-шлем")
	wearer.dropItemToGround(mask)
	check_step(wearer, "снята маска")
	wearer.dropItemToGround(uniform)
	check_step(wearer, "снят комбинезон")
	wearer.dropItemToGround(thermals)
	check_step(wearer, "сняты термалы")
	wearer.mock_client = null

/datum/unit_test/sight_equipment_recalc/proc/make_viewer()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	viewer.mock_client = new /datum/client_interface
	TEST_ASSERT(viewer.add_quirk(/datum/quirk/night_vision), "Квирк ночного зрения выдан")
	return viewer

/// Эталон: свежий моб с тем же квирком надевает только то, что сейчас на проверяемом.
/datum/unit_test/sight_equipment_recalc/proc/check_step(mob/living/carbon/human/wearer, step_name)
	var/mob/living/carbon/human/reference = make_viewer()
	for(var/slot in list(ITEM_SLOT_ICLOTHING, ITEM_SLOT_GLOVES, ITEM_SLOT_MASK, ITEM_SLOT_HEAD, ITEM_SLOT_EYES))
		var/obj/item/original = wearer.get_item_by_slot(slot)
		if(!original)
			continue
		var/obj/item/copy = allocate(original.type)
		TEST_ASSERT(reference.equip_to_slot_if_possible(copy, slot), "[step_name]: эталон надел [copy]")
	TEST_ASSERT_EQUAL(sight_state(wearer), sight_state(reference), "[step_name]: зрение не совпало с эталоном")
	reference.mock_client = null

/datum/unit_test/sight_equipment_recalc/proc/sight_state(mob/living/carbon/human/viewer)
	var/cutoffs = islist(viewer.lighting_color_cutoffs) ? jointext(viewer.lighting_color_cutoffs, ",") : "-"
	return "sight=[viewer.sight] dark=[viewer.see_in_dark] invis=[viewer.see_invisible] alpha=[viewer.lighting_alpha] cutoff=[viewer.lighting_cutoff] colors=[cutoffs]"

/// Перестройка подложек (show_hud, смена HUD, настройки) не сбрасывает прозрачность тьмы от ПНВ и мезонов.
/datum/unit_test/lighting_alpha_survives_backdrop

/datum/unit_test/lighting_alpha_survives_backdrop/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/plane_master_group/main/group = allocate(/datum/plane_master_group/main, "unit-test-lighting-alpha")
	var/atom/movable/screen/plane_master/lighting/lighting = group.plane_masters["[GET_NEW_PLANE(LIGHTING_PLANE, 0)]"]
	lighting.refresh_backdrop(viewer)
	TEST_ASSERT(islist(lighting.color), "Яркость по умолчанию обязана лечь матрицей в color")
	lighting.set_alpha(LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
	TEST_ASSERT_EQUAL(effective_alpha(lighting), LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE, "Прозрачность тьмы не дошла до плоскости")
	lighting.refresh_backdrop(viewer)
	TEST_ASSERT_EQUAL(effective_alpha(lighting), LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE, "Перестройка подложки сбросила прозрачность тьмы")
	lighting.set_alpha(LIGHTING_PLANE_ALPHA_VISIBLE)
	lighting.refresh_backdrop(viewer)
	TEST_ASSERT_EQUAL(effective_alpha(lighting), LIGHTING_PLANE_ALPHA_VISIBLE, "Снятая прозрачность вернулась после перестройки")

/// BYOND складывает alpha в матрицу color: читать её надо оттуда.
/datum/unit_test/lighting_alpha_survives_backdrop/proc/effective_alpha(atom/movable/screen/plane_master/plane)
	var/list/matrix = plane.color
	if(!islist(matrix))
		return plane.alpha
	return round(matrix[16] * plane.alpha, 1)
