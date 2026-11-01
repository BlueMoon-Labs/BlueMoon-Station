/datum/antagonist/traitor/netrun_contract_fixture/on_removal()
	// This fixture never installs the traitor class or its round-wide effects.
	SHOULD_CALL_PARENT(FALSE)
	return

/datum/netrun_contract_scene
	parent_type = /datum/netrun_fortress_scene
	var/mob/living/carbon/human/user
	var/datum/netrun_console/client
	var/datum/antagonist/traitor/role
	var/obj/machinery/rnd/server/server
	var/datum/component/netrun_node/research_node
	var/obj/machinery/ntnet_relay/relay

/datum/netrun_contract_scene/New(turf/origin)
	..(origin)
	user = new(origin)
	owned += user
	user.mind_initialize()
	client = new(node_a.parent)
	owned += client
	client.operator = user
	client.inventory.local_store.capacity = 128
	role = new /datum/antagonist/traitor/netrun_contract_fixture
	role.owner = user.mind
	LAZYADD(user.mind.antag_datums, role)
	var/obj/item/holder = new(origin)
	owned += holder
	role.uplink = holder.AddComponent(/datum/component/uplink, user.mind.key, TRUE, FALSE, UPLINK_TRAITORS, 0)
	server = machine(/obj/machinery/rnd/server, get_turf(node_b.parent))
	server.netrun_mapped_server = TRUE
	server.network_id = RND_NETWORK_STATION
	server.stored_research.research_points = list(TECHWEB_POINT_TYPE_GENERIC = 20000)
	server.stored_research.researched_nodes = list("base" = TRUE, "datatheory" = TRUE, "engineering" = TRUE)
	research_node = netrun_find_node(server)
	relay = machine(/obj/machinery/ntnet_relay, origin)
	SSnetworks.station_network.setting_disabled = FALSE
	SSnetrun.ensure_topology()

/datum/netrun_contract_scene/Destroy()
	QDEL_NULL(role)
	return ..()

/// Re-export, rename, disk copies and plain forged text cannot replay a sale.
/datum/unit_test/netrun_contract_technology_novelty/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	TEST_ASSERT(scene.client.has_uplink(), "The broker uses a real operational relay")
	var/datum/netrun_command/export = SSnetrun.get_command("rnd_grab")
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/file = scene.client.selected_local_file()
	TEST_ASSERT_NOTNULL(file.data_receipt, "An unauthorized station export receives an opaque receipt")
	var/datum/netrun_file/copy = file.copy()
	TEST_ASSERT(scene.client.store_file(copy), "The copied dump fits ordinary memory")
	TEST_ASSERT_EQUAL(copy.data_receipt, file.data_receipt, "All copies share the same receipt")
	scene.client.inventory.selected_file_uid = copy.uid
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "Three genuine technologies pay one TC")
	scene.client.inventory.selected_file_uid = file.uid
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "Selling the original after a copy cannot pay twice")
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/reexported = scene.client.selected_local_file()
	reexported.name = "renamed.web"
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "A fresh export of the same technologies is not novel")
	var/datum/netrun_file/forged = new("forged.web", NETRUN_FILE_TECHWEB, "base;datatheory;engineering", 1)
	scene.client.store_file(forged)
	scene.client.inventory.selected_file_uid = forged.uid
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "Filenames and forged content are not proof of theft")
	var/datum/objective/netrun_exfiltrate/objective = allocate(/datum/objective/netrun_exfiltrate)
	objective.owner = scene.user.mind
	objective.configure("technology", 3)
	TEST_ASSERT(objective.check_completion(), "The actual seller's authenticated receipts complete the objective")
	objective.owner = allocate(/datum/mind)
	TEST_ASSERT(!objective.check_completion(), "Another mind cannot inherit the seller's objective receipts")

