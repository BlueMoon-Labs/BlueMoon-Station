/// Редкие лоты аукциона сектора: предмет, имя для окна и новостей, ориентировочная цена.
GLOBAL_LIST_INIT(market_auction_lots, list(
	list("path" = /obj/item/storage/backpack/holding, "name" = "блюспейс-рюкзак", "value" = 6000),
	list("path" = /obj/item/clothing/suit/space/hardsuit/ancient, "name" = "старинный скафандр NT", "value" = 5000),
	list("path" = /obj/item/instrument/violin/golden, "name" = "золотая скрипка", "value" = 4000),
	list("path" = /obj/item/clothing/shoes/magboots/advance, "name" = "продвинутые магнитные ботинки", "value" = 3500),
	list("path" = /obj/item/organ/cyberimp/arm/toolset, "name" = "имплант-инструментарий", "value" = 3000),
	list("path" = /obj/item/clothing/head/crown, "name" = "корона", "value" = 2500),
	list("path" = /obj/item/clothing/neck/necklace/dope, "name" = "золотая цепь", "value" = 1500),
	list("path" = /obj/item/clothing/head/that, "name" = "цилиндр коллекционера", "value" = 800),
	list("path" = /obj/item/reagent_containers/food/drinks/bottle/goldschlager, "name" = "коллекционный голдшлягер", "value" = 700),
	list("path" = /obj/item/toy/plush/carpplushie, "name" = "коллекционный плюшевый карп", "value" = 600),
	list("path" = /obj/item/stock_parts/cell/bluespace, "name" = "блюспейс-батарея", "value" = 1800),
	list("path" = /obj/item/storage/belt/champion, "name" = "пояс чемпиона", "value" = 1600),
	list("path" = /obj/item/clothing/suit/jacket/leather/overcoat, "name" = "кожаный плащ", "value" = 1300),
	list("path" = /obj/item/instrument/piano_synth, "name" = "синтезатор-пианино", "value" = 1200),
	list("path" = /obj/item/clothing/head/collectable/xenom, "name" = "коллекционная шапка ксеноморфа", "value" = 1100),
	list("path" = /obj/item/clothing/head/collectable/petehat, "name" = "коллекционная шляпа Пита", "value" = 1000),
	list("path" = /obj/item/instrument/guitar, "name" = "гитара ручной работы", "value" = 900),
	list("path" = /obj/item/clothing/head/collectable/wizard, "name" = "коллекционная шляпа волшебника", "value" = 900),
	list("path" = /obj/item/pen/fountain/captain, "name" = "перьевая ручка капитана", "value" = 900),
	list("path" = /obj/item/toy/talking/AI, "name" = "говорящая игрушка ИИ", "value" = 700),
	list("path" = /obj/item/clothing/head/hardhat/cakehat, "name" = "шляпа-торт", "value" = 600),
	list("path" = /obj/item/toy/plush/beeplushie, "name" = "плюшевая пчёлка", "value" = 600),
))

/// Кто ещё торгуется на аукционе сектора.
GLOBAL_LIST_INIT(market_auction_rivals, list(
	"станция \"Кило-7\"",
	"аванпост \"Тау Кита\"",
	"станция \"Сигма-3\"",
	"база \"Ипсилон\"",
	"станция \"Дельта-Аква\"",
	"торговый пост \"Перекрёсток\"",
))

/// Лот аукциона сектора: ставки станции замораживаются на счёте биржи, соперники - другие станции сектора.
/datum/auction_lot
	var/uid
	var/obj/item/item_type
	var/name
	var/value
	var/bid = 0
	/// Счёт станции с текущей ставкой; null - ведёт соперник или ставок нет
	var/datum/bank_account/bidder_account
	var/bidder_name
	var/ends_at
	var/next_rival_at = 0
	/// Имя соперника -> сколько он готов отдать
	var/list/rivals = list()
	/// Последние ставки: list(кто, сколько)
	var/list/history = list()
	/// weakref счёта, который ставил на лот, -> TRUE: перебитым за минуту до конца приходит напоминание
	var/list/bidder_refs = list()
	var/ending_warned = FALSE
	var/step_timer

/datum/auction_lot/Destroy()
	deltimer(step_timer)
	set_leader(null)
	return ..()

/datum/auction_lot/proc/start_price()
	return max(AUCTION_MIN_INCREMENT, round(value * AUCTION_START_SHARE))

/datum/auction_lot/proc/increment()
	return max(AUCTION_MIN_INCREMENT, round(bid * AUCTION_INCREMENT_SHARE))

/// Наименьшая ставка, которую лот сейчас примет.
/datum/auction_lot/proc/min_bid()
	return bid ? bid + increment() : start_price()

/datum/auction_lot/proc/seconds_left()
	return max(0, CEILING((ends_at - world.time) / (1 SECONDS), 1))

/datum/auction_lot/proc/lot_desc()
	return initial(item_type.desc)

/datum/auction_lot/proc/label()
	return "Аукцион сектора"

/// Продаёт ли лот этот счёт: на свой лот ставить нельзя.
/datum/auction_lot/proc/sold_by(datum/bank_account/account)
	return FALSE

/// Ставка в последнюю минуту продлевает торги до минуты: соперники и станция успевают ответить.
/datum/auction_lot/proc/note_bid(who, amount)
	bid = amount
	bidder_name = who
	history.Insert(1, list(list(who, amount)))
	if(length(history) > AUCTION_HISTORY_MAX)
		history.Cut(AUCTION_HISTORY_MAX + 1)
	if(ends_at - world.time < AUCTION_SNIPE_WINDOW)
		ends_at = world.time + AUCTION_SNIPE_WINDOW

/// Чья замороженная ставка сейчас ведёт; удаление этого счёта сжигает его ставку.
/datum/auction_lot/proc/set_leader(datum/bank_account/account)
	if(bidder_account == account)
		return
	if(bidder_account)
		UnregisterSignal(bidder_account, COMSIG_PARENT_QDELETING)
	bidder_account = account
	if(account)
		RegisterSignal(account, COMSIG_PARENT_QDELETING, PROC_REF(on_leader_deleted))

/datum/auction_lot/proc/on_leader_deleted(datum/bank_account/source)
	SIGNAL_HANDLER
	set_leader(null)
	SSeconomy.move(SSeconomy.market_account, null, bid, ECON_ACCOUNT_CLOSED, null, "Аукцион: ставка закрытого счёта, лот \"[name]\"")

