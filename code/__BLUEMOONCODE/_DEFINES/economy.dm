//What should vending machines charge when you buy something in-department.
#define DEPARTMENT_DISCOUNT 0.2

//Civilian bounties
#define CIV_JOB_CMO 17
#define CIV_JOB_RD 18

#define ECONOMY_CONFIG_PATH "config/economy.json"
#define ECON_SNAPSHOT_MAX 48
/// Значащих цифр в суммах для текста: без этого числа от миллиона печатаются как 1e+006
#define ECON_TEXT_DIGITS 12

#define ACCOUNT_CMD "CMD"
#define ACCOUNT_CMD_NAME "Казна станции"

#define ACCOUNT_ACTIVE 0
#define ACCOUNT_FROZEN 1
#define ACCOUNT_DORMANT 2

#define ECON_STATE_POOR "poor"
#define ECON_STATE_NORMAL "normal"
#define ECON_STATE_RICH "rich"

#define PAY_GRADE_ASSISTANT "assistant"
#define PAY_GRADE_MINIMAL "minimal"
#define PAY_GRADE_EASY "easy"
#define PAY_GRADE_MEDIUM "medium"
#define PAY_GRADE_HARD "hard"
#define PAY_GRADE_COMMAND "command"

///from SSeconomy.move(): (datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor)
#define COMSIG_ECONOMY_MOVED "economy_moved"
///from SSeconomy.refund() после обоих переводов: (datum/bank_account/from_account, datum/bank_account/to_account, amount) - вся сумма со счёта получателя, со сбором СБ
#define COMSIG_ECONOMY_AUDIT_REFUNDED "economy_audit_refunded"
///from SSeconomy.record_work(): (department_id, work_type, amount, mob/performer, paid, atom/subject)
#define COMSIG_ECONOMY_WORK_RECORDED "economy_work_recorded"
#define WORK_LOG_MAX 30
/// Окно, в котором копится личная премия до потолка work_personal_cap_hour
#define WORK_PREMIUM_WINDOW (1 HOURS)

#define WORK_MED_DISCHARGE_LIGHT "med_discharge_light"
#define WORK_MED_DISCHARGE_HEAVY "med_discharge_heavy"
#define WORK_MED_DISCHARGE_CRIT "med_discharge_crit"
#define WORK_MED_REVIVE "med_revive"
#define WORK_MED_SURGERY "med_surgery"
/// Общий ключ кулдауна выписок любой тяжести
#define WORK_GROUP_MED_DISCHARGE "med_discharge"

