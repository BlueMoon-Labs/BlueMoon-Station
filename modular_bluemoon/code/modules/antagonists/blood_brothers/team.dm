GLOBAL_LIST_INIT(brother_backstories, list(
	"Вы служили на одном рудовозе и не раз вытаскивали друг друга из разгерметизированных отсеков.",
	"Вы вместе бежали с колонии Тау, когда её закрыли на карантин.",
	"Вы выросли в одном приюте на орбитальной станции и поклялись держаться друг друга.",
	"Вы оба ходили в одной банде контрабандистов и единственные ушли из неё живыми.",
	"Когда-то вы делили одну камеру в тюрьме на Ио.",
	"Вы пережили крушение шаттла и неделю ждали спасателей в одной капсуле.",
	"Вы вместе работали на шахтах астероидного пояса и знаете цену чужому долгу.",
	"Вы прошли одни и те же испытания препаратов и с тех пор не верите корпорациям.",
	"Ваши семьи разорила одна и та же корпорация, и вы поклялись, что она заплатит.",
	"Вы служили в одном пограничном гарнизоне, пока его не бросили на произвол судьбы.",
	"Вы вместе выбрались из плена у космических пиратов.",
	"Вы росли на одной гидропонной ферме и смешали кровь ещё детьми.",
	"Вы были напарниками на спасательном буксире, пока его не списали за долги.",
	"Вы вместе пережили бунт на исследовательской станции и знаете, что там случилось на самом деле.",
	"Вы учились в одной лётной академии, и одного из вас отчислили за вину другого.",
	"Вы единственные пережили эпидемию на родной колонии.",
	"Вы вместе сбежали из долговой кабалы на фабриках внешних миров.",
	"Вы много лет возили грузы на одном вольном торговце и делили всё поровну.",
	"Вы выросли в соседних отсеках жилого кольца и дали клятву на крови в двенадцать лет.",
	"Вы служили в одной частной охране и однажды прикрыли друг друга ценой карьеры.",
))

/datum/team/brother_team
	name = "brotherhood"
	member_name = "blood brother"
	var/datum/blood_oath/oath
	/// Исполненные прежде клятвы: их венцы и финалы остаются за командой
	var/list/datum/blood_oath/fulfilled_oaths = list()
	var/list/datum/blood_oath/offered = list()
	var/datum/blood_oath/proposed
	var/datum/mind/proposed_by
	var/list/datum/mind/signed = list()
	var/oath_deadline = 0
	var/bond_tier = 0
	var/third_oath_used = FALSE
	var/replacement_available = FALSE
	var/replacement_used = FALSE
	var/list/datum/mind/severed_minds = list()
	/// mind -> BROTHER_SEVER_*: чем разорвали клятву
	var/list/severed_kinds = list()
	var/list/datum/mind/departed_minds = list()
	/// mind -> BROTHER_DEPARTURE_*
	var/list/departed_reasons = list()
	/// mind -> пол тела в момент ухода, для итогов раунда
	var/list/departed_genders = list()
	/// Последние Шёпоты крови: list("name", "text", "time", "heard" = WEAKREF разумов, кому он дошёл)
	var/list/whisper_log = list()
	/// mind -> world.time последнего отказа от клятвы третьего
	var/list/recruit_refusals = list()
	var/backstory
	var/cooldown_multiplier = 1
	var/datum/blood_vow/vow
	/// Учебная команда полигона: без сообщений админам и итогов раунда
	var/training = FALSE
	/// start() пройден: дальше братья приходят только клятвой третьего
	var/started = FALSE
	/// Ни одного брата в команде не осталось
	var/abandoned = FALSE
	/// mind -> world.time, с которого у брата нет игрока за телом или игрок без клиента
	var/list/ghost_since = list()
	var/next_sense_at = 0
	/// mind -> BROTHER_STATE_* с прошлой проверки, для Ярости
	var/list/last_states = list()
	/// Мёртвые братья, чью смерть почувствовали остальные
	var/list/datum/mind/fallen_minds = list()