/// Лот для окон: mine - ведёт ли ставка account, outbid - account ставил, но его перебили.
/datum/auction_lot/proc/ui_entry(datum/bank_account/account)
	var/list/bids = list()
	for(var/list/entry as anything in history)
		bids += list(list("who" = entry[1], "amount" = entry[2]))
	var/datum/weakref/account_ref = account?.weak_reference
	return list(
		"uid" = uid,
		"name" = name,
		"desc" = lot_desc(),
		"value" = value,
		"bid" = bid,
		"bidder" = bidder_name,
		"mine" = !!account && bidder_account == account,
		"outbid" = !!account_ref && bidder_account != account && !!bidder_refs[account_ref],
		"min_bid" = min_bid(),
		"increment" = increment(),
		"left" = seconds_left(),
		"rivals" = length(rivals),
		"history" = bids,
	)

/// Лот экипажа: вещь продавца ждёт итога вне карты, соперников-станций нет, сбор NT с продажи сгорает.
/datum/auction_lot/crew
	/// Выставленная вещь, пока лот идёт
	var/obj/item/stored
	var/datum/bank_account/seller_account
	var/anonymous = FALSE
	var/start = 0
	/// За столько лот покупают сразу, ставки идут ниже; 0 - только торги
	var/buyout = 0
	/// Исходное описание типа вещи: правки игрока в эфир и сообщения не идут
	var/desc
	/// Что игрок написал на вещи ручкой или этикеткой: только пометкой в окне
	var/inscription
	/// Пад, с которого вещь приняли: посылка с итогом встанет на него
	var/turf/origin

/datum/auction_lot/crew/Destroy()
	if(seller_account)
		UnregisterSignal(seller_account, COMSIG_PARENT_QDELETING)
		seller_account = null
	var/obj/item/leftover = take_item()
	if(leftover)
		qdel(leftover)
	origin = null
	return ..()

/datum/auction_lot/crew/start_price()
	return start

/datum/auction_lot/crew/lot_desc()
	return desc

/datum/auction_lot/crew/label()
	return "Аукцион экипажа"

/datum/auction_lot/crew/sold_by(datum/bank_account/account)
	return !!account && account == seller_account

/datum/auction_lot/crew/proc/seller_name()
	return anonymous ? "аноним" : seller_account?.account_holder

/datum/auction_lot/crew/ui_entry(datum/bank_account/account)
	. = ..()
	.["seller"] = seller_name()
	.["my_lot"] = sold_by(account)
	.["buyout"] = buyout
	.["inscription"] = inscription

/// Вещь уходит с пада на хранение лота.
/datum/auction_lot/crew/proc/hold(obj/item/thing, datum/bank_account/seller)
	stored = thing
	econ_auction_stash(thing)
	RegisterSignal(thing, COMSIG_PARENT_QDELETING, PROC_REF(on_item_deleted))
	seller_account = seller
	RegisterSignal(seller, COMSIG_PARENT_QDELETING, PROC_REF(on_seller_deleted))

/// Забирает вещь с хранения: дальше за неё отвечает вызывающий.
/datum/auction_lot/crew/proc/take_item()
	. = stored
	if(stored)
		UnregisterSignal(stored, COMSIG_PARENT_QDELETING)
		stored = null

/datum/auction_lot/crew/proc/on_item_deleted(datum/source)
	SIGNAL_HANDLER
	take_item()
	SSmarket.close_crew_lot(src, "вещь с лота пропала")

/datum/auction_lot/crew/proc/on_seller_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(seller_account, COMSIG_PARENT_QDELETING)
	seller_account = null
	SSmarket.close_crew_lot(src, "счёт продавца закрыт")

/datum/controller/subsystem/market
	var/datum/auction_lot/auction
	var/next_auction_at = 0
	var/auction_uid = 0
	/// Итоги последних лотов сектора для окна: list(лот, победитель, цена, станция ли)
	var/list/auction_results = list()
	/// Итоги последних лотов экипажа: list(лот, победитель или null, цена)
	var/list/crew_auction_results = list()
	/// Куда приходит посылка с лотом; null - на пад лота или капсулой в снабжение
	var/turf/auction_drop_turf
	/// Идущие лоты экипажа
	var/list/crew_lots = list()
	/// Раньше этого новый лот не звучит по общему каналу
	var/auction_announce_ready_at = 0
	var/auction_round_end_hooked = FALSE

/// Раз в минуту из fire(): новый лот, когда старый закончился и подошло время.
/datum/controller/subsystem/market/proc/tick_auction()
	if(auction)
		return
	if(!next_auction_at)
		next_auction_at = world.time + rand(AUCTION_FIRST_MIN, AUCTION_FIRST_MAX)
		return
	if(world.time >= next_auction_at)
		start_auction()

/// Новый лот: случайный предмет, 2-3 соперника с потолком вокруг его цены.
/datum/controller/subsystem/market/proc/start_auction(list/lot_entry)
	if(auction)
		return null
	lot_entry = lot_entry || pick(GLOB.market_auction_lots)
	var/datum/auction_lot/lot = new
	lot.uid = ++auction_uid
	lot.item_type = lot_entry["path"]
	lot.name = lot_entry["name"]
	lot.value = lot_entry["value"]
	lot.ends_at = world.time + AUCTION_DURATION
	lot.next_rival_at = world.time + rand(AUCTION_RIVAL_DELAY_MIN, AUCTION_RIVAL_DELAY_MAX)
	var/list/names = GLOB.market_auction_rivals.Copy()
	for(var/i in 1 to rand(2, 3))
		lot.rivals[pick_n_take(names)] = round(lot.value * rand(AUCTION_RIVAL_MAX_MIN, AUCTION_RIVAL_MAX_MAX) / 100)
	auction = lot
	hook_auction_round_end()
	publish("Аукцион сектора: на торги выставлен лот \"[lot.name]\", начальная цена [lot.start_price()] кр. Ставки - в Кошельке на КПК и в консоли снабжения, торги около [round(AUCTION_DURATION / (1 MINUTES))] мин.")
	announce_auction_lot(lot, round(AUCTION_DURATION / (1 MINUTES)))
	var/list/rival_caps = list()
	for(var/rival in lot.rivals)
		rival_caps += "[rival] до [lot.rivals[rival]] кр."
	log_econ("Аукцион: лот #[lot.uid] \"[lot.name]\" выставлен, соперники: [jointext(rival_caps, ", ")]")
	schedule_auction_step(lot)
	return lot

