#define INIT_PROFILE_NAME "init_profiler.json"

/// Dumps the world profiler right after initialization finishes, so the cost of
/// server init lives in its own file instead of polluting the round profile
/// (profiler.json / tick-spike dumps). Port of Nova/Bee SSinit_profiler.
/// world.Profile(PROFILE_START) already runs at world/New, so by the time this
/// subsystem initializes (last), the accumulated data is init-only.
SUBSYSTEM_DEF(init_profiler)
	name = "Init Profiler"
	init_order = INIT_ORDER_INIT_PROFILER
	flags = SS_NO_FIRE

/datum/controller/subsystem/init_profiler/Initialize()
	if(CONFIG_GET(flag/auto_profile))
		write_init_profile()
	return ..()

/datum/controller/subsystem/init_profiler/proc/write_init_profile()
#if DM_BUILD >= 1506
	var/current_profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	CHECK_TICK

	if(!length(current_profile_data))
		stack_trace("Warning, profiling stopped manually before the init dump.")
	var/prof_file = file("[GLOB.log_directory]/[INIT_PROFILE_NAME]")
	if(fexists(prof_file))
		fdel(prof_file)
	WRITE_FILE(prof_file, current_profile_data)
	// Now that init data is written out, clear it so the round profile
	// (SSprofiler dumps, tick-spike dumps) starts from a clean slate.
	world.Profile(PROFILE_CLEAR)
#endif

#undef INIT_PROFILE_NAME
