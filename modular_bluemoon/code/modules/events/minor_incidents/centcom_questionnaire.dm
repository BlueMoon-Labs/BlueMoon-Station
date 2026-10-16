#define QUESTIONNAIRE_REWARD 450
#define QUESTIONNAIRE_COMMEND_REWARD 100
#define QUESTIONNAIRE_DEADLINE (20 MINUTES)
#define QUESTIONNAIRE_REPLY_DELAY (20 SECONDS)
/// Сетевой ID особого адресата ЦК в факсе (special_networks["nanotrasen"]).
#define QUESTIONNAIRE_CENTCOM_ID "central_command"
#define QUESTIONNAIRE_FIELD_RATING 0
#define QUESTIONNAIRE_FIELD_INCIDENT 1
#define QUESTIONNAIRE_FIELD_COMMEND 2
#define QUESTIONNAIRE_FIELD_SIGNATURE 3
/// Более короткий кусок имени совпадёт с половиной экипажа.
#define QUESTIONNAIRE_NAME_MIN_PART 3
#define QUESTIONNAIRE_NEWS_CHANNEL "Станционные Объявления"

/datum/round_event_control/paperwork/centcom_questionnaire
	name = "Central Command Questionnaire"
	typepath = /datum/round_event/paperwork/centcom_questionnaire
	family = "centcom_questionnaire"
	min_staffing = list(DIRECTOR_DEPT_COMMAND = 1)

/datum/round_event_control/paperwork/centcom_questionnaire/New()
	description = "На факс командования приходит шуточная анкета ЦК о смене. Заполненная, подписанная и заверенная печатью капитана, главы отдела или представителя NT анкета, отправленная факсом в ЦК за [DisplayTimeText(QUESTIONNAIRE_DEADLINE)], приносит [QUESTIONNAIRE_REWARD] кр в гражданский бюджет. Отмеченный в анкете сотрудник получает благодарность ЦК и [QUESTIONNAIRE_COMMEND_REWARD] кр, если это не тот, кто анкету подписал или отправил; итоги опроса выходят в ленте новостей. Без ответа приходит вежливое напоминание, штрафа нет."
	return ..()

/datum/round_event_control/paperwork/centcom_questionnaire/preflight_failure()
	if(!find_command_fax())
		return "На станции нет работающего факса командования."
	return null

/datum/round_event_control/paperwork/centcom_questionnaire/proc/find_command_fax()
	return find_station_command_fax()

/// Факс мостика, затем кабинетов капитана и HoP, затем любой другой в командных отсеках.
/proc/find_station_command_fax()
	var/static/list/preferred_areas = list(
		/area/command/bridge,
		/area/command/heads_quarters/captain,
		/area/command/heads_quarters/hop,
		/area/command,
	)
	var/list/candidates = list()
	for(var/obj/machinery/fax/fax as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/fax))
		if(fax.syndicate_network || !fax.visible_to_network || !fax.is_operational() || !is_station_level(fax.z))
			continue
		candidates += fax
	for(var/area_type in preferred_areas)
		var/list/in_area = list()
		for(var/obj/machinery/fax/fax as anything in candidates)
			if(istype(get_area(fax), area_type))
				in_area += fax
		if(length(in_area))
			return pick(in_area)
	return null

/datum/round_event/paperwork/centcom_questionnaire
	var/fax_name

/datum/round_event/paperwork/centcom_questionnaire/start()
	var/datum/round_event_control/paperwork/centcom_questionnaire/questionnaire = control
	var/obj/machinery/fax/fax = questionnaire.find_command_fax()
	if(!fax)
		return
	var/datum/centcom_questionnaire/survey = new(fax)
	survey.open(QUESTIONNAIRE_DEADLINE)
	fax_name = fax.fax_name
	log_game("DIRECTOR: [control.name], анкета отправлена на факс [fax_name] в [AREACOORD(fax)].")

