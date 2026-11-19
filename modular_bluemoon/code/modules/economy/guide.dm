/// Памятка экипажу в наборе ГП и квартирмейстера: числа берутся из настроек экономики в момент печати.
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
	var/list/lines = list(
		"<h2>Экономика станции: памятка экипажу</h2>",
		"<i>Числа - на момент печати. О бюджетах отделов, заявках и снабжении - памятка главам.</i>",
		"<h3>Зарплата и налог</h3><ul>",
		"<li>Раз в [settings.payroll_interval_ticks * economy_minutes] мин. из бюджета отдела, кр. по грейду: [jointext(wages, ", ")]. Глава добавляет надбавку до [settings.max_wage_bonus]% и премии.</li>",
		"<li>Пустой бюджет зарплату не отменяет: недоплата - долг отдела перед вами (до [settings.owed_wages_cap_paychecks] окладов), его гасят первым. Меньше [settings.wage_floor] кр. за выплату не бывает - доплачивает NT; безбилетникам - нет. Мёртвым и не на смене дольше [settings.dormant_after_minutes] мин. зарплаты нет.</li>",
		"<li>Налог с зарплаты, работы и контрактов: сейчас [SSeconomy.tax_rate]%, капитан или ГП ставят до [settings.tax_max]%; [settings.tax_nt_share]% налога забирает NT, остальное - казне. Переводы, чаевые, биржа, касса и прилавок - без налога.</li>",
		"<li>Налог выше [settings.tax_unrest_above]% дольше [settings.tax_mood_minutes] мин. злит экипаж: за работу отделам платят на [settings.tax_unrest_work_cut]% меньше. Налог до [settings.tax_goodwill_upto]% столько же времени - премия за работу [settings.work_personal_share + settings.tax_goodwill_premium_bonus]% вместо [settings.work_personal_share]%.</li></ul>",
		"<h3>Как заработать</h3><ul>",
		"<li>Работа по прайсу отдела (весь прайс - в \"Бюджете отдела\"; например, [jointext(prices, ", ")]): NT платит отделу, исполнителю - ещё [settings.work_personal_share]% сверху, до [settings.work_personal_cap_hour] кр./ч. Уборка - [settings.work_prices[WORK_SRV_CLEANING]] кр. сервису за плитку, не больше [settings.cleaning_cap_per_tick] плиток одного уборщика за [economy_minutes] мин. За аресты NT не платит.</li>",
		"<li>Контракт NT на доске любого отдела берёт кто угодно, взявшему - [settings.contract_performer_share]% награды. Там же личные заказы и объявления экипажа. После отказа - пауза [DisplayTimeText(ECON_CONTRACT_DROP_COOLDOWN)].</li>",
		"<li>Касса: продавец встаёт за неё своей ID-картой, покупатель платит картой, КПК или кошельком с картой по кассе, кнопкой в её окне или наличными. Чужую карту кассир проводит только при владельце. Кассиру - [settings.register_cashier_share_default]% оплаты (по умолчанию) и все чаевые, остальное - отделу. Подробнее - осмотрите кассу.</li>",
		"<li>На аванпостах (Тарков, DS) своя доска заказов в экспресс-консоли, сдают сканером продажи: награда - бюджету аванпоста и сдавшим.</li></ul>",
		"<h3>Кошелёк</h3><ul>",
		"<li>\"Магазин\": одежда, игрушки, питомцы - капсулой сразу, себе или в подарок с открыткой. \"Заказы\": личный каталог, везёт шаттл снабжения.</li>",
		"<li>В номере отеля Гильберта - терминал обслуживания: еда и напитки с кухни и бара станции с предоплатой (не доставят за [DisplayTimeText(ROOM_SERVICE_STAFF_WAIT)] - деньги вернутся), без сервиса - кейтеринг NT [econ_times_text(ROOM_SERVICE_CATERING_MULT)] дороже; там же декор номера.</li>",
		"<li>\"Перевод\": заплатить человеку рядом по его ID-карте или по имени и номеру счёта. Переводы и чаевые в \"Кошельке\" - до [settings.transfer_max] кр., чаевые на кассе - до [min(REGISTER_PRICE_MAX, settings.transfer_max)] кр.; не чаще раза в [settings.transfer_cooldown_seconds] с.</li>",
		"<li>Цены автоматов - по индексу цен сектора (сейчас ×[round(SSeconomy.price_index(), 0.01)]): [settings.vend_wholesale_share]% выручки - NT, остальное - отделу-владельцу. Прилавок: аренда [settings.stall_rent_fee] кр. на [settings.stall_rent_minutes] мин.</li>",
		"<li>Слот-машина: [settings.slot_house_edge]% ставки - NT, [settings.slot_jackpot_share]% - в джекпот сектора (от [settings.slot_jackpot_floor] кр.). Лотерея: билет [settings.lottery_ticket_price] кр., до [settings.lottery_tickets_per_account] на счёт, победителю [100 - settings.lottery_house_share]% продаж.</li></ul>",
		"<h3>Биржа и аукцион</h3><ul>",
		"<li>\"Биржа\": спред [settings.stock_spread]%, комиссия [settings.stock_fee]%, до [settings.stock_position_cap] кр. на компанию, сделка раз в [settings.stock_trade_cooldown_seconds] с. Акции двигают работа отделов (до ±[SSmarket.work_stock_cap * 100]% за смену) и беды станции, о скачке от [STOCK_HOLDER_ALERT_MIN * 100]% сообщает карта. [settings.stock_dividend_share]% закупок станции у партнёра - дивиденды держателям его акций. Заявки в \"Портфеле\" торгуют сами по порогу цены.</li>",
		"<li>Аукцион сектора: лот раз в [round(AUCTION_GAP_MIN / (1 MINUTES))]-[round(AUCTION_GAP_MAX / (1 MINUTES))] мин., ставки в \"Кошельке\", перебитая возвращается, выигрыш - запертой посылкой на имя. Соперники-станции дают не больше [settings.auction_rival_cap_max]% оценки, около [settings.auction_rival_free_chance]% лотов без них. Свою вещь выставляют с пада подработки, сбор NT [settings.auction_crew_fee]%.</li></ul>",
		"<h3>Между сменами</h3>",
		"<p>Деньги и акции не переходят: в конце смены акции продаются по рынку. Переходят цены биржи (со сдвигом [SSmarket.persist_decay]% к базовым), джекпот и репутация партнёров снабжения.</p>",
	)
	return jointext(lines, "")

