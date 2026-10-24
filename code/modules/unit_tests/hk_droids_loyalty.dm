#define HK_TEST_DISABLE_TIME (10 SECONDS)

/// Смена хозяина в блоке лояльности шлёт сигнал со старым и новым хозяином.
/datum/unit_test/hk_loyalty_master_change
	var/datum/mind/signal_new_master
	var/datum/mind/signal_old_master

/datum/unit_test/hk_loyalty_master_change/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human)
	first.mind_initialize()
	second.mind_initialize()

	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty, first.mind)
	TEST_ASSERT_EQUAL(loyalty.get_master(), first.mind, "initial master")
	RegisterSignal(droid, COMSIG_HK_MASTER_CHANGED, PROC_REF(on_master_changed))
	loyalty.set_master(second.mind)
	TEST_ASSERT_EQUAL(loyalty.get_master(), second.mind, "master changed")
	TEST_ASSERT_EQUAL(signal_new_master, second.mind, "signal carries the new master")
	TEST_ASSERT_EQUAL(signal_old_master, first.mind, "signal carries the old master")

	loyalty.set_master(null)
	TEST_ASSERT_NULL(loyalty.get_master(), "master cleared")
	TEST_ASSERT_NULL(signal_new_master, "signal reports no master")
	TEST_ASSERT_EQUAL(signal_old_master, second.mind, "signal reports the cleared master")
	UnregisterSignal(droid, COMSIG_HK_MASTER_CHANGED)

/datum/unit_test/hk_loyalty_master_change/proc/on_master_changed(datum/source, datum/mind/new_master, datum/mind/old_master)
	SIGNAL_HANDLER
	signal_new_master = new_master
	signal_old_master = old_master

/// Перепрошивка предлагается на голове обездвиженного HK и не предлагается свободному HK, человеку и простому IPC; обычные операции на голове им предлагаются.
/datum/unit_test/hk_reprogram_offered

/datum/unit_test/hk_reprogram_offered/Run()
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/obj/item/surgical_drapes/drapes = allocate(/obj/item/surgical_drapes)

	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.set_resting(TRUE, silent = TRUE)
	TEST_ASSERT(droid.lying, "resting HK lies down")
	TEST_ASSERT(!offers(surgeon, drapes, droid), "free HK lying down is not offered reprogramming")

	droid.Knockdown(HK_TEST_DISABLE_TIME)
	TEST_ASSERT(offers(surgeon, drapes, droid), "knocked down HK is offered reprogramming")
	droid.mind_initialize()
	TEST_ASSERT(!offers(droid, drapes, droid), "HK can't reprogram itself")
	droid.SetKnockdown(0)

	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	droid.handcuffed = cuffs
	cuffs.forceMove(droid)
	droid.update_handcuffed()
	TEST_ASSERT(offers(surgeon, drapes, droid), "handcuffed HK is offered reprogramming")
	droid.handcuffed = null
	droid.update_handcuffed()

	droid.emp_act(HK_EMP_HEAVY_SEVERITY)
	TEST_ASSERT(offers(surgeon, drapes, droid), "EMP-stunned HK is offered reprogramming")
	droid.SetParalyzed(0)

	var/mob/living/carbon/human/crewman = allocate(/mob/living/carbon/human)
	crewman.Unconscious(HK_TEST_DISABLE_TIME)
	TEST_ASSERT(crewman.lying, "unconscious human lies down")
	TEST_ASSERT(!offers(surgeon, drapes, crewman), "human is not offered HK reprogramming")
	TEST_ASSERT(offers(surgeon, drapes, crewman, /datum/surgery/organ_manipulation), "unconscious human is offered head organ manipulation")

	var/mob/living/carbon/human/ipc = allocate(/mob/living/carbon/human)
	ipc.set_species(/datum/species/ipc)
	ipc.Unconscious(HK_TEST_DISABLE_TIME)
	TEST_ASSERT(ipc.lying, "unconscious IPC lies down")
	TEST_ASSERT(!offers(surgeon, drapes, ipc), "plain IPC is not offered HK reprogramming")
	TEST_ASSERT(offers(surgeon, drapes, ipc, /datum/surgery/organ_manipulation/mechanic), "unconscious IPC is offered prosthesis organ manipulation on the head")

/datum/unit_test/hk_reprogram_offered/proc/offers(mob/living/carbon/human/surgeon, obj/item/tool, mob/living/carbon/human/patient, surgery_type = /datum/surgery/hk_reprogram)
	var/list/offered = get_available_surgeries(tool, patient, surgeon, BODY_ZONE_HEAD)
	for(var/surgery_name in offered)
		var/datum/surgery/surgery = offered[surgery_name]
		if(surgery.type == surgery_type)
			return TRUE
	return FALSE

/// Шаг перепрошивки ставит хирурга хозяином, а со свободным дроидом не начинается.
/datum/unit_test/hk_reprogram_step

