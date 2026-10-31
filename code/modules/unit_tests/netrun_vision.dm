/// Ordinary network devices and organic eyes never become accidental viewpoints.
/datum/unit_test/netrun_vision_source_defaults/Run()
	var/obj/item/device = allocate(/obj/item)
	TEST_ASSERT(!device.netrun_view_capable(), "An ordinary device advertised an optical feed")
	TEST_ASSERT_NULL(device.netrun_view_target(), "An ordinary device returned a viewpoint")
	var/list/settings = device.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["see_in_dark"], 2, "The default optical source has elevated night vision")
	TEST_ASSERT_EQUAL(settings["sight"], 0, "The default optical source has elevated sight flags")
	TEST_ASSERT_EQUAL(settings["see_invisible"], SEE_INVISIBLE_LIVING, "The default optical source sees invisible entities")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!user.netrun_view_capable(), "Organic eyes advertised a cybernetic feed")
	var/obj/item/organ/cyberimp/eyes/hud/medical/implant = allocate(/obj/item/organ/cyberimp/eyes/hud/medical)
	implant.Insert(user, TRUE)
	TEST_ASSERT(!user.netrun_view_capable(), "A separate HUD implant exposed unrelated organic eyes")
	TEST_ASSERT_NULL(user.netrun_view_target(), "Organic eyes supplied an image through a non-optical implant")

/// Recording switches, EMP and node lockouts all invalidate a camera stream.
/datum/unit_test/netrun_vision_camera_source/Run()
	var/obj/machinery/camera/camera = allocate(/obj/machinery/camera)
	var/datum/component/netrun_node/node = camera.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "The camera is missing its network node")
	TEST_ASSERT(camera.netrun_view_capable(), "The camera did not advertise its optical capability")
	TEST_ASSERT_EQUAL(camera.netrun_view_target(), camera, "A working camera did not publish its viewpoint")
	var/list/settings = camera.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["see_in_dark"], 7, "The camera feed lost its configured darkness range")
	TEST_ASSERT_EQUAL(settings["sight"], 0, "A normal camera gained X-ray sight")
	camera.status = FALSE
	TEST_ASSERT_NULL(camera.netrun_view_target(), "A switched-off camera still supplied an image")
	camera.status = TRUE
	camera.set_machine_stat(camera.machine_stat | EMPED)
	TEST_ASSERT_NULL(camera.netrun_view_target(), "An EMP-disabled camera still supplied an image")
	camera.set_machine_stat(camera.machine_stat & ~EMPED)
	node.offline_until = world.time + 10 SECONDS
	TEST_ASSERT_NULL(camera.netrun_view_target(), "A rebooting camera still supplied an image")
	node.offline_until = 0
	TEST_ASSERT_EQUAL(camera.netrun_view_target(), camera, "The camera did not recover its feed after the lockout")
	var/obj/machinery/camera/xray/xray_camera = allocate(/obj/machinery/camera/xray)
	settings = xray_camera.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["sight"], SEE_TURFS | SEE_MOBS | SEE_OBJS, "The source ignored the camera's real X-ray upgrade")
	TEST_ASSERT_EQUAL(settings["see_invisible"], SEE_INVISIBLE_LIVING, "An upgraded camera incorrectly exposed ghosts")

