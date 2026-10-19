/// Using an urethral tube in hand empties it.
/datum/unit_test/urethral_tube_empties_in_hand/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/reagent_containers/urethral_tube/tube = allocate(/obj/item/reagent_containers/urethral_tube)
	tube.reagents.add_reagent(/datum/reagent/water, 10)

	tube.attack_self(user)

	TEST_ASSERT_EQUAL(tube.reagents.total_volume, 0, "Using the tube in hand must pour out its contents")

/// Switching a cyborg module puts away the tools the cyborg held from the old module.
/datum/unit_test/borg_module_swap_puts_away_held_tools/Run()
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	borg.set_hud_used(new borg.hud_type(borg))
	var/obj/item/robot_module/old_module = borg.module
	var/obj/item/dogborg_nose/nose = new(old_module)
	old_module.basic_modules += nose
	old_module.rebuild_modules()
	TEST_ASSERT(borg.activate_module(nose), "test premise: the cyborg must be able to hold its module tool")

	var/obj/item/robot_module/new_module = old_module.transform_to(/obj/item/robot_module)

	TEST_ASSERT_NOTNULL(new_module, "test premise: the module swap must go through")
	TEST_ASSERT(!(nose in borg.held_items), "A tool from the replaced module must not stay in the cyborg's hands")

/// Swiping a PDA over a MOD control unit copies the access of the ID inside the PDA.
/datum/unit_test/mod_access_from_pda/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/mod/control/mod = allocate(/obj/item/mod/control/pre_equipped/standard)
	var/obj/item/modular_computer/pda/roboticist/pda = allocate(/obj/item/modular_computer/pda/roboticist)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_ROBOTICS)
	TEST_ASSERT(pda.InsertID(card), "test premise: the PDA must accept the ID card")

	mod.handle_change_access(pda, user)

	TEST_ASSERT_EQUAL(length(mod.req_access), 1, "The MOD must take the access list of the ID inside the PDA")
	TEST_ASSERT(ACCESS_ROBOTICS in mod.req_access, "The MOD must take the access list of the ID inside the PDA")

/// Fuel loaded into a power generation module outside a suit tops it up without overfilling it.
/datum/unit_test/mod_powergen_fuel_outside_suit/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/mod/module/power/plasma/module = allocate(/obj/item/mod/module/power/plasma)
	var/obj/item/stack/sheet/mineral/plasma/fuel = allocate(/obj/item/stack/sheet/mineral/plasma, null, 30)
	module.current_fuel_amount = module.max_fuel_amount - 10

	module.insert_fuel(fuel, user)

	TEST_ASSERT_EQUAL(module.current_fuel_amount, module.max_fuel_amount, "Fuel must be added to what the module already holds, up to its capacity")
	TEST_ASSERT_EQUAL(fuel.amount, 20, "Only the sheets that fit must be taken from the stack")

/// A monkey turned human by mutadone during its own life tick stops processing instead of breathing as a deleted mob.
/datum/unit_test/monkey_humanized_mid_life/Run()
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey)
	monkey.reagents.add_reagent(/datum/reagent/medicine/mutadone, 5)
	monkey.failed_last_breath = TRUE

	var/life_result = monkey.BiologicalLife(SSMOBS_DT, monkey.life_periodic_phase)

	TEST_ASSERT(QDELETED(monkey), "test premise: mutadone must turn the monkey into a human")
	TEST_ASSERT(!life_result, "A mob deleted during its life tick must report the tick as interrupted")

/// Mannitol starts working in a mob without a mood component.
/datum/unit_test/mannitol_without_mood/Run()
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey)
	TEST_ASSERT_NULL(monkey.GetComponent(/datum/component/mood), "test premise: monkeys have no mood component")
	monkey.reagents.add_reagent(/datum/reagent/medicine/mannitol, 5)

	monkey.reagents.metabolize(monkey, SSMOBS_DT, 0, can_overdose = TRUE)

	var/datum/reagent/medicine/mannitol/mannitol = monkey.reagents.has_reagent(/datum/reagent/medicine/mannitol)
	TEST_ASSERT(mannitol?.metabolizing, "Mannitol must start metabolizing in a mob without moods")

