/// Памятка в наборе ГП и квартирмейстера: числа берутся из настроек экономики в момент печати.
/obj/item/paper/guides/economy
	name = "paper- 'Station Economy Guide'"

/obj/item/paper/guides/economy/Initialize(mapload)
	default_raw_text = get_info_text()
	return ..()

/obj/item/paper/guides/economy/proc/get_info_text()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/economy_minutes = round(SSeconomy.wait / (1 MINUTES), 1)
	var/list/wages = list()
	for(var/grade in GLOB.econ_pay_grade_names)
		wages += "[GLOB.econ_pay_grade_names[grade]] [settings.wages[grade]]"
	var/list/prices = list()
	var/static/list/examples = list(WORK_MED_REVIVE = "реанимация", WORK_MED_SURGERY = "операция", WORK_SRV_NEW_PLANT = "новый сорт урожая")
	for(var/work_type in examples)
		prices += "[examples[work_type]] - [settings.work_prices[work_type]] кр."
	var/cleaning_price = settings.work_prices[WORK_SRV_CLEANING]
	var/list/lines = list(
		"<h2>Памятка по экономике станции</h2>",
		"<i>Числа - на момент печати. Подробности - в справках приложений \"Кошелёк\", \"Бюджет отдела\", \"Казна\", доски контрактов и консоли снабжения.</i>",
		"<h3>Зарплата и налог</h3><ul>",
		"<li>Раз в [settings.payroll_interval_ticks * economy_minutes] мин. из бюджета отдела, кр. по грейду: [jointext(wages, ", ")]. Глава добавляет до [settings.max_wage_bonus]%. Премии: до [settings.bonus_cap_hour] кр./ч на человека, себе до [settings.bonus_self_cap_hour].</li>",
		"<li>Если бюджет пуст, недоплата - долг отдела перед вами (до [settings.owed_wages_cap_paychecks] окладов), он гасится первым. Меньше [settings.wage_floor] кр. за выплату не бывает: доплачивает NT, даже без отдела или грейда, в том числе после увольнения; безбилетникам - нет. Кто дольше [settings.dormant_after_minutes] мин. мёртв или не на смене, зарплату не получает.</li>",
		"<li>Налог с зарплаты, работы и контрактов: сейчас [SSeconomy.tax_rate]%, капитан или ГП ставят от 0 до [settings.tax_max]%; [settings.tax_nt_share]% налога забирает NT, остальное - казне. Чаевые, переводы, биржа, касса и прилавок без налога.</li></ul>",
		"<h3>Доход отделов</h3><ul>",
		"<li>Грант раз в [economy_minutes] мин.: [settings.grant_payroll_share]% окладов сотрудников на смене[settings.grant_base ? ", отделам с каталогом ещё [settings.grant_base] кр." : ""].</li>",
		"<li>За работу NT платит отделу по прайсу, исполнителю - ещё [settings.work_personal_share]% сверху, до [settings.work_personal_cap_hour] кр. в час. Прайс своего отдела - в \"Бюджете отдела\"; например, [jointext(prices, ", ")]. За аресты и приговоры NT не платит.</li>",
		"<li>Уборка: [cleaning_price] кр. сервису за каждую отмытую от грязи плитку, не больше [settings.cleaning_cap_per_tick] плиток одного уборщика за [economy_minutes] мин.</li>",
		"<li>Касса любого отдела делит оплату между кассиром и его отделом, кассиру по умолчанию [settings.register_cashier_share_default]%. За кассой до [REGISTER_CASHIERS_MAX] кассиров, у каждого свой счёт по общему меню; платят картой или наличными, сдачу касса выдаёт голочипом. Чаевые получает кассир лично.</li>",
		"<li>Контракт любого отдела может взять кто угодно, взявшему - [settings.contract_performer_share]% награды. Есть личные заказы и объявления экипажа. За отказ пауза [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)].</li>",
		"<li>Бюджет выше [settings.budget_cap_paydays] окладов отдела (не ниже [settings.budget_cap_floor] кр., у снабжения - [settings.budget_cap_floor_cargo] кр.; у казны - стартовая и по запросу на отдел): раз в [economy_minutes] мин. [settings.budget_cap_return_share]% излишка уходит NT. Не излишек: долги и зарплата сотрудникам, переводы из казны, события и доля контрактов [settings.budget_cap_grace_ticks * economy_minutes] мин. (переводы между отделами не защищены), цель накопления главы [settings.saving_goal_minutes] мин. (новая - через [settings.saving_goal_cooldown_minutes] мин.)</li></ul>",
		"<h3>Заявки</h3><ul>",
		"<li>Заявку на пак из каталога отдела одобряет глава, без главы - ГП или капитан. Если нет никого, заявка до [settings.auto_approve_limit] кр. одобряется сама[settings.auto_approve_wait_minutes > 0 ? "; если есть, но за [settings.auto_approve_wait_minutes] мин. никто не ответил - тоже" : ""].</li>",
		"<li>Глава может попросить из казны до [settings.treasury_request_max] кр. за раз.</li></ul>",
		"<h3>Снабжение</h3><ul>",
		"<li>Накладная отдела в любом ящике, даже снабжения, отдаёт выручку ящика отделу, снабжению - сбор [settings.cargo_handling_fee]%.</li>",
		"<li>Частный заказ дороже пака на [round((ECON_PRIVATE_ORDER_MARKUP - 1) * 100)]%. Малые кейсы - без наценки и с бесплатной доставкой до [GOODY_FREE_SHIPPING_MAX] за отгрузку, сверх этого сбор [CRATE_TAX] кр.</li>",
		"<li>Купленное через снабжение или в автомате NT выкупает не дороже [round(econ_import_resale_factor() * 100)]% базовой цены.</li></ul>",
		"<h3>Личные деньги</h3><ul>",
		"<li>Переводы и чаевые в \"Кошельке\" - до [settings.transfer_max] кр., чаевые на кассе - до [min(REGISTER_PRICE_MAX, settings.transfer_max)] кр.; не чаще раза в [settings.transfer_cooldown_seconds] с.</li>",
		"<li>Станционный прилавок: аренда [settings.stall_rent_fee] кр. на [settings.stall_rent_minutes] мин. в казну.</li>",
		"<li>Цены автоматов следуют индексу цен сектора (сейчас ×[round(SSeconomy.price_index(), 0.01)]), [settings.vend_wholesale_share]% выручки - себестоимость NT, остальное - отделу-владельцу; у премиальных позиций NT берёт [settings.vend_premium_sink_share]%.</li>",
		"<li>Личный каталог снабжения (питомцы, одежда, украшения, уют) - за свой счёт без наценки, деньги (кроме залога за ящик) уходят NT.</li>",
		"<li>Слот-машина: [settings.slot_house_edge]% ставки берёт NT, [settings.slot_jackpot_share]% идёт в общий джекпот автоматов сектора (переходит в следующую смену, не меньше [settings.slot_jackpot_floor] кр.), остальное - в банк выигрышей.</li>",
		"<li>Лотерея сектора: билет [settings.lottery_ticket_price] кр. в \"Кошельке\", до [settings.lottery_tickets_per_account] на счёт, победителю [100 - settings.lottery_house_share]% продаж.</li></ul>",
		"<h3>Биржа</h3><ul>",
		"<li>Спред [settings.stock_spread]%, комиссия [settings.stock_fee]%, позиция до [settings.stock_position_cap] кр. на компанию, сделка по ней раз в [settings.stock_trade_cooldown_seconds] с. Цены переходят в следующую смену со сдвигом [SSmarket.persist_decay]% к исходным. Деньги и акции игроков - нет.</li>",
		"<li>Что двигает цену каждой компании - в разделе \"От чего зависит цена\". О скачке от [STOCK_HOLDER_ALERT_MIN * 100]% и остановке торгов держателю сообщает карта.</li>",
		"<li>[settings.stock_dividend_share]% закупок станции у партнёра - дивиденды держателям его компании с каждой зарплатой. [STOCK_INDEX_TICKER] - индекс сектора. Заявки в \"Портфеле\" (до [STOCK_ORDERS_MAX]) торгуют сами по порогу цены.</li></ul>",
		"<h3>Аукцион сектора</h3><ul>",
		"<li>Редкий лот раз в [round(AUCTION_GAP_MIN / (1 MINUTES))]-[round(AUCTION_GAP_MAX / (1 MINUTES))] мин., торгуются и другие станции сектора. Ставка с личного счёта замораживается, перебитая возвращается.</li>",
		"<li>Скупка - пачки разных предметов партнёра со скидкой до [BUNDLE_DISCOUNT_MAX]%, только целиком. Всё это - в консоли снабжения, спецзаказы - ещё на паде подработки и сканером аванпоста.</li></ul>",
		"<h3>Аудит</h3><ul>",
		"<li>Ведут [SSeconomy.audit_rights_text()]. Дело открывают крупные или частые выплаты одному человеку, премия себе, неопознанные устройства, обналичка анонимного счёта, сделки перед новостью о компании.</li>",
		"<li>Замороженный счёт не платит, зарплата копится долгом отдела. С возврата украденного [settings.audit_case_fee_percent]% идёт бюджету СБ.</li></ul>",
	)
	return jointext(lines, "")

