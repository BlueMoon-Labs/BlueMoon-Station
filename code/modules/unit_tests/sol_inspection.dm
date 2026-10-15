/// Validate the actual ported map against the compiled type tree, including inherited paths.
/datum/unit_test/sol_inspection_map_types/Run()
	var/datum/parsed_map/map = new(file("_maps/shuttles/sol_inspection_default.dmm"))
	var/datum/map_report/report = map.check_for_errors()
	if(report)
		TEST_FAIL("Inspection map has invalid paths: [report.bad_paths.Join(", ")]; invalid tiles: [report.bad_keys.Join(", ")].")
		qdel(report)
	qdel(map)

/// Fine assessment may put cargo in debt, but routine spending must still require funds.
/datum/unit_test/sol_inspection_fine_debt/Run()
	var/datum/bank_account/cargo = allocate(/datum/bank_account, "Test Cargo")
	var/datum/bank_account/inspection = allocate(/datum/bank_account, "Test Inspection")

	TEST_ASSERT(cargo.assess_sol_inspection_fine(25000, inspection, "unit test"), "An inspection fine must be assessed against an empty cargo account.")
	TEST_ASSERT_EQUAL(cargo.account_balance, -25000, "The cargo account must retain its fine debt.")
	TEST_ASSERT_EQUAL(inspection.account_balance, 25000, "The inspection account must receive the full fine.")
	TEST_ASSERT_EQUAL(cargo.account_balance + inspection.account_balance, 0, "Fine assessment must conserve credits between both accounts.")

	TEST_ASSERT(cargo.adjust_money(5000, "test income"), "Positive income must be accepted while cargo has debt.")
	TEST_ASSERT_EQUAL(cargo.account_balance, -20000, "Income must repay cargo debt instead of clamping it to zero.")
	TEST_ASSERT_EQUAL(cargo.adjust_money(-1, "test purchase"), FALSE, "Ordinary purchases must still fail while cargo lacks funds.")

/// The cooldown is deliberately stored on the board, which survives a machine rebuild.
/datum/unit_test/sol_inspection_miner_cooldown/Run()
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	var/obj/machinery/cryptominer/original = allocate(/obj/machinery/cryptominer)
	var/obj/item/circuitboard/machine/cryptominer/board = original.circuit
	var/obj/machinery/cryptominer/replacement = allocate(/obj/machinery/cryptominer, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/item/circuitboard/machine/replacement_board = replacement.circuit
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human)
	builder.ckey = "sol_miner_rebuild_test"
	record_sol_inspection_builder(original, builder)

	scanner.set_last_fined(original)
	TEST_ASSERT(scanner.is_on_cooldown(original), "A newly fined miner must refuse a duplicate scan.")

	qdel(replacement_board)
	board.forceMove(replacement)
	original.component_parts -= board
	original.circuit = null
	replacement.component_parts += board
	replacement.circuit = board
	TEST_ASSERT(scanner.is_on_cooldown(replacement), "Moving the same board into a rebuilt miner must preserve its fine cooldown.")
	TEST_ASSERT_EQUAL(scanner.get_builder_ckey(replacement), builder.ckey, "Moving a board must preserve assembly provenance until a new assembly is completed.")

	board.sol_inspection_last_fined = world.time - scanner.fine_cooldown - 1
	TEST_ASSERT(!scanner.is_on_cooldown(replacement), "A miner must become eligible after its fine cooldown expires.")

