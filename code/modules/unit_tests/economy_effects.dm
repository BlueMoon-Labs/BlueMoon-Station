/// Счёт, который запоминает звуки своей карты.
/datum/bank_account/econ_test_sound_spy
	var/list/card_sounds = list()
	var/list/card_balloons = list()
	var/list/shown_balloons = list()

/datum/bank_account/econ_test_sound_spy/bank_card_talk(message, force, talk_sound, balloon)
	card_sounds += "[talk_sound]"
	if(balloon)
		card_balloons += balloon
	return ..()

/datum/bank_account/econ_test_sound_spy/show_card_balloon(mob/holder, text)
	shown_balloons += text
	return ..()

/// Шпион, до держателя которого сообщения карты доходят и без клиента.
/datum/bank_account/econ_test_sound_spy/listening/card_talk_reaches(mob/holder, force)
	return TRUE

/obj/structure/sign/ticker_board/econ_test_spy
	var/list/heard = list()
	var/list/flashes = list()

/obj/structure/sign/ticker_board/econ_test_spy/board_flash(animation)
	flashes += animation
	return ..()

/obj/structure/sign/ticker_board/econ_test_spy/play_market_sound(kind)
	heard += kind
	return ..()

/obj/machinery/computer/stock_terminal/econ_test_spy
	var/list/heard = list()

/obj/machinery/computer/stock_terminal/econ_test_spy/play_market_sound(kind)
	heard += kind
	return ..()

/obj/machinery/evidence_locker/econ_test_spy
	var/list/animations = list()
	var/list/heard = list()

/obj/machinery/evidence_locker/econ_test_spy/locker_feedback(animation, soundfile, vary, always)
	animations += animation
	return ..()

/obj/machinery/evidence_locker/econ_test_spy/play_locker_sound(soundfile, vary)
	heard += "[soundfile]"
	return ..()

/// Чаевые из окна кассы поднимают над ней монетки не чаще кулдауна, свайп кассира открывает ящик.
/datum/unit_test/economy_register/effects/Run()
	setup_register()
	swipe(cashier)
	TEST_ASSERT(register.is_cashier(cashier), "Кассир встал за кассу")
	TEST_ASSERT(!COOLDOWN_FINISHED(register, drawer_cooldown), "Свайп кассира не открыл ящик")
	econ_ui_press(customer, register, "CashRegister", "tip", list("amount" = "15", "cashier" = cashier_account.account_id))
	TEST_ASSERT_EQUAL(customer_account.account_balance, 985, "Чаевые прошли")
	var/obj/effect/temp_visual/econ_coins/coins = locate() in get_turf(register)
	TEST_ASSERT_NOTNULL(coins, "Над кассой нет монеток")
	qdel(coins)
	var/mob/living/carbon/human/second = make_person("econ_test_second_customer", null, 1000)
	econ_ui_press(second, register, "CashRegister", "tip", list("amount" = "10", "cashier" = cashier_account.account_id))
	var/datum/bank_account/second_account = econ_account_of(second)
	TEST_ASSERT_EQUAL(second_account.account_balance, 990, "Вторые чаевые в кулдаун эффекта прошли")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/econ_coins) in get_turf(register), "Монетки повторились до кулдауна")

/// Узел экспорта гудит, только пока включён и отбирает мощность, и глохнет вместе с узлом.
/datum/unit_test/economy_engineering/node_hum/Run()
	save_state()
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node/econ_test_station)
	test_grid(node)
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = 1000))
	TEST_ASSERT(!node.soundloop.timerid, "Выключенный узел гудит")
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	TEST_ASSERT(node.soundloop.timerid, "Включённый узел не гудит")
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = 0))
	TEST_ASSERT(!node.soundloop.timerid, "Узел без отбора мощности гудит")
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = 1000))
	TEST_ASSERT(node.soundloop.timerid, "Гул не вернулся с мощностью")
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	TEST_ASSERT(!node.soundloop.timerid, "Выключенный узел гудит")
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	var/datum/looping_sound/export_node/hum = node.soundloop
	TEST_ASSERT(hum.timerid, "Узел не загудел снова")
	qdel(node)
	TEST_ASSERT(QDELETED(hum) && !hum.timerid && !hum.parent, "Гул пережил узел")

