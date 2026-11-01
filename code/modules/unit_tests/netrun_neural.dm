/// The display is a separate service, not a replacement for the wearer's cyber node.
/datum/unit_test/netrun_neural_endpoint_lifecycle/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/component/netrun_node/cyber_node = user.AddComponent(/datum/component/netrun_node, NETRUN_NODE_IMPLANT, list(), 2)
	var/datum/component/neural_interface/interface = user.LoadComponent(/datum/component/neural_interface)
	interface.AddSource("NETRUN_TEST")
	var/datum/component/netrun_neural_adapter/adapter = interface.GetComponent(/datum/component/netrun_neural_adapter)
	TEST_ASSERT_NOTNULL(adapter, "The neural display has no network adapter")
	var/obj/effect/netrun_endpoint/neural/endpoint = adapter.endpoint
	TEST_ASSERT_NOTNULL(endpoint, "The neural adapter has no endpoint")
	var/datum/component/netrun_node/display_node = endpoint.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(display_node != cyber_node, "The display reused the cybernetics node")
	TEST_ASSERT_EQUAL(user.GetComponent(/datum/component/netrun_node), cyber_node, "The display replaced the cybernetics node")
	TEST_ASSERT_EQUAL(endpoint.loc, user, "The endpoint does not follow its wearer")
	var/address = display_node.address
	TEST_ASSERT_EQUAL(SSnetrun.find_node(address), display_node, "The endpoint is not addressable")
	interface.RemoveSource("NETRUN_TEST")
	TEST_ASSERT(QDELETED(interface), "Removing the last source kept the interface alive")
	TEST_ASSERT(QDELETED(endpoint), "Removing the interface leaked its endpoint")
	TEST_ASSERT_NULL(SSnetrun.find_node(address), "The destroyed endpoint kept its address")
	TEST_ASSERT(!QDELETED(cyber_node), "Destroying the display also destroyed the cybernetics node")

/// Only carrying a device grants ownership, including carrying it inside a container.
/datum/unit_test/netrun_portable_owner_access/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	var/datum/netrun_console/console = deck.console
	console.operator = user
	TEST_ASSERT_EQUAL(deck.netrun_owner_access(console), NETRUN_ACCESS_NONE, "A nearby operator received ownership of a floor device")
	bag.forceMove(user)
	deck.forceMove(bag)
	TEST_ASSERT_EQUAL(deck.netrun_owner_access(console), NETRUN_ACCESS_ROOT, "An operator carrying the deck in a container lost ownership")
	deck.forceMove(get_turf(user))
	TEST_ASSERT_EQUAL(deck.netrun_owner_access(console), NETRUN_ACCESS_NONE, "A dropped device retained its previous owner's rights")

/// Standard neural signals, console events and damage feedback all reach resident processes.
/datum/unit_test/netrun_entity_neural_feedback/Run()
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/datum/component/neural_interface/interface = entity.GetComponent(/datum/component/neural_interface)
	TEST_ASSERT_NOTNULL(interface, "The resident process rejected the neural display component")
	var/datum/neural_interface_module/data/data_module = interface.modules["data"]
	SEND_SIGNAL(entity, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "TEST_SIGNAL", "received", 5 SECONDS)
	TEST_ASSERT_EQUAL(data_module.get_data_entry_value("TEST_SIGNAL"), "received", "The standard display signal did not reach the process")
	var/datum/neural_interface_module/logs/log_module = interface.modules["log"]
	entity.console.log_line("Error <broken>", "bad")
	var/datum/log_entry/entry = log_module.logs[length(log_module.logs)]
	TEST_ASSERT(findtext(entry.plain, "Error &lt;broken&gt;"), "Console feedback was not delivered as escaped neural text")
	entity.take_integrity(10, "test impact")
	entry = log_module.logs[length(log_module.logs)]
	TEST_ASSERT(findtext(entry.plain, "Integrity 90/100"), "An integrity event did not update English neural feedback")
	var/datum/component/netrun_neural_feedback/feedback = entity.GetComponent(/datum/component/netrun_neural_feedback)
	feedback.update_feedback()
	TEST_ASSERT_EQUAL(data_module.get_data_entry_value("INTEGRITY"), "90/100", "The process HUD did not publish its English integrity key")
	TEST_ASSERT_EQUAL(data_module.get_data_entry_value("HOST"), "none", "The process HUD did not publish its English host key")
	entity.console.log_line("Трассировка <проверка>", "average")
	entry = log_module.logs[length(log_module.logs)]
	TEST_ASSERT(findtext(entry.plain, "Trassirovka &lt;proverka&gt;"), "Russian console feedback did not use a safe Latin display fallback")
	qdel(entity.console)
	entity.console = null
	TEST_ASSERT(QDELETED(feedback), "Deleting a client leaked its neural feedback adapter")

