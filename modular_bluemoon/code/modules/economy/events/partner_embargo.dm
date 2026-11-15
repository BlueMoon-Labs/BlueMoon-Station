/// Эмбарго партнёра: открытый партнёр, кроме НТ Логистики и контрабандного, на время не покупает и не продаёт.
/datum/round_event_control/partner_embargo
	name = "Partner Embargo"
	typepath = /datum/round_event/partner_embargo
	weight = 12
	max_occurrences = 2
	earliest_start = 30 MINUTES
	min_players = 5
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	econ_state_weights = list(ECON_STATE_RICH = 2)
	description = "A trade partner stops buying from and selling to the station for a while."

/datum/round_event_control/partner_embargo/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	return !!length(econ_embargo_candidates())

/proc/econ_embargo_candidates()
	. = list()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(id != PARTNER_UNIVERSAL_ID && partner.unlocked && !partner.contraband && !partner.embargoed())
			. += partner

/datum/round_event/partner_embargo
	fakeable = FALSE

/datum/round_event/partner_embargo/start()
	var/list/candidates = econ_embargo_candidates()
	if(!length(candidates))
		return
	var/datum/trade_partner/partner = pick(candidates)
	var/minutes = SSeconomy.settings.event_embargo_minutes
	partner.embargo_until = world.time + minutes MINUTES
	log_econ("Эмбарго партнёра [partner.name] ([partner.id]) на [minutes] мин.")
	SSmarket.post_news("[partner.name] объявляет станции эмбарго на [minutes] мин.: не покупает её груз и не продаёт ей паки. Снабжение на это время работает через других партнёров. Новых спецзаказов от него не будет, уже взятые можно выполнить.")
