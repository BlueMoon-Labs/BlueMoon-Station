#define VARS_BLACKLIST list("_active_timers", "_datum_components", "_listen_lookup", "_signal_procs", "datum_flags", "abstract_type", "tgui_shared_states", "gc_destroyed", "open_tguis", "_status_traits", "trigger_uid", "status_traits", "cooldowns", "filter_data", "harddel_deets_dumped", "tag", "type", "parent_type", "vars")
GLOBAL_LIST_INIT(vars_blacklist_cache)

/proc/start_with(text, start_text)
	if(copytext(text, 1, length(start_text)) == start_text)
		return TRUE
	return FALSE

//Наверное есть способ оптимальнее для проверки...
/proc/check_vars_blacklist(var_name)
	for(var/temp as anything in VARS_BLACKLIST)
		if(temp == var_name) return FALSE
	for(var/temp as anything in GLOB.vars_blacklist_cache)
		if(temp == var_name) return FALSE
	if(start_with(var_name, "_"))
		GLOB.vars_blacklist_cache += var_name
		return FALSE

	return TRUE

/datum/component/vore_controller
	var/list/new_belly/my_bellies


/datum/component/vore_controller/Initialize(...)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/vore_controller/proc/load_belly(list/belly_raw_data)

/datum/component/vore_controller/proc/load_bellies()


/datum/component/vore_controller/proc/get_belly_data(obj/new_belly/belly_to_save)
	var/list/temp = alist()
	for(var/var_name as anything in belly_to_save.vars)

/datum/component/vore_controller/proc/save_bellies()

