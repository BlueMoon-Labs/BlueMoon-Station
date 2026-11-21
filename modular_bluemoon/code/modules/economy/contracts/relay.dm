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

/// Эстафета, которая начинается с отдела department_id, ещё не идёт и которую есть кому пройти; её первый этап уже на доске. null, если такой нет. Эстафета, чей первый этап - из avoid (снятых сбросом доски), не начинается.
/datum/controller/subsystem/economy/proc/start_relay(department_id, list/avoid)
	var/list/candidates = list()
	for(var/list/template as anything in GLOB.econ_relay_templates)
		var/list/stages = template["stages"]
		var/list/first = stages[1]
		if(first["department"] == department_id && !relay_running(template["title"]) && relay_staffed(template) && !econ_relay_stage_avoided(first, avoid))
			candidates += list(template)
	if(!length(candidates))
		return null
	return begin_relay(pick(candidates), needs_crew = TRUE)

/datum/controller/subsystem/economy/proc/relay_running(title)
	for(var/datum/econ_relay/relay as anything in relays)
		if(relay.title == title)
			return relay

/// Этап spec - тот же контракт деятельности или баунти того же базового типа, что одно из avoid.
/proc/econ_relay_stage_avoided(list/spec, list/avoid)
	for(var/avoided in avoid)
		if(avoided == spec["contract"] || (spec["bounty"] && ispath(avoided, spec["bounty"])))
			return TRUE
	return FALSE

/// У отдела каждого этапа есть сотрудник в игре.
/datum/controller/subsystem/economy/proc/relay_staffed(list/template)
	for(var/list/spec as anything in template["stages"])
		var/datum/economy_department/department = get_department(spec["department"])
		if(!length(department?.staff_in_game()))
			return FALSE
	return TRUE

/// Счета сотрудников отдела, которые сейчас в игре.
/datum/economy_department/proc/staff_in_game()
	. = list()
	for(var/datum/bank_account/member as anything in staff_accounts())
		if(econ_account_in_game(member))
			. += member

/// Запускает эстафету по шаблону: возвращает её первый этап, уже выставленный на доску. needs_crew - первый этап выставляется, только если его может взять кто-то из отдела в игре.
/datum/controller/subsystem/economy/proc/begin_relay(list/template, needs_crew = FALSE)
	var/datum/econ_relay/relay = new(template)
	relay.needs_crew = needs_crew
	relays += relay
	var/datum/econ_contract/first = relay.advance()
	var/channel = first && GLOB.econ_department_radio[first.department_id]
	if(channel)
		paperwork_radio("Эстафета «[relay.title]» началась: первой идёт [relay.stage_label(1)] - «[first.title]» на доске контрактов, [relay.stage_terms()], дальше - [relay.next_labels()].", channel)
	return first

/// Эстафета отделов: этапы идут по одному, каждый платит своему отделу, за последний - премия от суммы этапов, всё вместе - не выше потолка серий.
/datum/econ_relay
	var/title
	var/list/stages
	var/stage = 0
	/// Сумма наград выполненных этапов
	var/paid = 0
	/// Премия за последний этап, вошедшая в paid
	var/premium = 0
	var/datum/econ_contract/current
	/// Когда нынешний этап вышел на доску
	var/stage_posted_at = 0
	/// Отдел уже слышал, что невзятый этап скоро снимут
	var/warned = FALSE
	/// Первый этап выставляется, только если его может взять кто-то из отдела в игре
	var/needs_crew = FALSE

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

/// Сколько минут осталось нынешнему этапу: у взятого - его срок, у невзятого - срок этапа или свой срок срочного, что раньше.
/datum/econ_relay/proc/stage_minutes_left()
	var/due = current?.deadline
	if(!current?.taker)
		due = due ? min(due, stage_due_at()) : stage_due_at()
	return max(CEILING((due - world.time) / (1 MINUTES), 1), 1)

/// "на этап 60 мин." для радио: взятому этапу - сколько осталось взявшему.
/datum/econ_relay/proc/stage_terms()
	if(current?.taker)
		return "этап уже взят, у взявшего [stage_minutes_left()] мин."
	return "на этап [stage_minutes_left()] мин."

/// Выставляет следующий этап на доску его отдела. Возвращает контракт этапа; если этапы кончились или этап не собрать - эстафета удаляется и возвращается null.
/datum/econ_relay/proc/advance()
	stage++
	warned = FALSE
	if(stage > length(stages))
		finish()
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
	if(contract && stage == 1 && needs_crew && !crew_can_take(contract, department))
		log_econ("Эстафета \"[title]\" не началась: в отделе [department_id] некому взять \"[contract.title]\"")
		qdel(contract)
		qdel(src)
		return null
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

