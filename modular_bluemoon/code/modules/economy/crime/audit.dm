/// Дело финансового аудита: деньги ушли со счёта account_number на counterparty_number.
/datum/econ_audit_flag
	var/uid
	var/account_number
	var/kind
	var/text
	var/amount = 0
	var/counterparty_number
	/// Станционное время открытия дела
	var/time
	/// world.time последней операции в деле
	var/last_seen = 0
	var/closed = FALSE
	/// Сколько вернули пострадавшему, без сбора СБ
	var/refunded = 0
	/// Отток бюджета на счета без владельца: все такие получатели одного источника - одно дело, получатели в recipients
	var/pooled = FALSE
	/// Объединённое дело: номер получателя -> сколько ушло ему от источника
	var/list/recipients
	/// Номер получателя -> сколько с него уже списано возвратом, со сбором СБ
	var/list/recipients_refunded
	var/closed_by
	/// Причина закрытия без возврата
	var/close_reason
	/// ckey и REF разума тех, кто двигал деньги по делу: они его не закрывают
	var/list/actors

/// Ключи для flag.actors: ckey и REF разума.
/proc/econ_audit_identities(mob/actor)
	. = list()
	if(!actor)
		return
	var/actor_ckey = econ_ckey_of(actor)
	if(actor_ckey)
		. += actor_ckey
	if(actor.mind)
		. += REF(actor.mind)

/datum/econ_audit_flag/proc/acted_by(mob/user)
	return length(actors) && length(actors & econ_audit_identities(user))

/// Пользователь владеет счётом в деле или сам двигал по нему деньги.
/datum/econ_audit_flag/proc/concerns(mob/user)
	if(acted_by(user))
		return TRUE
	for(var/number in party_numbers())
		var/datum/bank_account/party = SSeconomy.find_account(number)
		if(party?.owned_by(user))
			return TRUE
	return FALSE

/datum/econ_audit_flag/proc/party_numbers()
	. = list(account_number)
	if(counterparty_number)
		. += counterparty_number
	for(var/number in recipients)
		. += text2num(number)

/datum/econ_audit_flag/proc/involves(number)
	return !isnull(number) && (number in party_numbers())

/// Сколько ещё можно вернуть со счёта number; 0 - он не получатель или с него всё возвращено.
/datum/econ_audit_flag/proc/refundable_from(number)
	if(!pooled)
		return number == counterparty_number ? amount : 0
	if(!recipients || !("[number]" in recipients))
		return 0
	var/taken = recipients_refunded ? recipients_refunded["[number]"] : 0
	return max(recipients["[number]"] - taken, 0)

/datum/econ_audit_flag/proc/refundable_total()
	. = 0
	for(var/number in recipients)
		. += refundable_from(text2num(number))

/// Остаток открытого объединённого дела после возврата со счёта number.
/datum/econ_audit_flag/proc/remaining_text(number)
	var/own = refundable_from(number)
	return "осталось вернуть: с этого счёта [own] кр., с других получателей [refundable_total() - own] кр."

/datum/bank_account
	/// Номер получателя -> корзины исходящих list(начало, сумма, число) для следа денег
	var/list/audit_outflows
	/// То же для порогов дробления и оттока бюджета; пара очищается, когда по ней открыто или закрыто дело
	var/list/audit_watch
	/// Получатель без владельца -> корзины выплат, пока они копятся в объединённое дело оттока
	var/list/audit_pool
	/// Ключ audit_watch -> econ_audit_identities() тех, кто платил, пока пара копится до порога
	var/list/audit_watch_actors
	var/audit_next_sweep = 0
	var/freeze_reason
	/// Имя и должность того, кто заморозил счёт
	var/frozen_by
	/// Состояние до заморозки: разморозка возвращает спящий счёт спящим
	var/state_before_freeze = ACCOUNT_ACTIVE
	/// Счёт официальной стороны вне станции (инспекция): платежи на него аудит не разбирает
	var/audit_exempt_target = FALSE