/datum/team/brother_team/New(starting_members)
	. = ..()
	backstory = pick(GLOB.brother_backstories)
	RegisterSignals(src, list(COMSIG_BROTHER_TEAM_MEMBER_JOINED, COMSIG_BROTHER_TEAM_MEMBER_LEFT), PROC_REF(on_roster_changed))

/datum/team/brother_team/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	deltimer(oath_timer)
	dump_stash()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.silent = TRUE
		brother.owner.remove_antag_datum(/datum/antagonist/brother)
	QDEL_NULL(oath)
	QDEL_LIST(fulfilled_oaths)
	QDEL_LIST(offered)
	QDEL_NULL(vow)
	QDEL_LIST(objectives)
	proposed = null
	proposed_by = null
	signed.Cut()
	severed_minds.Cut()
	severed_kinds.Cut()
	departed_minds.Cut()
	departed_reasons.Cut()
	departed_genders.Cut()
	recruit_refusals.Cut()
	whisper_log.Cut()
	ghost_since.Cut()
	last_states.Cut()
	fallen_minds.Cut()
	return ..()

/datum/team/brother_team/process(delta_time)
	if(world.time < next_sense_at)
		return
	next_sense_at = world.time + BROTHER_SENSE_INTERVAL
	check_returns()
	if(abandoned)
		return
	check_departures()
	check_brother_states()
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.update_sense()
	oath?.on_team_tick()
	vow?.on_team_tick()
	capstone_tick()

/datum/team/brother_team/is_solo()
	return FALSE

/datum/team/brother_team/antag_check_name()
	return "[name] blood brothers"

/datum/team/brother_team/proc/update_name()
	var/list/last_names = list()
	for(var/datum/mind/member as anything in members)
		var/list/split_name = splittext(member.name, " ")
		last_names += split_name[length(split_name)]
	name = last_names.Join(" & ")

/datum/team/brother_team/proc/brother_antags()
	. = list()
	for(var/datum/mind/member as anything in members)
		var/datum/antagonist/brother/brother = member.has_antag_datum(/datum/antagonist/brother)
		if(brother?.team == src)
			. += brother

/// Тела живых братьев, не ушедших и не разорвавших клятву
/datum/team/brother_team/proc/living_brothers()
	. = list()
	for(var/datum/mind/member as anything in members - departed_minds - severed_minds)
		var/mob/living/body = member.current
		if(!QDELETED(body) && body.stat != DEAD)
			. += body

/datum/team/brother_team/proc/notify(message, sound_file, volume = BROTHER_NOTIFY_VOLUME, datum/mind/skip)
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/datum/mind/member = brother.owner
		var/mob/living/body = member.current
		if(member == skip || (member in departed_minds) || QDELETED(body) || brother.is_muted())
			continue
		to_chat(body, span_boldwarning(message))
		if(sound_file)
			body.playsound_local(get_turf(body), sound_file, volume, FALSE, pressure_affected = FALSE)
	pulse_bond()

/datum/team/brother_team/proc/start()
	if(started)
		return
	started = TRUE
	START_PROCESSING(SSprocessing, src)
	update_name()
	var/list/member_keys = list()
	for(var/datum/mind/member as anything in members)
		member_keys += key_name(member)
	log_game("Blood brothers [name] formed: [english_list(member_keys)].")
	offer_oaths()

/datum/team/brother_team/proc/set_bond_tier(new_tier)
	new_tier = clamp(round(new_tier), 0, BLOOD_BOND_TIER_MAX)
	if(new_tier == bond_tier)
		return FALSE
	var/old_tier = bond_tier
	bond_tier = new_tier
	SEND_SIGNAL(src, COMSIG_BROTHER_TEAM_TIER_CHANGED, new_tier, old_tier)
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.refresh_bond_actions()
	log_game("Blood brothers [name] bond tier: [old_tier] -> [new_tier].")
	return TRUE

/datum/team/brother_team/proc/has_stash_capstone()
	return holds_capstone(/datum/action/cooldown/blood_bond/capstone/stash)

