#define ROOM_SERVICE_WALL_OFFSET 32
/// Сдвиг, с которого вещь на клетке считается висящей на стене: у лежащих на полу он меньше
#define ROOM_SERVICE_WALL_MOUNTED 16
/// На сколько клеток от входа в номер ищется стена под терминал
#define ROOM_SERVICE_PANEL_RANGE 2
/// Экран ищет северную стену во всей комнате вокруг терминала
#define ROOM_SERVICE_SCREEN_RANGE 20

/// Меню обслуживания номеров. Цена - заказу сервису станции, кейтеринг NT дороже в ROOM_SERVICE_CATERING_MULT раз.
GLOBAL_LIST_INIT(room_service_menu, list(
	"burger" = list("name" = "Бургер", "path" = /obj/item/reagent_containers/food/snacks/burger/plain, "kind" = ROOM_SERVICE_FOOD, "price" = 60),
	"fries" = list("name" = "Картошка фри", "path" = /obj/item/reagent_containers/food/snacks/fries, "kind" = ROOM_SERVICE_FOOD, "price" = 40),
	"pasta" = list("name" = "Паста с томатным соусом", "path" = /obj/item/reagent_containers/food/snacks/pastatomato, "kind" = ROOM_SERVICE_FOOD, "price" = 70),
	"steak" = list("name" = "Стейк", "path" = /obj/item/reagent_containers/food/snacks/meat/steak/plain, "kind" = ROOM_SERVICE_FOOD, "price" = 90),
	"soup" = list("name" = "Томатный суп", "path" = /obj/item/reagent_containers/food/snacks/soup/tomato, "kind" = ROOM_SERVICE_FOOD, "price" = 50),
	"salad" = list("name" = "Салат с зеленью", "path" = /obj/item/reagent_containers/food/snacks/salad/herbsalad, "kind" = ROOM_SERVICE_FOOD, "price" = 50),
	"pancakes" = list("name" = "Блинчики", "path" = /obj/item/reagent_containers/food/snacks/pancakes, "kind" = ROOM_SERVICE_FOOD, "price" = 60),
	"cake" = list("name" = "Кусок шоколадного торта", "path" = /obj/item/reagent_containers/food/snacks/cakeslice/chocolate, "kind" = ROOM_SERVICE_FOOD, "price" = 50),
	"pizza" = list("name" = "Пицца «Маргарита»", "path" = /obj/item/reagent_containers/food/snacks/pizza/margherita, "kind" = ROOM_SERVICE_FOOD, "price" = 180),
	"coffee" = list("name" = "Кофе", "path" = /obj/item/reagent_containers/food/drinks/coffee, "kind" = ROOM_SERVICE_DRINK, "price" = 30),
	"tea" = list("name" = "Чай", "path" = /obj/item/reagent_containers/food/drinks/mug/tea, "kind" = ROOM_SERVICE_DRINK, "price" = 30),
	"cocoa" = list("name" = "Какао", "path" = /obj/item/reagent_containers/food/drinks/mug/coco, "kind" = ROOM_SERVICE_DRINK, "price" = 30),
	"cola" = list("name" = "Кола", "path" = /obj/item/reagent_containers/food/drinks/soda_cans/cola, "kind" = ROOM_SERVICE_DRINK, "price" = 20),
	"juice" = list("name" = "Апельсиновый сок, бутылка", "path" = /obj/item/reagent_containers/food/drinks/bottle/orangejuice, "kind" = ROOM_SERVICE_DRINK, "price" = 60),
	"beer" = list("name" = "Пиво", "path" = /obj/item/reagent_containers/food/drinks/beer, "kind" = ROOM_SERVICE_DRINK, "price" = 40),
	"wine" = list("name" = "Вино, бутылка", "path" = /obj/item/reagent_containers/food/drinks/bottle/wine, "kind" = ROOM_SERVICE_DRINK, "price" = 150),
	"whiskey" = list("name" = "Виски, бутылка", "path" = /obj/item/reagent_containers/food/drinks/bottle/whiskey, "kind" = ROOM_SERVICE_DRINK, "price" = 200),
	"champagne" = list("name" = "Шампанское, бутылка", "path" = /obj/item/reagent_containers/food/drinks/bottle/champagne, "kind" = ROOM_SERVICE_DRINK, "price" = 300),
))