/// Points have one authoritative balance shared with rnd_restore; payouts have a round cap.
/datum/unit_test/netrun_contract_research_consumption/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/netrun_command/siphon = SSnetrun.get_command("rnd_siphon")
	var/datum/netrun_command/restore = SSnetrun.get_command("rnd_restore")
	siphon.execute(scene.research_node, scene.client)
	var/datum/netrun_file/research_points/file = scene.client.selected_local_file()
	var/datum/netrun_file/research_points/copy = file.copy()
	scene.client.store_file(copy)
	scene.relay.enabled = FALSE
	scene.client.broker_sell()
	TEST_ASSERT(!file.data_receipt.redeemed && length(file.payload.points), "A lost uplink cannot spend a receipt or its point balance")
	scene.relay.enabled = TRUE
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 5, "The real stolen balance is credited to the traitor's native uplink")
	TEST_ASSERT(!length(file.payload.points), "Cashout consumes the same balance as research restoration")
	scene.client.inventory.selected_file_uid = copy.uid
	var/bank = scene.server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC]
	restore.execute(scene.research_node, scene.client)
	TEST_ASSERT_EQUAL(scene.server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC], bank, "A sold copy cannot also restore research points")
	scene.server.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC] = 40000
	siphon.execute(scene.research_node, scene.client)
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 6, "Repeated genuine point exports still respect the per-mind round cap")

/// Legal exports and private manufactured banks cannot farm station-theft rewards.
/datum/unit_test/netrun_contract_source_authority/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/netrun_command/export = SSnetrun.get_command("rnd_grab")
	scene.server.netrun_mapped_server = FALSE
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/private_dump = scene.client.selected_local_file()
	TEST_ASSERT_NULL(private_dump.data_receipt, "A privately built bank does not issue paid station-theft receipts")
	scene.server.netrun_mapped_server = TRUE
	scene.research_node.required_access = list()
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_NETWORK)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	scene.user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	scene.user.equip_to_slot_if_possible(card, ITEM_SLOT_ID)
	scene.research_node.required_access = list(ACCESS_NETWORK)
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/legal_dump = scene.client.selected_local_file()
	TEST_ASSERT_NULL(legal_dump.data_receipt, "Legally authorized exports cannot be sold as stolen data")

/// Only the exporting mind's live traitor role may spend a receipt.
/datum/unit_test/netrun_contract_role_revalidation/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/netrun_command/export = SSnetrun.get_command("rnd_grab")
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/file = scene.client.selected_local_file()
	scene.user.mind.antag_datums -= scene.role
	scene.client.broker_sell()
	TEST_ASSERT(!file.data_receipt.redeemed, "Losing the role preserves the data and rejects payment")
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 0, "A former traitor cannot credit the old uplink")
	scene.user.mind.antag_datums += scene.role
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	other.mind_initialize()
	scene.client.operator = other
	scene.client.broker_sell()
	TEST_ASSERT(!file.data_receipt.redeemed, "Changing the terminal operator does not transfer the receipt's issuer")

/datum/unit_test/netrun_contract_objective_eligibility/Run()
	var/list/previous_choices = GLOB.objective_choices
	populate_objective_choices()
	var/registered = GLOB.objective_choices["netrun data exfiltration"] == /datum/objective/netrun_exfiltrate
	GLOB.objective_choices = previous_choices
	TEST_ASSERT(registered, "The new objective is available in the native objective picker")
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/traitor_class/human/class = GLOB.traitor_classes[TRAITOR_HUMAN]
	scene.role.should_equip = FALSE
	TEST_ASSERT(!class.try_forge_netrun_objective(scene.role), "Equipment-less special roles are not assigned a network equipment objective")
	scene.role.should_equip = TRUE
	TEST_ASSERT(class.try_forge_netrun_objective(scene.role), "A human traitor with a real station source can receive a network objective")
	var/datum/objective/netrun_exfiltrate/objective = locate() in scene.role.objectives
	allocated += objective
	TEST_ASSERT_NOTNULL(objective, "The forged objective is part of the existing traitor's objective list")
	TEST_ASSERT(length(objective.special_items_given), "The objective supplies the equipment needed before station research")
	var/obj/item/netrun_deck/contract/deck = objective.special_items_given[1]
	TEST_ASSERT(deck.console.daemon_capability("autobreach"), "The issued deck carries a real hacking executable")
	TEST_ASSERT(!class.try_forge_netrun_objective(scene.role), "A single traitor cannot accumulate duplicate network objectives")

