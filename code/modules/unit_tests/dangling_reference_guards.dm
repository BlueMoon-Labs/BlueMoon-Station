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
	var/turf/template = get_step(copy_target, EAST)
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
	var/list/own_sources = copy_target.light_sources
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
	copy_target.light_sources = own_sources
	copy_target.desc = saved_desc

	TEST_ASSERT_EQUAL(copied_desc, "шаблонное описание", "Обычные вары шаблона должны переноситься")
	TEST_ASSERT_EQUAL(copied_corner, own_corner, "Углы освещения шаблона не должны подменять собственные углы приёмника")
	TEST_ASSERT_EQUAL(copied_object, own_object, "lighting_object шаблона не должен подменять собственный оверлей приёмника")
	TEST_ASSERT_NOTEQUAL(copied_sources, template_sources, "Список источников света шаблона не должен переезжать на копию")
	TEST_ASSERT_EQUAL(copied_sources, own_sources, "Собственный список источников света приёмника должен остаться нетронутым")

///Тот же перенос варов, но через списки: мелкая .Copy() отсеивала одиночную ссылку
///на датум и молча тащила список таких же ссылок. Копия становилась вторым держателем
///атомов из vis_contents и HUD-датумов шаблона, а её Destroy дёргал чужое хозяйство.
///Аппирансы при этом не владение, а значение внешнего вида - они переезжать обязаны.
/datum/unit_test/turf_template_copy_drops_datum_lists/Run()
	var/turf/copy_target = run_loc_floor_bottom_left
	var/turf/template = get_step(copy_target, EAST)
	TEST_ASSERT_NOTNULL(template, "Sanity: соседний турф резервации должен существовать")

	var/obj/item/crowbar/template_prop = allocate(/obj/item/crowbar, template)
	var/list/saved_template_filters = template.filter_data
	var/list/saved_own_filters = copy_target.filter_data
	var/list/saved_template_vis = template.vis_contents.Copy()
	var/list/saved_own_vis = copy_target.vis_contents.Copy()

	//датум и в ключе, и в значении, и во вложенном списке - все три пути чистки
	template.filter_data = list(
		"держатель" = template_prop,
		template_prop = "датум-ключ",
		"обычная" = "строка",
		"аппиранс" = template_prop.appearance,
		"вложенная" = list(template_prop, "уцелевшая строка")
		)
	template.vis_contents += template_prop

	copy_target.copy_template_vars(template)

	var/list/copied_filters = copy_target.filter_data
	var/list/copied_vis = copy_target.vis_contents.Copy()
	template.filter_data = saved_template_filters
	template.vis_contents = saved_template_vis
	copy_target.filter_data = saved_own_filters
	copy_target.vis_contents = saved_own_vis

	TEST_ASSERT_NOTNULL(copied_filters, "Список шаблона должен доезжать до копии, а не теряться целиком")
	TEST_ASSERT(!(template_prop in copied_filters), "Датум шаблона не должен остаться ключом в списке копии")
	TEST_ASSERT(!("держатель" in copied_filters), "Запись со значением-датумом не должна остаться в списке копии")
	TEST_ASSERT_EQUAL(copied_filters["обычная"], "строка", "Не-датумные записи должны переживать чистку")
	TEST_ASSERT_NOTNULL(copied_filters["аппиранс"], "Аппиранс - значение внешнего вида, его чистка выкидывать не должна")
	var/list/copied_nested = copied_filters["вложенная"]
	TEST_ASSERT_NOTNULL(copied_nested, "Вложенный список должен доезжать до копии")
	TEST_ASSERT(!(template_prop in copied_nested), "Датум шаблона не должен остаться во вложенном списке")
	TEST_ASSERT(("уцелевшая строка" in copied_nested), "Не-датумные записи вложенного списка должны переживать чистку")
	TEST_ASSERT(!(template_prop in copied_vis), "Атом из vis_contents шаблона не должен оседать в vis_contents копии")

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
