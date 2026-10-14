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

	scanner.set_last_fined(original)
	TEST_ASSERT(scanner.is_on_cooldown(original), "A newly fined miner must refuse a duplicate scan.")

	qdel(replacement_board)
	board.forceMove(replacement)
	original.component_parts -= board
	original.circuit = null
	replacement.component_parts += board
	replacement.circuit = board
	TEST_ASSERT(scanner.is_on_cooldown(replacement), "Moving the same board into a rebuilt miner must preserve its fine cooldown.")

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
/datum/unit_test/sol_inspection_mech_thresholds/Run()
	var/old_security_level = GLOB.security_level
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
	GLOB.security_level = old_security_level

/// A listed inspection member who last handled the target is suspended before any fine is paid.
/datum/unit_test/sol_inspection_sabotage_blocks_payout/Run()
	var/obj/item/sol_inspection_scanner/scanner = allocate(/obj/item/sol_inspection_scanner)
	var/obj/item/test_target = allocate(/obj/item)
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
	test_target.fingerprintslast = actor.ckey

	var/scanning_balance = scanning_team.account.account_balance
	var/actor_balance = actor_team.account.account_balance
	TEST_ASSERT(scanner.handle_inspector_sabotage(test_target, scanning_team), "An inspection member listed as the last actor must trigger sabotage handling.")
	TEST_ASSERT(actor_antag.suspended, "The last-actor inspector must be suspended.")
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
