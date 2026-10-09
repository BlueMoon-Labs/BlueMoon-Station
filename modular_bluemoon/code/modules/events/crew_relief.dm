#define CREW_RELIEF_MIN_MEMBERS 2
#define CREW_RELIEF_MAX_MEMBERS 3

/// Роли помощи экипажу: директор присылает из призраков отряд ЦК в опустевший отдел.
/datum/round_event_control/crew_relief
	category = EVENT_CATEGORY_FRIENDLY
	severity = DIRECTOR_SEVERITY_FLAVOR
	family = "crew_relief"
	weight = 40
	min_players = 20
	earliest_start = 20 MINUTES
	max_occurrences = 2
	director_ghost_jobban = ROLE_DEATHSQUAD
	director_ghost_minimum = CREW_RELIEF_MIN_MEMBERS
	/// Отдел, нехватку которого закрывает отряд (DIRECTOR_DEPT_*)
	var/relief_department
	/// Отряд нужен, когда в отделе активных сотрудников не больше этого числа
	var/relief_staff_max = 0
	/// Доля погибших в манифесте, открывающая отряд при любом штате; 0 - не учитывать
	var/relief_dead_fraction = 0
	/// Последний присланный отряд
	var/list/datum/weakref/relief_team = list()

/datum/round_event_control/crew_relief/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	if(signals.evac_state != DIRECTOR_EVAC_NONE || relief_team_alive())
		return FALSE
	if(relief_dead_fraction && signals.dead_fraction >= relief_dead_fraction)
		return TRUE
	return (signals.staffing[relief_department] || 0) <= relief_staff_max

/datum/round_event_control/crew_relief/get_weight(datum/director_signals/signals)
	return weight * (SSdirector.profile ? SSdirector.profile.crew_relief_weight_mult : 1)

/datum/round_event_control/crew_relief/proc/note_relief_team(list/mob/members)
	relief_team = list()
	for(var/mob/member as anything in members)
		relief_team += WEAKREF(member)

/datum/round_event_control/crew_relief/proc/relief_team_alive()
	for(var/datum/weakref/member_ref as anything in relief_team)
		var/mob/member = member_ref.resolve()
		if(member && member.stat != DEAD)
			return TRUE
	return FALSE

/datum/round_event_control/crew_relief/repair
	name = "Emergency Repair Crew"
	typepath = /datum/round_event/ghost_role/crew_relief/repair
	description = "Ремонтная бригада ЦК из призраков, когда на станции не больше одного инженера."
	relief_department = DIRECTOR_DEPT_ENGINEERING
	relief_staff_max = 1

/datum/round_event_control/crew_relief/medical
	name = "Medical Relief Team"
	typepath = /datum/round_event/ghost_role/crew_relief/medical
	description = "Санитарная бригада ЦК из призраков, когда медотдел пуст или погибло больше 15% экипажа."
	relief_department = DIRECTOR_DEPT_MEDICAL
	relief_staff_max = 0
	relief_dead_fraction = 0.15

/datum/round_event/ghost_role/crew_relief
	minimum_required = CREW_RELIEF_MIN_MEMBERS
	/// Шаблон ОБР, по которому собирается отряд
	var/datum/ert/ert_template
	/// Задача отряда: миссия команды и брифинг каждому бойцу
	var/mission = ""
	var/announce_title = ""
	var/announce_text = ""

/datum/round_event/ghost_role/crew_relief/spawn_role()
	if(!length(GLOB.emergencyresponseteamspawn))
		return MAP_ERROR
	var/list/mob/candidates = get_candidates(ROLE_DEATHSQUAD)
	if(length(candidates) < minimum_required)
		return NOT_ENOUGH_PLAYERS
	var/datum/ert/template = new ert_template
	template.mission = mission
	template.enforce_human = CONFIG_GET(flag/enforce_human_authority)
	var/list/mob/living/carbon/human/members = template.spawn_members(candidates, CREW_RELIEF_MAX_MEMBERS)
	if(!length(members))
		return NOT_ENOUGH_PLAYERS
	for(var/mob/living/carbon/human/member as anything in members)
		prepare_member(member)
	spawned_mobs += members
	var/datum/round_event_control/crew_relief/relief_control = control
	if(istype(relief_control))
		relief_control.note_relief_team(members)
	return SUCCESSFUL_SPAWN

/datum/round_event/ghost_role/crew_relief/proc/prepare_member(mob/living/carbon/human/member)
	ADD_TRAIT(member, TRAIT_NO_MIDROUND_ANTAG, GHOSTROLE_TRAIT)
	to_chat(member, span_boldnotice("Вы - отряд помощи экипажу, а не боевое ОБР. [mission]"))

/datum/round_event/ghost_role/crew_relief/announce(fake)
	priority_announce("Внимание, [station_name()]. [announce_text]", announce_title, initial(ert_template.ertphrase))

/datum/round_event/ghost_role/crew_relief/repair
	role_name = "Ремонтная бригада ЦК"
	ert_template = /datum/ert/engineer_ert
	mission = "Задача: устранить пробоины и разгерметизацию, восстановить питание и атмосферу, починить повреждённое. Вы подчиняетесь капитану станции в разумных пределах."
	announce_title = "Ремонтная бригада ЦК"
	announce_text = "На станции почти не осталось инженерного персонала. Центральное Командование направляет ремонтную бригаду для устранения повреждений. Окажите ей содействие."

/datum/round_event/ghost_role/crew_relief/medical
	role_name = "Санитарная бригада ЦК"
	ert_template = /datum/ert/hsc
	mission = "Задача: стабилизировать раненых, доставить пострадавших и тела в медотдел, вернуть к жизни всех, кого возможно. Вы подчиняетесь капитану станции в разумных пределах."
	announce_title = "Санитарная бригада ЦК"
	announce_text = "Медицинский отдел станции не справляется с потоком пострадавших. Центральное Командование направляет санитарную бригаду. Обеспечьте ей доступ в медотдел."

#undef CREW_RELIEF_MIN_MEMBERS
#undef CREW_RELIEF_MAX_MEMBERS