/// Платный декор номера: появляется в номере и хранится с ним. "wall" - экран на стене, остальное - вещи у терминала.
GLOBAL_LIST_INIT(room_service_decor, list(
	"flowers" = list("name" = "Цветы", "desc" = "Два растения в горшках.", "price" = 400, "max" = ROOM_SERVICE_DECOR_PER_ROOM, "items" = list(/obj/item/kirbyplants/random = 2)),
	"candles" = list("name" = "Свечи", "desc" = "Четыре вечные свечи: горят, пока их не задуют.", "price" = 400, "max" = ROOM_SERVICE_DECOR_PER_ROOM, "items" = list(/obj/item/candle/infinite = 4)),
	"lamps" = list("name" = "Тёплый свет", "desc" = "Две настольные лампы, белая и зелёная.", "price" = 500, "max" = ROOM_SERVICE_DECOR_PER_ROOM, "items" = list(/obj/item/flashlight/lamp = 1, /obj/item/flashlight/lamp/green = 1)),
	"music" = list("name" = "Музыка", "desc" = "Экран Muz-TV на стене: играет только в этом номере и не снимается.", "price" = 3000, "max" = 1, "wall" = /obj/structure/sign/moniq/room_service),
))

GLOBAL_DATUM_INIT(room_service, /datum/room_service, new)

/// Заказы в номера отеля: счёт предоплаты, ждущие доставки заказы и итог смены для econ.log.
/datum/room_service
	var/datum/bank_account/system/escrow
	var/list/datum/room_service_order/orders = list()
	var/next_uid = 0
	var/list/stats = list("staff" = 0, "delivered" = 0, "refunded" = 0, "catering" = 0, "decor" = 0)
	var/summary_hooked = FALSE
	COOLDOWN_DECLARE(radio_cooldown)

/datum/room_service/proc/escrow_account()
	if(!escrow)
		escrow = new("Обслуживание номеров NT")
	return escrow

/datum/room_service/proc/note(stat)
	stats[stat] += 1
	if(summary_hooked)
		return
	summary_hooked = TRUE
	SSticker.OnRoundend(CALLBACK(src, PROC_REF(log_summary)))

/datum/room_service/proc/log_summary()
	log_econ("Обслуживание номеров за смену: заказов сервису [stats["staff"]], доставлено [stats["delivered"]], возвратов [stats["refunded"]], кейтеринг NT [stats["catering"]], декор [stats["decor"]]")

/// Повара (food) или бармены (drink) на станции с игроком.
/proc/room_service_staff(kind)
	. = list()
	var/job = kind == ROOM_SERVICE_FOOD ? "Cook" : "Bartender"
	for(var/mob/living/carbon/human/member in GLOB.player_list)
		if(member.stat != DEAD && member.mind?.assigned_role == job && econ_on_station(member))
			. += member

/proc/room_service_staff_name(kind, capital = FALSE)
	if(kind == ROOM_SERVICE_FOOD)
		return capital ? "Повар" : "повар"
	return capital ? "Бармен" : "бармен"

/// Вид заказа, который закрывает предмет: блюдо или налитый напиток.
/proc/room_service_item_kind(obj/item/thing)
	if(istype(thing, /obj/item/reagent_containers/food/snacks))
		return ROOM_SERVICE_FOOD
	if(istype(thing, /obj/item/reagent_containers/food/drinks) && thing.reagents?.total_volume > 0)
		return ROOM_SERVICE_DRINK
	return null

/// Поднос отправляет только еду и напитки без вложенных вещей: это не телепорт для чего угодно.
/proc/room_service_item_allowed(obj/item/thing)
	if(!istype(thing, /obj/item/reagent_containers/food) || length(thing.contents))
		return FALSE
	return !istype(thing, /obj/item/reagent_containers/food/snacks/cube) && !istype(thing, /obj/item/reagent_containers/food/drinks/bottle/molotov)

/// Терминал и экран номера живут только в комнате отеля или в её хранилище.
/proc/room_service_place_ok(atom/movable/thing)
	var/turf/spot = get_turf(thing)
	return spot && (istype(spot.loc, /area/hilbertshotel) || istype(spot.loc, /area/hilbertshotelstorage))

/datum/room_service_order
	var/uid
	var/item_id
	var/list/entry
	var/count
	var/total
	var/room_number
	var/datum/bank_account/payer
	var/datum/weakref/payer_mob
	var/obj/machinery/room_service_panel/panel
	var/deadline
	var/timer_id
	/// Деньги уже ушли сервису или вернулись заказчику
	var/settled = FALSE

/datum/room_service_order/New(obj/machinery/room_service_panel/panel, datum/bank_account/payer, mob/living/guest, item_id, count)
	src.panel = panel
	src.payer = payer
	payer_mob = WEAKREF(guest)
	src.item_id = item_id
	entry = GLOB.room_service_menu[item_id]
	src.count = count
	total = entry["price"] * count
	room_number = panel.room_number
	uid = ++GLOB.room_service.next_uid
	deadline = world.time + ROOM_SERVICE_STAFF_WAIT
	timer_id = addtimer(CALLBACK(src, PROC_REF(expire)), ROOM_SERVICE_STAFF_WAIT, TIMER_STOPPABLE)
	RegisterSignal(panel, COMSIG_PARENT_QDELETING, PROC_REF(on_panel_deleted))
	RegisterSignal(payer, COMSIG_PARENT_QDELETING, PROC_REF(on_payer_deleted))
	GLOB.room_service.orders += src

