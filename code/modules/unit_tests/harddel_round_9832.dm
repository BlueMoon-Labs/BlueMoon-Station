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

/// Рана обязана отцепиться от конечности при удалении даже с обнулённой жертвой.
///
/// QDELETED(null) в DM истинно, поэтому условие `if(!QDELETED(victim)) remove_wound(...)`
/// у раны с уже обнулённой жертвой не вызывало remove_wound() вовсе, и рана оставалась в
/// limb.wounds. Через порог warnfail её добивал del(), запись превращалась в null, и
/// get_bleed_rate() падал на каждом тике SSmobs до конца раунда: прод-раунд 9834 - около
/// двух тысяч рантаймов Cannot read null.blood_flow с одной конечности.
/datum/unit_test/wound_detaches_without_victim
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/wound_detaches_without_victim/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, floor)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm, "У тестового человека нет левой руки - тест ничего не проверяет")

	var/datum/wound/slash/moderate/cut = new
	cut.apply_wound(arm, silent = TRUE)
	TEST_ASSERT(cut in arm.wounds, "Рана не легла в список конечности - тест ничего не проверяет")

	// Ровно то состояние, что даёт null_victim() по сигналу удаления жертвы.
	cut.victim = null
	qdel(cut)

	TEST_ASSERT(!(cut in arm.wounds), "Рана с обнулённой жертвой не отцепилась от конечности: список получит null и get_bleed_rate начнёт рантаймить каждый тик")
	for(var/entry in arm.wounds)
		TEST_ASSERT_NOTNULL(entry, "В списке ран конечности осталась пустая запись")

	// Страховка на стороне чтения: даже подсунутый null не должен ронять расчёт крови.
	LAZYADD(arm.wounds, null)
	arm.get_bleed_rate()
	TEST_ASSERT(!(null in arm.wounds), "get_bleed_rate обязан вычищать пустые записи из списка ран")

/// Пришитая обратно конечность обязана сохранить свои раны.
///
/// drop_limb() снимает раны из all_wounds жертвы, но оставляет их в wounds конечности.
/// Из-за этого проверка дублей в apply_wound() сравнивала рану сама с собой и делала ей
/// qdel: конечность возвращалась чистой, а список правился прямо в обходе по нему.
/datum/unit_test/reattached_limb_keeps_wounds
	parent_type = /datum/unit_test/harddel_9813_base

/datum/unit_test/reattached_limb_keeps_wounds/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, floor)
	var/obj/item/bodypart/arm = patient.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm, "У тестового человека нет левой руки - тест ничего не проверяет")

	var/datum/wound/slash/moderate/cut = new
	cut.apply_wound(arm, silent = TRUE)

	arm.drop_limb()
	TEST_ASSERT(cut in arm.wounds, "После отрыва рана обязана остаться на самой конечности")

	arm.attach_limb(patient)

	TEST_ASSERT(!QDELETED(cut), "Пришивание конечности удалило её собственную рану")
	TEST_ASSERT(cut in arm.wounds, "Пришитая конечность потеряла свою рану")
	TEST_ASSERT_EQUAL(cut.victim, patient, "Рана не вернулась к владельцу конечности")
	TEST_ASSERT(cut in patient.all_wounds, "Рана не вернулась в список ран владельца")
	// Алерт один на все раны: отрыв конечности снял его через remove_wound(), и вернуть его
	// больше некому - throw_alert зовётся только из apply_wound().
	TEST_ASSERT_NOTNULL(patient.alerts["wound"], "Пришитая рана осталась без алерта: он снят при отрыве и обратно не выставлен")

	// Ни один список не имеет права получить второй экземпляр той же раны: apply_wound() на
	// уже привязанной ране дублировал бы и записи, и подписку на удаление жертвы.
	var/copies_on_limb = 0
	for(var/datum/wound/entry as anything in arm.wounds)
		if(entry == cut)
			copies_on_limb++
	TEST_ASSERT_EQUAL(copies_on_limb, 1, "Рана продублировалась в списке конечности при пришивании")

	var/copies_on_victim = 0
	for(var/datum/wound/entry as anything in patient.all_wounds)
		if(entry == cut)
			copies_on_victim++
	TEST_ASSERT_EQUAL(copies_on_victim, 1, "Рана продублировалась в списке ран владельца при пришивании")
