/// Происшествия сервиса: отсек ищется по группам типов, следующая группа - запасная.
/datum/round_event_control/station_incident/service
	weight = 15
	category = EVENT_CATEGORY_FRIENDLY
	severity = DIRECTOR_SEVERITY_MINOR
	public_locations_only = FALSE
	requires_air = TRUE
	var/list/area_groups = list()
	var/list/excluded_area_types = list(
		/area/service/kitchen/abandoned,
		/area/service/library/abandoned,
		/area/service/chapel/asteroid,
		/area/service/chapel/dock,
		/area/service/chapel/office,
		/area/service/chapel/storage,
	)

/datum/round_event_control/station_incident/service/valid_area(area/location)
	if(is_type_in_list(location, excluded_area_types))
		return FALSE
	for(var/list/group as anything in area_groups)
		if(is_type_in_list(location, group))
			return TRUE
	return FALSE

/// Свободные клетки пола в первом подходящем отсеке группы.
/datum/round_event_control/station_incident/service/proc/find_floors(list/area_types, first_only = FALSE)
	var/list/result = list()
	var/list/areas = first_only ? GLOB.sortedAreas : shuffle(GLOB.sortedAreas)
	for(var/area/location as anything in areas)
		if(!is_type_in_list(location, area_types) || !valid_area(location))
			continue
		for(var/turf/open/floor/floor in location)
			if(valid_target(floor))
				result += floor
				if(first_only)
					return result
			CHECK_TICK
		if(length(result))
			return result
	return result

/datum/round_event_control/station_incident/service/director_preflight()
	. = ..()
	director_preflight_failure = . ? null : "На станции нет подходящего отсека с пригодным воздухом."

/datum/round_event_control/station_incident/service/get_candidates(first_only = FALSE)
	for(var/list/group as anything in area_groups)
		var/list/found = find_floors(group, first_only)
		if(length(found))
			return found
	return list()

/datum/round_event/station_incident/service

/datum/round_event/station_incident/service/apply_effect(turf/target)
	return deliver_shipment(target)

/datum/round_event/station_incident/service/make_shipment()
	var/obj/structure/closet/supplypod/centcompod/pod = new()
	pod.effectQuiet = TRUE
	pod.delays = list(POD_TRANSIT = 8 SECONDS, POD_FALLING = 4, POD_OPENING = 2 SECONDS, POD_LEAVING = 2 SECONDS)
	pack_shipment(pod)
	return pod

/datum/round_event/station_incident/service/proc/pack_shipment(obj/structure/closet/supplypod/pod)
	return

/datum/round_event/station_incident/service/proc/announcement_title()
	var/datum/round_event_control/station_incident/incident = control
	return istype(incident) ? incident.announcement_title : "Станционная служба оповещения"

/// Живые сотрудники станции за клавиатурой, как их считает директор.
/proc/minor_service_effective_crew()
	. = 0
	for(var/mob/player as anything in GLOB.player_list)
		if(player.client && !player.client.is_afk() && is_effective_crew_mob(player))
			.++

/proc/minor_service_pay_budget(amount, reason)
	var/datum/bank_account/budget = SSeconomy.get_dep_account(ACCOUNT_SRV)
	return budget?.adjust_money(amount, reason)

/// Счёт карты в руках или на поясе, иначе личный счёт персонажа.
/proc/minor_service_account_of(mob/living/payee)
	if(!istype(payee))
		return null
	var/datum/bank_account/account = payee.get_bank_account()
	if(account)
		return account
	if(ishuman(payee))
		var/mob/living/carbon/human/human_payee = payee
		if(human_payee.account_id)
			return SSeconomy.bank_accounts_by_id["[human_payee.account_id]"]
	return null
