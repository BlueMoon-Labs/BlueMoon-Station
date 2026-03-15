#ifdef MEMORY_PROFILER

#define MEMORYSTATS_FILENAME "memory_profiler.json"
#define MEMORYSTATS_MAX_SNAPSHOTS 60
#define MEMORYSTATS_MAX_BASELINES 10
#define MEMORYSTATS_INIT_BASELINE_NAME "Init"

/* This comment bypasses grep checks */ /var/__memorystats
/* This comment bypasses grep checks */ /var/__memorystats_unavailable = FALSE

/proc/__detect_memorystats()
	if(world.system_type == UNIX)
		return __memorystats = "./libmemorystats.so"
	else
		return __memorystats = "./memorystats.dll"

#define MEMORYSTATS (__memorystats || __detect_memorystats())

/proc/memorystats_get()
	if(__memorystats_unavailable)
		return null
	. = call_ext(MEMORYSTATS, "memory_stats")()
	if(!.)
		__memorystats_unavailable = TRUE

/client
	/// Per-client active baseline name for memory profiler
	var/memorystats_active_baseline = MEMORYSTATS_INIT_BASELINE_NAME

#endif
