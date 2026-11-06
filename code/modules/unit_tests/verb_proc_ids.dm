/// Каждый верб должен получить id проца не больше MAX_VERB_PROC_ID, иначе клиент молча его не вызовет (см. verb_id_order.dm)
/datum/unit_test/verb_proc_ids

/datum/unit_test/verb_proc_ids/Run()
	TEST_ASSERT(isnum(verb_proc_id(/mob/verb/say_verb)), "verb_proc_id не читает id проца из ref")
	TEST_ASSERT_NULL(verb_proc_id(/datum), "verb_proc_id принял тип за проц")

	var/max_id = scan_verb_proc_ids()
	TEST_ASSERT(max_id >= verb_proc_id(/mob/verb/say_verb), "Обход таблицы процов не дошёл до say_verb")

	// Процы-вербы раздаются списками: админские, гостовые, менторские
	for(var/global_name in GLOB.vars)
		if(!findtext(global_name, "verbs"))
			continue
		var/list/candidates = GLOB.vars[global_name]
		if(islist(candidates))
			check_verb_proc_ids(candidates)

	var/list/offenders = list()
	for(var/verb_path in GLOB.uncallable_verbs)
		offenders += "[verb_path] ([GLOB.uncallable_verbs[verb_path]])"
	TEST_ASSERT(!length(offenders), "Вербы с id проца больше [MAX_VERB_PROC_ID], клиент их не вызовет - объявите корень их типа в verb_id_order.dm до /datum: [jointext(offenders, ", ")]")
	TEST_ASSERT(max_id < MAX_VERB_PROC_ID - 5000, "Запас id для вербов кончается: самый большой [max_id] из [MAX_VERB_PROC_ID]")