/datum/round_event/paperwork/centcom_questionnaire/announce(fake)
	if(!fax_name)
		return
	priority_announce("Отдел изучения удовлетворённости персонала направил на факс «[fax_name]» анкету о ходе смены. Капитану, главе отдела или представителю NanoTrasen нужно заполнить её, подписать, заверить печатью и вернуть факсом в ЦК в течение [DisplayTimeText(QUESTIONNAIRE_DEADLINE)]. За своевременный ответ гражданский бюджет получит [QUESTIONNAIRE_REWARD] кр, а отмеченный в анкете сотрудник - благодарность ЦК и [QUESTIONNAIRE_COMMEND_REWARD] кр.", "Отдел изучения удовлетворённости ЦК")

/// Состояние одной анкеты: срок ответа, проверка и ответные факсы.
/datum/centcom_questionnaire
	var/datum/weakref/home_fax_ref
	var/deadline
	var/deadline_timer
	var/resolved = FALSE
	var/rewarded = FALSE

/datum/centcom_questionnaire/New(obj/machinery/fax/home_fax)
	. = ..()
	home_fax_ref = WEAKREF(home_fax)

/datum/centcom_questionnaire/Destroy()
	if(deadline_timer)
		deltimer(deadline_timer)
		deadline_timer = null
	return ..()

/// Срок пошёл, бланк сразу уходит на факс командования.
/datum/centcom_questionnaire/proc/open(duration)
	deadline = world.time + duration
	deadline_timer = addtimer(CALLBACK(src, PROC_REF(expire)), duration, TIMER_STOPPABLE)
	deliver_fax(make_form())

/datum/centcom_questionnaire/proc/make_form()
	var/obj/item/paper/centcom_questionnaire/form = new()
	form.survey = src
	form.add_raw_text("<center><b>ЦЕНТРАЛЬНОЕ КОМАНДОВАНИЕ NANOTRASEN</b><br>Отдел изучения удовлетворённости персонала<br>Анкета КС-7 «Как проходит смена?»</center><br>\
1. Оцените смену от 1 до 10, где 1 - «эвакуация досрочно», а 10 - «эвакуация по расписанию»: \[____\]<br><br>\
2. Самое необычное происшествие смены одной фразой. Взрывы не предлагать, о них нам и так докладывают: \[____\]<br><br>\
3. Кого из сотрудников смены вы бы отметили? Полное имя, как на ID-карте; подписавший анкету себя не отмечает. ЦК объявит ему благодарность и начислит [QUESTIONNAIRE_COMMEND_REWARD] кр: \[____\]<br><br>\
Заполняет капитан, глава отдела или представитель NanoTrasen. Подпись (впишите %sign): \[____\]<br><br>\
<i>Заполните все поля ручкой, поставьте печать капитана, главы отдела или представителя NanoTrasen и отправьте анкету факсом в [GLOB.nt_fax_department] (раздел особых адресатов ЦК) до [STATION_TIME_TIMESTAMP("hh:mm", deadline)]. За своевременный ответ гражданский бюджет станции получит [QUESTIONNAIRE_REWARD] кр. Краткие итоги опроса выйдут в ленте новостей.</i>", advanced_html = TRUE)
	form.update_appearance()
	return form

/datum/centcom_questionnaire/proc/field_answer(obj/item/paper/form, field_index)
	for(var/datum/paper_field/field as anything in form.raw_field_input_data)
		if("[field.field_index]" != "[field_index]")
			continue
		var/answer = field.field_data?.raw_text
		return answer ? trim(answer) : ""
	return ""

/datum/centcom_questionnaire/proc/has_command_stamp(obj/item/paper/form)
	var/static/list/command_stamps = list("stamp-cap", "stamp-ce", "stamp-cmo", "stamp-com", "stamp-hop", "stamp-hos", "stamp-ntr", "stamp-qm", "stamp-rd")
	for(var/stamp_state in form.stamp_cache)
		if(stamp_state in command_stamps)
			return TRUE
	for(var/datum/paper_stamp/stamp as anything in form.raw_stamp_data)
		for(var/stamp_class in splittext(stamp.class, " "))
			if(stamp_class in command_stamps)
				return TRUE
	return FALSE