/datum/room_service_order/Destroy()
	refund("Заказ №[uid] отменён")
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	GLOB.room_service.orders -= src
	if(payer)
		UnregisterSignal(payer, COMSIG_PARENT_QDELETING)
		payer = null
	payer_mob = null
	if(panel)
		UnregisterSignal(panel, COMSIG_PARENT_QDELETING)
		var/obj/machinery/room_service_panel/old_panel = panel
		panel = null
		if(!QDELETED(old_panel))
			old_panel.update_appearance()
	return ..()

/datum/room_service_order/proc/what()
	return "[entry["name"]][count > 1 ? " x[count]" : ""]"

/datum/room_service_order/proc/minutes_left()
	return max(CEILING((deadline - world.time) / (1 MINUTES), 1), 0)

/// Возврат предоплаты: ровно один раз на заказ, что бы его ни закрыло.
/datum/room_service_order/proc/refund(why)
	if(settled)
		return FALSE
	settled = TRUE
	GLOB.room_service.orders -= src
	if(!payer || !SSeconomy.move(GLOB.room_service.escrow_account(), payer, total, ECON_REFUND, null, "Обслуживание номеров: возврат заказа №[uid]"))
		log_econ("Обслуживание номеров: возврат заказа №[uid] на [total] кр. не прошёл")
		return FALSE
	GLOB.room_service.note("refunded")
	payer.bank_card_talk("[why]: [total] кр. вернулись на счёт.", balloon = "возврат +[total] кр")
	log_econ("Обслуживание номеров: заказ №[uid] ([what()], номер [room_number]) - [total] кр. вернулись [payer.account_holder] ([payer.account_id]): [why]")
	return TRUE

/// Сервис не успел: деньги назад, номеру открывается кейтеринг NT этого вида.
/datum/room_service_order/proc/expire()
	if(settled || QDELETED(src))
		return
	var/obj/machinery/room_service_panel/room_panel = panel
	refund("Сервис не успел с заказом №[uid] ([what()]) за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)]")
	if(room_panel)
		room_panel.catering_open |= entry["kind"]
		room_panel.say("Заказ №[uid] не успели доставить, деньги вернулись. Теперь можно заказать готовое у NT.")
	qdel(src)

/datum/room_service_order/proc/on_panel_deleted(datum/source)
	SIGNAL_HANDLER
	refund("Номер [room_number] закрыт, заказ №[uid] отменён")
	qdel(src)

/datum/room_service_order/proc/on_payer_deleted(datum/source)
	SIGNAL_HANDLER
	refund("Счёт закрыт, заказ №[uid] отменён")
	qdel(src)

/// Почему sender не может отправить заказ подносом tray; null - может.
/datum/room_service_order/proc/delivery_problem(mob/living/sender, obj/item/storage/bag/tray/room_service/tray)
	if(settled || QDELETED(src))
		return "Этот заказ уже закрыт."
	if(!isliving(sender) || sender.incapacitated() || !sender.is_holding(tray))
		return "Держите поднос в руке."
	var/datum/bank_account/account = econ_account_of(sender)
	if(!account || account.department_id != ACCOUNT_SRV || SSeconomy.personal_account_problem(account, FALSE))
		return "Отправлять заказы в номера может только сотрудник сервиса со своей картой."
	if(account == payer)
		return "Свой заказ себе не отправляют."
	if(!panel?.room_area())
		return "В номере [room_number] сейчас никого нет, он закрыт. Заказ ждёт до [STATION_TIME_TIMESTAMP("hh:mm", deadline)]."
	if(!panel.has_guest())
		return "В номере [room_number] некому принять заказ."
	return tray.contents_problem(entry["kind"], count)

