/**
 * Shared contract definitions contain rules, never a seller's data or receipt state.
 * A subtype publishes a category to settlement, objectives and broker help together.
 */
/datum/netrun_contract_category
	var/id
	var/units_per_tc = 1
	var/objective_label
	var/reward_label
	var/status_label

/// Research exports must originate from an authored station bank.
/datum/netrun_contract_category/proc/eligible_research_source(datum/component/netrun_node/node)
	var/obj/machinery/rnd/server/server = node.parent
	return istype(server) && server.netrun_mapped_server && server.research_network_id() == RND_NETWORK_STATION

/datum/netrun_contract_category/proc/export_values(datum/netrun_console/console, datum/component/netrun_node/node, list/values)
	return eligible_research_source(node) ? values.Copy() : list()

/datum/netrun_contract_category/proc/objective_available(datum/netrun_console/console, datum/component/netrun_node/node)
	return FALSE

/datum/netrun_contract_category/proc/units(datum/component/netrun_broker_account/account)
	return 0

/// Return an error without mutation, or commit the actual data without sleeping.
/datum/netrun_contract_category/proc/redeem(datum/netrun_file/file, datum/netrun_data_receipt/receipt, datum/component/netrun_broker_account/account)
	return "Брокер не принимает эту категорию данных."

/datum/netrun_contract_category/research
	id = "research"
	units_per_tc = 1000
	objective_label = "очков исследований"
	reward_label = "изъятых очков"
	status_label = "очков исследований"

/datum/netrun_contract_category/research/units(datum/component/netrun_broker_account/account)
	return account?.research_points || 0

/datum/netrun_contract_category/research/objective_available(datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/machinery/rnd/server/server = node.parent
	return eligible_research_source(node) && server.stored_research

/datum/netrun_contract_category/research/redeem(datum/netrun_file/file, datum/netrun_data_receipt/receipt, datum/component/netrun_broker_account/account)
	var/datum/netrun_file/research_points/data = file
	if(!istype(data) || !length(data.payload?.points))
		return "Эта выгрузка очков уже погашена."
	var/points = 0
	for(var/point_type in data.payload.points)
		points += data.payload.points[point_type]
	if(points <= 0)
		return "В этой выгрузке нет очков исследований."
	// Copies and rnd_restore spend the exact same balance.
	data.payload.consume()
	account.research_points += points

/// Distinct categories share novelty accounting but select their own account ledger.
/datum/netrun_contract_category/distinct

/datum/netrun_contract_category/distinct/proc/recorded_values(datum/component/netrun_broker_account/account)
	return null

/datum/netrun_contract_category/distinct/units(datum/component/netrun_broker_account/account)
	return length(recorded_values(account))

/datum/netrun_contract_category/distinct/redeem(datum/netrun_file/file, datum/netrun_data_receipt/receipt, datum/component/netrun_broker_account/account)
	var/list/recorded = recorded_values(account)
	var/list/novel = list()
	for(var/value in receipt.values)
		if(!(value in recorded))
			novel |= value
	if(!length(novel))
		return "Брокер уже получил эти технологии или доступы. Нужны новые данные."
	recorded.Add(novel)

/datum/netrun_contract_category/distinct/technology
	id = "technology"
	units_per_tc = 3
	objective_label = "различные технологии"
	reward_label = "новые технологии"
	status_label = "технологий"

/datum/netrun_contract_category/distinct/technology/recorded_values(datum/component/netrun_broker_account/account)
	return account?.technologies

/datum/netrun_contract_category/distinct/technology/objective_available(datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/machinery/rnd/server/server = node.parent
	return eligible_research_source(node) && length(server.stored_research?.researched_nodes) >= units_per_tc

/datum/netrun_contract_category/distinct/access
	id = "access"
	units_per_tc = 5
	objective_label = "различных чужих ID-доступов"
	reward_label = "новых чужих доступов"
	status_label = "доступов"

/datum/netrun_contract_category/distinct/access/recorded_values(datum/component/netrun_broker_account/account)
	return account?.accesses

/datum/netrun_contract_category/distinct/access/export_values(datum/netrun_console/console, datum/component/netrun_node/node, list/values)
	if(!length(values))
		return list()
	var/mob/living/carbon/victim = node.parent
	if(istype(node.parent, /obj/effect/netrun_endpoint/neural))
		var/obj/effect/netrun_endpoint/neural/endpoint = node.parent
		victim = endpoint.interface?.host_mob
	if(istype(victim) && victim.netrun_personal_principal() == console.broker_mind())
		return list()
	return console.broker_foreign_access(node, values)

/datum/netrun_contract_category/distinct/access/objective_available(datum/netrun_console/console, datum/component/netrun_node/node)
	var/atom/source = node.parent
	return length(export_values(console, node, source.netrun_credential_access())) >= units_per_tc

/datum/controller/subsystem/netrun
	var/list/datum/netrun_contract_category/contract_categories

/datum/controller/subsystem/netrun/proc/get_contract_category(id)
	RETURN_TYPE(/datum/netrun_contract_category)
	if(!contract_categories)
		contract_categories = list()
		for(var/datum/netrun_contract_category/path as anything in subtypesof(/datum/netrun_contract_category))
			var/category_id = initial(path.id)
			var/threshold = initial(path.units_per_tc)
			if(!istext(category_id) || !length(category_id) || !IS_FINITE(threshold) || threshold <= 0)
				continue
			contract_categories[category_id] = new path
	return istext(id) ? contract_categories[id] : null

/datum/controller/subsystem/netrun/proc/contract_category_ids()
	get_contract_category(null)
	. = list()
	for(var/id in contract_categories)
		. += id

/datum/controller/subsystem/netrun/proc/contract_reward_terms()
	var/list/terms = list()
	for(var/id in contract_category_ids())
		var/datum/netrun_contract_category/category = get_contract_category(id)
		terms += "[category.units_per_tc] [category.reward_label]"
	return jointext(terms, ", ")