/// The clothes burst interaction is offered only to carbon mobs.
/datum/unit_test/clothesplosion_needs_carbon/Run()
	var/mob/living/simple_animal/bot/secbot/bot = allocate(/mob/living/simple_animal/bot/secbot)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/datum/interaction/lewd/clothesplosion/interaction = new

	TEST_ASSERT(!interaction.special_check(bot, bot), "A bot has no clothes to burst out of")
	TEST_ASSERT(interaction.special_check(human, human), "A human must still be able to burst out of their clothes")
	qdel(interaction)

/// Pulling an item out of a wall puts it in hand and removes the embed.
/datum/unit_test/embedded_wall_item_pull_out/Run()
	var/turf/closed/wall/wall = locate(run_loc_floor_bottom_left.x - 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT(iswallturf(wall), "test premise: the reservation must have a wall west of the arena")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, WEST))
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)
	var/datum/thrownthing/throw_datum = new(knife, wall, WEST, 1, 1)
	wall.AddComponent(/datum/component/embedded, knife, throw_datum)
	qdel(throw_datum)
	var/list/embeds = wall.GetComponents(/datum/component/embedded)
	TEST_ASSERT_EQUAL(length(embeds), 1, "test premise: the knife must stick in the wall")
	var/datum/component/embedded/embed = embeds[1]

	usr = user
	embed.Topic(null, list("embedded_object" = REF(knife)))

	TEST_ASSERT(user.is_holding(knife), "The pulled out item must end up in hand")
	TEST_ASSERT_EQUAL(knife.invisibility, initial(knife.invisibility), "The pulled out item must be visible again")
	TEST_ASSERT(QDELETED(embed), "The wall must forget the pulled out item")

/// A puddle of space cleaner is used up cleaning its own turf.
/datum/unit_test/space_cleaner_puddle_cleans_itself/Run()
	var/turf/open/floor/floor = run_loc_floor_bottom_left

	floor.add_liquid_list(list(/datum/reagent/space_cleaner = 10), FALSE, T20C)

	TEST_ASSERT_NULL(floor.liquids, "Space cleaner must use up its own puddle")

/// Destroying a milking machine with someone strapped in releases them.
/datum/unit_test/milking_machine_destroyed_with_occupant/Run()
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human)
	var/obj/structure/chair/milking_machine/machine = allocate(/obj/structure/chair/milking_machine)
	TEST_ASSERT(machine.buckle_mob(occupant, force = TRUE), "test premise: the machine must take the occupant")
	TEST_ASSERT_NOTNULL(occupant.handcuffed, "test premise: the machine must lock the occupant's hands")

	qdel(machine)

	TEST_ASSERT_NULL(occupant.buckled, "The occupant must be unbuckled from a destroyed machine")
	TEST_ASSERT_NULL(occupant.handcuffed, "The machine cuffs must go away with the machine")
	TEST_ASSERT_EQUAL(occupant.layer, initial(occupant.layer), "The occupant must return to the mob layer")

/// A pregnancy test on someone without a womb reads negative.
/datum/unit_test/pregnancy_test_without_womb/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/organ/womb = user.getorganslot(ORGAN_SLOT_WOMB)
	if(womb)
		qdel(womb)
	var/obj/item/pregnancytest/tester = allocate(/obj/item/pregnancytest)

	tester.attack_self(user)

	TEST_ASSERT_EQUAL(tester.results, "negative", "Someone without a womb cannot be pregnant")

/// Deleting a mob with aphasia cleans the trauma up without touching the deleted language holder.
/datum/unit_test/aphasia_mob_deletion/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	var/datum/brain_trauma/severe/aphasia/trauma = patient.gain_trauma(/datum/brain_trauma/severe/aphasia, TRAUMA_RESILIENCE_ABSOLUTE)
	TEST_ASSERT(istype(trauma), "test premise: the patient must get aphasia")

	qdel(patient)

	TEST_ASSERT(QDELETED(trauma), "The trauma must be deleted with its brain")
