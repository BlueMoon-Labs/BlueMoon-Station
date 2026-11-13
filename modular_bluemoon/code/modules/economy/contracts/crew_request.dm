/// Объявление экипажа: заказчик кладёт награду в депозит, исполнитель получает её, когда заказчик примет работу.
/datum/econ_contract/crew_request
	var/datum/bank_account/poster
	/// Исполнитель сдал работу и ждёт решения заказчика
	var/reported = FALSE
	/// Депозит уже выплачен или возвращён
	var/settled = FALSE
	/// Номер сдачи: таймер автоприёмки старой сдачи не срабатывает на новую
	var/report_count = 0
	/// Отложенная строка по общему каналу
	var/announce_timer
	/// Кто дал объявление: мут IC перепроверяется перед строкой по радио
	var/datum/weakref/poster_mob_ref

/datum/econ_contract/crew_request/New(datum/bank_account/poster, title, desc, reward)
	..(null)
	src.poster = poster
	src.title = title
	src.desc = desc
	src.reward = reward
	RegisterSignal(poster, COMSIG_PARENT_QDELETING, PROC_REF(on_poster_deleted))
	SSeconomy.loose_contracts += src
	set_deadline(world.time + ECON_CREW_REQUEST_TIME)

/datum/econ_contract/crew_request/Destroy()
	refund()
	if(poster)
		UnregisterSignal(poster, COMSIG_PARENT_QDELETING)
		poster = null
	return ..()

/datum/econ_contract/crew_request/proc/on_poster_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/econ_contract/crew_request/proc/refund()
	if(settled)
		return
	settled = TRUE
	if(poster && SSeconomy.move(SSeconomy.escrow_account, poster, reward, ECON_REFUND, null, "Объявление снято: [title]"))
		poster.bank_card_talk("Объявление \"[title]\" снято, [reward] кр. депозита вернулись на счёт.")

/datum/econ_contract/crew_request/kind()
	return "crew"

/datum/econ_contract/crew_request/payout()
	return reward

/datum/econ_contract/crew_request/performer_share()
	return 100

/datum/econ_contract/crew_request/rotation_due_at()
	return null

/datum/econ_contract/crew_request/has_progress()
	return reported

/datum/econ_contract/crew_request/take_refusal(datum/bank_account/account)
	if(account && account == poster)
		return "Своё объявление не берут."
	return ..()

/datum/econ_contract/crew_request/take(datum/bank_account/account)
	. = ..()
	if(!.)
		return
	if(deadline < world.time + ECON_CONTRACT_TAKEN_TIME)
		set_deadline(world.time + ECON_CONTRACT_TAKEN_TIME)
	poster.bank_card_talk("Объявление \"[title]\" взял [account.account_holder].")

/datum/econ_contract/crew_request/taken_text()
	return "Объявление \"[title]\" закреплено за вами. Сделав работу, отметьте её сданной: заказчик [poster.account_holder] примет её, и [reward] кр. придут вам целиком."

/// Отказ исполнителя: объявление снова свободно и остаётся на доске до своего срока.
/datum/econ_contract/crew_request/after_drop()
	reported = FALSE
	poster.bank_card_talk("Исполнитель отказался от объявления \"[title]\", оно снова свободно.")

/datum/econ_contract/crew_request/expire()
	if(completed || QDELETED(src) || !is_expired())
		return
	if(reported && taker)
		complete()
		return
	if(taker)
		taker.bank_card_talk("Срок объявления \"[title]\" истёк, оно снято.")
	qdel(src)

/datum/econ_contract/crew_request/complete(mob/performer)
	if(completed || !taker)
		return
	completed = TRUE
	settled = TRUE
	SSeconomy.move(SSeconomy.escrow_account, taker, reward, ECON_CREW_REQUEST, performer, "Объявление: [title]")
	taker.bank_card_talk("Работа по объявлению \"[title]\" принята: [reward] кр. на счёте.", balloon = "объявление +[reward] кр")
	taker.contract_done(rep_value())
	poster.bank_card_talk("Работа по объявлению \"[title]\" принята, [reward] кр. ушли исполнителю [taker.account_holder].")
	log_econ("Объявление #[uid] \"[title]\" от [poster.account_holder] ([poster.account_id]) выполнено: [reward] кр. исполнителю [taker.account_holder] ([taker.account_id])")
	qdel(src)