/// Отправка подноса: всё с него уходит в номер, предоплата - отправителю и бюджету сервиса, как на кассе. Возвращает null или текст отказа.
/datum/room_service_order/proc/deliver(mob/living/sender, obj/item/storage/bag/tray/room_service/tray)
	. = delivery_problem(sender, tray)
	if(.)
		return
	settled = TRUE
	GLOB.room_service.orders -= src
	var/turf/drop = get_turf(panel)
	tray.send_contents(drop)
	var/datum/bank_account/account = econ_account_of(sender)
	var/share = pay_out(account, sender)
	var/mob/living/guest = payer_mob?.resolve()
	if(isliving(guest))
		SSeconomy.record_work(ACCOUNT_SRV, entry["kind"] == ROOM_SERVICE_FOOD ? WORK_SRV_DISH : WORK_SRV_DRINK, count, sender, guest, "Обслуживание номеров: [what()]")
	GLOB.room_service.note("delivered")
	do_sparks(2, FALSE, drop)
	playsound(drop, 'sound/machines/ding.ogg', 50, TRUE)
	panel.say("Заказ №[uid] доставлен: [what()]. Приятного аппетита!")
	payer?.bank_card_talk("Заказ №[uid] доставлен в номер [room_number]: [what()].")
	playsound(sender, 'sound/effects/phasein.ogg', 25, TRUE)
	to_chat(sender, span_notice("Заказ №[uid] ушёл в номер [room_number]: [what()]. Ваша доля - [share] кр."))
	log_econ("Обслуживание номеров: [key_name(sender)] доставил заказ №[uid] ([what()], [total] кр.) в номер [room_number], доля [share] кр.")
	log_game("[key_name(sender)] доставил подносом заказ №[uid] ([what()]) в номер отеля [room_number]")
	qdel(src)
	return null

/datum/room_service_order/proc/pay_out(datum/bank_account/account, mob/living/sender)
	var/datum/bank_account/escrow = GLOB.room_service.escrow_account()
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/memo = "Обслуживание номеров: заказ №[uid]"
	. = service?.account ? round(total * service.register_cashier_share / 100) : total
	if(. && !SSeconomy.move(escrow, account, ., ECON_ROOM_SERVICE, sender, memo))
		. = 0
	if(total - . > 0)
		SSeconomy.move(escrow, service?.account || account, total - ., ECON_ROOM_SERVICE, sender, memo)
	if(.)
		account.bank_card_talk("Обслуживание номеров: заказ №[uid] доставлен, ваша доля [.] кр.", balloon = "номер +[.] кр")

/datum/room_service/proc/open_orders()
	. = list()
	for(var/datum/room_service_order/order as anything in orders)
		if(!order.settled)
			. += order

/// Терминал обслуживания номеров: сам появляется в каждой комнате отеля, кроме гост-кафе, и хранится вместе с ней.
/obj/machinery/room_service_panel
	name = "room service terminal"
	desc = "Терминал обслуживания номеров. Здесь заказывают еду и напитки с кухни и бара станции, а если сервиса нет - готовое у NT. Ещё здесь продаётся декор для номера."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "dorm_available"
	verb_say = "сообщает"
	density = FALSE
	anchored = TRUE
	use_power = NO_POWER_USE
	init_process = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	interaction_flags_machine = INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OFFLINE
	var/room_number = 0
	/// Виды заказов, по которым сервис не успел: номеру открыт кейтеринг NT, даже если повар или бармен на смене
	var/list/catering_open = list()
	/// id набора декора -> сколько раз куплен в этот номер
	var/list/decor_bought = list()
	COOLDOWN_DECLARE(act_cooldown)
	COOLDOWN_DECLARE(notify_cooldown)

/obj/machinery/room_service_panel/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(!QDELETED(src) && !room_service_place_ok(src))
		qdel(src)

/obj/machinery/room_service_panel/update_icon_state()
	icon_state = length(orders()) ? "dorm_inside" : "dorm_available"
	return ..()

/obj/machinery/room_service_panel/proc/orders()
	. = list()
	for(var/datum/room_service_order/order as anything in GLOB.room_service.orders)
		if(order.panel == src && !order.settled)
			. += order

/// Комната, в которой стоит терминал; null, если комната убрана в хранилище или терминал не в отеле.
/obj/machinery/room_service_panel/proc/room_area()
	var/area/hilbertshotel/room = get_area(src)
	if(!isturf(loc) || !istype(room) || !room.reservation || !room.parentSphere)
		return null
	return room

/obj/machinery/room_service_panel/proc/has_guest()
	var/area/hilbertshotel/room = room_area()
	if(!room)
		return FALSE
	for(var/mob/living/guest in room)
		if(guest.stat != DEAD && guest.mind)
			return TRUE
	return FALSE

/obj/machinery/room_service_panel/proc/catering_allowed(kind)
	return !length(room_service_staff(kind)) || (kind in catering_open)

/// Свободна ли стена с этой стороны клетки: на ней нет настенных вещей и лампы, смотрящей туда.
/proc/room_service_wall_free(turf/spot, direction)
	var/turf/wall = get_step(spot, direction)
	if(!isclosedturf(wall) || istype(wall, /turf/closed/indestructible/hoteldoor))
		return FALSE
	for(var/obj/thing in spot)
		if(istype(thing, /obj/machinery/light) && thing.dir == direction)
			return FALSE
		if((direction == NORTH && thing.pixel_y >= ROOM_SERVICE_WALL_MOUNTED) || (direction == SOUTH && thing.pixel_y <= -ROOM_SERVICE_WALL_MOUNTED) || (direction == EAST && thing.pixel_x >= ROOM_SERVICE_WALL_MOUNTED) || (direction == WEST && thing.pixel_x <= -ROOM_SERVICE_WALL_MOUNTED))
			return FALSE
	return TRUE

