/// Блок лояльности дроида HK: разум хозяина, которому дроид подчиняется.
/datum/component/hk_loyalty
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/master_ref
	/// Типы командных ролей и фракции, которые дало порабощение: смена хозяина их снимает.
	var/list/granted_teams
	var/list/granted_factions
	/// Разум, которому достались granted_teams: мозг в шасси могли заменить.
	var/datum/weakref/granted_mind_ref

/datum/component/hk_loyalty/Initialize(datum/mind/master)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(master)
		master_ref = WEAKREF(master)

/datum/component/hk_loyalty/proc/get_master()
	return master_ref?.resolve()

/datum/component/hk_loyalty/proc/set_master(datum/mind/new_master)
	var/datum/mind/old_master = get_master()
	var/mob/living/droid = parent
	master_ref = new_master ? WEAKREF(new_master) : null
	SEND_SIGNAL(parent, COMSIG_HK_MASTER_CHANGED, new_master, old_master)
	var/enslaved = sync_allegiance()
	if(!new_master)
		to_chat(droid, span_boldnotice("Блок лояльности сброшен. Хозяина нет: вы никому не подчиняетесь."))
	else if(enslaved)
		to_chat(droid, span_boldwarning("Блок лояльности перезаписан, новый хозяин - [new_master.name]. Он антагонист: вы служите ему и его команде."))
	else
		to_chat(droid, span_boldnotice("Блок лояльности перезаписан, новый хозяин - [new_master.name]. Вы на стороне станции и не антагонист: не нападаете на экипаж и не вредите станции, даже если хозяин прикажет."))
	if(old_master && old_master != new_master && old_master.current)
		to_chat(old_master.current, span_warning("Сигнал блока лояльности [droid.real_name] потерян: дроид вам больше не подчиняется."))

/// Сторона дроида по хозяину: хозяин-антагонист порабощает разум, иначе прежнее порабощение снимается. TRUE - дроид порабощён.
/datum/component/hk_loyalty/proc/sync_allegiance()
	var/mob/living/droid = parent
	var/datum/mind/droid_mind = droid.mind
	var/datum/mind/granted_mind = granted_mind_ref?.resolve()
	var/datum/mind/master = get_master()
	var/mob/living/master_body = hk_master_is_antagonist(master) ? master.current : null
	if(!droid_mind || !istype(master_body) || master_body == droid || master_body.mind != master)
		master_body = null
	var/list/kept_teams = list()
	for(var/team_type in granted_teams)
		if(master_body && granted_mind == droid_mind && master.has_antag_datum(team_type))
			kept_teams += team_type
		else
			granted_mind?.remove_antag_datum(team_type)
	droid.faction -= granted_factions
	granted_factions = null
	granted_teams = kept_teams
	if(granted_mind && granted_mind != droid_mind)
		granted_mind.set_enslaved_to(null)
	granted_mind_ref = null
	if(!droid_mind)
		return FALSE
	droid_mind.set_enslaved_to(null)
	if(!master_body)
		return FALSE
	var/list/teams_before = hk_team_types(droid_mind)
	var/list/factions_before = droid.faction.Copy()
	droid_mind.enslave_mind_to_creator(master_body)
	granted_teams |= hk_team_types(droid_mind) - teams_before
	granted_factions = droid.faction - factions_before
	granted_mind_ref = WEAKREF(droid_mind)
	return TRUE

/// Командные роли, которые даёт enslave_mind_to_creator().
/proc/hk_team_types(datum/mind/droid_mind)
	. = list()
	for(var/team_type in list(/datum/antagonist/cult, /datum/antagonist/rev, /datum/antagonist/clockcult, /datum/antagonist/nukeop))
		if(droid_mind.has_antag_datum(team_type))
			. += team_type

/// Хозяин-антагонист забирает HK в свою команду; гостевые роли, ОБР, представители ЦК и похищенные антагонистами не считаются.
/proc/hk_master_is_antagonist(datum/mind/master)
	var/static/list/not_antagonists = typecacheof(list(/datum/antagonist/ghost_role, /datum/antagonist/ert, /datum/antagonist/official, /datum/antagonist/abductee))
	for(var/datum/antagonist/antag as anything in master?.antag_datums)
		if(!is_type_in_typecache(antag, not_antagonists))
			return TRUE
	return FALSE
