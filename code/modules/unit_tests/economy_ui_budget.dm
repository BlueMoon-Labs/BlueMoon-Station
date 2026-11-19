/datum/unit_test/economy_ui_budget
	abstract_type = /datum/unit_test/economy_ui_budget
	var/list/stashed_contracts
	var/list/saved_balances = list()
	var/list/saved_requests = list()
	var/list/saved_auto_approve = list()
	var/list/saved_shares = list()
	var/list/saved_shoppinglist
	var/list/saved_treasury_requests
	var/saved_tax_rate

/datum/unit_test/economy_ui_budget/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		saved_balances[id] = department.account.account_balance
		saved_requests[id] = department.requests
		department.requests = list()
		saved_auto_approve[id] = department.auto_approve_after
		department.auto_approve_after = list()
		saved_shares[id] = department.register_cashier_share
	saved_shoppinglist = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()
	saved_treasury_requests = SSeconomy.treasury_requests
	SSeconomy.treasury_requests = list()
	saved_tax_rate = SSeconomy.tax_rate
	SSeconomy.tax_rate = 0

/datum/unit_test/economy_ui_budget/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	for(var/id in saved_balances)
		var/datum/economy_department/department = SSeconomy.departments[id]
		econ_test_set_balance(department.account, saved_balances[id])
		QDEL_LIST(department.requests)
		department.requests = saved_requests[id]
		department.auto_approve_after = saved_auto_approve[id]
		department.register_cashier_share = saved_shares[id]
	QDEL_LIST(SSshuttle.shoppinglist)
	SSshuttle.shoppinglist += saved_shoppinglist
	QDEL_LIST(SSeconomy.treasury_requests)
	SSeconomy.treasury_requests = saved_treasury_requests
	SSeconomy.tax_rate = saved_tax_rate
	return ..()

/datum/unit_test/economy_ui_budget/proc/make_staff(department_id, list/access)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human)
	var/datum/bank_account/account = new("econ_test_[department_id]")
	account.department_id = department_id
	account.pay_grade = PAY_GRADE_EASY
	staff.account_id = account.account_id
	allocated += account
	if(access)
		var/obj/item/card/id/card = allocate(/obj/item/card/id)
		card.access = access
		staff.put_in_hands(card)
	return staff

/// КПК в руке с приложением бюджета: оно стоит с завода, у КПК без жёсткого диска его ставят как скачанное.
/datum/unit_test/economy_ui_budget/proc/give_pda(mob/living/carbon/human/owner, pda_type = /obj/item/modular_computer/pda)
	var/obj/item/modular_computer/pda/pda = allocate(pda_type)
	owner.put_in_hands(pda)
	var/datum/computer_file/program/department_budget/program = locate() in pda.get_all_files()
	if(!program)
		program = new
		var/obj/item/computer_hardware/hard_drive/drive = pda.all_components[MC_HDD]
		if(drive)
			drive.store_file(program)
		else
			pda.store_file(program)
	return program

/datum/unit_test/economy_ui_budget/proc/press(mob/living/user, datum/host, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, host, "NtosDepartmentBudget")
	window.status = UI_INTERACTIVE
	usr = user
	host.ui_act(action, params, window)
	usr = null
	var/datum/computer_file/program/department_budget/program = host
	if(istype(host, /obj/machinery/computer/department_budget))
		var/obj/machinery/computer/department_budget/console = host
		program = console.program
	return program.messages[REF(user)]

/datum/unit_test/economy_ui_budget/proc/pack_above_auto_limit(datum/economy_department/department)
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(!econ_pack_unavailable(pack) && !econ_pack_staple(pack) && econ_pack_price(pack) > SSeconomy.settings.auto_approve_limit)
			return pack

/datum/unit_test/economy_ui_budget/proc/available_pack(datum/economy_department/department)
	for(var/datum/supply_pack/pack as anything in department.catalog())
		if(!econ_pack_unavailable(pack))
			return pack