/// Scanner authority requires an active, unsuspended member of an inspection team.
/datum/unit_test/sol_inspection_scanner_authority/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/turf/station_turf = locate(1, 1, station_z)
	var/mob/living/carbon/human/inspector = allocate(/mob/living/carbon/human, station_turf)
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner, station_turf)
	var/obj/item/test_target = allocate(/obj/item, station_turf)
	var/datum/team/sol_inspection/team = allocate(/datum/team/sol_inspection, list())
	allocated += team.account

	inspector.mind_initialize("sol_inspection_authority")
	inspector.put_in_hands(scanner, forced = TRUE)
	TEST_ASSERT(!scanner.can_scan(inspector, test_target), "A nonmember must not use the inspection scanner.")

	inspector.mind.add_antag_datum(/datum/antagonist/sol_inspector, team)
	var/datum/antagonist/sol_inspector/antag = inspector.mind.has_antag_datum(/datum/antagonist/sol_inspector)
	TEST_ASSERT(scanner.can_scan(inspector, test_target), "An active inspection member must be able to use the scanner.")

	antag.suspended = TRUE
	TEST_ASSERT(!scanner.can_scan(inspector, test_target), "A suspended inspector must not use the scanner.")

/// Durand and Gygax restrictions lift only at their respective security thresholds.
/datum/unit_test/sol_inspection_mech_thresholds
	var/old_security_level

/datum/unit_test/sol_inspection_mech_thresholds/Destroy()
	GLOB.security_level = old_security_level
	return ..()

