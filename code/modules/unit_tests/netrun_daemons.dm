/// A new program with an existing effect needs no factory or console switch.
/datum/netrun_program/daemon/unit_test_buffer
	id = "unit-test-buffer"
	name = "test-buffer.exe"
	size = 4
	bonus_kind = "buffer"
	bonus = 2
	loot_weight = 0

/datum/unit_test/netrun_daemon_registry/Run()
	var/datum/netrun_program/daemon/definition = SSnetrun.get_daemon("buffer")
	TEST_ASSERT_NOTNULL(definition, "The buffer daemon is not registered")
	TEST_ASSERT_EQUAL(SSnetrun.get_daemon(" BUFFER "), definition, "Daemon IDs are not normalized")
	TEST_ASSERT_NULL(SSnetrun.get_daemon("missing-daemon"), "An unknown ID resolved to a real program")
	TEST_ASSERT_NULL(netrun_daemon_file("missing-daemon"), "The factory created an unknown program")
	var/datum/netrun_file/file = netrun_daemon_file("buffer")
	TEST_ASSERT_EQUAL(file.content, "buffer", "The factory changed the existing file ID")
	TEST_ASSERT_EQUAL(file.size, 2, "The factory changed the existing file capacity cost")
	qdel(file)
	TEST_ASSERT(!QDELETED(definition), "A file incorrectly owns its shared daemon definition")
	var/obj/item/netrun_shard/buffer/buffer_shard = allocate(/obj/item/netrun_shard/buffer)
	var/obj/item/netrun_shard/icepick/icepick_shard = allocate(/obj/item/netrun_shard/icepick)
	var/obj/item/netrun_shard/cloak/cloak_shard = allocate(/obj/item/netrun_shard/cloak)
	for(var/obj/item/netrun_shard/shard in list(buffer_shard, icepick_shard, cloak_shard))
		TEST_ASSERT_EQUAL(length(shard.file_store.files), 1, "An individually printable daemon shard contains an unintended suite")
		TEST_ASSERT(netrun_storage_used(shard.file_store.files) <= shard.file_store.capacity, "A printed program exceeds its shard capacity")
	var/list/definitions = SSnetrun.daemon_definitions()
	var/found_extension = FALSE
	for(var/list/entry as anything in definitions)
		if(entry["id"] == "unit-test-buffer")
			found_extension = TRUE
	TEST_ASSERT(found_extension, "Help metadata ignored a newly added daemon subtype")

/datum/unit_test/netrun_daemon_capacity_and_effects/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.inventory.local_store.capacity = 4
	TEST_ASSERT(console.store_file(netrun_daemon_file("buffer")), "A daemon did not fit within available memory")
	TEST_ASSERT(console.store_file(netrun_daemon_file("buffer")), "A second copy did not fit exactly in memory")
	TEST_ASSERT_EQUAL(console.daemon_bonus("buffer"), 1, "Duplicate programs stacked their buffer effect")
	var/datum/netrun_file/excess = netrun_daemon_file("buffer")
	TEST_ASSERT(!console.store_file(excess), "A daemon bypassed memory capacity")
	qdel(excess)
	var/obj/item/netrun_shard/shard = allocate(/obj/item/netrun_shard)
	console.inventory.shard = shard
	shard.file_store.files += netrun_daemon_file("unit-test-buffer")
	TEST_ASSERT_EQUAL(console.daemon_bonus("buffer"), 2, "An analogous program's stronger effect was ignored or summed")
	shard.file_store.files += netrun_daemon_file("cloak")
	TEST_ASSERT(abs(console.effective_trace_mult() - 0.7) < 0.001, "The registry changed the existing cloak trace reduction")
	TEST_ASSERT_EQUAL(console.daemon_bonus("missing-effect"), 0, "An unknown effect received an unrelated daemon bonus")

/// No initial IDs: fixtures explicitly register these implementations for one test.
/datum/netrun_daemon_effect/unit_test_override
	capabilities = list("unit-test-capability")
	var/applications = 0
	var/last_strength
	var/datum/netrun_program/daemon/last_source

/datum/netrun_daemon_effect/unit_test_override/apply(datum/netrun_daemon_context/context, strength, datum/netrun_program/daemon/source)
	..()
	applications++
	last_strength = strength
	last_source = source
	if(!isnull(context.trace_factor))
		context.trace_factor *= 1 - strength / 10
	if(!isnull(context.disengage_grace))
		context.disengage_grace += strength * (1 SECONDS)