/// Памятка главам и снабжению: бюджет отдела, заявки, снабжение и аудит. Лежит рядом с памяткой экипажу.
/obj/item/paper/guides/economy/budget
	name = "paper- 'Department Budget Guide'"

/obj/item/paper/guides/economy/budget/get_info_text()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/economy_minutes = round(SSeconomy.wait / (1 MINUTES), 1)
	var/list/lines = list(
		"<h2>Бюджет отдела: памятка главам и снабжению</h2>",
		"<i>Числа - на момент печати. Порог, грант, долги и что нужно отделу сейчас - в \"Бюджете отдела\".</i>",
		"<h3>Доход и излишек</h3><ul>",
		"<li>Грант раз в [economy_minutes] мин. доливает бюджет до порога, долгов и следующей зарплаты сотрудникам и цели накопления: за время между зарплатами - не больше [settings.grant_payroll_share]% окладов сотрудников на смене[settings.grant_base ? ", отделам с каталогом ещё [settings.grant_base] кр. за раз" : ""].</li>",
		"<li>Порог - [settings.budget_cap_paydays] окладов отдела, не ниже [settings.budget_cap_floor] кр. (у снабжения - [settings.budget_cap_floor_cargo] кр.). Сверх порога, долгов и зарплаты раз в [economy_minutes] мин. [settings.budget_cap_return_share]% излишка уходит NT (с красного кода - нет). Не излишек: переводы из казны, события и доля контрактов первые [settings.budget_cap_grace_ticks * economy_minutes] мин., цель накопления.</li>",
		"<li>Цель накопления: набрать за [settings.saving_goal_collect_minutes] мин., потом [settings.saving_goal_minutes] мин. на заказ, новая - через [settings.saving_goal_cooldown_minutes] мин. Снабжение копит и на пак консоли или ОБР.</li>",
		"<li>Пустой бюджет копит долг по зарплате (до [settings.owed_wages_cap_paychecks] окладов), он гасится первым. Премии - до [settings.bonus_cap_hour] кр./ч на человека, себе - до [settings.bonus_self_cap_hour].</li>",
		"<li>За работу по прайсу NT платит отделу сам. Раз в [DisplayTimeText(ECON_CONTRACT_BOARD_RESET_COOLDOWN)] глава сбрасывает невзятые и давно взятые без отгрузки контракты отдела. За кассой до [REGISTER_CASHIERS_MAX] кассиров, долю кассира ставит глава.</li></ul>",
		"<h3>Заявки и казна</h3><ul>",
		"<li>Пак каталога оплачивает отдел. Заявка до [settings.auto_approve_limit] кр. одобряется сразу, не чаще раза в [settings.auto_approve_cooldown_minutes] мин. на сотрудника (у СБ при начальстве - нет[settings.auto_approve_wait_minutes > 0 ? ", там за [settings.auto_approve_wait_minutes] мин. без ответа" : ""]). Дороже - глава, ГП, капитан или ИИ (не у СБ) кнопкой в сообщении карты[settings.request_handoff_minutes > 0 ? "; через [settings.request_handoff_minutes] мин. без решения (не у СБ) - и начальник снабжения" : ""]. Расходники - без одобрения, до [settings.staple_self_order_cap_hour] кр./ч.</li>",
		"<li>Глава заказывает пак капсулой сразу - дороже на [settings.department_express_markup]%, не чаще раза в [settings.department_express_cooldown_minutes] мин. Из казны просит до [settings.treasury_request_max] кр. за раз.</li></ul>",
		"<h3>Снабжение</h3><ul>",
		"<li>Накладная отдела в любом ящике отдаёт выручку отделу, снабжению - сбор [settings.cargo_handling_fee]%. Купленное в снабжении или автомате NT выкупает не дороже [round(econ_import_resale_factor() * 100)]% базовой цены.</li>",
		"<li>Частный заказ дороже пака на [round((ECON_PRIVATE_ORDER_MARKUP - 1) * 100)]%. Малые кейсы - без наценки, доставка бесплатна до [GOODY_FREE_SHIPPING_MAX] за отгрузку, сверх - сбор [CRATE_TAX] кр.</li>",
		"<li>Скупка - пачки предметов партнёра со скидкой до [BUNDLE_DISCOUNT_MAX]%, только целиком, в консоли снабжения; спецзаказы - ещё на паде подработки и сканером. Подробно - справка консоли снабжения.</li>",
		"<li>У Таркова и DS своя доска заказов в экспресс-консоли, сдача сканером продажи; награда - их бюджету и сдавшим.</li></ul>",
		"<h3>Аудит</h3><ul>",
		"<li>Ведут [SSeconomy.audit_rights_text()]. Дело открывают крупные или частые выплаты одному, премия себе, неопознанные устройства, крупное внесение наличных, обналичка анонимного счёта, сделки перед новостью о компании.</li>",
		"<li>Замороженный счёт не платит, зарплата копится долгом отдела. С возврата украденного [settings.audit_case_fee_percent]% - бюджету СБ.</li></ul>",
	)
	return jointext(lines, "")

