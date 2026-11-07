GLOBAL_LIST_INIT(antag_training_squad_colors, list("#e05d5d", "#4fb3d9", "#6cc070", "#e8a33d", "#a66bd3", "#e07b39", "#3dbfa5", "#d95fa0"))
GLOBAL_LIST_INIT(antag_training_squad_actions, list("squad_create", "squad_join", "squad_accept", "squad_decline", "squad_leave", "squad_invite", "squad_kick", "squad_leader", "squad_open", "booking_book", "booking_release", "booking_extend", "waitlist_join", "waitlist_leave"))
/// Как часто группе объявляют смену «Открытая группа».
#define ANTAG_TRAINING_SQUAD_OPEN_NOTICE (10 SECONDS)

/datum/antag_training_arena
	var/list/datum/antag_training_squad/squads = list()
	var/squads_created = 0

/datum/antag_training_session
	var/datum/antag_training_squad/squad
	/// Отказ в движении приходит не с каждым шагом.
	var/next_move_notice_at = 0

/datum/antag_training_sector
	var/datum/antag_training_squad/booked_by
	var/booked_until = 0
	/// Когда в секторе последний раз видели кого-то из группы брони.
	var/booking_seen_at = 0
	var/booking_timer
	var/list/datum/antag_training_session/waitlist = list()
	/// Группы из очереди, которым сектор ещё не предлагали; занять его сейчас может только priority_squad.
	var/list/datum/antag_training_squad/priority_queue = list()
	var/datum/antag_training_squad/priority_squad
	var/priority_until = 0
	var/priority_timer

/datum/antag_training_squad
	var/datum/antag_training_arena/arena
	var/name
	var/color
	var/open = TRUE
	var/datum/antag_training_session/leader
	var/list/datum/antag_training_session/members = list()
	/// Приглашённый сеанс -> срок ответа.
	var/list/invites = list()
	var/datum/antag_training_sector/sector
	/// Идущий сценарий группы.
	var/datum/antag_training_scenario/scenario
	var/next_open_notice_at = 0

/datum/antag_training_squad/New(datum/antag_training_arena/owner, datum/antag_training_session/founder, squad_name, is_open = TRUE)
	arena = owner
	arena.squads_created++
	name = squad_name || "Группа [arena.squads_created]"
	color = GLOB.antag_training_squad_colors[(arena.squads_created - 1) % length(GLOB.antag_training_squad_colors) + 1]
	open = !!is_open
	arena.squads += src
	add_member(founder)

/datum/antag_training_squad/Destroy()
	QDEL_NULL(scenario)
	release()
	for(var/sector_id in arena?.sectors)
		var/datum/antag_training_sector/target = arena.sectors[sector_id]
		target.priority_queue -= src
		if(target.priority_squad == src)
			target.offer_priority()
	for(var/datum/antag_training_session/member as anything in members)
		if(member.squad == src)
			member.squad = null
	members.Cut()
	invites.Cut()
	arena?.squads -= src
	arena = null
	leader = null
	return ..()

/proc/antag_training_squad_name(raw_name)
	return trim(strip_html_simple(sanitize_simple(copytext_char("[raw_name]", 1, MAX_NAME_LEN), list("\n" = " ", "\t" = " "))), ANTAG_TRAINING_SQUAD_NAME_LENGTH + 1)

/proc/antag_training_clock(duration)
	var/total = max(0, round(duration / (1 SECONDS)))
	var/seconds = total % 60
	return "[round(total / 60)]:[seconds < 10 ? "0" : ""][seconds]"

/datum/antag_training_session/proc/same_squad(datum/antag_training_session/other)
	return other == src || (squad && other?.squad == squad)

/datum/antag_training_session/proc/squad_name()
	return current_body?.real_name || "Смена персонажа"