/// Сотрудник подаёт заявку из КПК, сам одобрить её не может даже с флагом автоодобрения; глава одобряет из своего КПК.
/datum/unit_test/economy_ui_budget/pda_request_approve/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/mob/living/carbon/human/worker = make_staff(ACCOUNT_MED)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/datum/computer_file/program/department_budget/worker_app = give_pda(worker)
	var/datum/computer_file/program/department_budget/chief_app = give_pda(chief, /obj/item/modular_computer/pda/heads/cmo)
	var/datum/supply_pack/pack = pack_above_auto_limit(medical)
	TEST_ASSERT_NOTNULL(pack, "В каталоге медицины есть пак дороже автоодобрения")
	var/price = round(econ_pack_price(pack))
	econ_test_set_balance(medical.account, price + 100)
	press(worker, worker_app, "request", list("pack" = "[pack.type]", "reason" = "Кончились бинты"))
	TEST_ASSERT_EQUAL(length(medical.requests), 1, "Заявка подана")
	var/datum/econ_request/request = medical.requests[1]
	TEST_ASSERT_EQUAL(request.reason, "Кончились бинты", "Причина сохранена")
	var/refusal = press(worker, worker_app, "approve", list("uid" = "[request.uid]", "automatic" = 1))
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_PENDING, "Сотрудник не одобряет даже с automatic")
	TEST_ASSERT_EQUAL(refusal, "Это может только глава отдела, ГП, капитан, ИИ или, если заявку передали снабжению, его начальник.", "Отказ объяснён")
	press(chief, chief_app, "approve", list("uid" = "[request.uid]"))
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Глава одобрил")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 100, "Бюджет оплатил заказ")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Заказ в очереди снабжения")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	TEST_ASSERT_EQUAL(order.department_id, ACCOUNT_MED, "Заказ предоплачен медициной")
	var/repeat = press(chief, chief_app, "deny", list("uid" = "[request.uid]"))
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Решённая заявка не меняется")
	TEST_ASSERT_EQUAL(repeat, "Заявка не найдена или уже решена.", "Повтор объяснён")