#define ECON_INJURY_NONE 0
#define ECON_INJURY_LIGHT 1
#define ECON_INJURY_HEAVY 2
#define ECON_INJURY_CRIT 3
#define ECON_INJURY_LIGHT_HEALTH_RATIO 0.8
#define ECON_INJURY_HEAVY_HEALTH_RATIO 0.5
/// Сколько после травмы пациента можно выписать
#define ECON_INJURY_WINDOW (30 MINUTES)
#define ECON_DISCHARGE_HEALTH_RATIO 0.9
#define WORK_ENG_POWER_EXPORT "eng_power_export"
#define WORK_ENG_INTEGRITY "eng_integrity"
/// Доход экспорта энергии уходит инженерии не чаще этого интервала...
#define ECON_POWER_EXPORT_PAYOUT_INTERVAL (1 MINUTES)
/// ...или сразу, когда накопилось столько
#define ECON_POWER_EXPORT_PAYOUT_BULK 500
#define WORK_SCI_NODE "sci_node"
#define WORK_SCI_SLIME_DISCOVERY "sci_slime_discovery"
#define WORK_SCI_ARTIFACT "sci_artifact"
/// Цена WORK_SCI_NODE платится за каждые столько очков стоимости узла
#define ECON_NODE_POINTS_UNIT 1000
#define WORK_MINING_ORE "mining_ore"
#define ECON_MANIFEST_PRINT_COOLDOWN (5 SECONDS)
/// Каталог окон снабжения пересчитывает цены и поставщиков не чаще этого
#define ECON_CARGO_PRICES_REFRESH (5 SECONDS)
/// Частный заказ не малым кейсом дороже цены пака во столько раз, разница идёт снабжению
#define ECON_PRIVATE_ORDER_MARKUP 1.1
/// Группа окна снабжения с паками личного каталога
#define ECON_PERSONAL_CATALOG_GROUP "Личный каталог"
/// Малых кейсов на один личный счёт за отгрузку, которые едут бесплатно; сверх этого все едут ящиком со сбором CRATE_TAX
#define GOODY_FREE_SHIPPING_MAX 5
#define CRATE_TAX 700
/// Цена маяка экспресс-доставки из бюджета консоли
#define EXPRESS_BEACON_COST 500
/// Консоль запросов и приложение снабжения оповещают канал снабжения о заявке не чаще этого
#define ECON_CARGO_REQUEST_RADIO_COOLDOWN (30 SECONDS)
/// Столько одинаковых паков консоль снабжения добавляет одним нажатием
#define ECON_CARGO_ADD_MAX 10
#define WORK_SRV_DISH "srv_dish"
#define WORK_SRV_DRINK "srv_drink"
#define WORK_SRV_NEW_PLANT "srv_new_plant"
#define WORK_SRV_CLEANING "srv_cleaning"
#define ECON_DISH_OF_THE_DAY_PERIOD (1 HOURS)
#define WORK_SEC_CONTRABAND "sec_contraband"
#define AUDIT_FLAG_BUDGET_SIPHON "budget_siphon"
#define AUDIT_FLAG_SELF_BONUS "self_bonus"
#define AUDIT_FLAG_STRUCTURING "structuring"
#define AUDIT_FLAG_UNKNOWN_DEVICE "unknown_device"
#define AUDIT_FLAG_INSIDER "insider"
#define AUDIT_FLAG_ANON_CASHOUT "anon_cashout"
#define AUDIT_FLAG_CRYPTOMINER "cryptominer"
/// Сколько дел аудита хранит раунд; сверх этого вытесняются старые закрытые
#define AUDIT_FLAGS_MAX 200
#define AUDIT_REASON_MAX 64
#define AUDIT_OWN_MOVES_REFUSAL "Вы сами двигали деньги по этому делу: его закрывает другой аудитор."
/// Исходящие одному получателю складываются в корзины этой длины: память пары не зависит от числа операций
#define AUDIT_BUCKET (1 MINUTES)
#define AUDIT_BUCKET_START 1
#define AUDIT_BUCKET_AMOUNT 2
#define AUDIT_BUCKET_COUNT 3
/// Ключ audit_watch для всех счетов без владельца одного источника
#define AUDIT_WATCH_UNOWNED "unowned"
#define ECON_SKIMMER_DO_AFTER (3 SECONDS)
/// Суммы экономических целей предателя округляются до этого шага
#define ECON_OBJECTIVE_STEP 100
/// Растрата: доля стартового бюджета отдела, проценты
#define ECON_OBJECTIVE_EMBEZZLE_MIN 20
#define ECON_OBJECTIVE_EMBEZZLE_MAX 50
/// Кража: сколько средних зарплат украсть и сохранить
#define ECON_OBJECTIVE_HOARD_MIN 10
#define ECON_OBJECTIVE_HOARD_MAX 20
/// Прибыль на бирже: доля порога инсайда, проценты
#define ECON_OBJECTIVE_STOCK_MIN 30
#define ECON_OBJECTIVE_STOCK_MAX 60
/// Контрабанда: на сколько ТК по курсу настроек продать
#define ECON_OBJECTIVE_SMUGGLE_MIN 5
#define ECON_OBJECTIVE_SMUGGLE_MAX 10
/// Обвал акций: на сколько процентов от цены при выдаче
#define ECON_OBJECTIVE_CRASH_MIN 25
#define ECON_OBJECTIVE_CRASH_MAX 30
/// Счёт главы считается опустошённым, если на нём осталось не больше этого
#define ECON_OBJECTIVE_DRAIN_LEFT 100
/// Сколько контрактов один счёт держит взятыми одновременно
#define ECON_CONTRACTS_PER_TAKER 1
/// Срок, который получает взятый контракт без своего срока
#define ECON_CONTRACT_TAKEN_TIME (40 MINUTES)
/// Шанс, что новый контракт отдела - деятельность, а не поставка
#define ECON_CONTRACT_ACTIVITY_CHANCE 35
/// Не чаще этого бюджет сообщает картам о возврате излишка NT
#define ECON_BUDGET_RETURN_NOTICE_COOLDOWN (10 MINUTES)
/// Шаг округления награды контракта деятельности
#define ECON_CONTRACT_REWARD_STEP 50
/// Начатый, но никем не взятый контракт снимается через столько возрастов ротации
#define ECON_CONTRACT_STALE_ROTATIONS 3
#define ECON_REQUEST_PENDING "pending"
#define ECON_REQUEST_APPROVED "approved"
#define ECON_REQUEST_DENIED "denied"
/// Сколько решённых заявок отдел хранит для истории
#define ECON_REQUESTS_KEPT 20
/// Наибольшая длина причины заявки или запроса в казну из окна бюджета отдела
#define ECON_REQUEST_REASON_MAX 200
#define REGISTER_MENU_MAX 20
#define REGISTER_PRICE_MAX 5000
/// Кассир дальше этого или на другом уровне считается ушедшим, его кассу может занять другой
#define REGISTER_CASHIER_RANGE 7
/// Свайп клиента сразу после смены позиции не платит: сумму нужно успеть увидеть
#define REGISTER_SELECT_GRACE (2 SECONDS)
#define ECON_TRANSFER_MEMO_MAX 64
/// Наибольшая сумма одной админской корректировки счёта
#define ECON_ADMIN_ADJUST_MAX 100000
#define ECON_ADMIN_COMMENT_MAX 200
#define ECON_ADMIN_HEADLINE_MAX 120
/// Фраза, которую админ вводит в окне для сброса сектора
#define ECON_ADMIN_RESET_PHRASE "сброс"
/// Кем заморожен счёт для его владельца, когда морозит администрация
#define ECON_ADMIN_FROZEN_BY "Центральное командование NT"
#define ECON_ADMIN_FREEZE_LOCKED "Счёт заморожен ЦК: разморозить может только ЦК."
#define ECON_ADMIN_EVENT_KEY "admin"
/// Второй свайп карты по прилавку в это окно подтверждает аренду или освобождение
#define STALL_CONFIRM_WINDOW (10 SECONDS)

