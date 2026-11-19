#define ROOM_SERVICE_WALL_OFFSET 32
/// Сдвиг, с которого вещь на клетке считается висящей на стене: у лежащих на полу он меньше
#define ROOM_SERVICE_WALL_MOUNTED 16
/// На сколько клеток от входа в номер ищется стена под терминал
#define ROOM_SERVICE_PANEL_RANGE 2
/// Экран ищет северную стену во всей комнате вокруг терминала
#define ROOM_SERVICE_SCREEN_RANGE 20
/// id позиции меню «Блюдо дня от шефа»
#define ROOM_SERVICE_SPECIAL_ID "special"
/// Блюдо дня от шефа дороже того же блюда меню во столько раз; нет его в меню - считается от ROOM_SERVICE_SPECIAL_BASE_PRICE
#define ROOM_SERVICE_SPECIAL_MULT 1.5
#define ROOM_SERVICE_SPECIAL_BASE_PRICE 80
#define ROOM_SERVICE_PICK_TIMEOUT (30 SECONDS)

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
	"candles" = list("name" = "Свечи", "desc" = "Четыре вечные свечи: горят, пока их не задуют, и ничего не поджигают.", "price" = 400, "max" = ROOM_SERVICE_DECOR_PER_ROOM, "items" = list(/obj/item/candle/infinite/hugbox = 4)),
	"lamps" = list("name" = "Тёплый свет", "desc" = "Две настольные лампы, белая и зелёная.", "price" = 500, "max" = ROOM_SERVICE_DECOR_PER_ROOM, "items" = list(/obj/item/flashlight/lamp = 1, /obj/item/flashlight/lamp/green = 1)),
	"music" = list("name" = "Музыка", "desc" = "Экран Muz-TV на стене: треки бесплатно, играет только в этом номере и не снимается.", "price" = 3000, "max" = 1, "wall" = /obj/structure/sign/moniq/room_service),
))

/// Чаевые, которые терминал предлагает оставить после доставки
GLOBAL_LIST_INIT(room_service_tip_amounts, list(10, 25, 50))

GLOBAL_DATUM_INIT(room_service, /datum/room_service, new)

/// Заказы в номера отеля: счёт предоплаты, ждущие доставки заказы и итог смены для econ.log.
/datum/room_service
	var/datum/bank_account/system/escrow
	var/list/datum/room_service_order/orders = list()
	var/next_uid = 0
	var/list/stats = list("staff" = 0, "delivered" = 0, "refunded" = 0, "catering" = 0, "decor" = 0, "tips" = 0)
	var/summary_hooked = FALSE
	/// Вид заказа -> когда канал сервиса снова можно позвать
	var/list/radio_ready_at = list()

/datum/room_service/proc/escrow_account()
	if(!escrow)
		escrow = new("Обслуживание номеров NT")
	return escrow

/datum/room_service/proc/note(stat, amount = 1)
	stats[stat] += amount
	if(summary_hooked)
		return
	summary_hooked = TRUE
	SSticker.OnRoundend(CALLBACK(src, PROC_REF(log_summary)))

/datum/room_service/proc/log_summary()
	log_econ("Обслуживание номеров за смену: заказов сервису [stats["staff"]], доставлено [stats["delivered"]], возвратов [stats["refunded"]], кейтеринг NT [stats["catering"]], декор [stats["decor"]], чаевых [stats["tips"]] кр.")

/// Канал сервиса о заказе вида kind, не чаще ROOM_SERVICE_NOTIFY_COOLDOWN на вид.
/datum/room_service/proc/radio(kind, text)
	if(world.time < (radio_ready_at[kind] || 0))
		return FALSE
	if(!paperwork_radio(text, RADIO_CHANNEL_SERVICE))
		return FALSE
	radio_ready_at[kind] = world.time + ROOM_SERVICE_NOTIFY_COOLDOWN
	return TRUE

/datum/room_service/proc/open_orders()
	. = list()
	for(var/datum/room_service_order/order as anything in orders)
		if(!order.settled)
			. += order

/datum/room_service/proc/order_by_uid(uid)
	if(!isnum(uid))
		return null
	for(var/datum/room_service_order/order as anything in open_orders())
		if(order.uid == uid)
			return order

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