/datum/antag_training_arena/proc/create_squad(datum/antag_training_session/founder, squad_name, is_open = TRUE)
	if(finished || !(founder in members) || founder.finished)
		return null
	if(founder.squad)
		founder.practice_message("Вы уже в группе «[founder.squad.name]». Выйдите из неё, чтобы собрать свою.")
		return null
	var/clean_name = antag_training_squad_name(squad_name)
	if(clean_name && CHAT_FILTER_CHECK(clean_name))
		founder.practice_message("В имени группы запрещённое слово. Выберите другое имя.")
		return null
	var/datum/antag_training_squad/created = new(src, founder, clean_name, is_open)
	log_game("Полигон: [key_name(founder.current_body)] собирает группу «[created.name]».")
	founder.practice_message("Группа «[created.name]» собрана. Пригласите участников ниже[created.open ? " или подождите, пока они присоединятся сами" : ""].")
	return created

/// Сеанс уходит с полигона: из группы, из приглашений и очередей.
/datum/antag_training_arena/proc/forget_squad_member(datum/antag_training_session/member)
	for(var/datum/antag_training_squad/team as anything in squads.Copy())
		team.invites -= member
		team.remove_member(member, moved = FALSE)
	for(var/sector_id in sectors)
		var/datum/antag_training_sector/sector = sectors[sector_id]
		sector.waitlist -= member

/datum/antag_training_arena/proc/booking_limit()
	return max(0, length(sectors) - ANTAG_TRAINING_BOOKING_FREE_SECTORS)

/datum/antag_training_arena/proc/booked_count()
	. = 0
	for(var/sector_id in sectors)
		var/datum/antag_training_sector/sector = sectors[sector_id]
		if(sector.booked_by)
			.++

/// Кто голосует за сброс: в занятом секторе - только его группа.
/datum/antag_training_arena/proc/reset_voters(zone_id)
	var/datum/antag_training_sector/sector = sectors[zone_id]
	return sector?.booked_by ? sector.booked_by.members : members

/datum/antag_training_arena/proc/reset_refusal(datum/antag_training_session/requester, zone_id)
	var/datum/antag_training_sector/sector = sectors[zone_id]
	if(sector?.booked_by && requester != sector.booked_by.leader)
		return "Сектор «[sector.name]» занят группой «[sector.booked_by.name]»: сброс запускает её лидер."
	return null

/datum/antag_training_arena/proc/may_cancel_reset(datum/antag_training_session/member)
	var/datum/antag_training_sector/sector = sectors[pending_reset_zone]
	return !sector?.booked_by || (member in sector.booked_by.members)

/datum/antag_training_squad/proc/add_member(datum/antag_training_session/session)
	members += session
	session.squad = src
	invites -= session
	if(!leader)
		leader = session
	sector?.waitlist -= session
	arena.sync_reset_votes()

/datum/antag_training_squad/proc/announce(message)
	for(var/datum/antag_training_session/member as anything in members)
		to_chat(member.current_body, span_notice(message))

/// Убирает сеанс из группы. moved: вывести его из сектора брони, раз он больше не в группе.
/datum/antag_training_squad/proc/remove_member(datum/antag_training_session/session, reason, moved = TRUE)
	if(!(session in members))
		return FALSE
	members -= session
	scenario?.forget(session)
	if(session.squad == src)
		session.squad = null
	arena.sync_reset_votes()
	if(moved && sector?.bounds && !session.finished && session.current_body && arena.inside_bounds(get_turf(session.current_body), sector.bounds))
		session.current_body.forceMove(arena.entry_turf)
	if(reason)
		to_chat(session.current_body, span_notice(reason))
	if(!length(members))
		disband()
		return TRUE
	if(leader == session)
		leader = members[1]
		announce("[session.squad_name()] покидает группу, лидер теперь [leader.squad_name()].")
	else
		announce("[session.squad_name()] покидает группу.")
	return TRUE

/datum/antag_training_squad/proc/disband(reason)
	if(QDELETED(src))
		return
	log_game("Полигон: группа «[name]» распущена.")
	release(reason || (sector ? "Группа распущена, бронь сектора «[sector.name]» снята." : null))
	for(var/datum/antag_training_session/member as anything in members)
		to_chat(member.current_body, span_notice("Группа «[name]» распущена."))
	qdel(src)

