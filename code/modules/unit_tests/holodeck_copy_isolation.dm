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
	check_turf_overlay_transfer()

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

/// Встроенные списки BYOND проходят islist(), но ассоциативного чтения не поддерживают:
/// общий цикл copy_template_vars() спрашивал у overlays значение по ключу-аппирансу и
/// падал "bad index" (273 рантайма за раунд 10137), а оверлеи шаблона на копию не
/// переезжали вовсе - у турфов голодека слетала вся нарисованная обвязка.
/datum/unit_test/holodeck_copy_isolation/proc/check_turf_overlay_transfer()
	for(var/builtin_list in list("overlays", "underlays", "filters", "vis_contents", "vis_locs"))
		TEST_ASSERT(builtin_list in GLOB.turf_copy_forbidden_vars, "[builtin_list] выпал из turf_copy_forbidden_vars - copy_template_vars снова полезет читать встроенный список по ключу")

	var/turf/template = run_loc_floor_bottom_left
	var/turf/copy = run_loc_floor_top_right
	TEST_ASSERT(template != copy, "Шаблон и приёмник - один и тот же турф, предпосылка теста сломана")

	var/overlays_before = length(template.overlays)
	var/mutable_appearance/marker = mutable_appearance(template.icon, template.icon_state)
	marker.color = COLOR_RED
	template.add_overlay(marker)
	TEST_ASSERT_EQUAL(length(template.overlays), overlays_before + 1, "Оверлей не встал на турф-шаблон, предпосылка теста сломана")

	copy.cut_overlays()
	copy.copy_template_vars(template)

	TEST_ASSERT_EQUAL(length(copy.overlays), length(template.overlays), "Оверлеи шаблона не переехали на копию турфа")

	//арену за собой прибираем точечно: cut_overlays() снёс бы и то, что турф носил до теста
	template.cut_overlay(marker)
	copy.cut_overlay(marker)