/// Взявший заказ всё ещё им занимается: жив, у клавиатуры и на станции.
/proc/room_service_claimer_active(mob/living/staff)
	return isliving(staff) && staff.stat != DEAD && staff.client && econ_on_station(staff)

/// Почему sender не может работать с заказами в номера; null - может.
/proc/room_service_sender_problem(mob/living/sender)
	var/datum/bank_account/account = econ_account_of(sender)
	if(!account || account.department_id != ACCOUNT_SRV || SSeconomy.personal_account_problem(account, FALSE))
		return "Отправлять заказы в номера может только сотрудник сервиса со своей картой."
	return null

/// Блюдо дня сервиса как позиция меню; null - блюда дня нет. Только заказом повару и только это блюдо.
/proc/room_service_special_entry()
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/obj/item/dish = service?.dish_of_the_day
	if(!ispath(dish, /obj/item/reagent_containers/food/snacks))
		return null
	var/base = ROOM_SERVICE_SPECIAL_BASE_PRICE
	for(var/id in GLOB.room_service_menu)
		var/list/entry = GLOB.room_service_menu[id]
		if(entry["path"] == dish)
			base = entry["price"]
	return list("name" = "Блюдо дня от шефа: [initial(dish.name)]", "path" = dish, "kind" = ROOM_SERVICE_FOOD, "price" = round(base * ROOM_SERVICE_SPECIAL_MULT), "exact" = TRUE)

/proc/room_service_entry(item_id)
	if(item_id == ROOM_SERVICE_SPECIAL_ID)
		return room_service_special_entry()
	return istext(item_id) ? GLOB.room_service_menu[item_id] : null

/// Вид заказа, который закрывает предмет: блюдо или налитый напиток.
/proc/room_service_item_kind(obj/item/thing)
	if(istype(thing, /obj/item/reagent_containers/food/snacks))
		return ROOM_SERVICE_FOOD
	if(istype(thing, /obj/item/reagent_containers/food/drinks) && thing.reagents?.total_volume > 0)
		return ROOM_SERVICE_DRINK
	return null

/// Сколько порций в предмете: стопка блинчиков считается по блинчикам.
/proc/room_service_item_units(obj/item/thing)
	if(istype(thing, /obj/item/reagent_containers/food/snacks/pancakes))
		return 1 + length(thing.contents)
	return 1

/// Поднос отправляет только еду и напитки: это не телепорт для чего угодно. Внутри можно только то, что прошло бы само.
/proc/room_service_item_allowed(obj/item/thing)
	var/static/list/banned = typecacheof(list(
		/obj/item/reagent_containers/food/snacks/cube,
		/obj/item/reagent_containers/food/drinks/bottle/molotov,
		/obj/item/reagent_containers/food/snacks/grown/cherry_bomb,
		/obj/item/reagent_containers/food/snacks/grown/firelemon,
	))
	if(!istype(thing, /obj/item/reagent_containers/food) || is_type_in_typecache(thing, banned))
		return FALSE
	if(!length(thing.contents))
		return TRUE
	if(!istype(thing, /obj/item/reagent_containers/food/snacks/customizable) && !istype(thing, /obj/item/reagent_containers/food/snacks/pancakes))
		return FALSE
	for(var/atom/movable/inner as anything in thing.contents)
		if(!isitem(inner) || !room_service_item_allowed(inner))
			return FALSE
	return TRUE

/// Имена вещей через запятую, одинаковые - с числом.
/proc/room_service_names(list/things)
	var/list/counts = list()
	for(var/atom/movable/thing as anything in things)
		counts["[thing.name]"] += 1
	var/list/parts = list()
	for(var/name in counts)
		parts += counts[name] > 1 ? "[name] x[counts[name]]" : name
	return jointext(parts, ", ")

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
	var/review_timer
	var/remind_timer
	/// Сотрудник, который взял заказ
	var/datum/weakref/claimer
	var/claimer_name
	/// Деньги уже ушли сервису или вернулись заказчику
	var/settled = FALSE