/datum/netrun_program/daemon/unit_test_override
	loot_weight = 0
	var/custom_strength = 2

/datum/netrun_program/daemon/unit_test_override/collect_effects(list/strongest, list/sources)
	..()
	collect_effect("unit-test-effect", custom_strength, strongest, sources)

/// Teardown also restores registry membership after an assertion returns early.
/datum/netrun_daemon_registry_test_fixture
	var/list/registry
	var/id
	var/datum/definition
	var/datum/previous_definition

/datum/netrun_daemon_registry_test_fixture/New(list/source_registry, entry_id, datum/entry)
	registry = source_registry
	id = entry_id
	definition = entry
	previous_definition = registry[id]
	registry[id] = definition

/datum/netrun_daemon_registry_test_fixture/Destroy()
	if(registry[id] == definition)
		if(previous_definition)
			registry[id] = previous_definition
		else
			registry -= id
	registry = null
	definition = null
	previous_definition = null
	return ..()

/// A daemon can compose an unknown effect implemented by its own polymorphic object.
/datum/unit_test/netrun_daemon_effect_polymorphism/Run()
	SSnetrun.get_daemon_effect(null)
	SSnetrun.get_daemon(null)
	var/datum/netrun_daemon_effect/unit_test_override/effect = allocate(/datum/netrun_daemon_effect/unit_test_override)
	effect.id = "unit-test-effect"
	allocate(/datum/netrun_daemon_registry_test_fixture, SSnetrun.daemon_effects, effect.id, effect)
	var/datum/netrun_program/daemon/unit_test_override/program = allocate(/datum/netrun_program/daemon/unit_test_override)
	program.id = "unit-test-daemon-override"
	program.effects = list("buffer" = 1)
	allocate(/datum/netrun_daemon_registry_test_fixture, SSnetrun.daemons, program.id, program)
	TEST_ASSERT_EQUAL(SSnetrun.get_daemon_effect(" UNIT-TEST-EFFECT "), effect, "The shared effect registry resolves and normalizes an independent implementation")
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	TEST_ASSERT(console.store_file(netrun_daemon_file(program.id)), "An overridden daemon is an ordinary real executable")
	TEST_ASSERT(console.store_file(netrun_daemon_file(program.id)), "A duplicate retains its actual storage cost")
	var/datum/netrun_daemon_context/context = allocate(/datum/netrun_daemon_context)
	context.trace_factor = 1
	context.disengage_grace = 10 SECONDS
	context.breach_buffer = 3
	context.capability = "unit-test-capability"
	effect.applications = 0
	TEST_ASSERT_EQUAL(console.apply_daemon_effects(context), context, "Daemon execution updates the caller-owned operation context")
	TEST_ASSERT_EQUAL(effect.applications, 1, "Duplicate executables invoke their strongest effect once")
	TEST_ASSERT_EQUAL(effect.last_strength, program.custom_strength, "The program's collect override supplies the custom strength")
	TEST_ASSERT_EQUAL(effect.last_source, program, "The handler receives the winning executable definition")
	TEST_ASSERT(abs(context.trace_factor - 0.8) < 0.001, "An unknown effect applies its own trace calculation without a central branch")
	TEST_ASSERT_EQUAL(context.disengage_grace, 12 SECONDS, "The same effect supplies another independent gameplay modifier")
	TEST_ASSERT_EQUAL(context.breach_buffer, 4, "Overridden collection still composes the ordinary inherited effects")
	TEST_ASSERT(context.capability_granted, "The new effect grants its own requested capability")
	TEST_ASSERT(console.daemon_capability("unit-test-capability"), "The native capability query invokes the new effect")
	TEST_ASSERT(!console.daemon_capability("missing-test-capability"), "A custom effect cannot grant unrelated capabilities")
	TEST_ASSERT_EQUAL(program.custom_strength, 2, "Operation execution leaves the shared program's strength unchanged")

