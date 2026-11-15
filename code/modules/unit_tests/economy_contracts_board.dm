/datum/unit_test/economy_contract_machines/board
	abstract_type = /datum/unit_test/economy_contract_machines/board
	var/saved_tax
	var/saved_started
	var/mob/living/carbon/human/helper
	var/datum/bank_account/helper_account

/// Доска без налога и с запущенными контрактами: суммы в проверках точные.
/datum/unit_test/economy_contract_machines/board/setup()
	..()
	saved_tax = SSeconomy.tax_rate
	saved_started = SSeconomy.contracts_started
	SSeconomy.tax_rate = 0
	SSeconomy.contracts_started = TRUE
	SSeconomy.contract_demand.Cut()
	helper = allocate(/mob/living/carbon/human)
	helper_account = new("econ_test_helper")
	helper.account_id = helper_account.account_id

/datum/unit_test/economy_contract_machines/board/Destroy()
	if(!isnull(saved_tax))
		SSeconomy.tax_rate = saved_tax
		SSeconomy.contracts_started = saved_started
	SSeconomy.contract_demand.Cut()
	. = ..()
	QDEL_NULL(helper_account)

/datum/unit_test/economy_contract_machines/board/proc/single_item(datum/econ_contract/delivery/contract)
	var/datum/bounty/item/wanted = contract.bounty
	wanted.required_count = 1
	return allocate(wanted.wanted_types[1])

/// Ранг подрядчика даёт слоты и надбавку, отказ и сорванный срок роняют репутацию.
/datum/unit_test/economy_contract_machines/board/reputation/Run()
	setup()
	var/datum/econ_contract/delivery/first = post_scooter_contract()
	var/datum/econ_contract/delivery/second = post_scooter_contract()
	var/datum/econ_contract/delivery/third = post_scooter_contract()
	TEST_ASSERT_EQUAL(taker_account.contract_slots(), 1, "Новичок держит один контракт")
	TEST_ASSERT(first.take(taker_account), "Первый взят")
	TEST_ASSERT(!second.take(taker_account), "Новичок взял второй контракт")
	taker_account.adjust_contract_rep(3)
	TEST_ASSERT_EQUAL(taker_account.contract_slots(), 2, "Подрядчик держит два контракта")
	TEST_ASSERT(second.take(taker_account), "Второй слот не открылся")
	TEST_ASSERT(!third.take(taker_account), "Взят контракт сверх слотов ранга")
	TEST_ASSERT(second.drop(taker_account), "Отказ")
	TEST_ASSERT_EQUAL(taker_account.contract_rep, 3 - ECON_CONTRACT_REP_DROP, "Отказ не снизил репутацию")
	first.urgent = TRUE
	first.complete(user)
	TEST_ASSERT_EQUAL(taker_account.contract_rep, 3 - ECON_CONTRACT_REP_DROP + 2, "Срочный контракт даёт две репутации")
	TEST_ASSERT_EQUAL(taker_account.contracts_done, 1, "Закрытый контракт не посчитан")

	COOLDOWN_RESET(taker_account, contract_drop_cooldown)
	taker_account.contract_rep = 8
	TEST_ASSERT_EQUAL(taker_account.contract_rank_bonus(), 10, "Надбавка надёжного подрядчика")
	econ_test_set_balance(taker_account, 0)
	TEST_ASSERT(third.take(taker_account), "Третий взят")
	var/share = round(third.payout() * SSeconomy.settings.contract_performer_share / 100)
	third.complete(user)
	TEST_ASSERT_EQUAL(taker_account.account_balance, share + round(share * 10 / 100), "Доля с надбавкой за репутацию")

	var/datum/econ_contract/delivery/late = post_scooter_contract()
	TEST_ASSERT(late.take(taker_account), "Взят")
	var/rep_before = taker_account.contract_rep
	late.deadline = world.time - 1
	late.expire()
	TEST_ASSERT(QDELETED(late), "Просроченный остался")
	TEST_ASSERT_EQUAL(taker_account.contract_rep, rep_before - ECON_CONTRACT_REP_EXPIRED, "Сорванный срок не снизил репутацию")
	var/list/rank = taker_account.contract_rank_data()
	TEST_ASSERT_EQUAL(rank["slots"], taker_account.contract_slots(), "Слоты в данных окна")

