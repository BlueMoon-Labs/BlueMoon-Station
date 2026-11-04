#define PRESS_RELEASE_GOOD "Хорошая"
#define PRESS_RELEASE_BAD "Плохая"

/datum/market_event
	/// Номер последней сделки на бирже к постановке в очередь: раньше о событии знать было неоткуда
	var/known_after_trade = 0
	/// Фальшивый пресс-релиз: на выходе ставит опровержение
	var/press_release = FALSE
	var/press_release_origin
	/// Разум выпустившего фальшивку
	var/datum/weakref/press_release_author
	/// У опровержения: заголовок фальшивки и во сколько раз вернуть цену и накопленный эффект событий
	var/refutes
	var/refute_price = 1
	var/refute_mult = 1

/datum/market_event/New()
	. = ..()
	known_after_trade = SSmarket.trade_serial

/datum/stock_company
	/// Когда вышло последнее настоящее событие компании
	var/last_real_event_at = 0

/datum/stock_company/proc/undo_shock(price_factor, mult_factor)
	event_mult = min(event_mult * mult_factor, STOCK_EVENT_MULT_MAX)
	set_price(price * price_factor)

/datum/controller/subsystem/market
	/// list(номер счёта, тикер, сумма сделки со знаком: покупка +, продажа -, world.time, номер сделки), поля INSIDER_TRADE_*
	var/list/recent_trades = list()
	var/trade_serial = 0
	/// Раньше этого world.time следующий фальшивый пресс-релиз не пройдёт
	var/press_release_ready_at = 0
	/// Тикеры, о которых в эту смену уже выходил фальшивый релиз
	var/list/press_released = list()

/datum/controller/subsystem/market/proc/note_trade_for_audit(datum/source, datum/bank_account/account, ticker, count, price, is_buy, realized, mob/user)
	SIGNAL_HANDLER
	prune_recent_trades()
	trade_serial++
	recent_trades += list(list(account.account_id, ticker, round(count * price) * (is_buy ? 1 : -1), world.time, trade_serial, econ_audit_identities(user)))

/// Сделки хранятся, пока их может задеть событие: окно перед фальшивкой, очередь настоящего события, срок опровержения, плюс тик на задержку.
/datum/controller/subsystem/market/proc/prune_recent_trades()
	var/keep = max(SSeconomy.settings.audit_insider_window_minutes MINUTES, STOCK_EVENT_ETA_MAX, SSeconomy.settings.press_release_refute_minutes MINUTES) + wait
	while(length(recent_trades))
		var/list/oldest = recent_trades[1]
		if(oldest[INSIDER_TRADE_TIME] >= world.time - keep)
			break
		recent_trades.Cut(1, 2)

/// Чистые сделки счёта в сторону события от порога - дело аудита: деньги биржи ушли инсайдеру. Настоящее событие и опровержение считают сделки после постановки в очередь, фальшивка - за окно до выхода.
/datum/controller/subsystem/market/proc/check_insider(datum/market_event/event)
	if(!event.effect || !SSeconomy.market_account)
		return
	prune_recent_trades()
	var/window = SSeconomy.settings.audit_insider_window_minutes
	var/since = event.press_release ? world.time - window MINUTES : 0
	var/after_trade = event.press_release ? 0 : event.known_after_trade
	var/direction = event.effect > 0 ? 1 : -1
	var/list/net = list()
	var/list/traders = list()
	for(var/list/trade as anything in recent_trades)
		if(trade[INSIDER_TRADE_TICKER] == event.company.ticker && trade[INSIDER_TRADE_TIME] >= since && trade[INSIDER_TRADE_SERIAL] > after_trade)
			var/number = "[trade[INSIDER_TRADE_ACCOUNT]]"
			net[number] += trade[INSIDER_TRADE_VALUE] * direction
			var/list/known = traders[number]
			traders[number] = known ? (known | trade[INSIDER_TRADE_ACTORS]) : trade[INSIDER_TRADE_ACTORS]
	var/when
	if(event.press_release)
		when = "меньше чем за [window] мин. до фальшивого пресс-релиза «[event.headline]»"
	else if(event.refutes)
		when = "после фальшивого пресс-релиза «[event.refutes]», до его опровержения"
	else
		when = "меньше чем за [DisplayTimeText(STOCK_EVENT_ETA_MAX)] до новости «[event.headline]»"
	for(var/number in net)
		var/value = net[number]
		if(value < SSeconomy.settings.audit_insider_threshold)
			continue
		var/datum/bank_account/trader = SSeconomy.find_account(number)
		if(!trader)
			continue
		var/text = "[direction > 0 ? "Покупка" : "Продажа"] [event.company.ticker] на [value] кр. [when] ([signed_percent(round(event.effect * 100, 1))])"
		var/datum/econ_audit_flag/flag = SSeconomy.add_audit_flag(SSeconomy.market_account, AUDIT_FLAG_INSIDER, text, round(value * abs(event.effect)), trader)
		if(!findtext(flag.text, text))
			flag.text += "; [text]"
		if(length(traders[number]))
			LAZYINITLIST(flag.actors)
			flag.actors |= traders[number]