/// Network notification payloads use an explicit UID, even when filenames collide.
/datum/unit_test/netrun_neural_selected_payload/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/datum/component/neural_interface/interface = user.LoadComponent(/datum/component/neural_interface)
	interface.AddSource("NETRUN_TEST")
	var/datum/component/netrun_neural_adapter/adapter = interface.GetComponent(/datum/component/netrun_neural_adapter)
	var/datum/component/netrun_node/node = adapter.endpoint.GetComponent(/datum/component/netrun_node)
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck)
	var/datum/netrun_file/selected = new("файл.txt", NETRUN_FILE_TEXT, "Тест <selected>")
	var/datum/netrun_file/decoy = new("файл.txt", NETRUN_FILE_TEXT, "wrong file")
	deck.console.store_file(selected)
	deck.console.store_file(decoy)
	deck.console.inventory.selected_file_uid = selected.uid
	var/datum/netrun_command/notify = SSnetrun.get_command("neural_notify")
	TEST_ASSERT_NOTNULL(notify, "The neural notification command is not registered")
	notify.execute(node, deck.console)
	var/datum/neural_interface_module/logs/log_module = interface.modules["log"]
	var/datum/log_entry/entry = log_module.logs[length(log_module.logs)]
	TEST_ASSERT(findtext(entry.plain, "Test &lt;selected&gt;"), "The neural command ignored its selected UID or Latin display fallback")
	TEST_ASSERT_EQUAL(selected.content, "Тест <selected>", "The display fallback changed the actual file")
	var/datum/netrun_command/data = SSnetrun.get_command("neural_data")
	data.execute(node, deck.console)
	var/datum/neural_interface_module/data/data_module = interface.modules["data"]
	TEST_ASSERT_EQUAL(data_module.get_data_entry_value("NET:fayl.txt"), "Test &lt;selected&gt;", "A remote data label or value contains unsupported text")
	deck.console.inventory.selected_file_uid = null
	var/count = length(log_module.logs)
	TEST_ASSERT_NULL(notify.execute(node, deck.console), "The neural command silently fell back to a different file")
	TEST_ASSERT_EQUAL(length(log_module.logs), count, "A failed notification wrote to the remote neural display")

/// Font fallback is local to the HUD, keeps HTML inert and exposes unsupported code points.
/datum/unit_test/netrun_neural_font_fallback/Run()
	var/original = "Иван Петров <root> ☃"
	TEST_ASSERT_EQUAL(netrun_neural_text(original), "Ivan Petrov &lt;root&gt; U+2603", "The HUD fallback did not preserve a readable, escaped ASCII representation")
	TEST_ASSERT_EQUAL(original, "Иван Петров <root> ☃", "The display fallback changed its source text")
	TEST_ASSERT_EQUAL(netrun_neural_text("<&", 1), "&lt;", "HUD truncation split an HTML escape")
	TEST_ASSERT_EQUAL(netrun_neural_access_name(NETRUN_ACCESS_USER), "USER", "The neural HUD used a localized access label")
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	var/datum/component/netrun_neural_feedback/feedback = entity.GetComponent(/datum/component/netrun_neural_feedback)
	var/datum/neural_interface_module/netrun/module = feedback.interface.modules[feedback.module_key]
	var/datum/neural_interface_module/data/data_module = feedback.interface.modules["data"]
	var/list/netlink_position = splittext(module.screen_loc, ",")
	var/list/data_position = splittext(data_module.screen_loc, ",")
	TEST_ASSERT_EQUAL(netlink_position[1], data_position[1], "NETLINK is no longer aligned with DATA")
	var/netlink_y = text2num(replacetext(netlink_position[2], "CENTER", "")) * 32
	var/data_y = text2num(replacetext(data_position[2], "CENTER", "")) * 32
	TEST_ASSERT(netlink_y + module.maptext_height <= data_y - 8, "NETLINK overlaps the DATA module instead of sitting below it")
	TEST_ASSERT(findtext(module.render(), "NTnet: OFFLINE"), "The panel's disconnected state is not in English")
	entity.console.intrusion.lockout_until = world.time + 10 SECONDS
	TEST_ASSERT(findtext(module.render(), "LOCKED: 10s"), "The panel's lockout state is not in English")