/// Заказать и подать заявку можно только на пак из каталога своего отдела; строка пути из клиента проверяется по каталогу.
/datum/unit_test/economy_ui_budget/catalog_guard/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/datum/economy_department/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/mob/living/carbon/human/worker = make_staff(ACCOUNT_MED)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/datum/computer_file/program/department_budget/worker_app = give_pda(worker)
	var/datum/computer_file/program/department_budget/chief_app = give_pda(chief, /obj/item/modular_computer/pda/heads/cmo)
	var/datum/supply_pack/foreign = available_pack(science)
	var/datum/supply_pack/own = available_pack(medical)
	econ_test_set_balance(medical.account, 100000)
	for(var/bad_pack in list("[foreign.type]", "/obj/item/gun", "/datum/supply_pack", 12))
		var/refusal = press(chief, chief_app, "order", list("pack" = bad_pack))
		TEST_ASSERT_EQUAL(refusal, "Этого нет в каталоге отдела.", "Пак [bad_pack] не из каталога отвергнут")
		press(worker, worker_app, "request", list("pack" = bad_pack, "reason" = "тест"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Чужие паки не заказаны")
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Заявок на чужие паки нет")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 100000, "Бюджет не тронут")
	var/worker_order = press(worker, worker_app, "order", list("pack" = "[own.type]"))
	TEST_ASSERT_EQUAL(worker_order, "Это может только глава отдела, ГП или капитан.", "Сотрудник не заказывает напрямую")
	press(chief, chief_app, "order", list("pack" = "[own.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Глава заказал пак своего каталога")
	TEST_ASSERT_EQUAL(medical.account.account_balance, 100000 - round(econ_pack_price(own)), "Заказ списан с бюджета")

/// Премия, надбавка, доля кассира и запрос в казну - из КПК главы; сотруднику отказ, запрос в казну этим окном не одобряется.
/datum/unit_test/economy_ui_budget/head_money_actions/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/mob/living/carbon/human/engineer = make_staff(ACCOUNT_ENG)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	var/datum/computer_file/program/department_budget/chief_app = give_pda(chief, /obj/item/modular_computer/pda/heads/ce)
	var/datum/computer_file/program/department_budget/engineer_app = give_pda(engineer)
	var/datum/bank_account/member = econ_account_of(engineer)
	var/datum/bank_account/outsider = econ_account_of(doctor)
	econ_test_set_balance(engineering.account, 1000)
	press(engineer, engineer_app, "bonus", list("number" = "[member.account_id]", "amount" = "300"))
	press(engineer, engineer_app, "register_share", list("percent" = "90"))
	TEST_ASSERT_EQUAL(member.account_balance, 0, "Сотрудник не выписывает премию")
	TEST_ASSERT_EQUAL(engineering.register_cashier_share, saved_shares[ACCOUNT_ENG], "Сотрудник не меняет долю кассира")
	press(chief, chief_app, "bonus", list("number" = "[outsider.account_id]", "amount" = "300"))
	TEST_ASSERT_EQUAL(outsider.account_balance, 0, "Премия чужому отделу не выписана")
	press(chief, chief_app, "bonus", list("number" = "[member.account_id]", "amount" = "300"))
	TEST_ASSERT_EQUAL(member.account_balance, 300, "Премия выписана")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, 700, "Премия из бюджета")
	press(chief, chief_app, "wage_bonus", list("number" = "[member.account_id]", "percent" = "20"))
	TEST_ASSERT_EQUAL(member.wage_bonus, 20, "Надбавка выставлена")
	press(chief, chief_app, "wage_bonus", list("number" = "[member.account_id]", "percent" = "1000"))
	TEST_ASSERT_EQUAL(member.wage_bonus, SSeconomy.settings.max_wage_bonus, "Надбавка не выше потолка")
	press(chief, chief_app, "register_share", list("percent" = "30"))
	TEST_ASSERT_EQUAL(engineering.register_cashier_share, 30, "Доля кассира выставлена")
	var/long_reason = "<b>Ремонт</b>"
	for(var/i in 1 to ECON_REQUEST_REASON_MAX)
		long_reason += "щ"
	press(chief, chief_app, "treasury_request", list("amount" = "700", "reason" = long_reason))
	TEST_ASSERT_EQUAL(length(SSeconomy.treasury_requests), 1, "Запрос в казну подан")
	var/datum/econ_request/treasury/request = SSeconomy.treasury_requests[1]
	TEST_ASSERT_EQUAL(request.amount, 700, "Сумма запроса")
	TEST_ASSERT(length_char(request.reason) <= ECON_REQUEST_REASON_MAX, "Причина обрезана: [length_char(request.reason)]")
	TEST_ASSERT(!findtext(request.reason, "<") && !findtext(request.reason, ">"), "Причина очищена от разметки")
	TEST_ASSERT_EQUAL(copytext_char(request.reason, 1, 7), "Ремонт", "Текст причины сохранён")
	for(var/action in list("resolve_treasury_request", "approve_treasury"))
		press(chief, chief_app, action, list("uid" = "[request.uid]", "approve" = 1))
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_PENDING, "Окно бюджета не одобряет запросы в казну")
	TEST_ASSERT_EQUAL(engineering.account.account_balance, 700, "Казна ничего не перевела")

/// Глава не ставит надбавку на свой счёт: отказ, как у казны на свой оклад.
/datum/unit_test/economy_ui_budget/no_self_wage_bonus/Run()
	var/datum/economy_department/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_ENG, list(ACCESS_CE))
	var/datum/bank_account/own = econ_account_of(chief)
	own.bind_owner(chief)
	var/datum/computer_file/program/department_budget/chief_app = give_pda(chief, /obj/item/modular_computer/pda/heads/ce)
	var/refusal = press(chief, chief_app, "wage_bonus", list("number" = "[own.account_id]", "percent" = "50"))
	TEST_ASSERT_EQUAL(own.wage_bonus, 0, "Глава поставил надбавку себе")
	TEST_ASSERT_EQUAL(refusal, "Свой счёт так менять нельзя.", "Отказ не объяснён")
	own.owner_ref = null
	TEST_ASSERT(!engineering.set_wage_bonus(own, 50, chief), "Надбавка на счёт, куда главе платят, прошла")

/// "Нужно сейчас": раненые и обескровленные на станции поднимают кровь и медикаменты первыми, блюдо дня - продукты под его рецепт; не больше ECON_NEEDS_MAX паков каталога, пересчёт не чаще ECON_NEEDS_REFRESH; окно отдаёт их вместе с советами отдела.
/datum/unit_test/economy_ui_budget/needs_now
	var/saved_dish

/datum/unit_test/economy_ui_budget/needs_now/New()
	. = ..()
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	saved_dish = service.dish_of_the_day

/datum/unit_test/economy_ui_budget/needs_now/Destroy()
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	service.dish_of_the_day = saved_dish
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		department.needs_cache_until = 0
	return ..()

