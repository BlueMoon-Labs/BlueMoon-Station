#define SLOT_TEST_BASE_SPINS 20000
#define SLOT_TEST_BASE_SEEDS 3
/// Допуск среднего по SLOT_TEST_BASE_SEEDS сидам замера на SLOT_TEST_BASE_SPINS вращениях; разброс между сидами около 5%
#define SLOT_TEST_BASE_TOLERANCE 0.15

/// Человек с ID-картой в руке и личным счётом с balance кредитов.
/proc/econ_test_card_holder(datum/unit_test/test, holder, balance)
	var/mob/living/carbon/human/person = test.allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = test.allocate(/obj/item/card/id)
	var/datum/bank_account/account = new(holder)
	test.allocated += account
	econ_test_set_balance(account, balance)
	card.registered_account = account
	person.put_in_active_hand(card)
	return person

/proc/econ_test_card_account(mob/living/carbon/human/person)
	var/obj/item/card/id/card = person.get_idcard(TRUE)
	return card?.registered_account

/datum/unit_test/economy_slots
	abstract_type = /datum/unit_test/economy_slots
	var/obj/machinery/computer/slot_machine/machine
	var/datum/tgui/window
	var/mob/living/carbon/human/player
	var/saved_cash
	var/datum/economy_ledger/saved_ledger
	/// Джекпот сектора и гарантия NT до теста
	var/list/saved_jackpot

/// Автомат и игрок убираются, наличные возвращаются, и только потом возвращается настоящий журнал: его счётчики тест не трогает.
/datum/unit_test/economy_slots/Destroy()
	if(saved_ledger)
		if(machine)
			machine.balance = 0
		QDEL_NULL(machine)
		var/datum/bank_account/account = player ? econ_test_card_account(player) : null
		if(account)
			qdel(account)
		econ_test_set_balance(SSeconomy.cash_account, saved_cash)
		SSmarket.slot_jackpot = saved_jackpot[1]
		SSmarket.slot_jackpot_carried = saved_jackpot[2]
		SSeconomy.settings.slot_jackpot_floor = saved_jackpot[3]
		var/datum/economy_ledger/test_ledger = SSeconomy.ledger
		SSeconomy.ledger = saved_ledger
		qdel(test_ledger)
	return ..()

/// Копия счётчиков отделов журнала, чтобы тест вернул их как было.
/proc/econ_test_copy_flows()
	. = list()
	for(var/id in SSeconomy.ledger.department_flows)
		var/list/flow = SSeconomy.ledger.department_flows[id]
		.[id] = flow.Copy()

/datum/unit_test/economy_slots/proc/setup_machine(balance = 1000)
	saved_cash = SSeconomy.cash_account.account_balance
	saved_ledger = SSeconomy.ledger
	SSeconomy.ledger = new /datum/economy_ledger
	saved_jackpot = list(SSmarket.slot_jackpot, SSmarket.slot_jackpot_carried, SSeconomy.settings.slot_jackpot_floor)
	SSmarket.slot_jackpot = 0
	SSmarket.slot_jackpot_carried = 0
	SSeconomy.settings.slot_jackpot_floor = 0
	machine = allocate(/obj/machinery/computer/slot_machine)
	machine.set_machine_stat(machine.machine_stat & ~NOPOWER)
	player = econ_test_card_holder(src, "econ_test_gambler", balance)
	window = allocate(/datum/tgui, player, machine, "SlotMachine")
	window.status = UI_INTERACTIVE

/datum/unit_test/economy_slots/proc/press(action, list/params = list())
	usr = player
	machine.ui_act(action, params, window)
	usr = null

/// Кредиты, которые лежат в автомате, и джекпот сектора из ставок смены.
/datum/unit_test/economy_slots/proc/machine_cash()
	return machine.balance + SSmarket.slot_jackpot + machine.prize_bank

/// Взнос с карты уходит в наличные автомата; настоящее вращение сжигает долю NT ровно по настройкам, а джекпот и банк получают свои доли; ничего не создаётся.
/datum/unit_test/economy_slots/real_spin/Run()
	setup_machine()
	var/datum/bank_account/account = econ_test_card_account(player)
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	var/cash_before = SSeconomy.cash_account.account_balance
	press("card_deposit", list("amount" = "300"))
	TEST_ASSERT_EQUAL(account.account_balance, 700, "С карты списан взнос")
	TEST_ASSERT_EQUAL(machine.balance, 300, "Взнос на балансе автомата")
	TEST_ASSERT_EQUAL(SSeconomy.cash_account.account_balance - cash_before, 300, "Взнос стал наличными")
	press("set_bet", list("amount" = "100"))
	var/datum/economy_settings/settings = SSeconomy.settings
	press("spin")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, 100 * settings.slot_house_edge / 100, "Доля NT со ставки сгорела")
	TEST_ASSERT(abs(SSmarket.slot_jackpot - 100 * settings.slot_jackpot_share / 100) < 0.01, "Доля джекпота: [SSmarket.slot_jackpot]")
	press("set_bet", list("amount" = "5"))
	TEST_ASSERT_EQUAL(machine.bet_amount, 100, "Ставку нельзя сменить, пока барабаны крутятся")
	var/waited = 0
	while(machine.working && waited++ < 100)
		sleep(1)
	TEST_ASSERT(!machine.working, "Вращение закончилось")
	TEST_ASSERT_EQUAL(machine.spin_bet, 100, "Выигрыш считался по поставленной ставке")
	machine.free_spins_remaining = 0
	machine.auto_spin = FALSE
	var/burned = SSeconomy.ledger.burned - burned_before
	TEST_ASSERT(abs(machine_cash() - (300 - burned)) < 0.01, "В автомате [machine_cash()] кр. при взносе 300 и сожжённых [burned]")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Слот-машина не создала денег")
	var/left = machine.balance
	press("refund")
	var/obj/item/holochip/chip = locate() in machine.loc
	TEST_ASSERT_NOTNULL(chip, "Остаток выдан голочипом")
	TEST_ASSERT_EQUAL(chip?.credits, left, "Голочип на весь остаток")
	qdel(chip)

/// Монеты автомат не берёт: монета не превращается в кредиты.
/datum/unit_test/economy_slots/no_coins/Run()
	setup_machine()
	var/obj/item/coin/silver/coin = allocate(/obj/item/coin/silver)
	player.put_in_inactive_hand(coin)
	machine.attackby(coin, player)
	TEST_ASSERT_EQUAL(machine.balance, 0, "Монета не стала балансом")
	TEST_ASSERT(!QDELETED(coin), "Монета осталась у игрока")

/// Долгая игра: сгорает ровно доля NT от платных ставок, выплаты не больше банка, банк и джекпот не уходят в минус, деньги не создаются.
/datum/unit_test/economy_slots/long_run/Run()
	setup_machine(5000)
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	press("card_deposit", list("amount" = "1000"))
	press("set_bet", list("amount" = "25"))
	var/paid_spins = 0
	var/spins = 0
	while((machine.balance >= machine.bet_amount || machine.free_spins_remaining > 0) && spins++ < 2000)
		if(machine.free_spins_remaining <= 0)
			paid_spins++
		machine.charge_spin(player)
		machine.reset_spin_state()
		for(var/list/reel as anything in machine.reels)
			for(var/row in 1 to 3)
				reel[row] = pick(machine.symbols)
		machine.give_prizes(player.real_name, player)
		TEST_ASSERT(machine.prize_bank >= 0 && SSmarket.slot_jackpot >= 0, "Банк [machine.prize_bank], джекпот [SSmarket.slot_jackpot] ушли в минус")
	var/burned = SSeconomy.ledger.burned - burned_before
	var/expected = paid_spins * 25 * SSeconomy.settings.slot_house_edge / 100
	TEST_ASSERT(abs(burned + machine.house_remainder - expected) < 0.01, "Сгорело [burned] при доле NT [expected] с [paid_spins] ставок")
	TEST_ASSERT(abs(machine_cash() - (1000 - burned)) < 0.01, "Деньги автомата не сходятся: [machine_cash()] при взносе 1000 и сожжённых [burned]")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Слот-машина не создала денег")

/// Джекпот сектора платит накопленное, а не число из воздуха; выигрыш больше банка урезается до банка.
/datum/unit_test/economy_slots/jackpot_and_cap/Run()
	setup_machine()
	SSmarket.slot_jackpot = 40
	machine.prize_bank = 7
	for(var/list/reel as anything in machine.reels)
		reel[1] = "cherry"
		reel[2] = "seven"
		reel[3] = "cherry"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT_EQUAL(machine.balance, 40, "Джекпот выплатил накопленное")
	TEST_ASSERT_EQUAL(SSmarket.slot_jackpot, 0, "Джекпот обнулился")
	machine.balance = 0
	for(var/list/reel as anything in machine.reels)
		reel[1] = "star"
		reel[2] = "cherry"
		reel[3] = "star"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT_EQUAL(machine.balance, 7, "Выигрыш урезан до банка")
	TEST_ASSERT_EQUAL(machine.prize_bank, 0, "Банк выплачен целиком, не в минус")
	machine.balance = 0
	SSmarket.slot_jackpot = 25
	for(var/col in 1 to 5)
		var/list/reel = machine.reels[col]
		reel[2] = col == 3 ? "cherry" : "seven"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT_EQUAL(machine.balance, 25, "Четыре семёрки из пяти - джекпот")

