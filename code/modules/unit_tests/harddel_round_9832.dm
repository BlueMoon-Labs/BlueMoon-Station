/// Регрессии по прод-раунду 9832 (2026-07-30).
///
/// В том раунде 14 из 31 GC-warnfail'а пришлись на предметы, побывавшие в руках
/// (десять писем, поджжённых в 03:45, две монеты, кусачки, маяк капеллана) - все ровно
/// с одной внешней ссылкой. Держатель - запись в client.screen орбитящего госта: её
/// добавляет update_inv_hands()/update_observer_view(), а снимали её только на части
/// путей выхода предмета из руки.
///
/// Проверить сам client.screen в CI нельзя - у тестовых мобов нет клиента. Поэтому
/// тесты держат контракт на воронку: каждый путь, уносящий предмет из руки, обязан
/// пройти через remove_from_hud_screens(). Если кто-то снова впишет "client.screen -= I"
/// напрямую, мимо наблюдателей, эти тесты упадут.

/// Моб-зонд: запоминает, какие предметы прошли через воронку снятия с экранов.
/mob/living/carbon/human/screen_funnel_probe
	var/list/funnelled = list()

/mob/living/carbon/human/screen_funnel_probe/remove_from_hud_screens(obj/item/I)
	if(!isnull(I))
		funnelled += I
	return ..()

/datum/unit_test/hud_screen_funnel
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/hud_screen_funnel/Run()
	drop_to_ground_goes_through_funnel()
	qdel_in_hand_goes_through_funnel()
	uncuff_goes_through_funnel()
	equip_from_hand_goes_through_funnel()
	clientless_observers_do_not_runtime()

/// Обычный дроп на пол: doUnEquip.
/datum/unit_test/hud_screen_funnel/proc/drop_to_ground_goes_through_funnel()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/screen_funnel_probe/user = allocate(/mob/living/carbon/human/screen_funnel_probe, floor)
	var/obj/item/paper/note = allocate(/obj/item/paper, floor)

	user.put_in_active_hand(note, forced = TRUE)
	TEST_ASSERT_EQUAL(note.loc, user, "Предмет не оказался в руке - тест ничего не проверяет")

	user.funnelled.Cut()
	user.dropItemToGround(note, TRUE)

	TEST_ASSERT(note in user.funnelled, "dropItemToGround не прошёл через remove_from_hud_screens: экран наблюдателя сохранит ссылку на предмет")

/// qdel предмета прямо в руке: путь /obj/item/doMove, а не doUnEquip.
/datum/unit_test/hud_screen_funnel/proc/qdel_in_hand_goes_through_funnel()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/screen_funnel_probe/user = allocate(/mob/living/carbon/human/screen_funnel_probe, floor)
	var/obj/item/coin/silver/coin = allocate(/obj/item/coin/silver, floor)

	user.put_in_active_hand(coin, forced = TRUE)
	TEST_ASSERT_EQUAL(coin.loc, user, "Монета не оказалась в руке - тест ничего не проверяет")

	user.funnelled.Cut()
	allocated -= coin
	qdel(coin)

	TEST_ASSERT(coin in user.funnelled, "qdel предмета в руке не прошёл через remove_from_hud_screens - ровно этот путь дал утечку писем и монет в раунде 9832")

/// Наручники живут в отдельном слоте и снимаются своим проком.
/datum/unit_test/hud_screen_funnel/proc/uncuff_goes_through_funnel()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/screen_funnel_probe/user = allocate(/mob/living/carbon/human/screen_funnel_probe, floor)
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, floor)

	user.handcuffed = cuffs
	cuffs.forceMove(user)
	user.funnelled.Cut()

	user.uncuff()

	TEST_ASSERT_NULL(user.handcuffed, "uncuff() не снял наручники - тест ничего не проверяет")
	TEST_ASSERT(cuffs in user.funnelled, "uncuff() не прошёл через remove_from_hud_screens")

/// Переезд из руки в слот одежды: этот путь наблюдателей чистил и раньше, тест
/// закрепляет, что он остался на общей воронке и не разъехался с остальными.
/datum/unit_test/hud_screen_funnel/proc/equip_from_hand_goes_through_funnel()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/screen_funnel_probe/user = allocate(/mob/living/carbon/human/screen_funnel_probe, floor)
	var/obj/item/clothing/head/helmet/helmet = allocate(/obj/item/clothing/head/helmet, floor)

	user.put_in_active_hand(helmet, forced = TRUE)
	user.funnelled.Cut()

	user.equip_to_slot(helmet, ITEM_SLOT_HEAD)

	TEST_ASSERT_EQUAL(user.head, helmet, "Шлем не надет - тест ничего не проверяет")
	TEST_ASSERT(helmet in user.funnelled, "equip_to_slot не прошёл через remove_from_hud_screens")

/// В observers может лежать гост, у которого клиент уже ушёл: воронка обязана это
/// терпеть, иначе любой дроп станет рантаймом.
/datum/unit_test/hud_screen_funnel/proc/clientless_observers_do_not_runtime()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)
	var/obj/item/paper/note = allocate(/obj/item/paper, floor)
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)

	LAZYINITLIST(user.observers)
	user.observers |= ghost
	user.put_in_active_hand(note, forced = TRUE)

	user.dropItemToGround(note, TRUE)

	TEST_ASSERT_EQUAL(note.loc, floor, "Предмет не упал на пол: воронка сломала обычный дроп")
	TEST_ASSERT_NULL(note.screen_loc, "screen_loc предмета не сброшен при дропе")

/// Магазин лежит в contents ствола, но общий /obj/item/gun/handle_atom_del его не чистит -
/// перечислены только pin, chambered, bayonet и gun_light. Из-за этого удаление магазина внутри
/// ствола (модкит, разбор, админский del) оставляло висячую ссылку, и следующий attack_self
/// делал forceMove мертвецу: рантаймы "doMove qdel-нутого .../magazine/e45" в раунде 9827.
/datum/unit_test/ballistic_gun_forgets_deleted_magazine
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/ballistic_gun_forgets_deleted_magazine/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/item/gun/ballistic/automatic/pistol/enforcer/gun = allocate(/obj/item/gun/ballistic/automatic/pistol/enforcer, floor)

	var/obj/item/ammo_box/magazine/loaded = gun.magazine
	TEST_ASSERT_NOTNULL(loaded, "Заводской ствол приехал без магазина - тест ничего не проверяет")
	TEST_ASSERT_EQUAL(loaded.loc, gun, "Магазин не в contents ствола - тест ничего не проверяет")

	qdel(loaded)

	TEST_ASSERT_NULL(gun.magazine, "Ствол сохранил ссылку на удалённый магазин: handle_atom_del его не обнулил")