/datum/unit_test/economy_ui_budget/needs_now/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		department.needs_cache_until = 0
		var/list/needs = department.needs_now()
		var/list/packs = department.catalog()
		TEST_ASSERT(length(needs) <= ECON_NEEDS_MAX, "[id]: нужно сейчас больше [ECON_NEEDS_MAX]")
		TEST_ASSERT(length(needs) >= min(ECON_NEEDS_MIN, length(packs)), "[id]: нужно сейчас меньше [ECON_NEEDS_MIN]: [length(needs)]")
		for(var/pack_type in needs)
			TEST_ASSERT(SSshuttle.supply_packs[pack_type] in packs, "[id]: [pack_type] не из каталога отдела")
		if(length(packs))
			TEST_ASSERT(length(department.spending_advice()), "[id]: нет совета, на что тратить бюджет")
	var/list/before = medical.needs_now()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, locate(3, 3, station_z))
	patient.mind_initialize()
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under/color/grey)
	uniform.has_sensor = HAS_SENSORS
	uniform.sensor_mode = SENSOR_VITALS
	patient.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	patient.adjustBruteLoss(ECON_NEEDS_INJURED_DAMAGE + 10)
	patient.blood_volume = BLOOD_VOLUME_SAFE / 2
	TEST_ASSERT(medical.needs_now() == before, "Пересчитано раньше ECON_NEEDS_REFRESH")
	medical.needs_cache_until = 0
	var/list/needs = medical.needs_now()
	TEST_ASSERT(!econ_pack_unavailable(SSshuttle.supply_packs[/datum/supply_pack/medical/bloodpacks]), "Кровь есть у партнёров")
	TEST_ASSERT_EQUAL(needs[1], /datum/supply_pack/medical/bloodpacks, "Кровь первой, когда у экипажа её мало: [json_encode(needs)]")
	TEST_ASSERT(findtext(needs[/datum/supply_pack/medical/bloodpacks], "Мало крови у "), "Почему нужна кровь: [needs[/datum/supply_pack/medical/bloodpacks]]")
	TEST_ASSERT(findtext(needs[/datum/supply_pack/medical/supplies], "Раненых на станции: "), "Почему нужны медикаменты: [needs[/datum/supply_pack/medical/supplies]]")
	var/mob/living/carbon/human/cmo = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/datum/computer_file/program/department_budget/app = give_pda(cmo, /obj/item/modular_computer/pda/heads/cmo)
	var/list/shown = app.budget_data(cmo)["needs"]
	var/list/first = shown[1]
	TEST_ASSERT(first["type"] == "[/datum/supply_pack/medical/bloodpacks]" && first["why"] == needs[/datum/supply_pack/medical/bloodpacks], "Окно показывает нужное сейчас: [json_encode(shown)]")
	TEST_ASSERT_EQUAL(json_encode(app.budget_static_data(cmo)["advice"]), json_encode(medical.spending_advice()), "Окно показывает советы отдела")
	var/datum/economy_department/service/service = SSeconomy.get_department(ACCOUNT_SRV)
	var/tomato = /obj/item/reagent_containers/food/snacks/grown/tomato
	var/datum/crafting_recipe/food/tomato_dish
	for(var/datum/crafting_recipe/food/recipe in GLOB.crafting_recipes)
		if(recipe.always_availible && (tomato in recipe.reqs))
			tomato_dish = recipe
			break
	TEST_ASSERT_NOTNULL(tomato_dish, "Есть блюдо с помидором")
	service.dish_of_the_day = tomato_dish.result
	service.needs_cache_until = 0
	var/obj/item/dish = tomato_dish.result
	TEST_ASSERT_EQUAL(service.situational_needs()[/datum/supply_pack/organic/randomized/vegetables], "Блюдо дня: [initial(dish.name)]", "Под блюдо дня с помидором - овощи")

