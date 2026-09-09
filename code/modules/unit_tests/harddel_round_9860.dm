/// Регрессии по hard delete из прод-раундов 9859/9860 (2026-08-02).
/// В комментариях к тестам - замер из runtime.log: строка
/// "## GC: ... не собрался (warnfail, ~120с, внешних ссылок: N)".

/datum/unit_test/harddel_9860_base
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/harddel_9860_base/Run()
	return

/// Паучок лез по вентиляции через spawn() с вложенными sleep. Цепочка держала его
/// жёсткой ссылкой и последним шагом возвращала forceMove'ом в contents живого
/// вентиля уже ПОСЛЕ qdel. Раунд 9860: восемь рантаймов "doMove qdel-нутого
/// /obj/structure/spider/spiderling/nurse" и 13 хардделов паучков - больше, чем
/// у любого другого типа, кроме решёток и окон.
/datum/unit_test/spiderling_vent_travel_releases_on_qdel
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/spiderling_vent_travel_releases_on_qdel/proc/qdel_mid_travel(obj/machinery/atmospherics/components/unary/vent_pump/entry, obj/machinery/atmospherics/components/unary/vent_pump/exit)
	var/obj/structure/spider/spiderling/crawler = allocate(/obj/structure/spider/spiderling, get_turf(entry))
	crawler.entry_vent = entry
	crawler.vent_travel_exit = exit
	crawler.vent_travel_enter()

	TEST_ASSERT_EQUAL(crawler.loc, entry, "Паучок не забрался в вентиль")
	var/timer_id = crawler.vent_travel_timer
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timer_id], "Отложенный шаг прогулки не встал в SStimer")

	var/list/record = target_record(crawler, "паучок посреди прогулки по вентиляции")
	// Тест владеет паучком сам: разбор теста не должен держать его до конца Run().
	allocated -= crawler
	qdel(crawler)

	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer_id], "Destroy не снял отложенный шаг прогулки")
	TEST_ASSERT_NULL(crawler.entry_vent, "Удалённый паучок продолжает держать вентиль входа")
	TEST_ASSERT_NULL(crawler.vent_travel_exit, "Удалённый паучок продолжает держать вентиль выхода")
	TEST_ASSERT(!(crawler in entry.contents), "Удалённый паучок остался в contents вентиля")
	return record

/datum/unit_test/spiderling_vent_travel_releases_on_qdel/Run()
	begin_isolated_gc()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/machinery/atmospherics/components/unary/vent_pump/entry = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, floor)
	var/obj/machinery/atmospherics/components/unary/vent_pump/exit = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, get_step(floor, EAST))

	var/list/record = qdel_mid_travel(entry, exit)
	if(!record)
		return
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_soft_collected(record)

/// Заваренный вентиль на выходе: прежний код делал forceMove обратно ВНУТРЬ вентиля
/// входа и обнулял entry_vent. travelling_in_vent сбрасывался только по isturf(loc),
/// то есть паучок оставался в contents машины навсегда.
/datum/unit_test/spiderling_blocked_vent_returns_to_floor
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/spiderling_blocked_vent_returns_to_floor/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/machinery/atmospherics/components/unary/vent_pump/entry = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, floor)
	var/obj/machinery/atmospherics/components/unary/vent_pump/exit = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, get_step(floor, EAST))
	var/obj/structure/spider/spiderling/crawler = allocate(/obj/structure/spider/spiderling, floor)

	crawler.entry_vent = entry
	crawler.vent_travel_exit = exit
	crawler.vent_travel_enter()
	TEST_ASSERT_EQUAL(crawler.loc, entry, "Паучок не забрался в вентиль")

	exit.welded = TRUE
	crawler.vent_travel_halfway(1)

	TEST_ASSERT_EQUAL(crawler.loc, floor, "Паучок остался в вентиле, хотя выход заварили")
	TEST_ASSERT_NULL(crawler.entry_vent, "entry_vent не сброшен после отмены прогулки")
	TEST_ASSERT_NULL(crawler.vent_travel_exit, "vent_travel_exit не сброшен после отмены прогулки")
	TEST_ASSERT_NULL(crawler.vent_travel_timer, "После отмены прогулки остался живой таймер")
	TEST_ASSERT_EQUAL(crawler.travelling_in_vent, 0, "Флаг путешествия по вентиляции остался поднятым")