/// Повторная сдача одного заказа дешевеет до пола, спрос возвращается за возраст ротации, заказ ЦК не дешевеет.
/datum/unit_test/economy_contract_machines/board/demand/Run()
	setup()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/bounty_type = /datum/bounty/item/assistant/scooter
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/full = contract.payout()
	contract.complete()
	TEST_ASSERT_EQUAL(SSeconomy.contract_demand[bounty_type], 1, "Сдача не отмечена в спросе")
	var/datum/econ_contract/delivery/again = post_scooter_contract()
	TEST_ASSERT_EQUAL(again.payout(), round(full * (100 - settings.contract_repeat_step) / 100), "Повтор не подешевел на шаг")
	TEST_ASSERT_EQUAL(again.ui_entry()["demand"], 100 - settings.contract_repeat_step, "Спрос в данных окна")
	for(var/repeat in 1 to 10)
		SSeconomy.note_contract_demand(bounty_type)
	TEST_ASSERT_EQUAL(again.payout(), round(full * settings.contract_repeat_floor / 100), "Награда упала ниже пола")
	again.pinned = TRUE
	TEST_ASSERT_EQUAL(again.payout(), full, "Особый заказ ЦК подешевел от повторов")
	again.pinned = FALSE
	SSeconomy.contract_demand[bounty_type] = 1
	for(var/tick in 1 to settings.contract_rotation_ticks)
		SSeconomy.recover_contract_demand()
	TEST_ASSERT(!(bounty_type in SSeconomy.contract_demand), "Спрос не вернулся за возраст ротации")
	TEST_ASSERT_EQUAL(again.payout(), full, "После возврата спроса награда не полная")

/// Личные заказы видит и берёт только владелец, платят ему свою долю от сниженной награды, подборка обновляется с паузой.
/datum/unit_test/economy_contract_machines/board/personal/Run()
	setup()
	var/datum/economy_settings/settings = SSeconomy.settings
	SSeconomy.ensure_personal_offers(taker_account)
	var/list/offers = SSeconomy.personal_contracts_of(taker_account)
	TEST_ASSERT_EQUAL(length(offers), settings.contract_personal_offers, "Размер подборки")
	var/list/seen = list()
	var/list/offer_uids = list()
	for(var/datum/econ_contract/delivery/offer as anything in offers)
		offer_uids += offer.uid
		TEST_ASSERT(!(offer.bounty.type in seen), "Заказ [offer.bounty.type] повторился в подборке")
		seen += offer.bounty.type
		TEST_ASSERT(!offer.take(helper_account), "Чужой личный заказ взят")
		TEST_ASSERT(!(offer in civilian.contracts), "Личный заказ попал на доску отдела")
	var/list/board = econ_contracts_ui_data(helper, helper_account)["contracts"]
	for(var/list/entry as anything in board)
		TEST_ASSERT(!(entry["uid"] in offer_uids), "Чужой личный заказ виден в окне")
	TEST_ASSERT_EQUAL(length(SSeconomy.personal_contracts_of(helper_account)), settings.contract_personal_offers, "Открывшему доску подборка не выдана")
	var/datum/bank_account/visitor = new("econ_test_visitor")
	visitor.offstation = TRUE
	SSeconomy.ensure_personal_offers(visitor)
	TEST_ASSERT_EQUAL(length(SSeconomy.personal_contracts_of(visitor)), 0, "Счёту вне станции выданы личные заказы")
	qdel(visitor)

	TEST_ASSERT(SSeconomy.reroll_personal_offers(taker_account)[1], "Подборка не обновилась")
	for(var/datum/econ_contract/old as anything in offers)
		TEST_ASSERT(QDELETED(old), "Невзятый заказ пережил обновление подборки")
	TEST_ASSERT_EQUAL(length(SSeconomy.personal_contracts_of(taker_account)), settings.contract_personal_offers, "После обновления подборка неполная")
	TEST_ASSERT(!SSeconomy.reroll_personal_offers(taker_account)[1], "Подборка обновилась второй раз без паузы")

	var/datum/econ_contract/delivery/own = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter)
	own.set_owner(taker_account)
	SSeconomy.loose_contracts += own
	var/obj/scooter = single_item(own)
	TEST_ASSERT(!own.wants(scooter), "Невзятый личный заказ принял предмет")
	var/datum/econ_contract/delivery/public = post_scooter_contract()
	TEST_ASSERT_EQUAL(own.payout(), round(public.payout() * settings.contract_personal_reward / 100), "Награда личного заказа")
	qdel(public)
	TEST_ASSERT(own.take(taker_account), "Свой личный заказ не взят")
	var/total = own.payout()
	var/share = round(total * settings.contract_personal_share / 100)
	econ_test_set_balance(taker_account, 0)
	var/budget_before = civilian.account.account_balance
	TEST_ASSERT(econ_contracts_ship(scooter, user), "Предмет по личному заказу не засчитан")
	TEST_ASSERT_EQUAL(taker_account.account_balance, share, "Доля исполнителя личного заказа")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - budget_before, total - share, "Доля отдела с личного заказа")
	var/list/orphans = SSeconomy.personal_contracts_of(taker_account)
	QDEL_NULL(taker_account)
	for(var/datum/econ_contract/orphan as anything in orphans)
		TEST_ASSERT(QDELETED(orphan), "Личный заказ пережил счёт владельца")

