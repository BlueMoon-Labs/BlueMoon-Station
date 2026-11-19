/// Вид аварии -> контракт, что в station_damage() считается поломкой и что - всем, наименьшее число новых поломок.
GLOBAL_LIST_INIT(econ_incident_kinds, list(
	ECON_INCIDENT_POWER = list(/datum/econ_contract/incident/power, "dark_apcs", "apcs", ECON_INCIDENT_POWER_MIN),
	ECON_INCIDENT_AIR = list(/datum/econ_contract/incident/air, "bad_alarms", "alarms", ECON_INCIDENT_AIR_MIN),
))

/// Срочный контракт аварии: после пробоя, пожара, метеоров или обесточки инженерия возвращает станцию в норму. Брать его не нужно: закрывается сам, когда поломок осталось мало, награду поровну делят инженеры на смене и бюджет.
/datum/econ_contract/incident
	takeable = FALSE
	urgent = TRUE
	var/incident_kind
	/// Сколько поломок станция считала обычным до аварии
	var/baseline = 0
	/// Больше всего поломок за аварию
	var/peak = 0
	var/current = 0
	var/check_timer

/datum/econ_contract/incident/New(department_id, baseline, count)
	..()
	src.baseline = baseline
	peak = count
	current = count
	update_reward()
	update_desc()
	set_deadline(world.time + ECON_INCIDENT_TIME)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_INCIDENT_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/econ_contract/incident/Destroy()
	deltimer(check_timer)
	check_timer = null
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	engineering?.incident_over(src)
	return ..()

/datum/econ_contract/incident/kind()
	return "incident"

/datum/econ_contract/incident/occupies_slot()
	return FALSE

/datum/econ_contract/incident/repeat_key()
	return null

/datum/econ_contract/incident/rotation_due_at()
	return null

/datum/econ_contract/incident/board_reset_removes(datum/bank_account/head_account)
	return FALSE

/datum/econ_contract/incident/has_progress()
	return fixed() > 0

/// Сколько поломок можно оставить: малая доля новых, которую не стоит гоняться чинить.
/datum/econ_contract/incident/proc/limit()
	return baseline + round((peak - baseline) * ECON_INCIDENT_LEFT_SHARE)

/datum/econ_contract/incident/proc/needed()
	return max(peak - limit(), 1)

/datum/econ_contract/incident/proc/fixed()
	return clamp(peak - current, 0, needed())

/datum/econ_contract/incident/proc/update_reward()
	reward = max(round(min(needed(), ECON_INCIDENT_UNITS_MAX) * SSeconomy.settings.contract_incident_unit_reward, ECON_CONTRACT_REWARD_STEP), ECON_CONTRACT_REWARD_STEP)

/datum/econ_contract/incident/proc/update_desc()
	return

/// Число поломок этого вида в отчёте station_damage().
/datum/econ_contract/incident/proc/measure(list/damage)
	var/list/spec = GLOB.econ_incident_kinds[incident_kind]
	return damage[spec[2]]

/// Раз в ECON_INCIDENT_CHECK_INTERVAL: станция снова в порядке - контракт выполнен; стало хуже - растут объём и награда.
/datum/econ_contract/incident/proc/check()
	check_timer = null
	if(completed || QDELETED(src) || SSeconomy.round_over())
		return
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	if(!engineering)
		return
	current = measure(engineering.station_damage())
	if(current > peak)
		peak = current
		update_reward()
	update_desc()
	if(current <= limit())
		complete()
		return
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_INCIDENT_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/econ_contract/incident/complete(mob/performer)
	if(completed)
		return
	var/total = final_payout()
	..()
	paperwork_radio("Авария «[title]» устранена: NT заплатил [total] кр., доля инженеров на смене - на их счетах.", RADIO_CHANNEL_ENGINEERING)

/datum/econ_contract/incident/progress_text()
	return "[fixed()] / [needed()]"

/datum/econ_contract/incident/power
	title = "Авария питания"
	incident_kind = ECON_INCIDENT_POWER

/datum/econ_contract/incident/power/update_desc()
	desc = "Щитков без питания: [current], до аварии было [baseline]. Верните свет - пусть останется не больше [limit()]."

/datum/econ_contract/incident/air
	title = "Пробоины и пожары"
	incident_kind = ECON_INCIDENT_AIR

/datum/econ_contract/incident/air/update_desc()
	desc = "Отсеков с тревогой по воздуху: [current], до аварии было [baseline]. Залатайте пробоины, потушите пожары и верните воздух - пусть останется не больше [limit()]."

/datum/economy_department/engineering
	/// Вид аварии -> сколько поломок станция считает обычным: после аварии - сколько их осталось
	var/list/incident_baseline = list()
	/// Вид аварии -> когда можно выставить новую
	var/list/incident_ready_at = list()

/datum/economy_department/engineering/proc/active_incident(kind)
	for(var/datum/econ_contract/incident/incident in contracts)
		if(incident.incident_kind == kind)
			return incident

/// Раз в тик экономики: поломок стало заметно больше обычного - инженерии выставляется срочный контракт.
/datum/economy_department/engineering/proc/check_incidents(list/damage)
	if(!SSeconomy.contracts_started)
		return
	for(var/kind in GLOB.econ_incident_kinds)
		var/list/spec = GLOB.econ_incident_kinds[kind]
		var/count = damage[spec[2]]
		if(active_incident(kind))
			continue
		if(isnull(incident_baseline[kind]) || count < incident_baseline[kind])
			incident_baseline[kind] = count
			continue
		if(world.time < incident_ready_at[kind])
			continue
		if(count - incident_baseline[kind] < max(spec[4], round(damage[spec[3]] * ECON_INCIDENT_MIN_SHARE)))
			continue
		post_incident(kind, count)

/datum/economy_department/engineering/proc/post_incident(kind, count)
	var/list/spec = GLOB.econ_incident_kinds[kind]
	var/contract_type = spec[1]
	var/datum/econ_contract/incident/incident = new contract_type(id, incident_baseline[kind], count)
	contracts += incident
	log_econ("Авария \"[incident.title]\": [count] при обычных [incident.baseline], инженерии выставлен срочный контракт #[incident.uid] на [incident.payout()] кр.")
	paperwork_radio("Доска контрактов: срочный заказ инженерии «[incident.title]». [incident.desc] Награда [incident.payout()] кр., брать контракт не нужно.", RADIO_CHANNEL_ENGINEERING)
	return incident

/// Авария закрыта, снята сроком или удалена: что осталось - новая норма, следующая того же вида - не раньше ECON_INCIDENT_COOLDOWN.
/datum/economy_department/engineering/proc/incident_over(datum/econ_contract/incident/incident)
	incident_baseline[incident.incident_kind] = incident.current
	incident_ready_at[incident.incident_kind] = world.time + ECON_INCIDENT_COOLDOWN
	if(!incident.completed)
		log_econ("Авария \"[incident.title]\" не устранена к сроку: осталось [incident.current] при обычных [incident.baseline]")