/// Во сколько раз лучшая публичная стратегия на опровержениях (купить после любой плохой новости или продать после хорошей и откупить) окупает спред и комиссии при наибольшей частоте фейков; от 1 и выше - окупает. active - сколько компаний торгуется, по умолчанию сейчас.
/datum/controller/subsystem/market/proc/press_release_edge(cooldown_minutes = press_release_cooldown(), active)
	if(isnull(active))
		active = 0
		for(var/ticker in companies)
			var/datum/stock_company/company = companies[ticker]
			if(!company.is_halted())
				active++
	var/list/negative = list()
	var/list/positive = list()
	for(var/list/template as anything in company_event_templates)
		if(template["effect"] < 0)
			negative += template["effect"]
		else if(template["effect"] > 0)
			positive += template["effect"]
	var/total = length(company_event_templates)
	if(!active || !total || company_event_chance <= 0)
		return INFINITY
	var/spread = SSeconomy.settings.stock_spread
	var/fee = SSeconomy.settings.stock_fee
	var/breakeven = (100 + spread) * (100 + fee) / ((100 - spread) * (100 - fee))
	var/real_per_hour = active * 60 / (100 / company_event_chance + STOCK_EVENT_ETA_MAX / (1 MINUTES))
	var/fakes_per_hour = 60 / max(cooldown_minutes, SSeconomy.settings.press_release_refute_minutes)
	var/best = 1
	var/fake_share = fakes_per_hour / (fakes_per_hour + real_per_hour * length(negative) / total)
	for(var/effect in negative)
		best = max(best, 1 + fake_share * (1 / (1 + effect) - 1))
	fake_share = fakes_per_hour / (fakes_per_hour + real_per_hour * length(positive) / total)
	for(var/effect in positive)
		best = max(best, 1 + fake_share * effect)
	return best / breakeven

/// Кулдаун фальшивок в минутах: настройка, а если при ней и полной бирже публика зарабатывала бы на опровержениях - ближайший безопасный.
/datum/controller/subsystem/market/proc/press_release_cooldown()
	. = SSeconomy.settings.press_release_cooldown_minutes
	if(company_event_chance <= 0 || !length(company_event_templates))
		return
	while(press_release_edge(., length(companies)) >= 1 && . < PRESS_RELEASE_COOLDOWN_LIMIT)
		. += 5

/// Ошибка конфига, если кулдаун фальшивок из настроек небезопасен; в игре всё равно действует press_release_cooldown().
/datum/controller/subsystem/market/proc/check_press_release_cooldown()
	. = list()
	var/configured = SSeconomy.settings.press_release_cooldown_minutes
	var/used = press_release_cooldown()
	if(used != configured)
		. += "settings.press_release_cooldown_minutes: при [configured] мин. покупка после плохой новости окупается на опровержениях, действует [used]"

