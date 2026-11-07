/// Все стейты, на которые ссылаются типы экономики, есть в их файлах иконок.
/datum/unit_test/economy_icon_states

/datum/unit_test/economy_icon_states/proc/check_states(icon_file, list/states, owner)
	var/list/present = icon_states(icon_file)
	for(var/state in states)
		TEST_ASSERT(state in present, "[owner]: нет стейта [state] в [icon_file]")

/datum/unit_test/economy_icon_states/proc/check_inhand(obj/item/item_type)
	check_states(initial(item_type.lefthand_file), list(initial(item_type.item_state)), item_type)
	check_states(initial(item_type.righthand_file), list(initial(item_type.item_state)), item_type)

/datum/unit_test/economy_icon_states/Run()
	for(var/obj/machinery/cash_register/register_type as anything in typesof(/obj/machinery/cash_register))
		var/skin = initial(register_type.skin)
		check_states(initial(register_type.icon), list(skin, "[skin]_open", "[skin]_paid", "[skin]_print", "[skin]_off", "[skin]_panel"), register_type)
	var/obj/machinery/power/export_node/node = /obj/machinery/power/export_node
	check_states(initial(node.icon), list("node", "node_on_1", "node_on_2", "node_on_3", "node_overload", "node_off", "node_panel", "node_terminal", "node_on_1_glow", "node_on_2_glow", "node_on_3_glow", "node_overload_glow"), node)
	var/obj/machinery/evidence_locker/locker = /obj/machinery/evidence_locker
	check_states(initial(locker.icon), list("locker", "locker_accept", "locker_handover", "locker_locked", "locker_broken"), locker)
	var/obj/machinery/computer/stock_terminal/terminal = /obj/machinery/computer/stock_terminal
	check_states(initial(terminal.icon), list("terminal", "terminal_ticker", "terminal_up", "terminal_down", "terminal_off", "terminal_broken"), terminal)
	var/obj/structure/sign/ticker_board/board = /obj/structure/sign/ticker_board
	check_states(initial(board.icon), list("board", "board_halt", "board_event"), board)
	var/obj/item/sign/ticker_board/board_item = /obj/item/sign/ticker_board
	check_states(initial(board_item.icon), list(initial(board_item.icon_state)), board_item)
	var/list/items = list(
		/obj/item/card_skimmer = list("skimmer", "skimmer_loaded"),
		/obj/item/insider_pager = list("pager", "pager_alert"),
		/obj/item/export_manifest = list("manifest", "manifest_special"),
		/obj/item/anon_account_card = list("anon_card"),
		/obj/item/press_release_kit = list("press_release"),
		/obj/item/econ_receipt = list("receipt"),
	)
	for(var/obj/item/item_type as anything in items)
		check_states(initial(item_type.icon), items[item_type] + initial(item_type.icon_state), item_type)
		check_inhand(item_type)
	var/obj/item/econ_receipt/receipt = /obj/item/econ_receipt
	check_states(initial(receipt.icon), list(initial(receipt.icon_state)), receipt)
	check_inhand(receipt)
	var/list/screens = list("screen_any")
	var/list/labels = list("label_special")
	for(var/id in SSeconomy.departments)
		screens += "screen_[lowertext(id)]"
		labels += "label_[lowertext(id)]"
	check_states('icons/obj/machines/economy/department_console.dmi', screens, /obj/machinery/computer/department_budget)
	check_states('icons/obj/economy/crate_labels.dmi', labels, /obj/item/export_manifest)

/// У каждой программы экономики свой экран, и он есть у планшета, ноутбука и консоли.
/datum/unit_test/economy_program_screens/Run()
	var/list/programs = list(
		/datum/computer_file/program/wallet,
		/datum/computer_file/program/stock_exchange,
		/datum/computer_file/program/department_budget,
		/datum/computer_file/program/treasury,
		/datum/computer_file/program/financial_audit,
		/datum/computer_file/program/cargo_orders,
	)
	var/list/seen = list()
	for(var/datum/computer_file/program/program_type as anything in programs)
		var/screen = initial(program_type.program_icon_state)
		TEST_ASSERT(!seen[screen], "[program_type] делит экран [screen] с [seen[screen]]")
		seen[screen] = program_type
		for(var/icon_file in list('icons/obj/modular_tablet.dmi', 'icons/obj/modular_laptop.dmi', 'icons/obj/modular_console.dmi'))
			TEST_ASSERT(screen in icon_states(icon_file), "Нет экрана [screen] программы [program_type] в [icon_file]")

/// Иконка оверлея с этим стейтом среди наложенных на атом сейчас; TRUE для строкового оверлея, null - нет такого.
/datum/unit_test/proc/econ_overlay_icon(atom/target, state)
	for(var/overlay in islist(target.managed_overlays) ? target.managed_overlays : list(target.managed_overlays))
		if(overlay == state)
			return TRUE
		if(isappearance(overlay) || istype(overlay, /mutable_appearance))
			var/mutable_appearance/appearance = overlay
			if(appearance.icon_state == state)
				return appearance.icon || TRUE