#define ECON_CAT_WAGE "wage"
#define ECON_CAT_WORK "work"
#define ECON_CAT_GRANT "grant"
#define ECON_CAT_CONTRACT "contract"
#define ECON_CAT_TRADE "trade"
#define ECON_CAT_PURCHASE "purchase"
#define ECON_CAT_TIP "tip"
#define ECON_CAT_TAX "tax"
#define ECON_CAT_TRANSFER "transfer"
#define ECON_CAT_FINE "fine"
#define ECON_CAT_STOCK "stock"
#define ECON_CAT_CASH "cash"
#define ECON_CAT_CRIME "crime"
#define ECON_CAT_ADMIN "admin"
#define ECON_CAT_EVENT "event"
#define ECON_CAT_MISC "misc"

#define ECON_WAGE "wage"
#define ECON_WAGE_FLOOR "wage_floor"
#define ECON_BONUS "bonus"
#define ECON_STARTING_FUNDS "starting_funds"
#define ECON_GRANT "grant"
#define ECON_WORK "work"
#define ECON_WORK_PREMIUM "work_premium"
#define ECON_CONTRACT "contract"
#define ECON_EXPORT "export"
#define ECON_IMPORT "import"
#define ECON_HANDLING_FEE "handling_fee"
#define ECON_PRIVATE_ORDER "private_order"
#define ECON_VEND "vend"
#define ECON_VEND_WHOLESALE "vend_wholesale"
#define ECON_PURCHASE "purchase"
#define ECON_REGISTER "register"
#define ECON_RENT "rent"
#define ECON_GAMBLING "gambling"
#define ECON_GAMBLING_WIN "gambling_win"
#define ECON_LOTTERY "lottery"
#define ECON_LOTTERY_PRIZE "lottery_prize"
#define ECON_LOTTERY_HOUSE "lottery_house"
#define ECON_PERSONAL_CATALOG "personal_catalog"
#define ECON_TIP "tip"
#define ECON_TAX "tax"
#define ECON_TAX_NT "tax_nt"
#define ECON_BUDGET_RETURN "budget_return"
#define ECON_BUDGET_TRANSFER "budget_transfer"
#define ECON_TRANSFER "transfer"
#define ECON_REFUND "refund"
#define ECON_FINE "fine"
#define ECON_FINE_CUSTOMS "fine_customs"
#define ECON_COURT_FEE "court_fee"
#define ECON_DEBT_PAYMENT "debt_payment"
#define ECON_STOCK_BUY "stock_buy"
#define ECON_STOCK_SELL "stock_sell"
#define ECON_STOCK_FEE "stock_fee"
#define ECON_CASH_OUT "cash_out"
#define ECON_CASH_IN "cash_in"
#define ECON_BLACKMARKET "blackmarket"
#define ECON_SKIM "skim"
#define ECON_ADMIN "admin"
#define ECON_EVENT "event"
#define ECON_EVENT_RANSOM "event_ransom"
/// Выкуп рейдеров и средневековых вояк: минимум и доля казны в процентах
#define ECON_RAIDERS_RANSOM_MIN 25000
#define ECON_RAIDERS_RANSOM_SHARE 90
#define ECON_WARMONGERS_RANSOM_MIN 30000
#define ECON_WARMONGERS_RANSOM_SHARE 85
#define ECON_ACCOUNT_CLOSED "account_closed"
#define ECON_MISC "misc"

