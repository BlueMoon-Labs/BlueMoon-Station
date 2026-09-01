/// Все экранные объекты, которые ВСЁ ЕЩЁ привязаны к переданному HUD.
///
/// Проверять по спискам самого HUD бессмысленно: в них по определению лежит
/// только то, что HUD не потерял, а вся эта пачка тестов как раз про потерянное.
/// Привязка делается в `/atom/movable/screen/set_new_hud` подпиской на
/// COMSIG_PARENT_QDELETING самого HUD, поэтому обратный список слушателей
/// (`comp_lookup`) - единственный способ увидеть экраны, которых в списках нет.
/datum/unit_test/proc/screens_bound_to_hud(datum/hud/hud)
	var/list/found = list()
	var/list/lookup = hud.comp_lookup
	if(!lookup)
		return found
	//В comp_lookup лежит либо один слушатель, либо ассоц-список слушателей
	var/listeners = lookup[COMSIG_PARENT_QDELETING]
	if(isnull(listeners))
		return found
	if(islist(listeners))
		for(var/atom/movable/screen/listener in listeners)
			found += listener
	else if(istype(listeners, /atom/movable/screen))
		found += listeners
	return found

/// HUD обязан уносить с собой ВСЕ экранные объекты, которые завёл, а не только
/// те, что доехали до его списков. Раунды 10050/10054 показали обратное: перепись
/// прода набирала по +315 /atom/movable/screen/plane_master/wall и столько же
/// above_wall за 25 минут при живом населении в 110 человек.
/datum/unit_test/hud_destroy_frees_bound_screens

/datum/unit_test/hud_destroy_frees_bound_screens/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)

	var/list/bound = screens_bound_to_hud(hud)
	TEST_ASSERT(length(bound) > 10, "HUD человека завёл всего [length(bound)] экранных объектов - предпосылка теста сломана")

	allocated -= owner
	qdel(owner)

	var/list/survivors = list()
	for(var/atom/movable/screen/leftover as anything in bound)
		if(!QDELETED(leftover))
			survivors += "[leftover.type]"
	TEST_ASSERT(!length(survivors), "Удаление моба оставило живыми экранные объекты HUD: [survivors.Join(", ")]")

/// WALL_PLANE, ABOVE_WALL_PLANE и GAME_PLANE объявлены одним и тем же числом, а
/// `plane_masters` ключуется номером плоскости - значит из трёх плейн-мастеров в
/// списке остаётся один. Двух вытесненных обязан удалять сам конструктор: в
/// списке их нет, а `hud/Destroy` чистит именно список.
/datum/unit_test/hud_plane_master_key_collision_leaves_no_orphans

/datum/unit_test/hud_plane_master_key_collision_leaves_no_orphans/Run()
	var/list/planes_seen = list()
	for(var/atom/movable/screen/plane_master/prototype as anything in subtypesof(/atom/movable/screen/plane_master))
		var/plane_key = "[initial(prototype.plane)]"
		planes_seen[plane_key] = TRUE
	// Коллизий может и не быть (мульти-Z разводит плоскости по разным номерам) - тогда
	// проверка ниже вырождается в "на каждую плоскость ровно один мастер и ни одного
	// сироты", что само по себе инвариант и без коллизий.

	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/hud = new(owner)
	owner.set_hud_used(hud)

	TEST_ASSERT_EQUAL(length(hud.plane_masters), length(planes_seen), "В plane_masters оказалось не по одному плейн-мастеру на плоскость")

	var/list/orphans = list()
	for(var/atom/movable/screen/plane_master/live_master in screens_bound_to_hud(hud))
		if(hud.plane_masters["[live_master.plane]"] != live_master)
			orphans += "[live_master.type]"
	TEST_ASSERT(!length(orphans), "Вытесненные из plane_masters плейн-мастеры остались жить: [orphans.Join(", ")]")

/// `build_hand_slots()` выбрасывает старые слоты рук из `static_inventory` - и это
/// единственный список, который обходит QDEL_LIST в `hud/Destroy`. Без удаления на
/// месте каждая пересборка рук (смена их числа, смена стиля интерфейса) оставляла
/// экраны жить до конца раунда.
/datum/unit_test/hud_hand_rebuild_frees_old_slots

/datum/unit_test/hud_hand_rebuild_frees_old_slots/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(owner)
	owner.set_hud_used(hud)

	var/list/old_hands = list()
	for(var/hand_index in hud.hand_slots)
		old_hands += hud.hand_slots[hand_index]
	TEST_ASSERT(length(old_hands) >= 2, "У человека набралось [length(old_hands)] слотов рук - предпосылка теста сломана")

	var/inventory_before = length(hud.static_inventory)
	hud.build_hand_slots()

	var/list/survivors = list()
	for(var/atom/movable/screen/inventory/hand/old_hand as anything in old_hands)
		if(!QDELETED(old_hand))
			survivors += "[old_hand.name]"
	TEST_ASSERT(!length(survivors), "Пересборка рук оставила живыми старые слоты: [survivors.Join(", ")]")
	TEST_ASSERT_EQUAL(length(hud.static_inventory), inventory_before, "Пересборка рук изменила размер static_inventory")