/// Почему фальшивый релиз о компании сейчас не выйдет; null - выйдет. positive - знак новости, если уже выбран.
/datum/controller/subsystem/market/proc/press_release_problem(datum/stock_company/company, positive, datum/mind/author)
	if(!econ_harmful_objectives_allowed())
		return "Редакции сектора в эту смену фальшивок не пропустят."
	if(!company || companies[company.ticker] != company)
		return "Такой компании нет на бирже."
	if(econ_press_release_reserved(company, author))
		return "Редакции сектора сейчас не берут новостей о [company.name]."
	if(company.is_halted())
		return "Торги [company.ticker] остановлены."
	if(company.ticker in press_released)
		return "О компании [company.name] в эту смену уже выходил фальшивый релиз, второй редакции не пропустят."
	if(world.time < press_release_ready_at)
		return "Редакции сектора ещё перепроверяют прошлый слух, следующий релиз пройдёт через [DisplayTimeText(press_release_ready_at - world.time, 1)]."
	if(company_event_chance <= 0)
		return "События компаний на бирже отключены: фальшивке не с чем смешаться."
	if(press_release_edge() >= 1)
		return "На бирже сейчас слишком тихо: фальшивку сразу заметят."
	if(positive && (company.event_mult >= STOCK_EVENT_MULT_MAX || company.price >= company.base_price * STOCK_PRICE_MAX_RATIO - STOCK_PRICE_EPSILON))
		return "Акции [company.ticker] и так на потолке, хорошая новость их не сдвинет."
	if(!isnull(positive) && !positive && company.price <= STOCK_PRICE_MIN + STOCK_PRICE_EPSILON)
		return "Акции [company.ticker] и так на дне."
	return null

/// Ставит ложную новость с заголовком и сдвигом настоящего события того же знака на ближайшую свободную котировку; после выхода через press_release_refute_minutes NT её опровергает и возвращает цену. Деньги не двигает. Возвращает заголовок или null.
/datum/controller/subsystem/market/proc/fake_press_release(datum/stock_company/company, positive, origin, datum/mind/author)
	positive = !!positive
	if(press_release_problem(company, positive, author))
		return null
	var/list/candidates = list()
	for(var/list/template as anything in company_event_templates)
		if(positive ? template["effect"] > 0 : template["effect"] < 0)
			candidates += list(template)
	if(!length(candidates))
		return null
	var/list/template = pick(candidates)
	var/headline = replacetext(template["headline"], "%NAME%", company.name)
	var/datum/market_event/event = schedule_company_event(company, template["key"], headline, template["effect"], 0, TRUE)
	if(!event)
		return null
	event.press_release = TRUE
	event.press_release_origin = origin
	event.press_release_author = author ? WEAKREF(author) : null
	press_released += company.ticker
	press_release_ready_at = world.time + press_release_cooldown() MINUTES * (1 + rand() * PRESS_RELEASE_COOLDOWN_JITTER)
	return headline

/// Фальшивка ждёт, пока у компании в очереди или только что вышла настоящая новость: две новости одной компании ближе STOCK_EVENT_ETA_MIN и тика выдали бы её.
/datum/controller/subsystem/market/proc/press_release_held(datum/market_event/event)
	if(!event.press_release)
		return FALSE
	var/datum/stock_company/company = event.company
	if(company.is_halted() || (company.last_real_event_at && world.time < company.last_real_event_at + STOCK_EVENT_ETA_MIN + wait))
		return TRUE
	for(var/datum/market_event/other as anything in scheduled_events)
		if(other.company == company && !other.fake)
			return TRUE
	return FALSE

