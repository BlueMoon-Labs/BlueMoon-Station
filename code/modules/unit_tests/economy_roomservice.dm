/// Номер отеля с гостем и деньгами на счёте, повар на станции и окно терминала номера.
/datum/unit_test/economy_roomservice
	abstract_type = /datum/unit_test/economy_roomservice
	priority = TEST_LONGER
	var/obj/item/hilbertshotel/sphere
	var/mob/living/carbon/human/guest
	var/datum/bank_account/guest_account
	var/mob/living/carbon/human/cook
	var/datum/bank_account/cook_account
	var/obj/machinery/room_service_panel/panel
	var/datum/bank_account/department/service_budget
	var/saved_budget
	var/saved_remainder
	var/saved_drink_remainder
	var/saved_dish
	var/dish_saved = FALSE
	var/list/added_players = list()

/datum/unit_test/economy_roomservice/Destroy()
	GLOB.player_list -= added_players
	added_players.Cut()
	for(var/datum/room_service_order/order as anything in GLOB.room_service.orders.Copy())
		qdel(order)
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	if(dish_saved)
		service.dish_of_the_day = saved_dish
	if(service_budget)
		econ_test_set_balance(service_budget, saved_budget)
		service.work_remainder[WORK_SRV_DISH] = saved_remainder
		service.work_remainder[WORK_SRV_DRINK] = saved_drink_remainder
		service_budget = null
	if(guest && sphere && !QDELETED(sphere) && istype(get_area(guest), /area/hilbertshotel))
		sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	return ..()

/datum/unit_test/economy_roomservice/proc/open_room(room_number, balance)
	if(!length(SShilbertshotel.hotel_map_list))
		SShilbertshotel.prepare_rooms()
	if(!SShilbertshotel.storageTurf)
		SShilbertshotel.setup_storage_turf()
	sphere = allocate(/obj/item/hilbertshotel, run_loc_floor_bottom_left)
	sphere.anchored = TRUE
	guest = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	guest.mind_initialize()
	guest.mind.key = "econ_test_room_guest"
	guest_account = new("econ_test_room_guest")
	allocated += guest_account
	guest.account_id = guest_account.account_id
	econ_test_set_balance(guest_account, balance)
	if(!sphere.sendToNewRoom(room_number, guest, "Hotel Room"))
		return null
	panel = locate() in get_area(guest)
	return panel

/datum/unit_test/economy_roomservice/proc/hire_cook()
	cook = allocate(/mob/living/carbon/human, find_walkable_station_turf())
	cook.mind_initialize()
	cook.mind.key = "econ_test_room_cook"
	cook.mind.assigned_role = "Cook"
	cook_account = new("econ_test_room_cook")
	allocated += cook_account
	cook_account.department_id = ACCOUNT_SRV
	cook.account_id = cook_account.account_id
	GLOB.player_list |= cook
	added_players += cook
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	service_budget = service.account
	saved_budget = service_budget.account_balance
	saved_remainder = service.work_remainder[WORK_SRV_DISH]
	saved_drink_remainder = service.work_remainder[WORK_SRV_DRINK]
	service.work_remainder[WORK_SRV_DISH] = 0
	service.work_remainder[WORK_SRV_DRINK] = 0

/datum/unit_test/economy_roomservice/proc/set_dish_of_the_day(path)
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	if(!dish_saved)
		saved_dish = service.dish_of_the_day
		dish_saved = TRUE
	service.dish_of_the_day = path

/datum/unit_test/economy_roomservice/proc/chef_burger(mob/living/near)
	var/obj/item/reagent_containers/food/snacks/burger/plain/dish = burger(near)
	ADD_TRAIT(dish, TRAIT_FOOD_CHEF_MADE, REF(cook.mind))
	return dish

/datum/unit_test/economy_roomservice/proc/newest_on(turf/spot, path)
	for(var/atom/movable/thing in spot)
		if(istype(thing, path))
			. = thing

/// Действие окна терминала от имени user, как его шлёт TGUI.
/datum/unit_test/economy_roomservice/proc/act(mob/user, action, list/params)
	var/datum/tgui/window = allocate(/datum/tgui, user, panel, "RoomService")
	window.status = UI_INTERACTIVE
	COOLDOWN_RESET(panel, act_cooldown)
	usr = user
	. = panel.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_roomservice/proc/tray_for(mob/living/holder, list/items)
	var/obj/item/storage/bag/tray/room_service/tray = allocate(/obj/item/storage/bag/tray/room_service, get_turf(holder))
	holder.put_in_active_hand(tray)
	for(var/obj/item/thing as anything in items)
		SEND_SIGNAL(tray, COMSIG_TRY_STORAGE_INSERT, thing, holder, TRUE, FALSE)
	return tray

/datum/unit_test/economy_roomservice/proc/burger(mob/living/near)
	return allocate(/obj/item/reagent_containers/food/snacks/burger/plain, get_turf(near))