/datum/room_service_order/New(obj/machinery/room_service_panel/panel, datum/bank_account/payer, mob/living/guest, item_id, list/entry, count)
	src.panel = panel
	src.payer = payer
	payer_mob = WEAKREF(guest)
	src.item_id = item_id
	src.entry = entry
	src.count = count
	total = entry["price"] * count
	room_number = panel.room_number
	uid = ++GLOB.room_service.next_uid
	deadline = world.time + ROOM_SERVICE_STAFF_WAIT
	timer_id = addtimer(CALLBACK(src, PROC_REF(expire)), ROOM_SERVICE_STAFF_WAIT, TIMER_STOPPABLE)
	remind_timer = addtimer(CALLBACK(src, PROC_REF(remind)), ROOM_SERVICE_STAFF_WAIT - ROOM_SERVICE_REMIND_BEFORE, TIMER_STOPPABLE)
	schedule_review()
	RegisterSignal(panel, COMSIG_PARENT_QDELETING, PROC_REF(on_panel_deleted))
	RegisterSignal(payer, COMSIG_PARENT_QDELETING, PROC_REF(on_payer_deleted))
	GLOB.room_service.orders += src

/datum/room_service_order/Destroy()
	refund("Заказ №[uid] отменён")
	deltimer(timer_id)
	deltimer(review_timer)
	deltimer(remind_timer)
	timer_id = null
	review_timer = null
	remind_timer = null
	GLOB.room_service.orders -= src
	if(payer)
		UnregisterSignal(payer, COMSIG_PARENT_QDELETING)
		payer = null
	payer_mob = null
	claimer = null
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

/datum/room_service_order/proc/claimer_mob()
	var/mob/living/staff = claimer?.resolve()
	return isliving(staff) ? staff : null

/// Строка заказа в списке подноса: без номера комнаты, он приватен.
/datum/room_service_order/proc/tray_label()
	return "Заказ №[uid]: [what()], осталось [minutes_left()] мин.[claimer ? " (взял [claimer_name])" : ""]"

/// Текст заказа для карт и канала сервиса: без номера комнаты, доставка идёт по терминалу заказа.
/datum/room_service_order/proc/staff_notice()
	return "Обслуживание номеров: заказ №[uid] - [what()], [total] кр. Используйте пустой поднос обслуживания номеров (DinnerWare, Booze-O-Mat) в руке, чтобы взять заказ, потом положите заказ на поднос и используйте его ещё раз. Не взятый за [DisplayTimeText(ROOM_SERVICE_CLAIM_WAIT)] заказ отменяется, срок доставки - [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)]."

/// Возврат предоплаты: ровно один раз на заказ, что бы его ни закрыло. quiet - без сообщения на карту.
/datum/room_service_order/proc/refund(why, quiet = FALSE)
	if(settled)
		return FALSE
	settled = TRUE
	GLOB.room_service.orders -= src
	if(!payer || !SSeconomy.move(GLOB.room_service.escrow_account(), payer, total, ECON_REFUND, null, "Обслуживание номеров: возврат заказа №[uid]"))
		log_econ("Обслуживание номеров: возврат заказа №[uid] на [total] кр. не прошёл")
		return FALSE
	GLOB.room_service.note("refunded")
	if(!quiet)
		payer.bank_card_talk("[why]: [total] кр. вернулись на счёт.", balloon = "возврат +[total] кр")
	log_econ("Обслуживание номеров: заказ №[uid] ([what()], номер [room_number]) - [total] кр. вернулись [payer.account_holder] ([payer.account_id]): [why]")
	return TRUE

/// Не успели или не взяли: деньги назад, а если гость в номере - номеру открывается кейтеринг NT этого вида.
/datum/room_service_order/proc/expire(early = FALSE)
	if(settled || QDELETED(src))
		return
	var/obj/machinery/room_service_panel/room_panel = panel
	var/room_open = !!room_panel?.has_guest()
	var/why
	if(early)
		why = "Никто из сервиса не взял заказ №[uid] ([what()]) за [DisplayTimeText(ROOM_SERVICE_CLAIM_WAIT)]"
	else if(room_open)
		why = "Сервис не успел с заказом №[uid] ([what()]) за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)]"
	else
		why = "Заказ №[uid] не доставлен за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)]"
	refund(why)
	if(room_open)
		room_panel.catering_open |= entry["kind"]
		room_panel.say("Заказ №[uid] не [early ? "взяли" : "успели доставить"], деньги вернулись. Теперь можно заказать готовое у NT.")
	qdel(src)

