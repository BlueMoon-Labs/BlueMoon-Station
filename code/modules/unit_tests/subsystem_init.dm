/datum/unit_test/subsystem_init/Run()
	for(var/i in Master.subsystems)
		var/datum/controller/subsystem/ss = i
		if(ss.flags & SS_NO_INIT)
			continue
		if(!ss.initialized)
			TEST_FAIL("[ss]([ss.type]) is a subsystem meant to initialize but doesn't get set as initialized.")

///A subsystem destroyed after Master.Loop() snapshots its runlevel leaves a
///null entry in that snapshot. CheckQueue must discard it without a runtime.
/datum/unit_test/master_checkqueue_null_entry/Run()
	var/list/subsystems_to_check = list(null)
	TEST_ASSERT(Master.CheckQueue(subsystems_to_check), "CheckQueue must tolerate a deleted subsystem in its runlevel snapshot")
	TEST_ASSERT(!length(subsystems_to_check), "CheckQueue must remove the deleted subsystem from its snapshot")