/datum/controller/subsystem/economy
	var/list/audit_flags = list()
	var/audit_flag_uid = 0
	var/audit_flags_overflow_logged = FALSE

/// Ключ пары в audit_watch: счета без владельца при оттоке бюджета копятся вместе, чтобы вывод на много новых счетов не дробился
/proc/econ_audit_watch_key(kind, datum/bank_account/counterparty)
	if(kind == AUDIT_FLAG_BUDGET_SIPHON && counterparty && !counterparty.owner_ref)
		return AUDIT_WATCH_UNOWNED
	return "[counterparty?.account_id]"

GLOBAL_LIST_INIT(econ_reasons_unaudited, list(ECON_WAGE, ECON_TAX, ECON_TAX_NT, ECON_ADMIN, ECON_ACCOUNT_CLOSED, ECON_BUDGET_RETURN))

/proc/econ_audit_bucket_add(list/buckets, amount)
	var/list/last = length(buckets) ? buckets[length(buckets)] : null
	if(last && world.time - last[AUDIT_BUCKET_START] < AUDIT_BUCKET)
		last[AUDIT_BUCKET_AMOUNT] += amount
		last[AUDIT_BUCKET_COUNT]++
		return
	buckets += list(list(world.time, amount, 1))

/// list(число, сумма) в корзинах, задевающих окно с since.
/proc/econ_audit_bucket_stats(list/buckets, since)
	var/count = 0
	var/total = 0
	for(var/list/bucket as anything in buckets)
		if(bucket[AUDIT_BUCKET_START] + AUDIT_BUCKET > since)
			count += bucket[AUDIT_BUCKET_COUNT]
			total += bucket[AUDIT_BUCKET_AMOUNT]
	return list(count, total)

/proc/econ_audit_prune_pairs(list/pairs, since)
	for(var/number in pairs)
		var/list/buckets = pairs[number]
		while(length(buckets))
			var/list/first = buckets[1]
			if(first[AUDIT_BUCKET_START] + AUDIT_BUCKET > since)
				break
			buckets.Cut(1, 2)
		if(!length(buckets))
			pairs -= number

/datum/controller/subsystem/economy/proc/audit_move(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor)
	if(!source || !target || target.audit_exempt_target || (reason in GLOB.econ_reasons_unaudited))
		return
	var/personal_target = target.add_to_accounts
	var/budget_target = istype(target, /datum/bank_account/department)
	if(!personal_target && !budget_target && !istype(target, /datum/bank_account/system))
		return
	note_outflow(source, target, amount)
	if(budget_target)
		return
	note_anon_cashout(source, amount, reason, actor)
	if(!personal_target)
		return
	if(reason == ECON_SKIM && source.add_to_accounts)
		add_audit_flag(source, AUDIT_FLAG_UNKNOWN_DEVICE, "Списание с неопознанного устройства", amount, target, actor)
		return
	if(reason == ECON_TRANSFER)
		watch_pair(source, target, amount, AUDIT_FLAG_STRUCTURING, "Серия переводов одному получателю", actor)
		return
	var/datum/bank_account/department/budget = source
	if(!istype(budget) || !budget.department)
		return
	if(reason == ECON_BONUS && econ_account_of(actor) == target)
		add_audit_flag(source, AUDIT_FLAG_SELF_BONUS, "Глава выписал премию самому себе", amount, target, actor)
		return
	watch_pair(source, target, amount, AUDIT_FLAG_BUDGET_SIPHON, target.owner_ref ? "Крупные выплаты из бюджета одному человеку" : "Выплаты из бюджета на счета без владельца", actor)