/datum/unit_test/sol_inspection_mech_thresholds/Run()
	old_security_level = GLOB.security_level
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	var/obj/vehicle/sealed/mecha/combat/durand/durand = allocate(/obj/vehicle/sealed/mecha/combat/durand)
	var/obj/vehicle/sealed/mecha/combat/gygax/gygax = allocate(/obj/vehicle/sealed/mecha/combat/gygax, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT_EQUAL(scanner.get_fine_amount(durand), 50000, "Durand must incur a 50,000 credit fine.")
	TEST_ASSERT_EQUAL(scanner.get_fine_amount(gygax), 25000, "Gygax must incur a 25,000 credit fine.")

	GLOB.security_level = SEC_LEVEL_GREEN
	TEST_ASSERT(scanner.violation_reason(durand), "Durand must be illegal outside the armory below code Red.")
	TEST_ASSERT(scanner.violation_reason(gygax), "Gygax must be illegal outside the armory below code Amber.")

	GLOB.security_level = SEC_LEVEL_AMBER
	TEST_ASSERT(scanner.violation_reason(durand), "Durand must remain illegal at code Amber.")
	TEST_ASSERT(!scanner.violation_reason(gygax), "Gygax must become legal at code Amber.")

	GLOB.security_level = SEC_LEVEL_RED
	TEST_ASSERT(!scanner.violation_reason(durand), "Durand must become legal at code Red.")

/// Handling an existing miner is legal; assembling one as an inspector blocks payment.
/datum/unit_test/sol_inspection_sabotage_blocks_payout/Run()
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	var/obj/machinery/cryptominer/test_target = allocate(/obj/machinery/cryptominer)
	var/datum/team/sol_inspection/scanning_team = allocate(/datum/team/sol_inspection, list())
	var/datum/team/sol_inspection/actor_team = allocate(/datum/team/sol_inspection, list())
	allocated += scanning_team.account
	allocated += actor_team.account
	var/mob/living/carbon/human/actor = allocate(/mob/living/carbon/human)

	actor.real_name = "Sol Inspection Saboteur Test"
	actor.name = actor.real_name
	actor.ckey = "sol_inspection_saboteur"
	actor.mind_initialize(actor.ckey)
	actor.mind.key = actor.ckey
	actor.mind.add_antag_datum(/datum/antagonist/sol_inspector, actor_team)
	var/datum/antagonist/sol_inspector/actor_antag = actor.mind.has_antag_datum(/datum/antagonist/sol_inspector)
	GLOB.player_list += actor
	test_target.add_fingerprint(actor)
	test_target.circuit.add_hiddenprint(actor)
	TEST_ASSERT(!scanner.handle_inspector_sabotage(test_target, scanning_team), "Touching a pre-existing miner or its board must not trigger sabotage.")
	TEST_ASSERT(!actor_antag.suspended, "Routine inspection must not suspend the inspector.")
	TEST_ASSERT(!GLOB.data_core.security_by_name[actor.real_name], "Routine inspection must not issue an arrest warrant.")
	var/mob/living/carbon/human/other_handler = allocate(/mob/living/carbon/human)
	other_handler.ckey = "sol_inspection_other_handler"
	record_sol_inspection_builder(test_target, other_handler)
	TEST_ASSERT(!scanner.handle_inspector_sabotage(test_target, scanning_team), "An ordinary crew member's miner remains eligible after an inspector touches it.")
	record_sol_inspection_builder(test_target, actor)
	test_target.add_fingerprint(other_handler)
	test_target.circuit.add_hiddenprint(other_handler)

	var/scanning_balance = scanning_team.account.account_balance
	var/actor_balance = actor_team.account.account_balance
	TEST_ASSERT(scanner.handle_inspector_sabotage(test_target, scanning_team), "The inspector who assembled the miner must trigger sabotage even after someone else handles it.")
	TEST_ASSERT(actor_antag.suspended, "The inspector who assembled the miner must be suspended.")
	TEST_ASSERT_EQUAL(scanning_team.account.account_balance, scanning_balance, "Sabotage handling must not pay the scanning team.")
	TEST_ASSERT_EQUAL(actor_team.account.account_balance, actor_balance, "Sabotage handling must not pay the offending inspector's team.")
	var/datum/data/record/security_record = GLOB.data_core.security_by_name[actor.real_name]
	var/datum/data/record/general_record = GLOB.data_core.general_by_name[actor.real_name]
	TEST_ASSERT(security_record && general_record, "An off-station inspector must receive security and general records when a warrant is issued.")
	allocated += list(security_record, general_record, general_record.photo_source)
	TEST_ASSERT_EQUAL(security_record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "A sabotaging inspector must be marked for arrest.")
	TEST_ASSERT(security_record.locked_security_reason, "The permanent arrest must have a reason.")
	TEST_ASSERT_EQUAL(general_record.locked_security_reason, security_record.locked_security_reason, "Both records must protect the same warrant.")
	var/list/charges = security_record.fields["ma_crim"]
	TEST_ASSERT_EQUAL(length(charges), 1, "Sabotage must create one permanent major charge.")
	var/datum/data/crime/charge = charges[1]
	allocated += charge
	TEST_ASSERT(charge.permanent && length(charge.crimeDetails), "The warrant's reason must be stored in an immutable crime entry.")
	TEST_ASSERT(!set_criminal_status(actor, security_record, SEC_RECORD_STATUS_NONE, "Test removal", "Captain", list(ACCESS_CAPTAIN)), "The security console helper must refuse to clear the warrant.")
	TEST_ASSERT(!security_record.set_security_status(SEC_RECORD_STATUS_INCARCERATED), "Brig intake must not replace a permanent arrest.")
	TEST_ASSERT(!security_record.set_security_status(SEC_RECORD_STATUS_RELEASED), "Brig release must not clear a permanent arrest.")
	GLOB.data_core.removeMajorCrime(security_record.fields["id"], "[charge.dataId]", TRUE)
	TEST_ASSERT(charge in security_record.fields["ma_crim"], "Even CentCom access must not erase the permanent charge.")
	GLOB.data_core.switch_incur(security_record.fields["id"], "[charge.dataId]")
	TEST_ASSERT(!charge.penalties_incurred, "The permanent charge must not be marked as served.")
	GLOB.data_core.remove_records_by_name(actor.real_name)
	TEST_ASSERT(!QDELETED(security_record) && !QDELETED(general_record), "Removing a crew member's records must preserve their permanent warrant.")
	TEST_ASSERT_EQUAL(security_record.fields["criminal"], SEC_RECORD_STATUS_ARREST, "The arrest must remain after all removal attempts.")
	TEST_ASSERT(scanner.handle_inspector_sabotage(test_target, scanning_team), "Repeated sabotage scans must still block payment.")
	TEST_ASSERT_EQUAL(length(charges), 1, "Repeated scans must not duplicate the warrant.")
	var/datum/data/record/ordinary_record = allocate(/datum/data/record)
	TEST_ASSERT(ordinary_record.set_security_status(SEC_RECORD_STATUS_RELEASED), "Normal records must remain editable.")
	TEST_ASSERT_EQUAL(ordinary_record.fields["criminal"], SEC_RECORD_STATUS_RELEASED, "Normal brig release behavior must be preserved.")
	GLOB.player_list -= actor

/// Completing either miner frame records the assembler independently of later fingerprints.
/datum/unit_test/sol_inspection_miner_assembly/Run()
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human)
	builder.ckey = "sol_miner_assembly_test"
	var/mob/living/carbon/human/handler = allocate(/mob/living/carbon/human)
	handler.ckey = "sol_miner_handler_test"
	var/obj/item/screwdriver/tool = allocate(/obj/item/screwdriver)
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	for(var/board_type in list(/obj/item/circuitboard/machine/cryptominer, /obj/item/circuitboard/machine/bluespace_miner))
		var/obj/structure/frame/machine/frame = allocate(/obj/structure/frame/machine)
		var/obj/item/circuitboard/machine/board = allocate(board_type, frame)
		frame.circuit = board
		frame.state = 3
		frame.set_anchored(TRUE)
		frame.req_components = list()
		for(var/part_type in board.req_components)
			for(var/part_number in 1 to board.req_components[part_type])
				allocate(part_type, frame)
		frame.components = frame.contents.Copy()
		frame.attackby(tool, builder)
		var/obj/machinery/machine = locate(board.build_path) in run_loc_floor_bottom_left
		TEST_ASSERT(machine, "The final screwdriver action must build the miner.")
		allocated += machine
		TEST_ASSERT_EQUAL(scanner.get_builder_ckey(machine), builder.ckey, "Completing the miner frame must record its assembler.")
		machine.add_fingerprint(handler)
		board.add_hiddenprint(handler)
		TEST_ASSERT_EQUAL(scanner.get_builder_ckey(machine), builder.ckey, "Touching the miner or its board must not replace the assembler.")

