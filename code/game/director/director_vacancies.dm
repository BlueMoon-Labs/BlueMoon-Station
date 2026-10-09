/// Критичные отделы, в которые зовут из наблюдателей, гост-кафе и лобби: отдел -> кого в нём нет
GLOBAL_LIST_INIT(director_vacancy_departments, list(
	DIRECTOR_DEPT_SECURITY = "сотрудника службы безопасности",
	DIRECTOR_DEPT_MEDICAL = "медика",
	DIRECTOR_DEPT_ENGINEERING = "инженера",
))

/// Учёт пустых критичных отделов для приглашений в смену. На веса и выбор событий директора не влияет.
/datum/director_vacancies
	/// Отдел -> world.time, с которого в нём нет ни одного активного сотрудника
	var/list/empty_since = list()
	/// Отдел -> world.time последнего приглашения
	var/list/last_invite_at = list()

/// Обновляет учёт по укомплектованности бита и возвращает отделы, в которые пора позвать людей.
/datum/director_vacancies/proc/update(list/staffing, now, round_start_time, evac_state)
	. = list()
	for(var/dept in GLOB.director_vacancy_departments)
		if(staffing[dept])
			empty_since -= dept
			continue
		if(isnull(empty_since[dept]))
			empty_since[dept] = now
		if(evac_state != DIRECTOR_EVAC_NONE || now - round_start_time < DIRECTOR_VACANCY_ROUND_GRACE)
			continue
		if(now - empty_since[dept] < DIRECTOR_VACANCY_INVITE_DELAY)
			continue
		var/last_invite = last_invite_at[dept]
		if(!isnull(last_invite) && now - last_invite < DIRECTOR_VACANCY_INVITE_COOLDOWN)
			continue
		last_invite_at[dept] = now
		. += dept

/datum/director_vacancies/proc/is_vacant(dept)
	return !isnull(empty_since[dept])

/datum/director_vacancies/proc/note_filled(dept)
	empty_since -= dept

/proc/director_dept_positions(dept)
	switch(dept)
		if(DIRECTOR_DEPT_SECURITY)
			return GLOB.security_positions
		if(DIRECTOR_DEPT_MEDICAL)
			return GLOB.medical_positions
		if(DIRECTOR_DEPT_ENGINEERING)
			return GLOB.engineering_positions
	return list()

/// Звать ли игрока в отдел: приглашения у него включены и хотя бы одна должность отдела не под джоббаном.
/proc/shift_invite_wanted(datum/preferences/prefs, list/jobbans, dept)
	if(!prefs?.shift_invites)
		return FALSE
	for(var/title in director_dept_positions(dept))
		if(!jobbans || !(title in jobbans))
			return TRUE
	return FALSE

/datum/controller/subsystem/director/proc/update_vacancies(datum/director_signals/signals)
	for(var/dept in vacancies.update(signals.staffing, now(), SSticker.round_start_time, signals.evac_state))
		// Проверка респавна может сходить в БД за кэшем джоббанов и уснуть.
		INVOKE_ASYNC(src, PROC_REF(send_vacancy_invite), dept)

/datum/controller/subsystem/director/proc/send_vacancy_invite(dept)
	var/missing_text = "На станции нет ни одного [GLOB.director_vacancy_departments[dept]]. Нужна помощь"
	var/join_link = "<a href='byond://?src=[REF(GLOB.shift_invite_link)];join_shift=1'>Войти в смену</a>"
	var/invited = 0
	for(var/mob/player as anything in GLOB.player_list)
		var/client/player_client = player.client
		if(!player_client || !shift_invite_wanted(player_client.prefs, player_client.jobbancache, dept))
			continue
		if(isnewplayer(player))
			var/mob/dead/new_player/lobby_player = player
			if(!lobby_player.bm_lobby_ready || lobby_player.spawning)
				continue
			player_client << output(url_encode("[missing_text]: нажмите, чтобы войти в смену."), "bm_lobby_browser:bm_show_invite")
		else if(isobserver(player))
			if(respawn_block_reason(player, player_client.prefs))
				continue
			to_chat(player, span_ghostalert("[missing_text]: [join_link]"))
			SEND_SOUND(player, sound('sound/misc/notice2.ogg'))
			window_flash(player_client)
		else if(is_ghost_cafe_visitor(player))
			if(respawn_block_reason(player, player_client.prefs))
				continue
			to_chat(player, span_boldnotice("[missing_text]: [join_link]"))
		else
			continue
		invited++
	log_game("DIRECTOR VACANCY: отдел [dept] пуст, приглашение получили [invited]")

/// Летджойн в пустой критичный отдел снимает вакансию и ставит отметку бонуса.
/datum/controller/subsystem/director/proc/on_job_latejoin(datum/source, datum/job/job, mob/living/spawning)
	SIGNAL_HANDLER
	var/dept = director_dept_of_job(job?.title)
	if(isnull(dept) || !vacancies.is_vacant(dept))
		return
	vacancies.note_filled(dept)
	log_game("DIRECTOR VACANCY: [key_name(spawning)] занял пустой отдел [dept] ([job.title])")
	if(director_evac_state() != DIRECTOR_EVAC_NONE)
		return
	SSmetadollars.note_relief_join(spawning)
