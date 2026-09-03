// Тесты мягкого космоочистителя (/datum/reagent/space_cleaner/gentle), которым
// моет станцию ивент space_cleaner_spill. Жалоба прода: пенная очистка уносила
// покраску и рисунки игроков (бар, библиотека). Мягкий вариант обязан:
//   1. сохранять рисунки крайонов/спрейканов (/obj/effect/decal/cleanable/crayon);
//   2. сохранять WASHABLE-покраску турфов и объектов (спрейкан "paint everything");
//   3. по-прежнему смывать обычную грязь и прочие декали.
// Базовый space_cleaner (мыло, гранаты, уборщик) поведение НЕ меняет - это тоже
// закреплено ассертами, чтобы флаг preserves_decor не протёк в базу.

/datum/unit_test/space_cleaner_gentle_preserves_decor/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/datum/reagent/space_cleaner/gentle/cleaner = new()

	var/obj/effect/decal/cleanable/crayon/art = new(T)
	var/obj/effect/decal/cleanable/dirt/grime = new(T)
	// Hex-литералы в нижнем регистре: BYOND нормализует цвета атомов в lowercase
	T.add_atom_colour("#bada55", WASHABLE_COLOUR_PRIORITY)

	cleaner.reaction_turf(T, 10)

	TEST_ASSERT(!QDELETED(art), "Gentle cleaner must not delete crayon decals on turf reaction")
	TEST_ASSERT(QDELETED(grime), "Gentle cleaner must still delete ordinary cleanable decals (dirt)")
	TEST_ASSERT_EQUAL(T.color, "#bada55", "Gentle cleaner must not strip washable paint from turfs")

	// Путь reaction_obj: пена реагирует с каждым объектом на тайле отдельно,
	// рисунок не должен погибнуть и там.
	cleaner.reaction_obj(art, 10)
	TEST_ASSERT(!QDELETED(art), "Gentle cleaner must not delete crayon decals via obj reaction")

	var/obj/item/pen/painted = new(T)
	painted.add_atom_colour("#112233", WASHABLE_COLOUR_PRIORITY)
	cleaner.reaction_obj(painted, 10)
	TEST_ASSERT_EQUAL(painted.color, "#112233", "Gentle cleaner must not strip washable paint from objects")

	T.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	qdel(painted)
	qdel(art)
	qdel(cleaner)

/datum/unit_test/space_cleaner_base_still_cleans_decor/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/datum/reagent/space_cleaner/cleaner = new()

	var/obj/effect/decal/cleanable/crayon/art = new(T)
	T.add_atom_colour("#bada55", WASHABLE_COLOUR_PRIORITY)

	cleaner.reaction_turf(T, 10)

	TEST_ASSERT(QDELETED(art), "Base space cleaner must still delete crayon decals (janitor gear behaviour)")
	TEST_ASSERT_NOTEQUAL(T.color, "#bada55", "Base space cleaner must still strip washable paint from turfs")

	T.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	qdel(cleaner)

/// Ивент обязан лить именно мягкий вариант: регресс на базовый реагент вернёт
/// смывание покраски всей станции. Проверяем реальным запуском start() на одном
/// вентиле: собранная пена должна нести gentle-реагент.
/datum/unit_test/space_cleaner_spill_uses_gentle_reagent/Run()
	// my_processing = FALSE: событие не должно жить своей жизнью (анонсы/тики) в CI,
	// им управляет тест. kill() в конце снимает его из SSdirector.running.
	var/datum/round_event/space_cleaner_spill/event_stub = new(FALSE)
	var/turf/T = run_loc_floor_bottom_left
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/vent = new(T)
	event_stub.atmos_devices = list(vent)
	event_stub.start()
	var/obj/effect/particle_effect/foam/spawned_foam = locate() in T
	TEST_ASSERT_NOTNULL(spawned_foam, "space_cleaner_spill start() must produce foam on the vent turf")
	TEST_ASSERT(spawned_foam.reagents.has_reagent(/datum/reagent/space_cleaner/gentle), "Event foam must carry the gentle space cleaner, not the paint-stripping base reagent")
	qdel(spawned_foam)
	qdel(vent)
	event_stub.kill()
	qdel(event_stub)
