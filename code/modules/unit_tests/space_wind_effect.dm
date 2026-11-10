/// Порыв показывает визуал на своём турфе по направлению давления, визуал сам исчезает и собирается.
/datum/unit_test/space_wind_effect
	priority = TEST_LONGER
	var/list/turf/open/touched = list()

/datum/unit_test/space_wind_effect/proc/wind_turf(dx, dy)
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/T = locate(origin.x + dx, origin.y + dy, origin.z)
	touched |= T
	return T

/// Порыв так же, как его даёт SSair: вектор давления и проход высокого давления.
/datum/unit_test/space_wind_effect/proc/blow(turf/open/T, vector_x = 150, vector_y = 0)
	T.next_space_wind_at = 0
	T.pressure_vector_x = vector_x
	T.pressure_vector_y = vector_y
	T.high_pressure_movements()
	T.pressure_vector_x = 0
	T.pressure_vector_y = 0
	T.pressure_difference = 0
	T.pressure_direction = NONE
	T.next_space_wind_at = 0
	return T.space_wind_visual

/datum/unit_test/space_wind_effect/Destroy()
	for(var/turf/open/T as anything in touched)
		for(var/obj/effect/temp_visual/dir_setting/space_wind/wind in T)
			qdel(wind)
		T.space_wind_visual = null
		T.next_space_wind_at = 0
	touched = null
	return ..()

/datum/unit_test/space_wind_effect/Run()
	var/turf/open/subject = wind_turf(4, 4)
	TEST_ASSERT(istype(subject), "нет открытого турфа для порыва")
	var/obj/effect/temp_visual/dir_setting/space_wind/wind = blow(subject, 0, 150)
	TEST_ASSERT(!QDELETED(wind), "порыв не показал визуал ветра")
	TEST_ASSERT(wind.loc == subject, "визуал ветра появился не на турфе порыва, а в [wind.loc]")
	TEST_ASSERT(wind.dir == NORTH, "визуал ветра смотрит в [dir2text(wind.dir)] вместо севера")
	var/list/obj/effect/temp_visual/dir_setting/space_wind/held = list(wind)
	wind = null
	sleep(SPACE_WIND_VISUAL_COOLDOWN * 2 + 1 SECONDS)
	TEST_ASSERT(QDELETED(held[1]), "визуал ветра не удалился по истечении срока")
	TEST_ASSERT_NULL(subject.space_wind_visual, "турф держит удалённый визуал ветра")
	TEST_ASSERT(EXTERNAL_REFCOUNT(held[1]) == 0, "на удалённый визуал ветра остались ссылки: [EXTERNAL_REFCOUNT(held[1])]")

/// Шаттл переносит визуал присваиванием loc: удаление на новом месте обязано отпустить ссылку старого турфа.
/datum/unit_test/space_wind_effect/shuttle_move_release
	priority = TEST_DEFAULT

/datum/unit_test/space_wind_effect/shuttle_move_release/Run()
	var/turf/open/home = wind_turf(1, 1)
	var/turf/open/away = wind_turf(4, 1)
	var/obj/effect/temp_visual/dir_setting/space_wind/wind = blow(home)
	TEST_ASSERT(!QDELETED(wind), "порыв не показал визуал ветра")
	wind.onShuttleMove(away, home, null, EAST, null, null)
	TEST_ASSERT(wind.loc == away, "визуал не переехал вместе с шаттлом")
	var/list/obj/effect/temp_visual/dir_setting/space_wind/held = list(wind)
	wind = null
	qdel(held[1])
	TEST_ASSERT_NULL(home.space_wind_visual, "старый турф держит уехавший и удалённый визуал ветра")
	TEST_ASSERT(EXTERNAL_REFCOUNT(held[1]) == 0, "на удалённый визуал ветра остались ссылки: [EXTERNAL_REFCOUNT(held[1])]")

/// Порыв на турфе, с которого визуал увёз шаттл, рисуется на этом турфе, а не переигрывает уехавший.
/datum/unit_test/space_wind_effect/shuttle_move_regust
	priority = TEST_DEFAULT

/datum/unit_test/space_wind_effect/shuttle_move_regust/Run()
	var/turf/open/home = wind_turf(1, 3)
	var/turf/open/away = wind_turf(4, 3)
	var/obj/effect/temp_visual/dir_setting/space_wind/moved = blow(home)
	TEST_ASSERT(!QDELETED(moved), "порыв не показал визуал ветра")
	moved.onShuttleMove(away, home, null, EAST, null, null)
	var/obj/effect/temp_visual/dir_setting/space_wind/fresh = blow(home)
	TEST_ASSERT(!QDELETED(fresh), "второй порыв не показал визуал ветра")
	TEST_ASSERT(fresh != moved, "второй порыв переиграл визуал, уехавший на [moved.loc]")
	TEST_ASSERT(fresh.loc == home, "визуал второго порыва лежит в [fresh.loc], а не на турфе порыва")
	TEST_ASSERT(moved.loc == away, "уехавший визуал вернулся на старый турф")

/// Турф под визуалом стал стеной: визуал удаляется без рантайма.
/datum/unit_test/space_wind_effect/turf_changed

/datum/unit_test/space_wind_effect/turf_changed/Run()
	var/turf/open/subject = wind_turf(4, 4)
	var/floor_type = subject.type
	var/obj/effect/temp_visual/dir_setting/space_wind/wind = blow(subject)
	TEST_ASSERT(!QDELETED(wind), "порыв не показал визуал ветра")
	var/turf/changed = subject.ChangeTurf(/turf/closed/wall)
	TEST_ASSERT(!QDELETED(wind), "test premise: смена турфа не должна удалять визуал")
	qdel(wind)
	changed.ChangeTurf(floor_type)
