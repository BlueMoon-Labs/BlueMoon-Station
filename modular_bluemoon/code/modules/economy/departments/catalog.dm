GLOBAL_VAR_INIT(econ_request_uid, 0)

/// Группа пака снабжения -> отдел, в чей каталог он входит
GLOBAL_LIST_INIT(econ_group_department, list(
	"Medical" = ACCOUNT_MED,
	"Engineering" = ACCOUNT_ENG,
	"Engine Construction" = ACCOUNT_ENG,
	"Canisters & Materials" = ACCOUNT_ENG,
	"Science" = ACCOUNT_SCI,
	"Security" = ACCOUNT_SEC,
	"Armory" = ACCOUNT_SEC,
	"Food & Hydroponics" = ACCOUNT_SRV,
	"Service" = ACCOUNT_SRV,
	"Livestock" = ACCOUNT_SRV,
))

/proc/econ_pack_department(datum/supply_pack/pack)
	return pack.department_catalog || GLOB.econ_group_department[pack.group]

/// Отделы, у которых есть паки в общем каталоге снабжения: эксклюзивы отделов в нём не показываются.
/proc/econ_group_departments()
	var/static/list/departments
	if(!departments)
		departments = list()
		for(var/group in GLOB.econ_group_department)
			departments |= GLOB.econ_group_department[group]
	return departments

/// id отдела -> его паки по группе и department_catalog в порядке SSshuttle.supply_packs; эти поля паков не меняются, флаги catalog() проверяет каждый раз.
/// Пересобирается при замене списка паков или смене его длины: подмену пака без смены длины индекс не заметит.
GLOBAL_LIST_EMPTY(econ_department_packs)
GLOBAL_LIST(econ_department_packs_source)
GLOBAL_VAR_INIT(econ_department_packs_count, 0)

/proc/econ_department_packs(department_id)
	if(GLOB.econ_department_packs_source != SSshuttle.supply_packs || GLOB.econ_department_packs_count != length(SSshuttle.supply_packs))
		GLOB.econ_department_packs_source = SSshuttle.supply_packs
		GLOB.econ_department_packs_count = length(SSshuttle.supply_packs)
		GLOB.econ_department_packs = list()
		for(var/pack_id in SSshuttle.supply_packs)
			var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
			var/owner = econ_pack_department(pack)
			if(!owner)
				continue
			if(!GLOB.econ_department_packs[owner])
				GLOB.econ_department_packs[owner] = list()
			GLOB.econ_department_packs[owner] += pack
	return GLOB.econ_department_packs[department_id] || list()

/// Цена пака у самого дешёвого партнёра с запасом; пак мимо партнёров или без поставщика - по рынку.
/proc/econ_pack_price(datum/supply_pack/pack, datum/bank_account/paying_account, allow_contraband = FALSE)
	var/datum/trade_partner/supplier = econ_pack_supplier(pack, paying_account, allow_contraband)
	return supplier ? supplier.pack_price(pack, paying_account) : pack.market_cost(paying_account)

/// Возвращает отделу или покупателю с КПК деньги за снятый с корзины предоплаченный заказ.
/proc/econ_cancel_order(datum/supply_order/order, mob/user)
	if(!order.prepaid)
		return
	if(order.personal_prepaid())
		econ_refund_personal_order(order, user)
		return
	var/datum/economy_department/department = SSeconomy.get_department(order.department_id)
	if(!department)
		stack_trace("Отмена предоплаченного заказа [order.pack.name]: нет отдела [order.department_id], [order.prepaid] кр. некому вернуть")
		return
	if(!department.account.credit(order.prepaid, ECON_REFUND, user, "Отмена заказа: [order.pack.name]"))
		stack_trace("Отмена предоплаченного заказа [order.pack.name]: возврат [order.prepaid] кр. отделу [department.name] не прошёл")
		return
	department.restore_shield(order.shield_entries)
	department.ledger_cancel_purchase(order.prepaid)
	var/topup_back = min(order.cargo_topup, order.prepaid)
	if(topup_back && SSeconomy.department_transfer(department, SSeconomy.get_department(ACCOUNT_CAR), topup_back, user))
		department.restore_shield(department.account.department_shield_spent)
		log_econ("Отмена заказа [order.pack.name] отдела [department.name]: доплата [topup_back] кр. вернулась снабжению")
	order.cargo_topup = 0
	if(order.saving_goal_until)
		department.restore_saving_goal(order.pack, order.saving_goal_until, funded = order.saving_goal_funded)
		order.saving_goal_until = 0
		order.saving_goal_funded = 0
	log_econ("[key_name(user)] снял заказ [order.pack.name] отдела [department.name], возвращено [order.prepaid] кр.")
	order.prepaid = 0