/// Новый лот одной строкой по общему каналу, не чаще auction_announce_minutes на всю станцию. В строке только исходные имя и описание типа вещи, правки игрока в эфир не идут. TRUE, если прозвучал.
/datum/controller/subsystem/market/proc/announce_auction_lot(datum/auction_lot/lot, minutes)
	if(world.time < auction_announce_ready_at)
		return FALSE
	var/text
	var/buyout_text = ""
	var/datum/auction_lot/crew/crew_lot = lot
	if(istype(crew_lot))
		var/desc = trim(crew_lot.desc)
		if(length_char(desc) > AUCTION_RADIO_DESC_MAX)
			desc = "[trim(copytext_char(desc, 1, AUCTION_RADIO_DESC_MAX + 1))]..."
		else if(desc && !(copytext_char(desc, -1) in list(".", "!", "?")))
			desc += "."
		text = "Аукцион экипажа: [crew_lot.seller_name()] продаёт \"[lot.name]\"[desc ? " - [desc]" : "."]"
		if(crew_lot.buyout)
			buyout_text = ", купить сразу - [crew_lot.buyout] кр."
	else
		text = "Аукцион сектора: на торгах \"[lot.name]\"."
	if(!paperwork_radio("[text] Старт [lot.start_price()] кр.[buyout_text], торги [minutes] мин. Ставки - в Кошельке на КПК, вкладка «Заказы».", RADIO_CHANNEL_COMMON))
		return FALSE
	auction_announce_ready_at = world.time + SSeconomy.settings.auction_announce_minutes MINUTES
	return TRUE

/datum/controller/subsystem/market/proc/auction_active(datum/auction_lot/lot)
	return !QDELETED(lot) && (lot == auction || (lot in crew_lots))

/// Шаг торгов: соперники перебивают, за минуту до конца перебитым приходит напоминание, время вышло - итог.
/datum/controller/subsystem/market/proc/auction_step(datum/auction_lot/lot)
	if(!auction_active(lot))
		return
	if(world.time >= lot.ends_at)
		if(lot == auction)
			finish_auction()
		else
			finish_crew_lot(lot)
		return
	if(!lot.ending_warned && lot.ends_at - world.time <= AUCTION_SNIPE_WINDOW)
		lot.ending_warned = TRUE
		warn_outbid(lot)
		warn_seller_no_bids(lot)
	if(length(lot.rivals) && world.time >= lot.next_rival_at)
		rival_bid(lot)
		var/hurry = lot.ends_at - world.time < AUCTION_SNIPE_WINDOW
		lot.next_rival_at = world.time + (hurry ? rand(AUCTION_RIVAL_HURRY_MIN, AUCTION_RIVAL_HURRY_MAX) : rand(AUCTION_RIVAL_DELAY_MIN, AUCTION_RIVAL_DELAY_MAX))
	schedule_auction_step(lot)

/datum/controller/subsystem/market/proc/schedule_auction_step(datum/auction_lot/lot)
	deltimer(lot.step_timer)
	lot.step_timer = addtimer(CALLBACK(src, PROC_REF(auction_step), lot), AUCTION_STEP, TIMER_STOPPABLE)

/// Тем, кто ставил на лот и кого перебили, - что торги вот-вот закончатся.
/datum/controller/subsystem/market/proc/warn_outbid(datum/auction_lot/lot)
	for(var/datum/weakref/account_ref as anything in lot.bidder_refs)
		var/datum/bank_account/account = account_ref.resolve()
		if(!account || account == lot.bidder_account)
			continue
		account.bank_card_talk("[lot.label()]: до конца торгов за \"[lot.name]\" [DisplayTimeText(AUCTION_SNIPE_WINDOW)], вашу ставку перебили - сейчас [lot.bid] кр. Перебить можно в Кошельке на КПК, вкладка «Заказы».", balloon = "торги кончаются")

/// Продавцу лота экипажа без ставок - что торги вот-вот закончатся.
/datum/controller/subsystem/market/proc/warn_seller_no_bids(datum/auction_lot/crew/lot)
	if(!istype(lot) || lot.bid)
		return
	lot.seller_account?.bank_card_talk("Аукцион экипажа: до конца торгов за ваш лот \"[lot.name]\" [DisplayTimeText(AUCTION_SNIPE_WINDOW)], а ставок пока нет. Без ставок вещь вернётся к вам.", balloon = "ставок нет")

/// Соперник, который ещё готов платить и не ведёт, перебивает ставку; возвращает его имя или null.
/datum/controller/subsystem/market/proc/rival_bid(datum/auction_lot/lot, force = FALSE)
	var/list/willing = list()
	for(var/rival in lot.rivals)
		if(rival != lot.bidder_name && lot.rivals[rival] >= lot.min_bid())
			willing += rival
	if(!length(willing) || (!force && !prob(AUCTION_RIVAL_CHANCE)))
		return null
	var/rival = pick(willing)
	var/amount = min(lot.rivals[rival], lot.min_bid() + rand(0, 2) * lot.increment())
	refund_auction_bid(lot)
	lot.note_bid(rival, amount)
	return rival

/// Возврат замороженной ставки, которую перебили или чей лот закрылся; notice - текст карте вместо "перебили".
/datum/controller/subsystem/market/proc/refund_auction_bid(datum/auction_lot/lot, notice)
	var/datum/bank_account/account = lot.bidder_account
	if(!account)
		return
	lot.set_leader(null)
	SSeconomy.move(SSeconomy.market_account, account, lot.bid, ECON_AUCTION_REFUND, null, "Аукцион: возврат ставки, лот \"[lot.name]\"")
	if(notice)
		account.bank_card_talk(notice)
		return
	account.bank_card_talk("[lot.label()]: вашу ставку [lot.bid] кр. на \"[lot.name]\" перебили, деньги вернулись на счёт. Перебить можно в Кошельке на КПК, вкладка «Заказы».", balloon = "ставку перебили")