/// Короткая памятка для всех в канале "Сводка сектора": полные печатают ГП и квартирмейстеру.
/proc/econ_guide_summary_text()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/economy_minutes = round(SSeconomy.wait / (1 MINUTES), 1)
	return "Памятка по экономике станции. Зарплата приходит раз в [settings.payroll_interval_ticks * economy_minutes] мин. из бюджета отдела, с неё удерживается налог (сейчас [SSeconomy.tax_rate]%, капитан или ГП ставят до [settings.tax_max]%). Приложения КПК: \"Кошелёк\" - счёт, магазин с доставкой капсулой, переводы (и человеку рядом по ID-карте), личные заказы, аукцион и лотерея; \"Биржа\" - акции компаний сектора; \"Бюджет отдела\" - заявки, премии и закупки отдела; \"Заказы снабжения\" - каталог. Недорогой пак своего отдела сотрудник заказывает в \"Бюджете отдела\" сразу (у СБ при начальстве - нет), дорогой одобряет глава. Глава может заказать пак капсулой сразу - дороже на [settings.department_express_markup]%, не чаще раза в [settings.department_express_cooldown_minutes] мин. Заработать сверх зарплаты: работа по прайсу отдела, контракты NT на доске любого отдела (взявшему [settings.contract_performer_share]% награды), касса и чаевые. На кассе платят ID-картой или КПК по кассе, кнопкой в её окне или наличными. Глава отдела раз в [DisplayTimeText(ECON_CONTRACT_BOARD_RESET_COOLDOWN)] может сбросить доску своего отдела: неначатые контракты сменятся новыми; свой контракт главы и взятые меньше [DisplayTimeText(ECON_CONTRACT_BOARD_RESET_GRACE)] назад остаются, снятым - без штрафа. Личные деньги и акции в следующую смену не переходят: акции в конце смены продаются по рынку, переходят цены рынка, котировки биржи и репутация партнёров снабжения. Полные памятки с числами - экипажу и главам - есть у ГП и квартирмейстера."
