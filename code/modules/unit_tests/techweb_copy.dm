/// Tests for /datum/techweb/proc/copy_research_to delta-sync behavior.
/// Every researched node re-applied by a sync pays SSeconomy.techweb_bounty into the science
/// budget (see research_node), so a repeat sync of an already up-to-date receiver must be a no-op:
/// no bounty payments, no state changes. Fabricators auto-sync on every node unlock, which made
/// the old full re-research loop both a CPU hotspot and a money printer.
/datum/unit_test/techweb_copy_delta/Run()
	var/datum/techweb/source = new
	var/datum/techweb/receiver = new
	allocated += source
	allocated += receiver

	// Research a few available nodes on the source (forced, no point cost)
	var/researched_extra = 0
	for(var/node_id in source.available_nodes.Copy())
		if(source.researched_nodes[node_id])
			continue
		source.research_node_id(node_id, TRUE, FALSE)
		researched_extra++
		if(researched_extra >= 3)
			break
	TEST_ASSERT(researched_extra >= 1, "Could not research any node on the source web, test cannot proceed")

	// First sync: receiver must get every researched node and design
	source.copy_research_to(receiver)
	for(var/node_id in source.researched_nodes)
		TEST_ASSERT(receiver.researched_nodes[node_id], "Receiver is missing node [node_id] after copy_research_to")
	for(var/design_id in source.researched_designs)
		TEST_ASSERT(receiver.researched_designs[design_id], "Receiver is missing design [design_id] after copy_research_to")

	var/list/nodes_snapshot = receiver.researched_nodes.Copy()
	var/list/designs_snapshot = receiver.researched_designs.Copy()
	var/list/hidden_snapshot = receiver.hidden_nodes.Copy()

	var/datum/bank_account/sci_budget = SSeconomy.get_dep_account(ACCOUNT_SCI)
	TEST_ASSERT_NOTNULL(sci_budget, "Science department account not found, bounty observable unavailable")
	var/balance_before = sci_budget.account_balance

	// Repeat sync with zero delta: must not re-research anything
	source.copy_research_to(receiver)

	TEST_ASSERT_EQUAL(sci_budget.account_balance, balance_before, \
		"Repeat copy_research_to re-researched already-synced nodes and paid techweb_bounty for each")
	TEST_ASSERT_EQUAL(length(receiver.researched_nodes), length(nodes_snapshot), "Repeat sync changed receiver researched_nodes")
	TEST_ASSERT_EQUAL(length(receiver.researched_designs), length(designs_snapshot), "Repeat sync changed receiver researched_designs")
	TEST_ASSERT_EQUAL(length(receiver.hidden_nodes), length(hidden_snapshot), "Repeat sync changed receiver hidden_nodes")

	// Delta sync: a node researched after the first sync must still reach the receiver
	var/new_node_id
	for(var/node_id in source.available_nodes.Copy())
		if(source.researched_nodes[node_id])
			continue
		new_node_id = node_id
		break
	if(!new_node_id)
		return // techweb too small to have a remaining frontier, delta part not testable
	source.research_node_id(new_node_id, TRUE, FALSE)
	source.copy_research_to(receiver)
	TEST_ASSERT(receiver.researched_nodes[new_node_id], "Delta sync did not deliver newly researched node [new_node_id] to the receiver")
	for(var/design_id in source.researched_designs)
		TEST_ASSERT(receiver.researched_designs[design_id], "Receiver is missing design [design_id] after delta sync")

/// Logs the cost of a repeat copy_research_to (the fabricator auto-sync path).
/// No assertions on timing, output is for before/after comparison in test logs.
/datum/unit_test/techweb_copy_bench
	priority = TEST_LONGER

/datum/unit_test/techweb_copy_bench/Run()
	var/datum/techweb/source = new
	var/datum/techweb/receiver = new
	allocated += source
	allocated += receiver

	// Unlock the tree in waves along the frontier to get a realistically sized web
	var/researched = 0
	for(var/wave in 1 to 10)
		var/progress = FALSE
		for(var/node_id in source.available_nodes.Copy())
			if(source.researched_nodes[node_id])
				continue
			source.research_node_id(node_id, TRUE, FALSE)
			researched++
			progress = TRUE
			if(researched >= 25)
				break
		if(!progress || researched >= 25)
			break

	source.copy_research_to(receiver)
	var/start = REALTIMEOFDAY
	for(var/i in 1 to 20)
		source.copy_research_to(receiver)
	var/elapsed_ds = REALTIMEOFDAY - start
	log_world("PERF: techweb copy_research_to repeat sync x20 with [researched] researched nodes: [elapsed_ds * 100]ms")