/// Джекпот один на все автоматы: с двумя джокерами в четвёрке не срывается, ставки разных автоматов копятся вместе; гарантия NT доплачивается выпуском.
/datum/unit_test/economy_slots/sector_jackpot/Run()
	setup_machine()
	var/obj/machinery/computer/slot_machine/second = allocate(/obj/machinery/computer/slot_machine)
	machine.take_bet(100, player)
	second.take_bet(100, player)
	TEST_ASSERT(abs(SSmarket.slot_jackpot - 2 * 100 * SSeconomy.settings.slot_jackpot_share / 100) < 0.01, "Ставки двух автоматов в одном джекпоте: [SSmarket.slot_jackpot]")
	TEST_ASSERT_EQUAL(machine.ui_data(player)["money"], second.ui_data(player)["money"], "Автоматы показывают один джекпот")
	var/pooled = SSmarket.slot_jackpot
	machine.reset_spin_state()
	for(var/col in 1 to 5)
		var/list/reel = machine.reels[col]
		reel[1] = "cherry"
		reel[2] = list("seven", "wild", "wild", "seven", "cherry")[col]
		reel[3] = "banana"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT(machine.result_type != "jackpot", "Два джокера в четвёрке сорвали джекпот")
	TEST_ASSERT_EQUAL(SSmarket.slot_jackpot, pooled, "Джекпот не тронут")

	SSmarket.slot_jackpot = 40
	SSmarket.slot_jackpot_carried = 100
	SSeconomy.settings.slot_jackpot_floor = 500
	TEST_ASSERT_EQUAL(machine.ui_data(player)["money"], 500, "Окно показывает гарантию NT")
	var/minted_before = SSeconomy.ledger.minted
	machine.balance = 0
	machine.reset_spin_state()
	for(var/col in 1 to 5)
		var/list/reel = machine.reels[col]
		reel[2] = col == 3 ? "wild" : "seven"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT_EQUAL(machine.balance, 500, "Выплачена гарантия NT, а не 140 кр.")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted - minted_before, 460, "NT выпустил всё, кроме ставок этой смены")
	TEST_ASSERT_EQUAL(SSmarket.slot_jackpot_total(), 0, "Джекпот сектора обнулился")

/// Ставка меняется только на значения из списка; бесплатные вращения играются по ставке, на которой выиграны.
/datum/unit_test/economy_slots/bets/Run()
	setup_machine()
	press("set_bet", list("amount" = "7.3"))
	TEST_ASSERT_EQUAL(machine.bet_amount, 5, "Дробная ставка отвергнута")
	press("set_bet", list("amount" = "1000"))
	TEST_ASSERT_EQUAL(machine.bet_amount, 5, "Ставка вне списка отвергнута")
	machine.balance = 100
	machine.prize_bank = 0
	machine.charge_spin(player)
	machine.reset_spin_state()
	for(var/list/reel as anything in machine.reels)
		reel[1] = "star"
		reel[2] = "cherry"
		reel[3] = "star"
	for(var/col in 4 to 5)
		var/list/reel = machine.reels[col]
		reel[2] = "grape"
	machine.give_prizes(player.real_name, player)
	TEST_ASSERT(machine.free_spins_remaining > 0, "Три в линию дали бесплатные вращения")
	press("set_bet", list("amount" = "100"))
	machine.charge_spin(player)
	machine.reset_spin_state()
	TEST_ASSERT_EQUAL(machine.spin_bet, 5, "Бесплатное вращение играется по ставке 5, на которой выиграно")
	TEST_ASSERT_EQUAL(machine.balance, 95, "Бесплатное вращение ничего не списало")

/// Удвоение и ЭМИ только перекладывают наличные внутри автомата и выдают голочип из банка: деньги не создаются.
/datum/unit_test/economy_slots/gamble_emp/Run()
	setup_machine()
	machine.balance = 100
	machine.prize_bank = 300
	var/minted_before = SSeconomy.ledger.minted
	for(var/attempt in 1 to 20)
		machine.gamble_available = TRUE
		machine.gamble_amount = 10
		press("gamble", list("choice" = "red"))
		TEST_ASSERT_EQUAL(machine.balance + machine.prize_bank, 400, "Удвоение сохраняет наличные автомата")
	machine.balance = 0
	var/before = machine.prize_bank + SSmarket.slot_jackpot
	machine.emp_act(1)
	var/obj/item/holochip/chip = locate() in machine.loc
	var/spilled = chip ? chip.credits : 0
	if(chip)
		qdel(chip)
	TEST_ASSERT_EQUAL(machine.prize_bank + SSmarket.slot_jackpot + spilled, before, "ЭМИ выдаёт голочип только из банка")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Ничего не создано")

/// Взнос с карты отказывает выше лимита, с замороженного счёта и во время техобслуживания банка.
/datum/unit_test/economy_slots/deposit_refusals/Run()
	setup_machine()
	var/datum/bank_account/account = econ_test_card_account(player)
	press("card_deposit", list("amount" = "1001"))
	TEST_ASSERT_EQUAL(machine.balance, 0, "Выше лимита отказ")
	account.state = ACCOUNT_FROZEN
	press("card_deposit", list("amount" = "100"))
	account.state = ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(machine.balance, 0, "С замороженного счёта отказ")
	account.withdrawDelay = world.time + 1 MINUTES
	press("card_deposit", list("amount" = "100"))
	account.withdrawDelay = 0
	TEST_ASSERT_EQUAL(machine.balance, 0, "Во время техобслуживания банка отказ")
	TEST_ASSERT_EQUAL(account.account_balance, 1000, "Ничего не списано")

/// Новый автомат показывает честную статистику: ни вращений, ни джекпотов до первой игры.
/datum/unit_test/economy_slots/honest_stats/Run()
	setup_machine()
	var/list/data = machine.ui_data(player)
	TEST_ASSERT_EQUAL(data["plays"], 0, "Новый автомат показывает выдуманные вращения")
	TEST_ASSERT_EQUAL(data["jackpots"], 0, "Новый автомат показывает выдуманные джекпоты")

/// Возврат таблицы выигрышей при множителе 1 на 1-3 линиях сходится с константами slot_paytable_base_return: состояние сбрасывается каждое вращение, как в spin(); выигрыши бесплатных вращений входят, их ставки и джекпот - нет.
/datum/unit_test/economy_slots/base_return/Run()
	setup_machine()
	var/cash_before = SSeconomy.cash_account.account_balance
	var/list/report = list()
	for(var/lines in 1 to 3)
		var/bet = list(5, 10, 25)[lines]
		var/total = 0
		for(var/seed in 1 to SLOT_TEST_BASE_SEEDS)
			rand_seed(seed * 101 + lines)
			total += measure_return(bet)
		var/measured = total / SLOT_TEST_BASE_SEEDS
		var/expected = GLOB.slot_paytable_base_return[lines]
		report += "[lines] линий: [round(measured, 0.001)] (константа [expected])"
		if(abs(measured - expected) / expected >= SLOT_TEST_BASE_TOLERANCE)
			econ_test_set_balance(SSeconomy.cash_account, cash_before)
		TEST_ASSERT(abs(measured - expected) / expected < SLOT_TEST_BASE_TOLERANCE, "Возврат на [lines] линиях [round(measured, 0.001)], константа [expected]")
	log_test("Возврат таблицы выигрышей: [jointext(report, ", ")]")
	econ_test_set_balance(SSeconomy.cash_account, cash_before)

/// Возврат при множителе 1 за SLOT_TEST_BASE_SPINS вращений по ставке bet, как в spin(): состояние сбрасывается каждое вращение, джекпот не платится.
/datum/unit_test/economy_slots/base_return/proc/measure_return(bet)
	machine.bet_amount = bet
	machine.balance = 0
	machine.prize_bank = 1000000
	machine.free_spins_remaining = 0
	var/paid = 0
	var/won = 0
	for(var/spin in 1 to SLOT_TEST_BASE_SPINS)
		if(machine.free_spins_remaining <= 0)
			paid += bet
			machine.balance += bet
		machine.charge_spin(player)
		machine.reset_spin_state()
		for(var/list/reel as anything in machine.reels)
			for(var/row in 1 to 3)
				reel[row] = pick(machine.symbols)
		SSmarket.slot_jackpot = 0
		var/before = machine.balance
		machine.give_prizes(player.real_name, player)
		won += machine.balance - before
		machine.gamble_available = FALSE
	return won / paid / machine.prize_scale(bet)