/datum/unit_test/economy_roomservice/proc/count_on(turf/spot, path)
	. = 0
	for(var/atom/movable/thing in spot)
		if(istype(thing, path))
			.++

/datum/unit_test/economy_roomservice/proc/panels_in(area/room)
	. = 0
	for(var/obj/machinery/room_service_panel/each in room)
		.++

/// Терминал появляется на стене у входа нового номера (не на двери), уходит с номером в хранилище и возвращается тем же, без второго; гост-кафе без терминала.
/datum/unit_test/economy_roomservice/panel_follows_room/Run()
	TEST_ASSERT_NOTNULL(open_room(6151, 0), "в новом номере нет терминала обслуживания")
	var/datum/turf_reservation/reservation = sphere.activeRooms["6151"]
	var/datum/map_template/hilbertshotel/template = SShilbertshotel.hotel_map_list["Hotel Room"]
	var/turf/landing = locate(reservation.bottom_left_coords[1] + template.landingZoneRelativeX, reservation.bottom_left_coords[2] + template.landingZoneRelativeY, reservation.bottom_left_coords[3])
	TEST_ASSERT(isturf(panel.loc) && get_dist(panel, landing) <= 2, "терминал не у входа в номер, а в [panel.loc]")
	TEST_ASSERT(panel.pixel_x || panel.pixel_y, "терминал не повешен на стену")
	var/turf/wall = get_step(panel, panel.pixel_y > 0 ? NORTH : (panel.pixel_y < 0 ? SOUTH : (panel.pixel_x > 0 ? EAST : WEST)))
	TEST_ASSERT(isclosedturf(wall) && !istype(wall, /turf/closed/indestructible/hoteldoor), "терминал висит не на стене, а на [wall?.type]")
	var/offset_x = panel.x - reservation.bottom_left_coords[1]
	var/offset_y = panel.y - reservation.bottom_left_coords[2]
	TEST_ASSERT_EQUAL(panel.room_number, 6151, "терминал не знает номер комнаты")
	TEST_ASSERT_EQUAL(panels_in(get_area(guest)), 1, "в номере не один терминал")

	sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	TEST_ASSERT(sphere.storedRooms["6151"], "номер не ушёл в хранилище")
	TEST_ASSERT(!QDELETED(panel), "терминал удалился вместе с хранением номера")
	TEST_ASSERT(istype(panel.loc, /obj/item/abstracthotelstorage), "терминал не в хранилище номера, а в [panel.loc]")
	TEST_ASSERT_NULL(panel.room_area(), "терминал в хранилище считает номер открытым")

	TEST_ASSERT(sphere.tryStoredRoom(6151, guest), "номер не восстановился")
	var/area/hilbertshotel/room = get_area(guest)
	reservation = sphere.activeRooms["6151"]
	TEST_ASSERT(panel.loc == locate(reservation.bottom_left_coords[1] + offset_x, reservation.bottom_left_coords[2] + offset_y, reservation.bottom_left_coords[3]), "терминал вернулся не на своё место")
	TEST_ASSERT_EQUAL(panels_in(room), 1, "восстановленный номер получил второй терминал")
	TEST_ASSERT(panel.room_area() == room, "восстановленный терминал не видит свой номер")

	var/obj/item/hilbertshotel/ghostdojo/ghostcafe/cafe = allocate(/obj/item/hilbertshotel/ghostdojo/ghostcafe, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/ghost_guest = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	ghost_guest.mind_initialize()
	TEST_ASSERT(cafe.sendToNewRoom(6152, ghost_guest, "Hotel Room"), "номер гост-кафе не создался")
	TEST_ASSERT_EQUAL(panels_in(get_area(ghost_guest)), 0, "в номере гост-кафе появился терминал обслуживания")
	cafe.MobTransfer(ghost_guest, run_loc_floor_bottom_left)

	var/obj/machinery/room_service_panel/stray = allocate(/obj/machinery/room_service_panel, run_loc_floor_bottom_left)
	stray.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(QDELETED(stray), "терминал, вынесенный из отеля, остался цел")

/// Заказ сервису: деньги сразу в предоплату, повар отправляет подносом только полный заказ, номер получает блюда, повар - долю, бюджет сервиса - остаток и оплату работы; повтор и возврат после доставки ничего не дают.
/datum/unit_test/economy_roomservice/staff_order_delivered/Run()
	TEST_ASSERT_NOTNULL(open_room(6153, 1000), "в номере нет терминала")
	hire_cook()
	var/datum/bank_account/escrow = GLOB.room_service.escrow_account()
	var/escrow_before = escrow.account_balance
	var/budget_before = service_budget.account_balance

	TEST_ASSERT(act(guest, "order", list("id" = "burger", "count" = 2, "route" = "staff")), "окно не приняло заказ")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 880, "предоплата не списана")
	TEST_ASSERT_EQUAL(escrow.account_balance - escrow_before, 120, "предоплата не легла на счёт обслуживания номеров")
	var/list/waiting = panel.orders()
	TEST_ASSERT_EQUAL(length(waiting), 1, "заказ не появился у терминала")
	var/datum/room_service_order/order = waiting[1]
	TEST_ASSERT_EQUAL(panel.icon_state, "dorm_inside", "терминал не показывает ждущий заказ")

	var/obj/item/reagent_containers/food/snacks/burger/plain/first = chef_burger(cook)
	var/obj/item/storage/bag/tray/room_service/tray = tray_for(cook, list(first))
	TEST_ASSERT(first.loc == tray, "бургер не лёг на поднос")
	tray.attack_self(cook)
	TEST_ASSERT(first.loc == tray, "неполный заказ ушёл в номер")
	TEST_ASSERT(!order.settled, "неполная отправка закрыла заказ")

	var/obj/item/reagent_containers/food/snacks/burger/plain/second = burger(cook)
	SEND_SIGNAL(tray, COMSIG_TRY_STORAGE_INSERT, second, cook, TRUE, FALSE)
	var/cook_before = cook_account.account_balance
	tray.attack_self(cook)
	var/turf/drop = get_turf(panel)
	TEST_ASSERT(get_turf(first) == drop && get_turf(second) == drop, "блюда не попали в номер к терминалу")
	TEST_ASSERT(first.econ_paid && second.econ_paid, "доставленные блюда засчитаются сервису второй раз, когда их съедят")
	TEST_ASSERT(!length(tray.contents), "на подносе что-то осталось")
	TEST_ASSERT(cook.is_holding(tray), "поднос ушёл вместе с заказом")
	TEST_ASSERT(order.settled, "доставка не закрыла заказ")
	TEST_ASSERT(!(order in GLOB.room_service.orders), "доставленный заказ остался в списке")

	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/share = round(120 * service.register_cashier_share / 100)
	var/work = SSeconomy.settings.work_prices[WORK_SRV_DISH]
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "предоплата осталась висеть после доставки")
	TEST_ASSERT(cook_account.account_balance - cook_before >= share, "повар не получил долю: +[cook_account.account_balance - cook_before] при доле [share]")
	TEST_ASSERT_EQUAL(service_budget.account_balance - budget_before, 120 - share + work, "бюджет сервиса не получил остаток и оплату работы только за приготовленное поваром блюдо")
	TEST_ASSERT(panel.tip_offers["[order.uid]"], "после доставки терминал не предложил чаевые")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 880, "гость заплатил не ровно один раз")

	order.expire()
	order.refund("повтор")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 880, "после доставки деньги вернулись ещё и гостю")
	var/obj/item/reagent_containers/food/snacks/burger/plain/extra = burger(cook)
	SEND_SIGNAL(tray, COMSIG_TRY_STORAGE_INSERT, extra, cook, TRUE, FALSE)
	tray.attack_self(cook)
	TEST_ASSERT(extra.loc == tray, "поднос отправил блюдо без открытого заказа")
	TEST_ASSERT_EQUAL(panel.icon_state, "dorm_available", "терминал после доставки всё ещё показывает заказ")