/// Native card snapshots retain their receipt through copying and reject the operator's rights.
/datum/unit_test/netrun_contract_credentials/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/obj/item/modular_computer/laptop/computer = allocate(/obj/item/modular_computer/laptop, run_loc_floor_bottom_left)
	computer.enabled = TRUE
	var/obj/item/computer_hardware/card_slot/slot = computer.get_modular_computer_part(MC_CARD)
	if(!slot)
		slot = allocate(/obj/item/computer_hardware/card_slot)
		computer.install_component(slot)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MEDICAL, ACCESS_RD, ACCESS_SECURITY, ACCESS_CARGO, ACCESS_ENGINE)
	TEST_ASSERT(slot.try_insert(card), "The exported data comes from an actual inserted card")
	var/datum/component/netrun_node/node = netrun_find_node(computer)
	var/datum/netrun_command/export = SSnetrun.get_command("extract_credentials")
	export.execute(node, scene.client)
	var/datum/netrun_file/access/file = scene.client.selected_local_file()
	TEST_ASSERT_NOTNULL(file.data_receipt, "A real unauthorized credential snapshot carries its origin receipt")
	var/datum/netrun_file/access/copy = file.copy()
	scene.client.store_file(copy)
	TEST_ASSERT_EQUAL(copy.data_receipt, file.data_receipt, "Credential subtype copies preserve the same receipt")
	scene.client.inventory.selected_file_uid = copy.uid
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "Five real novel access rights are rewarded")
	export.execute(node, scene.client)
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "A newly exported copy of the same card cannot farm rewards")
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/card/id/own_card = allocate(/obj/item/card/id)
	own_card.access = card.access.Copy()
	scene.user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	scene.user.equip_to_slot_if_possible(own_card, ITEM_SLOT_ID)
	export.execute(node, scene.client)
	file = scene.client.selected_local_file()
	TEST_ASSERT_NULL(file.data_receipt, "Rights already on the exporting operator's own ID are not stolen data")

/// Eligibility uses the same native authorization as export receipts, beyond job-name exclusions.
/datum/unit_test/netrun_contract_objective_legal_sources/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_CAPTAIN, ACCESS_RD, ACCESS_NETWORK)
	scene.user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	scene.user.equip_to_slot_if_possible(card, ITEM_SLOT_ID)
	scene.role.owner.assigned_role = "Captain"
	var/datum/traitor_class/human/class = GLOB.traitor_classes[TRAITOR_HUMAN]
	TEST_ASSERT(!class.try_forge_netrun_objective(scene.role), "A captain cannot receive a theft objective for exports already authorized by their native ID")

/// Removing, upgrading and renaming the original ID cannot launder it through a public laptop.
/datum/unit_test/netrun_contract_removed_own_id/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_MEDICAL, ACCESS_RD, ACCESS_SECURITY, ACCESS_CARGO, ACCESS_ENGINE)
	card.registered_name = scene.user.real_name
	scene.user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	scene.user.equip_to_slot_if_possible(card, ITEM_SLOT_ID)
	var/datum/component/netrun_broker_account/account = scene.user.mind.LoadComponent(/datum/component/netrun_broker_account)
	TEST_ASSERT(account.owns_card(card), "The role captures the original physical card before the player can remove it")
	card.access |= list(ACCESS_TOX, ACCESS_ROBOTICS, ACCESS_CHEMISTRY, ACCESS_ENGINE_EQUIP, ACCESS_MAINT_TUNNELS)
	card.registered_name = "Renamed identity"
	TEST_ASSERT(scene.user.temporarilyRemoveItemFromInventory(card), "The owner can remove their real ID")
	card.forceMove(run_loc_floor_bottom_left)
	var/obj/item/modular_computer/laptop/computer = allocate(/obj/item/modular_computer/laptop, run_loc_floor_bottom_left)
	computer.enabled = TRUE
	var/obj/item/computer_hardware/card_slot/slot = computer.get_modular_computer_part(MC_CARD)
	if(!slot)
		slot = allocate(/obj/item/computer_hardware/card_slot)
		computer.install_component(slot)
	TEST_ASSERT(slot.try_insert(card), "The removed ID enters an external native card slot")
	TEST_ASSERT_EQUAL(length(scene.client.user_access(TRUE)), 0, "The current operator no longer carries those rights")
	var/datum/component/netrun_node/node = netrun_find_node(computer)
	var/datum/netrun_command/export = SSnetrun.get_command("extract_credentials")
	export.execute(node, scene.client)
	var/datum/netrun_file/access/file = scene.client.selected_local_file()
	TEST_ASSERT(istype(file) && length(file.accesses) == 10, "The data remains a usable ordinary snapshot of the real card")
	TEST_ASSERT_NULL(file.data_receipt, "The owner's removed, upgraded and renamed ID cannot issue a paid theft receipt")
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 0, "Laundering an owned ID earns no TC")

