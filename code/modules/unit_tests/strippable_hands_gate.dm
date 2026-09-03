/// Tests the "no hands - no stripping" gate on the strip menu:
/// handless fauna can't open it, while cyborgs and adult xenomorphs
/// (manipulators/claws via TRAIT_CAN_STRIP) still can.
/datum/unit_test/strippable_hands_gate

/datum/unit_test/strippable_hands_gate/proc/can_open_strip_menu(mob/living/stripper)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/datum/element/strippable/strippable = SSdcs.GetElement(list(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human, should_strip)))
	strippable.mouse_drop_onto(victim, stripper, stripper)
	return !isnull(LAZYACCESS(strippable.strip_menus, victim))

/datum/unit_test/strippable_hands_gate/Run()
	var/mob/living/simple_animal/hostile/carp/carp = allocate(/mob/living/simple_animal/hostile/carp)
	TEST_ASSERT(!can_open_strip_menu(carp), "A carp (no hands) was able to open the strip menu")

	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	borg.a_intent = INTENT_HELP
	TEST_ASSERT(can_open_strip_menu(borg), "A cyborg was unable to open the strip menu")

	var/mob/living/carbon/alien/humanoid/hunter/xeno = allocate(/mob/living/carbon/alien/humanoid/hunter)
	TEST_ASSERT(can_open_strip_menu(xeno), "An adult xenomorph was unable to open the strip menu")

	var/mob/living/simple_animal/qareen/spirit = allocate(/mob/living/simple_animal/qareen)
	TEST_ASSERT(can_open_strip_menu(spirit), "A qareen (spirit that strips players by design) was unable to open the strip menu")