/// Сервис не успел: деньги возвращаются ровно один раз и номеру открывается кейтеринг NT; кейтеринг дороже и сжигает деньги; отмена - только заказчиком; лимит ждущих заказов.
/datum/unit_test/economy_roomservice/refund_and_catering/Run()
	TEST_ASSERT_NOTNULL(open_room(6154, 1000), "в номере нет терминала")
	hire_cook()
	var/datum/bank_account/escrow = GLOB.room_service.escrow_account()
	var/escrow_before = escrow.account_balance
	var/turf/drop = get_turf(panel)
	var/price = GLOB.room_service_menu["burger"]["price"]

	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "catering"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "кейтеринг NT продал еду при поваре на смене")

	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price, "предоплата не списана")
	var/list/waiting = panel.orders()
	var/datum/room_service_order/order = waiting[1]
	order.expire()
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "сервис не успел, а деньги не вернулись")
	order.expire()
	order.refund("повтор")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "возврат прошёл второй раз")
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "на счёте предоплаты остались деньги")
	TEST_ASSERT(ROOM_SERVICE_FOOD in panel.catering_open, "после опоздания сервиса номеру не открылся кейтеринг")
	TEST_ASSERT(!length(panel.orders()), "просроченный заказ остался у терминала")

	var/burgers_before = count_on(drop, /obj/item/reagent_containers/food/snacks/burger/plain)
	act(guest, "order", list("id" = "burger", "count" = 2, "route" = "catering"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price * ROOM_SERVICE_CATERING_MULT * 2, "кейтеринг взял не свою цену")
	TEST_ASSERT_EQUAL(count_on(drop, /obj/item/reagent_containers/food/snacks/burger/plain) - burgers_before, 2, "кейтеринг не прислал блюда в номер")
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "кейтеринг прошёл через предоплату сервиса")
	var/balance = guest_account.account_balance

	act(guest, "order", list("id" = "coffee", "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance, "заказ бармену прошёл, хотя бармена нет на смене")
	act(guest, "order", list("id" = "coffee", "count" = 1, "route" = "catering"))
	balance -= GLOB.room_service_menu["coffee"]["price"] * ROOM_SERVICE_CATERING_MULT
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance, "без бармена кейтеринг напитков недоступен")
	TEST_ASSERT_EQUAL(count_on(drop, /obj/item/reagent_containers/food/drinks/coffee), 1, "кофе не появился в номере")

	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	waiting = panel.orders()
	order = waiting[1]
	act(cook, "cancel", list("uid" = order.uid))
	TEST_ASSERT(!order.settled, "чужой отменил заказ")
	var/list/cancelled = panel.cancel_order(guest, order.uid)
	TEST_ASSERT_EQUAL(cancelled[2], "Заказ №[order.uid] отменён.", "отмена отвечает не одной строкой")
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance, "отмена не вернула деньги")
	act(guest, "cancel", list("uid" = order.uid))
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance, "повторная отмена вернула деньги ещё раз")

	act(guest, "order", list("id" = "burger", "count" = ROOM_SERVICE_COUNT_MAX + 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance, "заказ сверх ROOM_SERVICE_COUNT_MAX штук прошёл")
	for(var/i in 1 to ROOM_SERVICE_ORDERS_PER_ROOM + 1)
		act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(length(panel.orders()), ROOM_SERVICE_ORDERS_PER_ROOM, "номер набрал больше ждущих заказов, чем можно")
	TEST_ASSERT_EQUAL(guest_account.account_balance, balance - price * ROOM_SERVICE_ORDERS_PER_ROOM, "лишний заказ списал деньги")

	sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	TEST_ASSERT(!length(panel.catering_open), "кейтеринг остался открытым после ухода гостя")
	waiting = panel.orders()
	order = waiting[1]
	order.expire()
	TEST_ASSERT(order.settled, "просроченный заказ закрытого номера не вернул деньги")
	TEST_ASSERT(!length(panel.catering_open), "сервис не успел без гостя в номере, а кейтеринг открылся")

/// Поднос отправляет только сотрудник сервиса, не себе, только еду без вложенных вещей и только в открытый номер; закрытие терминала возвращает деньги.
/datum/unit_test/economy_roomservice/tray_rules_and_closed_room/Run()
	TEST_ASSERT_NOTNULL(open_room(6155, 1000), "в номере нет терминала")
	hire_cook()
	var/price = GLOB.room_service_menu["burger"]["price"]
	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	var/list/waiting = panel.orders()
	TEST_ASSERT_EQUAL(length(waiting), 1, "заказ не принят")
	var/datum/room_service_order/order = waiting[1]

	var/obj/item/reagent_containers/food/snacks/burger/plain/own = burger(guest)
	var/obj/item/storage/bag/tray/room_service/guest_tray = tray_for(guest, list(own))
	guest_tray.attack_self(guest)
	TEST_ASSERT(own.loc == guest_tray, "поднос сработал у человека не из сервиса")
	guest_account.department_id = ACCOUNT_SRV
	guest_tray.attack_self(guest)
	guest_account.department_id = null
	TEST_ASSERT(own.loc == guest_tray, "сотрудник сервиса отправил заказ сам себе")

	var/obj/item/reagent_containers/food/snacks/burger/plain/dish = burger(cook)
	var/obj/item/reagent_containers/food/drinks/bottle/molotov/molotov = allocate(/obj/item/reagent_containers/food/drinks/bottle/molotov, get_turf(cook))
	var/obj/item/storage/bag/tray/room_service/tray = tray_for(cook, list(dish, molotov))
	TEST_ASSERT(molotov.loc == tray, "test premise: молотов не лёг на поднос")
	tray.attack_self(cook)
	TEST_ASSERT(dish.loc == tray && molotov.loc == tray, "поднос отправил коктейль Молотова")
	molotov.forceMove(get_turf(cook))
	var/obj/item/coin/stash = allocate(/obj/item/coin, dish)
	tray.attack_self(cook)
	TEST_ASSERT(dish.loc == tray, "поднос отправил блюдо с вещью внутри")
	stash.forceMove(get_turf(cook))

	sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	TEST_ASSERT(sphere.storedRooms["6155"], "номер не ушёл в хранилище")
	tray.attack_self(cook)
	TEST_ASSERT(dish.loc == tray, "поднос отправил заказ в номер, убранный в хранилище")
	var/closed_problem = order.delivery_problem(cook, tray)
	TEST_ASSERT(findtext(closed_problem, "№[order.uid]") && !findtext(closed_problem, "6155"), "отказ сотруднику выдал номер комнаты: [closed_problem]")
	TEST_ASSERT(!order.settled, "закрытый номер закрыл заказ")
	TEST_ASSERT(sphere.tryStoredRoom(6155, guest), "номер не восстановился")
	tray.attack_self(cook)
	TEST_ASSERT(get_turf(dish) == get_turf(panel) && istype(get_area(dish), /area/hilbertshotel), "после возвращения гостя заказ не доставлен")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price, "доставка после хранения номера списала не одну цену")

	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price * 2, "второй заказ не оплачен")
	qdel(panel)
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price, "удалённый терминал не вернул деньги за ждущий заказ")
	TEST_ASSERT(!length(GLOB.room_service.open_orders()), "заказ удалённого терминала остался открытым")

