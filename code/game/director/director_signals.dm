/// Мгновенный снимок состояния раунда для решений директора.
/datum/director_signals
	/// Живые не-AFK игроки с клиентом и станционной должностью
	var/effective_crew = 0
	/// Доля мёртвых/критических среди манифеста экипажа (0..1)
	var/dead_fraction = 0
	/// Ассоциация DIRECTOR_DEPT_* -> число активных
	var/list/staffing = list()
	/// Живые антагонисты (по antag datums)
	var/living_antags = 0
	/// Суммарная активная intensity (заполняет SSdirector)
	var/active_intensity = 0
	/// Видимая (событийная) часть intensity: только ledger-записи вне антаг-пулов (заполняет
	/// SSdirector). Порог тишины гарантированного бита смотрит сюда: стелс-нагрузка живых
	/// антагов не должна выключать гарантию в раундах, где активности "не видно".
	var/event_intensity = 0
	/// DIRECTOR_EVAC_*
	var/evac_state = DIRECTOR_EVAC_NONE

/// Является ли моб экипажем с точки зрения директора (без проверки клиента/AFK -
/// их проверяет счётчик; это позволяет юнит-тестировать классификацию).
/proc/is_effective_crew_mob(mob/M)
	if(!istype(M) || M.stat == DEAD)
		return FALSE
	if(isnewplayer(M) || isobserver(M))
		return FALSE
	if(!M.mind || !M.mind.assigned_role)
		return FALSE
	return !isnull(director_dept_of_job(M.mind.assigned_role, allow_other = TRUE))

/// Отдел станционной должности или null, если должность не станционная (гост-роль).
/// allow_other: считать станционными и должности вне шести отделов (ассистент и пр.).
/proc/director_dept_of_job(job_title, allow_other = FALSE)
	if(job_title in GLOB.security_positions)
		return DIRECTOR_DEPT_SECURITY
	if(job_title in GLOB.engineering_positions)
		return DIRECTOR_DEPT_ENGINEERING
	if(job_title in GLOB.medical_positions)
		return DIRECTOR_DEPT_MEDICAL
	if(job_title in GLOB.science_positions)
		return DIRECTOR_DEPT_SCIENCE
	if(job_title in GLOB.supply_positions)
		return DIRECTOR_DEPT_SUPPLY
	if(job_title in GLOB.command_positions)
		return DIRECTOR_DEPT_COMMAND
	if(allow_other && ((job_title in GLOB.civilian_positions) || (job_title in GLOB.nonhuman_positions)))
		return "other"
	return null

/// Есть ли живой персонаж с одной из перечисленных должностей. Обход SSticker.minds
/// (записей - по числу заходивших игроков), а не GLOB.alive_mob_list (тысячи, почти всё -
/// фауна без mind): гейты "есть ли живой врач" зовутся битом директора по несколько раз в минуту.
/proc/director_has_living_role(list/roles)
	for(var/datum/mind/checked_mind as anything in SSticker.minds)
		if(checked_mind.current && checked_mind.current.stat != DEAD && (checked_mind.assigned_role in roles))
			return TRUE
	return FALSE

/datum/director_signals/proc/update()
	effective_crew = 0
	living_antags = 0
	var/crew_total = 0
	var/crew_dead = 0
	staffing = list(
		DIRECTOR_DEPT_SECURITY = 0,
		DIRECTOR_DEPT_ENGINEERING = 0,
		DIRECTOR_DEPT_MEDICAL = 0,
		DIRECTOR_DEPT_SCIENCE = 0,
		DIRECTOR_DEPT_SUPPLY = 0,
		DIRECTOR_DEPT_COMMAND = 0,
	)
	for(var/mob/M as anything in GLOB.player_list)
		if(!M.client)
			continue
		if(M.mind && M.mind.assigned_role && !isnewplayer(M))
			var/dept = director_dept_of_job(M.mind.assigned_role, allow_other = TRUE)
			if(!isnull(dept))
				crew_total++
				if(M.stat == DEAD || isobserver(M))
					crew_dead++
		if(!is_effective_crew_mob(M))
			continue
		if(M.client.is_afk())
			continue
		effective_crew++
		var/dept = director_dept_of_job(M.mind.assigned_role)
		if(!isnull(dept))
			staffing[dept]++
	dead_fraction = crew_total ? (crew_dead / crew_total) : 0
	for(var/datum/antagonist/A in GLOB.antagonists)
		var/datum/mind/antag_mind = A.owner
		if(antag_mind?.current && antag_mind.current.stat != DEAD)
			living_antags++
	if(EMERGENCY_ESCAPED_OR_ENDGAMED)
		evac_state = DIRECTOR_EVAC_GONE
	else if(SSshuttle.emergency && SSshuttle.emergency.mode != SHUTTLE_IDLE)
		evac_state = DIRECTOR_EVAC_CALLED
	else
		evac_state = DIRECTOR_EVAC_NONE
