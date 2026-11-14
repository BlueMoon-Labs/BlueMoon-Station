/// Гуманитарная поставка NT бедной станции: бесплатный ящик базовых припасов капсулой в отсек снабжения.
/datum/round_event_control/nt_aid_shipment
	name = "NT Aid Shipment"
	typepath = /datum/round_event/nt_aid_shipment
	weight = 8
	weight_can_change = TRUE
	max_occurrences = 2
	earliest_start = 20 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_BUREAUCRATIC
	family = "economy"
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	econ_state_weights = list(ECON_STATE_NORMAL = 0, ECON_STATE_RICH = 0)
	description = "Only for a poor station: a free crate of basic supplies drops into the cargo bay."

/datum/round_event_control/nt_aid_shipment/director_preflight()
	if(SSeconomy.economy_state != ECON_STATE_POOR)
		director_preflight_failure = "Станция не бедна."
	else if(!econ_aid_pack())
		director_preflight_failure = "Нет пака поставки."
	else if(!econ_aid_landing_turf())
		director_preflight_failure = "Нет свободного пола в помещениях снабжения станции."
	else
		director_preflight_failure = null
	director_preflight_detail = director_preflight_failure || "Станция бедна, есть пак и место посадки."
	return !director_preflight_failure

/datum/round_event_control/nt_aid_shipment/execute_action()
	if(!director_preflight())
		return FALSE
	return ..()

/datum/round_event/nt_aid_shipment
	fakeable = FALSE
	var/datum/weakref/pod_ref

/datum/round_event/nt_aid_shipment/start()
	var/datum/supply_pack/pack = econ_aid_pack()
	var/turf/landing = econ_aid_landing_turf()
	var/reason
	if(triggered_randomly && SSeconomy.economy_state != ECON_STATE_POOR)
		reason = "станция больше не бедна"
	else if(!pack || !landing)
		reason = pack ? "нет свободного пола в помещениях снабжения станции" : "нет пака поставки"
	if(reason)
		log_game("EVENT: NT Aid Shipment не отправлен: [reason]")
		if(!triggered_randomly)
			message_admins("NT Aid Shipment не отправлен: [reason].")
		if(control)
			control.occurrences = max(control.occurrences - 1, 0)
		return
	var/obj/structure/closet/supplypod/centcompod/pod = new
	var/obj/structure/closet/crate/crate = pack.generate(pod)
	econ_mark_imported(crate)
	crate.econ_imported = TRUE
	pod_ref = WEAKREF(pod)
	new /obj/effect/pod_landingzone(landing, pod)
	priority_announce("Нанотрейзен направляет станции гуманитарную поставку: [pack.name]. Капсула приземлится в отсеке снабжения, платить за неё не нужно. Помощь не для перепродажи: NT выкупает её как купленное, контракты и спецзаказы её не засчитывают.", "Отдел снабжения NT")
	log_game("EVENT: NT Aid Shipment отправил [pack.name] в [AREACOORD(landing)]")

/proc/econ_aid_pack()
	var/static/list/aid_packs = list(
		/datum/supply_pack/emergency/medemergencylite,
		/datum/supply_pack/emergency/mre,
		/datum/supply_pack/emergency/internals,
	)
	var/list/available = list()
	for(var/pack_type in aid_packs)
		if(SSshuttle.supply_packs[pack_type])
			available += SSshuttle.supply_packs[pack_type]
	return length(available) ? pick(available) : null

/// Свободный пол отсека снабжения; без него - любого помещения снабжения на станции, затем стоянки шаттла снабжения.
/proc/econ_aid_landing_turf()
	var/area/cargo_bay = GLOB.areas_by_type[/area/cargo/storage]
	var/list/free = econ_free_station_floors(cargo_bay?.contents)
	if(length(free))
		return pick(free)
	for(var/area/cargo/cargo_area in GLOB.sortedAreas)
		free += econ_free_station_floors(cargo_area.contents)
	if(length(free))
		return pick(free)
	var/obj/docking_port/stationary/supply_dock = SSshuttle.getDock("supply_home")
	free = econ_free_station_floors(supply_dock?.return_turfs())
	return length(free) ? pick(free) : null

/proc/econ_free_station_floors(list/turfs)
	. = list()
	for(var/turf/open/floor/floor in turfs)
		if(is_station_level(floor.z) && !floor.is_blocked_turf())
			. += floor