/// Декор покупается в номер до своего предела, деньги уходят NT; экран встаёт на стену, и всё остаётся в номере после его хранения.
/datum/unit_test/economy_roomservice/decor_stays_with_room/Run()
	TEST_ASSERT_NOTNULL(open_room(6156, 10000), "в номере нет терминала")
	var/flowers_price = GLOB.room_service_decor["flowers"]["price"]
	var/music_price = GLOB.room_service_decor["music"]["price"]
	var/turf/drop = get_turf(panel)
	var/plants_before = 0
	for(var/obj/item/kirbyplants/plant in get_area(guest))
		plants_before++
	var/drop_before = count_on(drop, /obj/item/kirbyplants)

	for(var/i in 1 to ROOM_SERVICE_DECOR_PER_ROOM + 1)
		act(guest, "decor", list("id" = "flowers"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 10000 - flowers_price * ROOM_SERVICE_DECOR_PER_ROOM, "набор продан сверх предела или не продан")
	TEST_ASSERT_EQUAL(count_on(drop, /obj/item/kirbyplants) - drop_before, 2 * ROOM_SERVICE_DECOR_PER_ROOM, "цветы не появились в номере")

	act(guest, "decor", list("id" = "music"))
	act(guest, "decor", list("id" = "music"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 10000 - flowers_price * ROOM_SERVICE_DECOR_PER_ROOM - music_price, "экран продан не один раз")
	var/obj/structure/sign/moniq/room_service/screen = locate() in get_area(guest)
	TEST_ASSERT_NOTNULL(screen, "экран Muz-TV не появился в номере")
	TEST_ASSERT(screen.pixel_y >= 32 && isclosedturf(get_step(screen, NORTH)), "экран не на северной стене")
	act(guest, "decor", list("id" = "yacht"))
	TEST_ASSERT_EQUAL(panel.decor_bought["music"], 1, "покупки номера не запомнены")
	TEST_ASSERT(screen.econ_vended, "экран номера сдаётся NT как ничейный")

	act(guest, "decor", list("id" = "candles"))
	var/obj/item/candle/candle = newest_on(drop, /obj/item/candle)
	TEST_ASSERT(istype(candle, /obj/item/candle/infinite/hugbox) && !candle.get_temperature(), "свеча декора поджигает: [candle?.type]")
	TEST_ASSERT(candle.econ_vended, "свеча декора не помечена купленной")

	guest.forceMove(get_turf(screen))
	usr = guest
	screen.MouseDrop(guest)
	usr = null
	TEST_ASSERT(!QDELETED(screen) && get_area(screen) == get_area(guest), "экран номера сняли со стены перетаскиванием")
	TEST_ASSERT(!(locate(/obj/item/sign/moniq) in guest.held_items) && !(locate(/obj/item/sign/moniq) in get_turf(guest)), "перетаскивание превратило экран номера в переносной Muz-TV")

	var/datum/component/jukebox/jukebox = screen.GetComponent(/datum/component/jukebox)
	var/datum/track/track = new("A", null, 10 MINUTES, 5, "a")
	jukebox.queuedplaylist = list(track)
	TEST_ASSERT(jukebox.activate_music(), "test premise: экран не заиграл")
	TEST_ASSERT(SSjukeboxes.findjukeboxindex(screen), "test premise: экран не занял канал джукбокса")

	sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	var/still_playing = SSjukeboxes.findjukeboxindex(screen)
	if(still_playing)
		SSjukeboxes.removejukebox(still_playing)
	jukebox.queuedplaylist = list()
	qdel(track)
	TEST_ASSERT(!still_playing && !jukebox.playing, "экран в хранилище номера играет и держит канал джукбокса")
	TEST_ASSERT(sphere.tryStoredRoom(6156, guest), "номер не восстановился")
	var/area/hilbertshotel/room = get_area(guest)
	TEST_ASSERT(get_area(screen) == room, "экран не вернулся с номером")
	var/plants = 0
	for(var/obj/item/kirbyplants/plant in room)
		plants++
	TEST_ASSERT_EQUAL(plants - plants_before, 2 * ROOM_SERVICE_DECOR_PER_ROOM, "цветы не вернулись с номером")
	TEST_ASSERT_EQUAL(panel.decor_bought["flowers"], ROOM_SERVICE_DECOR_PER_ROOM, "номер забыл купленный декор")

	screen.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(QDELETED(screen), "экран номера, вынесенный из отеля, остался цел")

/// Сфера удалена, пока номер в хранилище: вещи номера выбрасываются из хранилища, а терминал уходит и возвращает деньги за ждущий заказ.
/datum/unit_test/economy_roomservice/stored_room_ejected/Run()
	TEST_ASSERT_NOTNULL(open_room(6158, 1000), "в номере нет терминала")
	hire_cook()
	var/price = GLOB.room_service_menu["burger"]["price"]
	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price, "заказ не оплачен")
	var/obj/item/pen/keepsake = allocate(/obj/item/pen, get_turf(guest))
	sphere.MobTransfer(guest, run_loc_floor_bottom_left)
	TEST_ASSERT(sphere.storedRooms["6158"], "номер не ушёл в хранилище")
	TEST_ASSERT(istype(keepsake.loc, /obj/item/abstracthotelstorage), "test premise: вещь не в хранилище номера, а в [keepsake.loc]")
	qdel(sphere)
	TEST_ASSERT(!QDELETED(keepsake) && isturf(keepsake.loc), "вещь сохранённого номера осталась в удалённом хранилище: [keepsake.loc]")
	TEST_ASSERT(QDELETED(panel), "терминал сохранённого номера пережил сферу")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "деньги за ждущий заказ не вернулись")
	TEST_ASSERT(!length(GLOB.room_service.open_orders()), "заказ удалённого номера остался открытым")