/// Доход криптомайнера на личный счёт: деньги, которые майнер платит снабжению, получил человек. Дело на бюджете снабжения, возврат - туда же.
/datum/controller/subsystem/economy/proc/note_crypto_income(datum/bank_account/account, amount, atom/miner)
	var/datum/bank_account/cargo = get_dep_account(ACCOUNT_CAR)
	if(!cargo || !(account in bank_accounts))
		return
	var/place = get_area_name(miner, TRUE) || "место неизвестно"
	var/datum/econ_audit_flag/flag = add_audit_flag(cargo, AUDIT_FLAG_CRYPTOMINER, "Доход криптомайнера на личный счёт: [place]", amount, account)
	if(!findtext(flag.text, place))
		flag.text += ", [place]"

/datum/controller/subsystem/economy/proc/note_outflow(datum/bank_account/source, datum/bank_account/target, amount)
	if(!source.audit_outflows)
		source.audit_outflows = list()
	var/key = "[target.account_id]"
	var/list/buckets = source.audit_outflows[key]
	if(!buckets)
		buckets = list()
		source.audit_outflows[key] = buckets
	econ_audit_bucket_add(buckets, amount)
	if(world.time < source.audit_next_sweep)
		return
	source.audit_next_sweep = world.time + AUDIT_BUCKET
	econ_audit_prune_pairs(source.audit_outflows, world.time - settings.audit_trace_minutes MINUTES)
	if(source.audit_watch)
		econ_audit_prune_pairs(source.audit_watch, world.time - max(settings.audit_structuring_minutes, settings.audit_siphon_minutes) MINUTES)
	for(var/watch_key in source.audit_watch_actors)
		if(!source.audit_watch || !source.audit_watch[watch_key])
			source.audit_watch_actors -= watch_key
	if(source.audit_pool)
		econ_audit_prune_pairs(source.audit_pool, world.time - settings.audit_siphon_minutes MINUTES)

/// Дробление (число переводов) и отток бюджета (сумма) по паре: открытое дело пополняется, иначе копится до порога.
/datum/controller/subsystem/economy/proc/watch_pair(datum/bank_account/source, datum/bank_account/target, amount, kind, text, mob/actor)
	if(open_audit_flag(kind, source, target))
		add_audit_flag(source, kind, text, amount, target, actor)
		return
	if(!source.audit_watch)
		source.audit_watch = list()
	var/key = econ_audit_watch_key(kind, target)
	var/list/buckets = source.audit_watch[key]
	if(!buckets)
		buckets = list()
		source.audit_watch[key] = buckets
	econ_audit_bucket_add(buckets, amount)
	var/list/identities = econ_audit_identities(actor)
	if(length(identities))
		LAZYINITLIST(source.audit_watch_actors)
		var/list/known = source.audit_watch_actors[key]
		source.audit_watch_actors[key] = known ? (known | identities) : identities
	var/pooled = key == AUDIT_WATCH_UNOWNED
	if(pooled)
		LAZYINITLIST(source.audit_pool)
		var/list/recipient_buckets = source.audit_pool["[target.account_id]"]
		if(!recipient_buckets)
			recipient_buckets = list()
			source.audit_pool["[target.account_id]"] = recipient_buckets
		econ_audit_bucket_add(recipient_buckets, amount)
	var/structuring = kind == AUDIT_FLAG_STRUCTURING
	var/since = world.time - (structuring ? settings.audit_structuring_minutes : settings.audit_siphon_minutes) MINUTES
	var/list/stats = econ_audit_bucket_stats(buckets, since)
	if(!(structuring ? stats[1] >= settings.audit_structuring_count : stats[2] >= settings.audit_bonus_threshold))
		return
	var/datum/econ_audit_flag/flag = add_audit_flag(source, kind, text, stats[2], target, actor)
	if(!pooled)
		return
	flag.recipients = list()
	flag.amount = 0
	for(var/number in source.audit_pool)
		var/list/recipient_stats = econ_audit_bucket_stats(source.audit_pool[number], since)
		if(recipient_stats[2])
			flag.recipients[number] = recipient_stats[2]
			flag.amount += recipient_stats[2]
	source.audit_pool = null