/datum/supply_order
	/// Заказ закрыл цель накопления отдела: до какого world.time она действовала, отмена заказа её возвращает
	var/saving_goal_until = 0
	/// Сколько чужого излишка было долито на цель, которую закрыл заказ: отмена возвращает его цели
	var/saving_goal_funded = 0
	/// Сколько доплатил бюджет снабжения к заказу по переданной заявке: отмена возвращает это снабжению
	var/cargo_topup = 0
	/// Заказ по заявке сотрудника: номер заявки и счёт подавшего, его карта узнает о прибытии
	var/econ_request_uid
	var/requester_account_id

/datum/supply_order/proc/cart_entry()
	var/datum/economy_department/department = prepaid ? SSeconomy.get_department(department_id) : null
	var/datum/trade_partner/supplier = econ_order_supplier(src)
	return list(
		"object" = department ? "[pack.name] (оплачено: [department.name])" : (personal_prepaid() ? "[pack.name] ([gift_to ? "подарок с КПК для [gift_to.account_holder]" : "оплачено с КПК"])" : pack.name),
		"cost" = prepaid ? 0 : econ_order_cost(src),
		"id" = id,
		"pack" = "[pack.type]",
		"supplier" = supplier?.name,
		"orderer" = orderer,
		"paid" = !isnull(paying_account),
		"prepaid" = prepaid > 0,
		"department" = department?.name,
	)

/datum/econ_request
	var/uid
	var/department_id
	var/datum/supply_pack/pack
	/// Имя подавшего
	var/requester
	var/requester_account_id
	var/reason
	var/status = ECON_REQUEST_PENDING
	var/created
	/// Одобрена и оплачена сразу при подаче
	var/instant = FALSE

/datum/econ_request/New(department_id, datum/supply_pack/pack, requester, requester_account_id, reason)
	uid = ++GLOB.econ_request_uid
	src.department_id = department_id
	src.pack = pack
	src.requester = requester
	src.requester_account_id = requester_account_id
	src.reason = reason
	created = world.time

/datum/econ_request/proc/ui_entry()
	return list(
		"uid" = uid,
		"pack" = pack.name,
		"pack_type" = "[pack.type]",
		"price" = econ_pack_price(pack),
		"requester" = requester,
		"reason" = reason,
		"status" = status,
		"waited" = waited_minutes(),
		"handed_off" = handed_off,
	)

/datum/econ_request/proc/notify_requester(message)
	var/datum/bank_account/account = SSeconomy.find_account(requester_account_id)
	account?.bank_card_talk(message)

/datum/economy_department
	/// "номер счёта" -> world.time, раньше которого заявки этого сотрудника сами не одобряются
	var/list/auto_approve_after = list()
	COOLDOWN_DECLARE(request_announce_cooldown)
	COOLDOWN_DECLARE(supply_notice_cooldown)

/datum/economy_department/proc/catalog()
	. = list()
	for(var/datum/supply_pack/pack as anything in econ_department_packs(id))
		if(econ_catalog_pack_allowed(pack))
			. += pack

/proc/econ_catalog_pack_allowed(datum/supply_pack/pack)
	if(pack.hidden || pack.contraband || pack.admin_spawned || pack.DropPodOnly || pack.goody != PACK_GOODY_NONE || pack.exclusive_consoles)
		return FALSE
	return !pack.special || pack.special_enabled

/// id отдела, в каталог которого входит пак, или null.
/proc/econ_pack_catalog_department(datum/supply_pack/pack)
	return econ_catalog_pack_allowed(pack) ? econ_pack_department(pack) : null

/// Отдел, чей бюджет оплатит заявку user на пак с окна снабжения: пак из каталога отдела, а user - его сотрудник, глава, ГП или капитан. Иначе null - заявка уходит снабжению.
/// Дорогой пак или расходник сверх часового лимита сотрудника, когда на смене некому решить (ни начальства, ни ИИ), тоже уходит снабжению. С speaker это окончательный маршрут - он пишется в лог, а speaker объясняет его подавшему.
/proc/econ_request_department(mob/living/user, datum/supply_pack/pack, atom/movable/speaker)
	var/department_id = econ_pack_catalog_department(pack)
	if(!department_id || department_id == ACCOUNT_CMD)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	if(!department?.accepts_request(user))
		return null
	if(department.can_manage(user) || department.auto_approvable(pack) || department.has_decider_on_shift() || department.staple_allowed(user, pack))
		return department
	if(speaker)
		var/staple = econ_pack_staple(pack)
		var/why_log = staple ? "часовой лимит расходников сотрудника исчерпан" : "дороже [SSeconomy.settings.auto_approve_limit] кр."
		var/why_say = staple ? "ваш часовой лимит расходников без одобрения исчерпан" : "пак дороже [SSeconomy.settings.auto_approve_limit] кр."
		log_econ("[key_name(user)]: заявка на [pack.name] ([round(econ_pack_price(pack))] кр.) ушла снабжению - в отделе [department.name] на смене некому одобрить, [why_log]")
		speaker.say("Начальства отдела [department.name][department.ai_decides() ? " и ИИ" : ""] на смене нет, а [why_say]: заявку рассмотрит снабжение за свой бюджет.")
	return null