/datum/controller/subsystem/market/proc/find_auction_lot(uid)
	if(!uid || auction?.uid == uid)
		return auction
	for(var/datum/auction_lot/lot as anything in crew_lots)
		if(lot.uid == uid)
			return lot

/// Почему account не может торговаться за лот; null - может.
/datum/controller/subsystem/market/proc/auction_bidder_problem(datum/auction_lot/lot, datum/bank_account/account)
	if(!lot || world.time >= lot.ends_at)
		return "Этот лот уже не продаётся."
	if(!account)
		return "Нет банковского счёта."
	. = SSeconomy.personal_account_problem(account, TRUE)
	if(.)
		return
	if(account.offstation)
		return "На аукционе торгуется только экипаж станции: со счёта вне станции ставки не принимаются."
	if(lot.sold_by(account))
		return "На свой лот ставить нельзя."

/// Ставка amount от account становится ведущей: к своей ставке доплачивается разница, перебитая чужая возвращается с текстом outbid_notice. Возвращает текст отказа или null.
/datum/controller/subsystem/market/proc/take_auction_bid(datum/auction_lot/lot, datum/bank_account/account, amount, mob/user, memo, outbid_notice)
	var/raising = lot.bidder_account == account
	var/needed = raising ? amount - lot.bid : amount
	if(!account.has_money(needed))
		return "На счёте не хватает: нужно [needed] кр."
	if(!SSeconomy.move(account, SSeconomy.market_account, needed, ECON_AUCTION_BID, user, memo))
		return "Ставка не прошла."
	if(!raising)
		refund_auction_bid(lot, outbid_notice)
	lot.set_leader(account)
	lot.bidder_refs[WEAKREF(account)] = TRUE
	lot.note_bid(account.account_holder, amount)
	return null

/// Ставка с личного счёта: деньги замораживаются на счёте биржи до конца торгов или пока ставку не перебьют. Возвращает текст отказа или null.
/datum/controller/subsystem/market/proc/place_auction_bid(datum/bank_account/account, amount, mob/user, uid)
	var/datum/auction_lot/lot = find_auction_lot(uid)
	. = auction_bidder_problem(lot, account)
	if(.)
		return
	var/datum/auction_lot/crew/crew_lot = lot
	if(istype(crew_lot) && crew_lot.buyout && (lot.min_bid() >= crew_lot.buyout || (isnum(amount) && amount >= crew_lot.buyout)))
		return "Ставка не дойдёт до цены выкупа: этот лот можно сразу купить за [crew_lot.buyout] кр."
	if(!isnum(amount) || round(amount) != amount || amount < lot.min_bid())
		return "Ставка должна быть целой и не меньше [lot.min_bid()] кр."
	if(amount > AUCTION_BID_MAX)
		return "Ставка больше [AUCTION_BID_MAX] кр. не принимается."
	var/first = !lot.bid
	. = take_auction_bid(lot, account, amount, user, "Аукцион: ставка на \"[lot.name]\"")
	if(.)
		return
	log_econ("Аукцион: [key_name(user)] ставит [amount] кр. на лот #[lot.uid] \"[lot.name]\"")
	if(first && istype(crew_lot))
		crew_lot.seller_account?.bank_card_talk("Аукцион экипажа: на ваш лот \"[lot.name]\" поставили [amount] кр. Теперь торги идут до конца, снять лот уже нельзя.", balloon = "первая ставка")

/// Покупка лота экипажа сразу за цену выкупа: лот закрывается проданным. Возвращает list(куплен ли, ответ игроку).
/datum/controller/subsystem/market/proc/buyout_crew_lot(datum/bank_account/account, uid, mob/user)
	var/datum/auction_lot/crew/lot = find_auction_lot(uid)
	if(!istype(lot) || !(lot in crew_lots))
		return list(FALSE, "Этот лот уже не продаётся.")
	var/problem = auction_bidder_problem(lot, account)
	if(problem)
		return list(FALSE, problem)
	if(!lot.buyout)
		return list(FALSE, "Сразу этот лот не купить: продавец выставил его только на торги.")
	var/price = lot.buyout
	problem = take_auction_bid(lot, account, price, user, "Аукцион: покупка \"[lot.name]\" сразу", "Аукцион экипажа: лот \"[lot.name]\" купили сразу за [price] кр., ваша ставка [lot.bid] кр. вернулась на счёт.")
	if(problem)
		return list(FALSE, problem)
	log_econ("Аукцион экипажа: [key_name(user)] купил лот #[lot.uid] \"[lot.name]\" сразу за [price] кр. со счёта [account.account_holder] ([account.account_id])")
	log_game("[key_name(user)] купил лот аукциона экипажа \"[lot.name]\" сразу за [price] кр.")
	var/lot_name = lot.name
	var/place = finish_crew_lot(lot)
	return list(TRUE, "Лот \"[lot_name]\" ваш за [price] кр.[place ? ": [econ_auction_parcel_note(place, TRUE)]" : ""].")

/// Итог торгов: победившая ставка станции сгорает, лот летит посылкой в снабжение; не долетел - деньги назад.
/datum/controller/subsystem/market/proc/finish_auction()
	var/datum/auction_lot/lot = auction
	if(!lot)
		return
	auction = null
	next_auction_at = world.time + rand(AUCTION_GAP_MIN, AUCTION_GAP_MAX)
	var/datum/bank_account/winner = lot.bidder_account
	if(winner)
		var/place = deliver_auction_lot(lot, winner)
		if(place)
			SSeconomy.move(SSeconomy.market_account, null, lot.bid, ECON_AUCTION, null, "Аукцион: лот \"[lot.name]\"")
			lot.set_leader(null)
			winner.bank_card_talk("Аукцион сектора: лот \"[lot.name]\" ваш за [lot.bid] кр.: [econ_auction_parcel_note(place, TRUE)].", TRUE, balloon = "лот ваш!")
			publish("Аукцион сектора: лот \"[lot.name]\" уходит на нашу станцию, покупатель - [winner.account_holder], [lot.bid] кр.")
		else
			refund_auction_bid(lot, "Аукцион сектора: лот \"[lot.name]\" не удалось доставить на станцию, ставка [lot.bid] кр. вернулась на счёт.")
			publish("Аукцион сектора: лот \"[lot.name]\" не удалось доставить на станцию, ставка возвращена.")
	else if(lot.bidder_name)
		publish("Аукцион сектора: лот \"[lot.name]\" ушёл: [lot.bidder_name], [lot.bid] кр.")
	else
		publish("Аукцион сектора: лот \"[lot.name]\" снят с торгов без ставок.")
	note_auction_result(lot.name, lot.bidder_name, lot.bid, !!winner)
	log_econ("Аукцион: лот #[lot.uid] \"[lot.name]\" закрыт, [lot.bidder_name || "без ставок"] [lot.bid] кр.")
	qdel(lot)