/// Что мешает принять анкету: пустые ответы, нет подписи, нет командной печати.
/datum/centcom_questionnaire/proc/missing_parts(obj/item/paper/form)
	. = list()
	var/list/empty_questions = list()
	var/signed = TRUE
	for(var/field_index in 0 to QUESTIONNAIRE_FIELD_SIGNATURE)
		if(length(field_answer(form, field_index)))
			continue
		if(field_index == QUESTIONNAIRE_FIELD_SIGNATURE)
			signed = FALSE
		else
			empty_questions += "[field_index + 1]"
	if(length(empty_questions) == 1)
		. += "нет ответа на вопрос [empty_questions[1]]"
	else if(length(empty_questions))
		. += "нет ответов на вопросы [english_list(empty_questions)]"
	if(!signed)
		. += "нет подписи"
	if(!has_command_stamp(form))
		. += "нет печати капитана, главы отдела или представителя NanoTrasen"

/datum/centcom_questionnaire/proc/receive(obj/item/paper/form, obj/machinery/fax/sender, mob/user)
	if(sender)
		home_fax_ref = WEAKREF(sender)
	if(rewarded)
		send_fax(make_letter("Re: Анкета КС-7", "Анкета о текущей смене уже принята. Повторная отправка не требуется, но мы ценим ваше рвение."))
		return FALSE
	var/list/missing = missing_parts(form)
	if(length(missing))
		send_fax(make_letter("Re: Анкета КС-7", "Анкета возвращена без рассмотрения: [english_list(missing)]. Ваша анкета приложена к письму: дополните её и отправьте снова.[resolved ? "" : " Срок ответа прежний."]"))
		send_fax(make_returned_copy(form))
		log_game("DIRECTOR: Central Command Questionnaire, [key_name(user)] прислал неполную анкету: [english_list(missing)].")
		return FALSE
	rewarded = TRUE
	var/commend_answer = field_answer(form, QUESTIONNAIRE_FIELD_COMMEND)
	var/mob/living/carbon/human/commended = find_crew_by_name(commend_answer)
	var/mob/living/carbon/human/signer = find_crew_by_name(field_answer(form, QUESTIONNAIRE_FIELD_SIGNATURE))
	var/commend_note
	if(!commended)
		commend_note = " Сотрудника «[html_encode(commend_answer)]» в списках смены не нашли, благодарность не отправлена."
	else if(commended == user || commended == signer)
		commend_note = " Самовыдвижение не рассматривается, благодарность не отправлена."
		commended = null
	else
		commend_note = " Благодарность объявлена сотруднику [commended.real_name], грамота прилагается."
	publish_results(form, user, commended)
	if(resolved)
		send_fax(make_letter("Re: Анкета КС-7", "Анкета получена после срока и приобщена к отчёту, итоги опроса опубликованы в ленте новостей. Премия за своевременный ответ в этот раз не начисляется.[commend_note]"))
		if(commended)
			commend(commended)
		log_game("DIRECTOR: Central Command Questionnaire, анкета от [key_name(user)] пришла после срока.")
		return FALSE
	resolved = TRUE
	if(deadline_timer)
		deltimer(deadline_timer)
		deadline_timer = null
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_CIV)
	budget?.adjust_money(QUESTIONNAIRE_REWARD, "ЦК: премия за анкету КС-7")
	send_fax(make_letter("Благодарность за анкету КС-7", "Отдел изучения удовлетворённости персонала благодарит командование станции за подробные ответы. Гражданскому бюджету начислено [QUESTIONNAIRE_REWARD] кр, итоги опроса опубликованы в ленте новостей.[commend_note] Ваше мнение очень важно для нас и уже подшито в папку."))
	if(commended)
		commend(commended)
	log_game("DIRECTOR: Central Command Questionnaire решена: анкету отправил [key_name(user)], гражданскому бюджету начислено [QUESTIONNAIRE_REWARD] кр.")
	return TRUE

