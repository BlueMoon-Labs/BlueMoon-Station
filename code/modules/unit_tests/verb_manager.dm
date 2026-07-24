// ===== SSverb_manager (tg/Paradise port) =====
//
// Expensive player verbs (examine, resist, say/whisper/me, intent switch) get
// wrapped in verb_callbacks: on an overloaded tick (TICK_USAGE above the
// threshold) they queue into SSverb_manager/SSspeech_controller and execute at
// the start of the next tick instead of pushing the current one into overtime.

/mob/unit_test_verb_dummy
	var/bumps = 0

/mob/unit_test_verb_dummy/proc/bump_counter()
	bumps++

/datum/unit_test/verb_manager_queue/Run()
	var/mob/unit_test_verb_dummy/dummy = allocate(/mob/unit_test_verb_dummy)

	// --- Direct queue mechanics: queued callbacks run exactly once and the queue clears ---
	var/datum/callback/verb_callback/queued_callback = VERB_CALLBACK(dummy, TYPE_PROC_REF(/mob/unit_test_verb_dummy, bump_counter))
	SSverb_manager.verb_queue += queued_callback
	SSverb_manager.run_verb_queue()
	TEST_ASSERT_EQUAL(dummy.bumps, 1, "run_verb_queue must invoke the queued callback")
	TEST_ASSERT_EQUAL(length(SSverb_manager.verb_queue), 0, "run_verb_queue must clear the queue")

	// --- Emergency bypass: _queue_verb must refuse deterministically ---
	// (an "underloaded tick refuses" assert would be flaky: TICK_USAGE during
	// the test suite is arbitrary and routinely above any threshold)
	var/old_always_queue = SSverb_manager.always_queue
	SSverb_manager.always_queue = TRUE
	SSverb_manager.FOR_ADMINS_IF_VERBS_FUCKED_immediately_execute_all_verbs = TRUE
	var/bypassed = _queue_verb(VERB_CALLBACK(dummy, TYPE_PROC_REF(/mob/unit_test_verb_dummy, bump_counter)), VERB_DEFAULT_QUEUE_THRESHOLD)
	SSverb_manager.FOR_ADMINS_IF_VERBS_FUCKED_immediately_execute_all_verbs = FALSE
	TEST_ASSERT(!bypassed, "The emergency bypass must refuse to queue (caller then executes inline)")
	TEST_ASSERT_EQUAL(dummy.bumps, 1, "Refusing to queue must not itself invoke the callback")

	// --- always_queue: the callback must land in the queue and run on fire ---
	SSverb_manager.always_queue = TRUE
	var/accepted = _queue_verb(VERB_CALLBACK(dummy, TYPE_PROC_REF(/mob/unit_test_verb_dummy, bump_counter)), VERB_DEFAULT_QUEUE_THRESHOLD, null)
	SSverb_manager.always_queue = old_always_queue
	TEST_ASSERT(accepted, "always_queue must accept the verb into the queue")
	TEST_ASSERT_EQUAL(length(SSverb_manager.verb_queue), 1, "Accepted verb must sit in the queue until the next fire")
	TEST_ASSERT_EQUAL(dummy.bumps, 1, "Queued verb must not run before the subsystem fires")
	SSverb_manager.run_verb_queue()
	TEST_ASSERT_EQUAL(dummy.bumps, 2, "Queued verb must run when the subsystem fires")

	// --- The speech controller subtype shares the same machinery ---
	SSspeech_controller.always_queue = TRUE
	var/speech_accepted = _queue_verb(VERB_CALLBACK(dummy, TYPE_PROC_REF(/mob/unit_test_verb_dummy, bump_counter)), VERB_DEFAULT_QUEUE_THRESHOLD, SSspeech_controller)
	SSspeech_controller.always_queue = FALSE
	TEST_ASSERT(speech_accepted, "SSspeech_controller must accept queued speech verbs")
	SSspeech_controller.run_verb_queue()
	TEST_ASSERT_EQUAL(dummy.bumps, 3, "SSspeech_controller must run its queue")

// ===== mode(): the activated item is captured at press time =====
//
// The verb can sit in the queue for a tick; if the player swaps hands in that
// window, execute_mode must not activate the unexpected item.

/obj/item/unit_test_mode_item
	var/activations = 0

/obj/item/unit_test_mode_item/attack_self(mob/user)
	activations++

/datum/unit_test/verb_mode_hand_capture/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	var/obj/item/unit_test_mode_item/held = allocate(/obj/item/unit_test_mode_item)
	var/obj/item/unit_test_mode_item/other = allocate(/obj/item/unit_test_mode_item)
	TEST_ASSERT(human.put_in_active_hand(held), "test premise: the item must fit the active hand")

	// captured item still held: activates
	human.execute_mode(held)
	TEST_ASSERT_EQUAL(held.activations, 1, "execute_mode with the captured item still held must activate it")

	// hand changed while queued: neither item activates
	human.execute_mode(other)
	TEST_ASSERT_EQUAL(held.activations, 1, "execute_mode must not activate the currently held item when it differs from the captured one")
	TEST_ASSERT_EQUAL(other.activations, 0, "execute_mode must not activate the stale captured item either")

	// pressed with an empty hand, item picked up while queued: no activation
	human.execute_mode(null)
	TEST_ASSERT_EQUAL(held.activations, 1, "execute_mode captured on an empty hand must not activate a later item")