/datum/economy_department/proc/accepts_request(mob/living/user)
	if(can_manage(user))
		return TRUE
	var/datum/bank_account/account = econ_account_of(user)
	return account?.department_id == id

/datum/economy_department/proc/radio_channel()
	var/static/list/channels = list(
		ACCOUNT_MED = RADIO_CHANNEL_MEDICAL,
		ACCOUNT_ENG = RADIO_CHANNEL_ENGINEERING,
		ACCOUNT_SCI = RADIO_CHANNEL_SCIENCE,
		ACCOUNT_SEC = RADIO_CHANNEL_SECURITY,
		ACCOUNT_SRV = RADIO_CHANNEL_SERVICE,
		ACCOUNT_CAR = RADIO_CHANNEL_SUPPLY,
		ACCOUNT_CMD = RADIO_CHANNEL_COMMAND,
	)
	return channels[id]

/// Подаёт до amount заявок отделу с окна снабжения и возвращает ответ подавшему. О ждущих решения отдел оповещает сам: через radio от speaker, если они есть.
/datum/economy_department/proc/submit_window_requests(datum/supply_pack/pack, mob/living/user, reason, amount, obj/item/radio/radio, atom/movable/speaker)
	var/datum/econ_request/repeat = instant_repeat(pack, user)
	if(repeat)
		return econ_repeat_refusal(repeat)
	var/list/approved = list()
	var/list/pending = list()
	for(var/i in 1 to amount)
		var/datum/econ_request/request = submit_request(pack, user, reason, FALSE)
		if(!request)
			break
		if(request.status == ECON_REQUEST_APPROVED)
			approved += request
		else
			pending += request
	var/submitted = length(approved) + length(pending)
	if(!submitted)
		var/datum/bank_account/requester_account = econ_account_of(user)
		var/waiting = requester_account ? pending_requests_of(requester_account.account_id) : 0
		return "У вас уже [waiting] [ru_plural(waiting, "заявка ждёт", "заявки ждут", "заявок ждут")] решения отдела [name], больше подать нельзя."
	announce_pending(pending, user, radio, speaker)
	var/list/parts = list()
	if(submitted == 1)
		var/datum/econ_request/request = length(approved) ? approved[1] : pending[1]
		parts += econ_sentence("Заявка №[request.uid] отделу [name] [length(approved) ? "одобрена и оплачена из бюджета отдела, заказ ушёл в снабжение" : pending_text(pack, user, 1)]")
	else
		parts += "Подано заявок отделу [name]: [submitted][submitted < amount ? " из [amount], больше [SSeconomy.settings.request_pending_per_requester] ждущих решения на сотрудника не бывает" : ""]."
		if(length(approved))
			parts += "[length(approved)] [ru_plural(length(approved), "одобрена и оплачена", "одобрены и оплачены", "одобрены и оплачены")] из бюджета отдела, заказ ушёл в снабжение."
		if(length(pending))
			parts += econ_sentence("[length(pending)] [pending_text(pack, user, length(pending))]")
	if(length(pending))
		var/money = money_note(pack)
		if(money)
			parts += money
		var/datum/bank_account/requester_account = econ_account_of(user)
		var/cooldown = cooldown_note(pack, requester_account?.account_id)
		if(cooldown)
			parts += cooldown
	return jointext(parts, " ")

/// Почему бюджет не оплатит пак без одобрения: не хватает денег или они отложены на зарплату сотрудникам; пусто, если хватает.
/datum/economy_department/proc/money_note(datum/supply_pack/pack)
	var/price = round(econ_pack_price(pack))
	var/balance = account.account_balance
	if(balance < price)
		return "В бюджете сейчас [balance] кр., пак стоит [price] кр.[can_save_for(pack) ? " Глава может поставить его целью накопления в \"Бюджете отдела\": NT дольёт её излишками других отделов." : ""]"
	var/reserve = owed_to_staff()
	if(balance - price < reserve)
		return "В бюджете сейчас [balance] кр., пак стоит [price] кр., но [reserve] кр. отложено на зарплату сотрудникам: без одобрения такой заказ не пройдёт."
	return ""