/// falling_atoms у /datum/component/chasm - static, то есть один список на всю карту
/// и на весь раунд. Ветка "в забвение" спит секунду и выходила по QDELETED мимо
/// снятия ключа: удалённый в полёте моб оставался в этом списке навсегда. Трупы
/// тендрилов падают именно туда - обвал тендрила делает вокруг себя лавовые
/// пропасти без нижнего z-уровня. Раунды 9859/9860: goliath/beast/tendril (318.6мс)
/// и basilisk/watcher/tendril (114мс), у обоих ровно одна внешняя ссылка.
/datum/unit_test/chasm_drop_releases_qdeleted_faller
	parent_type = /datum/unit_test/harddel_9860_base
	priority = TEST_LONGER

/datum/unit_test/chasm_drop_releases_qdeleted_faller/Run()
	var/turf/floor = run_loc_floor_bottom_left
	// Компонент вешаем на эффект, а не на турф: на турфе он ловил бы COMSIG_ATOM_ENTERED
	// и ронял в забвение чужие атомы теста.
	var/obj/effect/pit_host = allocate(/obj/effect, floor)
	var/datum/component/chasm/pit = pit_host.AddComponent(/datum/component/chasm, null)
	TEST_ASSERT_NOTNULL(pit, "Компонент пропасти не повесился")

	var/obj/item/faller = allocate(/obj/item, floor)
	INVOKE_ASYNC(pit, TYPE_PROC_REF(/datum/component/chasm, drop), faller)
	TEST_ASSERT(faller in pit.falling_atoms, "drop() не поставил предмет на учёт падения")

	qdel(faller)
	// Анимация падения - пять шагов по 2 деци; ждём с запасом.
	sleep(3 SECONDS)
	TEST_ASSERT(!(faller in pit.falling_atoms), "Удалённый в полёте предмет остался ключом в falling_atoms")

/// cleanbot/Destroy отдавал живой нож в drop_part, который ждёт ТИППАТ и делает по
/// нему new(). Раунд 9859: "new() called with an object of type /obj/item/kitchen/knife
/// instead of the type path itself" прямо в Destroy(0) - и весь остаток разбора бота
/// (janitor_devices, bots_list, bot_core, Radio, родительский Destroy) не выполнялся.
/datum/unit_test/cleanbot_teardown_survives_deputized_weapon
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/cleanbot_teardown_survives_deputized_weapon/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/bot/cleanbot/janitor = allocate(/mob/living/simple_animal/bot/cleanbot, floor)
	var/obj/item/kitchen/knife/blade = allocate(/obj/item/kitchen/knife, floor)

	blade.forceMove(janitor)
	janitor.weapon = blade
	janitor.weapon_orig_force = blade.force

	TEST_ASSERT(janitor in GLOB.janitor_devices, "Уборщик не попал в GLOB.janitor_devices")
	TEST_ASSERT(janitor in GLOB.bots_list, "Уборщик не попал в GLOB.bots_list")

	qdel(janitor)

	TEST_ASSERT(!(janitor in GLOB.janitor_devices), "Уборщик остался в GLOB.janitor_devices")
	TEST_ASSERT(!(janitor in GLOB.bots_list), "Разбор уборщика не дошёл до родительского Destroy")
	TEST_ASSERT_NULL(janitor.bot_core, "Разбор уборщика не дошёл до ядра")
	TEST_ASSERT_NULL(janitor.weapon, "Уборщик продолжает держать выданное оружие")
	TEST_ASSERT(!QDELETED(blade), "Нож удалили вместе с ботом вместо того, чтобы выложить")
	TEST_ASSERT_EQUAL(blade.loc, floor, "Нож не выложен на пол")

/// Бот в своём Destroy делает QDEL_NULL(bot_core), но обратной ссылки ядро не рвало.
/datum/unit_test/bot_core_releases_owner
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/bot_core_releases_owner/Run()
	var/mob/living/simple_animal/bot/cleanbot/janitor = allocate(/mob/living/simple_animal/bot/cleanbot, run_loc_floor_bottom_left)
	var/obj/machinery/bot_core/core = janitor.bot_core
	TEST_ASSERT_NOTNULL(core, "У бота нет ядра")
	TEST_ASSERT_EQUAL(core.owner, janitor, "Ядро не запомнило владельца")

	qdel(core)
	TEST_ASSERT_NULL(core.owner, "Удалённое ядро продолжает держать бота")