/// Ключ economy.json, начинающийся с "_", - комментарий: загрузчики его пропускают без ошибки
#define ECON_CONFIG_COMMENT_KEY(key) (copytext("[key]", 1, 2) == "_")

#define INIT_ORDER_MARKET (INIT_ORDER_ECONOMY - 1)
#define MARKET_PRICE_MIN 0.5
#define MARKET_PRICE_MAX 3
#define MARKET_TREND_REVERSION 0.9
#define MARKET_HISTORY_MAX 24
#define MARKET_INDEX_MIN 0.8
#define MARKET_INDEX_MAX 1.5
#define MARKET_INDEX_SMOOTHING 0.3
/// Доля цены продажи, которая остаётся при полностью выбитом спросе
#define MARKET_DEMAND_FLOOR 0.2
#define MARKET_HOT_MULT_MIN 1.5
#define MARKET_HOT_MULT_MAX 2.5
#define MARKET_HOT_SHIFTS_MIN 2
#define MARKET_HOT_SHIFTS_MAX 4
/// Разброс момента сдвига рынка в обе стороны
#define MARKET_SHIFT_JITTER (90 SECONDS)
#define MARKET_VOLATILITY_MAX 1
/// Сумма долей связей, входящих в один товар: выше неё связи раскачивают тренды до потолка
#define MARKET_LINK_INBOUND_MAX 1
/// Относительный сдвиг индекса цен, после которого автоматы пересчитывают цены
#define MARKET_VENDING_REFRESH_SHARE 0.05