/// Заморозка из окна аудита звучит на карте владельца звуком заморозки.
/datum/unit_test/economy_ui_audit/freeze_sound/Run()
	var/mob/living/carbon/human/captain = make_person("Econ UI Audit Chief", list(ACCESS_CAPTAIN), pda_type = /obj/item/modular_computer/pda/heads/captain)
	var/datum/bank_account/econ_test_sound_spy/owner = make_account("Econ UI Audit Owner", 0, /datum/bank_account/econ_test_sound_spy)
	press(captain, "freeze", list("number" = "[owner.account_id]", "reason" = "проверка"))
	TEST_ASSERT_EQUAL(owner.state, ACCOUNT_FROZEN, "Счёт заморожен")
	TEST_ASSERT(("sound/economy/account_freeze.ogg" in owner.card_sounds), "Заморозка без звука на карте: [jointext(owner.card_sounds, ", ")]")
	TEST_ASSERT(("счёт заморожен" in owner.card_balloons), "Заморозка без всплывашки над владельцем: [jointext(owner.card_balloons, ", ")]")

/// Зарплата звенит монетами на карте сотрудника без всплывашки над головой.
/datum/unit_test/economy_payroll/payday_sound/Run()
	setup_worker(10000)
	SSeconomy.tax_rate = 10
	var/datum/bank_account/econ_test_sound_spy/spy = new("econ_test_payday_spy")
	spy.department_id = ACCOUNT_SRV
	spy.pay_grade = PAY_GRADE_EASY
	spy.bind_owner(allocate(/mob/living/carbon/human))
	SSeconomy.run_payroll()
	var/list/heard = spy.card_sounds.Copy()
	var/list/balloons = spy.card_balloons.Copy()
	var/paid = spy.account_balance
	qdel(spy)
	TEST_ASSERT(paid > 0 && paid < SSeconomy.settings.wages[PAY_GRADE_EASY], "Зарплата не пришла или пришла без налога: [paid]")
	TEST_ASSERT(("sound/economy/coin_soft.ogg" in heard), "Зарплата без звона монет: [jointext(heard, ", ")]")
	TEST_ASSERT(!length(balloons), "Всплывашка на зарплате: [jointext(balloons, ", ")]")

/// Всплывашка одного вида не чаще кулдауна на держателя; другой вид, другой держатель и force проходят.
/datum/unit_test/economy_payroll/card_balloon_throttle/Run()
	var/datum/bank_account/econ_test_sound_spy/spy = new("econ_test_balloon_spy")
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/other_holder = allocate(/mob/living/carbon/human)
	spy.card_balloon(holder, "касса +1 кр")
	spy.card_balloon(holder, "касса +2 кр")
	spy.card_balloon(holder, "чаевые +3 кр")
	spy.card_balloon(other_holder, "касса +4 кр")
	spy.card_balloon(holder, "касса +5 кр", TRUE)
	var/shown = jointext(spy.shown_balloons, ",")
	qdel(spy)
	TEST_ASSERT_EQUAL(shown, "касса +1 кр,чаевые +3 кр,касса +4 кр,касса +5 кр", "Всплывашки в кулдаун")

/// Чаевые на карту в руке поднимают всплывашку над держателем, перевод оглохшему - нет, как и строки в чате.
/datum/unit_test/economy_payroll/card_balloon_carried/Run()
	var/datum/bank_account/econ_test_sound_spy/listening/spy = new("econ_test_carried_spy")
	var/datum/bank_account/payer = new("econ_test_balloon_payer")
	econ_test_set_balance(payer, 100)
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.registered_account = spy
	spy.bank_cards += card
	holder.put_in_hands(card)
	var/first_error = SSeconomy.send_tip(payer, spy, 15)
	var/list/shown = spy.shown_balloons.Copy()
	var/obj/item/organ/ears/ears = holder.getorganslot(ORGAN_SLOT_EARS)
	ears.deaf = 100
	payer.personal_payment_cooldown = 0
	var/second_error = SSeconomy.send_transfer(payer, spy, 10)
	var/list/shown_deaf = spy.shown_balloons.Copy()
	spy.bank_cards -= card
	card.registered_account = null
	qdel(spy)
	qdel(payer)
	TEST_ASSERT_NULL(first_error, "Чаевые не прошли: [first_error]")
	TEST_ASSERT_NULL(second_error, "Перевод не прошёл: [second_error]")
	TEST_ASSERT_EQUAL(jointext(shown, ","), "чаевые +15 кр", "Всплывашка над держателем карты")
	TEST_ASSERT_EQUAL(jointext(shown_deaf, ","), "чаевые +15 кр", "Всплывашка оглохшему держателю")