/// Разбор автомата сжигает его банк, общий джекпот сектора остаётся другим автоматам; баланс игрока выдаётся голочипом.
/datum/unit_test/economy_slots/destroy_burns_pools/Run()
	setup_machine()
	var/turf/spot = machine.loc
	SSmarket.slot_jackpot = 30
	machine.prize_bank = 70
	machine.balance = 20
	var/burned_before = SSeconomy.ledger.burned
	qdel(machine)
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, 70, "Сгорел только банк автомата")
	TEST_ASSERT_EQUAL(SSmarket.slot_jackpot, 30, "Джекпот сектора остался")
	var/obj/item/holochip/chip = locate() in spot
	TEST_ASSERT_EQUAL(chip?.credits, 20, "Баланс игрока выдан")
	qdel(chip)

/// Премиум-позиция автомата - почти вся сток: отделу-владельцу только остаток доли; обычная позиция по-прежнему делится по оптовой доле.
/datum/unit_test/economy_vending/premium_sink/Run()
	setup_machine()
	var/mob/living/carbon/human/buyer = econ_test_card_holder(src, "econ_test_premium", 5000)
	var/datum/bank_account/account = econ_test_card_account(buyer)
	TEST_ASSERT(length(machine.coin_records), "У снек-автомата есть премиум")
	record = machine.coin_records[1]
	record.amount = max(record.amount, 1)
	var/price = record.custom_premium_price || machine.extra_price
	var/minted_before = SSeconomy.ledger.minted
	buy(buyer)
	var/sink = round(price * SSeconomy.settings.vend_premium_sink_share / 100)
	TEST_ASSERT_EQUAL(5000 - account.account_balance, price, "Списана премиальная цена")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, sink, "Сгорела доля NT премиума")
	TEST_ASSERT_EQUAL(owner.account_balance - owner_before, price - sink, "Отделу - остаток")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Покупка ничего не создала")

/// Личный каталог: заказ за свой счёт с консоли снабжения идёт по цене партнёра без наценки, вся сумма сгорает, снабжению ничего; обычный частный заказ - с наценкой снабжению.
/datum/unit_test/economy_partners/personal_catalog/Run()
	var/datum/supply_pack/pet = SSshuttle.supply_packs[/datum/supply_pack/critter/corgi]
	var/datum/supply_pack/other = SSshuttle.supply_packs[/datum/supply_pack/critter/cow]
	TEST_ASSERT(econ_personal_catalog_pack(pet), "Корги в личном каталоге")
	TEST_ASSERT(!econ_personal_catalog_pack(other), "Корова не в личном каталоге")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/buyer = econ_test_card_holder(src, "econ_test_pet_owner", 50000)
	var/datum/bank_account/account = econ_test_card_account(buyer)
	var/datum/tgui/window = allocate(/datum/tgui, buyer, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = buyer
	console.ui_act("toggleprivate", list(), window)
	console.ui_act("add", list("id" = "[pet.type]"), window)
	console.ui_act("add", list("id" = "[other.type]"), window)
	usr = null
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 2, "Оба частных заказа в корзине")
	var/pet_price = round(econ_pack_price(pet, account))
	var/other_price = round(econ_pack_price(other, account))
	var/other_markup = round(other_price * ECON_PRIVATE_ORDER_MARKUP) - other_price
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	var/catalog_before = SSeconomy.ledger.by_reason[ECON_PERSONAL_CATALOG]
	var/list/before = shuttle_movables()
	SSshuttle.supply.buy()
	TEST_ASSERT_EQUAL(50000 - account.account_balance, pet_price + other_price + other_markup, "Списано: корги без наценки, корова с наценкой")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.by_reason[ECON_PERSONAL_CATALOG] - catalog_before, pet_price, "Личный каталог учтён своей причиной")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, pet_price + other_price, "Сгорели цены паков, наценка - нет")
	TEST_ASSERT_EQUAL(cargo.account_balance - saved_cargo, other_markup, "Снабжению только наценка обычного частного заказа")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Заказ ничего не создал")
	for(var/pass in 1 to 3)
		for(var/atom/movable/thing as anything in shuttle_movables() - before)
			qdel(thing)
	for(var/obj/item/paper/paper in console.loc)
		qdel(paper)

/datum/unit_test/economy_partners/proc/shuttle_movables()
	. = list()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/turf/floor in shuttle_area)
			for(var/atom/movable/thing in floor)
				. += thing

/// В личном каталоге нет оружия, лечения и снаряжения отделов; группа видна в окне снабжения с пометкой.
/datum/unit_test/economy_personal_catalog_contents/Run()
	var/static/list/forbidden_groups = list("Armory", "Security", "Medical", "Emergency", "Engineering", "Engine Construction", "Science", "Canisters & Materials")
	for(var/pack_type in GLOB.econ_personal_catalog)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		TEST_ASSERT_NOTNULL(pack, "Пак [pack_type] есть в снабжении")
		if(!pack)
			continue
		TEST_ASSERT(!(pack.group in forbidden_groups), "[pack_type] из группы [pack.group]")
		TEST_ASSERT(pack.can_private_buy && !pack.hidden && !pack.contraband && !pack.access && !pack.DropPodOnly, "[pack_type] нельзя купить лично")
		for(var/content_type in pack.contains)
			TEST_ASSERT(!ispath(content_type, /obj/item/gun) && !ispath(content_type, /obj/item/melee) && !ispath(content_type, /obj/item/reagent_containers/hypospray) && !ispath(content_type, /obj/item/storage/firstaid), "[pack_type] везёт [content_type]")
	var/list/supplies = econ_cargo_supplies(FALSE, FALSE, FALSE)
	var/list/group = supplies[ECON_PERSONAL_CATALOG_GROUP]
	TEST_ASSERT(length(group?["packs"]), "Группа личного каталога в окне снабжения")

/datum/unit_test/economy_ui_wallet/lottery
	var/datum/econ_lottery/saved_lottery

/datum/unit_test/economy_ui_wallet/lottery/New()
	. = ..()
	saved_lottery = SSeconomy.lottery
	SSeconomy.lottery = null

/datum/unit_test/economy_ui_wallet/lottery/Destroy()
	QDEL_NULL(SSeconomy.lottery)
	SSeconomy.lottery = saved_lottery
	return ..()

/// Событие лотереи открывает продажу и пишет в "Сводку сектора"; билеты из "Кошелька" уходят в банк лотереи, лимит на счёт держится, розыгрыш сжигает долю NT, остальное - победителю, ничего не создаётся.
/datum/unit_test/economy_ui_wallet/lottery/Run()
	var/datum/round_event/money_lottery/event = new(FALSE)
	event.start()
	event.kill()
	qdel(event)
	var/datum/econ_lottery/lottery = SSeconomy.lottery
	TEST_ASSERT_NOTNULL(lottery, "Событие открыло лотерею")
	if(!lottery)
		return
	var/datum/news/feed_channel/channel = SSmarket.news_channel()
	var/datum/news/feed_message/opening = channel.messages[length(channel.messages)]
	TEST_ASSERT(findtext(opening.returnBody(-1), "лотереи"), "Сводка сектора объявила лотерею")
	var/datum/economy_settings/settings = SSeconomy.settings
	var/mob/living/carbon/human/first = make_owner("Econ Lottery First", 2000)
	var/mob/living/carbon/human/second = make_owner("Econ Lottery Second", 2000)
	var/datum/bank_account/first_account = account_of(first)
	var/datum/bank_account/second_account = account_of(second)
	var/datum/computer_file/program/wallet/first_wallet = wallet_of(first)
	var/minted_before = SSeconomy.ledger.minted
	var/burned_before = SSeconomy.ledger.burned
	press(first, "lottery_buy", list("count" = "3"))
	press(second, "lottery_buy", list("count" = 1))
	TEST_ASSERT_EQUAL(first_account.account_balance, 2000 - 3 * settings.lottery_ticket_price, "Первый купил 3 билета")
	TEST_ASSERT_EQUAL(second_account.account_balance, 2000 - settings.lottery_ticket_price, "Второй купил билет")
	var/refused = press(first, "lottery_buy", list("count" = "[settings.lottery_tickets_per_account]"))
	TEST_ASSERT(findtext(refused, "Не больше"), "Сверх лимита отказ: [refused]")
	TEST_ASSERT_EQUAL(first_account.account_balance, 2000 - 3 * settings.lottery_ticket_price, "Отказ ничего не списал")
	var/list/data = first_wallet.wallet_data(first)
	TEST_ASSERT_EQUAL(data["lottery"]["mine"], 3, "Окно показывает свои билеты")
	var/sales = 4 * settings.lottery_ticket_price
	var/cut = round(sales * settings.lottery_house_share / 100)
	lottery.draw()
	TEST_ASSERT_NULL(SSeconomy.lottery, "Лотерея закрылась")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, cut, "NT забрала свою долю")
	TEST_ASSERT_EQUAL(first_account.account_balance + second_account.account_balance, 4000 - cut, "Остальное ушло победителю")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.minted, minted_before, "Лотерея ничего не создала")
	var/datum/news/feed_message/result = channel.messages[length(channel.messages)]
	TEST_ASSERT(findtext(result.returnBody(-1), "получает"), "Сводка сектора назвала победителя")