/// A personal AI has its own client without receiving unrestricted station access.
/datum/unit_test/netrun_pai_client_permissions/Run()
	var/obj/item/paicard/card = allocate(/obj/item/paicard)
	var/mob/living/silicon/pai/pai = allocate(/mob/living/silicon/pai, card)
	card.setPersonality(pai)
	TEST_ASSERT_NOTNULL(pai.netrun_console, "The personal AI has no network client")
	TEST_ASSERT_NOTNULL(pai.network_action, "The personal AI has no network action")
	TEST_ASSERT_EQUAL(length(pai.netrun_console.user_access()), 0, "The personal AI client inherited unrestricted silicon access")
	TEST_ASSERT_EQUAL(length(netrun_mob_access(pai)), 0, "A personal AI using another terminal receives unrestricted silicon access")
	TEST_ASSERT_EQUAL(pai.netrun_owner_access(pai.netrun_console), NETRUN_ACCESS_ROOT, "The personal AI cannot administer its own endpoint")
	TEST_ASSERT_NOTNULL(pai.GetComponent(/datum/component/netrun_node), "The personal AI cannot be addressed through the network")

/// Ordinary bystanders can identify a diver and safely wake the same mind.
/datum/unit_test/netrun_dive_body_help_return/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The body-feedback fixture must enter the network")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	var/list/examine_list = list()
	SEND_SIGNAL(scene.user, COMSIG_PARENT_EXAMINE, scene.user, examine_list)
	TEST_ASSERT(findtext(jointext(examine_list, " "), "Нейролинк активен"), "A physical examination identifies an active neural dive")
	TEST_ASSERT(!(SEND_SIGNAL(scene.user, COMSIG_CARBON_PRE_MISC_HELP, scene.user) & COMPONENT_BLOCK_MISC_HELP), "A self-help signal cannot terminate the remote session")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, scene.far_spot)
	TEST_ASSERT(!(SEND_SIGNAL(scene.user, COMSIG_CARBON_PRE_MISC_HELP, helper) & COMPONENT_BLOCK_MISC_HELP), "A distant helper cannot wake the diver remotely")
	TEST_ASSERT(!QDELETED(entity), "Rejected help preserves the active resident")
	helper.forceMove(get_turf(scene.user))
	TEST_ASSERT(SEND_SIGNAL(scene.user, COMSIG_CARBON_PRE_MISC_HELP, helper) & COMPONENT_BLOCK_MISC_HELP, "Adjacent help owns the safe return instead of ordinary shaking")
	sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(entity), "A helper removes the temporary network resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Help returns the original mind to its own body")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 0, "A controlled help return causes no emergency brain injury")
	examine_list.Cut()
	SEND_SIGNAL(scene.user, COMSIG_PARENT_EXAMINE, helper, examine_list)
	TEST_ASSERT(!findtext(jointext(examine_list, " "), "Нейролинк активен"), "Return unsubscribes the active-dive examination")
	TEST_ASSERT(!(SEND_SIGNAL(scene.user, COMSIG_CARBON_PRE_MISC_HELP, helper) & COMPONENT_BLOCK_MISC_HELP), "Return releases the ordinary help interaction")

/// Damage callbacks use the same emergency policy as a physically severed link.
/datum/unit_test/proc/netrun_assert_body_damage_return(damage_type)
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The body-damage fixture must enter the network")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	SEND_SIGNAL(scene.user, COMSIG_MOB_APPLY_DAMAGE, 4, damage_type)
	TEST_ASSERT(!QDELETED(entity), "Minor damage preserves the established dive threshold")
	SEND_SIGNAL(scene.user, COMSIG_MOB_APPLY_DAMAGE, 5, damage_type)
	sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(entity), "Significant physical damage ends the network resident")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "An emergency returns the same mind to the damaged body")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "A damage-triggered emergency inflicts the common bounded brain injury")
	SEND_SIGNAL(scene.user, COMSIG_MOB_APPLY_DAMAGE, 5, damage_type)
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Released damage subscriptions cannot injure the body twice")

/datum/unit_test/netrun_dive_body_brute_return/Run()
	netrun_assert_body_damage_return(BRUTE)

/datum/unit_test/netrun_dive_body_burn_return/Run()
	netrun_assert_body_damage_return(BURN)