/datum/controller/subsystem/economy/proc/open_audit_flag(kind, datum/bank_account/account, datum/bank_account/counterparty)
	var/since = world.time - settings.audit_trace_minutes MINUTES
	var/pooled = econ_audit_watch_key(kind, counterparty) == AUDIT_WATCH_UNOWNED
	for(var/datum/econ_audit_flag/flag as anything in audit_flags)
		if(flag.closed || flag.kind != kind || flag.account_number != account.account_id || flag.last_seen < since || flag.pooled != pooled)
			continue
		if(pooled || flag.counterparty_number == counterparty?.account_id)
			return flag

/// account - откуда ушли деньги, counterparty - куда. Свежее открытое дело того же вида по той же паре пополняется.
/datum/controller/subsystem/economy/proc/add_audit_flag(datum/bank_account/account, kind, text, amount, datum/bank_account/counterparty, mob/actor)
	var/datum/econ_audit_flag/flag = open_audit_flag(kind, account, counterparty)
	if(!flag)
		flag = new
		flag.uid = ++audit_flag_uid
		flag.account_number = account.account_id
		flag.kind = kind
		flag.text = text
		flag.time = STATION_TIME_TIMESTAMP("hh:mm", world.time)
		flag.pooled = econ_audit_watch_key(kind, counterparty) == AUDIT_WATCH_UNOWNED
		flag.counterparty_number = flag.pooled ? null : counterparty?.account_id
		audit_flags += flag
		trim_audit_flags()
	if(flag.pooled)
		LAZYINITLIST(flag.recipients)
		flag.recipients["[counterparty.account_id]"] += amount
	var/list/identities = econ_audit_identities(actor)
	if(counterparty && account.audit_watch)
		account.audit_watch -= econ_audit_watch_key(kind, counterparty)
	if(counterparty && account.audit_watch_actors)
		var/key = econ_audit_watch_key(kind, counterparty)
		identities |= account.audit_watch_actors[key]
		account.audit_watch_actors -= key
	if(length(identities))
		LAZYINITLIST(flag.actors)
		flag.actors |= identities
	flag.amount += amount
	flag.last_seen = world.time
	log_econ("Аудит, дело [flag.uid]: [text], [amount] кр. со счёта [account.account_holder] №[account.account_id][counterparty ? " на [counterparty.account_holder] №[counterparty.account_id]" : ""]")
	return flag

/datum/controller/subsystem/economy/proc/close_audit_flag(datum/econ_audit_flag/flag)
	flag.closed = TRUE
	var/datum/bank_account/source = find_account(flag.account_number)
	var/key = flag.pooled ? AUDIT_WATCH_UNOWNED : "[flag.counterparty_number]"
	if(source?.audit_watch)
		source.audit_watch -= key
	if(source?.audit_watch_actors)
		source.audit_watch_actors -= key
	if(source && flag.pooled)
		source.audit_pool = null

/// Сверх лимита вытесняются только закрытые дела, старые первыми.
/datum/controller/subsystem/economy/proc/trim_audit_flags()
	var/excess = length(audit_flags) - AUDIT_FLAGS_MAX
	if(excess <= 0)
		audit_flags_overflow_logged = FALSE
		return
	for(var/datum/econ_audit_flag/flag as anything in audit_flags.Copy())
		if(excess <= 0)
			break
		if(flag.closed)
			audit_flags -= flag
			qdel(flag)
			excess--
	if(excess > 0 && !audit_flags_overflow_logged)
		audit_flags_overflow_logged = TRUE
		log_econ("Аудит: открытых дел больше [AUDIT_FLAGS_MAX], они не вытесняются.")

/datum/controller/subsystem/economy/proc/find_audit_flag(uid)
	for(var/datum/econ_audit_flag/flag as anything in audit_flags)
		if(flag.uid == uid)
			return flag

/datum/controller/subsystem/economy/proc/flags_for(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/econ_audit_flag/flag as anything in audit_flags)
		if(flag.involves(account.account_id))
			. += flag