/// Ответ на заявку объясняет, почему она ждёт: сколько денег в бюджете против цены пака и через сколько минут недорогая снова пройдёт без одобрения.
/datum/unit_test/economy_ui_budget/request_answer/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/mob/living/carbon/human/worker = make_staff(ACCOUNT_MED)
	var/datum/computer_file/program/department_budget/app = give_pda(worker)
	var/datum/supply_pack/cheap
	for(var/datum/supply_pack/pack as anything in medical.catalog())
		if(!econ_pack_unavailable(pack) && medical.auto_approvable(pack))
			cheap = pack
			break
	TEST_ASSERT_NOTNULL(cheap, "Есть недорогой пак медицины")
	var/price = round(econ_pack_price(cheap))
	econ_test_set_balance(medical.account, 0)
	var/answer = press(worker, app, "request", list("pack" = "[cheap.type]", "reason" = "тест"))
	TEST_ASSERT(findtext(answer, "В бюджете сейчас 0 кр., пак стоит [price] кр."), "Ответ не называет деньги и цену: [answer]")
	TEST_ASSERT(!findtext(answer, ".."), "В ответе две точки подряд: [answer]")
	econ_test_set_balance(medical.account, price * 10 + medical.owed_to_staff())
	var/datum/bank_account/account = econ_account_of(worker)
	medical.auto_approve_after["[account.account_id]"] = world.time + 5 MINUTES
	answer = press(worker, app, "request", list("pack" = "[cheap.type]", "reason" = "тест"))
	TEST_ASSERT(findtext(answer, "Без одобрения снова через 5 мин."), "Ответ не называет перерыв: [answer]")
	TEST_ASSERT(!findtext(answer, "В бюджете сейчас"), "Ответ жалуется на деньги, которых хватает: [answer]")

/// Прайс работы в окне, подсказка о премии и осмотры называют оплату с поправкой на настроение экипажа.
/datum/unit_test/economy_ui_budget/mood_prices/Run()
	var/saved_mood = SSeconomy.tax_mood
	SSeconomy.tax_mood = TAX_MOOD_UNREST
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/datum/computer_file/program/department_budget/app = give_pda(chief, /obj/item/modular_computer/pda/heads/cmo)
	var/list/data = app.budget_data(chief)
	var/obj/item/healthanalyzer/analyzer = allocate(/obj/item/healthanalyzer)
	var/examine = analyzer.econ_discharge_examine()
	SSeconomy.tax_mood = TAX_MOOD_GOODWILL
	var/goodwill_share = app.budget_data(chief)["work_share"]
	SSeconomy.tax_mood = saved_mood
	var/datum/economy_settings/settings = SSeconomy.settings
	var/mult = (100 - settings.tax_unrest_work_cut) / 100
	var/list/surgery
	for(var/list/work as anything in data["work_prices"])
		if(work["name"] == econ_work_name(WORK_MED_SURGERY))
			surgery = work
	TEST_ASSERT_NOTNULL(surgery, "В прайсе нет операции")
	TEST_ASSERT_EQUAL(surgery["price"], round(settings.work_prices[WORK_MED_SURGERY] * mult, 0.01), "Прайс не учитывает недовольство")
	TEST_ASSERT(findtext(examine, "[round(settings.work_prices[WORK_MED_DISCHARGE_LIGHT] * mult, 0.01)],"), "Осмотр анализатора не учитывает недовольство: [examine]")
	TEST_ASSERT_EQUAL(goodwill_share, settings.work_personal_share + settings.tax_goodwill_premium_bonus, "Подсказка о премии не учитывает довольство")

/// "Нужно сейчас" медицины видит экипаж только датчиками костюма, как монитор экипажа: раны и кровь - от SENSOR_VITALS, смерть - от SENSOR_LIVING; дефибриллятор - пока погибшего можно поднять, мешки - для тел вне морга и мешков. О новой нужде канал отдела слышит раз в ECON_NEEDS_ALERT_COOLDOWN и только при сотрудниках на смене.
/datum/unit_test/economy_ui_budget/needs_sensors
	var/list/saved_alerted

/datum/unit_test/economy_ui_budget/needs_sensors/New()
	. = ..()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	saved_alerted = medical.alerted_needs
	medical.alerted_needs = list()
	medical.needs_alert_cooldown = 0

/datum/unit_test/economy_ui_budget/needs_sensors/Destroy()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	medical.alerted_needs = saved_alerted
	medical.needs_alert_cooldown = 0
	medical.needs_cache_until = 0
	return ..()

