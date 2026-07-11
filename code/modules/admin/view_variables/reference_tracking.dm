/// Рефтрекер: поиск всех ссылок на датум по миру.
/// Компилируется всегда; тяжёлый запуск - только вручную (VV, R_DEBUG) или
/// через SSgarbage.reftrack_mode (авто-скан при GC-фейлах, см. garbage.dm).
/// Лог: data/logs/<раунд>/harddels.log через log_reftracker.

#define REFSEARCH_RECURSE_LIMIT 64

/// TRUE = активный скан должен прерваться при следующей проверке.
GLOBAL_VAR_INIT(reftracker_cancel, FALSE)

/// Типы, которые заведомо не держат чужих ссылок - пропускаются при полном скане.
GLOBAL_LIST_INIT(reftracker_skip_typecache, init_reftracker_skip_typecache())

/proc/init_reftracker_skip_typecache()
	. = list()
	for(var/base_type in list(
		/datum/qdel_item,
		/datum/weakref,
		/datum/gas_mixture,
		/datum/lighting_corner,
		/datum/chatmessage,
		/turf/open/space,
		/turf/open/openspace,
		/turf/closed/mineral,
	))
		for(var/type in typesof(base_type))
			.[type] = TRUE

/// Ищет и логирует все ссылки на src. references_to_clear ограничивает поиск
/// известным числом внешних держателей (из refcount) - нашли все, вышли рано.
/datum/proc/find_references(references_to_clear = INFINITY, skip_alert = FALSE)
	if(usr?.client && !skip_alert)
		if(tgui_alert(usr, "Полный скан заблокирует сервер на десятки секунд или минуты. Начать поиск?", "Find References", list("Да", "Нет")) != "Да")
			return
	GLOB.reftracker_cancel = FALSE
	running_find_references = type
	// Останавливаем GC, чтобы он не собрал цель посреди поиска.
	SSgarbage.can_fire = FALSE
	_search_references(references_to_clear)
	running_find_references = null
	SSgarbage.can_fire = TRUE
	SSgarbage.update_nextfire(reset_time = TRUE)

/datum/proc/_search_references(references_to_clear)
	src.references_to_clear = references_to_clear
	log_reftracker("Начат поиск ссылок на [type] [text_ref(src)], ищем [references_to_clear == INFINITY ? "все" : references_to_clear].")
	var/starting_time = world.time

	DoSearchVar(GLOB, "GLOB", starting_time)
	log_reftracker("GLOB просканирован")
	if(SearchDone())
		return FinishSearch()

	//Yes we do actually need to do this. The searcher refuses to read weird lists
	//And global.vars is a really weird list
	var/list/global_vars = list()
	for(var/key in global.vars)
		global_vars[key] = global.vars[key]
	DoSearchVar(global_vars, "Native Global", starting_time)
	log_reftracker("Нативные глобалы просканированы")
	if(SearchDone())
		return FinishSearch()

	var/list/skip_types = GLOB.reftracker_skip_typecache
	for(var/datum/thing in world) //atoms (don't beleive its lies)
		if(skip_types[thing.type])
			continue
		DoSearchVar(thing, "World -> [thing.type]", starting_time)
		if(SearchDone())
			return FinishSearch()
	log_reftracker("Атомы просканированы")

	for(var/datum/thing) //datums
		if(skip_types[thing.type])
			continue
		DoSearchVar(thing, "Datums -> [thing.type]", starting_time)
		if(SearchDone())
			return FinishSearch()
	log_reftracker("Датумы просканированы")

	// Клиентские структуры (images/screen/eye) обычному скану не видны - явный проб.
	log_reftracker("Проверка клиентских структур ([length(GLOB.clients)] клиентов)...")
	find_client_references(src)

	FinishSearch()

/// TRUE, когда скан пора прекращать: все ссылки найдены или запрошена отмена.
/// В тестовом режиме (should_save_refs) ранний выход по счётчику отключён.
/datum/proc/SearchDone()
	if(GLOB.reftracker_cancel)
		return TRUE
	#ifdef REFERENCE_TRACKING_DEBUG
	if(SSgarbage.should_save_refs)
		return FALSE
	#endif
	return references_to_clear <= 0

/datum/proc/FinishSearch()
	if(GLOB.reftracker_cancel)
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] ОТМЕНЁН.")
	else
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] завершён.")
	GLOB.reftracker_cancel = FALSE

