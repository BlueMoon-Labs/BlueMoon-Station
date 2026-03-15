#ifdef MEMORY_PROFILER

#define MEMORYSTATS_FILENAME "memory_profiler.json"
#define MEMORYSTATS_MAX_SNAPSHOTS 60
#define MEMORYSTATS_MAX_BASELINES 10

/var/__memorystats

/proc/__detect_memorystats()
	if(world.system_type == UNIX)
		return __memorystats = "./libmemorystats.so"
	else
		return __memorystats = "./memorystats.dll"

#define MEMORYSTATS (__memorystats || __detect_memorystats())

/proc/memorystats_get()
	return call_ext(MEMORYSTATS, "memory_stats")()

#endif
