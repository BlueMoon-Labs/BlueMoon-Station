// Регрессии по ревью ветки round-10137-fixes.
// Общая тема первых трёх: /turf/change_area() отдаёт машинерии on_area_swap() уже ПОСЛЕ
// того, как турф переписан на новую область, поэтому всё, что определяет зону лениво
// (alarm_handler, broadcast_status), считает новую и молча промахивается мимо старой.

/// Пожарная сигнализация, уехавшая из зоны, обязана погасить за собой тревогу:
/// иначе покинутая область навсегда остаётся с fire = TRUE и захлопнутыми файрлоками.
/datum/unit_test/firealarm_area_swap_resets_old_area/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	first_area.contents.Add(floor)

	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	// Область кладём в allocated ПОСЛЕ машины: уборка идёт по списку, и подписчик
	// должен умереть раньше того, на что он смотрит.
	allocated += first_area
	allocated += second_area
	TEST_ASSERT_EQUAL(alarm.myarea, first_area, "предпосылка: сигнализация не приписалась к своей зоне")

	first_area.firealert(alarm)
	TEST_ASSERT(first_area.fire, "предпосылка: тревога в исходной зоне не поднялась")

	second_area.contents.Add(floor)
	floor.change_area(first_area, second_area)

	TEST_ASSERT(!first_area.fire, "покинутая зона осталась в пожарной тревоге: файрлоки там уже никто не откроет")
	TEST_ASSERT_EQUAL(alarm.myarea, second_area, "сигнализация не переехала в новую зону")
	TEST_ASSERT(alarm in second_area.firealarms, "новая зона не получила сигнализацию в реестр")
	TEST_ASSERT(!(alarm in first_area.firealarms), "старая зона всё ещё держит сигнализацию")

	original_area.contents.Add(floor)

/// Сломанную сигнализацию obj_break() снимает с учёта зоны. Переезд не должен её воскрешать:
/// иначе разбитая коробка на стене снова считалась бы исправным детектором.
/datum/unit_test/firealarm_area_swap_keeps_broken_unregistered/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	first_area.contents.Add(floor)

	var/obj/machinery/firealarm/alarm = allocate(/obj/machinery/firealarm)
	allocated += first_area
	allocated += second_area
	alarm.obj_break()
	TEST_ASSERT(!(alarm in first_area.firealarms), "предпосылка: obj_break() не снял сигнализацию с учёта")

	second_area.contents.Add(floor)
	floor.change_area(first_area, second_area)

	TEST_ASSERT(!(alarm in second_area.firealarms), "переезд вернул сломанную сигнализацию в реестр новой зоны")

	original_area.contents.Add(floor)

/// Атмосферная тревога воздушки живёт в alarm_handler, который ищет область через
/// get_area(source_atom). После смены зоны под ногами обычный clear_alarm() промахивается,
/// и старая область остаётся с поднятым ALARM_ATMOS до конца раунда.
/datum/unit_test/airalarm_area_swap_clears_old_area_alarm/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	first_area.contents.Add(floor)

	var/obj/machinery/airalarm/alarm = allocate(/obj/machinery/airalarm)
	allocated += first_area
	allocated += second_area
	TEST_ASSERT_NOTNULL(alarm.alarm_manager, "предпосылка: у воздушки нет alarm_handler")

	alarm.alarm_manager.send_alarm(ALARM_ATMOS)
	TEST_ASSERT(first_area.active_alarms[ALARM_ATMOS], "предпосылка: тревога в исходной зоне не поднялась")

	second_area.contents.Add(floor)
	floor.change_area(first_area, second_area)

	TEST_ASSERT(!first_area.active_alarms[ALARM_ATMOS], "покинутая зона осталась с поднятой атмосферной тревогой")
	TEST_ASSERT_EQUAL(alarm.alarm_area, second_area, "воздушка не переписалась на новую зону")

	original_area.contents.Add(floor)