/// Fixtures do not publish a production category during subtype discovery.
/datum/netrun_contract_category/distinct/extension_fixture
	id = null
	units_per_tc = 2
	objective_label = "fixture records"
	reward_label = "new fixture records"
	status_label = "fixture records"

/datum/component/netrun_broker_account
	var/list/contract_fixture_values = list()

/datum/netrun_contract_category/distinct/extension_fixture/recorded_values(datum/component/netrun_broker_account/account)
	return account?.contract_fixture_values

/datum/netrun_contract_category/distinct/extension_fixture/objective_available(datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/machinery/rnd/server/server = node.parent
	return eligible_research_source(node) && length(server.stored_research?.researched_nodes) >= units_per_tc

/datum/netrun_contract_category/invalid_threshold_fixture
	id = "unit-test-invalid-threshold"
	units_per_tc = 0

/// Restore the shared registry even when an assertion exits Run early.
/datum/unit_test/netrun_contract_categories
	var/list/previous_categories
	var/registry_replaced = FALSE

/datum/unit_test/netrun_contract_categories/proc/use_categories(list/categories)
	previous_categories = SSnetrun.contract_categories
	registry_replaced = TRUE
	SSnetrun.contract_categories = categories

/datum/unit_test/netrun_contract_categories/Destroy()
	if(registry_replaced)
		SSnetrun.contract_categories = previous_categories
	return ..()

/// A new category participates in export, settlement and objectives without central dispatch edits.
/datum/unit_test/netrun_contract_categories/extension/Run()
	TEST_ASSERT_NULL(SSnetrun.get_contract_category("unit-test-invalid-threshold"), "An invalid reward divisor cannot enter the shared registry")
	var/datum/netrun_contract_category/distinct/extension_fixture/category = allocate(/datum/netrun_contract_category/distinct/extension_fixture)
	category.id = "unit-test-extension"
	var/list/categories = list()
	categories[category.id] = category
	use_categories(categories)
	TEST_ASSERT(category.id in SSnetrun.contract_category_ids(), "A registered extension is visible to the category picker")
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/netrun_file/file = new("extension.txt", NETRUN_FILE_TEXT, "fixture data", 1)
	TEST_ASSERT(scene.client.store_file(file), "The extension uses an ordinary local file")
	scene.client.inventory.selected_file_uid = file.uid
	scene.client.stamp_data_export(file, scene.research_node, category.id, list("first", "second"))
	TEST_ASSERT_NOTNULL(file.data_receipt, "The extension controls its ordinary authenticated export")
	scene.client.broker_sell()
	var/datum/component/netrun_broker_account/account = scene.user.mind.GetComponent(/datum/component/netrun_broker_account)
	TEST_ASSERT_EQUAL(account.units(category.id), 2, "The extension records its own ledger rather than a built-in category")
	TEST_ASSERT_EQUAL(length(account.technologies) + length(account.accesses) + account.research_points, 0, "Extension settlement does not change unrelated ledgers")
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "The common broker pays the extension's reward")
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "The common receipt guard still prevents extension replay")
	TEST_ASSERT(category.objective_available(scene.client, scene.research_node), "The extension publishes its own source eligibility")
	var/datum/objective/netrun_exfiltrate/objective = allocate(/datum/objective/netrun_exfiltrate)
	objective.owner = scene.user.mind
	TEST_ASSERT(objective.configure(category.id), "A registered extension configures the existing objective")
	TEST_ASSERT(objective.check_completion(), "The existing objective reads the extension's settled ledger")