/// Когда недорогая заявка сотрудника снова одобрится сразу; пусто, если перерыва нет.
/datum/economy_department/proc/cooldown_note(datum/supply_pack/pack, account_id)
	if(!account_id || !auto_approvable(pack) || !instant_approval())
		return ""
	var/left = auto_approve_after["[account_id]"] - world.time
	if(left <= 0)
		return ""
	return "Без одобрения снова через [CEILING(left / (1 MINUTES), 1)] мин."

/// После заказа pack без одобрения в бюджете остаются долги и следующая зарплата сотрудникам.
/datum/economy_department/proc/keeps_wage_reserve(datum/supply_pack/pack)
	return account.account_balance - round(econ_pack_price(pack)) >= owed_to_staff()

/// Текст с точкой в конце, без второй точки после сокращения вроде "мин.".
/proc/econ_sentence(text)
	return copytext(text, -1) == "." ? text : "[text]."

/// Почему count заявок user на pack ждут; точку в конце ставит econ_sentence().
/datum/economy_department/proc/pending_text(datum/supply_pack/pack, mob/living/user, count)
	var/verb_wait = ru_plural(count, "ждёт", "ждут", "ждут")
	if(can_manage(user) || staple_allowed(user, pack))
		return "[verb_wait] денег в бюджете отдела"
	if(has_approver_on_shift())
		return "[verb_wait] решения главы, оплатит бюджет отдела"
	var/datum/economy_settings/settings = SSeconomy.settings
	if(!auto_approvable(pack))
		if(ai_decides() && econ_ai_on_shift())
			return "[verb_wait] решения ИИ: начальства отдела на смене нет, оплатит бюджет отдела"
		var/handoff = hands_off_requests() && settings.request_handoff_minutes > 0 ? "; через [settings.request_handoff_minutes] мин. её сможет решить и начальник снабжения" : ""
		var/why = econ_pack_staple(pack) ? "часовой лимит расходников без одобрения исчерпан" : "дороже [settings.auto_approve_limit] кр. заявка сама не одобряется"
		return "[verb_wait] главу, ГП или капитана[ai_decides() ? " либо ИИ" : ""]: никого из них на смене нет, а [why][handoff]"
	if(settings.auto_approve_wait_minutes > 0)
		return "[verb_wait]: начальства отдела на смене нет, [count > 1 ? "одобрятся сами" : "одобрится сама"] через [settings.auto_approve_wait_minutes] мин."
	return "[verb_wait]: начальства отдела на смене нет, решит глава, когда выйдет на смену"

/// Оповещает о ждущих заявках канал отдела, не чаще ECON_CARGO_REQUEST_RADIO_COOLDOWN на отдел, и карты тех, кто может их одобрить, - о каждой заявке, с кнопками решения.
/// Канал слышит через radio от speaker, без них - через станционную систему оповещения. Заявки главы ждут только денег, о них не оповещает.
/datum/economy_department/proc/announce_pending(list/pending, mob/living/requester, obj/item/radio/radio, atom/movable/speaker)
	if(!length(pending) || can_manage(requester))
		return FALSE
	var/datum/econ_request/first = pending[1]
	var/count = length(pending)
	var/what = "[first.pack.name][count > 1 ? " x[count]" : ""], [round(econ_pack_price(first.pack))] кр. за штуку"
	if(COOLDOWN_FINISHED(src, request_announce_cooldown))
		COOLDOWN_START(src, request_announce_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
		var/how = "Одобрить - в программе \"Бюджет отдела\" на КПК."
		var/channel = radio_channel()
		if(radio && speaker)
			econ_radio_department(radio, speaker, "Заявка №[first.uid] от [first.requester]: [what]. [how]", channel)
		else if(channel)
			paperwork_radio("Отдел \"[name]\": заявка №[first.uid] от [first.requester] ждёт решения - [what]. [how]", channel)
	var/list/links = list()
	for(var/datum/econ_request/request as anything in pending)
		links += count > 1 ? "№[request.uid]: [decision_links(request)]" : decision_links(request)
	var/head = count > 1 ? "[count] [ru_plural(count, "заявка", "заявки", "заявок")] от [first.requester] ждут" : "заявка №[first.uid] от [first.requester] ждёт"
	var/message = "Отдел \"[name]\": [head] вашего решения - [what]. [jointext(links, "; ")] - или в программе \"Бюджет отдела\" на КПК."
	for(var/datum/bank_account/manager_account as anything in managers_on_shift())
		manager_account.bank_card_talk(message)
	return TRUE

/// Счета живого начальства отдела на смене, без повторов.
/datum/economy_department/proc/managers_on_shift()
	. = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.stat == DEAD || !can_manage(player))
			continue
		var/datum/bank_account/manager_account = econ_account_of(player)
		if(manager_account)
			. |= manager_account