/// The final welding step passes the completing player through to the new combat mech.
/datum/unit_test/sol_inspection_mech_assembly/Run()
	var/mob/living/carbon/human/builder = allocate(/mob/living/carbon/human)
	builder.ckey = "sol_mech_assembly_test"
	var/mob/living/carbon/human/handler = allocate(/mob/living/carbon/human)
	handler.ckey = "sol_mech_handler_test"
	var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
	welder.switched_on(builder)
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	for(var/construction_type in list(/datum/component/construction/mecha/durand, /datum/component/construction/mecha/gygax))
		var/obj/item/mecha_parts/chassis/chassis = allocate(/obj/item/mecha_parts/chassis)
		allocate(/obj/item/stock_parts/cell, chassis)
		allocate(/obj/item/stock_parts/scanning_module, chassis)
		allocate(/obj/item/stock_parts/capacitor, chassis)
		var/datum/component/construction/mecha/construction = chassis.AddComponent(construction_type)
		var/result_type = construction.result
		construction.index = length(construction.steps)
		TEST_ASSERT(construction.action(chassis, welder, builder), "The final welding step must complete the combat mech.")
		var/obj/vehicle/sealed/mecha/mech = locate(result_type) in run_loc_floor_bottom_left
		TEST_ASSERT(mech, "The completed combat mech must exist.")
		allocated += mech
		TEST_ASSERT_EQUAL(scanner.get_builder_ckey(mech), builder.ckey, "Mech construction must record the completing player.")
		mech.add_fingerprint(handler)
		TEST_ASSERT_EQUAL(scanner.get_builder_ckey(mech), builder.ckey, "Later contact with the mech must not replace its assembler.")