/// Cybernetic feeds follow the installed eyes and their current modes, not the body's other senses.
/datum/unit_test/netrun_vision_cybernetic_eyes/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/brain/netlink/uplink = allocate(/obj/item/organ/cyberimp/brain/netlink)
	uplink.Insert(user, TRUE)
	var/obj/item/organ/eyes/robotic/toggled/xray/eyes = allocate(/obj/item/organ/eyes/robotic/toggled/xray)
	eyes.Insert(user, TRUE)
	TEST_ASSERT_EQUAL(user.getorganslot(ORGAN_SLOT_EYES), eyes, "The real eye implantation failed")
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/netrun_node), "Implantation did not provide the wearer's existing cybernetics node")
	TEST_ASSERT(user.netrun_view_capable(), "Installed cybernetic eyes did not advertise their feed")
	TEST_ASSERT_EQUAL(user.netrun_view_target(), user, "Working cybernetic eyes did not publish their wearer")
	var/list/settings = user.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["sight"], eyes.sight_flags, "The stream did not use its physical eye's sight flags")
	TEST_ASSERT_EQUAL(settings["see_in_dark"], eyes.see_in_dark, "The stream did not use its physical eye's darkness range")
	eyes.toggle(silent = TRUE)
	settings = user.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["sight"], 0, "Turning off the eye's X-ray mode left that mode in the stream")
	user.SetUnconscious(10 SECONDS)
	TEST_ASSERT_EQUAL(user.netrun_view_target(), user, "An intact optical sensor incorrectly depended on its wearer's consciousness")
	eyes.applyOrganDamage(eyes.maxHealth)
	TEST_ASSERT_NULL(user.netrun_view_target(), "Failed cybernetic eyes still supplied an image")
	eyes.setOrganDamage(0)
	TEST_ASSERT_EQUAL(user.netrun_view_target(), user, "Repairing the actual eyes did not restore their feed")
	eyes.netrun_suppressed_until = world.time + 10 SECONDS
	TEST_ASSERT_NULL(user.netrun_view_target(), "Suppressed eye hardware still supplied an image")
	eyes.netrun_suppressed_until = 0
	user.death(FALSE)
	TEST_ASSERT_NULL(user.netrun_view_target(), "Cybernetic eyes continued streaming from a dead wearer")
	eyes.Remove(TRUE)
	TEST_ASSERT(!user.netrun_view_capable(), "Removing cybernetic eyes left a stale optical capability")
	TEST_ASSERT_NULL(user.netrun_view_target(), "Removed cybernetic eyes still published their former owner")

/// Hacked HUD lenses must be worn: possession and ROOT access alone never create an image.
/datum/unit_test/netrun_vision_hud_firmware_and_wearer/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/glasses/hud/health/night/glasses = allocate(/obj/item/clothing/glasses/hud/health/night)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, user)
	var/datum/component/netrun_node/node = glasses.GetComponent(/datum/component/netrun_node)
	TEST_ASSERT_NOTNULL(node, "The HUD glasses have no separate network address")
	TEST_ASSERT_EQUAL(length(node.required_access), 0, "HUD ownership accidentally depends on department access")
	TEST_ASSERT_EQUAL(glasses.netrun_owner_access(console), NETRUN_ACCESS_NONE, "Being next to glasses granted ownership")
	var/datum/netrun_api/api = SSnetrun.get_api(glasses)
	TEST_ASSERT(api?.allow_emag, "The HUD firmware cannot use the existing bypass mechanism")
	TEST_ASSERT("firmware" in node.all_command_ids(), "The optic node did not publish the firmware command")
	TEST_ASSERT_NULL(glasses.netrun_view_target(), "Unhacked glasses published a floor viewpoint")
	TEST_ASSERT(user.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, disable_warning = TRUE), "The actual HUD equip operation failed")
	TEST_ASSERT_EQUAL(glasses.netrun_owner_access(console), NETRUN_ACCESS_ROOT, "The wearer did not own their glasses")
	TEST_ASSERT_NULL(glasses.netrun_view_target(), "Wearing secure HUD glasses skipped the firmware requirement")
	world.PushUsr(user, CALLBACK(glasses, TYPE_PROC_REF(/atom, emag_act), user))
	TEST_ASSERT(glasses.obj_flags & EMAGGED, "The native emag operation did not bypass the HUD firmware")
	TEST_ASSERT_EQUAL(glasses.netrun_view_target(), user, "Hacked, worn glasses did not publish their wearer's viewpoint")
	var/list/settings = glasses.netrun_view_settings()
	TEST_ASSERT_EQUAL(settings["see_in_dark"], glasses.darkness_view, "The feed ignored the glasses' night vision")
	TEST_ASSERT_EQUAL(settings["sight"], glasses.vision_flags, "The feed acquired vision beyond the lens itself")
	TEST_ASSERT_EQUAL(settings["see_invisible"], glasses.invis_view, "The feed acquired visibility beyond the lens itself")
	node.offline_until = world.time + 10 SECONDS
	TEST_ASSERT_NULL(glasses.netrun_view_target(), "A rebooting optical node still supplied an image")
	node.offline_until = 0
	TEST_ASSERT(user.dropItemToGround(glasses), "The actual HUD drop operation failed")
	TEST_ASSERT_NULL(user.glasses, "Dropping the glasses retained the worn slot")
	TEST_ASSERT_NULL(glasses.netrun_view_target(), "A dropped, hacked HUD retained its previous wearer's image")
	TEST_ASSERT_EQUAL(glasses.netrun_owner_access(console), NETRUN_ACCESS_NONE, "Dropped glasses retained their previous owner")
	TEST_ASSERT(user.put_in_hands(glasses), "The wearer could not pick their glasses up")
	TEST_ASSERT_EQUAL(glasses.netrun_owner_access(console), NETRUN_ACCESS_ROOT, "Held glasses did not recognize their owner")
	TEST_ASSERT_NULL(glasses.netrun_view_target(), "Holding hacked glasses incorrectly counted as wearing them")