/// Ссылки в сообщении карты главы: решить заявку одним нажатием, не открывая программу.
/datum/economy_department/proc/decision_links(datum/econ_request/request)
	return "<a href='byond://?src=[REF(src)];econ_request=[request.uid];econ_decide=approve'>Одобрить</a> | <a href='byond://?src=[REF(src)];econ_request=[request.uid];econ_decide=deny'>Отклонить</a>"

/// Тихая строка начальству на смене о заказе без одобрения: со ссылкой отмены, пока заказ ждёт шаттла.
/datum/economy_department/proc/notify_auto_order(datum/econ_request/request, datum/supply_order/order)
	var/message = "Отдел \"[name]\": [request.requester] заказал \"[request.pack.name]\" за [order.prepaid] кр. без одобрения. <a href='byond://?src=[REF(src)];econ_cancel_order=[order.id]'>Отменить</a>"
	for(var/datum/bank_account/manager_account as anything in managers_on_shift())
		manager_account.bank_card_talk(message, quiet = TRUE)

/datum/economy_department/Topic(href, list/href_list)
	. = ..()
	var/mob/living/user = usr
	if(!isliving(user) || user.stat != CONSCIOUS || user.incapacitated())
		return
	var/cancel_id = text2num(href_list["econ_cancel_order"])
	if(isnum(cancel_id))
		to_chat(user, span_notice(cancel_from_link(user, cancel_id)))
		return
	var/decision = href_list["econ_decide"]
	var/uid = text2num(href_list["econ_request"])
	if(!(decision in list("approve", "deny")) || !isnum(uid))
		return
	to_chat(user, span_notice(decide_from_link(user, uid, decision == "approve")))

/// Отмена заказа без одобрения по ссылке из сообщения карты: деньги возвращаются бюджету, пока заказ не улетел. Возвращает ответ.
/datum/economy_department/proc/cancel_from_link(mob/living/user, order_id)
	if(!can_manage(user))
		return "Отменить заказ отдела может только глава отдела, ГП или капитан: нужна их ID-карта."
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		if(order.id != order_id || order.department_id != id || !order.prepaid)
			continue
		var/refund = order.prepaid
		econ_cancel_order(order, user)
		SSshuttle.shoppinglist -= order
		for(var/datum/econ_request/request as anything in requests)
			if(request.uid == order.econ_request_uid && request.status == ECON_REQUEST_APPROVED)
				request.status = ECON_REQUEST_DENIED
				request.notify_requester("Глава отдела отменил заказ \"[order.pack.name]\" по вашей заявке №[request.uid]: деньги вернулись в бюджет отдела.")
		return "Заказ \"[order.pack.name]\" отменён, [refund] кр. вернулись в бюджет."
	return "Заказ уже улетел шаттлом или снят с корзины: отменить его нельзя."

/// Решение заявки по ссылке из сообщения карты; возвращает ответ решившему.
/datum/economy_department/proc/decide_from_link(mob/living/user, uid, approving)
	var/datum/econ_request/request
	for(var/datum/econ_request/candidate as anything in requests)
		if(candidate.uid == uid)
			request = candidate
			break
	if(!request || request.status != ECON_REQUEST_PENDING)
		return "Заявка №[uid] уже решена."
	if(!can_decide(request, user))
		return "Решить заявку №[uid] может только глава отдела, ГП или капитан: нужна их ID-карта."
	if(!approving)
		return deny(request, user) ? "Заявка №[uid] отклонена." : "Заявка №[uid] не отклонена."
	return approve(request, user) ? "Заявка №[uid] одобрена, заказ ушёл в снабжение[request.cargo_topup ? ", недостающие [request.cargo_topup] кр. доплатил бюджет снабжения" : ""]." : order_refusal(request.pack, request, user)

/// Сколько излишка снабжения доплатит отделу к закупке за price: вся недостача, если её хватает в излишке снабжения и она не больше surplus_topup_max_share% цены; иначе 0.
/datum/economy_department/proc/surplus_topup_for(price)
	var/shortfall = price - max(account.account_balance, 0)
	if(id == ACCOUNT_CAR || shortfall <= 0 || shortfall > round(price * SSeconomy.settings.surplus_topup_max_share / 100))
		return 0
	return econ_cargo_surplus() >= shortfall ? shortfall : 0