/// Регистрацию вента в реестрах области выдаёт broadcast_status(), а тот выходит сразу
/// без радиоканала. Значит на переезде вент без радио снимался со старой зоны и не
/// появлялся в новой - в списках воздушки его не было вообще нигде.
/datum/unit_test/vent_area_swap_registers_without_radio/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/area/original_area = get_area(floor)
	var/area/first_area = new /area
	var/area/second_area = new /area
	first_area.contents.Add(floor)

	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, floor)
	allocated += first_area
	allocated += second_area
	vent.set_machine_stat(0)
	// Регистрация и подписка на частоту живут в atmosinit(), которую в обычной жизни
	// зовёт SSair на старте раунда.
	vent.atmosinit()
	TEST_ASSERT_NOTNULL(first_area.air_vent_names[vent.id_tag], "предпосылка: вент не зарегистрировался в исходной зоне")

	// Вент без радиоканала: именно на нём broadcast_status() выходит первой же строкой.
	SSradio.remove_object(vent, vent.frequency)
	vent.radio_connection = null

	second_area.contents.Add(floor)
	floor.change_area(first_area, second_area)

	TEST_ASSERT_NULL(first_area.air_vent_names[vent.id_tag], "старая зона всё ещё числит уехавший вент")
	TEST_ASSERT_NOTNULL(second_area.air_vent_names[vent.id_tag], "вент без радиоканала не попал в реестр новой зоны")

	original_area.contents.Add(floor)

/// filters и underlays исключены из общего цикла копирования варов турфа (островной список
/// BYOND, ассоциативного чтения не поддерживает), поэтому переносить их обязан явный код.
/datum/unit_test/turf_template_copy_carries_filters_and_underlays/Run()
	var/turf/template = run_loc_floor_bottom_left
	var/turf/copy = locate(template.x + 1, template.y, template.z)
	TEST_ASSERT_NOTNULL(copy, "тесту нужен второй турф резервации")

	TEST_ASSERT_EQUAL(length(copy.filters), 0, "предпосылка: приёмник обязан начинать без фильтров")
	TEST_ASSERT_EQUAL(length(copy.underlays), 0, "предпосылка: приёмник обязан начинать без подложек")

	template.add_filter("unit_test_blur", 1, list("type" = "blur", "size" = 2))
	template.underlays += mutable_appearance(template.icon, template.icon_state)
	TEST_ASSERT_EQUAL(length(template.filters), 1, "предпосылка: фильтр не лёг на шаблон")
	TEST_ASSERT_EQUAL(length(template.underlays), 1, "предпосылка: подложка не легла на шаблон")

	copy.copy_template_vars(template)

	TEST_ASSERT_EQUAL(length(copy.filters), 1, "фильтры шаблона не переехали на копию")
	TEST_ASSERT_EQUAL(length(copy.underlays), 1, "подложки шаблона не переехали на копию")

/datum/unit_test/turf_template_copy_carries_filters_and_underlays/Destroy()
	// Уборка в Destroy, а не в хвосте Run(): провалившийся TEST_ASSERT выходит немедленно.
	var/turf/template = run_loc_floor_bottom_left
	if(template)
		template.filters = null
		template.underlays = null
		template.filter_data = null
		var/turf/copy = locate(template.x + 1, template.y, template.z)
		if(copy)
			copy.filters = null
			copy.underlays = null
			copy.filter_data = null
	return ..()

/// Отказавшую помпу перезапускать нечем: ближайший on_life() снова её остановит и
/// напечатает "Fatal error detected", а у синтетика он ещё и сбрасывает failed на каждом
/// проходе с beating - то есть каждый разряд дефиба перевзводил ровно тот спам,
/// ради которого ставили защиту.
/datum/unit_test/failing_synthetic_heart_is_not_restarted/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/obj/item/organ/heart/heart = patient.getorganslot(ORGAN_SLOT_HEART)
	TEST_ASSERT_NOTNULL(heart, "предпосылка: у тестового человека нет сердца")

	heart.organ_flags |= ORGAN_SYNTHETIC
	heart.Stop()
	TEST_ASSERT(patient.undergoing_cardiac_arrest(), "предпосылка: помпа не остановилась")

	// Исправную синтетическую помпу снятие приступа обязано заводить - ради этого
	// проверка can_heartattack() и гейтит только постановку.
	patient.set_heartattack(FALSE)
	TEST_ASSERT(heart.beating, "снятие приступа не завело исправную синтетическую помпу")

	heart.Stop()
	heart.setOrganDamage(heart.maxHealth)
	TEST_ASSERT(heart.organ_flags & ORGAN_FAILING, "предпосылка: помпа не ушла в отказ")

	patient.set_heartattack(FALSE)
	TEST_ASSERT(!heart.beating, "снятие приступа завело отказавшую помпу: on_life остановит её снова и напечатает Fatal error")

