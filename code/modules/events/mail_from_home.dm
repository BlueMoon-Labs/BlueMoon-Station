/// Почта из дома (порт идеи Baystation "Mail From Home"): близкие экипажа передали
/// внеплановую партию личной корреспонденции. Использует штатную почтовую систему
/// SSmail, но паттерны берёт из тёплой категории FAMILY - подарки и письма от родни,
/// а не спам и счета. Чистый добрый флавор: очередь у почтомата и повод для отыгрыша.
/datum/round_event_control/mail_from_home
	name = "Mail From Home"
	typepath = /datum/round_event/mail_from_home
	weight = 15
	max_occurrences = 2
	earliest_start = 20 MINUTES
	min_players = 5
	alert_observers = FALSE
	category = EVENT_CATEGORY_FRIENDLY
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "An unscheduled batch of personal mail from crew families arrives at the mail storage."

/datum/round_event/mail_from_home
	announce_when = 1
	start_when = 3
	fakeable = FALSE

/datum/round_event/mail_from_home/announce(fake)
	priority_announce("На вашу станцию доставлена внеплановая партия личной корреспонденции: родные и близкие сотрудников передали письма и посылки. Получить их можно в отделе снабжения после сортировки.",
		"Почтовая служба сектора",
		sound = 'sound/misc/notice2.ogg')

/datum/round_event/mail_from_home/start()
	if(!istype(SSmail.main_storage))
		SSmail.create_main_storage()
	if(!istype(SSmail.main_storage))
		return kill()

	var/list/candidates = list()
	for(var/mob/living/carbon/human/crew_member in GLOB.player_list)
		if(crew_member.stat == DEAD || !crew_member.mind)
			continue
		if(!(crew_member.mind.assigned_role in get_all_jobs()))
			continue
		candidates += crew_member

	if(!length(candidates))
		return kill()

	var/mail_count = clamp(round(length(candidates) / 3), 2, 8)
	for(var/i in 1 to mail_count)
		var/mob/living/carbon/human/recipient = pick_n_take(candidates)
		if(!recipient)
			break
		if(SSmail.main_storage.contents.len >= SSmail.main_storage.storage_capacity)
			break
		// Семейная категория: письма от родни, а не реклама. Если для получателя
		// в ней ничего не нашлось (нулевые веса), падаем на общий выбор паттерна.
		var/list/family_weights = SSmail.regenerate_all_weights(recipient, MAIL_CATEGORY_FAMILY)
		var/datum/mail_pattern/chosen = length(family_weights) ? pickweight(family_weights) : null
		SSmail.create_mail_for_recipient(recipient, SSmail.main_storage, chosen)
		CHECK_TICK

	SSmail.main_storage.update_icon()