/// Свободный излишек снабжения сверх его порога: из него доплачиваются закупки других отделов.
/proc/econ_cargo_surplus()
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	return cargo ? cargo.budget_surplus() : 0

/// Почему заказ пака за бюджет не прошёл.
/datum/economy_department/proc/order_refusal(datum/supply_pack/pack, datum/econ_request/request, mob/living/user)
	if(econ_pack_unavailable(pack))
		return "\"[pack.name]\" нет в наличии у партнёров снабжения."
	var/price = round(econ_pack_price(pack))
	if(account.account_balance < price && request && cargo_tops_up(request, user))
		return "В бюджете отдела [account.account_balance] кр. из [price], а в бюджете снабжения нет недостающих [request_shortfall(request)] кр."
	if(account.account_balance < price)
		return "В бюджете не хватает денег: \"[pack.name]\" стоит [price] кр.[id == ACCOUNT_CAR ? "" : " Излишек снабжения доплачивает до [SSeconomy.settings.surplus_topup_max_share]% цены, сейчас свободно [econ_cargo_surplus()] кр."]"
	return "Заказ не оформлен."

/// Заявки отделу с окна снабжения: ответ произносит speaker, о ждущих решения слышит канал отдела через radio.
/proc/econ_cargo_department_order(datum/economy_department/department, mob/living/user, datum/supply_pack/pack, reason, amount, atom/movable/speaker, obj/item/radio/radio)
	speaker.say(department.submit_window_requests(pack, user, reason, amount, radio, speaker))

/// Сообщение в канал отдела по радио консоли; нужный канал радио получает при первом сообщении.
/proc/econ_radio_department(obj/item/radio/radio, atom/movable/speaker, message, channel)
	if(!radio || !channel || !message)
		return
	if(!radio.channels[channel])
		radio.extra_channels[channel] = 1
		radio.recalculateChannels()
	radio.talk_into(speaker, message, channel)

/// Окну снабжения в режиме заявок: чей бюджет оплатит заявки зрителя на паки каталога отдела. ГП и капитану - бюджет отдела пака, отдел их счёта не показывается.
/// approver - есть кому одобрить заявку (начальство или ИИ): без него паки дороже auto_limit уходят снабжению, кроме расходников в пределах staple_left. instant - недорогая заявка одобряется сразу, а не ждёт начальство.
/proc/econ_budget_request_ui(mob/living/user)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/auto_limit = SSeconomy.settings.auto_approve_limit
	if(command?.can_manage(user))
		return list("manager" = TRUE, "any" = TRUE, "approver" = TRUE, "auto_limit" = auto_limit)
	var/datum/bank_account/own = econ_account_of(user)
	var/department_id = own?.department_id
	var/datum/economy_department/department = (department_id in econ_group_departments()) ? SSeconomy.get_department(department_id) : null
	if(!department)
		return null
	var/manager = department.can_manage(user)
	return list(
		"id" = department.id,
		"name" = department.name,
		"balance" = department.account.account_balance,
		"manager" = manager,
		"any" = FALSE,
		"approver" = manager || department.has_decider_on_shift(),
		"auto_limit" = auto_limit,
		"instant" = department.instant_approval(),
		"auto_cooldown" = SSeconomy.settings.auto_approve_cooldown_minutes,
		"staple_left" = department.staple_left(own.account_id),
	)

/// Глава отдела и капитан по доступу ID; ГП - по должности и с доступом ГП на ID. ACCESS_HOP есть и у бридж-офицера, поэтому одного доступа мало.
/datum/economy_department/proc/can_manage(mob/living/user)
	if(!isliving(user))
		return FALSE
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card)
		return FALSE
	var/list/card_access = card.GetAccess()
	var/datum/job/hop/hop_job = /datum/job/hop
	if(user.mind?.assigned_role == initial(hop_job.title) && (ACCESS_HOP in card_access))
		return TRUE
	for(var/access in (head_access - ACCESS_HOP) + ACCESS_CAPTAIN)
		if(access in card_access)
			return TRUE
	return FALSE

/datum/economy_department/proc/has_approver_on_shift()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player.stat != DEAD && can_manage(player))
			return TRUE
	return FALSE

/datum/economy_department/proc/pending_requests_of(account_id)
	. = 0
	for(var/datum/econ_request/request as anything in requests)
		if(request.requester_account_id == account_id && request.status == ECON_REQUEST_PENDING)
			.++