/// Моб, за которым сидит игрок брата: тело, VR-аватар, призрак с правом вернуться или кукла полигона
/datum/team/brother_team/proc/player_mob_of(datum/mind/member)
	var/mob/living/body = member.current
	if(!QDELETED(body))
		if(body.key)
			return body
		if(body.audiovisual_redirect)
			return body.audiovisual_redirect
	var/mob/dead/observer/ghost = member.get_ghost()
	if(ghost)
		return ghost
	for(var/session_key in GLOB.antag_training_sessions)
		var/datum/antag_training_session/session = GLOB.antag_training_sessions[session_key]
		if(session.return_can_reenter && session.return_mind?.resolve() == member)
			return session.current_body
	return null

/datum/team/brother_team/proc/check_departures()
	for(var/datum/mind/member as anything in members - departed_minds)
		var/mob/living/body = member.current
		if(!QDELETED(body) && !body.loc)
			handle_departure(member, BROTHER_DEPARTURE_CRYO)
			continue
		var/mob/player = player_mob_of(member)
		var/reason
		var/grace = BROTHER_GHOST_GRACE
		if(QDELETED(body))
			if(!player)
				handle_departure(member, BROTHER_DEPARTURE_DELETED)
				continue
			reason = BROTHER_DEPARTURE_DELETED
		else if(!player)
			reason = BROTHER_DEPARTURE_GHOST
		else if(!GET_CLIENT(player))
			reason = BROTHER_DEPARTURE_SSD
			grace = BROTHER_SSD_GRACE
		if(!reason)
			ghost_since -= member
			continue
		if(isnull(ghost_since[member]))
			ghost_since[member] = world.time
		else if(world.time - ghost_since[member] >= grace)
			handle_departure(member, reason)

/// Ушедший снова в живом теле со своим игроком: связь возвращается, если у братьев есть место
/datum/team/brother_team/proc/check_returns()
	for(var/datum/mind/departed as anything in departed_minds - severed_minds)
		var/mob/living/body = departed.current
		if(!(departed in members) || QDELETED(body) || !body.loc || body.stat == DEAD)
			continue
		var/mob/player = player_mob_of(departed)
		if(!player || (player != body && player != body.audiovisual_redirect) || !GET_CLIENT(player))
			continue
		var/datum/antagonist/brother/returned_brother = departed.has_antag_datum(/datum/antagonist/brother)
		if(returned_brother?.team != src)
			continue
		if(length(members - departed_minds) >= BROTHER_TEAM_MAX_SIZE)
			log_game("Blood brother [key_name(departed)] returned to full [name] and was released.")
			clear_departure(departed)
			returned_brother.silent = TRUE
			departed.remove_antag_datum(/datum/antagonist/brother)
			to_chat(body, span_boldwarning("Клятва отпустила вас: место у братьев занято."))
			continue
		restore_departed(departed)

/datum/team/brother_team/proc/clear_departure(datum/mind/departed)
	departed_minds -= departed
	departed_reasons -= departed
	departed_genders -= departed
	ghost_since -= departed

/datum/team/brother_team/proc/restore_departed(datum/mind/returned)
	clear_departure(returned)
	if(!length(departed_minds))
		replacement_available = FALSE
	abandoned = FALSE
	if(started && !oath && !oath_timer)
		offer_oaths()
	log_game("Blood brother [key_name(returned)] returned to [name].")
	notify("Связь с [returned.name] вернулась.", skip = returned)
	var/datum/antagonist/brother/returned_brother = returned.has_antag_datum(/datum/antagonist/brother)
	if(!returned_brother.is_muted())
		to_chat(returned.current, span_boldnotice("Связь с братьями вернулась."))
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.refresh_bond_actions()
		brother.update_sense()
	refresh_brother_uis(static_data = TRUE)

