/// Эстафеты отделов: этапы по очереди выходят на доски своих отделов. Этап - обычный контракт деятельности ("contract") или поставки заказа из пула отдела ("bounty" - базовый тип), label - кто его делает.
GLOBAL_LIST_INIT(econ_relay_templates, list(
	list("title" = "От грядки до бокала", "stages" = list(
		list("department" = ACCOUNT_SRV, "label" = "ботаника", "contract" = /datum/econ_contract/activity/service_plants),
		list("department" = ACCOUNT_SRV, "label" = "кухня", "contract" = /datum/econ_contract/activity/service_dishes),
		list("department" = ACCOUNT_SRV, "label" = "бар", "contract" = /datum/econ_contract/activity/service_drinks),
	)),
	list("title" = "Лекарства для медбея", "stages" = list(
		list("department" = ACCOUNT_MED, "label" = "химия", "bounty" = /datum/bounty/reagent/chemical),
		list("department" = ACCOUNT_MED, "label" = "медицина", "contract" = /datum/econ_contract/activity/medical_discharges),
	)),
	list("title" = "Руда для науки", "stages" = list(
		list("department" = ACCOUNT_CAR, "label" = "шахта", "contract" = /datum/econ_contract/activity/cargo_ore),
		list("department" = ACCOUNT_SCI, "label" = "наука", "contract" = /datum/econ_contract/activity/science_nodes),
	)),
))

/// Канал отдела, которому эстафета сообщает о его очереди.
GLOBAL_LIST_INIT(econ_department_radio, list(
	ACCOUNT_MED = RADIO_CHANNEL_MEDICAL,
	ACCOUNT_ENG = RADIO_CHANNEL_ENGINEERING,
	ACCOUNT_SCI = RADIO_CHANNEL_SCIENCE,
	ACCOUNT_SRV = RADIO_CHANNEL_SERVICE,
	ACCOUNT_SEC = RADIO_CHANNEL_SECURITY,
	ACCOUNT_CAR = RADIO_CHANNEL_SUPPLY,
))

/datum/controller/subsystem/economy
	/// Идущие эстафеты отделов
	var/list/relays = list()

/// Эстафета, которая начинается с отдела department_id и ещё не идёт; её первый этап уже на доске. null, если такой нет.
/datum/controller/subsystem/economy/proc/start_relay(department_id)
	var/list/candidates = list()
	for(var/list/template as anything in GLOB.econ_relay_templates)
		var/list/stages = template["stages"]
		var/list/first = stages[1]
		if(first["department"] == department_id && !relay_running(template["title"]))
			candidates += list(template)
	if(!length(candidates))
		return null
	return begin_relay(pick(candidates))

/datum/controller/subsystem/economy/proc/relay_running(title)
	for(var/datum/econ_relay/relay as anything in relays)
		if(relay.title == title)
			return relay

/// Запускает эстафету по шаблону: возвращает её первый этап, уже выставленный на доску.
/datum/controller/subsystem/economy/proc/begin_relay(list/template)
	var/datum/econ_relay/relay = new(template)
	relays += relay
	var/datum/econ_contract/first = relay.advance()
	var/channel = first && GLOB.econ_department_radio[first.department_id]
	if(channel)
		paperwork_radio("Эстафета «[relay.title]» началась: первой идёт [relay.stage_label(1)] - «[first.title]» на доске контрактов, на этап [relay.stage_minutes()] мин., дальше - [relay.next_labels()].", channel)
	return first

/// Эстафета отделов: этапы идут по одному, каждый платит своему отделу, за последний - премия от суммы этапов, всё вместе - не выше потолка серий.
/datum/econ_relay
	var/title
	var/list/stages
	var/stage = 0
	/// Сумма наград выполненных этапов
	var/paid = 0
	var/datum/econ_contract/current
	/// Когда нынешний этап вышел на доску
	var/stage_posted_at = 0

/datum/econ_relay/New(list/template)
	title = template["title"]
	stages = template["stages"]

/datum/econ_relay/Destroy()
	SSeconomy.relays -= src
	var/datum/econ_contract/stage_contract = current
	current = null
	if(stage_contract && !QDELETED(stage_contract))
		stage_contract.relay = null
		qdel(stage_contract)
	return ..()

/datum/econ_relay/proc/stage_label(number)
	var/list/spec = stages[number]
	return spec["label"]

/// "кухня, бар": кто делает этапы после нынешнего.
/datum/econ_relay/proc/next_labels()
	var/list/labels = list()
	for(var/number in stage + 1 to length(stages))
		labels += stage_label(number)
	return jointext(labels, ", ")

/datum/econ_relay/proc/final_stage()
	return stage >= length(stages)

/// Сколько невзятый этап ждёт свой отдел: несколько ротаций доски, а не одну, как обычный контракт.
/datum/econ_relay/proc/stage_lifetime()
	return SSeconomy.contract_rotation_age() * max(SSeconomy.settings.contract_relay_stage_rotations, 1)

/datum/econ_relay/proc/stage_minutes()
	return round(stage_lifetime() / (1 MINUTES))

