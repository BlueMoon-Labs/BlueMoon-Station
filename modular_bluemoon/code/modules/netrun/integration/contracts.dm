/// Export receipts are server-owned capabilities. Text, names and disk UIDs are not proof.
/datum/netrun_data_receipt
	var/datum/weakref/issuer_ref
	var/category
	var/list/values
	var/redeemed = FALSE

/datum/netrun_data_receipt/New(datum/mind/issuer, category, list/values)
	issuer_ref = WEAKREF(issuer)
	src.category = category
	src.values = values.Copy()

/datum/netrun_file
	/// Copies share this exact receipt, including its spent state.
	var/datum/netrun_data_receipt/data_receipt

/datum/component/netrun_broker_account
	var/list/technologies = list()
	var/list/accesses = list()
	var/research_points = 0
	var/paid_tc = 0
	var/list/original_access = list()
	var/list/own_card_refs = list()
	var/identity_name

/datum/component/netrun_broker_account/Initialize()
	if(!istype(parent, /datum/mind))
		return COMPONENT_INCOMPATIBLE
	var/datum/mind/principal = parent
	identity_name = principal.name || principal.current?.real_name
	if(principal.current)
		original_access = netrun_mob_access(principal.current).Copy()
		var/obj/item/card/id/card = principal.current.get_idcard(FALSE)
		if(card)
			own_card_refs += WEAKREF(card)

/datum/component/netrun_broker_account/proc/owns_card(obj/item/card/id/card)
	if(identity_name && card.registered_name == identity_name)
		return TRUE
	for(var/datum/weakref/reference as anything in own_card_refs)
		if(reference.resolve() == card)
			return TRUE
	return FALSE

/datum/component/netrun_broker_account/proc/units(category)
	var/datum/netrun_contract_category/definition = SSnetrun.get_contract_category(category)
	return definition ? definition.units(src) : 0

/datum/component/netrun_broker_account/proc/earned_tc()
	. = 0
	for(var/id in SSnetrun.contract_category_ids())
		var/datum/netrun_contract_category/category = SSnetrun.get_contract_category(id)
		. += FLOOR(category.units(src) / category.units_per_tc, 1)
	return min(NETRUN_CONTRACT_TC_CAP, .)

/datum/component/netrun_broker_account/proc/status_text()
	var/list/terms = list()
	for(var/id in SSnetrun.contract_category_ids())
		var/datum/netrun_contract_category/category = SSnetrun.get_contract_category(id)
		terms += "[category.units(src)] [category.status_label]"
	return jointext(terms, ", ")

/datum/netrun_console/proc/broker_mind()
	var/datum/mind/principal = personal_faction_principal()
	return istype(principal) && !QDELETED(principal) ? principal : null

/// Remember pre-contract identity: taking off an ID cannot turn its rights into foreign loot.
/datum/netrun_console/proc/broker_foreign_access(datum/component/netrun_node/node, list/values)
	var/datum/mind/principal = broker_mind()
	var/datum/component/netrun_broker_account/account = principal?.LoadComponent(/datum/component/netrun_broker_account)
	var/list/eligible = values.Copy()
	eligible -= user_access(TRUE)
	eligible -= account?.original_access
	var/atom/source = node.parent
	for(var/obj/item/card/id/card as anything in source.netrun_credential_cards())
		if(account?.owns_card(card))
			eligible -= card.GetAccess()
	return eligible

/// Only actual unauthorized exports from station equipment can carry a receipt.
/datum/netrun_console/proc/stamp_data_export(datum/netrun_file/file, datum/component/netrun_node/node, category, list/values)
	var/datum/mind/issuer = broker_mind()
	var/turf/location = node?.physical_turf()
	var/datum/netrun_contract_category/definition = SSnetrun.get_contract_category(category)
	if(!definition || !issuer || !location || !is_station_level(location.z) || compute_legit_node_level(node, TRUE) >= NETRUN_ACCESS_USER)
		return
	var/list/eligible = definition.export_values(src, node, values)
	if(length(eligible))
		file.data_receipt = new(issuer, category, eligible)

/// No sleeps: validation, spending the receipt/payload and crediting the uplink are atomic.
/datum/netrun_console/proc/broker_sell()
	var/datum/mind/seller = broker_mind()
	var/datum/antagonist/traitor/role = seller?.has_antag_datum(/datum/antagonist/traitor)
	if(!role || QDELETED(role.uplink) || QDELETED(role.uplink.parent) || role.uplink.owner != seller.key)
		return "Брокер: нужен действующий контракт трейтора и его аплинк."
	if(is_locked() || !has_uplink())
		return "Брокер недоступен: восстановите соединение с NTnet."
	var/datum/netrun_file/file = selected_local_file()
	var/datum/netrun_data_receipt/receipt = file?.data_receipt
	if(!receipt || receipt.redeemed || receipt.issuer_ref?.resolve() != seller)
		return "Выберите собственную ещё не сданную выгрузку: rnd_grab, rnd_siphon или extract_credentials. Подделки и повторная сдача не принимаются."
	var/datum/netrun_contract_category/category = SSnetrun.get_contract_category(receipt.category)
	if(!category)
		return "Брокер не принимает эту категорию данных."
	var/datum/component/netrun_broker_account/account = seller.LoadComponent(/datum/component/netrun_broker_account)
	var/error = category.redeem(file, receipt, account)
	if(error)
		return error
	receipt.redeemed = TRUE
	// A round cap bounds passive R&D harvesting; novelty is shared across every source and copy.
	var/reward = max(0, account.earned_tc() - account.paid_tc)
	account.paid_tc += reward
	role.uplink.telecrystals += reward
	SStgui.update_uis(role.uplink)
	log_game("NETRUN BROKER: [key_name(seller.current)] submitted [receipt.category], received [reward] TC (round total [account.paid_tc]).")
	return "Брокер принял данные. Выплата: [reward] TC; всего [account.paid_tc]/[NETRUN_CONTRACT_TC_CAP] TC. Принято: [account.status_text()]."

