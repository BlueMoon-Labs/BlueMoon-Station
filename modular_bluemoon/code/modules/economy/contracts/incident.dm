/// Вид аварии инженерии -> контракт, что в station_damage() считается поломкой, что - всем, наименьшее число новых поломок и где поломки по отсекам.
GLOBAL_LIST_INIT(econ_incident_kinds, list(
	ECON_INCIDENT_POWER = list(/datum/econ_contract/incident/power, "outage_apcs", "apcs", ECON_INCIDENT_POWER_MIN, "outage_areas"),
	ECON_INCIDENT_AIR = list(/datum/econ_contract/incident/air, "air_alarms", "alarms", ECON_INCIDENT_AIR_MIN, "air_areas"),
))

/// Контракт аварии: после пробоя, пожара, метеоров или обесточки отдел возвращает станцию в норму. Брать его не нужно: закрывается сам, награду делят отдел на смене и бюджет.
/datum/econ_contract/incident
	takeable = FALSE
	var/incident_kind
	/// Чей это заказ в радиосообщении: "инженерии"
	var/board_name = "инженерии"
	/// Кому из людей достаётся доля, для окна контрактов
	var/team_note = "Инженерам на смене поровну"
	var/done_note = "Брать не нужно: контракт закроется сам, когда станция будет в порядке."
	/// Сколько поломок станция считала обычным до аварии
	var/baseline = 0
	/// Больше всего поломок за аварию
	var/peak = 0
	var/current = 0
	/// Названия худших отсеков
	var/list/worst_areas
	var/check_timer

/datum/econ_contract/incident/New(department_id, baseline, count, list/worst)
	..()
	src.baseline = baseline
	peak = count
	current = count
	worst_areas = worst
	update_reward()
	update_desc()
	set_deadline(world.time + ECON_INCIDENT_TIME)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_INCIDENT_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/econ_contract/incident/Destroy()
	deltimer(check_timer)
	check_timer = null
	var/datum/economy_department/department = SSeconomy.get_department(department_id)
	department?.incident_over(src)
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

/datum/econ_contract/incident/proc/done()
	return current <= limit()

/datum/econ_contract/incident/proc/update_reward()
	reward = max(round(min(needed(), ECON_INCIDENT_UNITS_MAX) * SSeconomy.settings.contract_incident_unit_reward, ECON_CONTRACT_REWARD_STEP), ECON_CONTRACT_REWARD_STEP)

/datum/econ_contract/incident/proc/update_desc()
	return

/// " Хуже всего: мостик, бар." или пусто.
/datum/econ_contract/incident/proc/worst_text()
	return length(worst_areas) ? " Хуже всего: [jointext(worst_areas, ", ")]." : ""

/// Сколько поломок сейчас; заодно обновляет худшие отсеки.
/datum/econ_contract/incident/proc/measure()
	var/datum/economy_department/engineering/engineering = SSeconomy.get_department(ACCOUNT_ENG)
	if(!engineering)
		return current
	var/list/damage = engineering.station_damage()
	var/list/spec = GLOB.econ_incident_kinds[incident_kind]
	worst_areas = econ_worst_area_names(damage[spec[5]] || list())
	return damage[spec[2]]

/// Раз в ECON_INCIDENT_CHECK_INTERVAL: станция снова в порядке - контракт выполнен; стало хуже - растут объём и награда.
/datum/econ_contract/incident/proc/check()
	check_timer = null
	if(completed || QDELETED(src) || SSeconomy.round_over())
		return
	current = measure()
	if(current > peak)
		peak = current
		update_reward()
	update_desc()
	if(done())
		complete()
		return
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_INCIDENT_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/econ_contract/incident/complete(mob/performer)
	if(completed)
		return
	var/total = final_payout()
	..()
	var/channel = GLOB.econ_department_radio[department_id]
	if(channel)
		paperwork_radio("[title]: контракт закрыт, NT заплатил [total] кр., доля людей - на их счетах.", channel)

/datum/econ_contract/incident/progress_text()
	return "[fixed()] / [needed()]"

/datum/econ_contract/incident/ui_entry()
	. = ..()
	.["incident_team"] = team_note
	.["incident_note"] = done_note

/datum/econ_contract/incident/power
	title = "Авария питания"
	incident_kind = ECON_INCIDENT_POWER

/datum/econ_contract/incident/power/update_desc()
	desc = "Щитков без питания: [current], до аварии было [baseline]. Верните свет - пусть останется не больше [limit()].[worst_text()]"

/datum/econ_contract/incident/air
	title = "Пробоины и пожары"
	incident_kind = ECON_INCIDENT_AIR

/datum/econ_contract/incident/air/update_desc()
	desc = "Отсеков с тревогой по воздуху: [current], до аварии было [baseline]. Залатайте пробоины, потушите пожары и верните воздух - пусть останется не больше [limit()].[worst_text()]"