/// Консоль отдела показывает экран своего отдела, узел - уровень отбора и клемму, пока стоит на кабеле, ящик - бирку накладной.
/datum/unit_test/economy_icon_overlays/Run()
	var/obj/machinery/computer/department_budget/console = allocate(/obj/machinery/computer/department_budget/cargo)
	console.set_machine_stat(console.machine_stat & ~(NOPOWER|BROKEN))
	console.update_appearance()
	var/screen_icon = econ_overlay_icon(console, "screen_car")
	TEST_ASSERT(screen_icon, "Консоль бюджета снабжения показывает экран снабжения")
	if(screen_icon)
		TEST_ASSERT("screen_car" in icon_states(screen_icon == TRUE ? console.icon : screen_icon), "Экран снабжения есть в своём файле")

	var/obj/machinery/power/export_node/node = allocate(/obj/machinery/power/export_node/econ_test_station, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(node.icon_state, "node_off", "Выключенный узел")
	var/obj/structure/cable/cable = allocate(/obj/structure/cable, run_loc_floor_bottom_left)
	var/datum/powernet/grid = new
	SSmachines.powernets -= grid
	propagate_network(cable, grid)
	node.connect_to_network()
	node.toggle()
	TEST_ASSERT_EQUAL(node.icon_state, "node", "Включённый узел без отбора")
	TEST_ASSERT(econ_overlay_icon(node, "node_terminal"), "Узел на кабеле показывает клемму")
	node.set_target_kw(SSeconomy.settings.power_export_max_kw)
	TEST_ASSERT_EQUAL(node.icon_state, "node_on_3", "Полный отбор - третий уровень")
	node.set_target_kw(SSeconomy.settings.power_export_step_kw)
	TEST_ASSERT_EQUAL(node.icon_state, "node_on_1", "Малый отбор - первый уровень")
	COOLDOWN_START(node, spark_cooldown, 1 MINUTES)
	node.sell_surplus(grid)
	TEST_ASSERT_EQUAL(node.icon_state, "node_overload", "Отбор без излишка - перегрузка")
	node.set_target_kw(0)
	node.sell_surplus(grid)
	TEST_ASSERT(!node.overloaded, "Узел без отбора не остаётся перегруженным")
	node.set_target_kw(SSeconomy.settings.power_export_step_kw)
	node.sell_surplus(grid)
	qdel(cable)
	TEST_ASSERT_NULL(node.powernet, "Кабель перерезан - узел без сети")
	TEST_ASSERT_EQUAL(node.icon_state, "node", "Без сети узел не светит отбором и перегрузкой")
	TEST_ASSERT(!econ_overlay_icon(node, "node_terminal"), "Без кабеля клеммы нет")
	node.toggle()

	for(var/crate_type in list(/obj/structure/closet/crate, /obj/structure/closet/crate/bin, /obj/structure/closet/crate/critter))
		check_crate_label(crate_type)

/// Бирка накладной на закрытом ящике: отдела, спецзаказа поверх отдела; снимается, когда накладную вынули или ящик открыли.
/datum/unit_test/economy_icon_overlays/proc/check_crate_label(crate_type)
	var/obj/structure/closet/crate/crate = allocate(crate_type, run_loc_floor_bottom_left)
	crate.open()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	var/obj/item/export_manifest/manifest = medical.print_manifest(run_loc_floor_bottom_left)
	crate.close()
	TEST_ASSERT(manifest.loc == crate, "[crate_type]: накладная в ящике")
	TEST_ASSERT(econ_overlay_icon(crate, "label_med"), "[crate_type]: закрытый ящик с накладной медицины носит её бирку")
	var/obj/item/export_manifest/special = allocate(/obj/item/export_manifest)
	special.special_offer_id = "test_offer"
	special.forceMove(crate)
	TEST_ASSERT(econ_overlay_icon(crate, "label_special") && !econ_overlay_icon(crate, "label_med"), "[crate_type]: бирка спецзаказа вместо бирки отдела")
	qdel(special)
	TEST_ASSERT(econ_overlay_icon(crate, "label_med"), "[crate_type]: без спецзаказа снова бирка отдела")
	manifest.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!econ_overlay_icon(crate, "label_med"), "[crate_type]: без накладной бирки нет")
	manifest.forceMove(crate)
	TEST_ASSERT(econ_overlay_icon(crate, "label_med"), "[crate_type]: накладную вернули - бирка вернулась")
	crate.open()
	TEST_ASSERT(!econ_overlay_icon(crate, "label_med"), "[crate_type]: у открытого ящика бирки нет")
	qdel(manifest)
	qdel(crate)