/datum/room_service_order/proc/schedule_review()
	deltimer(review_timer)
	review_timer = null
	if(world.time + ROOM_SERVICE_CLAIM_WAIT < deadline)
		review_timer = addtimer(CALLBACK(src, PROC_REF(review)), ROOM_SERVICE_CLAIM_WAIT, TIMER_STOPPABLE)

/// Раз в ROOM_SERVICE_CLAIM_WAIT: не взятый заказ возвращается, с ушедшего сотрудника отметка снимается.
/datum/room_service_order/proc/review()
	review_timer = null
	if(settled || QDELETED(src))
		return
	if(!claimer)
		expire(TRUE)
		return
	if(!room_service_claimer_active(claimer_mob()))
		log_econ("Обслуживание номеров: [claimer_name] больше не занимается заказом №[uid]")
		claimer = null
		claimer_name = null
		payer?.bank_card_talk("[room_service_staff_name(entry["kind"], TRUE)] больше не занимается заказом №[uid]. Если его не возьмут за [DisplayTimeText(ROOM_SERVICE_CLAIM_WAIT)], деньги вернутся.")
		SStgui.update_uis(panel)
	schedule_review()

/// Сотрудник берёт заказ: гость видит, что им занимаются. Возвращает null или текст отказа.
/datum/room_service_order/proc/claim(mob/living/staff)
	if(settled || QDELETED(src))
		return "Этот заказ уже закрыт."
	if(econ_account_of(staff) == payer)
		return "Свой заказ себе не отправляют."
	var/mob/living/current = claimer_mob()
	if(current == staff)
		return "Заказ №[uid] уже за вами: положите его на поднос и используйте поднос ещё раз."
	if(current && room_service_claimer_active(current))
		return "Заказ №[uid] уже взял [claimer_name]."
	claimer = WEAKREF(staff)
	claimer_name = staff.name
	schedule_review()
	payer?.bank_card_talk("[room_service_staff_name(entry["kind"], TRUE)] принял заказ №[uid]: [what()].")
	SStgui.update_uis(panel)
	log_econ("Обслуживание номеров: [key_name(staff)] взял заказ №[uid] ([what()]) в номер [room_number]")
	return null

/// За ROOM_SERVICE_REMIND_BEFORE до срока - на карту взявшему, а если никто не взял - сервису этого вида. Возвращает, скольким напомнили.
/datum/room_service_order/proc/remind()
	remind_timer = null
	. = 0
	if(settled || QDELETED(src))
		return
	var/list/staff = room_service_claimer_active(claimer_mob()) ? list(claimer_mob()) : room_service_staff(entry["kind"])
	for(var/mob/living/member as anything in staff)
		var/datum/bank_account/member_account = econ_account_of(member)
		member_account?.bank_card_talk("Заказ №[uid] ([what()]): до срока доставки [DisplayTimeText(ROOM_SERVICE_REMIND_BEFORE)].")
		.++

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
	. = room_service_sender_problem(sender)
	if(.)
		return
	if(econ_account_of(sender) == payer)
		return "Свой заказ себе не отправляют."
	if(!panel?.room_area())
		return "Заказчика заказа №[uid] сейчас нет в номере, номер закрыт. Заказ ждёт до [STATION_TIME_TIMESTAMP("hh:mm", deadline)]."
	if(!panel.has_guest())
		return "В номере заказа №[uid] некому его принять."
	return tray.contents_problem(entry, count)