/// Массовые пострадавшие: много людей в крите сразу. Закрывается выписками пациентов, долю людей делят выписавшие медики.
/datum/econ_contract/incident/casualties
	title = "Массовые пострадавшие"
	incident_kind = ECON_INCIDENT_CASUALTIES
	board_name = "медицины"
	team_note = "Выписавшим медикам по вкладу"
	done_note = "Брать не нужно: контракт закроется, когда медики выпишут пострадавших."
	var/discharged = 0

/datum/econ_contract/incident/casualties/New(department_id, baseline, count, list/worst)
	..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_WORK_RECORDED, PROC_REF(on_work))

/datum/econ_contract/incident/casualties/Destroy()
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_WORK_RECORDED)
	return ..()

/datum/econ_contract/incident/casualties/fixed()
	return min(discharged, needed())

/datum/econ_contract/incident/casualties/done()
	return discharged >= needed()

/datum/econ_contract/incident/casualties/measure()
	return econ_station_casualties()

/datum/econ_contract/incident/casualties/update_desc()
	desc = "На станции в критическом состоянии: [current]. Вылечите и выпишите пострадавших - нужно [needed()]."

/datum/econ_contract/incident/casualties/proc/on_work(datum/source, work_department, recorded_type, amount, mob/performer, paid, atom/subject)
	SIGNAL_HANDLER
	if(completed || paid <= 0 || work_department != department_id)
		return
	if(!(recorded_type in list(WORK_MED_DISCHARGE_LIGHT, WORK_MED_DISCHARGE_HEAVY, WORK_MED_DISCHARGE_CRIT)))
		return
	note_contribution(performer)
	discharged++
	if(done())
		INVOKE_ASYNC(src, PROC_REF(complete), performer)

/// Люди экипажа на станции в критическом состоянии: живые и с игроком.
/proc/econ_station_casualties()
	. = 0
	for(var/mob/living/carbon/human/victim as anything in GLOB.human_list)
		if(victim.stat == DEAD || !victim.InCritical() || !GET_CLIENT(victim))
			continue
		var/turf/where = get_turf(victim)
		if(!where || !is_station_level(where.z))
			continue
		var/datum/bank_account/account = econ_account_of(victim)
		if(!account || account.offstation)
			continue
		.++

/datum/economy_department
	/// Вид аварии -> сколько поломок станция считает обычным: после аварии - сколько их осталось
	var/list/incident_baseline = list()
	/// Вид аварии -> когда можно выставить новую
	var/list/incident_ready_at = list()

/datum/economy_department/proc/active_incident(kind)
	for(var/datum/econ_contract/incident/incident in contracts)
		if(incident.incident_kind == kind)
			return incident

/// Выставляет отделу контракт аварии и объявляет его по каналу отдела.
/datum/economy_department/proc/post_incident(contract_type, baseline, count, list/worst)
	var/datum/econ_contract/incident/incident = new contract_type(id, baseline, count, worst)
	contracts += incident
	log_econ("Авария \"[incident.title]\": [count] при обычных [incident.baseline], отделу [id] выставлен контракт #[incident.uid] на [incident.payout()] кр.")
	var/channel = GLOB.econ_department_radio[id]
	if(channel)
		paperwork_radio("Доска контрактов: заказ [incident.board_name] «[incident.title]». [incident.desc] Награда [incident.payout()] кр., брать контракт не нужно.", channel)
	return incident

/// Авария закрыта, снята сроком или удалена: следующая того же вида - не раньше ECON_INCIDENT_COOLDOWN.
/datum/economy_department/proc/incident_over(datum/econ_contract/incident/incident)
	incident_ready_at[incident.incident_kind] = world.time + ECON_INCIDENT_COOLDOWN
	if(!incident.completed)
		log_econ("Авария \"[incident.title]\" не устранена к сроку: [incident.progress_text()], сейчас [incident.current] при обычных [incident.baseline]")

/// Что осталось после аварии - новая норма.
/datum/economy_department/engineering/incident_over(datum/econ_contract/incident/incident)
	..()
	incident_baseline[incident.incident_kind] = incident.current

/// Раз в тик экономики: поломок стало заметно больше обычного - инженерии выставляется контракт аварии.
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
		post_incident(spec[1], incident_baseline[kind], count, econ_worst_area_names(damage[spec[5]] || list()))

/datum/economy_department/medical/on_economy_tick()
	..()
	check_casualties()

/// Людей в крите на станции не меньше ECON_CASUALTIES_MIN - медицине выставляется контракт массовых пострадавших.
/datum/economy_department/medical/proc/check_casualties()
	var/kind = ECON_INCIDENT_CASUALTIES
	if(!SSeconomy.contracts_started || active_incident(kind) || world.time < incident_ready_at[kind])
		return
	var/count = econ_station_casualties()
	if(count >= ECON_CASUALTIES_MIN)
		return post_incident(/datum/econ_contract/incident/casualties, 0, count)