/// Есть ли в отделе сотрудник в игре, который ещё не выполнил этот заказ до лимита повторов.
/datum/econ_relay/proc/crew_can_take(datum/econ_contract/contract, datum/economy_department/department)
	for(var/datum/bank_account/member as anything in department.staff_in_game())
		if(!contract.repeats_exhausted(member))
			return TRUE
	return FALSE

/// Контракт становится нынешним этапом. Свой срок деятельности короче срока этапа: невзятый этап снимает ротация, а взятому срок даст take().
/datum/econ_relay/proc/claim_stage(datum/econ_contract/contract)
	contract.relay = src
	current = contract
	if(!contract.taker && !contract.urgent)
		contract.deadline = 0

/// Взявший ушёл с этапа: срочный хранит свой срок, остальной ждёт отдел до срока этапа, но не меньше ротации, чтобы отдел успел услышать предупреждение.
/datum/econ_relay/proc/stage_released(datum/econ_contract/contract)
	if(contract != current)
		return
	if(!contract.urgent)
		contract.deadline = 0
	stage_posted_at = max(stage_posted_at, world.time - stage_lifetime() + SSeconomy.contract_rotation_age())
	warned = FALSE

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
	if(final_stage())
		premium = max(total - contract.payout(), 0)
	contract.relay = null
	current = null
	var/done_label = stage_label(stage)
	log_econ("Эстафета \"[title]\": этап [stage] из [length(stages)] ([done_label]) выполнен, [total] кр., всего [paid] кр.")
	var/datum/econ_contract/next = advance()
	if(!next)
		return
	var/channel = GLOB.econ_department_radio[next.department_id]
	if(channel)
		paperwork_radio("Эстафета «[title]»: [done_label] справилась, теперь ваша очередь - «[next.title]» на доске контрактов, [stage_terms()]", channel)

/// Все этапы пройдены: итог слышат каналы всех отделов эстафеты, каждый по разу.
/datum/econ_relay/proc/finish()
	log_econ("Эстафета \"[title]\" пройдена: выплачено [paid] кр., из них премия [premium] кр.")
	var/list/channels = list()
	for(var/list/spec as anything in stages)
		var/channel = GLOB.econ_department_radio[spec["department"]]
		if(channel)
			channels |= channel
	var/premium_text = premium ? ", из них премия [premium] кр." : ""
	for(var/channel in channels)
		paperwork_radio("Эстафета «[title]» пройдена, выплачено [paid] кр.[premium_text]", channel)
	qdel(src)

/// За ротацию доски до снятия невзятого этапа его отдел один раз слышит, что эстафета вот-вот оборвётся.
/datum/econ_relay/proc/warn_if_late()
	if(warned || !current || current.taker)
		return
	var/age = SSeconomy.contract_rotation_age()
	if(stage_lifetime() <= age || world.time < stage_due_at() - age)
		return
	warned = TRUE
	var/channel = GLOB.econ_department_radio[current.department_id]
	if(channel)
		paperwork_radio("Эстафета «[title]»: этап «[current.title]» всё ещё ждёт, через [stage_minutes_left()] мин. эстафета оборвётся.", channel)

/// Почему этап сняли: cause - причина из withdraw(), без неё контракт сняли в обход доски.
/datum/econ_relay/proc/loss_reason(cause)
	switch(cause)
		if("late")
			return "взявший не успел к сроку"
		if("expired")
			return "вышел срок контракта"
		if("rotation")
			return "за [stage_minutes()] мин. этап никто не выполнил"
		if("reset")
			return "доску отдела сбросили"
	return "контракт сняли с доски"

/// Этап снят без выполнения по причине cause. Эстафета обрывается, отдел этапа слышит об этом по своему каналу.
/datum/econ_relay/proc/stage_lost(datum/econ_contract/contract, cause)
	if(contract != current)
		return
	current = null
	var/reason = loss_reason(cause)
	log_econ("Эстафета \"[title]\" оборвалась на этапе [stage] из [length(stages)] ([stage_label(stage)]): [reason], выплачено [paid] кр.")
	var/channel = GLOB.econ_department_radio[contract.department_id]
	if(channel)
		paperwork_radio("Эстафета «[title]» оборвалась на этапе «[contract.title]»: [reason].[paid ? " Пройденные этапы уже оплачены." : ""]", channel)
	qdel(src)