/datum/controller/subsystem/market/proc/note_auction_result(name, winner_name, price, ours)
	auction_results.Insert(1, list(list(name, winner_name, price, ours)))
	if(length(auction_results) > AUCTION_RESULTS_MAX)
		auction_results.Cut(AUCTION_RESULTS_MAX + 1)

/// Итоги лотов экипажа копятся отдельно и не вытесняют итоги лотов сектора.
/datum/controller/subsystem/market/proc/note_crew_result(name, winner_name, price)
	crew_auction_results.Insert(1, list(list(name, winner_name, price)))
	if(length(crew_auction_results) > AUCTION_RESULTS_MAX)
		crew_auction_results.Cut(AUCTION_RESULTS_MAX + 1)

/// Лот сектора с биркой лота в запертой посылке победителю. Купленное на аукционе NT выкупает как импорт. Возвращает, где ждать посылку; null - не доставлен.
/datum/controller/subsystem/market/proc/deliver_auction_lot(datum/auction_lot/lot, datum/bank_account/winner)
	var/obj/item/prize = new lot.item_type(null)
	prize.econ_imported = TRUE
	prize.name = "[prize.name] (лот аукциона)"
	. = send_auction_parcel(prize, winner)
	if(!.)
		qdel(prize)

/// Запертая посылка с вещью на счёт owner, открывает её только ID-карта владельца; named - имя владельца на посылке. Встаёт на свободный пад pad_turf, иначе летит блюспейс-капсулой в снабжение, иначе остаётся на месте пада. Возвращает, где её ждать; null - вещь осталась вне карты.
/datum/controller/subsystem/market/proc/send_auction_parcel(obj/item/thing, datum/bank_account/owner, named = TRUE, turf/pad_turf)
	var/obj/item/storage/lockbox/order/parcel = new(null, owner)
	parcel.name = named ? "auction parcel - [owner.account_holder]" : "auction parcel"
	parcel.desc = "Запертая посылка аукциона. Открыть её может только [named ? owner.account_holder : "получатель"] своей ID-картой."
	parcel.econ_imported = TRUE
	thing.forceMove(parcel)
	if(auction_drop_turf)
		parcel.forceMove(auction_drop_turf)
		return "ждёт на складе снабжения"
	var/obj/machinery/piratepad/civilian/pad = econ_auction_free_pad(pad_turf)
	if(pad)
		parcel.forceMove(pad_turf)
		flick(pad.sending_state, pad)
		playsound(pad, 'sound/machines/wewewew.ogg', 50, TRUE)
		return "ждёт на паде подработки"
	var/turf/landing = econ_aid_landing_turf()
	if(landing)
		new /obj/effect/pod_landingzone(landing, /obj/structure/closet/supplypod/bluespacepod, parcel)
		return istype(get_area(landing), /area/cargo/storage) ? "прилетит капсулой на склад снабжения" : "прилетит капсулой в отдел снабжения"
	if(pad_turf)
		parcel.forceMove(pad_turf)
		return "ждёт там, где стоял пад подработки"
	thing.moveToNullspace()
	qdel(parcel)
	return null

/// Пад подработки на pad_turf, если он на станции, собран и не занят отправкой; иначе null.
/proc/econ_auction_free_pad(turf/pad_turf)
	if(!pad_turf || !is_station_level(pad_turf.z))
		return null
	var/obj/machinery/piratepad/civilian/pad = locate() in pad_turf
	if(!pad || pad.panel_open || (pad.machine_stat & BROKEN))
		return null
	for(var/obj/machinery/computer/piratepad_control/civilian/console as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/computer/piratepad_control/civilian))
		if(console.sending && console.linked_pad() == pad)
			return null
	return pad

/// Для карты получателя: какая посылка, где её ждать и чем открыть.
/proc/econ_auction_parcel_note(place, named)
	return "[named ? "запертая посылка на ваше имя" : "безымянная запертая посылка"] [place], откроет её ваша ID-карта"

/// В nullspace вещь уходит мимо Moved(): свет её и того, что в ней, гасится вручную, иначе остаётся на паде.
/proc/econ_auction_stash(atom/movable/thing)
	thing.moveToNullspace()
	for(var/atom/movable/part as anything in thing.GetAllContents())
		part.update_light()
		var/datum/component/overlay_lighting/glow = part.GetComponent(/datum/component/overlay_lighting)
		glow?.check_holder()

/// Идущие лоты экипажа, которые выставил account.
/datum/controller/subsystem/market/proc/crew_lots_of(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/auction_lot/crew/lot as anything in crew_lots)
		if(lot.seller_account == account)
			. += lot