/// Грант покрывает оклады сотрудников на смене без надбавок; базовая часть - только отделу с каталогом, у гражданских её нет.
/datum/unit_test/economy_department_grant_rule/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/civilian = SSeconomy.get_department(ACCOUNT_CIV)
	var/datum/economy_department/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/list/saved_accounts = SSeconomy.bank_accounts
	SSeconomy.bank_accounts = list()
	var/datum/bank_account/assistant = new("econ_test_assistant")
	assistant.department_id = ACCOUNT_CIV
	assistant.pay_grade = PAY_GRADE_ASSISTANT
	assistant.wage_bonus = settings.max_wage_bonus
	var/datum/bank_account/cook = new("econ_test_cook")
	cook.department_id = ACCOUNT_SRV
	cook.pay_grade = PAY_GRADE_EASY
	var/civilian_grant = civilian.grant_amount()
	var/service_grant = service.grant_amount()
	var/civilian_before = civilian.account.account_balance
	econ_test_set_balance(civilian.account, 0)
	civilian.grant()
	var/civilian_paid = civilian.account.account_balance
	var/level = civilian.grant_level()
	var/expected_level = civilian.budget_threshold() + civilian.owed_to_staff()
	econ_test_set_balance(civilian.account, level - 7)
	civilian.grant()
	var/near_level_balance = civilian.account.account_balance
	econ_test_set_balance(civilian.account, level + 500)
	civilian.grant()
	var/above_level_balance = civilian.account.account_balance
	econ_test_set_balance(civilian.account, civilian_before)
	qdel(assistant)
	qdel(cook)
	SSeconomy.bank_accounts = saved_accounts
	TEST_ASSERT_EQUAL(civilian_grant, round(settings.wages[PAY_GRADE_ASSISTANT] * settings.grant_payroll_share / 100 / settings.payroll_interval_ticks), "Гражданским - доля оклада без надбавки и без базы")
	TEST_ASSERT_EQUAL(service_grant, round(settings.wages[PAY_GRADE_EASY] * settings.grant_payroll_share / 100 / settings.payroll_interval_ticks) + settings.grant_base, "Сервису - доля оклада и база на закупки")
	TEST_ASSERT_EQUAL(civilian_paid, civilian_grant, "Пустому бюджету grant() платит grant_amount()")
	TEST_ASSERT_EQUAL(level, expected_level, "Грант доливает до порога и следующей зарплаты")
	TEST_ASSERT_EQUAL(near_level_balance, level, "У самого уровня грант доливает только недостающее")
	TEST_ASSERT_EQUAL(above_level_balance, level + 500, "Выше уровня грант не идёт: его забрал бы возврат излишка")

/// Излишек бюджета сверх порога частью возвращается NT на тике экономики; деньги ниже порога, долг и следующая зарплата сотрудникам не трогаются.
/datum/unit_test/economy_budget_cap
	var/list/saved_accounts
	var/list/saved_balances
	var/list/saved_shields
	var/list/saved_owed
	var/list/saved_contracts
	var/list/saved_snapshots
	var/list/saved_flows
	var/saved_fire_count
	var/saved_state
	var/saved_contracts_started

/datum/unit_test/economy_budget_cap/New()
	. = ..()
	saved_accounts = SSeconomy.bank_accounts
	SSeconomy.bank_accounts = list()
	saved_balances = list()
	saved_shields = list()
	saved_owed = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
		saved_shields[id] = department.shield
		saved_owed[id] = department.owed
		department.shield = list()
		department.owed = 0
		department.clear_saving_goal(ordered = TRUE)
		department.saving_goal_cooldown_until = 0
	saved_contracts = econ_test_stash_contracts()
	saved_snapshots = SSeconomy.ledger.snapshots.Copy()
	saved_flows = econ_test_copy_flows()
	saved_fire_count = SSeconomy.fire_count
	saved_state = SSeconomy.economy_state
	saved_contracts_started = SSeconomy.contracts_started

/datum/unit_test/economy_budget_cap/Destroy()
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts.Copy())
		qdel(account)
	SSeconomy.bank_accounts = saved_accounts
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
		department.shield = saved_shields[id]
		department.owed = saved_owed[id]
		department.clear_saving_goal(ordered = TRUE)
		department.saving_goal_cooldown_until = 0
	econ_test_restore_contracts(saved_contracts)
	SSeconomy.ledger.snapshots = saved_snapshots
	SSeconomy.ledger.department_flows = saved_flows
	SSeconomy.fire_count = saved_fire_count
	SSeconomy.economy_state = saved_state
	SSeconomy.contracts_started = saved_contracts_started
	return ..()

/datum/unit_test/economy_budget_cap/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	for(var/i in 1 to 4)
		var/datum/bank_account/doctor = new("econ_test_doctor_[i]")
		doctor.department_id = ACCOUNT_MED
		doctor.pay_grade = PAY_GRADE_HARD
	var/threshold = medical.budget_threshold()
	TEST_ASSERT_EQUAL(threshold, max(4 * settings.wages[PAY_GRADE_HARD] * settings.budget_cap_paydays, settings.budget_cap_floor, medical.start_budget()), "Порог - оклады на смене за budget_cap_paydays выплат, не ниже budget_cap_floor")
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	TEST_ASSERT(cargo.budget_threshold() >= settings.budget_cap_floor_cargo, "Порог снабжения ниже budget_cap_floor_cargo: [cargo.budget_threshold()]")
	TEST_ASSERT(settings.budget_cap_floor_cargo > settings.budget_cap_floor, "Минимум порога снабжения не выше общего")
	econ_test_set_balance(medical.account, threshold)
	var/burned_before = SSeconomy.ledger.by_reason[ECON_BUDGET_RETURN]
	medical.return_excess()
	TEST_ASSERT_EQUAL(medical.account.account_balance, threshold, "Деньги до порога не тронуты")
	econ_test_set_balance(medical.account, threshold + 10000)
	var/datum/bank_account/owed_doctor = SSeconomy.bank_accounts[1]
	owed_doctor.owed_wages = 2000
	var/excess = 10000 - 2000 - 4 * settings.wages[PAY_GRADE_HARD]
	var/expected = round(excess * settings.budget_cap_return_share / 100)
	TEST_ASSERT_EQUAL(medical.budget_return_due(), expected, "Окно показывает возврат с излишка без долга и следующей зарплаты сотрудникам")
	medical.return_excess()
	TEST_ASSERT_EQUAL(threshold + 10000 - medical.account.account_balance, expected, "Вернулась доля излишка")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.by_reason[ECON_BUDGET_RETURN] - burned_before, expected, "Возврат сгорел")
	owed_doctor.owed_wages = 0
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/treasury_threshold = settings.treasury_start_budget + settings.treasury_request_max * (length(SSeconomy.departments) - 1)
	TEST_ASSERT_EQUAL(command.budget_threshold(), treasury_threshold, "Порог казны - стартовая и по запросу на отдел")
	econ_test_set_balance(medical.account, threshold)
	econ_test_set_balance(command.account, treasury_threshold + 20000)
	SSeconomy.treasury_transfer(medical, 15000)
	TEST_ASSERT_EQUAL(medical.shielded(), 15000, "Перевод из казны под защитой")
	TEST_ASSERT_EQUAL(medical.budget_return_due(), 0, "Защищённый перевод не излишек")
	medical.account.debit(5000, ECON_ADMIN)
	TEST_ASSERT_EQUAL(medical.shielded(), 10000, "Расход тратит защищённые деньги первыми")
	var/real_balance = medical.account.account_balance
	medical.account.account_balance = 4000
	var/capped = medical.shielded()
	medical.account.account_balance = real_balance
	TEST_ASSERT_EQUAL(capped, 4000, "Защита не больше баланса")
	SSeconomy.fire_count += settings.budget_cap_grace_ticks
	TEST_ASSERT_EQUAL(medical.shielded(), 0, "Защита кончилась через budget_cap_grace_ticks тиков")
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	science.shield = list()
	econ_test_set_balance(medical.account, 20000)
	SSeconomy.department_transfer(medical, science, 1000)
	TEST_ASSERT_EQUAL(science.shielded(), 0, "Перевод между отделами не защищён")
	TEST_ASSERT(!(ECON_STOCK_SELL in GLOB.econ_cap_shielded_reasons), "Продажа акций не защищена")
	var/datum/supply_pack/cheap_pack
	for(var/datum/supply_pack/pack as anything in medical.catalog())
		if(!econ_pack_unavailable(pack) && (!cheap_pack || econ_pack_price(pack) < econ_pack_price(cheap_pack)))
			cheap_pack = pack
	var/cheap_price = round(econ_pack_price(cheap_pack))
	medical.shield = list()
	var/list/orders_before_cancel = SSshuttle.shoppinglist.Copy()
	TEST_ASSERT(medical.order_pack(cheap_pack, null, "Тест", TRUE), "Заказ без защиты")
	var/datum/supply_order/plain_order = (SSshuttle.shoppinglist - orders_before_cancel)[1]
	econ_cancel_order(plain_order)
	SSshuttle.shoppinglist -= plain_order
	qdel(plain_order)
	TEST_ASSERT_EQUAL(medical.shielded(), 0, "Возврат заказа из незащищённых денег не защищён")
	SSeconomy.treasury_transfer(medical, cheap_price)
	TEST_ASSERT(medical.order_pack(cheap_pack, null, "Тест", TRUE), "Заказ из защищённых денег")
	TEST_ASSERT_EQUAL(medical.shielded(), 0, "Заказ потратил защиту")
	var/datum/supply_order/shielded_order = (SSshuttle.shoppinglist - orders_before_cancel)[1]
	econ_cancel_order(shielded_order)
	SSshuttle.shoppinglist -= shielded_order
	qdel(shielded_order)
	TEST_ASSERT_EQUAL(medical.shielded(), cheap_price, "Возврат заказа из защищённых денег снова защищён")
	medical.shield = list()
	var/datum/supply_pack/goal_pack
	for(var/datum/supply_pack/pack as anything in medical.catalog())
		if(!econ_pack_unavailable(pack) && (!goal_pack || econ_pack_price(pack) > econ_pack_price(goal_pack)))
			goal_pack = pack
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/due_before_goal = medical.budget_return_due()
	TEST_ASSERT(medical.set_saving_goal(goal_pack, head), "Глава назначил цель накопления")
	var/goal_price = round(econ_pack_price(goal_pack))
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), goal_price, "Цель - цена пака")
	TEST_ASSERT(medical.budget_return_due() < due_before_goal, "С целью возврат меньше")
	medical.saving_goal_until = world.time
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), 0, "Цель истекла")
	TEST_ASSERT(!medical.set_saving_goal(goal_pack, head), "После истечения новая цель ждёт перерыва")
	TEST_ASSERT_EQUAL(medical.saving_goal_cooldown_minutes(), settings.saving_goal_cooldown_minutes, "Перерыв равен настройке")
	medical.saving_goal_cooldown_until = 0
	medical.set_saving_goal(goal_pack, head)
	econ_test_set_balance(medical.account, goal_price + 1000)
	var/list/orders_before = SSshuttle.shoppinglist.Copy()
	TEST_ASSERT(medical.order_pack(goal_pack, head, "Тест"), "Пак-цель заказан")
	for(var/order in SSshuttle.shoppinglist - orders_before)
		SSshuttle.shoppinglist -= order
		qdel(order)
	TEST_ASSERT_NULL(medical.saving_goal, "Заказ пака снял цель")
	var/fired_before = SSeconomy.ledger.by_reason[ECON_BUDGET_RETURN]
	SSeconomy.fire()
	TEST_ASSERT(SSeconomy.ledger.by_reason[ECON_BUDGET_RETURN] > fired_before, "Тик экономики возвращает излишек казны")