/// Исполнитель сдаёт работу: заказчик принимает или отклоняет её, а промолчит ECON_CREW_REQUEST_ACCEPT_TIME - работа принята.
/datum/econ_contract/crew_request/proc/report(datum/bank_account/account)
	if(completed || account != taker)
		return list(FALSE, "Это не ваше объявление.")
	if(reported)
		return list(FALSE, "Работа уже сдана и ждёт решения заказчика.")
	reported = TRUE
	report_count++
	addtimer(CALLBACK(src, PROC_REF(accept_unanswered), report_count), ECON_CREW_REQUEST_ACCEPT_TIME)
	poster.bank_card_talk("[taker.account_holder] сдал работу по объявлению \"[title]\". Примите или отклоните её на доске контрактов: через [DisplayTimeText(ECON_CREW_REQUEST_ACCEPT_TIME)] она будет принята сама.")
	return list(TRUE, "Работа сдана. Заказчик [poster.account_holder] примет или отклонит её, а промолчит [DisplayTimeText(ECON_CREW_REQUEST_ACCEPT_TIME)] - награда ваша.")

/datum/econ_contract/crew_request/proc/accept_unanswered(report_number)
	if(completed || QDELETED(src) || !reported || report_number != report_count)
		return
	complete()

/datum/econ_contract/crew_request/proc/accept(datum/bank_account/account)
	if(completed || account != poster)
		return list(FALSE, "Это не ваше объявление.")
	if(!taker)
		return list(FALSE, "Объявление ещё никто не взял.")
	var/performer_name = taker.account_holder
	complete()
	return list(TRUE, "Работа принята, [reward] кр. ушли исполнителю [performer_name].")

/// Заказчик отклоняет сданную работу: исполнитель снят без штрафа, объявление снова свободно.
/datum/econ_contract/crew_request/proc/reject(datum/bank_account/account)
	if(completed || account != poster)
		return list(FALSE, "Это не ваше объявление.")
	if(!reported || !taker)
		return list(FALSE, "Отклонить можно только сданную работу.")
	taker.bank_card_talk("Заказчик [poster.account_holder] отклонил работу по объявлению \"[title]\". Объявление снова свободно.")
	log_econ("Объявление #[uid] \"[title]\": [poster.account_holder] ([poster.account_id]) отклонил работу [taker.account_holder] ([taker.account_id])")
	release_taker()
	reported = FALSE
	return list(TRUE, "Работа отклонена, объявление снова свободно.")

/datum/econ_contract/crew_request/proc/cancel(datum/bank_account/account)
	if(completed || account != poster)
		return list(FALSE, "Это не ваше объявление.")
	if(taker)
		return list(FALSE, "Объявление уже взято: примите работу или дождитесь срока.")
	var/refunded = reward
	log_econ("Объявление #[uid] \"[title]\" снято заказчиком [poster.account_holder] ([poster.account_id])")
	qdel(src)
	return list(TRUE, "Объявление снято, [refunded] кр. депозита вернулись на счёт.")

/datum/econ_contract/crew_request/ui_entry()
	. = ..()
	.["department_name"] = "Экипаж"
	.["poster"] = poster?.account_holder
	.["poster_id"] = poster?.account_id
	.["reported"] = reported

/datum/controller/subsystem/economy/proc/crew_requests_of(datum/bank_account/account)
	. = list()
	for(var/datum/econ_contract/crew_request/request in loose_contracts)
		if(request.poster == account)
			. += request

/// Текст объявления от игрока: без разметки и управляющих символов, не длиннее max_length. null - текст не годится.
/proc/econ_crew_request_text(text, max_length)
	if(!istext(text))
		return null
	text = trim(text)
	if(!length(text) || length_char(text) > max_length)
		return null
	return reject_bad_text(text, max_length, ascii_only = FALSE)