/// GLOB.antagonists_to_remind снимал датум только когда счётчик напоминаний догорит
/// до нуля - это 2 x 12 минут. Снятый раньше антаг оставался в глобальном списке
/// навсегда, а напоминалка с пустым owner проваливалась в холостую ветку и до
/// строчки снятия не доходила никогда. Раунд 9859: /datum/antagonist/bloodsucker,
/// одна внешняя ссылка.
/datum/unit_test/antag_datum_leaves_remind_list
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/antag_datum_leaves_remind_list/proc/removed_on_destroy()
	var/datum/mind/antag_mind = new
	var/datum/antagonist/antag = new /datum/antagonist()
	antag.owner = antag_mind
	antag.reminded_times_left = 2
	GLOB.antagonists_to_remind += antag

	qdel(antag)
	TEST_ASSERT(!(antag in GLOB.antagonists_to_remind), "Удалённый антаг остался в списке напоминаний")
	qdel(antag_mind)

/datum/unit_test/antag_datum_leaves_remind_list/proc/removed_when_owner_is_gone()
	var/datum/antagonist/orphan = new /datum/antagonist()
	// Destroy() без owner пишет stack_trace, если датум не помечен как выброшенный
	orphan.discarded_before_gain = TRUE
	orphan.reminded_times_left = 2
	GLOB.antagonists_to_remind += orphan

	orphan.remind_them_they_are_antagonists()
	TEST_ASSERT(!(orphan in GLOB.antagonists_to_remind), "Напоминалка без owner не сняла себя со списка")
	qdel(orphan)

/datum/unit_test/antag_datum_leaves_remind_list/Run()
	removed_on_destroy()
	removed_when_owner_is_gone()

/// unmodify() удалял применённые компоненты, но список не чистил, а InheritComponent
/// зовёт unmodify() и следом modify(), который дописывает туда НОВЫЕ. Мёртвые
/// компоненты копились на предмете до конца раунда. Раунд 9859:
/// /datum/component/mirv, одна внешняя ссылка.
/datum/unit_test/fantasy_unmodify_clears_applied_components
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/fantasy_unmodify_clears_applied_components/Run()
	var/obj/item/gun/energy/laser/blaster = allocate(/obj/item/gun/energy/laser, run_loc_floor_bottom_left)
	var/datum/component/fantasy/enchant = blaster.AddComponent(/datum/component/fantasy, 5)
	TEST_ASSERT_NOTNULL(enchant, "Компонент фэнтези не повесился на оружие")
	// Набор аффиксов случайный и к проверке отношения не имеет: снимаем, чтобы
	// unmodify() занимался ровно тем, что проверяем.
	enchant.affixes = list()

	var/datum/component/mirv/shrapnel = blaster.AddComponent(/datum/component/mirv, /obj/item/projectile/beam/laser)
	TEST_ASSERT_NOTNULL(shrapnel, "Компонент mirv не повесился на оружие")
	enchant.appliedComponents |= shrapnel

	enchant.unmodify()
	TEST_ASSERT(QDELETED(shrapnel), "unmodify() не удалил применённый компонент")
	TEST_ASSERT(!length(enchant.appliedComponents), "unmodify() оставил удалённый компонент в appliedComponents")

/// Маркеры эхолокации тешари снимались с экрана через client МОБА, а список
/// sonar_markers не чистился вовсе - это тот же объект списка, что раздают
/// таймерам. Раунд 9859: /atom/movable/screen/sonar_ping, 114.2мс, одна ссылка.
/datum/unit_test/sonar_markers_release_after_ping
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/sonar_markers_release_after_ping/Run()
	var/mob/living/carbon/human/listener = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/list/markers = list()
	var/atom/movable/screen/sonar_ping/marker = new()
	markers += marker
	listener.sonar_markers = markers

	listener.remove_sonar_markers(markers)

	TEST_ASSERT(QDELETED(marker), "Маркер эхолокации пережил снятие")
	TEST_ASSERT(!length(markers), "Список маркеров не очищен")
	TEST_ASSERT_NULL(listener.sonar_markers, "Моб продолжает держать список удалённых маркеров")