/// An explicitly watched source must survive processing without moving the resident process.
/datum/unit_test/netrun_vision_explicit_stream_persists/Run()
	netrun_connected_test_area()
	var/obj/machinery/camera/host_camera = allocate(/obj/machinery/camera)
	var/obj/machinery/camera/remote_camera = allocate(/obj/machinery/camera)
	var/datum/component/netrun_node/host_node = host_camera.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/remote_node = remote_camera.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(host_node)
	entity.console.operator = entity
	entity.console.access_session.node_access[host_node.address] = NETRUN_ACCESS_USER
	entity.console.access_session.node_access[remote_node.address] = NETRUN_ACCESS_USER
	entity.console.remote_session.watch_node = remote_node
	entity.console.remote_session.watch_viewer = entity
	TEST_ASSERT_EQUAL(entity.current_vision_target(), remote_camera, "An explicit stream did not take priority over the host's camera")
	for(var/i in 1 to 3)
		// Exercise entity synchronization without a fabricated BYOND client/perspective.
		entity.process_tick(1)
		TEST_ASSERT_EQUAL(entity.current_vision_target(), remote_camera, "Processing bounced an explicit stream back to the host")
		TEST_ASSERT_EQUAL(entity.host_node, host_node, "Watching another stream moved the resident process into its source")
	remote_camera.status = FALSE
	entity.console.process_tick(1)
	TEST_ASSERT_NULL(entity.console.remote_session.watch_node, "An invalid camera stream retained its active watch session")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), host_camera, "A disabled explicit source did not fall back to the accessible host camera")
	TEST_ASSERT_EQUAL(entity.host_node, host_node, "Disabling a remote feed moved the process out of its host")
	entity.leave_node()

/// Changes in real equipment and organs invalidate an already selected source on the next tick.
/datum/unit_test/netrun_vision_equipment_stream_invalidation/Run()
	netrun_connected_test_area()
	var/obj/machinery/camera/host_camera = allocate(/obj/machinery/camera)
	var/datum/component/netrun_node/host_node = host_camera.GetComponent(/datum/component/netrun_node)
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/brain/netlink/uplink = allocate(/obj/item/organ/cyberimp/brain/netlink)
	uplink.Insert(wearer, TRUE)
	var/obj/item/organ/eyes/robotic/eyes = allocate(/obj/item/organ/eyes/robotic)
	eyes.Insert(wearer, TRUE)
	var/datum/component/netrun_node/cyber_node = wearer.GetComponent(/datum/component/netrun_node)
	var/obj/item/clothing/glasses/hud/diagnostic/glasses = allocate(/obj/item/clothing/glasses/hud/diagnostic)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, disable_warning = TRUE), "The real equipment stream setup failed")
	world.PushUsr(wearer, CALLBACK(glasses, TYPE_PROC_REF(/atom, emag_act), wearer))
	var/datum/component/netrun_node/glasses_node = glasses.GetComponent(/datum/component/netrun_node)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(host_node)
	entity.console.operator = entity
	entity.console.access_session.node_access[host_node.address] = NETRUN_ACCESS_USER
	entity.console.access_session.node_access[glasses_node.address] = NETRUN_ACCESS_USER
	entity.console.access_session.node_access[cyber_node.address] = NETRUN_ACCESS_USER
	entity.console.remote_session.watch_viewer = entity
	entity.console.remote_session.watch_node = glasses_node
	TEST_ASSERT_EQUAL(entity.current_vision_target(), wearer, "A selected hacked HUD stream did not resolve its wearer")
	TEST_ASSERT(wearer.dropItemToGround(glasses), "The actual HUD drop operation failed")
	entity.console.process_tick(1)
	TEST_ASSERT_NULL(entity.console.remote_session.watch_node, "Dropping a HUD did not close its stream")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), host_camera, "Dropping the HUD did not restore the process's host view")
	entity.console.remote_session.watch_viewer = entity
	entity.console.remote_session.watch_node = cyber_node
	TEST_ASSERT_EQUAL(entity.current_vision_target(), wearer, "The process did not resolve the cybernetic eyes source")
	eyes.Remove(TRUE)
	entity.console.process_tick(1)
	TEST_ASSERT_NULL(entity.console.remote_session.watch_node, "Removing the actual eyes did not close their stream")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), host_camera, "Removing the eyes did not restore the process's host view")
	TEST_ASSERT_EQUAL(entity.host_node, host_node, "Invalidating equipment moved the resident process")
	entity.leave_node()

