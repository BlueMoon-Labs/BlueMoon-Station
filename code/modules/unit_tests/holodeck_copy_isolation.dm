/// DuplicateObject мелко копирует любой списочный вар оригинала: `O.vars[V] = L.Copy()`.
/// Проверка на датум в том же цикле стоит ПОСЛЕ islist(), поэтому отдельная ссылка на
/// датум отсеивалась, а список таких же ссылок - нет. Клон получал в свои
/// component_parts / debris / actions чужие объекты, и его собственный Destroy убивал
/// их вместе с собой через QDEL_LIST. Оригинал (шаблонная область голодека на CentCom)
/// оставался единственным держателем трупа и уходил в харддел.
///
/// В прод-раунде 9838 это стоило 8.1 секунды харддел-времени: одна смена программы
/// голодека убивала осколки, стержни, обломки столов, платы и детали машин шаблона,
/// и каждый такой del() потом стоил 350-440мс.
/datum/unit_test/holodeck_copy_isolation

/datum/unit_test/holodeck_copy_isolation/Run()
	check_forbidden_vars()
	check_debris_isolation()
	check_component_parts_isolation()
	check_appearance_list_survives()

/// overlays и underlays - спец-списки BYOND: ассоциативного хранилища у них нет, и
/// `source[аппиранс]` валится "bad index". copy_template_list лезла туда за значением
/// на каждом оверлее, и копирование турфа рвалось на первом же - загрузка программы
/// голодека давала 310 рантаймов за раунд (9972), а турфы приезжали недокопированными.
///
/// Список собирается НЕ литералом: обычный list() ассоциативное чтение переживает и
/// вернул бы null вместо падения, то есть тест был бы зелёным и до фикса.
/datum/unit_test/holodeck_copy_isolation/proc/check_appearance_list_survives()
	var/turf/template = run_loc_floor_top_right
	var/turf/receiver = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(template, "тесту нужен турф-шаблон")
	TEST_ASSERT_NOTNULL(receiver, "тесту нужен турф-приёмник")

	template.add_overlay(mutable_appearance('icons/turf/floors.dmi', "grass"))
	TEST_ASSERT(length(template.overlays), "предпосылка: у шаблона не появился оверлей")

	var/list/copied = copy_template_list(template.overlays)
	TEST_ASSERT_NOTNULL(copied, "копия overlays не вернулась - прок упал на ассоциативном чтении спец-списка")
	TEST_ASSERT_EQUAL(length(copied), length(template.overlays), "копия overlays потеряла элементы: [length(copied)] против [length(template.overlays)]")

	// И через настоящий путь голодека: оверлей обязан доехать до приёмника целиком.
	receiver.copy_template_vars(template)
	TEST_ASSERT_EQUAL(length(receiver.overlays), length(template.overlays), "копирование варов турфа не донесло оверлеи: [length(receiver.overlays)] против [length(template.overlays)]")

/datum/unit_test/holodeck_copy_isolation/proc/check_forbidden_vars()
	for(var/forbidden_var in list("component_parts", "debris", "actions"))
		TEST_ASSERT(forbidden_var in GLOB.duplicate_forbidden_vars, "[forbidden_var] выпал из duplicate_forbidden_vars - клон снова будет удалять чужие объекты")

/// Стеклянный стол держит в debris заранее созданные раму и осколок,
/// а в Destroy делает по ним QDEL_LIST.
/datum/unit_test/holodeck_copy_isolation/proc/check_debris_isolation()
	var/obj/structure/table/glass/original = allocate(/obj/structure/table/glass, run_loc_floor_bottom_left)
	TEST_ASSERT(length(original.debris), "У стеклянного стола нет обломков - предпосылка теста сломана")

	var/list/original_debris = original.debris.Copy()
	var/obj/structure/table/glass/clone = DuplicateObject(original, sameloc = TRUE)
	TEST_ASSERT_NOTNULL(clone, "DuplicateObject не создал клон стеклянного стола")

	for(var/atom/movable/fragment as anything in original_debris)
		TEST_ASSERT(!(fragment in clone.debris), "Клон получил обломок оригинала [fragment.type] - его Destroy убьёт чужой объект")

	qdel(clone)
	for(var/atom/movable/fragment as anything in original_debris)
		TEST_ASSERT(!QDELETED(fragment), "Удаление клона убило обломок оригинала [fragment.type]")

	qdel(original)

/// Машина держит платы и детали в component_parts, и её Destroy тоже делает QDEL_LIST.
/datum/unit_test/holodeck_copy_isolation/proc/check_component_parts_isolation()
	var/obj/machinery/computer/original = allocate(/obj/machinery/computer/atmos_alert, run_loc_floor_bottom_left)
	TEST_ASSERT(length(original.component_parts), "У консоли нет component_parts - предпосылка теста сломана")

	var/list/original_parts = original.component_parts.Copy()
	var/obj/machinery/computer/clone = DuplicateObject(original, sameloc = TRUE)
	TEST_ASSERT_NOTNULL(clone, "DuplicateObject не создал клон консоли")

	for(var/atom/movable/part as anything in original_parts)
		TEST_ASSERT(!(part in clone.component_parts), "Клон получил деталь оригинала [part.type] - его Destroy убьёт чужую плату")

	qdel(clone)
	for(var/atom/movable/part as anything in original_parts)
		TEST_ASSERT(!QDELETED(part), "Удаление клона убило деталь оригинала [part.type]")

	qdel(original)