/// One changed threshold drives the actual payout, source eligibility, objective and broker help.
/datum/unit_test/netrun_contract_categories/shared_threshold/Run()
	var/datum/netrun_contract_category/distinct/technology/category = allocate(/datum/netrun_contract_category/distinct/technology)
	category.units_per_tc = 2
	use_categories(list("technology" = category))
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	scene.server.stored_research.researched_nodes = list("base" = TRUE)
	TEST_ASSERT(!category.objective_available(scene.client, scene.research_node), "A source below the configured threshold cannot offer the objective")
	scene.server.stored_research.researched_nodes["datatheory"] = TRUE
	TEST_ASSERT(category.objective_available(scene.client, scene.research_node), "A source meeting the changed threshold can offer the objective")
	var/datum/objective/netrun_exfiltrate/objective = allocate(/datum/objective/netrun_exfiltrate)
	objective.owner = scene.user.mind
	TEST_ASSERT(objective.configure(category.id), "The configured category remains selectable")
	TEST_ASSERT_EQUAL(objective.target_amount, category.units_per_tc, "The objective uses the configured threshold")
	TEST_ASSERT(!objective.check_completion(), "Available source data alone does not complete an unsettled objective")
	TEST_ASSERT(findtext(SSnetrun.contract_reward_terms(), "[category.units_per_tc] [category.reward_label]"), "Broker help describes the configured reward threshold")
	var/datum/netrun_command/export = SSnetrun.get_command("rnd_grab")
	export.execute(scene.research_node, scene.client)
	var/datum/netrun_file/file = scene.client.selected_local_file()
	TEST_ASSERT_NOTNULL(file.data_receipt, "The changed threshold still uses a genuine station export")
	scene.client.broker_sell()
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 1, "Two exported technologies pay according to the changed threshold")
	TEST_ASSERT(objective.check_completion(), "Settlement completes the objective using the same threshold")

/// Unknown categories fail before consuming data, crediting accounts or reconfiguring an objective.
/datum/unit_test/netrun_contract_categories/unknown/Run()
	var/datum/netrun_contract_scene/scene = allocate(/datum/netrun_contract_scene, run_loc_floor_bottom_left)
	var/datum/netrun_file/unstamped = allocate(/datum/netrun_file, "unknown.txt", NETRUN_FILE_TEXT, "fixture data", 1)
	scene.client.stamp_data_export(unstamped, scene.research_node, "unit-test-unknown", list("value"))
	TEST_ASSERT_NULL(unstamped.data_receipt, "An unknown category cannot issue an authenticated receipt")
	var/datum/netrun_command/siphon = SSnetrun.get_command("rnd_siphon")
	siphon.execute(scene.research_node, scene.client)
	var/datum/netrun_file/research_points/file = scene.client.selected_local_file()
	TEST_ASSERT_NOTNULL(file.data_receipt, "The fixture first obtains a genuine research balance")
	file.data_receipt.category = "unit-test-unknown"
	var/points = file.payload.points[TECHWEB_POINT_TYPE_GENERIC]
	var/datum/component/netrun_broker_account/account = scene.user.mind.LoadComponent(/datum/component/netrun_broker_account)
	scene.client.broker_sell()
	TEST_ASSERT(!file.data_receipt.redeemed, "A rejected category leaves its receipt unspent")
	TEST_ASSERT_EQUAL(file.payload.points[TECHWEB_POINT_TYPE_GENERIC], points, "A rejected category preserves the restorable point balance")
	TEST_ASSERT_EQUAL(length(account.technologies) + length(account.accesses) + account.research_points + account.paid_tc, 0, "A rejected category cannot mutate any account ledger")
	TEST_ASSERT_EQUAL(scene.role.uplink.telecrystals, 0, "A rejected category cannot credit the uplink")
	TEST_ASSERT_EQUAL(account.units("unit-test-unknown"), 0, "An unknown category has no credited units")
	var/datum/objective/netrun_exfiltrate/objective = allocate(/datum/objective/netrun_exfiltrate)
	objective.configure("technology", 7)
	var/previous_explanation = objective.explanation_text
	TEST_ASSERT(!objective.configure("unit-test-unknown"), "An unknown objective category is rejected")
	TEST_ASSERT_EQUAL(objective.category, "technology", "Failed configuration preserves the existing objective category")
	TEST_ASSERT_EQUAL(objective.target_amount, 7, "Failed configuration preserves the existing objective amount")
	TEST_ASSERT_EQUAL(objective.explanation_text, previous_explanation, "Failed configuration preserves the existing objective text")