/// Каждый заказ доходит до карты повара, даже два за минуту; номер комнаты не уходит ни на карты, ни в список подноса, а список хранит только uid.
/datum/unit_test/economy_roomservice/notify_privacy/Run()
	TEST_ASSERT_NOTNULL(open_room(6157, 1000), "в номере нет терминала")
	hire_cook()
	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	act(guest, "order", list("id" = "fries", "count" = 1, "route" = "staff"))
	var/list/waiting = panel.orders()
	TEST_ASSERT_EQUAL(length(waiting), 2, "заказы не приняты")
	var/datum/room_service_order/second = waiting[2]
	TEST_ASSERT_EQUAL(panel.notify_staff(second), 1, "второй заказ из номера за минуту не дошёл до карты повара")
	for(var/text in list(second.staff_notice(), second.tray_label()))
		TEST_ASSERT(findtext(text, "№[second.uid]") && !findtext(text, "6157"), "номер комнаты виден сервису: [text]")
	var/list/choices = room_service_order_choices(waiting)
	for(var/label in choices)
		TEST_ASSERT(isnum(choices[label]), "окно выбора на подносе держит заказ, а не его uid")
	TEST_ASSERT(GLOB.room_service.order_by_uid(choices[second.tray_label()]) == second, "заказ не находится по uid после выбора")