/datum/proc/DoSearchVar(potential_container, container_name, search_time, recursion_count = 0, is_special_list = FALSE)
	#ifdef REFERENCE_TRACKING_DEBUG
	if(SSgarbage.should_save_refs && !found_refs)
		found_refs = list()
	#endif
	if(recursion_count >= REFSEARCH_RECURSE_LIMIT)
		log_reftracker("Достигнут лимит рекурсии. [container_name]")
		return
	if(SearchDone())
		return

	//Check each time you go down a layer. This makes it a bit slow, but it won't effect the rest of the game at all
	CHECK_TICK

	if(isdatum(potential_container))
		var/datum/datum_container = potential_container
		if(datum_container.last_find_references == search_time)
			return
		datum_container.last_find_references = search_time
		var/list/vars_list = datum_container.vars
		var/is_atom = isatom(datum_container)
		var/is_area = is_atom && isarea(datum_container)
		for(var/varname in vars_list)
			var/variable = vars_list[varname]
			if(islist(variable))
				//Fun fact, vis_locs don't count for references
				if(varname == "vars" || (is_atom && (varname == "vis_locs" || varname == "overlays" || varname == "underlays" || varname == "filters" || varname == "verbs" || (is_area && varname == "contents"))))
					continue
				// We do this after the varname check to avoid area contents (reading it incures a world loop's worth of cost)
				if(!length(variable))
					continue
				DoSearchVar(variable, \
					"[container_name] [datum_container.ref_search_details()] -> [varname] (list)", \
					search_time, \
					recursion_count + 1, \
					/*is_special_list = */ is_atom && (varname == "contents" || varname == "vis_contents" || varname == "locs"))
			else if(variable == src)
				MarkRefFound(varname, "Найден [type] [text_ref(src)] в [datum_container.type] [datum_container.ref_search_details()], вар [varname]. [container_name]")
			else if(isimage(variable) && !isimage(src))
				var/image/attached = variable
				if(attached.loc == src)
					MarkRefFound(varname, "Найден [type] [text_ref(src)] как loc у image [text_ref(attached)] в [datum_container.type] [datum_container.ref_search_details()], вар [varname]. [container_name]")
			if(SearchDone())
				return

	else if(islist(potential_container))
		var/list/potential_cache = potential_container
		for(var/element_in_list in potential_cache)
			//Check normal sublists
			if(islist(element_in_list))
				if(length(element_in_list))
					DoSearchVar(element_in_list, "[container_name] -> (list)", search_time, recursion_count + 1)
			//Check normal entrys
			else if(element_in_list == src)
				MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] в списке [container_name].")
			else if(isimage(element_in_list) && !isimage(src))
				var/image/attached_entry = element_in_list
				if(attached_entry.loc == src)
					MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] как loc у image [text_ref(attached_entry)] в списке [container_name].")
			if(SearchDone())
				return
			//Check assoc entrys
			if(!isnum(element_in_list) && !is_special_list)
				// This exists to catch an error that throws when we access a special list
				// is_special_list is a hint, it can be wrong
				try
					var/assoc_val = potential_cache[element_in_list]
					//Check assoc sublists
					if(islist(assoc_val))
						if(length(assoc_val))
							DoSearchVar(assoc_val, "[container_name]\[[element_in_list]\] -> (list)", search_time, recursion_count + 1)
					else if(assoc_val == src)
						MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] в списке [container_name]\[[element_in_list]\]")
				catch
					is_special_list = TRUE
					log_reftracker("Особый список: [container_name] бросил при доступе к [element_in_list]")
			if(SearchDone())
				return

/// Регистрирует найденную ссылку: лог + учёт раннего выхода + запись для тестов.
/datum/proc/MarkRefFound(found_key, message)
	#ifdef REFERENCE_TRACKING_DEBUG
	if(SSgarbage.should_save_refs)
		if(!found_refs)
			found_refs = list()
		found_refs[found_key] = TRUE
		return //End early, don't want these logging
	#endif
	log_reftracker(message)
	references_to_clear -= 1
	if(references_to_clear <= 0)
		log_reftracker("Все ссылки на [type] [text_ref(src)] найдены, выходим.")

/// Контекст датума в логах рефтрекера.
/datum/proc/ref_search_details()
	return text_ref(src)

/datum/callback/ref_search_details()
	return "[text_ref(src)] (obj: [object] proc: [delegate] user: [user ? "[user]" : "null"])"

/// Прервать активный поиск ссылок (следующая проверка внутри скана его остановит).
/client/proc/cancel_reference_search()
	set category = "Debug.1) Logs"
	set name = "Cancel Reference Search"
	if(!check_rights(R_DEBUG))
		return
	GLOB.reftracker_cancel = TRUE
	to_chat(src, span_notice("Активный поиск ссылок будет прерван."), confidential = TRUE)

/proc/qdel_and_find_ref_if_fail(datum/thing_to_del, force = FALSE)
	thing_to_del.qdel_and_find_ref_if_fail(force)

/datum/proc/qdel_and_find_ref_if_fail(force = FALSE)
	SSgarbage.reference_find_on_fail[REF(src)] = TRUE
	qdel(src, force)

#undef REFSEARCH_RECURSE_LIMIT
