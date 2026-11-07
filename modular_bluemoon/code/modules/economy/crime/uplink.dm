/datum/uplink_item/stealthy_tools/card_skimmer
	name = "Card Skimmer"
	item = /obj/item/card_skimmer
	cost = 2
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/stealthy_tools/card_skimmer/New()
	. = ..()
	desc = "Выглядит как считыватель для бесконтактных платежей. Приложите к ID-карте или к человеку с картой: за [DisplayTimeText(ECON_SKIMMER_DO_AFTER)] рядом он молча копирует доступ к личному счёту, до [SSeconomy.settings.skimmer_slots] счетов. \
		В руке переводит со скопированного счёта на любой личный счёт по номеру, не больше [SSeconomy.settings.skim_rate] кр. в минуту с каждого. Бюджеты отделов и замороженные счета не берёт. \
		Каждое списание видно владельцу в истории счёта и финансовому аудиту как \"неопознанное устройство\" вместе со счётом, куда ушли деньги: имя получателя скрывает только анонимный счёт."

/datum/uplink_item/stealthy_tools/anon_account
	name = "Prepaid Anonymous Account"
	item = /obj/item/anon_account_card
	cost = 1
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/stealthy_tools/anon_account/New()
	. = ..()
	desc = "Карта со своим банковским счётом без имени владельца: его нет в манифесте экипажа и по имени его не найти. \
		Это не тайник: финансовый аудит видит движения по счёту и след денег через него, ГП видит его в базе счетов. \
		Наличные снимаются с карты в руке, каждое снятие попадает в аудит вместе с местом, замороженный аудитом счёт не обналичить."

/datum/uplink_item/stealthy_tools/insider_pager
	name = "Insider Pager"
	item = /obj/item/insider_pager
	cost = 3
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/stealthy_tools/insider_pager/New()
	. = ..()
	desc = "Пейджер с инсайдерской сводкой: показывает настоящие события биржевых компаний, уже стоящие в очереди, - заголовок, сдвиг цены и сколько осталось до выхода (от [DisplayTimeText(STOCK_EVENT_ETA_MIN)] до [DisplayTimeText(STOCK_EVENT_ETA_MAX)]). \
		Фальшивых релизов и опровержений не видит, а мигание экрана при событии в очереди видно только вам. Крупные сделки в сторону события, сделанные после того, как оно встало в очередь, - то есть по сводке пейджера, - финансовый аудит помечает как инсайд."

/datum/uplink_item/stealthy_tools/press_release
	name = "Fake Press Release"
	item = /obj/item/press_release_kit
	cost = 2
	purchasable_from = UPLINK_TRAITORS
	blocked_round_types = list(ROUNDTYPE_DYNAMIC_LIGHT, ROUNDTYPE_EXTENDED)

/datum/uplink_item/stealthy_tools/press_release/New()
	. = ..()
	var/cooldown = SSmarket.press_release_cooldown()
	desc = "Одноразовый фальшивый пресс-релиз: выберите компанию и знак новости. Цена сдвигается на ближайшей котировке, как от настоящей новости того же знака, заголовок тоже настоящий; новость выходит в \"[MARKET_NEWS_CHANNEL]\". \
		Через [SSeconomy.settings.press_release_refute_minutes] мин. после выхода NT публикует опровержение и возвращает цену. Следующий такой релиз в секторе проходит через [cooldown]-[round(cooldown * (1 + PRESS_RELEASE_COOLDOWN_JITTER))] мин., о компании - один за смену, а на слишком тихой бирже, где фальшивку сразу заметят, релиз не примут. \
		Крупные сделки в сторону релиза незадолго до его выхода и сделки в сторону опровержения между выходом и опровержением попадают в финансовый аудит. Тот же релиз выпускает ньюскастер, перепрошитый емагом (Alt-клик), но опровержение назовёт его место."