/// Билеты не продаются после закрытия продажи; розыгрыш идёт по таймеру лотереи и пропускает владельцев вне игры; снятая лотерея возвращает билеты.
/datum/unit_test/economy_ui_wallet/lottery/edges

/datum/unit_test/economy_ui_wallet/lottery/edges/Run()
	var/mob/living/carbon/human/active = make_owner("Econ Lottery Active", 2000)
	var/mob/living/carbon/human/away = make_owner("Econ Lottery Away", 2000)
	var/datum/bank_account/active_account = account_of(active)
	var/datum/bank_account/away_account = account_of(away)
	var/datum/econ_lottery/lottery = SSeconomy.start_lottery()
	press(active, "lottery_buy", list("count" = "1"))
	press(away, "lottery_buy", list("count" = "10"))
	away_account.state = ACCOUNT_DORMANT
	var/datum/timedevent/timer = SStimer.timer_id_dict[lottery.draw_timer]
	TEST_ASSERT_NOTNULL(timer, "Розыгрыш назначен таймером")
	lottery.ends_at = world.time
	var/refused = press(active, "lottery_buy", list("count" = "1"))
	TEST_ASSERT(findtext(refused, "закрыта"), "После закрытия продажи отказ: [refused]")
	timer.callBack.Invoke()
	TEST_ASSERT_NULL(SSeconomy.lottery, "Таймер разыграл лотерею")
	TEST_ASSERT(active_account.account_balance > 2000 - SSeconomy.settings.lottery_ticket_price, "Выиграл владелец в игре")
	away_account.state = ACCOUNT_ACTIVE
	var/datum/econ_lottery/cancelled = SSeconomy.start_lottery()
	press(active, "lottery_buy", list("count" = "2"))
	var/before_cancel = active_account.account_balance
	qdel(cancelled)
	TEST_ASSERT_EQUAL(active_account.account_balance - before_cancel, 2 * SSeconomy.settings.lottery_ticket_price, "Снятая лотерея вернула билеты")

#undef SLOT_TEST_BASE_SPINS
#undef SLOT_TEST_BASE_SEEDS
#undef SLOT_TEST_BASE_TOLERANCE

/datum/unit_test/economy_budget_cap/proc/staff_medical()
	for(var/i in 1 to 4)
		var/datum/bank_account/doctor = new("econ_test_doctor_[i]")
		doctor.department_id = ACCOUNT_MED
		doctor.pay_grade = PAY_GRADE_HARD
	return SSeconomy.get_department(ACCOUNT_MED)

/datum/unit_test/economy_budget_cap/proc/cheapest_pack(datum/economy_department/department)
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(!econ_pack_unavailable(pack) && (!. || econ_pack_price(pack) < econ_pack_price(.)))
			. = pack

/datum/unit_test/economy_budget_cap/proc/order_and_cancel(datum/economy_department/department, datum/supply_pack/pack)
	var/list/before = SSshuttle.shoppinglist.Copy()
	department.order_pack(pack, null, "Тест", TRUE)
	var/list/placed = SSshuttle.shoppinglist - before
	var/datum/supply_order/order = placed[1]
	econ_cancel_order(order)
	SSshuttle.shoppinglist -= order
	qdel(order)

/// Отмена заказа из защищённых денег возвращает защиту с прежним сроком, а не с новым.
/datum/unit_test/economy_budget_cap/cancel_keeps_expiry/Run()
	var/datum/economy_department/medical = staff_medical()
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(SSeconomy.treasury(), price * 10)
	econ_test_set_balance(medical.account, 0)
	SSeconomy.treasury_transfer(medical, price)
	SSeconomy.fire_count += SSeconomy.settings.budget_cap_grace_ticks - 1
	order_and_cancel(medical, pack)
	TEST_ASSERT_EQUAL(medical.shielded(), price, "Отмена вернула защиту")
	SSeconomy.fire_count += 1
	TEST_ASSERT_EQUAL(medical.shielded(), 0, "Защита истекла в прежний срок")

/// Возврат не по отмене заказа (дело аудита) не защищён.
/datum/unit_test/economy_budget_cap/refund_not_shielded/Run()
	var/datum/economy_department/medical = staff_medical()
	var/datum/bank_account/payer = new("econ_test_refund_payer")
	allocated += payer
	econ_test_set_balance(payer, 500)
	SSeconomy.move(payer, medical.account, 500, ECON_REFUND)
	TEST_ASSERT_EQUAL(medical.shielded(), 0, "Возврат по делу не защищён")

/// Пока цель накопления стоит, другую не поставить: сначала снять, тогда действует перерыв.
/datum/unit_test/economy_budget_cap/goal_not_rearmed/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Первая цель поставлена")
	var/until = medical.saving_goal_until
	TEST_ASSERT(!medical.set_saving_goal(pack, head), "Цель не перезаводится, пока стоит")
	TEST_ASSERT_EQUAL(medical.saving_goal_until, until, "Срок цели не продлился")
	medical.clear_saving_goal(head)
	TEST_ASSERT(!medical.set_saving_goal(pack, head), "После снятия - перерыв")

/// Отмена заказа, закрывшего цель накопления, возвращает цель с прежним сроком, а занятое место - перерыв: перезавести цель отменой нельзя.
/datum/unit_test/economy_budget_cap/goal_cancel_restores/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	econ_test_set_balance(medical.account, round(econ_pack_price(pack)) * 4)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	var/until = world.time + 5 MINUTES
	medical.saving_goal_until = until
	order_and_cancel(medical, pack)
	TEST_ASSERT(medical.saving_goal == pack, "Отмена заказа не вернула цель")
	TEST_ASSERT_EQUAL(medical.saving_goal_until, until, "Цель вернулась с новым сроком")
	var/list/before = SSshuttle.shoppinglist.Copy()
	medical.order_pack(pack, null, "Тест", TRUE)
	var/datum/supply_order/order = (SSshuttle.shoppinglist - before)[1]
	TEST_ASSERT(medical.set_saving_goal(pack, head), "После заказа цели новая не ставится")
	econ_cancel_order(order)
	SSshuttle.shoppinglist -= order
	qdel(order)
	TEST_ASSERT_EQUAL(medical.saving_goal_until, until, "Цель, поставленная заново, пока заказ ждал, продлена отменой заказа")
	medical.saving_goal_until = world.time
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), 0, "Возвращённая цель не истекла")
	TEST_ASSERT(!medical.set_saving_goal(pack, head), "После истечения возвращённой цели нет перерыва")