/// Пустой поднос берёт заказ, гость это видит; с ушедшего сотрудника отметка снимается, не взятый заказ возвращается досрочно; напоминание за 5 минут; чаевые один раз и только заказчиком.
/datum/unit_test/economy_roomservice/claim_and_tips/Run()
	TEST_ASSERT_NOTNULL(open_room(6161, 1000), "в номере нет терминала")
	hire_cook()
	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	var/list/waiting = panel.orders()
	var/datum/room_service_order/order = waiting[1]
	var/obj/item/storage/bag/tray/room_service/tray = tray_for(cook, list())
	tray.attack_self(cook)
	TEST_ASSERT(order.claimer_mob() == cook, "пустой поднос не взял заказ")
	var/list/data = panel.ui_data(guest)
	var/list/rows = data["orders"]
	TEST_ASSERT(rows[1]["taken"], "гость не видит, что повар принял заказ")

	order.review()
	TEST_ASSERT_NULL(order.claimer, "с сотрудника без клиента отметка не снялась")
	TEST_ASSERT(!order.settled, "снятие отметки закрыло заказ")
	order.review()
	TEST_ASSERT(order.settled, "не взятый заказ не вернулся досрочно")
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "досрочный возврат не вернул деньги")
	TEST_ASSERT(ROOM_SERVICE_FOOD in panel.catering_open, "не взятый заказ не открыл кейтеринг")

	act(guest, "order", list("id" = "burger", "count" = 1, "route" = "staff"))
	waiting = panel.orders()
	order = waiting[1]
	TEST_ASSERT_EQUAL(order.remind(), 1, "повару не напомнили о сроке")
	var/obj/item/reagent_containers/food/snacks/burger/plain/dish = chef_burger(cook)
	SEND_SIGNAL(tray, COMSIG_TRY_STORAGE_INSERT, dish, cook, TRUE, FALSE)
	tray.attack_self(cook)
	TEST_ASSERT(order.settled, "заказ на подносе не доставлен")
	var/uid = order.uid
	data = panel.ui_data(guest)
	var/list/tips = data["tips"]
	TEST_ASSERT_EQUAL(length(tips), 1, "заказчику не предложили чаевые")
	data = panel.ui_data(cook)
	tips = data["tips"]
	TEST_ASSERT_EQUAL(length(tips), 0, "чаевые предложены не заказчику")
	var/cook_before = cook_account.account_balance
	var/guest_before = guest_account.account_balance
	var/list/result = panel.give_tip(guest, uid, 30)
	TEST_ASSERT(!result[1], "чаевые произвольной суммой прошли")
	result = panel.give_tip(cook, uid, 25)
	TEST_ASSERT(!result[1], "чаевые оставил не заказчик")
	result = panel.give_tip(guest, uid, 25)
	TEST_ASSERT(result[1], "чаевые не прошли: [result[2]]")
	TEST_ASSERT_EQUAL(cook_account.account_balance - cook_before, 25, "чаевые не дошли до доставившего")
	TEST_ASSERT_EQUAL(guest_before - guest_account.account_balance, 25, "чаевые списаны не той суммой")
	result = panel.give_tip(guest, uid, 25)
	TEST_ASSERT(!result[1], "чаевые за один заказ прошли дважды")
	TEST_ASSERT_EQUAL(cook_account.account_balance - cook_before, 25, "вторые чаевые дошли")