/// Куда ушли деньги со счёта за audit_trace_minutes: list(list("holder", "number", "amount", "children")). Раскрываются только личные счета.
/datum/controller/subsystem/economy/proc/trace_money(datum/bank_account/account, depth, list/visited)
	. = list()
	depth = min(depth, settings.audit_trace_depth)
	if(!account || depth < 1)
		return
	if(!visited)
		visited = list()
	visited["[account.account_id]"] = TRUE
	var/since = world.time - settings.audit_trace_minutes MINUTES
	var/list/sums = list()
	for(var/number in account.audit_outflows)
		var/list/stats = econ_audit_bucket_stats(account.audit_outflows[number], since)
		if(stats[2])
			sums[number] = stats[2]
	for(var/number in sums)
		var/datum/bank_account/next = find_account(number)
		var/list/children = list()
		if(next?.add_to_accounts && !visited[number])
			children = trace_money(next, depth - 1, visited)
		. += list(list(
			"holder" = next ? next.account_holder : "Счёт закрыт",
			"number" = next ? next.account_id : text2num(number),
			"amount" = sums[number],
			"children" = children,
		))

/// Глава СБ и капитан по доступу ID; детектив и ГП - по должности и с доступом своей должности на ID.
/datum/controller/subsystem/economy/proc/can_audit(mob/living/user)
	if(!isliving(user))
		return FALSE
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card)
		return FALSE
	var/list/card_access = card.GetAccess()
	if((ACCESS_HOS in card_access) || (ACCESS_CAPTAIN in card_access))
		return TRUE
	var/datum/job/detective/detective_job = /datum/job/detective
	var/datum/job/hop/hop_job = /datum/job/hop
	var/role = user.mind?.assigned_role
	if(role == initial(detective_job.title))
		return ACCESS_FORENSICS_LOCKERS in card_access
	if(role == initial(hop_job.title))
		return ACCESS_HOP in card_access
	return FALSE

/// Кто проходит can_audit(), для справок игрокам; правится вместе с ней.
/datum/controller/subsystem/economy/proc/audit_rights_text()
	return "глава СБ и капитан (по доступу ID), детектив и глава персонала (по должности и её доступу на ID)"

/datum/controller/subsystem/economy/proc/auditor_name(mob/living/user)
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	return "[card?.registered_name || user.real_name], [card?.assignment || user.mind?.assigned_role || "без должности"]"

/// Почему user не может заморозить (freeze) или разморозить счёт; null - может.
/datum/controller/subsystem/economy/proc/freeze_problem(datum/bank_account/account, mob/living/user, freeze)
	if(!can_audit(user))
		return "Нужны права финансового аудита: детектив, глава СБ, ГП или капитан."
	if(!account || QDELETED(account) || !account.add_to_accounts)
		return "Замораживаются только личные счета."
	if(account.owned_by(user))
		return "Свой счёт заморозить или разморозить нельзя."
	if(freeze && account.state == ACCOUNT_FROZEN)
		return "Счёт уже заморожен."
	if(!freeze && account.state != ACCOUNT_FROZEN)
		return "Счёт не заморожен."
	if(!freeze && account.frozen_by == ECON_ADMIN_FROZEN_BY)
		return ECON_ADMIN_FREEZE_LOCKED
	return null

/datum/controller/subsystem/economy/proc/freeze_account(datum/bank_account/account, mob/living/user, reason)
	reason = econ_ui_reason(reason, AUDIT_REASON_MAX)
	if(!length(reason) || freeze_problem(account, user, TRUE))
		return FALSE
	apply_freeze(account, auditor_name(user), reason)
	log_econ("[key_name(user)] заморозил счёт [account.account_holder] №[account.account_id]: [reason]")
	return TRUE

/datum/controller/subsystem/economy/proc/unfreeze_account(datum/bank_account/account, mob/living/user)
	if(freeze_problem(account, user, FALSE))
		return FALSE
	apply_unfreeze(account, auditor_name(user))
	log_econ("[key_name(user)] разморозил счёт [account.account_holder] №[account.account_id]")
	return TRUE