/// Родитель /obj/item/organ/Insert() отказывает не-карбону и повторной вставке в то же тело.
/// Тело нам в этом случае не принадлежит, и снос brainmob с переносом разума выполнять нельзя.
/datum/unit_test/brain_insert_rejected_keeps_brainmob/Run()
	var/obj/item/organ/brain/loose_brain = allocate(/obj/item/organ/brain)
	loose_brain.brainmob = new /mob/living/brain(loose_brain)
	var/mob/living/brain/stored_mob = loose_brain.brainmob

	var/inserted = loose_brain.Insert(null)

	TEST_ASSERT(!inserted, "Insert() отчитался об успехе на неподходящем теле")
	TEST_ASSERT(!QDELETED(stored_mob), "отказанный Insert() удалил brainmob вместе с разумом владельца")
	TEST_ASSERT_EQUAL(loose_brain.brainmob, stored_mob, "отказанный Insert() обнулил brainmob")

/// update_base_icon() писал смещение только когда оно ненулевое, поэтому обычное шасси,
/// снявшее маскировку под сдвинутое (borg_chameleon), навсегда оставалось съехавшим.
/datum/unit_test/cyborg_pixel_offset_resets_transform/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	TEST_ASSERT_NOTNULL(borg.module, "предпосылка: борг создан без модуля")

	// Не "robot": у той ветки update_base_icon() свой безусловный сброс сдвига.
	borg.module.cyborg_base_icon = "unit_test_chassis"
	borg.module.cyborg_pixel_offset = -16
	borg.update_base_icon()
	var/matrix/disguised = borg.transform
	TEST_ASSERT_EQUAL(disguised.c, -16, "предпосылка: смещение модуля не доехало до transform")

	// Маскировка снята - модулю вернули его нулевое смещение.
	borg.module.cyborg_pixel_offset = 0
	borg.update_base_icon()
	var/matrix/restored = borg.transform
	TEST_ASSERT_EQUAL(restored.c, 0, "снятие маскировки не вернуло шасси на место")

/// has_trauma_type() сравнивает стойкость как "<= указанной", поэтому ген паралича считал
/// своим любой чужой паралич. Ген обязан владеть только своей, неснимаемой травмой.
/datum/unit_test/paraplegic_gene_owns_only_its_own_trauma/Run()
	var/mob/living/carbon/human/carrier = allocate(/mob/living/carbon/human)
	carrier.dna.add_mutation(/datum/mutation/human/bm/paraplegic)
	var/datum/mutation/human/bm/paraplegic/gene = carrier.dna.get_mutation(/datum/mutation/human/bm/paraplegic)
	TEST_ASSERT_NOTNULL(gene, "предпосылка: мутация не легла на носителя")
	TEST_ASSERT(gene.trauma_from_mutation, "ген не отметил выданный им паралич своим")
	TEST_ASSERT_NOTNULL(carrier.has_trauma_type(/datum/brain_trauma/severe/paralysis/paraplegic, TRAUMA_RESILIENCE_ABSOLUTE), "ген не выдал паралич")

	carrier.dna.remove_mutation(/datum/mutation/human/bm/paraplegic)
	TEST_ASSERT_NULL(carrier.has_trauma_type(/datum/brain_trauma/severe/paralysis/paraplegic, TRAUMA_RESILIENCE_ABSOLUTE), "ген не снял собственный паралич при потере")

	// Паралич квирка (та же неснимаемая стойкость) ген присваивать и лечить не должен.
	var/mob/living/carbon/human/quirked = allocate(/mob/living/carbon/human)
	quirked.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT_NOTNULL(quirked.has_trauma_type(/datum/brain_trauma/severe/paralysis/paraplegic, TRAUMA_RESILIENCE_ABSOLUTE), "предпосылка: квирковый паралич не лёг")

	quirked.dna.add_mutation(/datum/mutation/human/bm/paraplegic)
	var/datum/mutation/human/bm/paraplegic/quirk_gene = quirked.dna.get_mutation(/datum/mutation/human/bm/paraplegic)
	TEST_ASSERT_NOTNULL(quirk_gene, "предпосылка: мутация не легла поверх квирка")
	TEST_ASSERT(!quirk_gene.trauma_from_mutation, "ген присвоил себе чужой паралич")

	quirked.dna.remove_mutation(/datum/mutation/human/bm/paraplegic)
	TEST_ASSERT_NOTNULL(quirked.has_trauma_type(/datum/brain_trauma/severe/paralysis/paraplegic, TRAUMA_RESILIENCE_ABSOLUTE), "ген вылечил чужой паралич за компанию")