/// Composite and custom sources compete by maximum, with live revocation through a borrowed disk.
/datum/unit_test/netrun_daemon_effect_borrowed_revocation/Run()
	SSnetrun.get_daemon_effect(null)
	SSnetrun.get_daemon(null)
	var/datum/netrun_daemon_effect/unit_test_override/effect = allocate(/datum/netrun_daemon_effect/unit_test_override)
	effect.id = "unit-test-effect"
	allocate(/datum/netrun_daemon_registry_test_fixture, SSnetrun.daemon_effects, effect.id, effect)
	var/datum/netrun_program/daemon/unit_test_override/local_program = allocate(/datum/netrun_program/daemon/unit_test_override)
	local_program.id = "unit-test-daemon-local"
	allocate(/datum/netrun_daemon_registry_test_fixture, SSnetrun.daemons, local_program.id, local_program)
	var/datum/netrun_program/daemon/composite = allocate(/datum/netrun_program/daemon)
	composite.id = "unit-test-daemon-composite"
	composite.effects = list("unit-test-effect" = 4, "buffer" = 1)
	allocate(/datum/netrun_daemon_registry_test_fixture, SSnetrun.daemons, composite.id, composite)
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/physical = allocate(/datum/netrun_console, host)
	var/datum/netrun_console/borrower = allocate(/datum/netrun_console, allocate(/obj/item))
	var/datum/netrun_file/first = netrun_daemon_file(local_program.id)
	var/datum/netrun_file/second = netrun_daemon_file(local_program.id)
	TEST_ASSERT(physical.store_file(first) && physical.store_file(second), "Both local executable copies fit in actual memory")
	var/obj/item/netrun_shard/shard = allocate(/obj/item/netrun_shard)
	shard.forceMove(host)
	physical.inventory.set_shard(shard)
	TEST_ASSERT(physical.store_file(netrun_daemon_file(composite.id), TRUE), "The stronger composite resides on an actual removable disk")
	TEST_ASSERT(borrower.inventory.borrow_from(physical.inventory), "A second session borrows the real source inventory")
	var/datum/netrun_daemon_context/context = allocate(/datum/netrun_daemon_context)
	context.trace_factor = 1
	context.disengage_grace = 10 SECONDS
	context.breach_buffer = 3
	context.capability = "unit-test-capability"
	effect.applications = 0
	borrower.apply_daemon_effects(context)
	TEST_ASSERT_EQUAL(effect.applications, 1, "Local duplicates and a composite apply the winning effect only once")
	TEST_ASSERT_EQUAL(effect.last_strength, 4, "A stronger composite wins without adding local copies")
	TEST_ASSERT_EQUAL(effect.last_source, composite, "The effect receives the actual strongest source")
	TEST_ASSERT(abs(context.trace_factor - 0.6) < 0.001, "The borrowed composite uses its own stronger modifier")
	TEST_ASSERT_EQUAL(context.disengage_grace, 14 SECONDS, "Independent context values use the same maximum strength")
	TEST_ASSERT_EQUAL(context.breach_buffer, 4, "The composite's unrelated effect also reaches the borrower")
	TEST_ASSERT(context.capability_granted, "The borrowed executable grants its requested capability")
	borrower.ui_files = borrower.all_files(TRUE)
	borrower.ui_bonuses = list("unit-test-effect" = 99)
	shard.forceMove(run_loc_floor_bottom_left)
	var/datum/netrun_daemon_context/detached = allocate(/datum/netrun_daemon_context)
	detached.trace_factor = 1
	detached.disengage_grace = 10 SECONDS
	detached.breach_buffer = 3
	borrower.apply_daemon_effects(detached)
	TEST_ASSERT_EQUAL(effect.last_source, local_program, "Removing the physical disk immediately falls back to the remaining real source")
	TEST_ASSERT(abs(detached.trace_factor - 0.8) < 0.001, "Borrowed execution cannot retain a detached stronger modifier")
	TEST_ASSERT_EQUAL(detached.disengage_grace, 12 SECONDS, "Detached source modifiers are revoked together")
	TEST_ASSERT_EQUAL(detached.breach_buffer, 3, "The composite's exclusive effect is also revoked")
	TEST_ASSERT(physical.delete_local_file(first) && physical.delete_local_file(second), "The actual remaining source files are deleted through their owner")
	var/datum/netrun_daemon_context/revoked = allocate(/datum/netrun_daemon_context)
	revoked.trace_factor = 1
	revoked.disengage_grace = 10 SECONDS
	revoked.capability = "unit-test-capability"
	effect.applications = 0
	borrower.apply_daemon_effects(revoked)
	TEST_ASSERT_EQUAL(effect.applications, 0, "No removed source executes through stale UI metadata")
	TEST_ASSERT_EQUAL(revoked.trace_factor, 1, "Revoked files leave the base trace factor intact")
	TEST_ASSERT_EQUAL(revoked.disengage_grace, 10 SECONDS, "Revoked files leave the base disengagement window intact")
	TEST_ASSERT(!revoked.capability_granted && !borrower.daemon_capability("unit-test-capability"), "Deleting the last real source revokes the capability across the borrowed inventory")