/// Пока бюджет не набрал цену цели, срок не идёт: дорогой пак можно копить дольше saving_goal_minutes. Срок на заказ начинается, когда денег хватает.
/datum/unit_test/economy_budget_cap/goal_waits_until_reached/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(medical.account, price - 1)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), price, "Цель - цена пака")
	TEST_ASSERT_EQUAL(medical.saving_goal_until, 0, "Срок цели пошёл, пока денег на пак нет")
	TEST_ASSERT_EQUAL(medical.budget_return_due(), 0, "Пока копим, излишка нет")
	TEST_ASSERT(!medical.set_saving_goal(pack, head), "Копящуюся цель можно перезавести")
	econ_test_set_balance(medical.account, price)
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), price, "Набранная цель пропала")
	TEST_ASSERT_EQUAL(medical.saving_goal_until, world.time + SSeconomy.settings.saving_goal_minutes MINUTES, "Набранная цель не дала срок на заказ")
	var/list/before = SSshuttle.shoppinglist.Copy()
	TEST_ASSERT(medical.order_pack(pack, head, "Тест"), "Пак-цель не заказан")
	var/datum/supply_order/order = (SSshuttle.shoppinglist - before)[1]
	econ_cancel_order(order)
	SSshuttle.shoppinglist -= order
	qdel(order)
	TEST_ASSERT(medical.saving_goal == pack, "Отмена заказа не вернула цель")

/datum/unit_test/economy_budget_cap/proc/cargo_budget_app()
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_QM)
	head.put_in_active_hand(head_card)
	var/datum/computer_file/program/department_budget/program = new
	allocated += program
	program.fixed_department = ACCOUNT_CAR
	return list(head, program)

/// Рабочая система оповещения станции первой в списке, с гарнитурой-шпионом.
/datum/unit_test/economy_budget_cap/proc/spy_announcer()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	return spy

/datum/unit_test/economy_budget_cap/proc/heard_on(obj/item/radio/headset/econ_test_spy/spy, channel)
	. = 0
	for(var/line in spy.heard)
		if(findtext(line, "[channel]: ") == 1)
			.++

/// Цель, которую бюджет не набрал за saving_goal_collect_minutes с постановки, снимается как истёкшая, с перерывом; набранная вовремя живёт до срока на заказ.
/datum/unit_test/economy_budget_cap/goal_lapses_uncollected/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	var/collect = settings.saving_goal_collect_minutes MINUTES
	econ_test_set_balance(medical.account, price - 1)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	TEST_ASSERT_EQUAL(medical.saving_goal_set_at, world.time, "Не запомнено, когда поставлена цель")
	medical.saving_goal_set_at = world.time - collect + 1
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), price, "Цель снята раньше срока на сбор")
	TEST_ASSERT_EQUAL(medical.budget_return_due(), 0, "Копящаяся цель не держит излишек")
	medical.saving_goal_set_at = world.time - collect - 1
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), 0, "Не набранная за [settings.saving_goal_collect_minutes] мин. цель держит деньги")
	TEST_ASSERT_NULL(medical.saving_goal, "Не набранная за срок цель не снята")
	TEST_ASSERT_EQUAL(medical.saving_goal_cooldown_minutes(), settings.saving_goal_cooldown_minutes, "Снятая по сроку сбора цель не дала перерыв")
	TEST_ASSERT(!medical.set_saving_goal(pack, head), "После снятия по сроку сбора новая цель без перерыва")
	medical.saving_goal_cooldown_until = 0
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена повторно")
	econ_test_set_balance(medical.account, price)
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), price, "Набранная цель пропала")
	medical.saving_goal_set_at = world.time - 2 * collect
	TEST_ASSERT_EQUAL(medical.saving_goal_amount(), price, "Набранная цель снята по сроку сбора, хотя срок на заказ идёт")

/// Снабжение копит на пак дороже своего порога, который заказывает за свой бюджет с консоли: цена пака не уходит NT, отгрузка пака шаттлом снимает цель.
/datum/unit_test/economy_budget_cap/cargo_goal_pack
	var/list/saved_orders
	var/list/saved_history

/datum/unit_test/economy_budget_cap/cargo_goal_pack/New()
	. = ..()
	saved_orders = SSshuttle.shoppinglist
	saved_history = SSshuttle.orderhistory.Copy()
	SSshuttle.shoppinglist = list()

/datum/unit_test/economy_budget_cap/cargo_goal_pack/Destroy()
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist | (SSshuttle.orderhistory - saved_history))
		qdel(order)
	SSshuttle.shoppinglist = saved_orders
	SSshuttle.orderhistory = saved_history
	return ..()

/datum/unit_test/economy_budget_cap/cargo_goal_pack/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/cargo/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/list/app = cargo_budget_app()
	var/mob/living/carbon/human/head = app[1]
	var/datum/computer_file/program/department_budget/program = app[2]
	var/threshold = cargo.budget_threshold()
	var/datum/supply_pack/goal_pack
	var/price = 0
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(!econ_cargo_budget_pack(pack) || pack.special || pack.goody || econ_pack_unavailable(pack) || ispath(pack.crate_type, /obj/structure/closet/secure_closet/cargo))
			continue
		var/pack_price = round(econ_pack_price(pack))
		if(pack_price > threshold && pack_price <= 100000 && pack_price > price)
			goal_pack = pack
			price = pack_price
	TEST_ASSERT_NOTNULL(goal_pack, "Нет пака снабжения дороже порога [threshold] кр.")
	econ_test_set_balance(cargo.account, price - 1)
	TEST_ASSERT(cargo.budget_return_due() > 0, "Без цели излишек не возвращается")
	program.budget_act(head, "set_goal", list("pack" = "[goal_pack.type]"))
	var/answer = program.messages[REF(head)]
	TEST_ASSERT(cargo.saving_goal == goal_pack, "Цель на пак снабжения не поставлена: [answer]")
	TEST_ASSERT(findtext(answer, "набрать её нужно за [settings.saving_goal_collect_minutes] мин."), "Ответ не говорит о сроке на сбор: [answer]")
	TEST_ASSERT(findtext(answer, "отгрузите шаттлом снабжения или закажите с экспресс-консоли за [settings.saving_goal_minutes] мин."), "Ответ не говорит, как получить пак вне каталога: [answer]")
	TEST_ASSERT_EQUAL(cargo.saving_goal_amount(), price, "Цель - цена пака у самого дешёвого партнёра")
	TEST_ASSERT_EQUAL(cargo.budget_return_due(), 0, "Цель не держит деньги снабжения от возврата")
	var/list/goal_entry = program.budget_data(head)["department"]["goal"]
	TEST_ASSERT(goal_entry["off_catalog"], "Окно не знает, что пак вне каталога")
	TEST_ASSERT_EQUAL(goal_entry["collect_minutes_left"], settings.saving_goal_collect_minutes, "Окно не показывает срок на сбор")
	var/datum/supply_pack/hidden_pack
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack.contraband && !pack.department_catalog)
			hidden_pack = pack
			break
	TEST_ASSERT_NOTNULL(hidden_pack, "Нет контрабандного пака")
	TEST_ASSERT(!cargo.can_save_for(hidden_pack), "На контрабанду копить нельзя")
	econ_test_set_balance(cargo.account, threshold + price * 3)
	var/datum/supply_order/order = new(goal_pack, "Тест", "Тест", null, "Тест")
	SSshuttle.shoppinglist += order
	var/list/before = list()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/atom/movable/thing in shuttle_area)
			before += thing
	SSshuttle.supply.buy()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/obj/thing in shuttle_area)
			if(!(thing in before))
				allocated += thing.GetAllContents()
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Заказ пака-цели не отгружен")
	TEST_ASSERT_NULL(cargo.saving_goal, "Отгрузка пака за бюджет снабжения не сняла цель")
	TEST_ASSERT_EQUAL(cargo.saving_goal_cooldown_minutes(), 0, "Заказ цели дал перерыв")

/// Снабжение копит на отряд ОБР: его цена не уходит NT, командование слышит, что отряд можно вызвать; вызов снимает цель, возврат денег за не прилетевший отряд возвращает её и защиту разовых поступлений.
/datum/unit_test/economy_budget_cap/cargo_goal_ert
	var/list/saved_ert_available = list()

/datum/unit_test/economy_budget_cap/cargo_goal_ert/New()
	. = ..()
	for(var/list/ert as anything in GLOB.payed_ert)
		saved_ert_available += ert["available"]

/datum/unit_test/economy_budget_cap/cargo_goal_ert/Destroy()
	for(var/i in 1 to length(saved_ert_available))
		GLOB.payed_ert[i]["available"] = saved_ert_available[i]
	var/datum/economy_department/cargo/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	cargo.ert_paid = list()
	cargo.saving_goal_extended = FALSE
	return ..()