/// Первый update_research() свежей машины обязан построить полный кэш. Свежий
/// /datum/techweb исследует стартовые ноды прямо в New(), поэтому непустой снапшот
/// researched_designs не означает "кэш уже строился": инкрементальный путь на первом
/// синке оставлял cached_designs без базовых рецептов (кабели, обогреватель,
/// стёкла/пласталь, платы серверов) на всех протолатах и принтерах схем.
/datum/unit_test/production_initial_design_cache/Run()
	var/obj/machinery/rnd/production/protolathe/lathe = allocate(/obj/machinery/rnd/production/protolathe)
	// Initialize запускает асинхронный первый update_research() - даём ему завершиться.
	sleep(1 SECONDS)
	var/checked = 0
	for(var/design_id in lathe.stored_research.researched_designs)
		var/datum/design/known = SSresearch.techweb_design_by_id(design_id)
		if(!(known.build_type & lathe.allowed_buildtypes))
			continue
		if(!isnull(lathe.allowed_department_flags) && !(known.departmental_flags & lathe.allowed_department_flags))
			continue
		checked++
		TEST_ASSERT(lathe.cached_designs.Find(known), "после первого синка в кэше нет изученного дизайна [design_id]")
	TEST_ASSERT(checked >= 1, "ни один стартовый дизайн не прошёл фильтры протолата - тест ничего не проверил")

/// Инкрементальный синк дизайнов production-машины: волна исследований на проде гоняла
/// полный пересбор cached_designs (весь researched_designs через techweb_design_by_id,
/// ~75k вызовов за 18 секунд на 57 машин). После снапшота "что уже знали" доклеиваются
/// только новые дизайны, старые не теряются.
/datum/unit_test/production_incremental_design_sync/Run()
	var/obj/machinery/rnd/production/protolathe/lathe = allocate(/obj/machinery/rnd/production/protolathe)
	// Initialize запускает асинхронный первый update_research() - даём ему дойти,
	// затем забираем стейт стенда под контроль теста.
	sleep(1 SECONDS)
	lathe.allowed_department_flags = ALL
	lathe.stored_research.researched_designs = list()

	var/datum/design/first_design
	var/datum/design/second_design
	for(var/design_id in SSresearch.techweb_designs)
		var/datum/design/candidate = SSresearch.techweb_designs[design_id]
		// Кандидаты обязаны проходить оба фильтра update_designs (build_type + отдел),
		// иначе тест меряет фильтрацию, а не инкрементальность.
		if(!(candidate.build_type & lathe.allowed_buildtypes))
			continue
		if(!isnull(lathe.allowed_department_flags) && !(candidate.departmental_flags & lathe.allowed_department_flags))
			continue
		if(!first_design)
			first_design = candidate
			continue
		second_design = candidate
		break
	TEST_ASSERT_NOTNULL(second_design, "в реестре должны найтись два дизайна, проходящие фильтр протолата")

	lathe.stored_research.researched_designs[first_design.id] = TRUE
	lathe.update_designs()
	TEST_ASSERT(lathe.cached_designs.Find(first_design), "полный пересбор должен закэшировать изученный дизайн")
	TEST_ASSERT(!lathe.cached_designs.Find(second_design), "прекондиция: второй дизайн ещё не изучен")

	var/list/known_designs = lathe.stored_research.researched_designs.Copy()
	lathe.stored_research.researched_designs[second_design.id] = TRUE
	lathe.update_designs_incremental(known_designs)
	TEST_ASSERT(lathe.cached_designs.Find(second_design), "инкрементальный синк обязан доложить новый дизайн")
	TEST_ASSERT(lathe.cached_designs.Find(first_design), "инкрементальный синк не должен терять уже закэшированные дизайны")
