/// Снапшот улик warnfail: предмет, не вынутый из контейнера, должен дать loc-цепочку.
/datum/unit_test/warnfail_context_loc_chain/Run()
	var/obj/structure/closet/locker = allocate(/obj/structure/closet)
	var/obj/item/pinned = allocate(/obj/item)
	pinned.forceMove(locker)
	var/context = SSgarbage.build_warnfail_context(pinned)
	TEST_ASSERT(findtext(context, "всё ещё в loc"), "Предмет внутри контейнера не дал улику loc: [context]")
	TEST_ASSERT(findtext(context, "closet"), "Улика loc не назвала тип контейнера: [context]")

/// Живой таймер с колбеком на датум должен попасть в улики warnfail.
/datum/unit_test/warnfail_context_active_timer/Run()
	var/obj/item/thing = allocate(/obj/item)
	var/timer_id = addtimer(CALLBACK(thing, TYPE_PROC_REF(/atom, update_icon)), 10 MINUTES, TIMER_STOPPABLE)
	var/context = SSgarbage.build_warnfail_context(thing)
	deltimer(timer_id)
	TEST_ASSERT(findtext(context, "таймеров на датуме"), "Активный таймер не попал в улики: [context]")

/// Датум без внешних зацепок должен давать пустой снапшот - без ложных улик.
/datum/unit_test/warnfail_context_clean_datum/Run()
	var/obj/item/loose = allocate(/obj/item)
	loose.moveToNullspace()
	TEST_ASSERT_EQUAL(SSgarbage.build_warnfail_context(loose), "", "Чистый предмет в nullspace дал ложные улики")

/// hard_resolve обязан возвращать qdel-нутую, но ещё не собранную цель; resolve() - null.
/// Живой объект в переиспользованном ref-слоте (weak_reference не наш) - null.
/datum/unit_test/weakref_hard_resolve/Run()
	var/obj/item/thing = new(run_loc_floor_bottom_left)
	var/datum/weakref/ref = WEAKREF(thing)
	var/obj/item/holder = thing
	// Симуляция переиспользованного слота: по ref живой датум, но он не наша цель.
	thing.weak_reference = null
	TEST_ASSERT_NULL(ref.hard_resolve(), "hard_resolve() вернул чужой живой объект из переиспользованного ref-слота")
	thing.weak_reference = ref
	qdel(thing)
	TEST_ASSERT_NULL(ref.resolve(), "resolve() вернул qdel-нутую цель")
	TEST_ASSERT_EQUAL(ref.hard_resolve(), holder, "hard_resolve() не вернул qdel-нутую, но живую цель")
	holder = null