/// Без announce о ждущей заявке оповещает вызывающий: окно снабжения оповещает о пачке заявок разом.
/datum/economy_department/proc/submit_request(datum/supply_pack/pack, mob/living/user, reason, announce = TRUE)
	if(!pack || !(pack in catalog()))
		return null
	if(!accepts_request(user))
		return null
	var/datum/bank_account/requester_account = econ_account_of(user)
	var/account_id = requester_account?.account_id
	if(account_id && pending_requests_of(account_id) >= SSeconomy.settings.request_pending_per_requester)
		return null
	var/datum/econ_request/request = new(id, pack, econ_public_name(user), account_id, reason)
	requests += request
	econ_trim_resolved(requests)
	log_econ("[key_name(user)] подал заявку [request.uid] отделу [name]: [pack.name] ([econ_pack_price(pack)] кр.), причина: [reason]")
	if(can_manage(user))
		approve(request, user)
	else if(!approve_staple(request) && account_id && auto_approvable(pack) && instant_approval() && world.time >= auto_approve_after["[account_id]"])
		if(approve(request, null, TRUE))
			auto_approve_after["[account_id]"] = world.time + SSeconomy.settings.auto_approve_cooldown_minutes MINUTES
	request.instant = request.status == ECON_REQUEST_APPROVED
	if(announce && request.status == ECON_REQUEST_PENDING)
		announce_pending(list(request), user)
	return request

/// Заявка на тот же пак, которую этот сотрудник только что подал и она сразу оплачена: повторное нажатие кнопки второй пак не заказывает.
/datum/economy_department/proc/instant_repeat(datum/supply_pack/pack, mob/living/user)
	var/datum/bank_account/account = econ_account_of(user)
	if(!account)
		return null
	for(var/datum/econ_request/request as anything in requests)
		if(request.instant && request.pack == pack && request.requester_account_id == account.account_id && world.time - request.created < ECON_REQUEST_REPEAT_GUARD)
			return request

/proc/econ_repeat_refusal(datum/econ_request/request)
	return "Заявка №[request.uid] на \"[request.pack.name]\" только что оплачена, повторное нажатие второй пак не заказывает. Нужен ещё один - подайте заявку снова чуть позже."

/// Одобряет расходники, которым теперь хватает денег, и недорогие заявки, которые ждут ответа дольше auto_approve_wait_minutes (у СБ - только без начальства на смене). Без денег сверх зарплаты сотрудникам заявка ждёт следующего тика.
/datum/economy_department/proc/approve_stale_requests()
	var/datum/economy_settings/settings = SSeconomy.settings
	for(var/datum/econ_request/request as anything in requests.Copy())
		if(request.status != ECON_REQUEST_PENDING || approve_staple(request))
			continue
		if(settings.auto_approve_wait_minutes > 0 && instant_approval() && world.time - request.created >= settings.auto_approve_wait_minutes MINUTES && auto_approvable(request.pack))
			approve(request, null, TRUE)

/// Недорогая заявка сотрудника одобряется сразу, даже при начальстве на смене; у СБ - только когда начальства нет.
/datum/economy_department/proc/instant_approval()
	return id != ACCOUNT_SEC || !has_approver_on_shift()

/// Пак одобряется сам по обычному пути: не дороже auto_approve_limit и не расходник - расходники одобряются сами только в часовом лимите сотрудника.
/datum/economy_department/proc/auto_approvable(datum/supply_pack/pack)
	return !econ_pack_staple(pack) && econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit

/// Оставляет в списке заявок все ожидающие и ECON_REQUESTS_KEPT последних решённых.
/proc/econ_trim_resolved(list/requests)
	var/resolved = 0
	for(var/i in length(requests) to 1 step -1)
		var/datum/econ_request/request = requests[i]
		if(request.status != ECON_REQUEST_PENDING && ++resolved > ECON_REQUESTS_KEPT)
			requests.Cut(i, i + 1)
			qdel(request)

