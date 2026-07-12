/// Рефтрекер: поиск всех ссылок на датум по миру.
/// Компилируется всегда; тяжёлый запуск - только вручную (VV, R_DEBUG) или
/// через SSgarbage.reftrack_mode (авто-скан при GC-фейлах, см. garbage.dm).
/// Лог: data/logs/<раунд>/harddels.log через log_reftracker.

#define REFSEARCH_RECURSE_LIMIT 64

/// TRUE = активный скан должен прерваться при следующей проверке.
GLOBAL_VAR_INIT(reftracker_cancel, FALSE)
/// Не даёт двум тяжёлым сканам одновременно управлять SSgarbage и общим состоянием поиска.
GLOBAL_VAR_INIT(reftracker_active, FALSE)
/// Уникальная отрицательная метка обхода. Положительные значения оставлены прямым unit-тестам DoSearchVar.
GLOBAL_VAR_INIT(reftracker_scan_id, 0)
/// Сколько внешних ссылок осталось найти текущему сериализованному скану.
GLOBAL_VAR_INIT(reftracker_references_to_clear, INFINITY)
/// Сколько внешних ссылок скан искал изначально - для отчёта о недоборе в FinishSearch.
GLOBAL_VAR_INIT(reftracker_scan_requested, INFINITY)
/// Уже посчитанные физические ссылки текущего скана: повторный путь к тому же списку не должен съедать лимит.
GLOBAL_LIST_EMPTY(reftracker_found_identities)

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
	if(GLOB.reftracker_active)
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] не запущен: другой полный скан уже активен.")
		return
	// Флаг ставится до сна в tgui_alert, иначе второй админ успеет запустить параллельный скан.
	GLOB.reftracker_active = TRUE
	if(usr?.client && !skip_alert)
		if(tgui_alert(usr, "Полный скан заблокирует сервер на десятки секунд или минуты. Начать поиск?", "Find References", list("Да", "Нет")) != "Да")
			GLOB.reftracker_active = FALSE
			return
	GLOB.reftracker_cancel = FALSE
	var/garbage_was_enabled = SSgarbage.can_fire
	// Останавливаем GC, чтобы он не собрал цель посреди поиска.
	SSgarbage.can_fire = FALSE
	try
		_search_references(references_to_clear)
	catch(var/exception/error)
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] аварийно завершён: [error] ([error.file]:[error.line]).")
	// Этот cleanup обязан выполниться и после рантайма внутри произвольного vars/list.
	GLOB.reftracker_active = FALSE
	GLOB.reftracker_cancel = FALSE
	GLOB.reftracker_references_to_clear = INFINITY
	GLOB.reftracker_scan_requested = INFINITY
	GLOB.reftracker_found_identities.Cut()
	SSgarbage.can_fire = garbage_was_enabled
	if(garbage_was_enabled)
		SSgarbage.update_nextfire(reset_time = TRUE)

/datum/proc/_search_references(references_to_clear)
	GLOB.reftracker_references_to_clear = references_to_clear
	GLOB.reftracker_scan_requested = references_to_clear
	GLOB.reftracker_found_identities.Cut()
	log_reftracker("Начат поиск ссылок на [type] [text_ref(src)], ищем [references_to_clear == INFINITY ? "все" : references_to_clear].")
	GLOB.reftracker_scan_id--
	var/search_id = GLOB.reftracker_scan_id

	DoSearchVar(GLOB, "GLOB", search_id)
	log_reftracker("GLOB просканирован")
	if(SearchDone())
		return FinishSearch()

	//Yes we do actually need to do this. The searcher refuses to read weird lists
	//And global.vars is a really weird list
	var/list/global_vars = list()
	for(var/key in global.vars)
		global_vars[key] = global.vars[key]
	DoSearchVar(global_vars, "Native Global", search_id)
	log_reftracker("Нативные глобалы просканированы")
	if(SearchDone())
		return FinishSearch()

	var/list/skip_types = GLOB.reftracker_skip_typecache
	for(var/datum/thing in world) //atoms (don't beleive its lies)
		if(skip_types[thing.type])
			continue
		DoSearchVar(thing, "World -> [thing.type]", search_id)
		if(SearchDone())
			return FinishSearch()
	log_reftracker("Атомы просканированы")

	for(var/datum/thing) //datums
		if(skip_types[thing.type])
			continue
		DoSearchVar(thing, "Datums -> [thing.type]", search_id)
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
	return GLOB.reftracker_references_to_clear <= 0

