/datum/round_event_control/high_priority_bounty
	name = "High Priority Bounty"
	typepath = /datum/round_event/high_priority_bounty
	max_occurrences = 1
	weight = 50
	earliest_start = 10
	category = EVENT_CATEGORY_BUREAUCRATIC
	description = "Creates bounties that are three times original worth."

/datum/round_event/high_priority_bounty/announce(fake)
	priority_announce("Центральное командование выставило заявку с Наградой за Высокоприоритетный Груз. Подробности были отправлены на все Консоли Грантов.", "Программа Грантов Nanotrasen!")

/datum/round_event/high_priority_bounty/start()
	var/datum/bounty/B
	for(var/attempts = 0; attempts < 50; ++attempts)
		B = random_bounty()
		if(!B || istype(B, /datum/bounty/lewd))
			continue
		B.mark_high_priority(3)
		if(try_add_bounty(B))
			break