/proc/room_service_wall_offset(atom/movable/thing, direction)
	thing.pixel_x += direction == EAST ? ROOM_SERVICE_WALL_OFFSET : (direction == WEST ? -ROOM_SERVICE_WALL_OFFSET : 0)
	thing.pixel_y += direction == NORTH ? ROOM_SERVICE_WALL_OFFSET : (direction == SOUTH ? -ROOM_SERVICE_WALL_OFFSET : 0)

/// Клетка комнаты room не дальше radius от center со свободной стеной и сторона этой стены, list(клетка, сторона): чем ближе к center, тем лучше, при равенстве - северная стена. null, если такой нет.
/proc/room_service_wall_spot(turf/center, area/room, radius, only_north = FALSE)
	var/best_score = INFINITY
	var/turf/low = locate(max(center.x - radius, 1), max(center.y - radius, 1), center.z)
	var/turf/high = locate(min(center.x + radius, world.maxx), min(center.y + radius, world.maxy), center.z)
	for(var/turf/open/spot in block(low, high))
		if(spot.loc != room || spot.is_blocked_turf())
			continue
		for(var/side in (only_north ? list(NORTH) : GLOB.cardinals))
			if(!room_service_wall_free(spot, side))
				continue
			var/score = max(get_dist(center, spot), 0) * 4 + (side == NORTH ? 0 : 1)
			if(score < best_score)
				best_score = score
				. = list(spot, side)

/obj/machinery/room_service_panel/examine(mob/user)
	. = ..()
	. += span_notice("Если повар или бармен на смене, заказ уходит ему: он готовит и отправляет его в номер подносом обслуживания номеров. Деньги списываются сразу, а если заказ не доставят за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)], вернутся, и номеру откроется кейтеринг NT.")
	. += span_notice("Кейтеринг NT присылает готовое сразу, но [econ_times_text(ROOM_SERVICE_CATERING_MULT)] дороже. Декор, купленный здесь, остаётся в номере, пока номер хранится.")
	var/list/waiting = orders()
	if(length(waiting))
		. += span_notice("Ждут доставки: [length(waiting)].")

/obj/machinery/room_service_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RoomService", name)
		ui.open()

/obj/machinery/room_service_panel/ui_static_data(mob/user)
	var/list/menu = list()
	for(var/id in GLOB.room_service_menu)
		var/list/entry = GLOB.room_service_menu[id]
		menu += list(list("id" = id, "name" = entry["name"], "kind" = entry["kind"], "price" = entry["price"]))
	var/list/decor = list()
	for(var/id in GLOB.room_service_decor)
		var/list/decor_set = GLOB.room_service_decor[id]
		decor += list(list("id" = id, "name" = decor_set["name"], "desc" = decor_set["desc"], "price" = decor_set["price"], "max" = decor_set["max"]))
	return list(
		"menu" = menu,
		"decor" = decor,
		"catering_mult" = ROOM_SERVICE_CATERING_MULT,
		"wait_minutes" = ROOM_SERVICE_STAFF_WAIT / (1 MINUTES),
		"count_max" = ROOM_SERVICE_COUNT_MAX,
		"orders_max" = ROOM_SERVICE_ORDERS_PER_ROOM,
	)

/obj/machinery/room_service_panel/ui_data(mob/user)
	var/datum/bank_account/account = econ_account_of(user)
	var/list/rows = list()
	for(var/datum/room_service_order/order as anything in orders())
		rows += list(list(
			"uid" = order.uid,
			"name" = order.entry["name"],
			"count" = order.count,
			"total" = order.total,
			"minutes_left" = order.minutes_left(),
			"mine" = order.payer == account,
		))
	return list(
		"room" = room_number,
		"open" = !!room_area(),
		"account_problem" = SSeconomy.personal_account_problem(account, TRUE),
		"balance" = account ? account.account_balance : 0,
		"staff" = list(ROOM_SERVICE_FOOD = !!length(room_service_staff(ROOM_SERVICE_FOOD)), ROOM_SERVICE_DRINK = !!length(room_service_staff(ROOM_SERVICE_DRINK))),
		"catering" = list(ROOM_SERVICE_FOOD = catering_allowed(ROOM_SERVICE_FOOD), ROOM_SERVICE_DRINK = catering_allowed(ROOM_SERVICE_DRINK)),
		"orders" = rows,
		"decor_bought" = decor_bought,
	)