/datum/proc/FinishSearch()
	if(GLOB.reftracker_cancel)
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] ОТМЕНЁН.")
	else if(GLOB.reftracker_scan_requested != INFINITY && GLOB.reftracker_references_to_clear > 0)
		// Полный обход мира закончился, а ожидаемые ссылки не нашлись: датумы,
		// списки, image-держатели и клиентские структуры уже исключены.
		var/found = GLOB.reftracker_scan_requested - GLOB.reftracker_references_to_clear
		log_reftracker("Поиск ссылок на [type] [text_ref(src)] завершён: найдено [found] из [GLOB.reftracker_scan_requested]. \
			Недостающие держатели вне датумов - как правило это VM-пины (локали и temp-слоты живых проков, \
			отпускают при смерти фрейма; refcount в момент фейла тоже мог быть завышен фреймом GC). \
			Устойчивый недобор при повторных сканах = реальный держатель во внутренностях BYOND.")
		if(ismob(src))
			var/mob/target_mob = src
			if(target_mob.pending_native_prompts > 0)
				log_reftracker("У [type] [text_ref(src)] висит [target_mob.pending_native_prompts] незакрытых нативных input()/alert() - \
					вероятный держатель: спящий фрейм промпта (BYOND хранит диалог до ответа даже после дисконнекта игрока).")
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
				MarkRefFound(varname, "Найден [type] [text_ref(src)] в [datum_container.type] [datum_container.ref_search_details()], вар [varname]. [container_name]", "[REF(datum_container)]|var|[varname]")
			else if(isimage(variable) && !isimage(src))
				var/image/attached = variable
				if(attached.loc == src)
					MarkRefFound(varname, "Найден [type] [text_ref(src)] как loc у image [text_ref(attached)] в [datum_container.type] [datum_container.ref_search_details()], вар [varname]. [container_name]", "image|[REF(attached)]")
			if(SearchDone())
				return

	else if(islist(potential_container))
		var/list/potential_cache = potential_container
		var/list_index = 0
		for(var/element_in_list in potential_cache)
			list_index++
			//Check normal sublists
			if(islist(element_in_list))
				if(length(element_in_list))
					DoSearchVar(element_in_list, "[container_name] -> (list)", search_time, recursion_count + 1)
			//Check normal entrys
			else if(element_in_list == src)
				MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] в списке [container_name].", "\ref[potential_cache]|entry|[list_index]")
			else if(isimage(element_in_list) && !isimage(src))
				var/image/attached_entry = element_in_list
				if(attached_entry.loc == src)
					MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] как loc у image [text_ref(attached_entry)] в списке [container_name].", "image|[REF(attached_entry)]")
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
						var/key_identity = isdatum(element_in_list) ? REF(element_in_list) : "[element_in_list]"
						MarkRefFound(potential_cache, "Найден [type] [text_ref(src)] в списке [container_name]\[[element_in_list]\]", "\ref[potential_cache]|assoc|[key_identity]")
				catch
					is_special_list = TRUE
					log_reftracker("Особый список: [container_name] бросил при доступе к [element_in_list]")
			if(SearchDone())
				return

/// Регистрирует найденную ссылку: лог + учёт раннего выхода + запись для тестов.
/datum/proc/MarkRefFound(found_key, message, reference_identity)
	#ifdef REFERENCE_TRACKING_DEBUG
	if(SSgarbage.should_save_refs)
		if(!found_refs)
			found_refs = list()
		found_refs[found_key] = TRUE
		return //End early, don't want these logging
	#endif
	if(reference_identity && GLOB.reftracker_found_identities[reference_identity])
		return
	if(reference_identity)
		GLOB.reftracker_found_identities[reference_identity] = TRUE
	log_reftracker(message)
	GLOB.reftracker_references_to_clear -= 1
	if(GLOB.reftracker_references_to_clear <= 0)
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
