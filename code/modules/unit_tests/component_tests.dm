/datum/unit_test/component_duping/Run()
	var/list/bad_dms = list()
	var/list/bad_dts = list()
	for(var/t in typesof(/datum/component))
		var/datum/component/comp = t
		if(!isnum(initial(comp.dupe_mode)))
			bad_dms += t
		var/dupe_type = initial(comp.dupe_type)
		if(dupe_type && !ispath(dupe_type))
			bad_dts += t
	TEST_ASSERT(!length(bad_dms) && !length(bad_dts),
		"Components with invalid dupe modes: ([bad_dms.Join(",")]) ||| Components with invalid dupe types: ([bad_dts.Join(",")])")

/datum/unit_test_signal_listener
	var/calls = 0
	var/datum/unit_test_signal_listener/listener_to_unregister

/datum/unit_test_signal_listener/proc/receive(datum/source)
	SIGNAL_HANDLER
	calls++
	if(listener_to_unregister)
		listener_to_unregister.UnregisterSignal(source, "unit_test_signal_snapshot")

///One listener unregistering another must not cancel the signal already in flight.
/datum/unit_test/signal_dispatch_snapshots_receivers/Run()
	var/datum/emitter = new
	var/datum/unit_test_signal_listener/first = new
	var/datum/unit_test_signal_listener/second = new
	first.listener_to_unregister = second
	first.RegisterSignal(emitter, "unit_test_signal_snapshot", TYPE_PROC_REF(/datum/unit_test_signal_listener, receive))
	second.RegisterSignal(emitter, "unit_test_signal_snapshot", TYPE_PROC_REF(/datum/unit_test_signal_listener, receive))

	SEND_SIGNAL(emitter, "unit_test_signal_snapshot")
	TEST_ASSERT_EQUAL(first.calls, 1, "The first signal listener must run once")
	TEST_ASSERT_EQUAL(second.calls, 1, "A listener removed mid-dispatch must still receive the in-flight signal")

	qdel(first)
	qdel(second)
	qdel(emitter)

/// Ian pinpointers are strong target holders. The qdelete signal must clear
/// all of them before the dog enters GC, even when several listeners coexist.
/datum/unit_test/ian_pinpointer_target_qdel/Run()
	var/mob/living/simple_animal/pet/dog/corgi/dog = new(run_loc_floor_bottom_left)
	var/list/obj/item/pinpointer/ian/pinpointers = list()
	for(var/i in 1 to 3)
		var/obj/item/pinpointer/ian/pinpointer = allocate(/obj/item/pinpointer/ian, run_loc_floor_bottom_left)
		pinpointer.set_target(dog)
		pinpointers += pinpointer

	qdel(dog)
	for(var/obj/item/pinpointer/ian/pinpointer as anything in pinpointers)
		TEST_ASSERT_NULL(pinpointer.target, "Every Ian pinpointer must release a qdeleted dog synchronously")