/// Размещает объявление экипажа со счёта account. Возвращает list(размещено ли, ответ игроку).
/proc/econ_post_crew_request(mob/user, datum/bank_account/account, title, desc, reward)
	var/datum/economy_settings/settings = SSeconomy.settings
	if(econ_ic_muted(user))
		return list(FALSE, "Вам запрещено говорить в IC, поэтому давать объявления нельзя.")
	if(!account || account.offstation || !(account in SSeconomy.bank_accounts))
		return list(FALSE, "Объявления размещают со счетов экипажа станции.")
	if(length(SSeconomy.crew_requests_of(account)) >= ECON_CREW_REQUESTS_PER_POSTER)
		return list(FALSE, "У вас уже висит объявлений: [ECON_CREW_REQUESTS_PER_POSTER]. Снимите одно или дождитесь исполнения.")
	title = econ_crew_request_text(title, ECON_CREW_REQUEST_TITLE_MAX)
	desc = econ_crew_request_text(desc, ECON_CREW_REQUEST_DESC_MAX)
	if(!title || !desc)
		return list(FALSE, "Нужны заголовок до [ECON_CREW_REQUEST_TITLE_MAX] и описание до [ECON_CREW_REQUEST_DESC_MAX] символов, без знаков <, >, / и \\.")
	if(CHAT_FILTER_CHECK(title) || CHAT_FILTER_CHECK(desc))
		return list(FALSE, "В тексте объявления есть запрещённые слова.")
	if(istext(reward))
		reward = text2num(reward)
	if(!isnum(reward))
		return list(FALSE, "Укажите награду числом.")
	reward = round(reward)
	if(reward < settings.crew_request_min || reward > settings.crew_request_max)
		return list(FALSE, "Награда объявления - от [settings.crew_request_min] до [settings.crew_request_max] кр.")
	if(!SSeconomy.move(account, SSeconomy.escrow_account, reward, ECON_CREW_REQUEST, user, "Депозит объявления: [title]"))
		return list(FALSE, "На счёте не хватает [reward] кр. для депозита объявления.")
	var/datum/econ_contract/crew_request/request = new(account, title, desc, reward)
	log_econ("[key_name(user)] разместил объявление #[request.uid] \"[title]\" за [reward] кр.: [desc]")
	log_game("[key_name(user)] разместил объявление экипажа \"[title]\" за [reward] кр.: [desc]")
	request.poster_mob_ref = WEAKREF(user)
	return list(TRUE, "Объявление \"[title]\" размещено на [DisplayTimeText(ECON_CREW_REQUEST_TIME)], [reward] кр. ушли в депозит до расчёта.[request.schedule_announce()]")

/// IC-мут: такой игрок не даёт объявлений, которые потом звучат по радио.
/proc/econ_ic_muted(mob/user)
	if(!user)
		return FALSE
	var/client/user_client = GET_CLIENT(user)
	return !!(user_client?.prefs?.muted & MUTE_IC)

/datum/controller/subsystem/economy
	COOLDOWN_DECLARE(crew_request_announce_cooldown)

/datum/bank_account
	COOLDOWN_DECLARE(crew_request_announce_cooldown)

/// Откладывает строку по общему каналу на ECON_CREW_REQUEST_ANNOUNCE_DELAY. Возвращает пояснение для заказчика.
/datum/econ_contract/crew_request/proc/schedule_announce()
	if(!COOLDOWN_FINISHED(poster, crew_request_announce_cooldown))
		return " По общему каналу о нём не скажут: ваши объявления звучат там не чаще раза в [SSeconomy.settings.crew_request_personal_announce_minutes] мин."
	announce_timer = addtimer(CALLBACK(src, PROC_REF(announce)), ECON_CREW_REQUEST_ANNOUNCE_DELAY, TIMER_STOPPABLE)
	return " Если за [DisplayTimeText(ECON_CREW_REQUEST_ANNOUNCE_DELAY)] его никто не возьмёт, о нём коротко скажет общий канал, когда тот не занят другим объявлением."

/// Строка по общему каналу без имени заказчика: объявление ещё свободно, заказчик не в муте, канал и личный кулдаун заказчика свободны. TRUE, если прозвучала.
/datum/econ_contract/crew_request/proc/announce()
	announce_timer = null
	if(QDELETED(src) || completed || taker || !poster || econ_ic_muted(poster_mob_ref?.resolve()))
		return FALSE
	if(!COOLDOWN_FINISHED(SSeconomy, crew_request_announce_cooldown) || !COOLDOWN_FINISHED(poster, crew_request_announce_cooldown))
		return FALSE
	if(!paperwork_radio("Доска объявлений экипажа: «[title]», награда [reward] кр. Взять - в Кошельке на КПК, вкладка «Подработка», или на доске контрактов.", RADIO_CHANNEL_COMMON))
		return FALSE
	COOLDOWN_START(SSeconomy, crew_request_announce_cooldown, SSeconomy.settings.crew_request_announce_minutes MINUTES)
	COOLDOWN_START(poster, crew_request_announce_cooldown, SSeconomy.settings.crew_request_personal_announce_minutes MINUTES)
	return TRUE

/// Действие action над объявлением uid от счёта account. Возвращает list(удалось ли, ответ игроку).
/proc/econ_crew_request_act(datum/bank_account/account, action, uid)
	var/datum/econ_contract/crew_request/request = econ_contract_uid(uid)
	if(!istype(request) || !account)
		return list(FALSE, "Объявление уже снято с доски.")
	switch(action)
		if("crew_report")
			return request.report(account)
		if("crew_accept")
			return request.accept(account)
		if("crew_reject")
			return request.reject(account)
		if("crew_cancel")
			return request.cancel(account)
	return list(FALSE, "Неизвестное действие.")