/datum/unit_test/netrun_dive_body_tox_return/Run()
	netrun_assert_body_damage_return(TOX)

/datum/unit_test/netrun_dive_body_oxy_return/Run()
	netrun_assert_body_damage_return(OXY)

/// Actual incremental oxygen damage is visible even when apply_damage is bypassed.
/datum/unit_test/netrun_dive_body_gradual_hypoxia/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	scene.user.adjustOxyLoss(10)
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "A conscious diver may enter with existing oxygen damage")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	entity.dive_link.process_tick(1)
	TEST_ASSERT(!QDELETED(entity), "Normal dive unconsciousness and old oxygen damage do not eject the diver")
	scene.user.adjustOxyLoss(4)
	entity.dive_link.process_tick(1)
	TEST_ASSERT(!QDELETED(entity), "Minor gradual deterioration does not end the dive")
	scene.user.adjustOxyLoss(1)
	entity.dive_link.process_tick(1)
	TEST_ASSERT(QDELETED(entity), "Five actual new oxygen damage triggers the emergency policy")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "Gradual hypoxia returns the original mind")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Gradual hypoxia inflicts exactly one emergency injury")

/// Genuine external paralysis differs from the unconsciousness sustained by the link.
/datum/unit_test/netrun_dive_body_paralysis_return/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The paralysis fixture must enter the network")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	entity.dive_link.process_tick(1)
	TEST_ASSERT(!QDELETED(entity), "Maintaining dive unconsciousness cannot itself trigger an emergency")
	scene.user.Paralyze(2 SECONDS)
	entity.dive_link.process_tick(1)
	TEST_ASSERT(QDELETED(entity), "External paralysis ends the neural session on its next body check")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Paralysis uses the common emergency injury")