/// Отправка подноса: всё с него уходит в номер, предоплата - отправителю и бюджету сервиса, как на кассе. Возвращает null или текст отказа.
/datum/room_service_order/proc/deliver(mob/living/sender, obj/item/storage/bag/tray/room_service/tray)
	. = delivery_problem(sender, tray)
	if(.)
		return
	settled = TRUE
	GLOB.room_service.orders -= src
	var/turf/drop = get_turf(panel)
	var/dishes = 0
	var/drinks = 0
	for(var/obj/item/thing as anything in tray.contents)
		if(istype(thing, /obj/item/reagent_containers/food/snacks))
			dishes += econ_dish_work_units(thing)
		else if(room_service_item_kind(thing) == ROOM_SERVICE_DRINK && econ_drink_work_ready(thing))
			drinks++
	var/list/sent = tray.send_contents(drop)
	var/list/logged = list()
	for(var/obj/item/thing as anything in sent)
		logged += room_service_item_kind(thing) == ROOM_SERVICE_DRINK ? "[thing.name] ([thing.reagents.log_list()])" : thing.name
	var/datum/bank_account/account = econ_account_of(sender)
	var/share = pay_out(account, sender)
	var/mob/living/guest = payer_mob?.resolve()
	if(isliving(guest))
		if(dishes)
			SSeconomy.record_work(ACCOUNT_SRV, WORK_SRV_DISH, dishes, sender, guest, "Обслуживание номеров: заказ №[uid]")
		if(drinks)
			SSeconomy.record_work(ACCOUNT_SRV, WORK_SRV_DRINK, drinks, sender, guest, "Обслуживание номеров: заказ №[uid]")
	GLOB.room_service.note("delivered")
	do_sparks(2, FALSE, drop)
	playsound(drop, 'sound/machines/ding.ogg', 50, TRUE)
	var/names = room_service_names(sent)
	panel.say("Заказ №[uid] доставлен: [names]. Приятного аппетита!")
	payer?.bank_card_talk("Заказ №[uid] доставлен в номер [room_number]: [names].")
	panel.offer_tip(src, account, sender)
	playsound(sender, 'sound/effects/phasein.ogg', 25, TRUE)
	to_chat(sender, span_notice("Заказ №[uid] доставлен: [names]. Ваша доля - [share] кр."))
	log_econ("Обслуживание номеров: [key_name(sender)] доставил заказ №[uid] ([what()], [total] кр.) в номер [room_number], доля [share] кр.: [jointext(logged, ", ")]")
	log_game("[key_name(sender)] доставил подносом заказ №[uid] ([what()]) в номер отеля [room_number]: [jointext(logged, ", ")]")
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
	/// Виды заказов, по которым сервис не успел, пока гость был в номере: открыт кейтеринг NT, пока номер не уберут в хранилище
	var/list/catering_open = list()
	/// id набора декора -> сколько раз куплен в этот номер
	var/list/decor_bought = list()
	/// "uid" доставленного заказа -> list(кто платил, кому чаевые, имя, что, до какого времени)
	var/list/tip_offers = list()
	COOLDOWN_DECLARE(act_cooldown)