/// Кейтеринг и декор помечены купленными; поднос не берёт вишнёвые бомбы и огненные лимоны ни сами, ни внутри блюда; авторские блюда и стопки блинчиков уходят, стопка - по числу блинчиков; вендинговое и вода не платят работу.
/datum/unit_test/economy_roomservice/catering_and_contents/Run()
	TEST_ASSERT_NOTNULL(open_room(6159, 10000), "в номере нет терминала")
	var/turf/drop = get_turf(panel)
	act(guest, "order", list("id" = "soup", "count" = 1, "route" = "catering"))
	var/obj/item/reagent_containers/food/snacks/soup/tomato/soup = newest_on(drop, /obj/item/reagent_containers/food/snacks/soup/tomato)
	TEST_ASSERT_NOTNULL(soup, "кейтеринг не прислал суп")
	var/datum/econ_contract/delivery/contract = new(ACCOUNT_SRV, new /datum/bounty/item/chef/soup)
	var/obj/item/reagent_containers/food/snacks/soup/tomato/own_soup = allocate(/obj/item/reagent_containers/food/snacks/soup/tomato, drop)
	var/own_wanted = contract.wants(own_soup)
	var/catering_wanted = contract.wants(soup)
	qdel(contract)
	TEST_ASSERT(own_wanted, "test premise: контракт на суп не берёт свой суп")
	TEST_ASSERT(!catering_wanted, "суп из кейтеринга NT сдаётся в контракт")

	TEST_ASSERT(!room_service_item_allowed(allocate(/obj/item/reagent_containers/food/snacks/grown/firelemon, drop)), "поднос берёт огненный лимон")
	var/obj/item/reagent_containers/food/snacks/grown/cherry_bomb/bomb = allocate(/obj/item/reagent_containers/food/snacks/grown/cherry_bomb, drop)
	TEST_ASSERT(!room_service_item_allowed(bomb), "поднос берёт вишнёвую бомбу")
	var/obj/item/reagent_containers/food/snacks/customizable/burger/custom = allocate(/obj/item/reagent_containers/food/snacks/customizable/burger, drop)
	allocate(/obj/item/reagent_containers/food/snacks/grown/tomato, custom)
	TEST_ASSERT(room_service_item_allowed(custom), "авторское блюдо с едой внутри не отправляется")
	bomb.forceMove(custom)
	TEST_ASSERT(!room_service_item_allowed(custom), "вишнёвая бомба спряталась в авторском блюде")
	var/obj/item/reagent_containers/food/snacks/customizable/burger/nested = allocate(/obj/item/reagent_containers/food/snacks/customizable/burger, drop)
	custom.forceMove(nested)
	TEST_ASSERT(!room_service_item_allowed(nested), "вишнёвая бомба спряталась на втором уровне вложения")

	hire_cook()
	act(guest, "order", list("id" = "pancakes", "count" = 3, "route" = "staff"))
	var/list/waiting = panel.orders()
	var/datum/room_service_order/order = waiting[1]
	var/obj/item/reagent_containers/food/snacks/pancakes/stack = allocate(/obj/item/reagent_containers/food/snacks/pancakes, get_turf(cook))
	allocate(/obj/item/reagent_containers/food/snacks/pancakes, stack)
	var/obj/item/storage/bag/tray/room_service/tray = tray_for(cook, list(stack))
	TEST_ASSERT_EQUAL(room_service_item_units(stack), 2, "стопка блинчиков считается не по блинчикам")
	tray.attack_self(cook)
	TEST_ASSERT(!order.settled, "два блинчика закрыли заказ на три")
	allocate(/obj/item/reagent_containers/food/snacks/pancakes, stack)
	var/budget_before = service_budget.account_balance
	tray.attack_self(cook)
	TEST_ASSERT(order.settled && get_turf(stack) == drop, "стопка из трёх блинчиков не ушла в номер")
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/share = round(order.total * service.register_cashier_share / 100)
	TEST_ASSERT_EQUAL(service_budget.account_balance - budget_before, order.total - share, "блинчики не от повара оплатили работу сервиса")

	var/obj/item/reagent_containers/food/drinks/soda_cans/cola/vended = allocate(/obj/item/reagent_containers/food/drinks/soda_cans/cola, get_turf(cook))
	econ_mark_vended(vended, 10)
	vended.econ_pourer = WEAKREF(cook)
	TEST_ASSERT(!econ_drink_work_ready(vended), "кола из автомата считается коктейлем")
	var/obj/item/reagent_containers/food/drinks/drinkingglass/water = allocate(/obj/item/reagent_containers/food/drinks/drinkingglass, get_turf(cook))
	water.reagents.add_reagent(/datum/reagent/water, 20)
	water.econ_pourer = WEAKREF(cook)
	TEST_ASSERT(!econ_drink_work_ready(water), "вода из-под крана считается коктейлем")