#define PARTNER_TIER_STEP 250
#define PARTNER_TIER_MAX 4
#define PARTNER_REPUTATION_MAX 1000
/// Скидка на высшей ступени репутации
#define PARTNER_DISCOUNT_MAX 0.15
#define PARTNER_MARKUP_MIN 0.5
#define PARTNER_MARKUP_MAX 3
/// Потолок множителя, с которым партнёр покупает товар
#define PARTNER_BUY_MULT_MAX 2
/// Партнёр производит пак для своего склада за такую долю его цены
#define PARTNER_PRODUCTION_SHARE 0.5
/// Сколько партнёров нужной ступени открывают партнёра с правилом any_two_tier
#define PARTNER_UNLOCK_SPONSORS 2
/// Встроенный партнёр, который продаёт и покупает всё: на него откатывается конфиг без такого партнёра
#define PARTNER_UNIVERSAL_ID "nt_logistics"
/// Ключ «любой товар» в buys и «любая группа» в sells_groups
#define PARTNER_ANY "*"
/// Пределы случайного множителя спецзаказа к цене единицы
#define MARKET_OFFER_MULT_MIN 1.5
#define MARKET_OFFER_MULT_MAX 2.5
#define MARKET_OFFER_REPUTATION_SUCCESS 120
#define MARKET_OFFER_REPUTATION_FAIL 60
/// Невзятый спецзаказ снимается через столько интервалов генерации
#define MARKET_OFFER_UNTAKEN_LIFETIME 2
/// Насколько проваленный спецзаказ роняет цену акций компании партнёра
#define MARKET_OFFER_FAIL_STOCK_SHOCK 0.05

/// Цена растёт на долю объём / STOCK_TRADE_SCALE от продаж партнёру, не больше STOCK_TRADE_BOOST_MAX за листинг
#define STOCK_TRADE_SCALE 20000
#define STOCK_TRADE_BOOST_MAX 0.15
/// Скачок цены от этой доли и больше приходит держателям акций сообщением на карту
#define STOCK_HOLDER_ALERT_MIN 0.05
#define STOCK_EVENT_MULT_MAX 3
#define STOCK_PRICE_MIN 0.01
/// Разница цен меньше этой считается нулевой
#define STOCK_PRICE_EPSILON 0.001
/// Потолок цены в базовых ценах компании
#define STOCK_PRICE_MAX_RATIO 5
#define STOCK_BANKRUPT_RATIO 0.05
#define STOCK_RELIST_RATIO 0.2
#define STOCK_HALT_TIME (10 MINUTES)
#define STOCK_HISTORY_MAX 60
#define STOCK_VOLATILITY_MAX 0.2
#define STOCK_EFFECT_MIN -0.9
#define STOCK_EFFECT_MAX 1
#define STOCK_EVENT_ETA_MIN (3 MINUTES)
#define STOCK_EVENT_ETA_MAX (5 MINUTES)
/// Одно и то же событие станции двигает акции не чаще раза в это время
#define STOCK_STATION_EVENT_COOLDOWN (10 MINUTES)
/// Ключ «все компании» в market.station_events
#define STOCK_ALL_COMPANIES "*"
/// Ключ события-опровержения фальшивого пресс-релиза
#define STOCK_REFUTATION_KEY "refutation"
/// Кулдаун фальшивых пресс-релизов случайно длиннее настройки, до этой доли
#define PRESS_RELEASE_COOLDOWN_JITTER 0.5
/// Безопасный кулдаун фальшивок при проверке конфига ищется не дальше этого, мин.
#define PRESS_RELEASE_COOLDOWN_LIMIT 600
/// Поля записи SSmarket.recent_trades
#define INSIDER_TRADE_ACCOUNT 1
#define INSIDER_TRADE_TICKER 2
#define INSIDER_TRADE_VALUE 3
#define INSIDER_TRADE_TIME 4
#define INSIDER_TRADE_SERIAL 5
#define INSIDER_TRADE_ACTORS 6
/// Сделка на V кр. сдвигает цену на долю V / глубину: первый из сговора меньше чем 144 полных счетов и казны не окупает спред и комиссии
#define STOCK_TRADE_IMPACT_DEPTH 25000000