/datum/econ_relay/proc/stage_due_at()
	return stage_posted_at + stage_lifetime()

/// Выставляет следующий этап на доску его отдела. Возвращает контракт этапа; если этапы кончились или этап не собрать - эстафета удаляется и возвращается null.
/datum/econ_relay/proc/advance()
	stage++
	if(stage > length(stages))
		log_econ("Эстафета \"[title]\" пройдена: выплачено [paid] кр.")
		qdel(src)
		return null
	var/list/spec = stages[stage]
	var/department_id = spec["department"]
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	stage_posted_at = world.time
	var/datum/econ_contract/contract = department && busy_same_activity(department, spec["contract"])
	if(contract)
		claim_stage(contract)
		return contract
	if(department)
		contract = make_stage(spec, department_id)
	if(!contract)
		log_econ("Эстафета \"[title]\" оборвалась: этап [stage] ([spec["label"]]) не собрать")
		qdel(src)
		return null
	claim_stage(contract)
	// Одна и та же работа не платит дважды: свободный такой же контракт деятельности уступает место этапу, а взятый или начатый сам становится этапом.
	for(var/datum/econ_contract/activity/existing in department.contracts.Copy())
		if(existing != contract && existing.type == contract.type && !existing.relay && !existing.taker && !existing.started() && !existing.pinned)
			qdel(existing)
	department.contracts |= contract
	return contract

/// Контракт становится нынешним этапом. Свой срок деятельности короче срока этапа: невзятый этап снимает ротация, а взятому срок даст take().
/datum/econ_relay/proc/claim_stage(datum/econ_contract/contract)
	contract.relay = src
	current = contract
	if(!contract.taker && !contract.urgent)
		contract.deadline = 0

/// Взятый или начатый такой же контракт деятельности на доске отдела: его не снять, этапом станет он.
/datum/econ_relay/proc/busy_same_activity(datum/economy_department/department, contract_type)
	if(!contract_type)
		return null
	for(var/datum/econ_contract/activity/existing in department.contracts)
		if(existing.type == contract_type && !existing.relay && !existing.pinned && !existing.completed && (existing.taker || existing.started()))
			return existing

/datum/econ_relay/proc/make_stage(list/spec, department_id)
	var/contract_type = spec["contract"]
	if(contract_type)
		var/datum/econ_contract/contract = new contract_type(department_id)
		if(contract.postable())
			return contract
		qdel(contract)
		return null
	var/list/by_department = econ_bounty_types_by_department()
	var/list/pool = by_department[department_id]
	var/list/candidates = list()
	for(var/bounty_type in typesof(spec["bounty"]))
		if(bounty_type in pool)
			candidates += bounty_type
	var/datum/bounty/bounty = SSeconomy.pick_bounty(candidates)
	if(bounty)
		return new /datum/econ_contract/delivery(department_id, bounty)

/// Награда этапа contract: на последнем - с премией от суммы этапов, вместе с выплаченными - не выше потолка серий.
/datum/econ_relay/proc/stage_payout(datum/econ_contract/contract)
	. = contract.payout()
	if(final_stage())
		. += round((paid + .) * SSeconomy.settings.contract_chain_bonus / 100)
	return econ_chain_capped(., paid)

/// Этап выполнен и оплачен: следующий выходит на доску своего отдела, а отдел слышит об этом по своему каналу.
/datum/econ_relay/proc/stage_done(datum/econ_contract/contract, total)
	if(contract != current)
		return
	paid += total
	contract.relay = null
	current = null
	var/done_label = stage_label(stage)
	log_econ("Эстафета \"[title]\": этап [stage] из [length(stages)] ([done_label]) выполнен, [total] кр., всего [paid] кр.")
	var/datum/econ_contract/next = advance()
	if(!next)
		return
	var/channel = GLOB.econ_department_radio[next.department_id]
	if(channel)
		paperwork_radio("Эстафета «[title]»: [done_label] справилась, теперь ваша очередь - «[next.title]» на доске контрактов, на этап [stage_minutes()] мин.", channel)

/// Этап снят без выполнения: по сроку этапа, по сроку взятого контракта или иначе. Эстафета обрывается, отдел этапа слышит об этом по своему каналу.
/datum/econ_relay/proc/stage_lost(datum/econ_contract/contract)
	if(contract != current)
		return
	current = null
	var/reason
	if(contract.is_expired())
		reason = contract.taker ? "взявший не успел к сроку" : "вышел срок контракта"
	else if(!contract.taker && world.time >= stage_due_at())
		reason = "за [stage_minutes()] мин. этап никто не выполнил"
	else
		reason = "контракт сняли с доски"
	log_econ("Эстафета \"[title]\" оборвалась на этапе [stage] из [length(stages)] ([stage_label(stage)]): [reason], выплачено [paid] кр.")
	var/channel = GLOB.econ_department_radio[contract.department_id]
	if(channel)
		paperwork_radio("Эстафета «[title]» оборвалась на этапе «[contract.title]»: [reason].[paid ? " Пройденные этапы уже оплачены." : ""]", channel)
	qdel(src)
