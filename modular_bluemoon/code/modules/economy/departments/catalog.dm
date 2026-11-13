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
/// Дорогой пак без начальства на смене тоже уходит снабжению: сам он не одобрится. С speaker это окончательный маршрут - он пишется в лог, а speaker объясняет его подавшему.
/proc/econ_request_department(mob/living/user, datum/supply_pack/pack, atom/movable/speaker)
	var/department_id = econ_pack_catalog_department(pack)
	if(!department_id || department_id == ACCOUNT_CMD)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	if(!department?.accepts_request(user))
		return null
	if(department.can_manage(user) || econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit || department.has_approver_on_shift())
		return department
	if(speaker)
		log_econ("[key_name(user)]: заявка на [pack.name] ([round(econ_pack_price(pack))] кр.) ушла снабжению - в отделе [department.name] на смене некому одобрить дороже [SSeconomy.settings.auto_approve_limit] кр.")
		speaker.say("Начальства отдела [department.name] на смене нет, а пак дороже [SSeconomy.settings.auto_approve_limit] кр.: заявку рассмотрит снабжение за свой бюджет.")
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
		parts += "Заявка №[request.uid] отделу [name] [length(approved) ? "одобрена и оплачена из бюджета отдела, заказ ушёл в снабжение" : pending_text(pack, user, 1)]."
	else
		parts += "Подано заявок отделу [name]: [submitted][submitted < amount ? " из [amount], больше [SSeconomy.settings.request_pending_per_requester] ждущих решения на сотрудника не бывает" : ""]."
		if(length(approved))
			parts += "[length(approved)] [ru_plural(length(approved), "одобрена и оплачена", "одобрены и оплачены", "одобрены и оплачены")] из бюджета отдела, заказ ушёл в снабжение."
		if(length(pending))
			parts += "[length(pending)] [pending_text(pack, user, length(pending))]."
	var/price = round(econ_pack_price(pack))
	if(length(pending) && account.account_balance < price)
		parts += "В бюджете сейчас [account.account_balance] кр., пак стоит [price] кр."
	return jointext(parts, " ")

/// Почему count заявок user на pack ждут, без точки в конце.
/datum/economy_department/proc/pending_text(datum/supply_pack/pack, mob/living/user, count)
	var/verb_wait = ru_plural(count, "ждёт", "ждут", "ждут")
	if(can_manage(user))
		return "[verb_wait] денег в бюджете отдела"
	if(has_approver_on_shift())
		return "[verb_wait] решения главы, оплатит бюджет отдела"
	var/datum/economy_settings/settings = SSeconomy.settings
	if(econ_pack_price(pack) > settings.auto_approve_limit)
		return "[verb_wait] главу, ГП или капитана: начальства на смене нет, а дороже [settings.auto_approve_limit] кр. заявка сама не одобряется"
	if(settings.auto_approve_wait_minutes > 0)
		return "[verb_wait]: начальства отдела на смене нет, [count > 1 ? "одобрятся сами" : "одобрится сама"] через [settings.auto_approve_wait_minutes] мин."
	return "[verb_wait]: начальства отдела на смене нет, решит глава, когда выйдет на смену"

/// Оповещает о ждущих заявках канал отдела и карты тех, кто может их одобрить, не чаще ECON_CARGO_REQUEST_RADIO_COOLDOWN на отдел.
/// Канал слышит через radio от speaker, без них - через станционную систему оповещения. Заявки главы ждут только денег, о них не оповещает.
/datum/economy_department/proc/announce_pending(list/pending, mob/living/requester, obj/item/radio/radio, atom/movable/speaker)
	if(!length(pending) || can_manage(requester) || !COOLDOWN_FINISHED(src, request_announce_cooldown))
		return FALSE
	COOLDOWN_START(src, request_announce_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
	var/datum/econ_request/first = pending[1]
	var/what = "[first.pack.name][length(pending) > 1 ? " x[length(pending)]" : ""], [round(econ_pack_price(first.pack))] кр. за штуку"
	var/how = "Одобрить - в программе \"Бюджет отдела\" на КПК."
	var/channel = radio_channel()
	if(radio && speaker)
		econ_radio_department(radio, speaker, "Заявка №[first.uid] от [first.requester]: [what]. [how]", channel)
	else if(channel)
		paperwork_radio("Отдел \"[name]\": заявка №[first.uid] от [first.requester] ждёт решения - [what]. [how]", channel)
	var/list/told = list()
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player == requester || player.stat == DEAD || !can_manage(player))
			continue
		var/datum/bank_account/manager_account = econ_account_of(player)
		if(!manager_account || (manager_account in told))
			continue
		told += manager_account
		manager_account.bank_card_talk("Отдел \"[name]\": заявка №[first.uid] от [first.requester] ждёт вашего решения - [what]. [how]")
	return TRUE

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
/// approver - есть кому одобрить заявку: без него паки дороже auto_limit уходят снабжению.
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
		"approver" = manager || department.has_approver_on_shift(),
		"auto_limit" = auto_limit,
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
	else if(account_id && econ_pack_price(pack) <= SSeconomy.settings.auto_approve_limit && !has_approver_on_shift() && world.time >= auto_approve_after["[account_id]"])
		if(approve(request, null, TRUE))
			auto_approve_after["[account_id]"] = world.time + SSeconomy.settings.auto_approve_cooldown_minutes MINUTES
	if(announce && request.status == ECON_REQUEST_PENDING)
		announce_pending(list(request), user)
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
	if(id != ACCOUNT_CAR && COOLDOWN_FINISHED(src, supply_notice_cooldown))
		COOLDOWN_START(src, supply_notice_cooldown, ECON_CARGO_REQUEST_RADIO_COOLDOWN)
		paperwork_radio("Отдел \"[name]\" оплатил заказ: [pack.name], в корзине снабжения.", RADIO_CHANNEL_SUPPLY)
	return TRUE
