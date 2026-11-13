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

/// Возвращает отделу деньги за снятый с корзины предоплаченный заказ.
/proc/econ_cancel_order(datum/supply_order/order, mob/user)
	if(!order.prepaid)
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
	if(order.saving_goal_until)
		department.restore_saving_goal(order.pack, order.saving_goal_until)
		order.saving_goal_until = 0
	log_econ("[key_name(user)] снял заказ [order.pack.name] отдела [department.name], возвращено [order.prepaid] кр.")
	order.prepaid = 0

/datum/supply_order
	/// Заказ закрыл цель накопления отдела: до какого world.time она действовала, отмена заказа её возвращает
	var/saving_goal_until = 0

/datum/supply_order/proc/cart_entry()
	var/datum/economy_department/department = prepaid ? SSeconomy.get_department(department_id) : null
	var/datum/trade_partner/supplier = econ_order_supplier(src)
	return list(
		"object" = department ? "[pack.name] (оплачено: [department.name])" : pack.name,
		"cost" = department ? 0 : econ_order_cost(src),
		"id" = id,
		"pack" = "[pack.type]",
		"supplier" = supplier?.name,
		"orderer" = orderer,
		"paid" = !isnull(paying_account),
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
		"price" = econ_pack_price(pack),
		"requester" = requester,
		"reason" = reason,
		"status" = status,
	)

/datum/econ_request/proc/notify_requester(message)
	var/datum/bank_account/account = SSeconomy.find_account(requester_account_id)
	account?.bank_card_talk(message)

/datum/economy_department
	/// "номер счёта" -> world.time, раньше которого заявки этого сотрудника сами не одобряются
	var/list/auto_approve_after = list()
	COOLDOWN_DECLARE(request_announce_cooldown)

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
/proc/econ_request_department(mob/living/user, datum/supply_pack/pack)
	var/department_id = econ_pack_catalog_department(pack)
	if(!department_id || department_id == ACCOUNT_CMD)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	return department?.accepts_request(user) ? department : null

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