/// Серия: этап платит сразу и сменяет заказ, последний платит с премией, генерация без запаса заказов даёт обычную поставку.
/datum/unit_test/economy_contract_machines/board/chain/Run()
	setup()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/econ_contract/delivery/chain/series = new(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter, list(/datum/bounty/item/assistant/skateboard, /datum/bounty/item/assistant/briefcase))
	civilian.contracts.Insert(1, series)
	TEST_ASSERT_EQUAL(series.stages_total, 3, "Этапов в серии")
	TEST_ASSERT(series.take(taker_account), "Серия не взята")
	var/share_percent = settings.contract_performer_share
	econ_test_set_balance(taker_account, 0)
	var/paid = 0
	var/stages_sum = 0
	for(var/stage in 1 to 2)
		var/stage_type = series.bounty.type
		var/stage_total = series.payout()
		var/obj/item = single_item(series)
		TEST_ASSERT(econ_contracts_ship(item, user), "Этап [stage]: предмет не засчитан")
		TEST_ASSERT(!series.completed && !QDELETED(series), "Серия закрылась на этапе [stage]")
		TEST_ASSERT_EQUAL(series.stage, stage + 1, "Этап не сменился")
		TEST_ASSERT(series.bounty.type != stage_type, "Заказ этапа не сменился")
		paid += round(stage_total * share_percent / 100)
		stages_sum += stage_total
		TEST_ASSERT_EQUAL(taker_account.account_balance, paid, "Этап [stage] не оплачен сразу")
		TEST_ASSERT_EQUAL(SSeconomy.contract_demand[stage_type], 1, "Этап [stage] не отмечен в спросе")
	TEST_ASSERT(series.has_progress(), "Начатая серия считается неначатой")
	TEST_ASSERT_EQUAL(series.ui_entry()["stage"], 3, "Этап в данных окна")
	var/obj/last = single_item(series)
	var/last_stage = round(series.reward * SSeconomy.bounty_modifier * settings.contract_delivery_mult)
	var/final_total = last_stage + round((stages_sum + last_stage) * settings.contract_chain_bonus / 100)
	TEST_ASSERT_EQUAL(series.payout(), final_total, "Последний этап без премии серии")
	TEST_ASSERT(econ_contracts_ship(last, user), "Последний этап: предмет не засчитан")
	TEST_ASSERT(series.completed, "Серия не закрыта")
	TEST_ASSERT_EQUAL(taker_account.account_balance, paid + round(final_total * share_percent / 100), "Премия серии не выплачена")
	TEST_ASSERT_EQUAL(taker_account.contract_rep, 2, "Серия даёт две репутации")

	var/datum/econ_contract/short = SSeconomy.generate_chain(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter, list(/datum/bounty/item/assistant/skateboard))
	TEST_ASSERT_EQUAL(short.type, /datum/econ_contract/delivery, "Серия собрана без запаса заказов")
	qdel(short)
	var/datum/econ_contract/delivery/chain/full = SSeconomy.generate_chain(ACCOUNT_CIV, new /datum/bounty/item/assistant/scooter, list(/datum/bounty/item/assistant/skateboard, /datum/bounty/item/assistant/briefcase))
	TEST_ASSERT(istype(full), "Серия не собрана")
	TEST_ASSERT_EQUAL(full.stages_total, ECON_CONTRACT_CHAIN_STAGES, "Длина собранной серии")
	qdel(full)