/datum/netrun_cli_command/broker
	id = "broker"
	args = "status|sell"
	desc = "Контрактный брокер: статус или сдача выбранной выгрузки в аплинк трейтора."
	category = "Файлы"

/datum/netrun_cli_command/broker/execute(datum/netrun_console/console, list/words, raw)
	if(words[2] == "sell")
		console.log_line(console.broker_sell())
		return
	var/datum/mind/principal = console.broker_mind()
	var/datum/component/netrun_broker_account/account = principal?.GetComponent(/datum/component/netrun_broker_account)
	console.log_line("Брокер: выберите выгрузку в памяти/на шарде, затем broker sell. За каждую полную группу данных ([SSnetrun.contract_reward_terms()]) — 1 TC; максимум [NETRUN_CONTRACT_TC_CAP] TC за раунд. Получено: [account?.paid_tc || 0]/[NETRUN_CONTRACT_TC_CAP] TC.")
	if(account)
		console.log_line("Принято: [account.status_text()].")

/obj/item/netrun_deck/contract
	name = "contract cyberdeck"

/obj/item/netrun_deck/contract/Initialize(mapload)
	. = ..()
	for(var/id in list("autobreach", "icepick", "cloak"))
		console.store_file(netrun_daemon_file(id))
	console.store_file(new /datum/netrun_file("contract.txt", NETRUN_FILE_TEXT, "Ваша цель указана в задачах трейтора. Взломайте научный сервер либо чужой источник ID-данных. rnd_grab копирует технологии, rnd_siphon изымает очки, extract_credentials копирует ID. Выберите выгрузку в памяти и выполните broker sell при рабочем NTnet. Повторные копии не оплачиваются. Способности взлома не дают разрешения игнорировать остальные задачи."))

/datum/objective/netrun_exfiltrate
	name = "netrun data exfiltration"
	var/category = "research"
	var/list/special_items_given = list()

/datum/objective/netrun_exfiltrate/New()
	. = ..()
	configure(category)

/datum/objective/netrun_exfiltrate/proc/configure(new_category, amount)
	var/datum/netrun_contract_category/definition = SSnetrun.get_contract_category(new_category)
	if(!definition)
		return FALSE
	category = new_category
	target_amount = isnull(amount) ? definition.units_per_tc : amount
	explanation_text = "Взломайте оборудование станции и сдайте контрактному брокеру [target_amount] [definition.objective_label]. Выберите выгрузку в памяти кибердеки и выполните broker sell при рабочем NTnet. Стартовая дека выдана; сдача копий и собственных доступов не засчитывается."
	return TRUE

/datum/objective/netrun_exfiltrate/check_completion()
	var/datum/component/netrun_broker_account/account = owner?.GetComponent(/datum/component/netrun_broker_account)
	return completed || (account && account.units(category) >= target_amount)

/datum/objective/netrun_exfiltrate/admin_edit(mob/admin)
	var/choice = tgui_input_list(admin, "Вид добычи", "Сетевая эксфильтрация", SSnetrun.contract_category_ids())
	if(!choice)
		return
	configure(choice)
	if(!length(special_items_given))
		special_items_given = give_special_equipment(list(/obj/item/netrun_deck/contract))

/datum/objective/netrun_exfiltrate/Destroy(force, ...)
	QDEL_LIST(special_items_given)
	return ..()

/// Normal human traitors only, at most one objective and only with a real station source.
/datum/traitor_class/proc/try_forge_netrun_objective(datum/antagonist/traitor/role)
	if(!role.should_equip || !ishuman(role.owner?.current) || (locate(/datum/objective/netrun_exfiltrate) in role.objectives) || (role.owner.assigned_role in list("Research Director", "Scientist", "Roboticist")))
		return FALSE
	var/relay_found = FALSE
	var/list/categories = list()
	var/list/category_ids = SSnetrun.contract_category_ids()
	var/datum/netrun_console/probe = new(role.owner.current)
	probe.operator = role.owner.current
	role.owner.LoadComponent(/datum/component/netrun_broker_account)
	for(var/address in SSnetrun.nodes_by_address)
		var/datum/component/netrun_node/node = SSnetrun.nodes_by_address[address]
		var/turf/location = node.physical_turf()
		if(istype(node.parent, /obj/machinery/ntnet_relay) && location && is_station_level(location.z) && node.is_online())
			relay_found = TRUE
		if(!location || !is_station_level(location.z) || probe.compute_legit_node_level(node, TRUE) >= NETRUN_ACCESS_USER)
			continue
		for(var/id in category_ids)
			var/datum/netrun_contract_category/definition = SSnetrun.get_contract_category(id)
			if(definition.objective_available(probe, node))
				categories |= id
	qdel(probe)
	if(!length(categories) || !relay_found)
		return FALSE
	var/datum/objective/netrun_exfiltrate/objective = new
	objective.owner = role.owner
	var/category = pick(categories)
	objective.configure(category)
	role.add_objective(objective)
	objective.special_items_given = objective.give_special_equipment(list(/obj/item/netrun_deck/contract))
	return TRUE