/// Лот экипажа: вещь с пада уходит на хранение, торгуется только экипаж; buyout - цена, за которую лот купят сразу, 0 - без неё. Возвращает list(выставлен ли, ответ игроку).
/datum/controller/subsystem/market/proc/start_crew_lot(mob/user, datum/bank_account/account, atom/movable/thing, price, minutes, anonymous, turf/origin, buyout = 0)
	var/datum/economy_settings/settings = SSeconomy.settings
	if(SSeconomy.round_over())
		return list(FALSE, "Смена закончилась, аукцион закрыт.")
	if(econ_ic_muted(user))
		return list(FALSE, "Вам запрещено говорить в IC, а о новом лоте говорит общий канал - выставлять вещи нельзя.")
	if(!account)
		return list(FALSE, "Нужен ваш банковский счёт: возьмите свою ID-карту в руку или наденьте её.")
	var/problem = SSeconomy.personal_account_problem(account, TRUE)
	if(problem)
		return list(FALSE, problem)
	if(account.offstation)
		return list(FALSE, "Аукцион экипажа принимает вещи только от экипажа станции.")
	if(!COOLDOWN_FINISHED(account, auction_relist_cooldown))
		return list(FALSE, "Вы недавно сняли свой лот: новый можно выставить через [DisplayTimeText(COOLDOWN_TIMELEFT(account, auction_relist_cooldown), 1)].")
	if(!isnum(price) || round(price) != price || price < AUCTION_MIN_INCREMENT || price > AUCTION_BID_MAX)
		return list(FALSE, "Стартовая цена - целое число от [AUCTION_MIN_INCREMENT] до [AUCTION_BID_MAX] кр.")
	if(buyout && (!isnum(buyout) || round(buyout) != buyout || buyout < price || buyout > AUCTION_BID_MAX))
		return list(FALSE, "Цена, за которую лот купят сразу, - целое число от стартовой цены [price] до [AUCTION_BID_MAX] кр.")
	var/list/durations = settings.auction_minutes_options()
	if(!isnum(minutes) || !(minutes in durations))
		return list(FALSE, "Торги идут [jointext(durations, ", ")] мин. - выберите один из вариантов.")
	var/mine = length(crew_lots_of(account))
	if(mine >= settings.auction_crew_lots_per_account)
		return list(FALSE, "Больше лотов сразу не выставить: ваших на торгах уже [mine] из [settings.auction_crew_lots_per_account]. Дождитесь итога или снимите лот без ставок в Кошельке на КПК.")
	if(length(crew_lots) >= settings.auction_crew_lots_max)
		return list(FALSE, "На аукционе уже [settings.auction_crew_lots_max] лотов экипажа, больше NT сразу не принимает. Загляните позже.")
	problem = econ_auction_item_problem(thing)
	if(problem)
		return list(FALSE, problem)
	var/obj/item/item = thing
	var/datum/auction_lot/crew/lot = new
	lot.uid = ++auction_uid
	lot.name = econ_auction_lot_name(item)
	lot.desc = econ_auction_lot_desc(item)
	lot.inscription = econ_auction_inscription(item)
	lot.start = price
	lot.buyout = buyout || 0
	lot.anonymous = !!anonymous
	lot.origin = origin
	lot.ends_at = world.time + minutes MINUTES
	var/player_desc = item.desc != initial(item.desc) ? ", описание игрока: [item.desc]" : ""
	lot.hold(item, account)
	crew_lots += lot
	hook_auction_round_end()
	schedule_auction_step(lot)
	var/announced = announce_auction_lot(lot, minutes)
	var/buyout_text = lot.buyout ? ", купить сразу - [lot.buyout] кр." : ""
	log_econ("Аукцион экипажа: [key_name(user)] выставил лот #[lot.uid] \"[lot.name]\" ([item.type]) со счёта [account.account_holder] ([account.account_id]), старт [price] кр.[buyout_text], [minutes] мин.[lot.anonymous ? ", анонимно" : ""]")
	log_game("[key_name(user)] выставил на аукцион экипажа [item.name] ([item.type]) за [price] кр.[buyout_text] на [minutes] мин.[lot.anonymous ? ", анонимно" : ""][player_desc]")
	return list(TRUE, "Лот \"[lot.name]\" выставлен на [minutes] мин., старт [price] кр.[buyout_text] Сбор NT с продажи - [settings.auction_crew_fee]%.[announced ? " Экипаж услышал о нём по общему каналу." : ""]")

/// Итог торгов лота экипажа: продавцу ставка без сбора NT, победителю посылка; без ставок вещь едет обратно продавцу. Возвращает, где победитель ждёт посылку.
/datum/controller/subsystem/market/proc/finish_crew_lot(datum/auction_lot/crew/lot)
	if(!(lot in crew_lots))
		return
	crew_lots -= lot
	var/datum/bank_account/winner = lot.bidder_account
	var/datum/bank_account/seller = lot.seller_account
	var/place
	if(winner)
		var/fee = round(lot.bid * SSeconomy.settings.auction_crew_fee / 100)
		SSeconomy.move(SSeconomy.market_account, seller, lot.bid - fee, ECON_AUCTION_SALE, null, "Аукцион: продан лот \"[lot.name]\"")
		SSeconomy.move(SSeconomy.market_account, null, fee, ECON_AUCTION_FEE, null, "Аукцион: сбор NT с лота \"[lot.name]\"")
		if(seller)
			SSeconomy.note_outflow(winner, seller, lot.bid - fee)
		lot.set_leader(null)
		var/obj/item/thing = lot.take_item()
		place = thing ? send_auction_parcel(thing, winner, TRUE, lot.origin) : null
		if(thing && !place)
			qdel(thing)
		winner.bank_card_talk("Аукцион экипажа: лот \"[lot.name]\" ваш за [lot.bid] кр.[place ? ": [econ_auction_parcel_note(place, TRUE)]" : ""].", TRUE, balloon = "лот ваш!")
		seller?.bank_card_talk("Аукцион экипажа: лот \"[lot.name]\" продан за [lot.bid] кр., сбор NT [fee] кр., на счёт пришло [lot.bid - fee] кр.", TRUE, balloon = "лот продан")
		log_econ("Аукцион экипажа: лот #[lot.uid] \"[lot.name]\" продан [winner.account_holder] ([winner.account_id]) за [lot.bid] кр., продавцу [seller?.account_holder] [lot.bid - fee] кр., сбор [fee] кр.")
		. = place
	else
		place = return_crew_lot(lot)
		seller?.bank_card_talk("Аукцион экипажа: лот \"[lot.name]\" ушёл без ставок[place ? ", вещь возвращается к вам: [econ_auction_parcel_note(place, !lot.anonymous)]" : ""].", TRUE)
		log_econ("Аукцион экипажа: лот #[lot.uid] \"[lot.name]\" без ставок, вещь возвращена [seller?.account_holder]")
	note_crew_result(lot.name, winner ? lot.bidder_name : null, winner ? lot.bid : 0)
	qdel(lot)

/// Вещь лота уходит посылкой обратно продавцу. Возвращает, где её ждать; null - вещи нет или её некому вернуть.
/datum/controller/subsystem/market/proc/return_crew_lot(datum/auction_lot/crew/lot)
	var/obj/item/thing = lot.take_item()
	if(!thing)
		return null
	. = lot.seller_account ? send_auction_parcel(thing, lot.seller_account, !lot.anonymous, lot.origin) : null
	if(!.)
		log_econ("Аукцион экипажа: вещь лота #[lot.uid] \"[lot.name]\" некому вернуть, удалена")
		qdel(thing)