/obj/machinery/room_service_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/user = ui?.user
	if(!isliving(user))
		return FALSE
	var/list/result
	switch(action)
		if("order")
			result = place_order(user, params["id"], econ_ui_number(params["count"]), params["route"])
		if("cancel")
			result = cancel_order(user, econ_ui_number(params["uid"]))
		if("decor")
			result = buy_decor(user, params["id"])
		else
			return FALSE
	to_chat(user, result[1] ? span_notice(result[2]) : span_warning(result[2]))
	playsound(src, result[1] ? 'sound/machines/terminal_prompt_confirm.ogg' : 'sound/machines/terminal_error.ogg', 25, TRUE)
	return TRUE

/// Общие проверки покупки: терминал в номере, не чаще ROOM_SERVICE_ACT_COOLDOWN, счёт платит. Возвращает текст отказа или null.
/obj/machinery/room_service_panel/proc/purchase_problem(datum/bank_account/account, price)
	if(!room_area())
		return "Терминал не в номере отеля."
	if(!COOLDOWN_FINISHED(src, act_cooldown))
		return "Терминал ещё оформляет прошлую покупку."
	. = SSeconomy.personal_account_problem(account, TRUE)
	if(.)
		return
	if(!account.has_money(price))
		return "Недостаточно средств: нужно [price] кр., на счёте [account.account_balance] кр."

/// Заказ из меню: route "staff" - сервису станции с предоплатой, "catering" - сразу от NT дороже. Возвращает list(удалось ли, ответ).
/obj/machinery/room_service_panel/proc/place_order(mob/living/user, item_id, count, route)
	var/list/entry = istext(item_id) ? GLOB.room_service_menu[item_id] : null
	if(!entry || !isnum(count) || !(route in list("staff", "catering")))
		return list(FALSE, "Неверный заказ.")
	count = round(count)
	if(count < 1 || count > ROOM_SERVICE_COUNT_MAX)
		return list(FALSE, "За раз можно заказать от 1 до [ROOM_SERVICE_COUNT_MAX] шт.")
	var/kind = entry["kind"]
	var/datum/bank_account/account = econ_account_of(user)
	if(route == "catering")
		return order_catering(user, account, entry, count)
	if(!length(room_service_staff(kind)))
		return list(FALSE, "[room_service_staff_name(kind, TRUE)] сейчас не на смене: закажите готовое у NT.")
	if(length(orders()) >= ROOM_SERVICE_ORDERS_PER_ROOM)
		return list(FALSE, "Доставки уже ждут [ROOM_SERVICE_ORDERS_PER_ROOM] заказа этого номера.")
	var/total = entry["price"] * count
	var/problem = purchase_problem(account, total)
	if(problem)
		return list(FALSE, problem)
	var/what = "[entry["name"]][count > 1 ? " x[count]" : ""]"
	if(!SSeconomy.move(account, GLOB.room_service.escrow_account(), total, ECON_ROOM_SERVICE, user, "Обслуживание номеров: [what], предоплата"))
		return list(FALSE, "Платёж отклонён.")
	COOLDOWN_START(src, act_cooldown, ROOM_SERVICE_ACT_COOLDOWN)
	var/datum/room_service_order/order = new(src, account, user, item_id, count)
	GLOB.room_service.note("staff")
	update_appearance()
	notify_staff(order)
	log_econ("Обслуживание номеров: [key_name(user)] заказал №[order.uid] ([what], [total] кр.) в номер [room_number]")
	log_game("[key_name(user)] заказал в номер отеля [room_number]: [what] за [total] кр. (заказ №[order.uid])")
	return list(TRUE, "Заказ №[order.uid] принят: [what], [total] кр. списаны. Его приготовит и пришлёт [room_service_staff_name(kind)] станции; не доставят за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)] - деньги вернутся.")

/obj/machinery/room_service_panel/proc/order_catering(mob/living/user, datum/bank_account/account, list/entry, count)
	var/kind = entry["kind"]
	if(!catering_allowed(kind))
		return list(FALSE, "[room_service_staff_name(kind, TRUE)] на смене: закажите у него. Кейтеринг NT откроется, если сервис не успеет с заказом.")
	var/price = entry["price"] * ROOM_SERVICE_CATERING_MULT * count
	var/problem = purchase_problem(account, price)
	if(problem)
		return list(FALSE, problem)
	var/what = "[entry["name"]][count > 1 ? " x[count]" : ""]"
	if(!SSeconomy.move(account, null, price, ECON_ROOM_SERVICE, user, "Кейтеринг NT: [what]"))
		return list(FALSE, "Платёж отклонён.")
	COOLDOWN_START(src, act_cooldown, ROOM_SERVICE_ACT_COOLDOWN)
	var/turf/drop = get_turf(src)
	var/path = entry["path"]
	for(var/i in 1 to count)
		new path(drop)
	do_sparks(2, FALSE, drop)
	playsound(drop, 'sound/machines/ding.ogg', 50, TRUE)
	GLOB.room_service.note("catering")
	log_econ("Обслуживание номеров: [key_name(user)] купил кейтеринг NT в номер [room_number]: [what] за [price] кр.")
	return list(TRUE, "Кейтеринг NT доставил [what] за [price] кр.")