/datum/team/brother_team/proc/handle_departure(datum/mind/departed, reason)
	if(!departed || (departed in departed_minds))
		return FALSE
	departed_minds += departed
	departed_reasons[departed] = reason
	departed_genders[departed] = departed.current?.gender
	ghost_since -= departed
	forget_departed(departed, reason)
	close_stash(departed.current)
	var/datum/antagonist/brother/departed_brother = departed.has_antag_datum(/datum/antagonist/brother)
	if(departed_brother?.team == src)
		departed_brother.refresh_bond_actions()
	var/list/remaining = members - departed_minds
	if(length(remaining) && !replacement_used)
		replacement_available = TRUE
	notify(reason == BROTHER_DEPARTURE_SEVERED ? "Связь с [departed.name] оборвалась." : "Связь с [departed.name] истончилась и пропала.")
	if(replacement_available && length(remaining))
		notify("Место ушедшего можно отдать: «Принять в братство» сработает ещё раз, даже если третий уже был.")
	SEND_SIGNAL(src, COMSIG_BROTHER_TEAM_MEMBER_LEFT, departed, reason)
	log_game("Blood brother [key_name(departed)] left [name]: [reason].")
	if(!length(remaining))
		abandoned = TRUE
		dump_stash()
	return TRUE

/// source_kind - BROTHER_SEVER_*, для окна и итогов; source_text с именем исполнителя - только в логи
/datum/team/brother_team/proc/sever(datum/mind/severed, source_text, source_kind)
	if(!(severed in members))
		return FALSE
	severed_minds |= severed
	severed_kinds[severed] = source_kind
	ADD_TRAIT(severed, TRAIT_BLOOD_OATH_SEVERED, BLOOD_OATH_TRAIT)
	severed.remove_antag_datum(/datum/antagonist/brother)
	var/turf/severed_turf = get_turf(severed.current)
	if(severed_turf)
		new /obj/effect/temp_visual/blood_brothers/sever_snap(severed_turf)
	if(severed.current)
		to_chat(severed.current, span_warning("Вы помните всё, что делали, но больше не чувствуете брата."))
		playsound(severed.current, 'modular_bluemoon/sound/blood_brothers/brother_severed.ogg', BROTHER_SEVERED_VOLUME, FALSE)
	handle_departure(severed, BROTHER_DEPARTURE_SEVERED)
	for(var/mob/living/body as anything in living_brothers())
		var/datum/antagonist/brother/listener = body.mind?.has_antag_datum(/datum/antagonist/brother)
		if(listener?.is_muted())
			continue
		body.playsound_local(get_turf(body), 'modular_bluemoon/sound/blood_brothers/brother_severed.ogg', BROTHER_SEVERED_VOLUME, FALSE, pressure_affected = FALSE)
	if(!training)
		message_admins("Кровная клятва [key_name_admin(severed)] в команде [name] разорвана: [source_text].")
	log_game("Blood oath of [key_name(severed)] in [name] severed by [source_text].")
	return TRUE

/// TRUE или строка-причина, почему recruiter сейчас никого не позовёт, кто бы ни стоял рядом
/datum/team/brother_team/proc/recruit_team_refusal(datum/mind/recruiter)
	var/list/active = members - departed_minds
	if(length(active) >= BROTHER_TEAM_MAX_SIZE)
		return "братьев уже [BROTHER_TEAM_MAX_SIZE]"
	if(third_oath_used && !replacement_available)
		return "клятва третьего уже дана"
	var/datum/antagonist/brother/recruiter_brother = recruiter?.has_antag_datum(/datum/antagonist/brother)
	if(recruiter_brother?.team != src || !(recruiter in active) || QDELETED(recruiter.current))
		return "вы не в этом братстве"
	if(recruiter_brother.is_muted())
		return "связь заглушена"
	if(recruiter.current.stat != CONSCIOUS)
		return "нужно быть в сознании"
	return TRUE