/// Контракт без исполнителя делит долю участников по вкладу, остальное получает отдел.
/datum/unit_test/economy_contract_machines/board/team_share/Run()
	setup()
	var/datum/econ_contract/delivery/contract = post_scooter_contract()
	var/datum/bounty/item/wanted = contract.bounty
	wanted.required_count = 3
	var/total = contract.payout()
	var/pool = round(total * SSeconomy.settings.contract_team_share / 100)
	econ_test_set_balance(taker_account, 0)
	econ_test_set_balance(helper_account, 0)
	var/budget_before = civilian.account.account_balance
	var/item_type = wanted.wanted_types[1]
	TEST_ASSERT(econ_contracts_ship(allocate(item_type), user), "Первый предмет")
	TEST_ASSERT(econ_contracts_ship(allocate(item_type), user), "Второй предмет")
	TEST_ASSERT_EQUAL(contract.ui_entry()["contributors"], 1, "Участники в данных окна")
	TEST_ASSERT(econ_contracts_ship(allocate(item_type), helper), "Третий предмет")
	TEST_ASSERT(contract.completed, "Контракт не закрыт")
	TEST_ASSERT_EQUAL(taker_account.account_balance, round(pool * 2 / 3), "Доля по вкладу 2 из 3")
	TEST_ASSERT_EQUAL(helper_account.account_balance, round(pool / 3), "Доля по вкладу 1 из 3")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - budget_before, total - round(pool * 2 / 3) - round(pool / 3), "Остальное отделу")
	TEST_ASSERT_EQUAL(taker_account.contract_rep, 0, "Участие без взятия дало репутацию")

	var/datum/econ_contract/delivery/anonymous = post_scooter_contract()
	budget_before = civilian.account.account_balance
	var/anonymous_total = anonymous.payout()
	TEST_ASSERT(econ_contracts_ship(single_item(anonymous)), "Отгрузка шаттлом")
	TEST_ASSERT_EQUAL(civilian.account.account_balance - budget_before, anonymous_total, "Без участников вся награда отделу")

	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/saved_engineering = engineering.account.account_balance
	var/datum/econ_contract/activity/engineering_export/shared = new(ACCOUNT_ENG)
	engineering.contracts += shared
	helper_account.department_id = ACCOUNT_ENG
	econ_test_set_balance(helper_account, 0)
	var/list/shares = shared.reward_shares(shared.payout())
	TEST_ASSERT(shares[helper_account] > 0, "Работа всего отдела не делится на отдел на смене")
	TEST_ASSERT_NULL(shares[taker_account], "Долю работы отдела получил чужой")
	var/staff = 0
	for(var/datum/bank_account/member as anything in engineering.staff_accounts())
		staff += member.state == ACCOUNT_ACTIVE
	TEST_ASSERT_EQUAL(shares[helper_account], round(shared.payout() / staff), "Доля сотрудника отдела на смене")
	helper_account.department_id = null
	qdel(shared)
	econ_test_set_balance(engineering.account, saved_engineering)

