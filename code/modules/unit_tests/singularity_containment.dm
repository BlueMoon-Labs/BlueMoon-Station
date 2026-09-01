/// Сдерживающие поля не плотные (density = FALSE) - физически сингулярность
/// держит только check_turfs_in(): Move() пускает шаг лишь если заслон впереди
/// чист. Заслон строился через switch() по направлению, который знал только
/// четыре кардинальных дира: на диагонали dir2/dir3 оставались нулём, боковые
/// клетки в список не попадали, и проверка вырождалась в один турф. Угол клетки
/// полей из-за этого был проходим насквозь - синга упиралась в угол и уходила
/// по диагонали мимо заслона.
/datum/unit_test/singularity_diagonal_containment/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/center = locate(origin.x + 2, origin.y + 2, origin.z)
	TEST_ASSERT_NOTNULL(center, "the test reservation has no turf two tiles north-east of its corner")

	var/obj/singularity/singulo = allocate(/obj/singularity, center)
	// Инертная синга: без своего хода и вне SSobj, иначе она уедет есть чужие
	// аллокации между тестами.
	singulo.move_self = FALSE
	STOP_PROCESSING(SSobj, singulo)

	// Радиус заслона задаём явно, чтобы тест не зависел от размера синги.
	var/steps = 2

	TEST_ASSERT(singulo.check_turfs_in(NORTHEAST, steps), "a clear diagonal is not passable")
	TEST_ASSERT(singulo.check_turfs_in(NORTH, steps), "a clear cardinal direction is not passable")

	// Клетка северной грани, но НЕ на самой диагонали: до фикса проверялся один
	// угловой турф, поэтому синга проходила ровно здесь.
	var/turf/north_face = locate(center.x + 1, center.y + steps, center.z)
	TEST_ASSERT_NOTNULL(north_face, "no turf in the northern face of the barrier")
	var/obj/machinery/field/containment/blocker = allocate(/obj/machinery/field/containment, north_face)
	TEST_ASSERT(!singulo.check_turfs_in(NORTHEAST, steps), "the singularity slips diagonally past the northern face")
	TEST_ASSERT(!singulo.check_turfs_in(NORTH, steps), "the northern face stopped blocking a cardinal step")
	// Восток чист - шаг туда обязан остаться разрешённым, иначе фикс просто
	// запирает сингу в клетке из воздуха.
	TEST_ASSERT(singulo.check_turfs_in(EAST, steps), "a clear cardinal direction got blocked by an unrelated field")
	qdel(blocker)

	// Та же проверка для второй оси: фикс обязан смотреть обе составляющие
	// диагонали, а не одну.
	var/turf/east_face = locate(center.x + steps, center.y + 1, center.z)
	TEST_ASSERT_NOTNULL(east_face, "no turf in the eastern face of the barrier")
	blocker = allocate(/obj/machinery/field/containment, east_face)
	TEST_ASSERT(!singulo.check_turfs_in(NORTHEAST, steps), "the singularity slips diagonally past the eastern face")
	qdel(blocker)

	// Сам угол держал и до фикса - следим, чтобы не потерялся.
	var/turf/corner = locate(center.x + steps, center.y + steps, center.z)
	TEST_ASSERT_NOTNULL(corner, "no turf in the diagonal corner of the barrier")
	blocker = allocate(/obj/machinery/field/containment, corner)
	TEST_ASSERT(!singulo.check_turfs_in(NORTHEAST, steps), "the diagonal corner stopped blocking a diagonal step")
	qdel(blocker)

	// Диагональ обязана оставаться проходимой после снятия полей, иначе фикс
	// стоит сингу намертво.
	TEST_ASSERT(singulo.check_turfs_in(NORTHEAST, steps), "the diagonal stayed blocked after the fields were removed")
