/// Разовое пополнение антаг-кошельков директора (слой дохода поверх дефицит-капли):
/// раунд, где антагонисты выбыли или залегли, получает шанс на внеплановую инжекцию раньше
/// графика. Экипажу событие видно как перехват финансирования - мета-сигнал СБ "что-то готовится",
/// без указания, что именно и когда.
/datum/round_event_control/antag_funding
	name = "Shadow Funding"
	typepath = /datum/round_event/antag_funding
	weight = 8
	max_occurrences = 2
	earliest_start = 20 MINUTES
	min_players = 10
	severity = DIRECTOR_SEVERITY_FLAVOR
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "funding"
	disruption = DIRECTOR_DISRUPTION_AMBIENT // объявление-слух, играть никому не мешает
	description = "CentCom intercepts a shady money transfer: the director's antag wallets get a one-time grant."

/datum/round_event_control/antag_funding/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	if(!SSdirector.profile)
		return FALSE
	// Профиль без антаг-долей (некому копить) или без заметного дефицита нагрузки:
	// грант ушёл бы в стену гейта насыщения, а анонс наобещал бы угрозу, которой не будет.
	var/list/shares = SSdirector.profile.pool_shares
	if(((shares[DIRECTOR_SEVERITY_ANTAG] || 0) + (shares[DIRECTOR_SEVERITY_GHOST] || 0)) <= 0)
		return FALSE
	if(SSdirector.last_antag_deficit < 0.25)
		return FALSE
	return TRUE

/datum/round_event/antag_funding
	fakeable = FALSE

/datum/round_event/antag_funding/start()
	var/grant = rand(5, 8)
	SSdirector.feed_antag_pools(grant)
	log_game("DIRECTOR: событие Shadow Funding добавило [grant] очков в антаг-кошельки")
	minor_announce("Служба финансового мониторинга зафиксировала перевод крупной суммы \
		неустановленным группировкам в вашем секторе. Конечный получатель не отслеживается. \
		Службе безопасности рекомендовано повысить бдительность.", "Финансовый мониторинг Nanotrasen")