/datum/unit_test/economy_budget_cap/cargo_goal_ert/Run()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/economy_department/cargo/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/list/app = cargo_budget_app()
	var/mob/living/carbon/human/head = app[1]
	var/datum/computer_file/program/department_budget/program = app[2]
	var/ert_id = length(GLOB.payed_ert)
	TEST_ASSERT(ert_id > 1, "Меньше двух платных отрядов ОБР")
	var/other_id = 1
	var/list/ert = GLOB.payed_ert[ert_id]
	var/list/other = GLOB.payed_ert[other_id]
	ert["available"] = TRUE
	other["available"] = TRUE
	var/price = ert["price"]
	var/threshold = cargo.budget_threshold()
	TEST_ASSERT(price > threshold, "Отряд дешевле порога снабжения")
	econ_test_set_balance(cargo.account, price - 1)
	TEST_ASSERT(cargo.budget_return_due() > 0, "Без цели излишек не возвращается")
	program.budget_act(head, "set_goal", list("ert" = ert_id))
	var/answer = program.messages[REF(head)]
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, ert_id, "Цель на отряд ОБР не поставлена: [answer]")
	TEST_ASSERT(findtext(answer, "отряд вызывает капитан с консоли связи"), "Ответ не говорит, кто вызывает отряд: [answer]")
	TEST_ASSERT_EQUAL(cargo.saving_goal_amount(), price, "Цель - цена отряда")
	TEST_ASSERT_EQUAL(cargo.budget_return_due(), 0, "Цель на ОБР не держит деньги от возврата")
	var/list/goal_entry = program.budget_data(head)["department"]["goal"]
	TEST_ASSERT(goal_entry && goal_entry["name"] == ert["name"], "Окно не показывает цель на ОБР")
	TEST_ASSERT_EQUAL(goal_entry["collect_minutes_left"], settings.saving_goal_collect_minutes, "Окно не показывает срок на сбор цели на ОБР")
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	econ_test_set_balance(SSeconomy.treasury(), price * 2)
	cargo.shield = list()
	TEST_ASSERT(SSeconomy.treasury_transfer(cargo, price), "Перевод из казны снабжению не прошёл")
	TEST_ASSERT_EQUAL(cargo.shielded(), price, "Перевод из казны не под защитой")
	TEST_ASSERT(cargo.saving_goal_amount() && cargo.saving_goal_until, "Набранная цель на ОБР не дала срок на вызов")
	cargo.saving_goal_amount()
	TEST_ASSERT_EQUAL(heard_on(spy, RADIO_CHANNEL_COMMAND), 1, "Командование не услышало ровно раз о набранной цели на ОБР: [jointext(spy.heard, " | ")]")
	TEST_ASSERT_EQUAL(heard_on(spy, RADIO_CHANNEL_SUPPLY), 1, "Снабжение не услышало ровно раз о набранной цели на ОБР: [jointext(spy.heard, " | ")]")
	TEST_ASSERT(findtext(jointext(spy.heard, " | "), "капитан может вызвать его с консоли связи"), "Оповещение не говорит, кто вызывает отряд: [jointext(spy.heard, " | ")]")
	var/obj/machinery/computer/communications/console = allocate(/obj/machinery/computer/communications, locate(3, 2, SSmapping.levels_by_trait(ZTRAIT_STATION)[1]))
	console.authenticated = TRUE
	console.authorize_access = list(ACCESS_HEADS)
	var/datum/tgui/window = allocate(/datum/tgui, head, console, "CommunicationsConsole")
	window.status = UI_INTERACTIVE
	var/purchases_before = SSeconomy.ledger.by_reason[ECON_PURCHASE] || 0
	cargo.saving_goal_until = world.time + 1 MINUTES
	usr = head
	console.ui_act("purchaseERT", list("ert" = ert_id), window)
	usr = null
	TEST_ASSERT_EQUAL(SSeconomy.ledger.by_reason[ECON_PURCHASE] || 0, purchases_before, "Отряд вызван с консоли связи не капитаном")
	console.authorize_access = list(ACCESS_HEADS, ACCESS_CAPTAIN)
	usr = head
	console.ui_act("purchaseERT", list("ert" = ert_id), window)
	usr = null
	TEST_ASSERT_EQUAL((SSeconomy.ledger.by_reason[ECON_PURCHASE] || 0) - purchases_before, price, "Капитан не вызвал отряд с консоли связи")
	TEST_ASSERT(ert["available"], "Отряд, на который не нашлось призраков, не вернулся в список")
	TEST_ASSERT_EQUAL(cargo.shielded(), price, "Возврат за отряд не вернул защиту разовых поступлений")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, ert_id, "Возврат за не прилетевший отряд не вернул цель")
	TEST_ASSERT_EQUAL(cargo.saving_goal_until, world.time + ECON_ERT_REFUND_GOAL_GRACE, "Почти истёкшая цель вернулась без продления")
	TEST_ASSERT_EQUAL(length(cargo.ert_paid), 0, "После возврата осталась запись об оплате отряда")
	TEST_ASSERT(cargo.pay_ert(ert_id), "Отряд не вызван")
	TEST_ASSERT(!ert["available"], "Вызванный отряд остался доступным")
	TEST_ASSERT_EQUAL(cargo.shielded(), 0, "Вызов отряда не потратил защищённые деньги")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, 0, "Вызов отряда не снял цель")
	TEST_ASSERT_EQUAL(cargo.saving_goal_amount(), 0, "После вызова цель держит деньги")
	TEST_ASSERT_EQUAL(cargo.saving_goal_cooldown_minutes(), 0, "Вызов цели дал перерыв")
	TEST_ASSERT(cargo.set_saving_goal_ert(other_id, head), "Пока отряд летит, новая цель не ставится")
	econ_test_set_balance(cargo.account, threshold + price + other["price"])
	TEST_ASSERT(cargo.pay_ert(other_id), "Второй отряд не вызван")
	cargo.refund_ert(ert_id, "Тест")
	TEST_ASSERT(ert["available"], "Возврат не вернул отряд в список")
	TEST_ASSERT_EQUAL(cargo.shielded(), price, "Возврат за первый отряд после вызова второго не вернул защиту")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, ert_id, "Возврат денег за первый отряд не вернул его цель после вызова второго")
	TEST_ASSERT_EQUAL(cargo.saving_goal_until, world.time + ECON_ERT_REFUND_GOAL_GRACE, "Срок возвращённой цели сдвинулся")
	cargo.refund_ert(other_id, "Тест")
	TEST_ASSERT(other["available"], "Возврат не вернул второй отряд")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, ert_id, "Возврат за второй отряд сбил цель первого")
	cargo.saving_goal_until = world.time + 1 MINUTES
	TEST_ASSERT(cargo.pay_ert(ert_id), "Отряд не вызван повторно")
	cargo.refund_ert(ert_id, "Тест")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, ert_id, "Второй возврат не вернул цель")
	TEST_ASSERT_EQUAL(cargo.saving_goal_until, world.time + 1 MINUTES, "Срок цели продлён возвратом второй раз")
	ert["available"] = FALSE
	TEST_ASSERT_EQUAL(cargo.saving_goal_amount(), 0, "Цель на недоступный отряд держит деньги")
	TEST_ASSERT_EQUAL(cargo.saving_goal_ert, 0, "Цель на недоступный отряд не снята")

/// Красный код и выше - ЧС: NT не забирает излишек, чтобы отделу было на что чинить станцию.
/datum/unit_test/economy_budget_cap/emergency_pauses_return/Run()
	var/datum/economy_department/medical = staff_medical()
	econ_test_set_balance(medical.account, medical.budget_threshold() + 20000)
	var/due_green = medical.budget_return_due()
	var/saved_level = GLOB.security_level
	GLOB.security_level = SEC_LEVEL_RED
	var/due_red = medical.budget_return_due()
	var/balance_before = medical.account.account_balance
	medical.return_excess()
	var/balance_after = medical.account.account_balance
	GLOB.security_level = saved_level
	TEST_ASSERT(due_green > 0, "Без ЧС излишек не возвращается")
	TEST_ASSERT_EQUAL(due_red, 0, "При красном коде NT забирает излишек")
	TEST_ASSERT_EQUAL(balance_after, balance_before, "При красном коде возврат списал деньги")
	TEST_ASSERT_EQUAL(medical.budget_return_due(), due_green, "После снятия кода возврат не вернулся")

/// Возврат излишка не тратит защиту: переведённое из казны остаётся защищённым весь срок.
/datum/unit_test/economy_budget_cap/return_keeps_shield/Run()
	var/datum/economy_department/medical = staff_medical()
	econ_test_set_balance(medical.account, medical.budget_threshold() + 20000)
	econ_test_set_balance(SSeconomy.treasury(), 50000)
	SSeconomy.treasury_transfer(medical, 3000)
	for(var/tick in 1 to SSeconomy.settings.budget_cap_grace_ticks - 1)
		medical.return_excess()
		SSeconomy.fire_count += 1
	TEST_ASSERT_EQUAL(medical.shielded(), 3000, "Перевод защищён весь срок, возврат его не тратит")

