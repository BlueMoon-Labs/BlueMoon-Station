/// Удаление моба удаляет его vore-панель: панель держит хозяина в host.
/datum/unit_test/vore_panel_released_with_mob/Run()
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human)
	host.vorePanel = new(host)
	var/datum/vore_look/panel = host.vorePanel
	qdel(host)
	TEST_ASSERT(QDELETED(panel), "vore-панель пережила удаление моба")
	TEST_ASSERT_NULL(panel.host, "vore-панель держит удалённого моба")

/// Щит, разбитый уроном или ЭМИ, уходит из списка своего генератора.
/datum/unit_test/shieldgen_forgets_destroyed_shield/Run()
	var/obj/machinery/shieldgen/generator = allocate(/obj/machinery/shieldgen)
	var/obj/structure/emergency_shield/shield = generator.deploy_shield(run_loc_floor_top_right)
	TEST_ASSERT(shield in generator.deployed_shields, "щит не попал в список генератора")
	qdel(shield)
	TEST_ASSERT(!(shield in generator.deployed_shields), "удалённый щит остался в списке генератора")

/// Удаление одной половины портальной пары отпускает обратную ссылку у второй.
/datum/unit_test/portal_pair_releases_partner/Run()
	var/obj/item/clothing/underwear/briefs/panties/portalpanties/panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/portallight/light = allocate(/obj/item/portallight)
	panties.set_private_pair(light)
	light.portalunderwear = panties
	qdel(panties)
	TEST_ASSERT_NULL(light.private_pair, "фонарик держит удалённые трусики как пару")
	TEST_ASSERT_NULL(light.portalunderwear, "фонарик держит удалённые трусики как подключение")

	var/obj/item/clothing/underwear/briefs/panties/portalpanties/other_panties = allocate(/obj/item/clothing/underwear/briefs/panties/portalpanties)
	var/obj/item/portallight/other_light = allocate(/obj/item/portallight)
	other_light.set_private_pair(other_panties)
	other_panties.portallight += other_light
	qdel(other_light)
	TEST_ASSERT_NULL(other_panties.private_pair, "трусики держат удалённый фонарик как пару")
	TEST_ASSERT(!(other_light in other_panties.portallight), "трусики держат удалённый фонарик в списке подключений")

/// Машина телекома, найденная консолью, уходит из её списков при удалении.
/datum/unit_test/telecomms_consoles_forget_destroyed_machine/Run()
	var/obj/machinery/computer/telecomms/monitor/monitor = allocate(/obj/machinery/computer/telecomms/monitor)
	var/obj/machinery/computer/message_monitor/message_console = allocate(/obj/machinery/computer/message_monitor)
	var/obj/machinery/telecomms/message_server/server = allocate(/obj/machinery/telecomms/message_server)
	monitor.machinelist += server
	monitor.SelectedMachine = server
	message_console.machinelist += server
	message_console.linkedServer = server
	qdel(server)
	TEST_ASSERT(!(server in monitor.machinelist), "монитор телекома держит удалённую машину в списке")
	TEST_ASSERT_NULL(monitor.SelectedMachine, "монитор телекома держит удалённую машину выбранной")
	TEST_ASSERT(!(server in message_console.machinelist), "консоль сообщений держит удалённый сервер в списке")
	TEST_ASSERT_NULL(message_console.linkedServer, "консоль сообщений держит удалённый сервер подключённым")

/// Второй предмет в руках не держит счётчик, который уже показывает первый.
/datum/unit_test/ammo_hud_second_item_skips_shown_counter/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/hud_path = user.hud_type
	user.set_hud_used(new hud_path(user))
	var/obj/item/weldingtool/first = allocate(/obj/item/weldingtool)
	var/obj/item/weldingtool/second = allocate(/obj/item/weldingtool)
	TEST_ASSERT(user.put_in_hands(first), "первый предмет не лёг в руку")
	var/datum/component/ammo_hud/first_hud = first.GetComponent(/datum/component/ammo_hud)
	TEST_ASSERT_EQUAL(first_hud.hud, user.hud_used.ammo_counter, "первый предмет не включил счётчик")
	TEST_ASSERT(user.put_in_hands(second), "второй предмет не лёг в руку")
	var/datum/component/ammo_hud/second_hud = second.GetComponent(/datum/component/ammo_hud)
	TEST_ASSERT_NULL(second_hud.hud, "второй предмет держит чужой счётчик без подписки на его удаление")
	TEST_ASSERT(user.dropItemToGround(first), "первый предмет не выпал из руки")
	TEST_ASSERT_EQUAL(second_hud.hud, user.hud_used.ammo_counter, "счётчик не перешёл к предмету, оставшемуся в руке")
	TEST_ASSERT(second_hud.hud.on, "перешедший счётчик не включён")

/// В строке утечки интерфейс tgui называется по имени окна.
/datum/unit_test/gc_leak_line_names_tgui_interface/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/source = allocate(/obj/item)
	var/datum/tgui/ui = new(user, source, "UnitTestWindow")
	var/display_name = SSgarbage.leaked_display_name(ui)
	qdel(ui)
	TEST_ASSERT_EQUAL(display_name, " \"UnitTestWindow\"", "строка утечки не называет интерфейс")