/// Член экипажа по полному имени, а если имя неполное - единственный, в чьём имени оно встречается.
/datum/centcom_questionnaire/proc/find_crew_by_name(name_text)
	var/needle = lowertext(trim(name_text))
	if(length_char(needle) < QUESTIONNAIRE_NAME_MIN_PART)
		return null
	var/list/partial = list()
	for(var/mob/living/carbon/human/crew as anything in GLOB.human_list)
		if(!crew.real_name || !is_effective_crew_mob(crew))
			continue
		var/crew_name = lowertext(crew.real_name)
		if(crew_name == needle)
			return crew
		if(findtext(crew_name, needle))
			partial += crew
	return length(partial) == 1 ? partial[1] : null

/datum/centcom_questionnaire/proc/commend(mob/living/carbon/human/crew)
	var/datum/bank_account/account = paperwork_account_of(crew)
	if(!account)
		for(var/datum/bank_account/candidate as anything in SSeconomy.bank_accounts)
			if(candidate.account_holder == crew.real_name)
				account = candidate
				break
	account?.adjust_money(QUESTIONNAIRE_COMMEND_REWARD, "ЦК: благодарность по итогам анкеты КС-7")
	SEND_SIGNAL(crew, COMSIG_ADD_MOOD_EVENT, "centcom_commendation", /datum/mood_event/centcom_commendation)
	crew.playsound_local(get_turf(crew), 'sound/misc/notice2.ogg', 40, FALSE)
	to_chat(crew, span_nicegreen("Командование станции отметило вас в анкете ЦК. Центральное командование NanoTrasen объявляет вам благодарность[account ? " и начисляет на ваш счёт [QUESTIONNAIRE_COMMEND_REWARD] кр" : ""]. Грамота придёт на факс командования."))
	var/money_line = account ? " На счёт сотрудника начислено [QUESTIONNAIRE_COMMEND_REWARD] кр." : ""
	send_fax(make_letter("Благодарность: [crew.real_name]", "<center><b>БЛАГОДАРНОСТЬ</b></center><br>Центральное командование NanoTrasen объявляет благодарность сотруднику [crew.real_name] ([crew.mind?.assigned_role || "экипаж станции"]) за добросовестную работу, отмеченную командованием станции в анкете КС-7.[money_line]"))
	log_game("DIRECTOR: Central Command Questionnaire, благодарность ЦК объявлена [key_name(crew)], начислено [account ? QUESTIONNAIRE_COMMEND_REWARD : 0] кр.")

/// Ответы игроков в ленту новостей: обрезанные по длине поля и экранированные.
/datum/centcom_questionnaire/proc/publish_results(obj/item/paper/form, mob/user, mob/living/carbon/human/commended)
	var/rating = html_encode(copytext_char(field_answer(form, QUESTIONNAIRE_FIELD_RATING), 1, MAX_PAPER_INPUT_FIELD_LENGTH + 1))
	var/incident = html_encode(copytext_char(field_answer(form, QUESTIONNAIRE_FIELD_INCIDENT), 1, MAX_PAPER_INPUT_FIELD_LENGTH + 1))
	var/list/lines = list(
		"Командование станции ответило на анкету ЦК КС-7 «Как проходит смена?».",
		"Оценка смены: [rating].",
		"Самое необычное происшествие: [incident].",
	)
	if(commended)
		lines += "Благодарность ЦК объявлена сотруднику: [commended.real_name]."
	GLOB.news_network.SubmitArticle(jointext(lines, "<br>"), "Отдел изучения удовлетворённости ЦК", QUESTIONNAIRE_NEWS_CHANNEL, null)
	log_game("DIRECTOR: Central Command Questionnaire, итоги в ленте новостей по анкете от [key_name(user)]: оценка «[rating]», происшествие «[incident]»[commended ? ", отмечен [key_name(commended)]" : ""].")