/// Короткая памятка для всех в канале "Сводка сектора": полную печатают ГП и квартирмейстеру.
/proc/econ_guide_summary_text()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/economy_minutes = round(SSeconomy.wait / (1 MINUTES), 1)
	return "Памятка по экономике станции. Зарплата приходит раз в [settings.payroll_interval_ticks * economy_minutes] мин. из бюджета отдела, с неё удерживается налог (сейчас [SSeconomy.tax_rate]%, капитан или ГП ставят до [settings.tax_max]%). Приложения КПК: \"Кошелёк\" - счёт, переводы и лотерея; \"Биржа\" - акции компаний сектора; \"Бюджет отдела\" - заявки, премии и закупки отдела; \"Заказы снабжения\" - каталог. Глава заказывает паки отдела в \"Бюджете отдела\" шаттлом снабжения или капсулой сразу - дороже на [settings.department_express_markup]%, не чаще раза в [settings.department_express_cooldown_minutes] мин. Заработать сверх зарплаты: работа по прайсу отдела, контракты NT на доске любого отдела (взявшему [settings.contract_performer_share]% награды), касса и чаевые. Личные деньги и акции в следующую смену не переходят - переходят только цены рынка, котировки биржи и репутация партнёров снабжения. Полная памятка с числами есть у ГП и квартирмейстера."