/// automatic - без решения человека: такой заказ не трогает деньги, отложенные на долги и следующую зарплату сотрудникам, а начальство получает строку на карту с отменой.
/datum/economy_department/proc/approve(datum/econ_request/request, mob/living/user, automatic = FALSE)
	if(!(request in requests) || request.status != ECON_REQUEST_PENDING || (!automatic && !can_decide(request, user)))
		return FALSE
	if(automatic && !keeps_wage_reserve(request.pack))
		return FALSE
	var/by_manager = !automatic && can_manage(user)
	var/topup = 0
	if(!automatic && cargo_tops_up(request, user) && (request.pack in catalog()) && !econ_pack_unavailable(request.pack))
		topup = cargo_top_up(request, user)
		if(isnull(topup))
			return FALSE
	var/datum/supply_order/order = order_pack(request.pack, user, "Заявка [request.requester]: [request.reason]", automatic || !by_manager, !automatic)
	if(!order)
		if(topup && SSeconomy.department_transfer(src, SSeconomy.get_department(ACCOUNT_CAR), topup, user))
			restore_shield(account.department_shield_spent)
		return FALSE
	if(topup)
		log_econ("Снабжение доплатило [topup] кр. к заявке [request.uid] отдела [name]: [key_name(user)]")
	var/from_surplus = order.cargo_topup
	topup += from_surplus
	request.cargo_topup = topup
	order.cargo_topup = topup
	order.econ_request_uid = request.uid
	order.requester_account_id = request.requester_account_id
	request.status = ECON_REQUEST_APPROVED
	var/by_whom = automatic || by_manager ? "" : (isAI(user) ? " ИИ" : " снабжением")
	log_econ("Заявка [request.uid] отдела [name] одобрена[by_whom]: [automatic ? "автоматически" : key_name(user)]")
	request.notify_requester("Заявка на \"[request.pack.name]\" одобрена[by_whom] и ушла в снабжение[topup ? ", недостающие [topup] кр. доплатил бюджет снабжения" : ""].")
	if(topup)
		account.bank_card_talk("[from_surplus ? "Заявка" : "Переданная снабжению заявка"] №[request.uid] на \"[request.pack.name]\" одобрена: бюджет снабжения доплатил недостающие [topup] кр.")
	if(automatic)
		notify_auto_order(request, order)
	econ_trim_resolved(requests)
	return TRUE

/datum/economy_department/proc/deny(datum/econ_request/request, mob/living/user)
	if(!(request in requests) || request.status != ECON_REQUEST_PENDING || !can_decide(request, user))
		return FALSE
	request.status = ECON_REQUEST_DENIED
	log_econ("[key_name(user)] отклонил заявку [request.uid] отдела [name]")
	request.notify_requester("Заявка на \"[request.pack.name]\" отклонена[can_manage(user) ? "" : (isAI(user) ? " ИИ" : " снабжением")].")
	econ_trim_resolved(requests)
	return TRUE

/// Заказ из каталога или пачки скупки для отдела за счёт бюджета: деньги списываются сразу, заказ встаёт в очередь снабжения предоплаченным. Возвращает заказ или FALSE.
/// surplus_topup - решение человека или ИИ: недостающее до цены доплачивает излишек снабжения (surplus_topup_for).
/datum/economy_department/proc/order_pack(datum/supply_pack/pack, mob/living/user, reason, automatic = FALSE, surplus_topup = FALSE)
	if(!pack || !(econ_bundle_department(pack) == id || (pack in catalog())) || (!automatic && !can_manage(user)) || econ_pack_unavailable(pack))
		return FALSE
	var/price = round(econ_pack_price(pack))
	var/datum/economy_department/cargo = SSeconomy.get_department(ACCOUNT_CAR)
	var/topup = surplus_topup ? surplus_topup_for(price) : 0
	if(topup)
		if(SSeconomy.department_transfer(cargo, src, topup, user))
			cargo.restore_shield(cargo.account.department_shield_spent)
		else
			topup = 0
	if(!account.debit(price, ECON_IMPORT, user, "Закупка: [pack.name]"))
		if(topup && SSeconomy.department_transfer(src, cargo, topup, user))
			restore_shield(account.department_shield_spent)
		return FALSE
	var/orderer_name = name
	var/orderer_rank = name
	if(ishuman(user))
		var/mob/living/carbon/human/human_user = user
		orderer_name = human_user.get_authentification_name()
		orderer_rank = human_user.get_assignment(hand_first = TRUE)
	var/datum/supply_order/order = new(pack, orderer_name, orderer_rank, user?.ckey, reason)
	order.prepaid = price
	order.department_id = id
	order.cargo_topup = topup
	SSshuttle.shoppinglist += order
	order.shield_entries = account.department_shield_spent
	if(pack == saving_goal)
		order.saving_goal_until = saving_goal_until || (world.time + SSeconomy.settings.saving_goal_minutes MINUTES)
		order.saving_goal_funded = saving_goal_funded
		clear_saving_goal(ordered = TRUE)
	log_econ("[user ? key_name(user) : "Автоодобрение"]: заказ [pack.name] для [name] за [price] кр.")
	if(topup)
		log_econ("Излишек снабжения доплатил [topup] кр. к закупке [pack.name] отдела [name]")
	if(id != ACCOUNT_CAR && COOLDOWN_FINISHED(src, supply_notice_cooldown))
		COOLDOWN_START(src, supply_notice_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
		paperwork_radio("Отдел \"[name]\" оплатил заказ: [pack.name], в корзине снабжения.", RADIO_CHANNEL_SUPPLY)
	return order
