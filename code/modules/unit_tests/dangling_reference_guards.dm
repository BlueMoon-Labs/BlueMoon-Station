// ===== Гарды на мёртвые ссылки =====
//
// Ссылка в DM нулится молча, когда объект хардделится: держатель не получает
// ни сигнала, ни исключения. Эти тесты закрепляют, что горячие циклы
// (processing, рассылка слышащих) переживают такую потерю без рантаймов.

///Имплант-помпа не должна крутиться в SSobj без носителя: implant() может
///отказать (несовместимая цель, COMPONENT_STOP_IMPLANTING), а process() по
///нулевому imp_in рантаймил каждые 2 секунды, пока имплант лежал в имплантере.
/datum/unit_test/aphrodisiac_pump_requires_host/Run()
	var/obj/item/implant/aphrodisiac_pump/pump = allocate(/obj/item/implant/aphrodisiac_pump)
	TEST_ASSERT_EQUAL(pump.process(), PROCESS_KILL, "An unimplanted pump must remove itself from processing")

	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	TEST_ASSERT(pump.implant(host, null, TRUE, TRUE), "Sanity: implanting into a carbon must succeed")
	TEST_ASSERT_EQUAL(pump.imp_in, host, "Sanity: the implant must know its host")
	TEST_ASSERT_NOTEQUAL(pump.process(), PROCESS_KILL, "An implanted pump must keep processing")

///null в important_recursive_contents (харддел слушателя внутри контейнера) не
///должен ронять рассылку COMSIG_ATOM_HEARER_IN_VIEW и просачиваться в выдачу
///get_hearers_in_view() - иначе каждый вызов телекомов сыпал рантаймами.
/datum/unit_test/get_hearers_in_view_skips_dead_refs/Run()
	var/obj/item/crowbar/holder = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/list/saved_contents = holder.important_recursive_contents
	holder.important_recursive_contents = list(SPATIAL_GRID_CONTENTS_TYPE_HEARING = list(null))

	var/list/hearers = get_hearers_in_view(0, holder)
	holder.important_recursive_contents = saved_contents

	TEST_ASSERT(!(null in hearers), "A dead recursive-contents reference must not leak into the hearers list")
	TEST_ASSERT(listener in hearers, "A live hearer on the same turf must still be delivered to")