/datum/centcom_questionnaire/proc/expire()
	deadline_timer = null
	if(resolved)
		return
	resolved = TRUE
	send_fax(make_letter("Напоминание: анкета КС-7", "Срок ответа на анкету КС-7 истёк. Взысканий не будет: мы понимаем, что смена бывает насыщенной. Если анкета всё же найдётся, пришлите её, мы приобщим её к отчёту."))
	log_game("DIRECTOR: Central Command Questionnaire истекла без ответа, отправлено напоминание.")

/datum/centcom_questionnaire/proc/make_letter(title, text)
	var/obj/item/paper/letter = new()
	letter.name = "paper - '[title]'"
	letter.add_raw_text("<center><b>ЦЕНТРАЛЬНОЕ КОМАНДОВАНИЕ NANOTRASEN</b><br>[GLOB.nt_fax_department]</center><br>[text]", advanced_html = TRUE)
	letter.update_appearance()
	return letter

/// Копия присланной анкеты с ответами и печатями: отправленный оригинал остаётся в ЦК.
/datum/centcom_questionnaire/proc/make_returned_copy(obj/item/paper/form)
	var/obj/item/paper/centcom_questionnaire/returned = form.copy(/obj/item/paper/centcom_questionnaire)
	returned.moveToNullspace()
	returned.survey = src
	returned.name = "paper - 'CentCom Questionnaire KS-7 (returned)'"
	for(var/stamp_index in 1 to LAZYLEN(form.raw_stamp_data))
		var/datum/paper_stamp/stamp = form.raw_stamp_data[stamp_index]
		returned.add_stamp(stamp.class, stamp.stamp_x, stamp.stamp_y, stamp.rotation, LAZYACCESS(form.stamp_cache, stamp_index))
	returned.update_appearance()
	return returned

/datum/centcom_questionnaire/proc/send_fax(obj/item/paper/letter)
	addtimer(CALLBACK(src, PROC_REF(deliver_fax), letter), QUESTIONNAIRE_REPLY_DELAY)

/datum/centcom_questionnaire/proc/deliver_fax(obj/item/paper/letter)
	var/obj/machinery/fax/target = home_fax_ref?.resolve()
	if(QDELETED(target) || !target.is_operational())
		target = find_station_command_fax()
	if(!target)
		qdel(letter)
		return
	target.receive(letter, GLOB.nt_fax_department, automated = TRUE)

/datum/mood_event/centcom_commendation
	description = "<span class='nicegreen'>Центральное командование объявило мне благодарность.</span>\n"
	mood_change = 4
	timeout = 15 MINUTES

/obj/item/paper/centcom_questionnaire
	name = "paper - 'CentCom Questionnaire KS-7'"
	var/datum/centcom_questionnaire/survey

/obj/item/paper/centcom_questionnaire/Destroy()
	survey = null
	return ..()

/obj/item/paper/centcom_questionnaire/examine(mob/user)
	. = ..()
	. += span_notice("Анкету заполняют ручкой, заверяют печатью капитана, главы отдела или представителя NanoTrasen и отправляют факсом в ЦК, раздел особых адресатов.")

/obj/item/paper/centcom_questionnaire/special_fax_auto_note(network_id)
	if(network_id == QUESTIONNAIRE_CENTCOM_ID && survey)
		return "анкета КС-7, обработано автоматически"
	return null

/obj/item/paper/centcom_questionnaire/on_special_fax(obj/machinery/fax/sender, network_id, mob/user)
	if(network_id == QUESTIONNAIRE_CENTCOM_ID)
		survey?.receive(src, sender, user)

#undef QUESTIONNAIRE_REWARD
#undef QUESTIONNAIRE_COMMEND_REWARD
#undef QUESTIONNAIRE_DEADLINE
#undef QUESTIONNAIRE_REPLY_DELAY
#undef QUESTIONNAIRE_CENTCOM_ID
#undef QUESTIONNAIRE_FIELD_RATING
#undef QUESTIONNAIRE_FIELD_INCIDENT
#undef QUESTIONNAIRE_FIELD_COMMEND
#undef QUESTIONNAIRE_FIELD_SIGNATURE
#undef QUESTIONNAIRE_NAME_MIN_PART
#undef QUESTIONNAIRE_NEWS_CHANNEL