/// Премия и доля контракта во всплывашке - сумма на руки после налога.
/datum/unit_test/economy_balloon_net/Run()
	var/saved_tax = SSeconomy.tax_rate
	SSeconomy.tax_rate = 10
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/saved_budget = engineering.account.account_balance
	var/datum/bank_account/service_budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	var/saved_service = service_budget.account_balance
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/saved_treasury = treasury.account_balance
	econ_test_set_balance(engineering.account, 1000)
	var/mob/living/carbon/human/chief = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/chief_card = allocate(/obj/item/card/id)
	chief_card.access = list(ACCESS_CE)
	chief.put_in_hands(chief_card)
	var/datum/bank_account/econ_test_sound_spy/member = new("econ_test_bonus_spy")
	member.department_id = ACCOUNT_ENG
	member.pay_grade = PAY_GRADE_EASY
	var/bonus_paid = engineering.pay_bonus(member, 200, chief)
	var/bonus_net = member.account_balance
	var/list/bonus_balloons = member.card_balloons.Copy()
	var/datum/econ_contract/contract = new /datum/econ_contract/activity/service_cleaning(ACCOUNT_SRV)
	var/taken = contract.take(member)
	contract.complete(null)
	var/contract_net = member.account_balance - bonus_net
	var/list/contract_balloons = member.card_balloons - bonus_balloons
	SSeconomy.tax_rate = saved_tax
	econ_test_set_balance(engineering.account, saved_budget)
	econ_test_set_balance(service_budget, saved_service)
	econ_test_set_balance(treasury, saved_treasury)
	if(!QDELETED(contract))
		qdel(contract)
	qdel(member)
	TEST_ASSERT(bonus_paid, "Премия не выдана")
	TEST_ASSERT(bonus_net > 0 && bonus_net < 200, "Премия без налога: [bonus_net]")
	TEST_ASSERT_EQUAL(jointext(bonus_balloons, ","), "премия +[bonus_net] кр", "Всплывашка премии")
	TEST_ASSERT(taken, "Контракт не взят")
	TEST_ASSERT(contract_net > 0, "Доля контракта не пришла")
	TEST_ASSERT_EQUAL(jointext(contract_balloons, ","), "контракт +[contract_net] кр", "Всплывашка контракта")

/// Табло тикает на обновлении цен; табло и включённый терминал бьют тревогу на остановке торгов и обвале, звонят на возобновлении, не чаще кулдауна.
/datum/unit_test/economy_trading/market_sounds/Run()
	var/obj/structure/sign/ticker_board/econ_test_spy/board = allocate(/obj/structure/sign/ticker_board/econ_test_spy)
	var/obj/machinery/computer/stock_terminal/econ_test_spy/terminal = allocate(/obj/machinery/computer/stock_terminal/econ_test_spy)
	terminal.set_machine_stat(terminal.machine_stat & ~(NOPOWER|BROKEN))
	TEST_ASSERT(!length(board.heard), "Табло прозвучало при установке")
	SSmarket.tick_stocks()
	TEST_ASSERT_EQUAL(jointext(board.heard, ","), MARKET_SOUND_TICK, "Табло на обычном тике")
	TEST_ASSERT(!length(terminal.heard), "Терминал озвучил обычный тик")
	company.price = company.base_price * STOCK_BANKRUPT_RATIO / 2
	SSmarket.tick_stocks()
	TEST_ASSERT(company.is_halted(), "Торги не остановлены")
	TEST_ASSERT_EQUAL(jointext(board.heard, ","), "[MARKET_SOUND_TICK],[MARKET_SOUND_CRASH]", "Табло на остановке торгов")
	TEST_ASSERT_EQUAL(jointext(terminal.heard, ","), MARKET_SOUND_CRASH, "Терминал на остановке торгов")
	SSmarket.station_event_cooldowns = list()
	TEST_ASSERT(SSmarket.station_event("market_crash"), "Обвал рынка не прошёл")
	TEST_ASSERT_EQUAL(length(board.heard) + length(terminal.heard), 3, "Тревога повторилась до кулдауна")
	board.alarm_cooldown = 0
	terminal.alarm_cooldown = 0
	company.halted_until = world.time
	SSmarket.tick_stocks()
	TEST_ASSERT(!company.is_halted(), "Торги не возобновлены")
	TEST_ASSERT_EQUAL(board.heard[length(board.heard)], MARKET_SOUND_BELL, "Табло на возобновлении торгов")
	TEST_ASSERT_EQUAL(terminal.heard[length(terminal.heard)], MARKET_SOUND_BELL, "Терминал на возобновлении торгов")
	board.alarm_cooldown = 0
	terminal.alarm_cooldown = 0
	SSmarket.station_event_cooldowns = list()
	TEST_ASSERT(SSmarket.station_event("market_crash"), "Обвал рынка не прошёл")
	TEST_ASSERT_EQUAL(board.heard[length(board.heard)], MARKET_SOUND_CRASH, "Табло на обвале")
	TEST_ASSERT_EQUAL(terminal.heard[length(terminal.heard)], MARKET_SOUND_CRASH, "Терминал на обвале")