/obj/machinery/room_service_panel/proc/cancel_order(mob/living/user, uid)
	var/datum/bank_account/account = econ_account_of(user)
	for(var/datum/room_service_order/order as anything in orders())
		if(order.uid != uid)
			continue
		if(!account || order.payer != account)
			return list(FALSE, "Отменить заказ может только тот, кто его оплатил.")
		var/total = order.total
		order.refund("Заказ №[uid] отменён")
		qdel(order)
		log_econ("Обслуживание номеров: [key_name(user)] отменил заказ №[uid] в номер [room_number]")
		return list(TRUE, "Заказ №[uid] отменён, [total] кр. вернулись на счёт.")
	return list(FALSE, "Этого заказа уже нет: его доставили или отменили.")

/obj/machinery/room_service_panel/proc/buy_decor(mob/living/user, set_id)
	var/list/decor_set = istext(set_id) ? GLOB.room_service_decor[set_id] : null
	if(!decor_set)
		return list(FALSE, "Неверный набор.")
	if((decor_bought[set_id] || 0) >= decor_set["max"])
		return list(FALSE, "Больше этого набора в номер не продают.")
	var/price = decor_set["price"]
	var/datum/bank_account/account = econ_account_of(user)
	var/problem = purchase_problem(account, price)
	if(problem)
		return list(FALSE, problem)
	var/turf/wall_spot
	if(decor_set["wall"])
		var/list/found = room_service_wall_spot(get_turf(src), room_area(), ROOM_SERVICE_SCREEN_RANGE, TRUE)
		if(!found)
			return list(FALSE, "В номере нет свободной стены для экрана.")
		wall_spot = found[1]
	if(!SSeconomy.move(account, null, price, ECON_ROOM_SERVICE, user, "Декор номера: [decor_set["name"]]"))
		return list(FALSE, "Платёж отклонён.")
	COOLDOWN_START(src, act_cooldown, ROOM_SERVICE_ACT_COOLDOWN)
	decor_bought[set_id] = (decor_bought[set_id] || 0) + 1
	var/turf/drop = get_turf(src)
	if(wall_spot)
		var/path = decor_set["wall"]
		var/atom/movable/screen_sign = new path(wall_spot)
		room_service_wall_offset(screen_sign, NORTH)
	var/list/items = decor_set["items"]
	for(var/path in items)
		for(var/i in 1 to items[path])
			new path(drop)
	do_sparks(2, FALSE, drop)
	GLOB.room_service.note("decor")
	log_econ("Обслуживание номеров: [key_name(user)] купил декор \"[decor_set["name"]]\" в номер [room_number] за [price] кр.")
	return list(TRUE, "[decor_set["name"]] для номера: [price] кр. списаны. Вещи остаются в номере, пока номер хранится.")

/// Сообщает поварам или барменам на смене и каналу сервиса о новом заказе, не чаще ROOM_SERVICE_NOTIFY_COOLDOWN с номера.
/obj/machinery/room_service_panel/proc/notify_staff(datum/room_service_order/order)
	if(!COOLDOWN_FINISHED(src, notify_cooldown))
		return FALSE
	COOLDOWN_START(src, notify_cooldown, ROOM_SERVICE_NOTIFY_COOLDOWN)
	var/how = "Положите заказ на поднос обслуживания номеров (DinnerWare, Booze-O-Mat) и используйте поднос в руке, срок [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)]."
	var/text = "Обслуживание номеров: заказ №[order.uid] в номер [order.room_number] - [order.what()], [order.total] кр. [how]"
	for(var/mob/living/carbon/human/member as anything in room_service_staff(order.entry["kind"]))
		var/datum/bank_account/member_account = econ_account_of(member)
		member_account?.bank_card_talk(text)
	if(COOLDOWN_FINISHED(GLOB.room_service, radio_cooldown) && paperwork_radio(text, RADIO_CHANNEL_SERVICE))
		COOLDOWN_START(GLOB.room_service, radio_cooldown, ROOM_SERVICE_NOTIFY_COOLDOWN)
	return TRUE