/// Объявление экипажа: депозит, взятие, сдача, отклонение, приёмка, снятие и срок.
/datum/unit_test/economy_contract_machines/board/crew_request/Run()
	setup()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/escrow_before = SSeconomy.escrow_account.account_balance
	econ_test_set_balance(taker_account, 1000)
	econ_test_set_balance(helper_account, 0)
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Починить <b>шлюз</b>", "Шлюз в баре", 200)[1], "Принят заголовок с разметкой")
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Починить шлюз", "", 200)[1], "Принято пустое описание")
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", settings.crew_request_min - 1)[1], "Принята награда ниже минимума")
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", settings.crew_request_max + 1)[1], "Принята награда выше максимума")
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", 5000)[1], "Объявление размещено без денег на депозит")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 1000, "Отказ в размещении снял деньги")
	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре не открывается", 200)[1], "Объявление не размещено")
	var/list/posted = SSeconomy.crew_requests_of(taker_account)
	TEST_ASSERT_EQUAL(length(posted), 1, "Объявление не на доске")
	var/datum/econ_contract/crew_request/request = posted[1]
	TEST_ASSERT_EQUAL(taker_account.account_balance, 800, "Депозит не списан")
	TEST_ASSERT_EQUAL(SSeconomy.escrow_account.account_balance - escrow_before, 200, "Депозит не на счёте депозитов")
	TEST_ASSERT(request.deadline, "У объявления нет срока")
	TEST_ASSERT_EQUAL(request.ui_entry()["kind"], "crew", "Вид объявления в данных окна")

	TEST_ASSERT(!request.take(taker_account), "Заказчик взял своё объявление")
	TEST_ASSERT(!request.cancel(helper_account)[1], "Чужой снял объявление")
	TEST_ASSERT(!request.report(helper_account)[1], "Работу сдал не исполнитель")
	TEST_ASSERT(request.take(helper_account), "Объявление не взято")
	TEST_ASSERT(!request.cancel(taker_account)[1], "Взятое объявление снято заказчиком")
	TEST_ASSERT(!request.reject(taker_account)[1], "Отклонена несданная работа")
	TEST_ASSERT(econ_crew_request_act(helper_account, "crew_report", request.uid)[1], "Работа не сдана")
	TEST_ASSERT(!request.report(helper_account)[1], "Работа сдана дважды")
	TEST_ASSERT(request.reject(taker_account)[1], "Работа не отклонена")
	TEST_ASSERT_NULL(request.taker, "Исполнитель остался после отклонения")
	TEST_ASSERT_EQUAL(helper_account.contract_rep, 0, "Отклонение изменило репутацию")
	request.accept_unanswered(request.report_count)
	TEST_ASSERT(!request.completed, "Отклонённая работа принята таймером")

	TEST_ASSERT(request.take(helper_account), "Объявление не взято повторно")
	TEST_ASSERT(request.report(helper_account)[1], "Работа не сдана повторно")
	TEST_ASSERT(econ_crew_request_act(taker_account, "crew_accept", request.uid)[1], "Работа не принята")
	TEST_ASSERT(QDELETED(request), "Закрытое объявление осталось")
	TEST_ASSERT_EQUAL(helper_account.account_balance, 200, "Исполнитель не получил депозит целиком")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 800, "Депозит вернулся заказчику после оплаты")
	TEST_ASSERT_EQUAL(SSeconomy.escrow_account.account_balance, escrow_before, "Депозит завис")
	TEST_ASSERT_EQUAL(helper_account.contract_rep, 1, "Объявление не дало репутацию")

	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Отнести ящик", "Ящик из карго в бар", 100)[1], "Второе объявление")
	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Накормить кота", "Кот в мостике голоден", 100)[1], "Третье объявление")
	TEST_ASSERT(!econ_post_crew_request(user, taker_account, "Ещё одно", "Сверх лимита", 100)[1], "Объявление сверх лимита на счёт")
	posted = SSeconomy.crew_requests_of(taker_account)
	var/datum/econ_contract/crew_request/cancelled = posted[1]
	var/datum/econ_contract/crew_request/timed = posted[2]
	TEST_ASSERT(cancelled.cancel(taker_account)[1], "Объявление не снято")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 700, "Депозит снятого объявления не вернулся")

	TEST_ASSERT(timed.take(helper_account), "Взято")
	TEST_ASSERT(timed.report(helper_account)[1], "Сдано")
	timed.accept_unanswered(timed.report_count)
	TEST_ASSERT(QDELETED(timed), "Сданная работа без ответа не принята")
	TEST_ASSERT_EQUAL(helper_account.account_balance, 300, "Автоприёмка не заплатила")

	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Сыграть на пианино", "В баре в полдень", 100)[1], "Объявление со сроком")
	var/datum/econ_contract/crew_request/expiring = SSeconomy.crew_requests_of(taker_account)[1]
	expiring.deadline = world.time - 1
	SSeconomy.refresh_contracts()
	TEST_ASSERT(QDELETED(expiring), "Просроченное объявление осталось")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 700, "Депозит просроченного объявления не вернулся")
	TEST_ASSERT_EQUAL(SSeconomy.escrow_account.account_balance, escrow_before, "После всех объявлений на депозите остались деньги")