/// Confiscation removes every illegal target and leaves only the seizure effect, never normal mech wreckage.
/datum/unit_test/sol_inspection_confiscation_removes_targets/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner, test_turf)
	for(var/target_type in list(/obj/machinery/cryptominer, /obj/machinery/mineral/bluespace_miner, /obj/vehicle/sealed/mecha/combat/durand, /obj/vehicle/sealed/mecha/combat/gygax))
		for(var/obj/effect/particle_effect/fake_sparks/sparks in test_turf)
			qdel(sparks)
		var/atom/target = allocate(target_type, test_turf)
		var/obj/item/circuitboard/machine/component_board
		if(istype(target, /obj/machinery))
			var/obj/machinery/machine = target
			component_board = machine.circuit
		scanner.confiscate_target(target)
		TEST_ASSERT(QDELETED(target), "Confiscation must delete [target_type].")
		if(component_board)
			TEST_ASSERT(QDELETED(component_board), "Confiscating [target_type] must delete its component board.")
		TEST_ASSERT(locate(/obj/effect/particle_effect/fake_sparks) in test_turf, "Confiscating [target_type] must leave fake sparks on its turf.")
		TEST_ASSERT(!locate(/obj/structure/mecha_wreckage) in test_turf, "Confiscating [target_type] must not create mech wreckage.")

/// Occupants must survive confiscation and no longer retain control of the seized mech.
/datum/unit_test/sol_inspection_confiscation_evacuation/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner, test_turf)

	var/obj/vehicle/sealed/mecha/combat/durand/human_mech = allocate(/obj/vehicle/sealed/mecha/combat/durand, test_turf)
	var/mob/living/carbon/human/human_pilot = allocate(/mob/living/carbon/human, human_mech)
	human_mech.add_occupant(human_pilot)
	scanner.confiscate_target(human_mech)
	TEST_ASSERT(QDELETED(human_mech), "Confiscation must delete the human pilot's mech.")
	TEST_ASSERT(!QDELETED(human_pilot) && human_pilot.loc == test_turf, "A human pilot must survive on the seizure turf.")

	var/obj/vehicle/sealed/mecha/combat/gygax/brain_mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, test_turf)
	var/obj/item/mmi/mmi = allocate(/obj/item/mmi, brain_mech)
	var/mob/living/brain/brain_pilot = allocate(/mob/living/brain, mmi)
	mmi.brainmob = brain_pilot
	mmi.mecha = brain_mech
	brain_pilot.container = mmi
	brain_pilot.remote_control = brain_mech
	brain_pilot.forceMove(brain_mech)
	brain_mech.add_occupant(brain_pilot)
	scanner.confiscate_target(brain_mech)
	TEST_ASSERT(QDELETED(brain_mech), "Confiscation must delete the MMI pilot's mech.")
	TEST_ASSERT(!QDELETED(brain_pilot) && brain_pilot.loc == mmi && mmi.loc == test_turf, "A brain pilot must be restored to its MMI on the seizure turf.")
	TEST_ASSERT(!brain_pilot.remote_control && !mmi.mecha, "An ejected brain and MMI must no longer control the seized mech.")

	var/mob/living/carbon/human/coreless_donor = allocate(/mob/living/carbon/human)
	var/obj/vehicle/sealed/mecha/combat/durand/coreless_mech = allocate(/obj/vehicle/sealed/mecha/combat/durand, test_turf)
	var/mob/living/silicon/ai/coreless_ai = allocate(/mob/living/silicon/ai, test_turf, null, coreless_donor)
	coreless_ai.controlled_equipment = coreless_mech
	coreless_ai.remote_control = coreless_mech
	coreless_ai.forceMove(coreless_mech)
	coreless_mech.add_occupant(coreless_ai)
	scanner.confiscate_target(coreless_mech)
	TEST_ASSERT(QDELETED(coreless_mech), "Confiscation must delete the coreless AI's mech.")
	TEST_ASSERT(!QDELETED(coreless_ai) && coreless_ai.loc == test_turf, "A coreless AI must survive on the seizure turf.")
	TEST_ASSERT(!coreless_ai.controlled_equipment && !coreless_ai.remote_control, "A coreless AI must lose its seized-mech references.")

	var/mob/living/carbon/human/linked_donor = allocate(/mob/living/carbon/human)
	var/obj/vehicle/sealed/mecha/combat/gygax/linked_mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, test_turf)
	var/mob/living/silicon/ai/linked_ai = allocate(/mob/living/silicon/ai, test_turf, null, linked_donor)
	var/turf/linked_core_turf = get_step(test_turf, EAST)
	var/obj/structure/ai_core/deactivated/linked_core = allocate(/obj/structure/ai_core/deactivated, linked_core_turf)
	linked_ai.linked_core = linked_core
	linked_ai.controlled_equipment = linked_mech
	linked_ai.remote_control = linked_mech
	linked_ai.forceMove(linked_mech)
	linked_mech.add_occupant(linked_ai)
	scanner.confiscate_target(linked_mech)
	TEST_ASSERT(QDELETED(linked_mech), "Confiscation must delete the linked AI's mech.")
	TEST_ASSERT(!QDELETED(linked_ai) && linked_ai.loc == linked_core_turf, "A linked AI must return to its core's turf when evacuated from the mech.")
	TEST_ASSERT(!linked_ai.controlled_equipment && !linked_ai.remote_control && QDELETED(linked_core), "A linked AI must lose its seized-mech references and consumed return core.")