/// Блюдо дня от шефа: в меню при блюде дня, дороже, только заказом повару и только это блюдо; работа - с множителем блюда дня.
/datum/unit_test/economy_roomservice/dish_of_the_day/Run()
	TEST_ASSERT_NOTNULL(open_room(6160, 1000), "в номере нет терминала")
	hire_cook()
	set_dish_of_the_day(null)
	var/list/data = panel.ui_data(guest)
	TEST_ASSERT_NULL(data["special"], "блюдо дня в меню без блюда дня")
	set_dish_of_the_day(/obj/item/reagent_containers/food/snacks/burger/plain)
	data = panel.ui_data(guest)
	var/list/special = data["special"]
	TEST_ASSERT_NOTNULL(special, "блюда дня нет в меню")
	var/price = round(GLOB.room_service_menu["burger"]["price"] * 1.5)
	TEST_ASSERT_EQUAL(special["price"], price, "блюдо дня от шефа стоит не в полтора раза дороже")
	act(guest, "order", list("id" = special["id"], "count" = 1, "route" = "catering"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000, "блюдо дня продано кейтерингом NT")
	act(guest, "order", list("id" = special["id"], "count" = 1, "route" = "staff"))
	TEST_ASSERT_EQUAL(guest_account.account_balance, 1000 - price, "блюдо дня не заказано")
	var/list/waiting = panel.orders()
	var/datum/room_service_order/order = waiting[1]
	var/obj/item/reagent_containers/food/snacks/fries/wrong = allocate(/obj/item/reagent_containers/food/snacks/fries, get_turf(cook))
	var/obj/item/storage/bag/tray/room_service/tray = tray_for(cook, list(wrong))
	tray.attack_self(cook)
	TEST_ASSERT(!order.settled, "вместо блюда дня ушла картошка")
	wrong.forceMove(get_turf(cook))
	SEND_SIGNAL(tray, COMSIG_TRY_STORAGE_INSERT, chef_burger(cook), cook, TRUE, FALSE)
	var/budget_before = service_budget.account_balance
	tray.attack_self(cook)
	TEST_ASSERT(order.settled, "блюдо дня не доставлено")
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/share = round(price * service.register_cashier_share / 100)
	var/work = round(SSeconomy.settings.work_prices[WORK_SRV_DISH] * SSeconomy.settings.dish_of_the_day_mult)
	TEST_ASSERT_EQUAL(service_budget.account_balance - budget_before, price - share + work, "блюдо дня оплатило работу без множителя блюда дня")

/// Новые атомы обслуживания номеров создаются и удаляются без хвостов.
/datum/unit_test/economy_roomservice_atoms

/datum/unit_test/economy_roomservice_atoms/Run()
	for(var/path in list(/obj/machinery/room_service_panel, /obj/item/storage/bag/tray/room_service, /obj/structure/sign/moniq/room_service))
		var/atom/movable/thing = new path(run_loc_floor_bottom_left)
		TEST_ASSERT(!QDELETED(thing), "[path] не создался")
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[path] не удалился")