/// Рабочая система оповещения станции первой в списке, с гарнитурой, которая запоминает сказанное.
/datum/unit_test/economy_contract_machines/board/proc/spy_announcer()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	qdel(announcer.radio)
	var/obj/item/radio/headset/econ_test_spy/spy = new(announcer)
	announcer.radio = spy
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	return spy

/// Отложенная строка объявления срабатывает тем же колбэком, что вызовет SStimer; таймер стоит на ECON_CREW_REQUEST_ANNOUNCE_DELAY от размещения.
/datum/unit_test/economy_contract_machines/board/proc/fire_announce(datum/econ_contract/crew_request/request)
	var/id = request.announce_timer
	var/datum/timedevent/timer = id ? SStimer.timer_id_dict[id] : null
	TEST_ASSERT_NOTNULL(timer, "Строка объявления \"[request.title]\" не поставлена в очередь радио")
	TEST_ASSERT(abs(timer.timeToRun - world.time - ECON_CREW_REQUEST_ANNOUNCE_DELAY) < 1, "Строка объявления звучит не через [DisplayTimeText(ECON_CREW_REQUEST_ANNOUNCE_DELAY)]")
	timer.callBack.Invoke()
	deltimer(id)

/// Новое объявление звучит по общему каналу не сразу, а через задержку, одной строкой с заголовком и наградой и без имени заказчика; на всю станцию не чаще общего кулдауна, от одного заказчика - не чаще личного.
/datum/unit_test/economy_contract_machines/board/crew_request_radio/Run()
	setup()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	econ_test_set_balance(taker_account, 1000)
	econ_test_set_balance(helper_account, 1000)
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	click(console, "crew_post", list("title" = "Починить шлюз", "desc" = "Шлюз в баре не открывается", "reward" = "150"))
	var/list/posted = SSeconomy.crew_requests_of(taker_account)
	TEST_ASSERT_EQUAL(length(posted), 1, "Объявление не размещено")
	TEST_ASSERT_EQUAL(length(spy.heard), 0, "Объявление прозвучало сразу, до задержки")
	fire_announce(posted[1])
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Объявление не прозвучало по радио")
	var/line = spy.heard[1]
	TEST_ASSERT(findtext(line, "общий: ") == 1, "Объявление не в общем канале: [line]")
	TEST_ASSERT(findtext(line, "Починить шлюз") && findtext(line, "150 кр."), "В строке нет заголовка и награды: [line]")
	TEST_ASSERT(!findtext(line, taker_account.account_holder), "Строка называет заказчика: [line]")

	TEST_ASSERT(econ_post_crew_request(helper, helper_account, "Сыграть на пианино", "В баре в полдень", 100)[1], "Объявление другого заказчика не размещено")
	fire_announce(SSeconomy.crew_requests_of(helper_account)[1])
	TEST_ASSERT_EQUAL(length(spy.heard), 1, "Объявление прозвучало, пока общий канал на кулдауне")

	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	var/list/answer = econ_post_crew_request(user, taker_account, "Накормить кота", "Кот в баре голоден", 100)
	TEST_ASSERT(answer[1], "Второе объявление заказчика не размещено: [answer[2]]")
	var/datum/econ_contract/crew_request/second = SSeconomy.crew_requests_of(taker_account)[2]
	TEST_ASSERT_NULL(second.announce_timer, "Второе объявление заказчика ушло в эфир раньше личного кулдауна")
	TEST_ASSERT(findtext(answer[2], "не чаще раза в [SSeconomy.settings.crew_request_personal_announce_minutes] мин."), "Заказчику не сказали, почему объявление не прозвучит: [answer[2]]")
	TEST_ASSERT(!second.announce(), "Объявление в личный кулдаун заказчика прозвучало")

	TEST_ASSERT(econ_post_crew_request(helper, helper_account, "Спеть в баре", "Вечером", 100)[1], "Второе объявление другого заказчика не размещено")
	fire_announce(SSeconomy.crew_requests_of(helper_account)[2])
	TEST_ASSERT_EQUAL(length(spy.heard), 2, "Объявление другого заказчика после общего кулдауна не прозвучало")
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)