/datum/unit_test/hk_reprogram_step/Run()
	var/mob/living/carbon/human/droid = allocate(/mob/living/carbon/human)
	droid.set_species(/datum/species/ipc/hk/hk47)
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human)
	surgeon.mind_initialize()
	var/datum/surgery/hk_reprogram/surgery = allocate(/datum/surgery/hk_reprogram, droid, BODY_ZONE_HEAD, droid.get_bodypart(BODY_ZONE_HEAD))
	var/datum/surgery_step/hk_reprogram/step = allocate(/datum/surgery_step/hk_reprogram)

	TEST_ASSERT_EQUAL(step.preop(surgeon, droid, BODY_ZONE_HEAD, null, surgery), -1, "free HK breaks off reprogramming")
	droid.Unconscious(HK_TEST_DISABLE_TIME)
	TEST_ASSERT_NOTEQUAL(step.preop(surgeon, droid, BODY_ZONE_HEAD, null, surgery), -1, "disabled HK can be reprogrammed")
	TEST_ASSERT(step.success(surgeon, droid, BODY_ZONE_HEAD, null, surgery), "reprogramming step succeeds")
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_NOTNULL(loyalty, "reprogramming installs a loyalty block")
	TEST_ASSERT_EQUAL(loyalty.get_master(), surgeon.mind, "surgeon is the new master")

	var/mob/living/carbon/human/second_surgeon = allocate(/mob/living/carbon/human)
	second_surgeon.mind_initialize()
	step.success(second_surgeon, droid, BODY_ZONE_HEAD, null, surgery)
	TEST_ASSERT_EQUAL(droid.GetComponent(/datum/component/hk_loyalty), loyalty, "second reprogramming keeps the same loyalty block")
	TEST_ASSERT_EQUAL(loyalty.get_master(), second_surgeon.mind, "second reprogramming replaces the master")

#undef HK_TEST_DISABLE_TIME

/datum/unit_test/proc/hk_reprogram_by(mob/living/carbon/human/surgeon, mob/living/carbon/human/droid)
	var/datum/surgery/hk_reprogram/surgery = allocate(/datum/surgery/hk_reprogram, droid, BODY_ZONE_HEAD, droid.get_bodypart(BODY_ZONE_HEAD))
	var/datum/surgery_step/hk_reprogram/step = allocate(/datum/surgery_step/hk_reprogram)
	return step.success(surgeon, droid, BODY_ZONE_HEAD, null, surgery)

/datum/unit_test/proc/allocate_minded_human()
	var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human)
	body.mind_initialize()
	allocated += body.mind
	return body

/// HK-51 культиста из каркаса после перепрошивки экипажем свободен от культа, порабощения и фракций хозяина; хирург-антагонист забирает его себе.
/datum/unit_test/hk51_reprogram_allegiance

/datum/unit_test/hk51_reprogram_allegiance/Run()
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		frame.install_part(allocate(part_type))
	var/mob/living/carbon/human/cultist = allocate_minded_human()
	var/datum/antagonist/cult/neutered/cult = allocate(/datum/antagonist/cult/neutered)
	cult.owner = cultist.mind
	cultist.mind.antag_datums = list(cult)
	cultist.faction |= ROLE_SYNDICATE
	var/mob/living/carbon/human/droid = frame.build_droid(cultist, null)
	allocated += list(droid, droid.mind)
	TEST_ASSERT_EQUAL(droid.mind.enslaved_to, cultist, "the cultist enslaves the droid on activation")
	TEST_ASSERT(iscultist(droid), "the droid joins its master's cult")
	TEST_ASSERT(ROLE_SYNDICATE in droid.faction, "the droid takes its master's factions")

	var/mob/living/carbon/human/surgeon = allocate_minded_human()
	TEST_ASSERT(hk_reprogram_by(surgeon, droid), "crew reprogramming succeeds")
	var/datum/component/hk_loyalty/loyalty = droid.GetComponent(/datum/component/hk_loyalty)
	TEST_ASSERT_EQUAL(loyalty.get_master(), surgeon.mind, "the surgeon is the new master")
	TEST_ASSERT_NULL(droid.mind.enslaved_to, "crew reprogramming frees the droid")
	TEST_ASSERT(!iscultist(droid), "the droid leaves the cult")
	TEST_ASSERT(!(ROLE_SYNDICATE in droid.faction), "the old master's factions are gone")
	TEST_ASSERT(!("cult" in droid.faction), "the cult faction is gone")
	TEST_ASSERT("neutral" in droid.faction, "the droid keeps its own faction")

	var/mob/living/carbon/human/traitor = allocate_minded_human()
	mark_hk47_antag(traitor.mind)
	traitor.faction |= ROLE_SYNDICATE
	hk_reprogram_by(traitor, droid)
	TEST_ASSERT_EQUAL(droid.mind.enslaved_to, traitor, "an antagonist surgeon takes the crew droid into his team")
	TEST_ASSERT(ROLE_SYNDICATE in droid.faction, "the droid takes the new master's factions")
	hk_reprogram_by(surgeon, droid)
	TEST_ASSERT_NULL(droid.mind.enslaved_to, "the crew takes the droid back")
	TEST_ASSERT(!(ROLE_SYNDICATE in droid.faction), "the traitor's factions are gone")