/// Хранилище улик анимирует отказ и приём всегда, а звук приёма сразу после отказа глушит кулдаун.
/datum/unit_test/economy_work/security/locker_feedback/Run()
	TEST_ASSERT_NOTNULL(setup_officer(), "ID офицера надета")
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/evidence_locker/econ_test_spy/locker = allocate(/obj/machinery/evidence_locker/econ_test_spy, station_turf)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	stranger.put_in_active_hand(emag)
	TEST_ASSERT(!locker.store(emag, stranger), "Без доступа СБ не принимает")
	TEST_ASSERT(locker.store(hold(allocate(/obj/item/card/id/syndicate)), performer), "Карту принимает")
	TEST_ASSERT_EQUAL(jointext(locker.animations, ","), "locker_locked,locker_accept", "Анимации отказа и приёма")
	TEST_ASSERT_EQUAL(jointext(locker.heard, ","), "sound/economy/locker_clunk.ogg", "Звук приёма в кулдаун отказа")

/// Найденный среди оверлеев атома оверлей свечения с этим стейтом.
/datum/unit_test/proc/econ_emissive_overlay(atom/target, state)
	for(var/overlay in islist(target.managed_overlays) ? target.managed_overlays : list(target.managed_overlays))
		if(!isappearance(overlay) && !istype(overlay, /mutable_appearance))
			continue
		var/mutable_appearance/appearance = overlay
		if(appearance.icon_state == state && PLANE_TO_TRUE(appearance.plane) == EMISSIVE_PLANE)
			return appearance