/// Числовой режим витрины хранилища заводил свой item_holder мимо пула на каждый
/// тип предмета при КАЖДОЙ перерисовке, а `_recycle_ui_objects` складывал
/// показанные экраны в `GLOB.storage_item_holder_pool`, откуда числовой режим их никогда не
/// доставал. Пул рос до конца раунда: перепись прода давала +219 и +170
/// /atom/movable/screen/storage/item_holder за интервал.
/datum/unit_test/storage_numerical_display_reuses_pool

/datum/unit_test/storage_numerical_display_reuses_pool/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/hud/human/hud = new(viewer)
	viewer.set_hud_used(hud)

	var/obj/item/storage/bag/trash/bag = allocate(/obj/item/storage/bag/trash, run_loc_floor_bottom_left)
	var/datum/component/storage/storage = bag.GetComponent(/datum/component/storage)
	TEST_ASSERT_NOTNULL(storage, "У мусорного мешка нет компонента хранилища")
	TEST_ASSERT(storage.display_numerical_stacking, "Мешок перестал показывать содержимое числом - тест проверяет не тот случай")

	//Два разных типа: числовая витрина группирует содержимое именно по типу
	var/obj/item/paper/first_sheet = allocate(/obj/item/paper, run_loc_floor_bottom_left)
	var/obj/item/paper/second_sheet = allocate(/obj/item/paper, run_loc_floor_bottom_left)
	var/obj/item/pen/only_pen = allocate(/obj/item/pen, run_loc_floor_bottom_left)
	first_sheet.forceMove(bag)
	second_sheet.forceMove(bag)
	only_pen.forceMove(bag)

	var/list/first_pass = storage.orient2hud_legacy(viewer, 7)
	var/list/first_holders = list()
	for(var/atom/movable/screen/storage/item_holder/holder in first_pass)
		first_holders += holder
	TEST_ASSERT_EQUAL(length(first_holders), 2, "Числовая витрина отдала [length(first_holders)] экранов вместо двух (по одному на тип)")

	//Пул общий на все хранилища и без сна его никто, кроме нас, не двигает
	var/pool_before = length(GLOB.storage_item_holder_pool)
	storage._recycle_ui_objects(first_pass)
	TEST_ASSERT_EQUAL(length(GLOB.storage_item_holder_pool), pool_before + 2, "Переработка не вернула экраны предметов в пул")

	var/list/second_pass = storage.orient2hud_legacy(viewer, 7)
	var/list/fresh = list()
	for(var/atom/movable/screen/storage/item_holder/holder in second_pass)
		if(!(holder in first_holders))
			fresh += "[holder.our_item]"
	TEST_ASSERT(!length(fresh), "Вторая отрисовка завела новые экраны вместо пула: [fresh.Join(", ")]")
	storage._recycle_ui_objects(second_pass)

/// Мониторы нейроинтерфейса крутятся на SSfastprocess сами по себе, а гостинг
/// владельца только рвёт ссылку на клиента. Уборку вытесненных записей делает
/// только UpdateVision, до которого `compile_display` при отсутствии клиента не
/// доходил - и каждая секунда без клиента оставляла бессмертный
/// /atom/movable/screen/text (раунд 10054: +2140 за интервал).
/datum/unit_test/neural_interface_drains_screens_without_client

/datum/unit_test/neural_interface_drains_screens_without_client/Run()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/component/neural_interface/interface = wearer.LoadComponent(/datum/component/neural_interface)
	TEST_ASSERT_NOTNULL(interface, "Нейроинтерфейс не встал на моба")

	var/datum/neural_interface_module/image_highlight/module = interface.modules["image"]
	TEST_ASSERT_NOTNULL(module, "У нейроинтерфейса нет модуля подсветки")

	//Мобу теста клиент не выдать, а это ровно то состояние, в котором интерфейс
	//остаётся после гостинга владельца: мониторы живы, клиента нет
	interface.is_client_attached = FALSE
	interface.attached_client = null

	interface.write_image_data("TEST", image(icon = 'icons/mob/screen_gen.dmi'), wearer, "", 30 SECONDS)
	TEST_ASSERT_EQUAL(length(module.image_data_entries), 1, "Первая запись подсветки не завелась")
	var/datum/image_holder_data/displaced = module.image_data_entries[1]
	var/atom/movable/screen/text/displaced_text = displaced.screen_text
	TEST_ASSERT_NOTNULL(displaced_text, "У записи подсветки нет экранного объекта")

	//Тот же ключ - старая запись уезжает в очередь на уборку
	interface.write_image_data("TEST", image(icon = 'icons/mob/screen_gen.dmi'), wearer, "", 30 SECONDS)
	TEST_ASSERT(!QDELETED(displaced_text), "Вытесненная запись удалилась до уборки - тест проверяет не тот случай")

	interface.compile_display()
	TEST_ASSERT(QDELETED(displaced_text), "Без клиента уборка вытесненных записей не запускается, экранный объект остаётся жить")

	//Живая запись обязана уходить вместе с модулем
	TEST_ASSERT_EQUAL(length(module.image_data_entries), 1, "После уборки в модуле осталась не одна запись")
	var/datum/image_holder_data/survivor = module.image_data_entries[1]
	var/atom/movable/screen/text/survivor_text = survivor.screen_text
	TEST_ASSERT_NOTNULL(survivor_text, "У пережившей уборку записи нет экранного объекта")

	qdel(interface)
	TEST_ASSERT(QDELETED(survivor_text), "Удаление нейроинтерфейса оставило экранный объект живой записи")
