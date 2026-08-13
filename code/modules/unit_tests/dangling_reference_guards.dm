// ===== Гарды на рантаймы из прод-логов =====
//
// Первая половина - про мёртвые ссылки: ссылка в DM нулится молча, когда объект
// хардделится, и держатель не получает ни сигнала, ни исключения. Эти тесты
// закрепляют, что горячие циклы (processing, рассылка слышащих) переживают такую
// потерю без рантаймов.
//
// Вторая половина - про конкретные падения, разобранные по логам раундов:
// перенос варов турфа-шаблона, разбор пустого JSON, вызов родительского прока.

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

///Копирование ареа (голодек, ресет тандердома) переносило на турф-приёмник ещё и
///lc_*/lighting_object/light_sources шаблона. Источники света рядом с копией брали
///чужие углы и лезли в таблицу затухания по смещению в десятки тайлов - "list index
///out of bounds" в LUM_FALLOFF, 166 рантаймов за один ресет.
/datum/unit_test/turf_template_copy_keeps_own_lighting/Run()
	var/turf/copy_target = run_loc_floor_bottom_left
	var/turf/template = locate(copy_target.x + 1, copy_target.y, copy_target.z)
	TEST_ASSERT_NOTNULL(template, "Sanity: соседний турф резервации должен существовать")

	copy_target.generate_missing_corners()
	template.generate_missing_corners()
	var/datum/lighting_corner/own_corner = copy_target.lc_topleft
	var/atom/movable/lighting_object/own_object = copy_target.lighting_object
	TEST_ASSERT_NOTNULL(own_corner, "Sanity: у турфа-приёмника должен быть свой верхний левый угол")
	TEST_ASSERT_NOTEQUAL(own_corner, template.lc_topleft, "Sanity: соседние по горизонтали турфы не делят верхний левый угол")

	var/saved_desc = copy_target.desc
	var/saved_template_desc = template.desc
	var/list/saved_sources = template.light_sources
	var/list/template_sources = list()
	template.light_sources = template_sources
	template.desc = "шаблонное описание"

	copy_target.copy_template_vars(template)

	template.light_sources = saved_sources
	template.desc = saved_template_desc
	var/list/copied_sources = copy_target.light_sources
	var/copied_corner = copy_target.lc_topleft
	var/copied_object = copy_target.lighting_object
	var/copied_desc = copy_target.desc
	copy_target.desc = saved_desc

	TEST_ASSERT_EQUAL(copied_desc, "шаблонное описание", "Обычные вары шаблона должны переноситься")
	TEST_ASSERT_EQUAL(copied_corner, own_corner, "Углы освещения шаблона не должны подменять собственные углы приёмника")
	TEST_ASSERT_EQUAL(copied_object, own_object, "lighting_object шаблона не должен подменять собственный оверлей приёмника")
	TEST_ASSERT_NOTEQUAL(copied_sources, template_sources, "Список источников света шаблона не должен переезжать на копию")

///Отсутствующая запись сейвфайла приезжает в safe_json_decode как null. Это не битый
///JSON, и трейс на него давал под две сотни рантаймов за раунд на пустом месте.
/datum/unit_test/safe_json_decode_ignores_empty_input/Run()
	TEST_ASSERT_NULL(safe_json_decode(null), "null должен разбираться в null")
	TEST_ASSERT_NULL(safe_json_decode(""), "пустая строка должна разбираться в null")

	var/list/decoded = safe_json_decode("{\"a\":1}")
	TEST_ASSERT_NOTNULL(decoded, "Валидный JSON должен разбираться")
	TEST_ASSERT_EQUAL(decoded["a"], 1, "Валидный JSON должен сохранять значения")

///call(/тип/proc/имя)(src, ...) зовёт прок как глобальный: src внутри null. Огнемётный
///снаряд так падал на fired_from каждым попаданием, а баллистический снаряд КА - на
///projectile_phasing. Оба должны доходить до родителя штатной цепочкой.
/datum/unit_test/parent_proc_calls_keep_src/Run()
	var/turf/open/impact_turf = run_loc_floor_bottom_left
	var/obj/item/crowbar/target = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)

	var/obj/item/projectile/bullet/flamethrower/flame = allocate(/obj/item/projectile/bullet/flamethrower, run_loc_floor_bottom_left)
	var/flame_result = flame.on_hit(target)
	if(istype(impact_turf))
		QDEL_NULL(impact_turf.turf_fire)
	TEST_ASSERT_EQUAL(flame_result, BULLET_ACT_HIT, "on_hit огнемётного снаряда должен доходить до родителя со своим src")

	var/obj/item/projectile/kinetic/etenmm/kinetic_round = allocate(/obj/item/projectile/kinetic/etenmm, run_loc_floor_bottom_left)
	var/starting_damage = kinetic_round.damage
	TEST_ASSERT_EQUAL(kinetic_round.prehit_pierce(target), PROJECTILE_PIERCE_NONE, "Баллистический снаряд КА должен останавливаться на цели")
	TEST_ASSERT_EQUAL(kinetic_round.damage, starting_damage, "Штраф давления не должен применяться к баллистическому снаряду КА")
	TEST_ASSERT(!kinetic_round.pressure_decrease_active, "Флаг штрафа давления должен остаться снятым")

///Осмотр стреляной гильзы падал на BB.armour_penetration: снаряда в ней уже нет.
/datum/unit_test/spent_casing_examine_without_projectile/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/ammo_casing/spent/casing = allocate(/obj/item/ammo_casing/spent, run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(casing.BB, "Sanity: у стреляной гильзы не должно быть снаряда")

	var/list/examine_text = casing.examine(viewer)
	TEST_ASSERT_NOTNULL(examine_text, "Осмотр стреляной гильзы должен возвращать текст, а не падать")