/datum/unit_test/economy_ui_budget/needs_sensors/Run()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, locate(3, 3, station_z))
	patient.mind_initialize()
	patient.adjustBruteLoss(ECON_NEEDS_INJURED_DAMAGE + 10)
	patient.blood_volume = BLOOD_VOLUME_SAFE / 2
	var/list/needs = medical.situational_needs()
	TEST_ASSERT(!needs[/datum/supply_pack/medical/supplies] && !needs[/datum/supply_pack/medical/bloodpacks], "Раненый без датчиков виден: [json_encode(needs)]")
	var/obj/item/clothing/under/uniform = allocate(/obj/item/clothing/under/color/grey)
	uniform.has_sensor = HAS_SENSORS
	uniform.sensor_mode = SENSOR_LIVING
	TEST_ASSERT(patient.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Комбинезон надет")
	needs = medical.situational_needs()
	TEST_ASSERT(!needs[/datum/supply_pack/medical/supplies], "Раны видны датчиком жизни: [json_encode(needs)]")
	uniform.sensor_mode = SENSOR_VITALS
	needs = medical.situational_needs()
	TEST_ASSERT(needs[/datum/supply_pack/medical/supplies] && needs[/datum/supply_pack/medical/bloodpacks], "Раны и кровь по датчикам не видны: [json_encode(needs)]")

	var/list/stats = list(ACCOUNT_MED = list("on_shift" = 1))
	var/alert = medical.announce_new_needs(stats)
	TEST_ASSERT(findtext(alert, "Отдел \"[medical.name]\", нужно сейчас: ") && findtext(alert, "Раненых на станции: "), "Канал не услышал о раненых: [alert]")
	TEST_ASSERT_NULL(medical.announce_new_needs(stats), "О той же нужде объявили снова")

	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, locate(4, 3, station_z))
	corpse.mind_initialize()
	var/obj/item/clothing/under/corpse_uniform = allocate(/obj/item/clothing/under/color/grey)
	corpse_uniform.has_sensor = HAS_SENSORS
	corpse_uniform.sensor_mode = SENSOR_LIVING
	corpse.equip_to_slot_if_possible(corpse_uniform, ITEM_SLOT_ICLOTHING)
	corpse.death()
	needs = medical.situational_needs()
	TEST_ASSERT(findtext(needs[/datum/supply_pack/medical/defibs], "Погибших недавно: "), "Свежий погибший не просит дефибриллятор: [json_encode(needs)]")
	TEST_ASSERT(findtext(needs[/datum/supply_pack/medical/bodybags], "Тел вне морга и мешков: "), "Тело вне морга не просит мешок: [json_encode(needs)]")
	TEST_ASSERT_NULL(medical.announce_new_needs(stats), "Новая нужда объявлена раньше кулдауна")
	medical.needs_alert_cooldown = 0
	TEST_ASSERT_NULL(medical.announce_new_needs(list(ACCOUNT_MED = list("on_shift" = 0))), "Объявили в отдел без сотрудников на смене")
	alert = medical.announce_new_needs(stats)
	TEST_ASSERT(findtext(alert, "Погибших недавно: ") && !findtext(alert, "Раненых на станции: "), "Канал услышал не только новую нужду: [alert]")

	var/obj/item/shockpaddles/paddles = /obj/item/shockpaddles
	corpse.timeofdeath = world.time - initial(paddles.tlimit) - 1
	var/obj/structure/closet/body_bag/bag = allocate(/obj/structure/closet/body_bag, corpse.loc)
	corpse.forceMove(bag)
	needs = medical.situational_needs()
	TEST_ASSERT(!needs[/datum/supply_pack/medical/defibs], "Давно погибший просит дефибриллятор")
	TEST_ASSERT(!needs[/datum/supply_pack/medical/bodybags], "Тело в мешке просит мешок")
	corpse.forceMove(get_turf(bag))

/// ГП и капитан переключают отдел, глава другого отдела - нет; грант на исследования покупает только наука.
/datum/unit_test/economy_ui_budget/switch_and_grant
	var/list/saved_points
	var/saved_grant_start
	var/saved_grant_points

/datum/unit_test/economy_ui_budget/switch_and_grant/New()
	. = ..()
	saved_points = SSresearch.science_tech.research_points.Copy()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	saved_grant_start = science.grant_window_start
	saved_grant_points = science.grant_points_in_window

/datum/unit_test/economy_ui_budget/switch_and_grant/Destroy()
	SSresearch.science_tech.research_points = saved_points
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	science.grant_window_start = saved_grant_start
	science.grant_points_in_window = saved_grant_points
	return ..()

