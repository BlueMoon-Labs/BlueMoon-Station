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

/datum/auction_lot/proc/start_price()
	return max(AUCTION_MIN_INCREMENT, round(value * AUCTION_START_SHARE))

/datum/auction_lot/proc/increment()
	return max(AUCTION_MIN_INCREMENT, round(bid * AUCTION_INCREMENT_SHARE))

/// Наименьшая ставка, которую лот сейчас примет.
/datum/auction_lot/proc/min_bid()
	return bid ? bid + increment() : start_price()

/datum/auction_lot/proc/seconds_left()
	return max(0, CEILING((ends_at - world.time) / (1 SECONDS), 1))

/// Ставка в последнюю минуту продлевает торги до минуты: соперники и станция успевают ответить.
/datum/auction_lot/proc/note_bid(who, amount)
	bid = amount
	bidder_name = who
	history.Insert(1, list(list(who, amount)))
	if(length(history) > AUCTION_HISTORY_MAX)
		history.Cut(AUCTION_HISTORY_MAX + 1)
	if(ends_at - world.time < AUCTION_SNIPE_WINDOW)
		ends_at = world.time + AUCTION_SNIPE_WINDOW

/datum/controller/subsystem/market
	var/datum/auction_lot/auction
	var/next_auction_at = 0
	var/auction_uid = 0
	/// Итоги последних лотов для окна: list(лот, победитель, цена, станция ли)
	var/list/auction_results = list()
	/// Куда приходит выигранный лот; null - капсулой на склад снабжения
	var/turf/auction_drop_turf

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
	publish("Аукцион сектора: на торги выставлен лот \"[lot.name]\", начальная цена [lot.start_price()] кр. Ставки - в консоли снабжения и приложении \"Заказы снабжения\", торги около [round(AUCTION_DURATION / (1 MINUTES))] мин.")
	log_econ("Аукцион: лот #[lot.uid] \"[lot.name]\" выставлен, соперники [json_encode(lot.rivals)]")
	addtimer(CALLBACK(src, PROC_REF(auction_step), lot), AUCTION_STEP)
	return lot

/// Шаг торгов: соперники перебивают, время вышло - итог.
/datum/controller/subsystem/market/proc/auction_step(datum/auction_lot/lot)
	if(lot != auction)
		return
	if(world.time >= lot.ends_at)
		finish_auction()
		return
	if(world.time >= lot.next_rival_at)
		rival_bid(lot)
		var/hurry = lot.ends_at - world.time < AUCTION_SNIPE_WINDOW
		lot.next_rival_at = world.time + (hurry ? rand(AUCTION_RIVAL_HURRY_MIN, AUCTION_RIVAL_HURRY_MAX) : rand(AUCTION_RIVAL_DELAY_MIN, AUCTION_RIVAL_DELAY_MAX))
	addtimer(CALLBACK(src, PROC_REF(auction_step), lot), AUCTION_STEP)

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

/// Возврат замороженной ставки станции, которую перебили.
/datum/controller/subsystem/market/proc/refund_auction_bid(datum/auction_lot/lot)
	var/datum/bank_account/account = lot.bidder_account
	if(!account)
		return
	lot.bidder_account = null
	SSeconomy.move(SSeconomy.market_account, account, lot.bid, ECON_AUCTION_REFUND, null, "Аукцион: ставку перебили, лот \"[lot.name]\"")
	account.bank_card_talk("Аукцион сектора: вашу ставку [lot.bid] кр. на \"[lot.name]\" перебили, деньги вернулись на счёт.", balloon = "ставку перебили")

/// Ставка станции: деньги замораживаются на счёте биржи до конца торгов или пока ставку не перебьют. Возвращает текст отказа или null.
/datum/controller/subsystem/market/proc/place_auction_bid(datum/bank_account/account, amount, mob/user, uid)
	var/datum/auction_lot/lot = auction
	if(!lot || (uid && uid != lot.uid))
		return "Этот лот уже не продаётся."
	if(!account)
		return "Нет банковского счёта."
	var/problem = SSeconomy.personal_account_problem(account, TRUE)
	if(problem)
		return problem
	if(!isnum(amount) || round(amount) != amount || amount < lot.min_bid())
		return "Ставка должна быть целой и не меньше [lot.min_bid()] кр."
	if(amount > AUCTION_BID_MAX)
		return "Ставка больше [AUCTION_BID_MAX] кр. не принимается."
	var/raising = lot.bidder_account == account
	var/needed = raising ? amount - lot.bid : amount
	if(!account.has_money(needed))
		return "На счёте не хватает: нужно [needed] кр."
	if(!SSeconomy.move(account, SSeconomy.market_account, needed, ECON_AUCTION_BID, user, "Аукцион: ставка на \"[lot.name]\""))
		return "Ставка не прошла."
	if(!raising)
		refund_auction_bid(lot)
	lot.bidder_account = account
	lot.note_bid(account.account_holder, amount)
	log_econ("Аукцион: [key_name(user)] ставит [amount] кр. на лот #[lot.uid] \"[lot.name]\"")
	return null