/// Работающий узел светится маской своего уровня и светом по уровню, перегрузка - маской дуг; выключенный узел гаснет.
/datum/unit_test/economy_engineering/node_glow/Run()
	save_state()
	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node/econ_test_station)
	var/datum/powernet/grid = test_grid(node)
	var/mob/living/carbon/human/engineer = allocate(/mob/living/carbon/human)
	var/datum/economy_settings/settings = SSeconomy.settings
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = settings.power_export_max_kw))
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_3_glow"), "Выключенный узел светится")
	TEST_ASSERT(!node.light_range, "Выключенный узел даёт свет")
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	TEST_ASSERT_NOTNULL(econ_emissive_overlay(node, "node_on_3_glow"), "Полный отбор без свечения обмоток")
	TEST_ASSERT("node_on_3_glow" in icon_states(node.icon), "Нет маски свечения в файле узла")
	var/full_power = node.light_power
	TEST_ASSERT(node.light_range > 0 && full_power > 0, "Работающий узел не даёт свет")
	econ_ui_press(engineer, node, "PowerExportNode", "set_draw", list("kw" = settings.power_export_step_kw))
	TEST_ASSERT_NOTNULL(econ_emissive_overlay(node, "node_on_1_glow"), "Малый отбор без свечения первого уровня")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_3_glow"), "Свечение третьего уровня осталось")
	TEST_ASSERT(node.light_power < full_power, "Свет малого отбора не слабее полного: [node.light_power] против [full_power]")
	node.screwdriver_act(engineer, allocate(/obj/item/screwdriver))
	TEST_ASSERT(node.panel_open, "Панель не открылась")
	TEST_ASSERT(!node.light_range, "Узел с открытой панелью светит")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_1_glow"), "Узел с открытой панелью светится обмотками")
	node.screwdriver_act(engineer, allocate(/obj/item/screwdriver))
	TEST_ASSERT(node.light_range, "Свет не вернулся с закрытой панелью")
	node.obj_break()
	TEST_ASSERT(!node.light_range, "Сломанный узел светит")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_1_glow"), "Сломанный узел светится обмотками")
	node.set_machine_stat(node.machine_stat & ~BROKEN)
	TEST_ASSERT(node.light_range, "Свет не вернулся после починки")
	node.set_machine_stat(node.machine_stat | NOPOWER)
	TEST_ASSERT(!node.light_range, "Узел без питания светит")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_1_glow"), "Узел без питания светится обмотками")
	node.set_machine_stat(node.machine_stat & ~NOPOWER)
	COOLDOWN_START(node, spark_cooldown, 1 MINUTES)
	node.process(1)
	power_cycle(grid, 0)
	TEST_ASSERT(node.overloaded, "Отбор без излишка не перегрузил узел")
	TEST_ASSERT_NOTNULL(econ_emissive_overlay(node, "node_overload_glow"), "Перегрузка без свечения дуг")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_1_glow"), "При перегрузке светится и уровень")
	TEST_ASSERT(!node.light_range, "Перегруженный узел светит обмотками")
	econ_ui_press(engineer, node, "PowerExportNode", "toggle")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_overload_glow"), "Выключенный узел светится дугами")
	TEST_ASSERT_NULL(econ_emissive_overlay(node, "node_on_1_glow"), "Выключенный узел светится обмотками")
	TEST_ASSERT(!node.light_range, "Выключенный узел не погас")

/// На событии станции табло вспыхивает, на обвале - всегда тревогой, бум в секторе звонит на табло и терминале, график терминала перерисовывается сразу.
/datum/unit_test/economy_trading/market_station_fx/Run()
	var/obj/structure/sign/ticker_board/econ_test_spy/board = allocate(/obj/structure/sign/ticker_board/econ_test_spy)
	var/obj/machinery/computer/stock_terminal/econ_test_spy/terminal = allocate(/obj/machinery/computer/stock_terminal/econ_test_spy)
	terminal.set_machine_stat(terminal.machine_stat & ~(NOPOWER|BROKEN))
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		each.history = list(each.price, each.price)
	terminal.market_up = TRUE
	SSmarket.station_event_cooldowns = list()
	TEST_ASSERT(SSmarket.station_event("market_crash"), "Обвал рынка не прошёл")
	TEST_ASSERT(!terminal.market_up, "График терминала не упал на обвале")
	TEST_ASSERT(econ_overlay_icon(terminal, "terminal_down"), "Терминал не показывает падающий график")
	board.alarm_cooldown = 0
	terminal.alarm_cooldown = 0
	TEST_ASSERT(SSmarket.station_event("sector_boom"), "Бум в секторе не прошёл")
	TEST_ASSERT_EQUAL(board.heard[length(board.heard)], MARKET_SOUND_BELL, "Табло на буме в секторе")
	TEST_ASSERT_EQUAL(terminal.heard[length(terminal.heard)], MARKET_SOUND_BELL, "Терминал на буме в секторе")
	var/heard_before = length(board.heard) + length(terminal.heard)
	SSmarket.station_event_cooldowns = list()
	TEST_ASSERT(SSmarket.station_event("sector_boom"), "Второй бум не прошёл")
	TEST_ASSERT_EQUAL(length(board.heard) + length(terminal.heard), heard_before, "Звонок повторился до кулдауна")
	board.flashes.Cut()
	TEST_ASSERT(SSmarket.station_event("disease_outbreak"), "Вспышка болезни не прошла")
	TEST_ASSERT_EQUAL(jointext(board.flashes, ","), "board_event", "Табло на событии станции")
	board.flashes.Cut()
	TEST_ASSERT(SSmarket.station_event("market_crash"), "Обвал в кулдаун тревоги не прошёл")
	TEST_ASSERT_EQUAL(jointext(board.flashes, ","), "board_halt", "Табло на обвале в кулдаун тревоги")
	TEST_ASSERT_EQUAL(length(board.heard) + length(terminal.heard), heard_before, "Тревога прозвучала в кулдаун")