/// Телеком-узел, который запоминает пойманные сигналы ("частота: сообщение") и дальше их не передаёт.
/obj/machinery/telecomms/allinone/econ_test_ear
	var/list/caught = list()

/obj/machinery/telecomms/allinone/econ_test_ear/receive_signal(datum/signal/subspace/signal)
	caught += "[signal.frequency]: [signal.data["message"]]"

/// Строка объявления уходит в эфир настоящей гарнитурой системы оповещения на общей частоте: у её ключа ИИ нет канала с именем общего, общий канал - частота по умолчанию.
/datum/unit_test/economy_contract_machines/board/crew_request_radio_on_air/Run()
	setup()
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	econ_test_set_balance(taker_account, 1000)
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/obj/machinery/announcement_system/announcer = allocate(/obj/machinery/announcement_system, locate(2, 2, station_z))
	announcer.machine_stat = NONE
	GLOB.announcement_systems -= announcer
	GLOB.announcement_systems.Insert(1, announcer)
	var/obj/machinery/telecomms/allinone/econ_test_ear/ear = allocate(/obj/machinery/telecomms/allinone/econ_test_ear, run_loc_floor_bottom_left)
	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", 150)[1], "Объявление не размещено")
	fire_announce(SSeconomy.crew_requests_of(taker_account)[1])
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	TEST_ASSERT_EQUAL(length(ear.caught), 1, "Строка объявления не ушла в эфир")
	var/line = ear.caught[1]
	TEST_ASSERT(findtext(line, "[FREQ_COMMON]: ") == 1 && findtext(line, "Починить шлюз"), "В эфире не та строка или не та частота: [line]")

/// Объявление, снятое или взятое до строки по радио, в эфир не попадает и общий канал не занимает; снятое уносит строку из очереди.
/datum/unit_test/economy_contract_machines/board/crew_request_radio_withdrawn/Run()
	setup()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	econ_test_set_balance(taker_account, 1000)
	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", 150)[1], "Объявление не размещено")
	var/datum/econ_contract/crew_request/cancelled = SSeconomy.crew_requests_of(taker_account)[1]
	var/timer_id = cancelled.announce_timer
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timer_id], "Строка объявления не в очереди радио")
	TEST_ASSERT(cancelled.cancel(taker_account)[1], "Объявление не снято")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer_id], "Снятое объявление осталось в очереди радио")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 1000, "Депозит снятого объявления не вернулся")

	TEST_ASSERT(econ_post_crew_request(user, taker_account, "Накормить кота", "Кот в баре голоден", 100)[1], "Второе объявление не размещено")
	var/datum/econ_contract/crew_request/taken = SSeconomy.crew_requests_of(taker_account)[1]
	TEST_ASSERT(taken.take(helper_account), "Объявление не взято")
	fire_announce(taken)
	TEST_ASSERT_EQUAL(length(spy.heard), 0, "Взятое объявление прозвучало по радио")
	TEST_ASSERT(COOLDOWN_FINISHED(SSeconomy, crew_request_announce_cooldown), "Непрозвучавшая строка заняла общий канал")
	TEST_ASSERT(COOLDOWN_FINISHED(taker_account, crew_request_announce_cooldown), "Непрозвучавшая строка начала личный кулдаун заказчика")