/// close() правил children прямо во время обхода этого же списка (child.close()
/// снимает себя из него), поэтому каждый второй ребёнок оставался открытым - с
/// живыми user и src_object в списках подсистемы.
/datum/unit_test/tgui_close_closes_every_child
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/tgui_close_closes_every_child/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/host = allocate(/obj/machinery/cryopod, run_loc_floor_bottom_left)

	var/datum/tgui/root = new(viewer, host, "Root", "корень")
	var/datum/tgui/first = new(viewer, host, "First", "первый", root)
	var/datum/tgui/second = new(viewer, host, "Second", "второй", root)
	TEST_ASSERT_EQUAL(length(root.children), 2, "Оба дочерних интерфейса должны числиться у корня")

	root.close()

	TEST_ASSERT(QDELETED(first), "Первый дочерний интерфейс не закрылся")
	TEST_ASSERT(QDELETED(second), "Второй дочерний интерфейс пропущен обходом children")
	TEST_ASSERT(QDELETED(root), "Корневой интерфейс не закрылся")

/// Закрытый посреди прохода подсистемы интерфейс оставался в current_run - копии
/// open_uis на текущий проход - со всем своим user и src_object.
/datum/unit_test/tgui_unregister_drops_from_current_run
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/tgui_unregister_drops_from_current_run/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/machinery/host = allocate(/obj/machinery/cryopod, run_loc_floor_bottom_left)

	var/datum/tgui/ui = new(viewer, host, "Root", "корень")
	SStgui.current_run += ui
	SStgui.unregister_ui(ui)

	TEST_ASSERT(!(ui in SStgui.current_run), "unregister_ui не снял интерфейс с текущего прохода подсистемы")
	qdel(ui)

/// Конструктор хотспота через perform_exposure() зовёт fire_act() по содержимому
/// турфа; детонация оттуда сносит сам турф, а /turf/open/Destroy делает
/// QDEL_NULL(active_hotspot). Присваивание результата `new` возвращало удалённый
/// хотспот обратно в поле турфа: ссылка держала его до харддела (два по 540мс за
/// раунд 9860), а сам турф после этого не загорался уже никогда - обе проверки в
/// hotspot_expose видели в поле "живой" огонь.
/datum/unit_test/hotspot_expose_ignores_dead_hotspot
	parent_type = /datum/unit_test/harddel_9860_base

/datum/unit_test/hotspot_expose_ignores_dead_hotspot/Run()
	var/turf/open/spot = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(spot.air, "Тестовый турф без газовой смеси")

	spot.air.set_moles(GAS_PLASMA, 50)
	spot.air.set_moles(GAS_O2, 200)
	spot.air.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 500)

	spot.hotspot_expose(spot.air.return_temperature(), CELL_VOLUME)
	var/obj/effect/hotspot/first_fire = spot.active_hotspot
	TEST_ASSERT_NOTNULL(first_fire, "Турф с плазмой и кислородом не загорелся")

	// Воспроизводим протухшую ссылку: хотспот удалён, но поле турфа на него ещё
	// смотрит - ровно то состояние, которое оставляло присваивание после `new`.
	qdel(first_fire)
	spot.active_hotspot = first_fire
	TEST_ASSERT(QDELETED(spot.active_hotspot), "Хотспот не удалился, тест проверяет не то состояние")

	spot.air.set_moles(GAS_PLASMA, 50)
	spot.air.set_moles(GAS_O2, 200)
	spot.air.set_temperature(FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 500)
	spot.hotspot_expose(spot.air.return_temperature(), CELL_VOLUME)

	var/obj/effect/hotspot/second_fire = spot.active_hotspot
	TEST_ASSERT_NOTNULL(second_fire, "Турф с протухшей ссылкой на хотспот отказался загораться")
	TEST_ASSERT(!QDELETED(second_fire), "В поле турфа снова оказался удалённый хотспот")
	TEST_ASSERT_NOTEQUAL(second_fire, first_fire, "Турф вернул в поле тот же удалённый хотспот")

	qdel(second_fire)
	spot.air.clear()
	spot.air.set_temperature(T20C)