/// Итог торгов: победившая ставка станции сгорает, лот летит на склад снабжения; не долетел - деньги назад.
/datum/controller/subsystem/market/proc/finish_auction()
	var/datum/auction_lot/lot = auction
	if(!lot)
		return
	auction = null
	next_auction_at = world.time + rand(AUCTION_GAP_MIN, AUCTION_GAP_MAX)
	var/datum/bank_account/winner = lot.bidder_account
	if(winner)
		var/obj/item/prize = deliver_auction_lot(lot)
		if(prize)
			SSeconomy.move(SSeconomy.market_account, null, lot.bid, ECON_AUCTION, null, "Аукцион: лот \"[lot.name]\"")
			winner.bank_card_talk("Аукцион сектора: лот \"[lot.name]\" ваш за [lot.bid] кр. Он уже на складе снабжения.", TRUE, balloon = "лот ваш!")
			publish("Аукцион сектора: лот \"[lot.name]\" уходит на нашу станцию, покупатель - [winner.account_holder], [lot.bid] кр.")
		else
			refund_auction_bid(lot)
			publish("Аукцион сектора: лот \"[lot.name]\" не удалось доставить на станцию, ставка возвращена.")
	else if(lot.bidder_name)
		publish("Аукцион сектора: лот \"[lot.name]\" ушёл: [lot.bidder_name], [lot.bid] кр.")
	else
		publish("Аукцион сектора: лот \"[lot.name]\" снят с торгов без ставок.")
	auction_results.Insert(1, list(list(lot.name, lot.bidder_name, lot.bid, !!winner)))
	if(length(auction_results) > AUCTION_RESULTS_MAX)
		auction_results.Cut(AUCTION_RESULTS_MAX + 1)
	log_econ("Аукцион: лот #[lot.uid] \"[lot.name]\" закрыт, [lot.bidder_name || "без ставок"] [lot.bid] кр.")
	qdel(lot)

/// Лот с биркой победителя: на заданный турф или капсулой на склад снабжения. Купленное на аукционе NT выкупает как импорт.
/datum/controller/subsystem/market/proc/deliver_auction_lot(datum/auction_lot/lot)
	var/obj/item/prize = new lot.item_type(auction_drop_turf)
	prize.econ_imported = TRUE
	prize.name = "[prize.name] (лот аукциона)"
	if(auction_drop_turf)
		return prize
	if(send_supply_pod_to_area(prize, /area/cargo/storage) || send_supply_pod_to_area(prize, /area/cargo))
		return prize
	qdel(prize)
	return null

/// Аукцион для окон снабжения: лот, ставка, кто ведёт, сколько осталось; mine - ведёт ли счёт пользователя.
/proc/econ_auction_ui_data(datum/bank_account/account)
	var/datum/auction_lot/lot = SSmarket.auction
	var/list/results = list()
	for(var/list/result as anything in SSmarket.auction_results)
		results += list(list("name" = result[1], "winner" = result[2], "price" = result[3], "ours" = result[4]))
	. = list(
		"auction" = null,
		"auction_next" = lot ? 0 : max(0, CEILING((SSmarket.next_auction_at - world.time) / (1 SECONDS), 1)),
		"auction_results" = results,
		"my_balance" = account ? account.account_balance : null,
	)
	if(!lot)
		return
	var/list/history = list()
	for(var/list/entry as anything in lot.history)
		history += list(list("who" = entry[1], "amount" = entry[2]))
	.["auction"] = list(
		"uid" = lot.uid,
		"name" = lot.name,
		"desc" = initial(lot.item_type.desc),
		"value" = lot.value,
		"bid" = lot.bid,
		"bidder" = lot.bidder_name,
		"mine" = !!account && lot.bidder_account == account,
		"min_bid" = lot.min_bid(),
		"increment" = lot.increment(),
		"left" = lot.seconds_left(),
		"rivals" = length(lot.rivals),
		"history" = history,
	)

/datum/auction_lot/Destroy()
	bidder_account = null
	return ..()