/// Игрок с мутом IC не даёт объявлений и не выставляет вещь на аукцион экипажа - обе строки звучат по общему каналу; мут после размещения глушит отложенную строку.
/datum/unit_test/economy_contract_machines/board/crew_request_muted/Run()
	setup()
	var/obj/item/radio/headset/econ_test_spy/spy = spy_announcer()
	COOLDOWN_RESET(SSeconomy, crew_request_announce_cooldown)
	econ_test_set_balance(taker_account, 1000)
	var/datum/client_interface/mock = new
	mock.prefs = new /datum/preferences
	allocated += mock.prefs
	mock.prefs.muted = MUTE_IC
	user.mock_client = mock
	var/list/answer = econ_post_crew_request(user, taker_account, "Починить шлюз", "Шлюз в баре", 150)
	var/obj/item/toy/plush/thing = allocate(/obj/item/toy/plush, run_loc_floor_bottom_left)
	var/list/lot_answer = SSmarket.start_crew_lot(user, taker_account, thing, 100, 10, FALSE, run_loc_floor_bottom_left)
	user.mock_client = null
	TEST_ASSERT(!answer[1] && findtext(answer[2], "IC"), "Объявление с мутом IC размещено: [answer[2]]")
	TEST_ASSERT_EQUAL(length(SSeconomy.crew_requests_of(taker_account)), 0, "Объявление с мутом IC на доске")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 1000, "Отказ с мутом взял депозит")
	TEST_ASSERT(!lot_answer[1] && findtext(lot_answer[2], "IC"), "Лот с мутом IC выставлен: [lot_answer[2]]")

	mock.prefs.muted = NONE
	user.mock_client = mock
	answer = econ_post_crew_request(user, taker_account, "Накормить кота", "Кот в баре голоден", 100)
	TEST_ASSERT(answer[1], "Объявление без мута не размещено: [answer[2]]")
	mock.prefs.muted = MUTE_IC
	fire_announce(SSeconomy.crew_requests_of(taker_account)[1])
	user.mock_client = null
	TEST_ASSERT_EQUAL(length(spy.heard), 0, "Объявление прозвучало, хотя заказчика замутили до строки")

/// Действия доски идут с консоли контрактов, а заказы без источника на станции на доску не попадают.
/datum/unit_test/economy_contract_machines/board/console_acts/Run()
	setup()
	econ_test_set_balance(taker_account, 500)
	var/obj/machinery/computer/bounty/console = allocate(/obj/machinery/computer/bounty)
	click(console, "crew_post", list("title" = "Починить шлюз", "desc" = "Шлюз в баре не открывается", "reward" = "150"))
	var/list/posted = SSeconomy.crew_requests_of(taker_account)
	TEST_ASSERT_EQUAL(length(posted), 1, "Объявление с консоли не размещено")
	var/datum/econ_contract/crew_request/request = posted[1]
	click(console, "crew_cancel", list("uid" = request.uid))
	TEST_ASSERT(QDELETED(request), "Объявление с консоли не снято")
	TEST_ASSERT_EQUAL(taker_account.account_balance, 500, "Депозит не вернулся")
	SSeconomy.ensure_personal_offers(taker_account)
	var/datum/econ_contract/old_offer = SSeconomy.personal_contracts_of(taker_account)[1]
	click(console, "reroll")
	TEST_ASSERT(QDELETED(old_offer), "Подборка с консоли не обновилась")
	var/list/by_department = econ_bounty_types_by_department()
	for(var/department_id in by_department)
		TEST_ASSERT(!(/datum/bounty/item/assistant/cheesiehonkers in by_department[department_id]), "Заказ без источника на станции попадает на доску [department_id]")