/// Running the real scanner path transfers the fine, prints a receipt, and confiscates the target.
/datum/unit_test/sol_inspection_scanner_confiscation_integration
	var/datum/bank_account/cargo_account
	var/old_cargo_balance

/datum/unit_test/sol_inspection_scanner_confiscation_integration/Destroy()
	if(cargo_account && !QDELETED(cargo_account))
		cargo_account.account_balance = old_cargo_balance
	return ..()

/datum/unit_test/sol_inspection_scanner_confiscation_integration/Run()
	var/station_z = SSmapping.levels_by_trait(ZTRAIT_STATION)[1]
	var/turf/station_turf = locate(1, 1, station_z)
	var/mob/living/carbon/human/inspector = allocate(/mob/living/carbon/human, station_turf)
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner, station_turf)
	var/obj/machinery/cryptominer/miner = allocate(/obj/machinery/cryptominer, station_turf)
	var/datum/team/sol_inspection/team = allocate(/datum/team/sol_inspection, list())
	var/fine_amount = scanner.get_fine_amount(miner)
	allocated += team.account
	cargo_account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	TEST_ASSERT(cargo_account, "The integration test requires the cargo department account.")
	old_cargo_balance = cargo_account.account_balance
	cargo_account.account_balance = old_cargo_balance + fine_amount

	inspector.mind_initialize("sol_inspection_confiscation")
	inspector.put_in_hands(scanner, forced = TRUE)
	scanner.pre_attack(miner, inspector)
	TEST_ASSERT(!QDELETED(miner) && cargo_account.account_balance == old_cargo_balance + fine_amount, "An unauthorized scanner user must not confiscate or fine the target.")
	inspector.mind.add_antag_datum(/datum/antagonist/sol_inspector, team)
	var/datum/antagonist/sol_inspector/antag = inspector.mind.has_antag_datum(/datum/antagonist/sol_inspector)
	TEST_ASSERT(antag?.inspection_team == team, "The scanner user must be a real Sol inspector on the test team.")

	scanner.pre_attack(miner, inspector)
	TEST_ASSERT(QDELETED(miner), "A successful scanner inspection must confiscate the miner.")
	TEST_ASSERT_EQUAL(cargo_account.account_balance, old_cargo_balance, "A successful inspection must transfer the miner fine from cargo.")
	TEST_ASSERT_EQUAL(team.account.account_balance, fine_amount, "A successful inspection must credit the inspector team.")
	TEST_ASSERT(locate(/obj/item/paper) in inspector.GetAllContents(), "A successful inspection must place a receipt in the inspector's inventory.")
	TEST_ASSERT(locate(/obj/effect/particle_effect/fake_sparks) in station_turf, "A successful inspection must leave confiscation sparks behind.")