/// Опровержение отсчитывается от выхода фальшивки и возвращает цену и накопленный эффект событий каждое своим множителем.
/datum/controller/subsystem/market/proc/schedule_refutation(datum/market_event/fake, price_before, mult_before)
	var/datum/stock_company/company = fake.company
	var/price_factor = price_before / company.price
	var/datum/market_event/refutation = schedule_company_event(company, STOCK_REFUTATION_KEY, "NT опровергает сообщение «[fake.headline]»: это фальшивый пресс-релиз[fake.press_release_origin ? ", [fake.press_release_origin]" : ""]", price_factor - 1, SSeconomy.settings.press_release_refute_minutes MINUTES, TRUE)
	if(!refutation)
		return
	refutation.refutes = fake.headline
	refutation.refute_price = price_factor
	refutation.refute_mult = mult_before / company.event_mult

/// Множители цены и накопленного эффекта от ещё не вышедших опровержений: в следующую смену фальшивка не переходит.
/datum/controller/subsystem/market/proc/pending_refutation(datum/stock_company/company)
	var/price_factor = 1
	var/mult_factor = 1
	for(var/datum/market_event/event as anything in scheduled_events)
		if(event.company == company && event.refutes)
			price_factor *= event.refute_price
			mult_factor *= event.refute_mult
	return list(price_factor, mult_factor)

/// Выпускает фальшивый релиз от имени user и сообщает итог; TRUE - принят.
/proc/econ_issue_press_release(mob/user, datum/stock_company/company, positive, origin)
	var/problem = SSmarket.press_release_problem(company, !!positive, user.mind)
	if(problem)
		to_chat(user, span_warning(problem))
		return FALSE
	var/headline = SSmarket.fake_press_release(company, positive, origin, user.mind)
	if(!headline)
		to_chat(user, span_warning("Редакции не нашли, чем подкрепить такую новость."))
		return FALSE
	to_chat(user, span_notice("Релиз принят: «[headline]». Цена [company.ticker] сдвинется на ближайшей котировке, а если о компании только что вышла или вот-вот выйдет настоящая новость - через несколько минут после неё. Новость выйдет в «[MARKET_NEWS_CHANNEL]» с ближайшим выпуском. Через [DisplayTimeText(SSeconomy.settings.press_release_refute_minutes MINUTES)] после выхода NT опровергнет её и вернёт цену."))
	log_game("[key_name(user)] выпустил фальшивый пресс-релиз о [company.ticker] «[headline]»[origin ? " ([origin])" : ""] в [AREACOORD(user)]")
	message_admins("[ADMIN_LOOKUPFLW(user)] выпустил фальшивый пресс-релиз о [company.ticker]: «[headline]».")
	return TRUE

/// Выбор компании и знака новости для фальшивого релиза: list(компания, хорошая ли) или null.
/proc/econ_press_release_choice(mob/user)
	if(!user?.client)
		return
	var/list/choices = list()
	var/problem
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		problem = SSmarket.press_release_problem(company, null, user.mind)
		if(!problem)
			choices["[ticker] - [company.name], [round(company.price, 0.01)] кр."] = company
	if(!length(choices))
		to_chat(user, span_warning(problem || "На бирже нет компаний."))
		return
	var/choice = tgui_input_list(user, "О какой компании выйдет новость?", "Пресс-релиз", choices)
	if(!choice)
		return
	var/direction = tgui_alert(user, "Хорошая новость поднимет акции, плохая уронит - так же, как настоящая новость компании, на ближайшей котировке. Через [DisplayTimeText(SSeconomy.settings.press_release_refute_minutes MINUTES)] после выхода NT опровергнет её и вернёт цену.", "Пресс-релиз", list(PRESS_RELEASE_GOOD, PRESS_RELEASE_BAD))
	if(!direction)
		return
	return list(choices[choice], direction == PRESS_RELEASE_GOOD)

/// Предатель, которому аплинк продаёт эти инструменты, видит их назначение.
/proc/econ_knows_crime_tools(mob/user)
	return user?.mind?.has_antag_datum(/datum/antagonist/traitor) || user?.mind?.has_antag_datum(/datum/antagonist/overthrow)

/obj/item/insider_pager
	name = "pager"
	desc = "Старый пейджер на подписке биржевых сводок."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "pager"
	item_state = "pager"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	/// Мигание экрана, видное только держателю
	var/datum/atom_hud/alternate_appearance/basic/onePerson/alert