/// Комната отеля получает терминал при создании; при восстановлении из хранилища он возвращается сам, второй не ставится.
/area/hilbertshotel/proc/ensure_room_service_panel()
	if(!reservation || !parentSphere || parentSphere.is_ghost_cafe || roomType == "Mystery Room")
		return null
	var/obj/machinery/room_service_panel/panel = locate() in src
	if(!panel)
		var/datum/map_template/hilbertshotel/template = parentSphere.getMapTemplate(roomType)
		var/turf/landing = locate(reservation.bottom_left_coords[1] + template.landingZoneRelativeX, reservation.bottom_left_coords[2] + template.landingZoneRelativeY, reservation.bottom_left_coords[3])
		if(!landing || get_area(landing) != src)
			return null
		var/list/found = room_service_wall_spot(landing, src, ROOM_SERVICE_PANEL_RANGE)
		panel = new(found ? found[1] : landing)
		if(found)
			room_service_wall_offset(panel, found[2])
	panel.room_number = roomnumber
	return panel

/obj/item/storage/bag/tray/room_service
	name = "room service tray"
	desc = "Поднос обслуживания номеров отеля Гильберта. Положите на него заказанные блюда или напитки и используйте поднос в руке: блюспейс-канал отправит их в номер заказчика, а сам поднос останется у вас. Отправляет только сотрудник сервиса, только еду и напитки и только по открытому заказу."
	icon_state = "bluespace_tray"
	item_state = "pizzabox"
	lefthand_file = 'icons/mob/inhands/misc/food_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/food_righthand.dmi'

/obj/item/storage/bag/tray/room_service/ComponentInitialize()
	. = ..()
	var/datum/component/storage/storage = GetComponent(/datum/component/storage)
	storage.can_hold = typecacheof(list(/obj/item/reagent_containers/food))
	storage.allow_quick_empty = FALSE

/obj/item/storage/bag/tray/room_service/examine(mob/user)
	. = ..()
	var/waiting = length(GLOB.room_service.open_orders())
	. += span_notice((waiting ? "Ждут доставки заказов: [waiting]." : "Ждущих доставки заказов в номера нет."))

/obj/item/storage/bag/tray/room_service/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	var/list/open = GLOB.room_service.open_orders()
	if(!length(open))
		to_chat(user, span_warning("Ждущих доставки заказов в номера нет."))
		return
	var/datum/room_service_order/order = open[1]
	if(length(open) > 1)
		var/list/choices = list()
		for(var/datum/room_service_order/candidate as anything in open)
			choices["№[candidate.uid], номер [candidate.room_number]: [candidate.what()] (осталось [candidate.minutes_left()] мин.)"] = candidate
		var/choice = tgui_input_list(user, "Какой заказ отправить?", name, choices)
		order = choice ? choices[choice] : null
		if(!order || QDELETED(src))
			return
	var/problem = order.deliver(user, src)
	if(problem)
		to_chat(user, span_warning(problem))

/// Почему содержимое подноса не закрывает заказ из count штук вида kind; null - закрывает.
/obj/item/storage/bag/tray/room_service/proc/contents_problem(kind, count)
	if(!length(contents))
		return "Поднос пуст: положите на него заказ."
	var/matching = 0
	for(var/obj/item/thing as anything in contents)
		if(!room_service_item_allowed(thing))
			return "[thing.name] в номер не отправить: только готовые блюда и напитки, без вложенных вещей."
		if(room_service_item_kind(thing) == kind)
			matching++
	if(matching < count)
		return "Заказано [kind == ROOM_SERVICE_FOOD ? "блюд" : "напитков"]: [count], на подносе: [matching]."
	return null

/// Всё с подноса уходит на drop; доставленное уже оплачено, при еде и питье работа сервиса второй раз не засчитывается.
/obj/item/storage/bag/tray/room_service/proc/send_contents(turf/drop)
	for(var/obj/item/thing as anything in contents)
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, thing, drop, TRUE)
		thing.econ_paid = TRUE
		if(thing.econ_dish)
			thing.econ_dish.paid = TRUE
		var/obj/item/reagent_containers/container = thing
		if(istype(container))
			container.econ_pourer = null
	update_appearance()

/// Экран Muz-TV номера: прикручен намертво, играет только в своём номере и исчезает, если его вынесут из отеля.
/obj/structure/sign/moniq/room_service
	desc = "Экран Muz-TV номера отеля: музыка слышна только в этом номере. Прикручен к стене намертво."
	buildable_sign = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/sign/moniq/room_service/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(!QDELETED(src) && !room_service_place_ok(src))
		qdel(src)

#undef ROOM_SERVICE_WALL_OFFSET
#undef ROOM_SERVICE_WALL_MOUNTED
#undef ROOM_SERVICE_PANEL_RANGE
#undef ROOM_SERVICE_SCREEN_RANGE