/datum/antag_training_squad/proc/invite_active(datum/antag_training_session/session)
	var/deadline = invites[session]
	if(!deadline)
		return FALSE
	if(world.time < deadline)
		return TRUE
	invites -= session
	return FALSE

/datum/antag_training_squad/proc/invite(datum/antag_training_session/inviter, datum/antag_training_session/target)
	if(QDELETED(src) || inviter != leader || inviter.finished || !target || target.finished || !(target in arena.members) || (target in members))
		return FALSE
	if(target.squad)
		inviter.practice_message("[target.squad_name()] уже в группе «[target.squad.name]».")
		return FALSE
	if(invite_active(target))
		return FALSE
	invites[target] = world.time + ANTAG_TRAINING_SQUAD_INVITE
	to_chat(target.current_body, span_notice("[inviter.squad_name()] зовёт вас в группу «[name]». Примите приглашение во вкладке «Участники» пульта за [ANTAG_TRAINING_SQUAD_INVITE / (1 SECONDS)] секунд."))
	return TRUE

/datum/antag_training_squad/proc/accept_invite(datum/antag_training_session/session)
	if(QDELETED(src) || !session || session.finished || !(session in arena.members) || !invite_active(session))
		return FALSE
	if(session.squad)
		session.practice_message("Сначала выйдите из группы «[session.squad.name]».")
		return FALSE
	add_member(session)
	announce("[session.squad_name()] присоединяется к группе «[name]».")
	return TRUE

/datum/antag_training_squad/proc/decline_invite(datum/antag_training_session/session)
	if(!invite_active(session))
		return FALSE
	invites -= session
	to_chat(leader?.current_body, span_notice("[session.squad_name()] отказывается от приглашения в группу."))
	return TRUE

/datum/antag_training_squad/proc/join(datum/antag_training_session/session)
	if(QDELETED(src) || !session || session.finished || !(session in arena.members) || (session in members))
		return FALSE
	if(!open && !invite_active(session))
		session.practice_message("Группа «[name]» собирается по приглашениям. Попросите её лидера позвать вас.")
		return FALSE
	if(session.squad)
		session.practice_message("Сначала выйдите из группы «[session.squad.name]».")
		return FALSE
	add_member(session)
	announce("[session.squad_name()] присоединяется к группе «[name]».")
	return TRUE

/datum/antag_training_squad/proc/kick(datum/antag_training_session/requester, datum/antag_training_session/target)
	if(requester != leader || target == requester || !(target in members))
		return FALSE
	return remove_member(target, "Лидер исключил вас из группы «[name]».")

/datum/antag_training_squad/proc/set_leader(datum/antag_training_session/requester, datum/antag_training_session/target)
	if(requester != leader || target == requester || !(target in members) || target.finished)
		return FALSE
	leader = target
	announce("Лидер группы «[name]» теперь [target.squad_name()].")
	return TRUE

/datum/antag_training_squad/proc/set_open(datum/antag_training_session/requester, is_open)
	if(requester != leader || open == !!is_open)
		return FALSE
	open = !!is_open
	if(world.time >= next_open_notice_at)
		next_open_notice_at = world.time + ANTAG_TRAINING_SQUAD_OPEN_NOTICE
		announce(open ? "Группа «[name]» открыта: присоединиться может любой участник." : "Группа «[name]» теперь только по приглашениям.")
	return TRUE

/// Почему группа не может занять сектор, или null.
/datum/antag_training_squad/proc/booking_refusal(datum/antag_training_sector/target)
	if(!target || target.arena != arena)
		return "Такого сектора нет."
	if(sector)
		return "У группы уже есть бронь: «[sector.name]». Снимите её, чтобы занять другой сектор."
	if(target.booked_by)
		return "Сектор «[target.name]» уже занят группой «[target.booked_by.name]»."
	var/datum/antag_training_squad/first = target.priority_holder()
	if(first && first != src)
		return "Сектор «[target.name]» придержан для группы «[first.name]» из очереди: она может занять его первой ещё [antag_training_clock(target.priority_until - world.time)]."
	var/limit = arena.booking_limit()
	if(arena.booked_count() >= limit)
		return "Занято секторов: [limit] из [length(arena.sectors)]. [ANTAG_TRAINING_BOOKING_FREE_SECTORS] всегда остаются свободными для всех, дождитесь, пока какая-нибудь группа освободит свой."
	var/list/outsiders = list()
	if(target.bounds)
		for(var/datum/antag_training_session/visitor as anything in arena.members)
			if(!(visitor in members) && arena.inside_bounds(get_turf(visitor.current_body), target.bounds))
				outsiders += visitor.squad_name()
	if(length(outsiders))
		return "В секторе «[target.name]» есть участники не из группы: [outsiders.Join(", ")]. Попросите их выйти, потом занимайте."
	return null