/// Разум в шасси сменили: перепрошивка снимает культ, выданный прежнему разуму, и не трогает собственный культ нового.
/datum/unit_test/hk_loyalty_mind_swap

/datum/unit_test/hk_loyalty_mind_swap/Run()
	var/mob/living/carbon/human/cult_master = allocate_minded_human()
	var/datum/antagonist/cult/neutered/master_cult = allocate(/datum/antagonist/cult/neutered)
	master_cult.owner = cult_master.mind
	cult_master.mind.antag_datums = list(master_cult)
	var/mob/living/carbon/human/droid = allocate_minded_human()
	droid.set_species(/datum/species/ipc/hk/hk51)
	var/datum/mind/first_mind = droid.mind
	var/datum/component/hk_loyalty/loyalty = droid.AddComponent(/datum/component/hk_loyalty)
	loyalty.set_master(cult_master.mind)
	TEST_ASSERT_NOTNULL(first_mind.has_antag_datum(/datum/antagonist/cult), "the cult master takes the droid into the cult")
	var/mob/living/carbon/human/zealot = allocate_minded_human()
	var/datum/mind/second_mind = zealot.mind
	second_mind.add_antag_datum(/datum/antagonist/cult/neutered/traitor)
	second_mind.transfer_to(droid)
	first_mind.transfer_to(zealot)
	TEST_ASSERT_EQUAL(droid.mind, second_mind, "a cultist of his own now runs the chassis")
	hk_reprogram_by(allocate_minded_human(), droid)
	TEST_ASSERT_NULL(first_mind.has_antag_datum(/datum/antagonist/cult), "the cult given by the old master leaves the old mind")
	TEST_ASSERT_NULL(first_mind.enslaved_to, "the old mind is no longer enslaved")
	TEST_ASSERT_NOTNULL(second_mind.has_antag_datum(/datum/antagonist/cult), "the new mind keeps its own cult")
	second_mind.remove_antag_datum(/datum/antagonist/cult)

/// Гостевая роль не делает хозяина антагонистом ни при сборке HK-51, ни при перепрошивке.
/datum/unit_test/hk51_ghost_role_master_is_crew

/datum/unit_test/hk51_ghost_role_master_is_crew/Run()
	var/obj/item/hk51_frame/frame = allocate(/obj/item/hk51_frame)
	for(var/part_type in subtypesof(/obj/item/hk51_part))
		frame.install_part(allocate(part_type))
	var/mob/living/carbon/human/guest = allocate_minded_human()
	var/datum/antagonist/ghost_role/role = allocate(/datum/antagonist/ghost_role)
	role.owner = guest.mind
	guest.mind.antag_datums = list(role)
	TEST_ASSERT(!hk_master_is_antagonist(guest.mind), "a ghost role is not an antagonist master")
	var/mob/living/carbon/human/droid = frame.build_droid(guest, null)
	allocated += list(droid, droid.mind)
	TEST_ASSERT_NULL(droid.mind.enslaved_to, "a ghost role master does not enslave the droid")
	hk_reprogram_by(guest, droid)
	TEST_ASSERT_NULL(droid.mind.enslaved_to, "a ghost role surgeon does not enslave the droid")

/// HK-50 с разумом, перепрошитый предателем, служит предателю, а не HK-47; экипаж затем его освобождает.
/datum/unit_test/hk50_ghost_reprogram_allegiance

/datum/unit_test/hk50_ghost_reprogram_allegiance/Run()
	var/datum/antagonist/hk47/contract_fixture/upgrade_test/hunter = allocate_hk47_droid()
	var/mob/living/carbon/human/servant = hunter.create_ghost_servant(run_loc_floor_top_right, null)
	allocated += list(servant, servant.mind)
	TEST_ASSERT_EQUAL(servant.mind.enslaved_to, hunter.owner.current, "the servant starts bound to HK-47")
	var/mob/living/carbon/human/traitor = allocate_minded_human()
	mark_hk47_antag(traitor.mind)
	hk_reprogram_by(traitor, servant)
	TEST_ASSERT_NULL(servant.mind.has_antag_datum(/datum/antagonist/hk50_servant), "the HK-47 servant role is gone")
	TEST_ASSERT_EQUAL(servant.mind.enslaved_to, traitor, "the traitor's HK-50 serves the traitor")
	var/mob/living/carbon/human/surgeon = allocate_minded_human()
	hk_reprogram_by(surgeon, servant)
	TEST_ASSERT_NULL(servant.mind.enslaved_to, "the crew frees the HK-50")