/// Заморозка без проверок прав, общая для аудита и админ-панели; сообщение владельцу - только отсюда.
/datum/controller/subsystem/economy/proc/apply_freeze(datum/bank_account/account, frozen_by, reason)
	account.state_before_freeze = account.state
	account.state = ACCOUNT_FROZEN
	account.freeze_reason = reason
	account.frozen_by = frozen_by
	account.bank_card_talk("Счёт заморожен [freeze_source(frozen_by)]: [html_encode(reason)]. Переводы, покупки и снятие наличных закрыты, зарплата копится долгом отдела (до [settings.owed_wages_cap_paychecks] выплат) до разморозки.", TRUE, 'sound/economy/account_freeze.ogg', "счёт заморожен")

/// Кем заморожен счёт, для карты и кошелька владельца: "Счёт заморожен ...".
/datum/controller/subsystem/economy/proc/freeze_source(frozen_by)
	if(frozen_by == ECON_ADMIN_FROZEN_BY)
		return "Центральным командованием NT, разморозить может только ЦК"
	return frozen_by ? "финансовым аудитом ([frozen_by])" : "финансовым аудитом"

/datum/controller/subsystem/economy/proc/apply_unfreeze(datum/bank_account/account, unfrozen_by)
	account.state = account.state_before_freeze == ACCOUNT_DORMANT ? ACCOUNT_DORMANT : ACCOUNT_ACTIVE
	account.state_before_freeze = ACCOUNT_ACTIVE
	account.freeze_reason = null
	account.frozen_by = null
	account.bank_card_talk("Счёт разморожен ([unfrozen_by]).", TRUE, balloon = "счёт разморожен")

/// Почему нельзя вернуть деньги по делу; null - можно. Возврат идёт только с замороженного получателя тому, с чьего счёта ушли деньги.
/datum/controller/subsystem/economy/proc/refund_problem(datum/bank_account/from_account, datum/bank_account/to_account, amount, mob/living/user, flag_uid)
	if(!can_audit(user))
		return "Нужны права финансового аудита: детектив, глава СБ, ГП или капитан."
	var/datum/econ_audit_flag/flag = find_audit_flag(flag_uid)
	if(!flag)
		return "Дело не найдено."
	if(flag.closed)
		return "Дело уже закрыто, повторный возврат запрещён."
	if(!from_account || !to_account || QDELETED(from_account) || QDELETED(to_account) || !flag.involves(from_account.account_id) || from_account.account_id == flag.account_number || to_account.account_id != flag.account_number)
		return "Вернуть можно только со счёта получателя по делу на счёт, с которого ушли деньги."
	var/limit = flag.refundable_from(from_account.account_id)
	if(!limit)
		return "С этого получателя по делу уже всё возвращено."
	if(from_account.state != ACCOUNT_FROZEN)
		return "Сначала заморозьте счёт получателя."
	if(from_account.owned_by(user) || to_account.owned_by(user))
		return "Дело, где замешан ваш счёт, ведёт другой аудитор."
	if(flag.acted_by(user))
		return AUDIT_OWN_MOVES_REFUSAL
	if(!isnum(amount) || round(amount) < 1)
		return "Неверная сумма."
	if(round(amount) > limit)
		return flag.pooled ? "Больше, чем ушло на этот счёт по делу: не больше [limit] кр." : "Больше суммы по делу: не больше [limit] кр."
	if(!from_account.has_money(round(amount)))
		return "На счёте только [from_account.account_balance] кр."
	return null