/datum/antag_training_squad/proc/book(datum/antag_training_session/requester, datum/antag_training_sector/target)
	if(QDELETED(src) || requester != leader || requester.finished || arena.finished)
		return FALSE
	var/refusal = booking_refusal(target)
	if(refusal)
		requester.practice_message(refusal)
		return FALSE
	sector = target
	target.booked_by = src
	var/list/datum/antag_training_squad/still_waiting = target.priority_queue - src
	target.clear_priority()
	target.booked_until = world.time + ANTAG_TRAINING_BOOKING_LIMIT
	target.booking_seen_at = world.time
	for(var/datum/antag_training_session/member as anything in members)
		target.waitlist -= member
	target.booking_timer = addtimer(CALLBACK(target, TYPE_PROC_REF(/datum/antag_training_sector, check_booking)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)
	log_game("Полигон: [key_name(requester.current_body)] бронирует сектор «[target.name]» для группы «[name]».")
	announce("Группа заняла сектор «[target.name]» на [ANTAG_TRAINING_BOOKING_LIMIT / (1 MINUTES)] минут. Входить в него может только группа; если [ANTAG_TRAINING_BOOKING_IDLE / (1 MINUTES)] минут внутри никого из вас не будет, бронь снимется. Пока в секторе идёт партия группы, бронь не снимается.")
	for(var/datum/antag_training_squad/waiting as anything in still_waiting)
		if(!QDELETED(waiting) && !waiting.sector && target.join_waitlist(waiting.leader, notify = FALSE))
			waiting.announce("Сектор «[target.name]» заняла группа «[name]», чья очередь подошла раньше. Ваша группа снова в очереди к нему.")
	if(target.state != ANTAG_TRAINING_SECTOR_READY)
		INVOKE_ASYNC(src, PROC_REF(load_booked), target)
	return TRUE

/// Срок брони идёт с готовности сектора, а не с начала загрузки.
/datum/antag_training_squad/proc/load_booked(datum/antag_training_sector/target)
	var/loaded = target.load()
	if(QDELETED(src) || sector != target)
		return
	if(!loaded)
		release("Сектор «[target.name]» не удалось загрузить, бронь снята.")
		return
	target.booked_until = world.time + ANTAG_TRAINING_BOOKING_LIMIT
	target.booking_seen_at = world.time

/datum/antag_training_squad/proc/release(reason)
	var/datum/antag_training_sector/target = sector
	if(!target)
		return FALSE
	sector = null
	target.clear_booking()
	log_game("Полигон: группа «[name]» освобождает сектор «[target.name]».[reason ? " [reason]" : ""]")
	if(reason)
		announce(reason)
	return TRUE

/datum/antag_training_squad/proc/release_booking(datum/antag_training_session/requester)
	if(requester != leader || !sector)
		return FALSE
	return release("Лидер освободил сектор «[sector.name]».")

/datum/antag_training_squad/proc/extend_booking(datum/antag_training_session/requester)
	if(requester != leader || !sector || requester.finished)
		return FALSE
	if(length(sector.waitlist))
		requester.practice_message("Продлить бронь нельзя: сектор «[sector.name]» ждут в очереди ([length(sector.waitlist)]). Освободите его, когда закончите.")
		return FALSE
	sector.booked_until = world.time + ANTAG_TRAINING_BOOKING_LIMIT
	announce("Бронь сектора «[sector.name]» продлена: снова [ANTAG_TRAINING_BOOKING_LIMIT / (1 MINUTES)] минут.")
	return TRUE

/datum/antag_training_squad/proc/present_in(datum/antag_training_sector/target)
	if(!target.bounds)
		return FALSE
	for(var/datum/antag_training_session/member as anything in members)
		if(arena.inside_bounds(get_turf(member.current_body), target.bounds))
			return TRUE
	return FALSE

/datum/antag_training_squad/proc/ui_entry(datum/antag_training_session/viewer)
	var/list/member_entries = list()
	for(var/datum/antag_training_session/member as anything in members)
		member_entries += list(list("id" = REF(member), "name" = member.squad_name(), "leader" = member == leader))
	var/list/invited = list()
	if(viewer == leader)
		for(var/datum/antag_training_session/target as anything in invites.Copy())
			if(invite_active(target))
				invited += list(list("id" = REF(target), "name" = target.squad_name(), "remaining" = max(0, round((invites[target] - world.time) / (1 SECONDS)))))
	return list("id" = REF(src), "name" = name, "color" = color, "open" = open, "leader" = leader?.squad_name(), "members" = member_entries, "sector" = sector?.name, "sector_id" = sector?.id, "mine" = (viewer in members), "invited" = invited)

/// Почему сеанс не может войти в сектор, или null.
/datum/antag_training_sector/proc/entry_refusal(datum/antag_training_session/session)
	if(!booked_by || session?.stand_full())
		return null
	if(session in booked_by.members)
		// Пока здесь идёт партия группы, внутрь пускают только её участников.
		return scenario_running() ? booked_by.scenario.entry_refusal(session) : null
	return "Сектор «[name]» занят группой «[booked_by.name]» ещё на [antag_training_clock(booked_until - world.time)]. Встаньте в очередь во вкладке «Зоны»: пока в ней кто-то есть, бронь не продлят, а освободившийся сектор группы из очереди получают по порядку, каждая на [ANTAG_TRAINING_BOOKING_PRIORITY / (1 SECONDS)] секунд."

/datum/antag_training_sector/proc/check_booking()
	deltimer(booking_timer)
	booking_timer = null
	var/datum/antag_training_squad/holder = booked_by
	if(!holder || !arena || arena.finished)
		return
	var/playing = scenario_running()
	if(playing || holder.present_in(src))
		booking_seen_at = world.time
	if(world.time >= booked_until && !playing)
		holder.release("Срок брони сектора «[name]» вышел.")
		return
	if(world.time >= booking_seen_at + ANTAG_TRAINING_BOOKING_IDLE)
		holder.release("Бронь сектора «[name]» снята: [ANTAG_TRAINING_BOOKING_IDLE / (1 MINUTES)] минут в нём не было никого из группы.")
		return
	booking_timer = addtimer(CALLBACK(src, PROC_REF(check_booking)), ANTAG_TRAINING_SECTOR_IDLE_CHECK, TIMER_STOPPABLE)

/// Партия группы брони идёт в этом секторе: срок и простой брони её не прерывают.
/datum/antag_training_sector/proc/scenario_running()
	var/datum/antag_training_scenario/current = booked_by?.scenario
	return current?.venue?.id() == id && (current.phase == ANTAG_TRAINING_SCENARIO_STARTING || current.phase == ANTAG_TRAINING_SCENARIO_RUNNING)

/// Почему mover не войдёт на клетку destination чужого занятого сектора; null - можно. Из самого сектора не выталкивает.
/datum/antag_training_arena/proc/booking_move_refusal(mob/mover, turf/destination)
	for(var/sector_id in sectors)
		var/datum/antag_training_sector/sector = sectors[sector_id]
		if(!sector.booked_by || !sector.bounds || !inside_bounds(destination, sector.bounds))
			continue
		if(inside_bounds(get_turf(mover), sector.bounds))
			return null
		var/datum/antag_training_session/session = session_of(mover)
		var/refusal = session && sector.entry_refusal(session)
		session?.move_notice(refusal)
		return refusal
	return null

/// Цели в занятом секторе создаёт только его группа; null - можно.
/datum/antag_training_arena/proc/booked_zone_refusal(zone_id, datum/antag_training_session/creator)
	var/datum/antag_training_sector/sector = sectors[zone_id]
	if(!creator || !sector?.booked_by)
		return null
	if(sector.scenario_running())
		return sector.booked_by.scenario.target_refusal(creator)
	if(creator in sector.booked_by.members)
		return null
	return "Сектор «[sector.name]» занят группой «[sector.booked_by.name]»: цели в нём создаёт только она."

/datum/antag_training_sector/proc/clear_booking()
	deltimer(booking_timer)
	booking_timer = null
	var/datum/antag_training_squad/previous = booked_by
	booked_by = null
	booked_until = 0
	booking_seen_at = 0
	last_occupied_at = world.time
	if(arena?.pending_reset_zone == id)
		arena.cancel_reset()
	clear_priority()
	for(var/datum/antag_training_session/waiting as anything in waitlist)
		if(waiting.squad && waiting.squad != previous && !(waiting.squad in priority_queue))
			priority_queue += waiting.squad
	var/list/datum/antag_training_session/notified = waitlist.Copy()
	waitlist.Cut()
	if(!arena || arena.finished || !offer_priority())
		for(var/datum/antag_training_session/waiting as anything in notified)
			to_chat(waiting.current_body, span_notice("Сектор «[name]» освободился: можно войти или занять его своей группой."))
		return
	for(var/datum/antag_training_session/waiting as anything in notified)
		if(waiting.squad != priority_squad)
			to_chat(waiting.current_body, span_notice("Сектор «[name]» освободился. Войти можно уже сейчас, а занять его первой может группа «[priority_squad.name]», которая раньше встала в очередь: у неё [ANTAG_TRAINING_BOOKING_PRIORITY / (1 SECONDS)] секунд, потом очередь следующей группы."))

/// Предлагает сектор следующей группе очереди на ANTAG_TRAINING_BOOKING_PRIORITY. TRUE - окно открыто.
/datum/antag_training_sector/proc/offer_priority()
	deltimer(priority_timer)
	priority_timer = null
	priority_squad = null
	priority_until = 0
	while(length(priority_queue) && !booked_by && arena && !arena.finished)
		var/datum/antag_training_squad/next = priority_queue[1]
		priority_queue.Cut(1, 2)
		if(QDELETED(next) || next.sector)
			continue
		priority_squad = next
		priority_until = world.time + ANTAG_TRAINING_BOOKING_PRIORITY
		priority_timer = addtimer(CALLBACK(src, PROC_REF(offer_priority)), ANTAG_TRAINING_BOOKING_PRIORITY, TIMER_STOPPABLE)
		next.announce("Сектор «[name]» освободился. Ваша группа стояла в очереди: занять его можете только вы, ещё [ANTAG_TRAINING_BOOKING_PRIORITY / (1 SECONDS)] секунд. Лидер бронирует его во вкладке «Зоны».")
		return TRUE
	priority_queue.Cut()
	return FALSE

/// Группа, за которой сейчас придержан сектор; просроченное или ненужное окно уходит следующей.
/datum/antag_training_sector/proc/priority_holder()
	if(priority_squad && (QDELETED(priority_squad) || priority_squad.sector || world.time >= priority_until))
		offer_priority()
	return priority_squad

/datum/antag_training_sector/proc/clear_priority()
	deltimer(priority_timer)
	priority_timer = null
	priority_squad = null
	priority_until = 0
	priority_queue.Cut()

/datum/antag_training_sector/proc/join_waitlist(datum/antag_training_session/session, notify = TRUE)
	if(!booked_by || !session || session.finished || !(session in arena.members) || (session in booked_by.members) || (session in waitlist))
		return FALSE
	waitlist += session
	if(notify)
		to_chat(booked_by.leader?.current_body, span_notice("[session.squad_name()] ждёт сектор «[name]»: продлить бронь уже не получится."))
	return TRUE

/datum/antag_training_sector/proc/leave_waitlist(datum/antag_training_session/session)
	if(!(session in waitlist))
		return FALSE
	waitlist -= session
	return TRUE

/datum/antag_training_sector/proc/booking_entry(datum/antag_training_session/viewer)
	var/list/waiting = list()
	for(var/datum/antag_training_session/session as anything in waitlist)
		waiting += session.squad_name()
	var/list/entry = list("id" = id, "squad" = booked_by?.name, "color" = booked_by?.color, "mine" = !!(booked_by && (viewer in booked_by.members)), "leader" = !!(booked_by && booked_by.leader == viewer), "waitlist" = waiting, "on_waitlist" = (viewer in waitlist))
	entry["remaining"] = booked_by ? max(0, round((booked_until - world.time) / (1 SECONDS))) : 0
	entry["idle_remaining"] = booked_by ? max(0, round((booking_seen_at + ANTAG_TRAINING_BOOKING_IDLE - world.time) / (1 SECONDS))) : 0
	var/datum/antag_training_squad/first = booked_by ? null : priority_holder()
	entry["priority"] = first?.name
	entry["priority_mine"] = !!first && viewer.squad == first
	entry["priority_remaining"] = first ? max(0, round((priority_until - world.time) / (1 SECONDS))) : 0
	return entry

/datum/antag_training_session/proc/squad_ui_data(list/data)
	data["squads"] = list()
	data["squad_invites"] = list()
	for(var/datum/antag_training_squad/team as anything in arena.squads)
		data["squads"] += list(team.ui_entry(src))
		if(team.invite_active(src))
			data["squad_invites"] += list(list("id" = REF(team), "name" = team.name, "color" = team.color, "remaining" = max(0, round((team.invites[src] - world.time) / (1 SECONDS)))))
	data["squad"] = squad ? REF(squad) : null
	data["squad_leader"] = !!squad && squad.leader == src
	var/list/bookings = list()
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		bookings[sector_id] = sector.booking_entry(src)
	data["bookings"] = bookings
	data["booking_used"] = arena.booked_count()
	data["booking_max"] = arena.booking_limit()
	data["booking_minutes"] = ANTAG_TRAINING_BOOKING_LIMIT / (1 MINUTES)
	data["booking_idle_minutes"] = ANTAG_TRAINING_BOOKING_IDLE / (1 MINUTES)
	data["squad_invite_seconds"] = ANTAG_TRAINING_SQUAD_INVITE / (1 SECONDS)

/datum/antag_training_session/proc/squad_act(action, list/params)
	var/datum/antag_training_squad/target_squad = locate(params["id"]) in arena.squads
	var/datum/antag_training_session/target_member = locate(params["id"]) in arena.members
	var/datum/antag_training_sector/target_sector = istext(params["id"]) ? arena.sectors[params["id"]] : null
	switch(action)
		if("squad_create")
			arena.create_squad(src, istext(params["name"]) ? params["name"] : null, params["open"] != FALSE)
		if("squad_join")
			target_squad?.join(src)
		if("squad_accept")
			target_squad?.accept_invite(src)
		if("squad_decline")
			target_squad?.decline_invite(src)
		if("squad_leave")
			if(squad)
				squad.remove_member(src, "Вы вышли из группы «[squad.name]».")
		if("squad_invite")
			squad?.invite(src, target_member)
		if("squad_kick")
			squad?.kick(src, target_member)
		if("squad_leader")
			squad?.set_leader(src, target_member)
		if("squad_open")
			squad?.set_open(src, !squad.open)
		if("booking_book")
			if(!squad)
				practice_message("Бронирует сектор лидер группы. Соберите группу во вкладке «Участники».")
				return TRUE
			squad.book(src, target_sector)
		if("booking_release")
			squad?.release_booking(src)
		if("booking_extend")
			squad?.extend_booking(src)
		if("waitlist_join")
			target_sector?.join_waitlist(src)
		if("waitlist_leave")
			target_sector?.leave_waitlist(src)
	return TRUE

#undef ANTAG_TRAINING_SQUAD_OPEN_NOTICE
