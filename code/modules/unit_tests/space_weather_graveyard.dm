/**
 * Тесты кладбища кораблей.
 *
 * Проверяется то, что ломается тихо: расписание ударов (удар за пределами пика не
 * случится, а удар без запаса на предупреждение случится без предупреждения), поиск
 * места под обломок у корпуса и учёт обломков в глобальном списке - по нему явление
 * уносит несобранное, и стухшая запись означала бы либо забытый обломок, либо держателя
 * удалённого объекта до конца раунда.
 */

/// Расписание ударов: внутри пика, по возрастанию, с запасом на предупреждение.
/datum/unit_test/graveyard_impact_schedule/Run()
	var/datum/round_event/space_weather/graveyard/phenomenon = unit_test_detached_phenomenon(/datum/round_event/space_weather/graveyard)
	phenomenon.schedule_impacts()

	TEST_ASSERT(length(phenomenon.impact_schedule) >= 1, "Кладбище не запланировало ни одного удара - риска в событии не осталось")
	TEST_ASSERT(phenomenon.impact_bearing in GLOB.cardinals, "Направление удара '[phenomenon.impact_bearing]' не сторона света - объявление назовёт мусор")

	var/previous = 0
	for(var/tick_due in phenomenon.impact_schedule)
		TEST_ASSERT(tick_due > previous, "Удары запланированы не по возрастанию: [tick_due] после [previous]")
		TEST_ASSERT(tick_due < phenomenon.peak_ticks, "Удар на тике [tick_due] выпадает за пик длиной [phenomenon.peak_ticks] и не случится вовсе")
		TEST_ASSERT(tick_due >= phenomenon.impact_warning_ticks, "Удар на тике [tick_due] не оставляет [phenomenon.impact_warning_ticks] тиков на предупреждение - о контакте сообщат после него")
		previous = tick_due

	qdel(phenomenon)

/// Обломок годится только там, где рядом есть корпус: в глубоком космосе его не видно
/// из окна и до него никто не полетит.
/datum/unit_test/graveyard_hulk_placement/Run()
	var/datum/round_event/space_weather/graveyard/phenomenon = unit_test_detached_phenomenon(/datum/round_event/space_weather/graveyard)

	var/turf/hull_turf = run_loc_floor_bottom_left
	var/turf/void_turf = locate(hull_turf.x + 2, hull_turf.y + 2, hull_turf.z)
	TEST_ASSERT_NOTNULL(void_turf, "Резервация оказалась меньше ожидаемой - тесту негде развернуться")
	void_turf.ChangeTurf(/turf/open/space)
	TEST_ASSERT(phenomenon.near_hull(void_turf), "Космический турф внутри корпуса станции не признан пригодным")
	void_turf.ChangeTurf(/turf/open/floor/plasteel)

	qdel(phenomenon)

/// Учёт обломков: список ведётся самим объектом, а не событием.
/datum/unit_test/graveyard_hulk_bookkeeping/Run()
	var/obj/structure/loot_pile/derelict/hulk = allocate(/obj/structure/loot_pile/derelict, run_loc_floor_bottom_left)
	TEST_ASSERT(hulk in GLOB.derelict_hulks, "Обломок не встал в глобальный список - уборка явления его не найдёт и он останется до конца раунда")
	TEST_ASSERT(!hulk.can_use_hands, "Обломок разбирается голыми руками, хотя висит в вакууме")
	TEST_ASSERT(length(hulk.loot) > 0, "У обломка пустой стол лута - разбирать его незачем")

	qdel(hulk)
	TEST_ASSERT(!(hulk in GLOB.derelict_hulks), "Удалённый обломок остался в глобальном списке - это держатель удалённого объекта")