/datum/unit_test/netrun_dive_body_death_return/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	scene.authorize()
	TEST_ASSERT(scene.implant.complete_dive(scene.target_node, scene.user), "The death fixture must enter the network")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	var/datum/mind/mind = entity.mind
	scene.user.death()
	var/deadline = world.time + 1 SECONDS
	while(!QDELETED(entity) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(QDELETED(entity), "Death cannot leave a living resident in the network")
	TEST_ASSERT_EQUAL(mind.current, scene.user, "The original mind returns to its dead body")
	TEST_ASSERT_EQUAL(scene.user.stat, DEAD, "The emergency cannot revive a dead diver")
	TEST_ASSERT_EQUAL(scene.user.getOrganLoss(ORGAN_SLOT_BRAIN), 20, "Death follows the same bounded emergency policy")

/// Native ownership survives the real mind transfer, without opening another person's implants.
/datum/unit_test/netrun_dive_native_device_ownership/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/entry = scene.implant.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT(scene.implant.complete_dive(entry, scene.user), "The owner must enter through the installed neural endpoint")
	var/mob/camera/netrun_entity/entity = scene.implant.console.dive_ref?.resolve()
	TEST_ASSERT_EQUAL(netrun_console_owner(entity.console), scene.user, "A live diver must retain the physical owner's identity")
	TEST_ASSERT_EQUAL(scene.user.netrun_owner_access(entity.console), NETRUN_ACCESS_ROOT, "A diver cannot administer the body's cybernetics")
	TEST_ASSERT_EQUAL(scene.implant.netrun_owner_access(entity.console), NETRUN_ACCESS_ROOT, "A diver cannot administer the body's neural implant")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(stranger.netrun_owner_access(entity.console), NETRUN_ACCESS_NONE, "A live body link granted access to a stranger's cybernetics")
	stranger.mind_initialize()
	var/datum/weakref/original_principal = entity.dive_link.personal_principal_ref
	entity.dive_link.personal_principal_ref = WEAKREF(stranger.mind)
	TEST_ASSERT_EQUAL(scene.user.netrun_owner_access(entity.console), NETRUN_ACCESS_NONE, "A changed resident identity inherited another mind's body ownership")
	entity.dive_link.personal_principal_ref = original_principal
	entity.dive_link.release_body()
	TEST_ASSERT_EQUAL(scene.user.netrun_owner_access(entity.console), NETRUN_ACCESS_NONE, "A released body link retained native ownership")
	entity.mind.transfer_to(scene.user)
	qdel(entity)

/// Local network silhouettes remain above machine blindness and include authorized device state.
/datum/unit_test/netrun_entity_neural_node_marks/Run()
	var/datum/netrun_entity_contact_scene/scene = allocate(/datum/netrun_entity_contact_scene, run_loc_floor_bottom_left)
	var/mob/camera/netrun_entity/entity = scene.recipient
	var/obj/item/radio/intercom/intercom = allocate(/obj/item/radio/intercom, get_turf(entity))
	intercom.name = "Test intercom <node>"
	intercom.broadcasting = TRUE
	intercom.listening = FALSE
	var/datum/component/netrun_node/node = intercom.GetComponent(/datum/component/netrun_node)
	entity.console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	var/datum/component/neural_interface/interface = entity.GetComponent(/datum/component/neural_interface)
	var/datum/neural_monitor/netrun_vision/vision
	for(var/datum/neural_monitor/netrun_vision/candidate in interface.monitors)
		vision = candidate
		break
	TEST_ASSERT_NOTNULL(vision, "A resident process has no network vision monitor")
	TEST_ASSERT_NULL(entity.current_vision_target(), "The fixture must have no physical optical feed")
	TEST_ASSERT(vision.update_marks(entity.console, get_turf(entity)), "Network vision must work without a physical optical feed")
	var/datum/neural_interface_module/image_highlight/images = interface.modules["image"]
	var/datum/image_holder_data/mark = images.get_image_data_entry_by_key("\ref[vision]:\ref[node]:NETVISION")
	TEST_ASSERT_NOTNULL(mark, "The nearby intercom was hidden by a non-optical machine host")
	TEST_ASSERT_EQUAL(mark.overlay.plane, FOV_VISUAL_PLANE, "Network marks were placed underneath the blindness fullscreen")
	TEST_ASSERT_EQUAL(mark.font_size, 12, "Network labels must use the readable 12-point HUD font")
	TEST_ASSERT_EQUAL(mark.screen_text.maptext_height, 40, "A compact two-line label must not reserve a tall status panel")
	TEST_ASSERT(findtext(mark.screen_text.maptext, "Test intercom &lt;node&gt;"), "A network mark omitted or failed to escape its device name")
	TEST_ASSERT(findtext(mark.screen_text.maptext, "MIC ON / SPK OFF"), "The intercom mark omitted its compact microphone/speaker state")
	TEST_ASSERT(!findtext(mark.screen_text.maptext, node.address) && !findtext(mark.screen_text.maptext, "USER"), "A compact mark must not repeat the address or access level")
	TEST_ASSERT_EQUAL(length(splittext(vision.node_text(node, NETRUN_ACCESS_ROOT), "<br>")), 2, "An authorized label must contain only the name and one status line")
	mark.toggle()
	TEST_ASSERT(!mark.enabled, "The fixture must disable a mark as the shared per-tile cycle does")
	vision.update_marks(entity.console, get_turf(entity))
	mark = images.get_image_data_entry_by_key("\ref[vision]:\ref[node]:NETVISION")
	TEST_ASSERT(!mark.enabled && mark.overlay.alpha == 0, "Refreshing a disabled mark broke per-tile label cycling")
	var/locked_text = vision.node_text(node, NETRUN_ACCESS_NONE)
	TEST_ASSERT_EQUAL(locked_text, "Test intercom &lt;node&gt;", "A locked node must display only its escaped name")
	var/guest_text = vision.node_text(node, NETRUN_ACCESS_GUEST)
	TEST_ASSERT_EQUAL(guest_text, locked_text, "Guest discovery leaked USER-only device state")
	intercom.name = "ABCDEFGHIJKLMNOPQRSTUVWXYZ extra device details"
	TEST_ASSERT_EQUAL(vision.node_text(node, NETRUN_ACCESS_GUEST), "ABCDEFGHIJKLMNOPQRSTUVWX", "Long device labels must be clipped to 24 display characters")
	intercom.name = "First\nSecond\tThird"
	TEST_ASSERT_EQUAL(vision.node_text(node, NETRUN_ACCESS_GUEST), "First Second Third", "A device name must not inject extra HUD lines")
	intercom.on = FALSE
	TEST_ASSERT_EQUAL(vision.node_text(node, NETRUN_ACCESS_NONE), "First Second Third<br>OFFLINE", "An unavailable node must use one compact public OFFLINE line")
	TEST_ASSERT_EQUAL(vision.node_text(scene.target_node, NETRUN_ACCESS_USER), netrun_neural_text(scene.target_node.get_name(), 24), "Devices without a compact status must not dump a generic machine report")