/// Истёкшая защита не считается потраченной заказом.
/datum/unit_test/economy_budget_cap/expired_not_consumed/Run()
	var/datum/economy_department/medical = staff_medical()
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(SSeconomy.treasury(), price * 10)
	econ_test_set_balance(medical.account, price * 3)
	SSeconomy.treasury_transfer(medical, price)
	SSeconomy.fire_count += SSeconomy.settings.budget_cap_grace_ticks
	var/list/before = SSshuttle.shoppinglist.Copy()
	medical.order_pack(pack, null, "Тест", TRUE)
	var/list/placed = SSshuttle.shoppinglist - before
	var/datum/supply_order/order = placed[1]
	var/shield_paid = length(order.shield_entries)
	SSshuttle.shoppinglist -= order
	qdel(order)
	TEST_ASSERT_EQUAL(shield_paid, 0, "Заказ не тратит истёкшую защиту")

/// Возврат за покупку (ОБР не прилетел) отменяет её сток, а не становится новыми деньгами отдела.
/datum/unit_test/economy_budget_cap/refund_reverses_burn/Run()
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	econ_test_set_balance(cargo.account, 10000)
	var/list/flow = SSeconomy.ledger.department_flow(ACCOUNT_CAR)
	var/burned_before = flow["burned"]
	var/in_before = flow["in"]
	cargo.account.debit(4000, ECON_PURCHASE)
	cargo.account.credit(4000, ECON_REFUND)
	TEST_ASSERT_EQUAL(flow["burned"], burned_before, "Возврат отменил сток покупки")
	TEST_ASSERT_EQUAL(flow["in"], in_before, "Возврат не стал оставшимися у отдела деньгами")

/// Излишек, который забрал бы NT, сначала доливает ещё не набранную цель накопления другого отдела, остальное уходит NT; набранную цель он больше не доливает.
/datum/unit_test/economy_budget_cap/surplus_funds_goals/Run()
	var/datum/economy_department/medical = staff_medical()
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(ACCESS_CMO)
	head.put_in_active_hand(head_card)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(medical.account, 0)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	TEST_ASSERT_EQUAL(medical.saving_goal_shortfall(), price, "До цели не хватает её цены")
	var/list/stats = econ_staff_stats()
	econ_test_set_balance(cargo.account, cargo.budget_threshold(stats) + cargo.owed_to_staff(stats) + price * 4)
	var/due = cargo.budget_return_due(stats)
	TEST_ASSERT(due > price, "Излишка снабжения хватает на цель: [due] из [price]")
	var/cargo_before = cargo.account.account_balance
	cargo.return_excess(stats)
	TEST_ASSERT_EQUAL(medical.account.account_balance, price, "Излишек снабжения долил цель медицины до цены")
	TEST_ASSERT(medical.saving_goal_until, "Долитая цель набрана и дала срок на заказ")
	TEST_ASSERT_EQUAL(cargo_before - cargo.account.account_balance, due, "Снабжение отдало не больше, чем забрал бы NT")
	var/medical_before = medical.account.account_balance
	cargo.return_excess(econ_staff_stats())
	TEST_ASSERT_EQUAL(medical.account.account_balance, medical_before, "Набранную цель излишек больше не доливает")
	TEST_ASSERT_EQUAL(medical.saving_goal_shortfall(), 0, "У набранной цели недостачи нет")

/datum/unit_test/economy_budget_cap/proc/head_of(access)
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/head_card = allocate(/obj/item/card/id)
	head_card.access = list(access)
	head.put_in_active_hand(head_card)
	return head

/// Снабжению излишек на заданную сумму возврата: баланс выше порога и зарплат на due / доля возврата.
/datum/unit_test/economy_budget_cap/proc/cargo_with_due(due)
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/list/stats = econ_staff_stats()
	econ_test_set_balance(cargo.account, cargo.budget_threshold(stats) + cargo.owed_to_staff(stats) + CEILING(due * 100 / SSeconomy.settings.budget_cap_return_share, 1))
	return cargo

/// Долив чужим излишком привязан к цели: потраченное на другое не доливается сверх первой недостачи, а при снятии цели без заказа долитое уходит NT, недостающее - в долг отдела.
/datum/unit_test/economy_budget_cap/goal_funding_capped_and_reclaimed/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = head_of(ACCESS_CMO)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	TEST_ASSERT(price >= 10, "Пак слишком дешёвый для теста: [price]")
	econ_test_set_balance(medical.account, 0)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	var/datum/economy_department/cargo = cargo_with_due(round(price / 2))
	cargo.return_excess(econ_staff_stats())
	var/first = medical.account.account_balance
	TEST_ASSERT(first > 0 && first < price, "Первый долив частичный: [first] из [price]")
	TEST_ASSERT_EQUAL(medical.saving_goal_funded, first, "Долив записан на цель")
	econ_test_set_balance(medical.account, 0)
	for(var/i in 1 to 4)
		cargo_with_due(price)
		cargo.return_excess(econ_staff_stats())
	TEST_ASSERT_EQUAL(medical.saving_goal_funded, price, "Долив на цель не больше первой недостачи, сколько бы ни потратили")
	TEST_ASSERT_EQUAL(medical.account.account_balance, price - first, "После траты долили только остаток до потолка")
	var/owed_before = medical.owed
	medical.clear_saving_goal(head)
	TEST_ASSERT_EQUAL(medical.account.account_balance, 0, "Снятая цель отдала NT долитое")
	TEST_ASSERT_EQUAL(medical.owed - owed_before, first, "Потраченный долив записан в долг отдела")
	TEST_ASSERT_EQUAL(medical.saving_goal_funded, 0, "Учёт долива сброшен")

/// Долив чужой цели не тратит защиту разовых поступлений источника: перевод из казны остаётся не излишком.
/datum/unit_test/economy_budget_cap/goal_funding_keeps_source_shield/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = head_of(ACCESS_CMO)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	econ_test_set_balance(medical.account, 0)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	var/datum/economy_department/cargo = cargo_with_due(round(econ_pack_price(pack)) * 2)
	econ_test_set_balance(SSeconomy.treasury(), 5000)
	SSeconomy.treasury_transfer(cargo, 5000)
	var/shield_before = cargo.shielded()
	TEST_ASSERT_EQUAL(shield_before, 5000, "Перевод из казны под защитой")
	cargo.return_excess(econ_staff_stats())
	TEST_ASSERT(medical.saving_goal_until, "Цель долита")
	TEST_ASSERT_EQUAL(cargo.shielded(), shield_before, "Долив не съел защиту источника")

/// Излишка на две цели не хватает - первой его получает цель, поставленная раньше.
/datum/unit_test/economy_budget_cap/goal_funding_oldest_first/Run()
	var/datum/economy_department/medical = staff_medical()
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/datum/supply_pack/med_pack = cheapest_pack(medical)
	var/datum/supply_pack/sci_pack = cheapest_pack(science)
	econ_test_set_balance(medical.account, 0)
	econ_test_set_balance(science.account, 0)
	TEST_ASSERT(science.set_saving_goal(sci_pack, head_of(ACCESS_RD)), "Цель науки не поставлена")
	science.saving_goal_set_at = world.time - 10
	TEST_ASSERT(medical.set_saving_goal(med_pack, head_of(ACCESS_CMO)), "Цель медицины не поставлена")
	var/datum/economy_department/cargo = cargo_with_due(round(econ_pack_price(sci_pack)))
	cargo.return_excess(econ_staff_stats())
	TEST_ASSERT(science.saving_goal_until, "Ранняя цель долита первой")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 0, "Поздней цели излишка не осталось")

/// Отмена заказа, закрывшего долитую цель, возвращает цели и её долив: снять её потом без заказа - долитое уходит NT.
/datum/unit_test/economy_budget_cap/goal_funding_survives_cancel/Run()
	var/datum/economy_department/medical = staff_medical()
	var/mob/living/carbon/human/head = head_of(ACCESS_CMO)
	var/datum/supply_pack/pack = cheapest_pack(medical)
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(medical.account, 0)
	TEST_ASSERT(medical.set_saving_goal(pack, head), "Цель не поставлена")
	var/datum/economy_department/cargo = cargo_with_due(price * 2)
	cargo.return_excess(econ_staff_stats())
	TEST_ASSERT_EQUAL(medical.account.account_balance, price, "Цель долита до цены")
	order_and_cancel(medical, pack)
	TEST_ASSERT(medical.saving_goal == pack, "Отмена вернула цель")
	TEST_ASSERT_EQUAL(medical.saving_goal_funded, price, "Отмена вернула цели её долив")
	medical.clear_saving_goal(head)
	TEST_ASSERT_EQUAL(medical.account.account_balance, 0, "Снятая после отмены цель отдала долитое NT")