/// Подаёт до amount заявок отделу с окна снабжения. Возвращает list(ответ подавшему, сообщение каналу отдела или null): о ждущих заявках канал слышит не чаще ECON_CARGO_REQUEST_RADIO_COOLDOWN.
/datum/economy_department/proc/submit_window_requests(datum/supply_pack/pack, mob/living/user, reason, amount)
	var/list/approved = list()
	var/list/pending = list()
	for(var/i in 1 to amount)
		var/datum/econ_request/request = submit_request(pack, user, reason)
		if(!request)
			break
		if(request.status == ECON_REQUEST_APPROVED)
			approved += request
		else
			pending += request
	var/limit = SSeconomy.settings.request_pending_per_requester
	var/submitted = length(approved) + length(pending)
	if(!submitted)
		return list("Заявку не приняли: решения отдела [name] ждут уже все ваши заявки, не больше [limit] на сотрудника.", null)
	var/list/parts = list()
	if(submitted == 1)
		var/datum/econ_request/request = length(approved) ? approved[1] : pending[1]
		parts += "Заявка №[request.uid] отдела [name]:"
	else
		parts += "Заявки отделу [name], подано [submitted][submitted < amount ? " из [amount]: решения ждут не больше [limit] ваших заявок" : ""]."
	if(length(approved))
		parts += "[length(approved) > 1 ? "[length(approved)] одобрено" : "одобрена"], оплачено из бюджета отдела, заказ ушёл в снабжение."
	if(!length(pending))
		return list(jointext(parts, " "), null)
	var/price = round(econ_pack_price(pack))
	var/manager = can_manage(user)
	parts += "[length(pending) > 1 ? "[length(pending)] ждут" : "ждёт"] [manager ? "денег в бюджете" : "решения главы"], оплатит бюджет отдела."
	if(account.account_balance < price)
		parts += "В бюджете сейчас [account.account_balance] кр., пак стоит [price] кр."
	var/announce
	if(!manager && COOLDOWN_FINISHED(src, request_announce_cooldown))
		COOLDOWN_START(src, request_announce_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
		var/datum/econ_request/first = pending[1]
		announce = "Заявка №[first.uid] от [first.requester]: [pack.name][length(pending) > 1 ? " x[length(pending)]" : ""], [price] кр. за штуку. Одобрить - в программе \"Бюджет отдела\" на КПК."
	return list(jointext(parts, " "), announce)

/// Заявки отделу с окна снабжения: ответ произносит speaker, о ждущих решения слышит канал отдела через radio.
/proc/econ_cargo_department_order(datum/economy_department/department, mob/living/user, datum/supply_pack/pack, reason, amount, atom/movable/speaker, obj/item/radio/radio)
	var/list/result = department.submit_window_requests(pack, user, reason, amount)
	speaker.say(result[1])
	econ_radio_department(radio, speaker, result[2], department.radio_channel())

/// Сообщение в канал отдела по радио консоли; нужный канал радио получает при первом сообщении.
/proc/econ_radio_department(obj/item/radio/radio, atom/movable/speaker, message, channel)
	if(!radio || !channel || !message)
		return
	if(!radio.channels[channel])
		radio.extra_channels[channel] = 1
		radio.recalculateChannels()
	radio.talk_into(speaker, message, channel)

/// Окну снабжения в режиме заявок: чей бюджет оплатит заявки зрителя на паки каталога отдела. ГП и капитану - бюджет отдела пака.
/proc/econ_budget_request_ui(mob/living/user)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/any = !!command?.can_manage(user)
	var/datum/bank_account/own = econ_account_of(user)
	var/department_id = own?.department_id
	var/datum/economy_department/department = (department_id in econ_group_departments()) ? SSeconomy.get_department(department_id) : null
	if(!department && !any)
		return null
	return list(
		"id" = department?.id,
		"name" = department?.name,
		"balance" = department?.account.account_balance,
		"manager" = any || !!department?.can_manage(user),
		"any" = any,
		"auto_limit" = SSeconomy.settings.auto_approve_limit,
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

/datum/economy_department/proc/submit_request(datum/supply_pack/pack, mob/living/user, reason)
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
	else if(account_id && econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit && !has_approver_on_shift() && world.time >= auto_approve_after["[account_id]"])
		if(approve(request, null, TRUE))
			auto_approve_after["[account_id]"] = world.time + SSeconomy.settings.auto_approve_cooldown_minutes MINUTES
	return request

/// Одобряет недорогие заявки, которые ждут ответа дольше auto_approve_wait_minutes. Без денег заявка ждёт следующего тика.
/datum/economy_department/proc/approve_stale_requests()
	var/datum/economy_settings/settings = SSeconomy.settings
	if(settings.auto_approve_wait_minutes <= 0)
		return
	for(var/datum/econ_request/request as anything in requests.Copy())
		if(request.status == ECON_REQUEST_PENDING && world.time - request.created >= settings.auto_approve_wait_minutes MINUTES && econ_pack_price(request.pack) <= settings.auto_approve_limit)
			approve(request, null, TRUE)

/// Оставляет в списке заявок все ожидающие и ECON_REQUESTS_KEPT последних решённых.
/proc/econ_trim_resolved(list/requests)
	var/resolved = 0
	for(var/i in length(requests) to 1 step -1)
		var/datum/econ_request/request = requests[i]
		if(request.status != ECON_REQUEST_PENDING && ++resolved > ECON_REQUESTS_KEPT)
			requests.Cut(i, i + 1)
			qdel(request)

/datum/economy_department/proc/approve(datum/econ_request/request, mob/living/user, automatic = FALSE)
	if(!(request in requests) || request.status != ECON_REQUEST_PENDING || (!automatic && !can_manage(user)))
		return FALSE
	if(!order_pack(request.pack, user, "Заявка [request.requester]: [request.reason]", automatic))
		return FALSE
	request.status = ECON_REQUEST_APPROVED
	log_econ("Заявка [request.uid] отдела [name] одобрена: [automatic ? "автоматически" : key_name(user)]")
	request.notify_requester("Заявка на \"[request.pack.name]\" одобрена и ушла в снабжение.")
	econ_trim_resolved(requests)
	return TRUE

/datum/economy_department/proc/deny(datum/econ_request/request, mob/living/user)
	if(!(request in requests) || request.status != ECON_REQUEST_PENDING || !can_manage(user))
		return FALSE
	request.status = ECON_REQUEST_DENIED
	log_econ("[key_name(user)] отклонил заявку [request.uid] отдела [name]")
	request.notify_requester("Заявка на \"[request.pack.name]\" отклонена.")
	econ_trim_resolved(requests)
	return TRUE

/// Заказ из каталога за счёт бюджета: деньги списываются сразу, заказ встаёт в очередь снабжения предоплаченным.
/datum/economy_department/proc/order_pack(datum/supply_pack/pack, mob/living/user, reason, automatic = FALSE)
	if(!pack || !(pack in catalog()) || (!automatic && !can_manage(user)) || econ_pack_unavailable(pack))
		return FALSE
	var/price = round(econ_pack_price(pack))
	if(!account.debit(price, ECON_IMPORT, user, "Закупка: [pack.name]"))
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
	SSshuttle.shoppinglist += order
	order.shield_entries = account.department_shield_spent
	if(pack == saving_goal)
		order.saving_goal_until = saving_goal_until
		clear_saving_goal(ordered = TRUE)
	log_econ("[automatic ? "Автоодобрение" : key_name(user)]: заказ [pack.name] для [name] за [price] кр.")
	return TRUE