/// The native remote-sight hook replaces a living viewer's own senses with the lens' senses.
/datum/unit_test/netrun_vision_living_remote_eye/Run()
	netrun_connected_test_area()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/obj/item/organ/cyberimp/brain/netlink/uplink = allocate(/obj/item/organ/cyberimp/brain/netlink)
	uplink.Insert(viewer, TRUE)
	var/obj/item/organ/eyes/robotic/toggled/xray/viewer_eyes = allocate(/obj/item/organ/eyes/robotic/toggled/xray)
	viewer_eyes.Insert(viewer, TRUE)
	var/obj/machinery/camera/camera = allocate(/obj/machinery/camera)
	var/datum/component/netrun_node/camera_node = camera.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, viewer)
	console.operator = viewer
	console.connection.wireless = FALSE
	console.access_session.node_access[camera_node.address] = NETRUN_ACCESS_USER
	console.remote_session.watch_viewer = viewer
	console.remote_session.watch_node = camera_node
	var/obj/effect/netrun_view_eye/eye = allocate(/obj/effect/netrun_view_eye, get_turf(camera), console)
	// Native update_sight exits for clientless test mobs. Seed the values their real eyes contribute.
	viewer.sight = viewer_eyes.sight_flags
	viewer.see_in_dark = viewer_eyes.see_in_dark
	viewer.see_invisible = 100
	TEST_ASSERT(viewer.sight & SEE_TURFS, "The test viewer does not have its implanted X-ray senses")
	TEST_ASSERT(eye.update_remote_sight(viewer), "The network viewpoint did not handle the native remote-sight hook")
	TEST_ASSERT_EQUAL(viewer.sight, 0, "A normal camera inherited X-ray vision from its viewer")
	TEST_ASSERT_EQUAL(viewer.see_in_dark, 7, "The normal camera did not replace the viewer's own darkness range")
	TEST_ASSERT_EQUAL(viewer.see_invisible, SEE_INVISIBLE_LIVING, "The normal camera inherited the viewer's invisible visibility")
	camera.view_range = camera.short_range
	eye.get_remote_view_fullscreens(viewer)
	TEST_ASSERT_NOTNULL(viewer.fullscreens["remote_view"], "The proxy did not delegate the real camera's impaired-view overlay")
	viewer.clear_fullscreen("remote_view", 0)

	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/glasses/hud/health/night/glasses = allocate(/obj/item/clothing/glasses/hud/health/night)
	TEST_ASSERT(wearer.equip_to_slot_if_possible(glasses, ITEM_SLOT_EYES, disable_warning = TRUE), "The night optics could not be worn")
	world.PushUsr(wearer, CALLBACK(glasses, TYPE_PROC_REF(/atom, emag_act), wearer))
	var/datum/component/netrun_node/glasses_node = glasses.GetComponent(/datum/component/netrun_node)
	console.access_session.node_access[glasses_node.address] = NETRUN_ACCESS_USER
	console.remote_session.watch_node = glasses_node
	TEST_ASSERT(eye.update_remote_sight(viewer), "The proxy did not handle a HUD optical source")
	TEST_ASSERT_EQUAL(viewer.see_in_dark, glasses.darkness_view, "The native hook lost the selected source's night vision")
	TEST_ASSERT_EQUAL(viewer.sight, glasses.vision_flags, "The native hook combined the viewer's X-ray eyes with another lens")

	console.remote_session.watch_node = camera_node
	camera.status = FALSE
	viewer.sight = viewer_eyes.sight_flags
	viewer.see_in_dark = viewer_eyes.see_in_dark
	viewer.see_invisible = 100
	TEST_ASSERT(eye.update_remote_sight(viewer), "An invalid source fell through to the viewer's own senses")
	TEST_ASSERT_EQUAL(viewer.sight, 0, "An invalid feed leaked the viewer's X-ray sight")
	TEST_ASSERT_EQUAL(viewer.see_in_dark, 2, "An invalid feed leaked the viewer's night vision")
	TEST_ASSERT_EQUAL(viewer.see_invisible, SEE_INVISIBLE_LIVING, "An invalid feed leaked invisible entities")
	eye.get_remote_view_fullscreens(viewer)
	TEST_ASSERT_NULL(viewer.fullscreens["remote_view"], "An invalid feed delegated the camera's overlay")
	camera.status = TRUE
	console.remote_session.watch_viewer = wearer
	viewer.sight = viewer_eyes.sight_flags
	eye.update_remote_sight(viewer)
	TEST_ASSERT_EQUAL(viewer.sight, 0, "A different viewer could reuse someone else's optical session")