/// Продавец снимает свой лот, пока на него не ставили; новый лот он выставит только через auction_crew_relist_minutes. Возвращает list(снят ли, ответ игроку).
/datum/controller/subsystem/market/proc/cancel_crew_lot(datum/bank_account/account, uid, mob/user)
	var/datum/auction_lot/crew/lot = find_auction_lot(uid)
	if(!istype(lot) || !(lot in crew_lots))
		return list(FALSE, "Этого лота уже нет на торгах.")
	if(!lot.sold_by(account))
		return list(FALSE, "Снять лот может только продавец.")
	if(lot.bid)
		return list(FALSE, "На лот уже поставили: торги идут до конца.")
	crew_lots -= lot
	var/place = return_crew_lot(lot)
	var/relist_minutes = SSeconomy.settings.auction_crew_relist_minutes
	COOLDOWN_START(account, auction_relist_cooldown, relist_minutes MINUTES)
	log_econ("Аукцион экипажа: [key_name(user)] снял лот #[lot.uid] \"[lot.name]\" без ставок")
	. = list(TRUE, "Лот \"[lot.name]\" снят[place ? ", вещь возвращается к вам: [econ_auction_parcel_note(place, !lot.anonymous)]" : ""].[relist_minutes ? " Новый лот можно выставить через [relist_minutes] мин." : ""]")
	qdel(lot)

/// Лот экипажа закрывается раньше срока: ставка возвращается, вещь, если есть, едет продавцу.
/datum/controller/subsystem/market/proc/close_crew_lot(datum/auction_lot/crew/lot, reason)
	if(!(lot in crew_lots))
		return
	crew_lots -= lot
	refund_auction_bid(lot, "Аукцион экипажа: лот \"[lot.name]\" снят - [reason]. Ваша ставка [lot.bid] кр. вернулась на счёт.")
	var/place = return_crew_lot(lot)
	lot.seller_account?.bank_card_talk("Аукцион экипажа: ваш лот \"[lot.name]\" снят - [reason].[place ? " Вещь возвращается к вам: [econ_auction_parcel_note(place, !lot.anonymous)]." : ""]")
	log_econ("Аукцион экипажа: лот #[lot.uid] \"[lot.name]\" снят - [reason]")
	qdel(lot)

/proc/market_close_auctions()
	SSmarket.close_auctions()

/datum/controller/subsystem/market/proc/hook_auction_round_end()
	if(auction_round_end_hooked)
		return
	auction_round_end_hooked = TRUE
	SSticker.OnRoundend(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(market_close_auctions)))

/// Конец смены: замороженные ставки возвращаются, вещи лотов экипажа - продавцам.
/datum/controller/subsystem/market/proc/close_auctions()
	var/datum/auction_lot/lot = auction
	if(lot)
		auction = null
		refund_auction_bid(lot, "Аукцион сектора: смена закончилась, торги за \"[lot.name]\" закрыты. Ваша ставка [lot.bid] кр. вернулась на счёт.")
		qdel(lot)
	for(var/datum/auction_lot/crew/crew_lot as anything in crew_lots.Copy())
		close_crew_lot(crew_lot, "смена закончилась")

/datum/bank_account
	COOLDOWN_DECLARE(auction_relist_cooldown)

/// Имя лота экипажа - исходное имя типа вещи, переименование ручкой и этикетка в него не идут; у стопки - с числом штук.
/proc/econ_auction_lot_name(atom/movable/thing)
	var/name = format_text(initial(thing.name))
	if(isstack(thing))
		var/obj/item/stack/stack = thing
		return "[name] ([stack.amount] шт.)"
	return name

/// Описание лота экипажа - исходное описание типа вещи.
/proc/econ_auction_lot_desc(atom/movable/thing)
	return format_text(initial(thing.desc))

/// Что игрок написал на вещи ручкой или этикеткой, одной строкой; null - ничего.
/proc/econ_auction_inscription(obj/item/item)
	var/list/parts = list()
	var/datum/component/label/label = item.GetComponent(/datum/component/label)
	if(item.renamedByPlayer)
		var/custom_name = label ? trim(replacetext(item.name, "([label.label_name])", "")) : item.name
		if(custom_name != initial(item.name))
			parts += custom_name
		if(item.desc != initial(item.desc))
			parts += item.desc
	if(label?.label_name)
		parts += label.label_name
	if(!length(parts))
		return null
	var/text = html_decode(jointext(parts, " - "))
	return length_char(text) > AUCTION_INSCRIPTION_MAX ? "[copytext_char(text, 1, AUCTION_INSCRIPTION_MAX + 1)]..." : text

/// Почему вещь нельзя выставить на аукцион экипажа; null - можно.
/proc/econ_auction_item_problem(atom/movable/thing)
	if(!isitem(thing) || thing.anchored)
		return "На аукцион принимаются только вещи, которые можно унести в руках."
	var/obj/item/item = thing
	if(item.item_flags & (ABSTRACT | DROPDEL))
		return "На аукцион принимаются только вещи, которые можно унести в руках."
	if(!GLOB.econ_contraband_built)
		return "Каталог NT ещё сверяется, попробуйте позже."
	var/datum/component/storage/storage = item.GetComponent(/datum/component/storage)
	var/atom/storage_location = storage?.real_location()
	if(storage_location && length(storage_location.contents))
		return "Сначала выньте всё из [item.name]: контейнеры принимаются пустыми."
	for(var/atom/movable/part as anything in item.GetAllContents())
		var/problem = econ_auction_part_problem(part)
		if(problem)
			return part == item ? problem : "Внутри лежит [part.name]. [problem]"
	return null