#define MARKET_NEWS_CHANNEL "Сводка сектора"
#define MARKET_NEWS_AUTHOR "NT Exchange"
/// Канал сводки хранит столько последних статей
#define MARKET_NEWS_KEEP 40
/// Срочных новостей в ожидании выпуска не больше, старые отбрасываются
#define MARKET_NEWS_PENDING_MAX 8

/// Файл состояния сектора другой версии не читается, сектор стартует с базы
#define MARKET_STATE_VERSION 1
#define MARKET_STATE_PATH "data/economy/sector_state.json"
/// Капитал партнёра из файла состояния не больше стольких его стартовых
#define MARKET_STATE_WEALTH_CAP_MULT 10

///from SSmarket.market_shift()
#define COMSIG_MARKET_SHIFTED "market_shifted"
///from /datum/commodity/proc/shift(): (datum/commodity/commodity)
#define COMSIG_MARKET_HOT "market_hot"
///from SSmarket.check_unlocks(): (datum/trade_partner/partner)
#define COMSIG_MARKET_PARTNER_UNLOCKED "market_partner_unlocked"
///from /datum/trade_partner/note_purchase() и note_sale(): (datum/trade_partner/partner, value, is_sale)
#define COMSIG_MARKET_TRADE "market_trade"
///from /datum/market_offer/complete() и fail(): (datum/market_offer/offer, success)
#define COMSIG_MARKET_OFFER_RESOLVED "market_offer_resolved"
///from /datum/econ_cargo_prices/tick() раз в ECON_CARGO_PRICES_REFRESH, пока есть подписчики
#define COMSIG_ECON_CARGO_PRICES_TICK "econ_cargo_prices_tick"
///from SSmarket.run_due_events(): (datum/market_event/event); после сигнала event удаляется, поля копировать синхронно
#define COMSIG_MARKET_COMPANY_EVENT "market_company_event"
///from SSmarket.try_buy_shares() и try_sell_shares(): (datum/bank_account/account, ticker, count, price, is_buy, realized, mob/user); realized - прибыль продажи
#define COMSIG_MARKET_STOCK_TRADE "market_stock_trade"
///from SSmarket.tick_stocks() после минутного шага цен и выхода событий компаний: (list/halted, list/relisted) - тикеры, остановленные и возобновлённые этим шагом
#define COMSIG_MARKET_STOCKS_TICKED "market_stocks_ticked"
///from SSmarket.station_event(), когда событие станции сдвинуло акции: (key)
#define COMSIG_MARKET_STATION_EVENT "market_station_event"

#define MARKET_SOUND_TICK "tick"
#define MARKET_SOUND_BELL "bell"
#define MARKET_SOUND_CRASH "crash"
/// Звонок и тревога биржи у одного табло или терминала не чаще этого
#define MARKET_ALARM_COOLDOWN (30 SECONDS)

#define COMMODITY_METALS "metals"
#define COMMODITY_PRECIOUS "precious_metals"
#define COMMODITY_PLASMA "plasma"
#define COMMODITY_CRYSTALS "crystals"
#define COMMODITY_GASES "gases"
#define COMMODITY_ENERGY "energy"
#define COMMODITY_FOOD "food"
#define COMMODITY_DRINKS "drinks"
#define COMMODITY_MEDICINE "medicine"
#define COMMODITY_CHEMICALS "chemicals"
#define COMMODITY_ELECTRONICS "electronics"
#define COMMODITY_MACHINERY "machinery"
#define COMMODITY_ROBOTICS "robotics"
#define COMMODITY_WEAPONS "weapons"
#define COMMODITY_TEXTILES "textiles"
#define COMMODITY_LUXURY "luxury"
#define COMMODITY_BIOMATERIALS "biomaterials"
#define COMMODITY_ARTIFACTS "artifacts"
#define COMMODITY_SEEDS "seeds"
#define COMMODITY_CONSTRUCTION "construction"
#define COMMODITY_FUEL "fuel"
#define COMMODITY_CULTURE "culture"
#define COMMODITY_CONTRABAND "contraband"
