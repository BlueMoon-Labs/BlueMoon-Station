/// Страховка шаттла (порт tgstation "Shuttle Insurance"): мутный, но легальный страховой
/// агент выходит на связь и предлагает застраховать эвакуационный шаттл за полцены его
/// стоимости. Решение принимается с консоли связи и оплачивается бюджетом карго.
/// Если позже случится Shuttle Catastrophe - страховка покроет ремонт (шаттл не заменят),
/// а ЦК ещё и премирует станцию за расчётливость. Пара к shuttle_catastrophe.dm.
/datum/round_event_control/shuttle_insurance
	name = "Shuttle Insurance"
	typepath = /datum/round_event/shuttle_insurance
	weight = 20
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 10
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "A sketchy but legit ship offers to insure the emergency shuttle for cargo money."

/datum/round_event_control/shuttle_insurance/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	if(!SSeconomy.get_dep_account(ACCOUNT_CAR))
		return FALSE // нечем платить
	if(SSshuttle.shuttle_insurance)
		return FALSE // уже застрахованы
	if(SSshuttle.shuttle_purchased == SHUTTLEPURCHASE_FORCED)
		return FALSE // страховать нечего
	if(istype(SSshuttle.emergency, /obj/docking_port/mobile/emergency/shuttle_build))
		return FALSE // рукодельный шаттл блокирует катастрофу - страховка бессмысленна
	if(EMERGENCY_AT_LEAST_DOCKED)
		return FALSE // катастрофа уже не случится
	return TRUE

/datum/round_event/shuttle_insurance
	fakeable = FALSE
	var/ship_name = "\"На Всякий Случай\""
	var/datum/comm_message/insurance_message
	var/insurance_evaluation = 0

/datum/round_event/shuttle_insurance/setup()
	ship_name = pick(strings(PIRATE_NAMES_FILE, "rogue_names"))
	for(var/shuttle_id in SSmapping.shuttle_templates)
		var/datum/map_template/shuttle/template = SSmapping.shuttle_templates[shuttle_id]
		if(template.name == SSshuttle.emergency.name)
			insurance_evaluation = template.credit_cost / 2
			break
	if(!insurance_evaluation)
		insurance_evaluation = 5000 // оценщик не нашёл шаттл в каталоге, ставка с потолка

/datum/round_event/shuttle_insurance/announce(fake)
	priority_announce("Входящая подпространственная передача данных. Открыт защищенный канал связи на всех коммуникационных консолях.", "Страховое предложение", SSstation.announcer.get_rand_report_sound(), has_important_message = TRUE)

/datum/round_event/shuttle_insurance/start()
	insurance_message = new("Страховка шаттла", "Приветствуем, дорогуша, это корабль [ship_name]. Не могли не заметить, что вы рассекаете сектор на роскошном эвакуационном шаттле БЕЗ СТРАХОВКИ! С ума сойти. А вдруг с ним что-то случится, а? Мы тут прикинули тарифы по вашему сектору и готовы застраховать ваш шаттл от любых катастроф всего за [insurance_evaluation] кредитов.", list("Оформить страховку.", "Отказаться."))
	insurance_message.answer_callback = CALLBACK(src, PROC_REF(answered))
	SScommunications.send_message(insurance_message, unique = TRUE)

/datum/round_event/shuttle_insurance/proc/answered()
	if(EMERGENCY_AT_LEAST_DOCKED)
		priority_announce("Друзья, страховать шаттл, который уже стоит в доке, немного поздновато. Наши агенты не работают на месте происшествия.", sender_override = ship_name)
		return
	if(insurance_message && insurance_message.answered == 1)
		var/datum/bank_account/station_balance = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(!station_balance?.adjust_money(-insurance_evaluation))
			priority_announce("Вы прислали недостаточно денег за страховку. На языке космических юристов это называется мошенничеством. Деньги мы, разумеется, оставим себе, мошенники!", sender_override = ship_name)
			return
		priority_announce("Благодарим за оформление страховки шаттла! Летайте спокойно.", sender_override = ship_name)
		SSshuttle.shuttle_insurance = TRUE