/datum/unit_test/economy_ui_budget/switch_and_grant/Run()
	var/datum/economy_department/science/science = SSeconomy.get_department(ACCOUNT_SCI)
	var/mob/living/carbon/human/captain = make_staff(ACCOUNT_CMD, list(ACCESS_CAPTAIN))
	var/mob/living/carbon/human/cmo = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/mob/living/carbon/human/director = make_staff(ACCOUNT_SCI, list(ACCESS_RD))
	var/datum/computer_file/program/department_budget/captain_app = give_pda(captain, /obj/item/modular_computer/pda/heads/captain)
	var/datum/computer_file/program/department_budget/cmo_app = give_pda(cmo, /obj/item/modular_computer/pda/heads/cmo)
	var/datum/computer_file/program/department_budget/director_app = give_pda(director, /obj/item/modular_computer/pda/heads/rd)
	var/list/data = captain_app.budget_data(captain)
	TEST_ASSERT(!data["has_department"], "Казна командования не открывается окном отдела")
	TEST_ASSERT(data["can_switch"], "Капитан переключает отделы")
	press(captain, captain_app, "select_department", list("id" = ACCOUNT_SCI))
	data = captain_app.budget_data(captain)
	var/list/department = data["department"]
	TEST_ASSERT_EQUAL(department["id"], ACCOUNT_SCI, "Капитан открыл науку")
	var/list/static_data = captain_app.budget_static_data(captain)
	var/list/catalog = static_data["catalog"]
	TEST_ASSERT_EQUAL(length(catalog), length(science.catalog()), "Каталог выбранного отдела")
	press(captain, captain_app, "select_department", list("id" = ACCOUNT_CMD))
	TEST_ASSERT_EQUAL(captain_app.selections[REF(captain)], ACCOUNT_SCI, "Казну не выбрать")
	captain_app.ui_close(captain)
	TEST_ASSERT(!(REF(captain) in captain_app.selections), "Выбор отдела забыт при закрытии окна")
	var/refusal = press(cmo, cmo_app, "select_department", list("id" = ACCOUNT_SCI))
	TEST_ASSERT_EQUAL(refusal, "Переключать отделы могут только ГП и капитан.", "Глава отдела не переключает")
	data = cmo_app.budget_data(cmo)
	department = data["department"]
	TEST_ASSERT_EQUAL(department["id"], ACCOUNT_MED, "Главврач остался в медицине")
	var/price = SSeconomy.settings.research_grant_price_per_point
	econ_test_set_balance(science.account, price * 100)
	science.grant_window_start = world.time
	science.grant_points_in_window = 0
	var/points_before = SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC]
	var/not_science = press(cmo, cmo_app, "research_grant", list("points" = "100"))
	TEST_ASSERT_EQUAL(not_science, "Грант на исследования покупает только наука.", "Медицина гранта не покупает")
	press(director, director_app, "research_grant", list("points" = "100"))
	TEST_ASSERT_EQUAL(SSresearch.science_tech.research_points[TECHWEB_POINT_TYPE_GENERIC] - points_before, 100, "Грант начислен")
	TEST_ASSERT_EQUAL(science.account.account_balance, 0, "Грант оплачен бюджетом науки")
	data = director_app.budget_data(director)
	TEST_ASSERT_EQUAL(data["grant_left"], SSeconomy.settings.research_grant_cap_hour - 100, "Остаток часового лимита")