/// TRUE или строка-причина, почему recruiter не может позвать target
/datum/team/brother_team/proc/can_recruit(datum/mind/recruiter, mob/living/carbon/human/target)
	var/team_verdict = recruit_team_refusal(recruiter)
	if(team_verdict != TRUE)
		return team_verdict
	if(!ishuman(target) || !target.mind)
		return "клятву даёт только человек"
	if(!training && !GET_CLIENT(target))
		return "взгляд пустой"
	if(target.stat != CONSCIOUS)
		return "нужен кто-то в сознании"
	if(!target.Adjacent(recruiter.current))
		return "нужно встать вплотную"
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		return "майндшилд глушит связь"
	var/role_verdict = recruit_role_ok(target.mind)
	if(role_verdict != TRUE)
		return role_verdict
	if(oath?.is_target(target.mind))
		return "цель клятвы не позвать"
	var/refused_at = recruit_refusals[target.mind]
	if(!isnull(refused_at) && world.time - refused_at < BROTHER_RECRUIT_REFUSAL_COOLDOWN)
		return "отказ был совсем недавно"
	return TRUE

/// TRUE или строка-причина: роль, антагонисты, баны и настройки, без проверки соседства.
/// Бан смотрится только у тела с игроком: без клиента jobban_isbanned спит на запросе к БД
/datum/team/brother_team/proc/recruit_role_ok(datum/mind/candidate)
	var/mob/living/carbon/human/body = candidate?.current
	if(!ishuman(body))
		return "клятву даёт только человек"
	if((candidate in severed_minds) || HAS_TRAIT(candidate, TRAIT_BLOOD_OATH_SEVERED))
		return "эту клятву уже разорвали"
	if(brother_mind_is_antagonist(candidate) || candidate.is_ghost_role())
		return "у этого человека своя роль"
	var/datum/client_interface/body_client = GET_CLIENT(body)
	if(body_client && (jobban_isbanned(body, ROLE_BROTHER) || jobban_isbanned(body, ROLE_INTEQ)))
		return "не может стать братом"
	if(body_client?.prefs && (body_client.prefs.toggles & NO_ANTAG))
		return "не хочет быть антагонистом"
	if(candidate.assigned_role in GLOB.brother_protected_roles)
		return "должность не позволяет"
	return TRUE

/datum/team/brother_team/proc/recruit(datum/mind/new_mind)
	if(!new_mind?.add_antag_datum(training ? /datum/antagonist/brother/training : /datum/antagonist/brother, src))
		return FALSE
	if(replacement_available)
		replacement_available = FALSE
		replacement_used = TRUE
	else
		third_oath_used = TRUE
	recruit_refusals -= new_mind
	update_name()
	notify("[new_mind.name] принимает кровную клятву. Теперь вас [length(members - departed_minds)].")
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		brother.update_sense()
	log_game("Blood brother [key_name(new_mind)] joined [name] by blood oath.")
	if(!training)
		message_admins("[key_name_admin(new_mind)] принял кровную клятву и вступил в команду братьев [name].")
	return TRUE

/// Брат умер; зовётся из обработчика сигнала и не спит
/datum/team/brother_team/proc/on_brother_died(datum/mind/fallen)
	if((fallen in departed_minds) || (fallen in fallen_minds))
		return
	last_states[fallen] = BROTHER_STATE_DEAD
	var/datum/antagonist/brother/fallen_brother = fallen.has_antag_datum(/datum/antagonist/brother)
	if(!fallen_brother || fallen_brother.is_muted())
		return
	fallen_minds += fallen
	log_game("Blood brother [key_name(fallen)] of [name] died.")
	for(var/datum/antagonist/brother/survivor as anything in brother_antags())
		if(survivor != fallen_brother && !(survivor.owner in departed_minds))
			survivor.grieve(fallen)

/// Брат ожил, в своём теле или в новом; зовётся из обработчика сигнала и не спит
/datum/team/brother_team/proc/on_brother_revived(datum/mind/revived)
	if(!(revived in fallen_minds))
		return
	fallen_minds -= revived
	log_game("Blood brother [key_name(revived)] of [name] revived.")
	for(var/datum/antagonist/brother/brother as anything in brother_antags())
		var/mob/living/body = brother.owner.current
		if(brother.owner == revived || (brother.owner in departed_minds) || !isliving(body) || brother.is_muted())
			continue
		to_chat(body, span_boldnotice("Связь с [revived.name] вернулась."))
	if(!length(fallen_minds))
		end_grief()
