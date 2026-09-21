/datum/unit_test/medipen_refiller_cycles/Run()
	var/obj/machinery/medipen_refiller/machine = allocate(/obj/machinery/medipen_refiller)
	machine.set_machine_stat(0)
	var/obj/item/reagent_containers/hypospray/medipen/pen = allocate(/obj/item/reagent_containers/hypospray/medipen)
	pen.reagents.clear_reagents()
	pen.reagents.maximum_volume = 0
	pen.reagent_flags = NONE
	pen.forceMove(machine)
	machine.medipens[1] = pen
	TEST_ASSERT(machine.start_refill(1), "An empty supported medipen should start refilling")
	TEST_ASSERT_EQUAL(pen.reagents.total_volume, 0, "Starting a timer must not add reagents")
	TEST_ASSERT_EQUAL(pen.reagents.maximum_volume, 0, "Starting a timer must not repair the medipen")
	var/list/cancelled_job = machine.refill_jobs[pen]
	machine.eject_medipen(1)
	TEST_ASSERT_EQUAL(length(machine.refill_jobs), 0, "Ejection must cancel the timer")
	TEST_ASSERT_EQUAL(pen.reagent_flags, NONE, "Cancellation must preserve spent flags")
	TEST_ASSERT_EQUAL(pen.reagents.maximum_volume, 0, "Cancellation must preserve spent capacity")
	pen.forceMove(machine)
	machine.medipens[1] = pen
	TEST_ASSERT(machine.start_refill(1), "A cancelled medipen should be reusable")
	machine.finish_refill(pen, cancelled_job)
	TEST_ASSERT_EQUAL(pen.reagents.total_volume, 0, "A stale callback must not complete a new job")
	machine.set_machine_stat(NOPOWER)
	TEST_ASSERT_EQUAL(length(machine.refill_jobs), 0, "Power loss must cancel all jobs immediately")
	TEST_ASSERT_EQUAL(pen.reagents.total_volume, 0, "Power loss must not refill the medipen")
	machine.set_machine_stat(0)
	TEST_ASSERT(machine.start_refill(1), "Restored power should allow a new cycle")
	// Complete the real callback without making the test sleep for 30 seconds.
	var/list/job = machine.refill_jobs[pen]
	deltimer(job["timer"])
	job["timer"] = null
	job["start"] = world.time - job["duration"]
	machine.finish_refill(pen, job)
	TEST_ASSERT_EQUAL(pen.reagents.maximum_volume, initial(pen.volume), "Completion must restore capacity")
	TEST_ASSERT_EQUAL(pen.reagent_flags, initial(pen.reagent_flags), "Completion must restore usability")
	for(var/reagent_type in pen.list_reagents)
		TEST_ASSERT(abs(pen.reagents.get_reagent_amount(reagent_type) - pen.list_reagents[reagent_type]) < 0.001, "Completion must restore every ingredient within reagent precision")
	TEST_ASSERT(!machine.start_refill(1), "A filled medipen must not start another cycle")
	TEST_ASSERT_EQUAL(length(machine.refill_jobs), 0, "Completion must clear the job")
	machine.eject_medipen(1)
	var/obj/item/reagent_containers/hypospray/medipen/stimpack/traitor/forbidden = allocate(/obj/item/reagent_containers/hypospray/medipen/stimpack/traitor)
	forbidden.reagents.clear_reagents()
	forbidden.forceMove(machine)
	machine.medipens[1] = forbidden
	TEST_ASSERT(!machine.start_refill(1), "Allowed parents must not authorize unsupported subtypes")

/datum/unit_test/medipen_refiller_parts/Run()
	var/obj/machinery/medipen_refiller/machine = allocate(/obj/machinery/medipen_refiller)
	machine.set_machine_stat(0)
	var/obj/item/reagent_containers/hypospray/medipen/first = allocate(/obj/item/reagent_containers/hypospray/medipen)
	var/obj/item/reagent_containers/hypospray/medipen/second = allocate(/obj/item/reagent_containers/hypospray/medipen)
	first.reagents.clear_reagents()
	second.reagents.clear_reagents()
	first.forceMove(machine)
	second.forceMove(machine)
	machine.medipens[1] = first
	machine.medipens[4] = second
	TEST_ASSERT(machine.start_refill(1) && machine.start_refill(4), "Separate slots should run concurrently")
	first.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(length(machine.refill_jobs), 1, "External removal must cancel only that slot")
	TEST_ASSERT_NULL(machine.medipens[1], "External removal must clear the slot")
	for(var/obj/item/stock_parts/part in machine.component_parts)
		part.rating = 1
	machine.RefreshParts()
	TEST_ASSERT_EQUAL(length(machine.refill_jobs), 0, "Changing parts must cancel active cycles")
	TEST_ASSERT(second.loc != machine, "Shrinking capacity must eject excess medipens")
	TEST_ASSERT_EQUAL(second.reagents.total_volume, 0, "Shrinking capacity must not refill a medipen")