/// Почему эта вещь или её часть не годится для аукциона экипажа; null - годится.
/proc/econ_auction_part_problem(atom/movable/part)
	var/static/list/weapon_types = typecacheof(list(
		/obj/item/gun,
		/obj/item/melee,
		/obj/item/grenade,
		/obj/item/ammo_box,
		/obj/item/ammo_casing,
		/obj/item/transfer_valve,
		/obj/item/kitchen/knife,
		/obj/item/shield,
		/obj/item/firing_pin,
		/obj/item/restraints,
		/obj/item/assembly/flash,
		/obj/item/fireaxe,
		/obj/item/spear,
		/obj/item/throwing_star,
		/obj/item/claymore,
		/obj/item/katana,
		/obj/item/dualsaber,
		/obj/item/nullrod,
		/obj/item/chainsaw,
		/obj/item/switchblade,
		/obj/item/hatchet,
		/obj/item/scythe,
		/obj/item/electrostaff,
		/obj/item/singularityhammer,
		/obj/item/mjollnir,
		/obj/item/pneumatic_cannon,
		/obj/item/kinetic_crusher,
		/obj/item/minigunpack,
		/obj/item/mecha_parts/mecha_equipment/weapon,
		/obj/item/reagent_containers/spray/pepper,
		/obj/item/flamethrower,
		/obj/item/onetankbomb,
		/obj/item/bombcore,
		/obj/item/syndicatedetonator,
	))
	var/static/list/antag_types = typecacheof(list(
		/obj/item/spellbook,
		/obj/item/book/granter,
		/obj/item/soulstone,
		/obj/item/necromantic_stone,
		/obj/item/forbidden_book,
		/obj/item/shuttle_curse,
		/obj/item/clockwork,
		/obj/item/abductor,
		/obj/item/antag_spawner,
		/obj/item/uplink,
	))
	var/static/list/body_types = typecacheof(list(
		/obj/item/organ,
		/obj/item/bodypart,
		/obj/item/implant,
		/obj/item/implanter,
		/obj/item/implantcase,
		/obj/item/implantpad,
		/obj/item/autosurgeon,
		/obj/item/mmi,
	))
	var/static/list/access_types = typecacheof(list(
		/obj/item/card/id,
		/obj/item/card/emag,
		/obj/item/door_remote,
		/obj/item/encryptionkey,
	))
	var/static/list/money_types = typecacheof(list(
		/obj/item/stack/spacecash,
		/obj/item/holochip,
		/obj/item/coin,
		/obj/item/stack/metadollar,
	))
	if(ismob(part))
		return "Живых существ на аукцион не выставить."
	if(!isitem(part))
		return null
	var/obj/item/item = part
	if(is_type_in_typecache(item, GLOB.blacklisted_cargo_types) || antag_types[item.type] || item.GetComponent(/datum/component/uplink) || econ_auction_reserved(item))
		return "Эту вещь NT продавать не разрешает."
	if((item.item_flags & NEEDS_PERMIT) || weapon_types[item.type] || item.force >= AUCTION_WEAPON_FORCE || econ_auction_weapon_export(item))
		return "Оружие, взрывчатка, боеприпасы и снаряжение СБ на аукцион не принимаются."
	if(body_types[item.type])
		return "Импланты, органы и части тела на аукцион не принимаются."
	if(access_types[item.type] || item.GetID() || length(item.GetAccess()))
		return "ID-карты и всё, что даёт доступ, на аукцион не принимаются."
	if(money_types[item.type] || item.get_item_credit_value() > 0)
		return "Деньги на аукцион не выставить."
	if(econ_is_contraband(item))
		return "Контрабанду NT на аукцион не пропустит."
	return null

/// Вещь на особом учёте NT: командные реликвии, за которыми охотятся, и цели краж антагонистов прямо сейчас. Цели из ходовых вещей (баллоны, экстракты) не в счёт: отказ всем баллонам выдал бы, что их кто-то ищет.
/proc/econ_auction_reserved(obj/item/item)
	var/static/list/reserved
	var/static/list/common_targets
	if(!reserved)
		var/list/paths = list()
		var/datum/objective_item/base = /datum/objective_item
		common_targets = list(initial(base.targetitem), /obj/item/tank, /obj/item/slime_extract, /obj/item/clothing/underwear/briefs)
		for(var/datum/objective_item/objective_type as anything in subtypesof(/datum/objective_item/steal) + subtypesof(/datum/objective_item/unique))
			var/target = initial(objective_type.targetitem)
			if(ispath(target, /obj/item) && !(target in common_targets))
				paths += target
		reserved = typecacheof(paths)
	if(reserved[item.type])
		return TRUE
	for(var/datum/objective/steal/objective in GLOB.objectives)
		if(!objective.steal_target || (objective.steal_target in common_targets))
			continue
		if(istype(item, objective.steal_target))
			return TRUE
		if(!objective.targetinfo)
			continue
		for(var/alt_type in objective.targetinfo.altitems)
			if(istype(item, alt_type))
				return TRUE
	return FALSE

/// Экспорт NT считает вещь оружием или снаряжением СБ.
/proc/econ_auction_weapon_export(obj/item/item)
	var/static/list/known = list()
	if(!isnull(known[item.type]))
		return known[item.type]
	if(!length(GLOB.exports_list))
		setupExports()
	. = FALSE
	for(var/datum/export/weapon/export in GLOB.exports_list)
		if(export.export_types[item.type] && !export.exclude_types[item.type])
			. = TRUE
			break
	known[item.type] = .

/// Аукцион для окон: лот сектора, лоты экипажа, итоги; mine/outbid/my_lot - со стороны account.
/proc/econ_auction_ui_data(datum/bank_account/account)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/auction_lot/lot = SSmarket.auction
	var/list/results = list()
	for(var/list/result as anything in SSmarket.auction_results)
		results += list(list("name" = result[1], "winner" = result[2], "price" = result[3], "ours" = result[4]))
	var/list/crew_results = list()
	for(var/list/result as anything in SSmarket.crew_auction_results)
		crew_results += list(list("name" = result[1], "winner" = result[2], "price" = result[3]))
	var/list/crew = list()
	for(var/datum/auction_lot/crew/crew_lot as anything in SSmarket.crew_lots)
		crew += list(crew_lot.ui_entry(account))
	return list(
		"auction" = lot?.ui_entry(account),
		"auction_next" = lot ? 0 : max(0, CEILING((SSmarket.next_auction_at - world.time) / (1 SECONDS), 1)),
		"auction_results" = results,
		"crew_results" = crew_results,
		"crew_lots" = crew,
		"auction_fee" = settings.auction_crew_fee,
		"auction_lots_per_account" = settings.auction_crew_lots_per_account,
		"my_balance" = account ? account.account_balance : null,
	)