/// Retiring another console must never release the viewer's currently owned optical session.
/datum/unit_test/netrun_vision_console_session_ownership/Run()
	netrun_connected_test_area()
	var/obj/machinery/camera/host_camera = allocate(/obj/machinery/camera)
	var/obj/machinery/camera/first_camera = allocate(/obj/machinery/camera)
	var/obj/machinery/camera/second_camera = allocate(/obj/machinery/camera)
	var/datum/component/netrun_node/host_node = host_camera.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/first_node = first_camera.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/second_node = second_camera.GetComponent(/datum/component/netrun_node)
	var/obj/machinery/computer/netrun_terminal/first_terminal = allocate(/obj/machinery/computer/netrun_terminal)
	var/obj/machinery/computer/netrun_terminal/second_terminal = allocate(/obj/machinery/computer/netrun_terminal)
	var/datum/netrun_console/first_console = first_terminal.console
	var/datum/netrun_console/second_console = second_terminal.console
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(host_node)
	entity.console.operator = entity
	entity.console.access_session.node_access[host_node.address] = NETRUN_ACCESS_USER
	first_console.operator = entity
	first_console.access_session.node_access[first_node.address] = NETRUN_ACCESS_USER
	first_console.remote_session.watch_node = first_node
	first_console.remote_session.watch_viewer = entity
	first_console.remote_session.watch_eye = new(get_turf(first_camera), first_console)
	var/obj/effect/netrun_view_eye/first_eye = first_console.remote_session.watch_eye
	second_console.operator = entity
	second_console.access_session.node_access[second_node.address] = NETRUN_ACCESS_USER
	second_console.remote_session.watch_node = second_node
	second_console.remote_session.watch_viewer = entity
	second_console.remote_session.watch_eye = new(get_turf(second_camera), second_console)
	var/obj/effect/netrun_view_eye/second_eye = second_console.remote_session.watch_eye
	entity.netrun_watch_console = second_console
	TEST_ASSERT_EQUAL(entity.current_vision_target(), second_camera, "The active console did not own the entity's current optical target")
	first_console.stop_watch()
	TEST_ASSERT(QDELETED(first_eye), "Stopping a retired console leaked its optical proxy")
	TEST_ASSERT_EQUAL(entity.netrun_watch_console, second_console, "Stopping the first console cleared ownership of the second")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), second_camera, "Stopping the first console bounced the second stream")
	TEST_ASSERT(!QDELETED(second_eye), "Stopping a retired console deleted the active proxy")

	// Reproduce a late Destroy with stale watch state after another console has taken ownership.
	first_console.remote_session.watch_node = first_node
	first_console.remote_session.watch_viewer = entity
	first_console.remote_session.watch_eye = new(get_turf(first_camera), first_console)
	first_eye = first_console.remote_session.watch_eye
	QDEL_NULL(first_terminal.console)
	TEST_ASSERT(QDELETED(first_console) && QDELETED(first_eye), "Destroying a retired console leaked its session or proxy")
	TEST_ASSERT_EQUAL(entity.netrun_watch_console, second_console, "Destroying a retired console cleared ownership of the active session")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), second_camera, "Destroying a retired console changed the active stream")
	TEST_ASSERT_EQUAL(second_console.remote_session.watch_eye, second_eye, "Destroying a retired console replaced the active proxy")
	second_console.stop_watch()
	TEST_ASSERT(QDELETED(second_eye), "Stopping the active session leaked its proxy")
	TEST_ASSERT_NULL(entity.netrun_watch_console, "Stopping the active session did not clear its ownership pointer")
	TEST_ASSERT_NULL(second_console.remote_session.watch_node, "Stopping the active session retained its source")
	TEST_ASSERT_EQUAL(entity.current_vision_target(), host_camera, "Stopping the final stream did not fall back to the entity's own accessible host")
	TEST_ASSERT_EQUAL(entity.host_node, host_node, "Switching optical session ownership moved the resident process")
	entity.leave_node()