/// Возврат: доля audit_case_fee_percent уходит отделу безопасности сбором с получателя, остальное пострадавшему. Деньги не создаются. Успех - list("returned", "fee").
/datum/controller/subsystem/economy/proc/refund(datum/bank_account/from_account, datum/bank_account/to_account, amount, mob/living/user, flag_uid)
	if(refund_problem(from_account, to_account, amount, user, flag_uid))
		return FALSE
	amount = round(amount)
	var/datum/econ_audit_flag/flag = find_audit_flag(flag_uid)
	var/datum/bank_account/sec = get_dep_account(ACCOUNT_SEC)
	var/fee = sec ? round(amount * settings.audit_case_fee_percent / 100) : 0
	var/returned = amount - fee
	if(returned && !move(from_account, to_account, returned, ECON_REFUND, user, "Возврат по делу аудита №[flag.uid]"))
		return FALSE
	if(fee && !move(from_account, sec, fee, ECON_REFUND, user, "Сбор СБ по делу аудита №[flag.uid]"))
		fee = 0
	SEND_SIGNAL(src, COMSIG_ECONOMY_AUDIT_REFUNDED, from_account, to_account, returned + fee)
	flag.refunded += returned
	if(flag.pooled)
		LAZYINITLIST(flag.recipients_refunded)
		flag.recipients_refunded["[from_account.account_id]"] += returned + fee
	if(!flag.pooled || !flag.refundable_total())
		close_audit_flag(flag)
		flag.closed_by = auditor_name(user)
	from_account.bank_card_talk("Списано по делу аудита №[flag.uid]: [returned + fee] кр., из них сбор отдела безопасности [fee] кр.", TRUE)
	to_account.bank_card_talk("Возврат по делу аудита №[flag.uid]: +[returned] кр.", TRUE)
	var/outcome = flag.closed ? "Дело №[flag.uid] закрыто." : "Дело №[flag.uid] открыто, [flag.remaining_text(from_account.account_id)]"
	to_chat(user, span_notice("Возвращено [returned] кр., сбор отдела безопасности [fee] кр. ([settings.audit_case_fee_percent]% с получателя). [outcome] NT за дела не доплачивает."))
	log_econ("[key_name(user)] вернул [returned] кр. по делу [flag.uid] со счёта [from_account.account_holder] №[from_account.account_id] на [to_account.account_holder] №[to_account.account_id], сбор СБ [fee] кр.")
	return list("returned" = returned, "fee" = fee)

/// Почему нельзя закрыть дело без возврата; null - можно.
/datum/controller/subsystem/economy/proc/close_case_problem(flag_uid, mob/living/user)
	if(!can_audit(user))
		return "Нужны права финансового аудита: детектив, глава СБ, ГП или капитан."
	var/datum/econ_audit_flag/flag = find_audit_flag(flag_uid)
	if(!flag)
		return "Дело не найдено."
	if(flag.closed)
		return "Дело уже закрыто."
	for(var/number in flag.party_numbers())
		var/datum/bank_account/party = find_account(number)
		if(party?.owned_by(user))
			return "Дело, где замешан ваш счёт, ведёт другой аудитор."
	if(flag.acted_by(user))
		return AUDIT_OWN_MOVES_REFUSAL
	return null

/// Закрыть дело без возврата денег, с причиной. Ничего не платит.
/datum/controller/subsystem/economy/proc/close_case(flag_uid, mob/living/user, reason)
	reason = econ_ui_reason(reason, AUDIT_REASON_MAX)
	if(!length(reason) || close_case_problem(flag_uid, user))
		return FALSE
	var/datum/econ_audit_flag/flag = find_audit_flag(flag_uid)
	close_audit_flag(flag)
	flag.close_reason = reason
	flag.closed_by = auditor_name(user)
	for(var/number in flag.party_numbers())
		var/datum/bank_account/party = find_account(number)
		party?.bank_card_talk("Дело финансового аудита №[flag.uid] по вашему счёту закрыто без возврата ([flag.closed_by]): [html_encode(reason)].", TRUE)
	to_chat(user, span_notice("Дело №[flag.uid] закрыто без возврата: [html_encode(reason)]. Денег это не двигает."))
	log_econ("[key_name(user)] закрыл дело [flag.uid] без возврата: [reason]")
	return TRUE