/// Консоль отдела: подтипы привязаны к отделам, заявка и одобрение идут через неё, чужой сотрудник заявку не подаёт, накладная печатается; удаление чистит программу.
/datum/unit_test/economy_ui_budget/console/Run()
	var/list/bound = list(
		/obj/machinery/computer/department_budget/medical = ACCOUNT_MED,
		/obj/machinery/computer/department_budget/engineering = ACCOUNT_ENG,
		/obj/machinery/computer/department_budget/science = ACCOUNT_SCI,
		/obj/machinery/computer/department_budget/security = ACCOUNT_SEC,
		/obj/machinery/computer/department_budget/service = ACCOUNT_SRV,
		/obj/machinery/computer/department_budget/cargo = ACCOUNT_CAR,
	)
	for(var/console_type in bound)
		var/obj/machinery/computer/department_budget/mapped = allocate(console_type)
		TEST_ASSERT_EQUAL(mapped.program.fixed_department, bound[console_type], "[console_type] привязана к отделу")
		var/obj/item/circuitboard/computer/department_budget/board = mapped.circuit
		TEST_ASSERT_EQUAL(board.department_id, bound[console_type], "Плата [console_type] помнит отдел")
		var/datum/computer_file/program/department_budget/inner = mapped.program
		qdel(mapped)
		TEST_ASSERT(QDELETED(inner), "Программа [console_type] удалена с консолью")
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/obj/machinery/computer/department_budget/medical/console = allocate(/obj/machinery/computer/department_budget/medical)
	var/mob/living/carbon/human/worker = make_staff(ACCOUNT_MED)
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/mob/living/carbon/human/scientist = make_staff(ACCOUNT_SCI)
	var/datum/supply_pack/pack = pack_above_auto_limit(medical)
	TEST_ASSERT_NOTNULL(pack, "В каталоге медицины есть пак дороже автоодобрения")
	econ_test_set_balance(medical.account, round(econ_pack_price(pack)))
	press(scientist, console, "request", list("pack" = "[pack.type]", "reason" = "тест"))
	TEST_ASSERT_EQUAL(length(medical.requests), 0, "Чужой сотрудник не подаёт заявку медицине")
	press(worker, console, "request", list("pack" = "[pack.type]", "reason" = "тест"))
	TEST_ASSERT_EQUAL(length(medical.requests), 1, "Заявка с консоли подана")
	var/datum/econ_request/request = medical.requests[1]
	press(chief, console, "approve", list("uid" = "[request.uid]"))
	TEST_ASSERT_EQUAL(request.status, ECON_REQUEST_APPROVED, "Глава одобрил с консоли")
	press(worker, console, "print_manifest")
	var/obj/item/export_manifest/manifest = locate() in worker.held_items
	TEST_ASSERT_NOTNULL(manifest, "Накладная в руке сотрудника")
	allocated += manifest
	TEST_ASSERT_EQUAL(manifest.department_id, ACCOUNT_MED, "Накладная медицины")
	var/obj/item/circuitboard/computer/department_budget/loose_board = allocate(/obj/item/circuitboard/computer/department_budget)
	loose_board.multitool_act(worker, null)
	TEST_ASSERT(loose_board.department_id && loose_board.department_id != ACCOUNT_CMD, "Мультитул выбирает отдел, не казну")
	var/obj/machinery/computer/department_budget/built = allocate(/obj/machinery/computer/department_budget)
	var/obj/item/circuitboard/computer/department_budget/built_board = built.circuit
	built_board.department_id = ACCOUNT_SRV
	built.on_construction()
	TEST_ASSERT_EQUAL(built.program.fixed_department, ACCOUNT_SRV, "Собранная консоль берёт отдел с платы")

/// Приложение бюджета стоит в КПК каждого главы и сотрудника отдела; окно отдаёт ровно ожидаемые поля правил, без порогов аудита.
/datum/unit_test/economy_ui_budget/presets/Run()
	for(var/pda_type in list(
		/obj/item/modular_computer/pda/heads/captain,
		/obj/item/modular_computer/pda/heads/hop,
		/obj/item/modular_computer/pda/heads/hos,
		/obj/item/modular_computer/pda/heads/ce,
		/obj/item/modular_computer/pda/heads/cmo,
		/obj/item/modular_computer/pda/heads/rd,
		/obj/item/modular_computer/pda/heads/quartermaster,
		/obj/item/modular_computer/pda/medical,
		/obj/item/modular_computer/pda/engineering,
		/obj/item/modular_computer/pda/cook,
	))
		var/obj/item/modular_computer/pda/pda = allocate(pda_type)
		TEST_ASSERT_NOTNULL(locate(/datum/computer_file/program/department_budget) in pda.get_all_files(), "[pda_type] без бюджета отдела")
	var/mob/living/carbon/human/chief = make_staff(ACCOUNT_MED, list(ACCESS_CMO))
	var/datum/computer_file/program/department_budget/program = give_pda(chief, /obj/item/modular_computer/pda/heads/cmo)
	var/list/static_data = program.budget_static_data(chief)
	var/list/data = program.budget_data(chief)
	for(var/key in static_data + data)
		TEST_ASSERT(key == "audit_rights" || !findtext(key, "audit"), "Окно отдаёт порог аудита [key]")
	TEST_ASSERT(data["can_manage"], "Главврач управляет медициной")
	TEST_ASSERT(length(data["staff"]) >= 1, "Главе виден список сотрудников")
	var/list/work_prices = data["work_prices"]
	TEST_ASSERT_EQUAL(length(work_prices), length(GLOB.econ_department_work[ACCOUNT_MED]), "Цены работ медицины")
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED)
	data = program.budget_data(doctor)
	TEST_ASSERT(!data["can_manage"], "Врач не управляет")
	TEST_ASSERT_EQUAL(length(data["staff"]), 0, "Врачу список сотрудников с окладами не виден")
