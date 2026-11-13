/**
  * handles adding verbs and updating the stat panel browser
  *
  * pass the verb type path to this instead of adding it directly to verbs so the statpanel can update
  * Arguments:
  * * target - Who the verb is being added to, client or mob typepath
  * * verb - typepath to a verb, or a list of verbs, supports lists of lists
  */
/proc/add_verb(client/target, verb_or_list_to_add)
	if(!target)
		CRASH("add_verb called without a target")
	if(IsAdminAdvancedProcCall())
		return
	var/mob/mob_target = null

	if(ismob(target))
		mob_target = target
		target = mob_target.client
	else if(!istype(target, /client))
		CRASH("add_verb called on a non-mob and non-client")
	var/list/verbs_list = list()
	if(!islist(verb_or_list_to_add))
		verbs_list += verb_or_list_to_add
	else
		var/list/verb_listref = verb_or_list_to_add
		var/list/elements_to_process = verb_listref.Copy()
		while(length(elements_to_process))
			var/element_or_list = elements_to_process[length(elements_to_process)] //Last element
			elements_to_process.len--
			if(islist(element_or_list))
				elements_to_process += element_or_list //list/a += list/b adds the contents of b into a, not the reference to the list itself
			else
				verbs_list += element_or_list

	check_verb_proc_ids(verbs_list)
	if(mob_target)
		mob_target.verbs += verbs_list
		if(!target)
			return //Our work is done.
	else
		target.verbs += verbs_list

	var/list/output_list = list()
	for(var/thing in verbs_list)
		var/procpath/verb_to_add = thing
		output_list[++output_list.len] = list(verb_to_add.category, verb_to_add.name)
	output_list = url_encode(json_encode(output_list))

	target << output("[output_list];", "statbrowser:add_verb_list")

/**
  * handles removing verb and sending it to browser to update, use this for removing verbs
  *
  * pass the verb type path to this instead of removing it from verbs so the statpanel can update
  * Arguments:
  * * target - Who the verb is being removed from, client or mob typepath
  * * verb - typepath to a verb, or a list of verbs, supports lists of lists
  */
/proc/remove_verb(client/target, verb_or_list_to_remove)
	if(IsAdminAdvancedProcCall())
		return

	var/mob/mob_target = null
	if(ismob(target))
		mob_target = target
		target = mob_target.client
	else if(!istype(target, /client))
		CRASH("remove_verb called on a non-mob and non-client")

	var/list/verbs_list = list()
	if(!islist(verb_or_list_to_remove))
		verbs_list += verb_or_list_to_remove
	else
		var/list/verb_listref = verb_or_list_to_remove
		var/list/elements_to_process = verb_listref.Copy()
		while(length(elements_to_process))
			var/element_or_list = elements_to_process[length(elements_to_process)] //Last element
			elements_to_process.len--
			if(islist(element_or_list))
				elements_to_process += element_or_list //list/a += list/b adds the contents of b into a, not the reference to the list itself
			else
				verbs_list += element_or_list

	if(mob_target)
		mob_target.verbs -= verbs_list
		if(!target)
			return //Our work is done.
	else
		target.verbs -= verbs_list

	var/list/output_list = list()
	for(var/thing in verbs_list)
		var/procpath/verb_to_remove = thing
		output_list[++output_list.len] = list(verb_to_remove.category, verb_to_remove.name)
	output_list = url_encode(json_encode(output_list))

	target << output("[output_list];", "statbrowser:remove_verb_list")

/// Вербы, которые клиент не вызовет: путь -> id проца
GLOBAL_LIST_EMPTY(uncallable_verbs)
/// Самый большой id объявленного верба, по scan_verb_proc_ids() при старте мира
GLOBAL_VAR_INIT(max_verb_proc_id, 0)

/proc/report_uncallable_verb(verb_path, id)
	if(GLOB.uncallable_verbs[verb_path])
		return
	GLOB.uncallable_verbs[verb_path] = id
	stack_trace("Верб [verb_path] получил id проца [id] при пределе [MAX_VERB_PROC_ID]: клиент его не вызовет. Корень его типа надо объявить в verb_id_order.dm раньше /datum.")
	message_admins("Верб [verb_path] не вызывается игроками: id проца [id] больше [MAX_VERB_PROC_ID]. Подробности в runtime.log.")

/// Сверяет вербы, которые выдаются игроку: сюда попадают и процы-вербы (админские, possess), которых нет среди объявленных
/proc/check_verb_proc_ids(list/verbs_to_check)
	var/static/list/checked = list()
	for(var/verb_path in verbs_to_check)
		if(checked[verb_path])
			continue
		checked[verb_path] = TRUE
		var/id = verb_proc_id(verb_path)
		if(id > MAX_VERB_PROC_ID)
			report_uncallable_verb(verb_path, id)

/// Обходит всю таблицу процов мира и сверяет с пределом объявленные вербы и их оверрайды. Возвращает самый большой id верба.
/proc/scan_verb_proc_ids()
	var/list/declarers_by_name = list()
	var/list/override_ids = list()
	var/list/override_paths = list()
	var/list/found = list()
	var/max_id = 0
	var/misses = 0
	for(var/id = 0, misses < 1000, id++)
		var/procpath = locate("\[0x26[num2text(id, 6, 16)]\]")
		if(isnull(procpath))
			misses++
			continue
		misses = 0
		var/path_text = "[procpath]"
		var/verb_at = findtext(path_text, "/verb/")
		if(verb_at)
			max_id = max(max_id, id)
			if(id > MAX_VERB_PROC_ID)
				found[procpath] = id
			var/verb_name = copytext(path_text, verb_at + 6)
			var/list/declarers = declarers_by_name[verb_name]
			if(!declarers)
				declarers = list()
				declarers_by_name[verb_name] = declarers
			declarers += text2path(copytext(path_text, 1, verb_at))
		else if(!findtext(path_text, "/proc/"))
			override_ids[path_text] = id
			override_paths[path_text] = procpath
	// Оверрайд верба (/mob/living/say_verb()) - тоже верб со своим id
	for(var/override_text in override_ids)
		var/name_at = findlasttext(override_text, "/")
		var/list/declarers = declarers_by_name[copytext(override_text, name_at + 1)]
		if(!declarers)
			continue
		var/override_type = text2path(copytext(override_text, 1, name_at))
		for(var/declarer in declarers)
			if(!ispath(override_type, declarer))
				continue
			var/id = override_ids[override_text]
			max_id = max(max_id, id)
			if(id > MAX_VERB_PROC_ID)
				found[override_paths[override_text]] = id
			break
	if(length(found))
		var/list/sample = list()
		for(var/verb_path in found)
			GLOB.uncallable_verbs[verb_path] = found[verb_path]
			if(length(sample) < 10)
				sample += "[verb_path] ([found[verb_path]])"
		stack_trace("[length(found)] вербов получили id проца больше [MAX_VERB_PROC_ID] и не вызываются клиентом: [jointext(sample, ", ")]. Корни их типов надо объявить в verb_id_order.dm раньше /datum.")
		message_admins("[length(found)] вербов не вызываются игроками: таблица процов переполнена. Подробности в runtime.log.")
	return max_id