/obj/machinery/room_service_panel/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(QDELETED(src))
		return
	if(!room_service_place_ok(src))
		qdel(src)
		return
	if(!isturf(loc))
		catering_open.Cut()

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
	. += span_notice("Если повар или бармен на смене, заказ уходит ему: он берёт заказ, готовит и отправляет его в номер подносом обслуживания номеров. Деньги списываются сразу; если заказ никто не возьмёт за [DisplayTimeText(ROOM_SERVICE_CLAIM_WAIT)] или не доставят за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)], они вернутся, а пока вы в номере, ему откроется кейтеринг NT.")
	. += span_notice("Кейтеринг NT присылает готовое сразу, но [econ_times_text(ROOM_SERVICE_CATERING_MULT)] дороже. После доставки можно оставить чаевые тому, кто прислал заказ. Декор, купленный здесь, остаётся в номере, пока номер хранится.")
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
		"claim_minutes" = ROOM_SERVICE_CLAIM_WAIT / (1 MINUTES),
		"tip_amounts" = GLOB.room_service_tip_amounts,
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
			"kind" = order.entry["kind"],
			"count" = order.count,
			"total" = order.total,
			"minutes_left" = order.minutes_left(),
			"taken" = !!order.claimer,
			"mine" = order.payer == account,
		))
	var/list/tips = list()
	for(var/uid in tip_offers)
		var/list/offer = tip_offers[uid]
		var/datum/weakref/payer_ref = offer["payer"]
		if(account && payer_ref?.resolve() == account && world.time < offer["until"])
			tips += list(list("uid" = text2num(uid), "name" = offer["what"], "staff" = offer["staff_name"]))
	var/list/special = room_service_special_entry()
	return list(
		"room" = room_number,
		"open" = !!room_area(),
		"account_problem" = SSeconomy.personal_account_problem(account, TRUE),
		"has_account" = !!account,
		"balance" = account ? account.account_balance : 0,
		"staff" = list(ROOM_SERVICE_FOOD = !!length(room_service_staff(ROOM_SERVICE_FOOD)), ROOM_SERVICE_DRINK = !!length(room_service_staff(ROOM_SERVICE_DRINK))),
		"catering" = list(ROOM_SERVICE_FOOD = catering_allowed(ROOM_SERVICE_FOOD), ROOM_SERVICE_DRINK = catering_allowed(ROOM_SERVICE_DRINK)),
		"special" = special ? list("id" = ROOM_SERVICE_SPECIAL_ID, "name" = special["name"], "kind" = special["kind"], "price" = special["price"]) : null,
		"orders" = rows,
		"tips" = tips,
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
		if("tip")
			result = give_tip(user, econ_ui_number(params["uid"]), econ_ui_number(params["amount"]))
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
	var/list/entry = room_service_entry(item_id)
	if(!entry || !isnum(count) || !(route in list("staff", "catering")))
		return list(FALSE, "Неверный заказ.")
	count = round(count)
	if(count < 1 || count > ROOM_SERVICE_COUNT_MAX)
		return list(FALSE, "За раз можно заказать от 1 до [ROOM_SERVICE_COUNT_MAX] шт.")
	var/kind = entry["kind"]
	var/datum/bank_account/account = econ_account_of(user)
	if(route == "catering")
		if(entry["exact"])
			return list(FALSE, "Блюдо дня готовит только повар станции.")
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
	var/datum/room_service_order/order = new(src, account, user, item_id, entry, count)
	GLOB.room_service.note("staff")
	update_appearance()
	notify_staff(order)
	log_econ("Обслуживание номеров: [key_name(user)] заказал №[order.uid] ([what], [total] кр.) в номер [room_number]")
	log_game("[key_name(user)] заказал в номер отеля [room_number]: [what] за [total] кр. (заказ №[order.uid])")
	return list(TRUE, "Заказ №[order.uid] принят: [what], [total] кр. списаны. Его приготовит и пришлёт [room_service_staff_name(kind)] станции; если никто не возьмёт заказ за [DisplayTimeText(ROOM_SERVICE_CLAIM_WAIT)] или не доставят за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)] - деньги вернутся.")

/obj/machinery/room_service_panel/proc/order_catering(mob/living/user, datum/bank_account/account, list/entry, count)
	var/kind = entry["kind"]
	if(!catering_allowed(kind))
		return list(FALSE, "[room_service_staff_name(kind, TRUE)] на смене: закажите у него. Кейтеринг NT откроется, если сервис не успеет с заказом.")
	var/unit_price = entry["price"] * ROOM_SERVICE_CATERING_MULT
	var/price = unit_price * count
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
		econ_mark_vended(new path(drop), unit_price)
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
		order.refund("Заказ №[uid] отменён", quiet = TRUE)
		qdel(order)
		log_econ("Обслуживание номеров: [key_name(user)] отменил заказ №[uid] в номер [room_number]")
		return list(TRUE, "Заказ №[uid] отменён.")
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
		econ_mark_vended(screen_sign, price)
	var/list/items = decor_set["items"]
	var/pieces = 0
	for(var/path in items)
		pieces += items[path]
	for(var/path in items)
		for(var/i in 1 to items[path])
			econ_mark_vended(new path(drop), round(price / pieces))
	do_sparks(2, FALSE, drop)
	GLOB.room_service.note("decor")
	log_econ("Обслуживание номеров: [key_name(user)] купил декор \"[decor_set["name"]]\" в номер [room_number] за [price] кр.")
	return list(TRUE, "[decor_set["name"]] для номера: [price] кр. списаны. Вещи остаются в номере, пока номер хранится.")

/// После доставки заказчик ROOM_SERVICE_TIP_WINDOW может оставить чаевые тому, кто прислал заказ.
/obj/machinery/room_service_panel/proc/offer_tip(datum/room_service_order/order, datum/bank_account/staff_account, mob/living/sender)
	if(!order.payer || !staff_account)
		return
	var/key = "[order.uid]"
	tip_offers[key] = list("payer" = WEAKREF(order.payer), "staff" = WEAKREF(staff_account), "staff_name" = sender.name, "what" = order.what(), "until" = world.time + ROOM_SERVICE_TIP_WINDOW)
	addtimer(CALLBACK(src, PROC_REF(drop_tip), key), ROOM_SERVICE_TIP_WINDOW)

/obj/machinery/room_service_panel/proc/drop_tip(key)
	tip_offers -= key
	SStgui.update_uis(src)

/obj/machinery/room_service_panel/proc/give_tip(mob/living/user, uid, amount)
	var/list/offer = isnum(uid) ? tip_offers["[uid]"] : null
	if(!offer || world.time >= offer["until"])
		return list(FALSE, "Чаевые за этот заказ уже не оставить.")
	if(!(amount in GLOB.room_service_tip_amounts))
		return list(FALSE, "Неверная сумма.")
	var/datum/bank_account/account = econ_account_of(user)
	var/datum/weakref/payer_ref = offer["payer"]
	if(!account || payer_ref.resolve() != account)
		return list(FALSE, "Чаевые оставляет тот, кто платил за заказ.")
	var/datum/weakref/staff_ref = offer["staff"]
	var/datum/bank_account/staff_account = staff_ref.resolve()
	var/problem = SSeconomy.send_tip(account, staff_account, amount, user)
	if(problem)
		return list(FALSE, problem)
	tip_offers -= "[uid]"
	GLOB.room_service.note("tips", amount)
	log_econ("Обслуживание номеров: [key_name(user)] оставил [amount] кр. чаевых за заказ №[uid] ([offer["staff_name"]])")
	return list(TRUE, "Чаевые [amount] кр. за заказ №[uid] ушли: [offer["staff_name"]].")

/// Сообщает поварам или барменам на смене о каждом заказе, каналу сервиса - не чаще ROOM_SERVICE_NOTIFY_COOLDOWN на вид. Возвращает, скольким сотрудникам ушло на карту.
/obj/machinery/room_service_panel/proc/notify_staff(datum/room_service_order/order)
	. = 0
	var/text = order.staff_notice()
	for(var/mob/living/carbon/human/member as anything in room_service_staff(order.entry["kind"]))
		var/datum/bank_account/member_account = econ_account_of(member)
		member_account?.bank_card_talk(text)
		.++
	GLOB.room_service.radio(order.entry["kind"], text)

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
	desc = "Поднос обслуживания номеров отеля Гильберта. Используйте пустой поднос в руке, чтобы взять заказ: гость увидит, что им занимаются. Потом положите на поднос заказанные блюда или напитки и используйте его ещё раз: блюспейс-канал отправит их в номер заказчика, а сам поднос останется у вас. Работает только у сотрудника сервиса, только с едой и напитками и только по открытому заказу."
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

/// Строка списка подноса -> uid заказа: после выбора заказ ищется заново, окно его не держит.
/proc/room_service_order_choices(list/orders)
	. = list()
	for(var/datum/room_service_order/order as anything in orders)
		.[order.tray_label()] = order.uid

/obj/item/storage/bag/tray/room_service/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return
	var/problem = room_service_sender_problem(user)
	if(problem)
		to_chat(user, span_warning(problem))
		return
	var/list/open = GLOB.room_service.open_orders()
	if(!length(open))
		to_chat(user, span_warning("Ждущих доставки заказов в номера нет."))
		return
	var/datum/room_service_order/order = open[1]
	if(length(open) > 1)
		var/list/choices = room_service_order_choices(open)
		var/choice = tgui_input_list(user, "Какой заказ?", name, choices, timeout = ROOM_SERVICE_PICK_TIMEOUT)
		order = choice ? GLOB.room_service.order_by_uid(choices[choice]) : null
		if(!order || QDELETED(src))
			return
	problem = use_on_order(user, order)
	if(problem)
		to_chat(user, span_warning(problem))

/// Пустой поднос берёт заказ, с заказом на подносе - отправляет. Возвращает null или текст отказа.
/obj/item/storage/bag/tray/room_service/proc/use_on_order(mob/living/user, datum/room_service_order/order)
	if(length(contents) || order.claimer_mob() == user)
		return order.deliver(user, src)
	. = order.claim(user)
	if(!.)
		to_chat(user, span_notice("Вы взяли заказ №[order.uid]: [order.what()], осталось [order.minutes_left()] мин. Положите его на поднос и используйте поднос ещё раз."))

/// Почему содержимое подноса не закрывает заказ из count штук позиции entry; null - закрывает.
/obj/item/storage/bag/tray/room_service/proc/contents_problem(list/entry, count)
	if(!length(contents))
		return "Поднос пуст: положите на него заказ."
	var/kind = entry["kind"]
	var/matching = 0
	for(var/obj/item/thing as anything in contents)
		if(!room_service_item_allowed(thing))
			return "[thing.name] в номер не отправить: только готовые блюда и напитки, внутри - только еда."
		if(room_service_item_kind(thing) == kind && (!entry["exact"] || istype(thing, entry["path"])))
			matching += room_service_item_units(thing)
	if(matching < count)
		if(entry["exact"])
			return "Заказано: [entry["name"]] x[count], на подносе: [matching]."
		return "Заказано [kind == ROOM_SERVICE_FOOD ? "блюд" : "напитков"]: [count], на подносе: [matching]."
	return null

/// Всё с подноса уходит на drop и возвращается списком; доставленное уже оплачено, при еде и питье работа сервиса второй раз не засчитывается.
/obj/item/storage/bag/tray/room_service/proc/send_contents(turf/drop)
	. = list()
	for(var/obj/item/thing as anything in contents)
		SEND_SIGNAL(src, COMSIG_TRY_STORAGE_TAKE, thing, drop, TRUE)
		. += thing
		for(var/obj/item/part as anything in thing.GetAllContents(/obj/item))
			part.econ_paid = TRUE
			if(part.econ_dish)
				part.econ_dish.paid = TRUE
		var/obj/item/reagent_containers/container = thing
		if(istype(container))
			container.econ_pourer = null
	update_appearance()

/// Экран Muz-TV номера: прикручен намертво, играет только в своём номере, молчит в хранилище и исчезает, если его вынесут из отеля.
/obj/structure/sign/moniq/room_service
	desc = "Экран Muz-TV номера отеля: нажмите на него, чтобы поставить музыку, треки бесплатные. Слышно только в этом номере; когда номер убирают в хранилище, музыка выключается. Снять со стены нельзя."
	buildable_sign = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/sign/moniq/room_service/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(QDELETED(src))
		return
	if(!room_service_place_ok(src))
		qdel(src)
		return
	if(!isturf(loc))
		stop_music()

/// Перетаскивание на себя только открывает выбор музыки: экран не снимается.
/obj/structure/sign/moniq/room_service/MouseDrop(atom/over, src_location, over_location, src_control, over_control, params)
	if(over && over == usr)
		SEND_SIGNAL(src, COMSIG_MOUSEDROP_ONTO, over, usr)
		return
	return ..()

/obj/structure/sign/moniq/room_service/proc/stop_music()
	var/datum/component/jukebox/jukebox = GetComponent(/datum/component/jukebox)
	if(!jukebox?.playing)
		return
	jukebox.active = FALSE
	jukebox.stop = 0
	jukebox.dance_over()
	STOP_PROCESSING(SSobj, jukebox)
	jukebox.playing = null
	jukebox.on_music_toggle?.Invoke(FALSE)

#undef ROOM_SERVICE_WALL_OFFSET
#undef ROOM_SERVICE_WALL_MOUNTED
#undef ROOM_SERVICE_PANEL_RANGE
#undef ROOM_SERVICE_SCREEN_RANGE
#undef ROOM_SERVICE_SPECIAL_ID
#undef ROOM_SERVICE_SPECIAL_MULT
#undef ROOM_SERVICE_SPECIAL_BASE_PRICE
#undef ROOM_SERVICE_PICK_TIMEOUT