/obj/item/insider_pager/Initialize(mapload)
	. = ..()
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED, PROC_REF(on_stocks_ticked))

/obj/item/insider_pager/Destroy()
	UnregisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED)
	clear_alert()
	return ..()

/obj/item/insider_pager/proc/on_stocks_ticked(datum/source)
	SIGNAL_HANDLER
	update_alert()

/obj/item/insider_pager/equipped(mob/user, slot)
	. = ..()
	update_alert()

/obj/item/insider_pager/dropped(mob/user)
	. = ..()
	update_alert()

/obj/item/insider_pager/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	update_alert()

/// Мигание видит только держатель, знающий назначение пейджера, и только при настоящих событиях в очереди; сам пейджер для всех обычный.
/obj/item/insider_pager/proc/update_alert()
	var/mob/holder = loc
	var/should_blink = FALSE
	if(ismob(holder) && econ_knows_crime_tools(holder))
		for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
			if(!event.fake)
				should_blink = TRUE
				break
	if(alert && (!should_blink || alert.seer != holder))
		clear_alert()
	if(!should_blink || alert)
		return
	var/image/blink = image(icon, src, "pager_alert")
	blink.override = TRUE
	alert = add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/onePerson, "insider_pager_alert", blink, holder)

/obj/item/insider_pager/proc/clear_alert()
	if(!alert)
		return
	alert = null
	remove_alt_appearance("insider_pager_alert")

/obj/item/insider_pager/examine(mob/user)
	. = ..()
	if(!econ_knows_crime_tools(user))
		return
	. += span_notice("Инсайдерская сводка: в руке показывает настоящие события биржевых компаний, уже стоящие в очереди - заголовок, сдвиг цены и сколько осталось до выхода (от [DisplayTimeText(STOCK_EVENT_ETA_MIN)] до [DisplayTimeText(STOCK_EVENT_ETA_MAX)]). Фальшивых релизов и опровержений не видит.")
	. += span_notice("Пока у вас при себе, экран мигает, если в очереди есть настоящее событие. Мигание видите только вы: для остальных это обычный пейджер.")
	. += span_notice("Крупные сделки в сторону события, сделанные после того, как оно встало в очередь, - то есть по сводке пейджера, - финансовый аудит помечает как инсайд.")

/obj/item/insider_pager/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/insider_pager/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/insider_pager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "InsiderPager", name)
		ui.open()

/obj/item/insider_pager/ui_data(mob/user)
	if(!econ_knows_crime_tools(user))
		return list("knows" = FALSE, "events" = list())
	return list(
		"knows" = TRUE,
		"events" = queued_events(),
		"eta_min" = STOCK_EVENT_ETA_MIN / (1 SECONDS),
		"eta_max" = STOCK_EVENT_ETA_MAX / (1 SECONDS),
	)

/// Экран пейджера: настоящие события компаний в очереди, без фальшивок и опровержений.
/obj/item/insider_pager/proc/queued_events()
	. = list()
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		if(event.fake)
			continue
		. += list(list(
			"ticker" = event.company.ticker,
			"headline" = event.headline,
			"effect" = round(event.effect * 100, 1),
			"positive" = event.effect > 0,
			"eta" = round(max(event.eta - world.time, 0) / (1 SECONDS)),
		))

/obj/item/press_release_kit
	name = "press release draft"
	desc = "Пресс-релиз на фирменном бланке с подписями и печатями. Выглядит вполне официально."
	icon = 'icons/obj/economy/items.dmi'
	icon_state = "press_release"
	item_state = "press_release"
	lefthand_file = 'icons/mob/inhands/economy_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/economy_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY

/obj/item/press_release_kit/examine(mob/user)
	. = ..()
	if(!econ_knows_crime_tools(user))
		return
	. += span_notice("Фальшивый пресс-релиз, одноразовый: в руке выберите компанию и знак новости. Цена сдвинется на ближайшей котировке, как от настоящей новости, а через [DisplayTimeText(SSeconomy.settings.press_release_refute_minutes MINUTES)] после выхода NT опровергнет её и вернёт цену. Крупные сделки в сторону релиза незадолго до его выхода и сделки в сторону опровержения между выходом и опровержением попадают в финансовый аудит.")

/obj/item/press_release_kit/attack_self(mob/user)
	. = ..()
	if(!econ_knows_crime_tools(user))
		to_chat(user, span_notice("Обычный пресс-релиз на бланке. Куда и зачем его отправлять, непонятно."))
		return
	var/list/choice = econ_press_release_choice(user)
	if(choice)
		use_kit(user, choice[1], choice[2])

/obj/item/press_release_kit/proc/use_kit(mob/user, datum/stock_company/company, positive)
	if(QDELETED(src) || !user.is_holding(src) || user.incapacitated() || !econ_knows_crime_tools(user))
		return FALSE
	if(!econ_issue_press_release(user, company, positive))
		return FALSE
	qdel(src)
	return TRUE

/obj/machinery/newscaster
	/// Перепрошит емагом: Alt-клик отправляет один фальшивый пресс-релиз
	var/econ_hacked = FALSE

/obj/machinery/newscaster/emag_act(mob/user)
	. = ..()
	if(econ_hacked || (machine_stat & BROKEN))
		return
	if(!econ_harmful_objectives_allowed())
		to_chat(user, span_warning("[src] мигает, но прошивка не встаёт: редакции сектора в эту смену фальшивок не принимают."))
		return
	econ_hacked = TRUE
	log_game("[key_name(user)] перепрошил ньюскастер для фальшивого пресс-релиза в [AREACOORD(src)]")
	if(!econ_knows_crime_tools(user))
		to_chat(user, span_warning("[src] мигает и перезагружается."))
		return TRUE
	to_chat(user, span_warning("Вы перепрошиваете [src]. Alt-клик по нему отправит один фальшивый пресс-релиз в «[MARKET_NEWS_CHANNEL]»: цена выбранной компании сдвинется на ближайшей котировке, а через [DisplayTimeText(SSeconomy.settings.press_release_refute_minutes MINUTES)] после выхода NT опровергнет новость, вернёт цену и назовёт место ньюскастера. Мультитул сбрасывает прошивку."))
	return TRUE

/obj/machinery/newscaster/examine(mob/user)
	. = ..()
	if(econ_hacked)
		. += span_warning("Из сервисного разъёма торчит чужой провод.")

/obj/machinery/newscaster/AltClick(mob/user)
	. = ..()
	if(!econ_hacked || !econ_knows_crime_tools(user) || !user.canUseTopic(src, BE_CLOSE, no_tk = TRUE, silent = TRUE))
		return
	var/list/choice = econ_press_release_choice(user)
	if(choice && user.canUseTopic(src, BE_CLOSE, no_tk = TRUE))
		issue_press_release(user, choice[1], choice[2])
	return TRUE

/obj/machinery/newscaster/proc/issue_press_release(mob/user, datum/stock_company/company, positive)
	if(!econ_hacked || (machine_stat & (NOPOWER|BROKEN)) || !econ_knows_crime_tools(user))
		return FALSE
	if(!econ_issue_press_release(user, company, positive, "отправлен со взломанного ньюскастера ([get_area_name(src, TRUE)])"))
		return FALSE
	econ_hacked = FALSE
	return TRUE

/obj/machinery/newscaster/multitool_act(mob/living/user, obj/item/tool)
	if(!econ_hacked)
		return ..()
	econ_hacked = FALSE
	to_chat(user, span_notice("Вы сбрасываете прошивку [src], чужой провод больше ничего не делает."))
	log_game("[key_name(user)] сбросил взлом ньюскастера в [AREACOORD(src)]")
	return TRUE

#undef PRESS_RELEASE_BAD
#undef PRESS_RELEASE_GOOD
