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
