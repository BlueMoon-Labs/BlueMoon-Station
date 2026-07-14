//#define TESTING //By using the testing("message") proc you can create debug-feedback for people with this
								//uncommented, but not visible in the release version)

//#define DATUMVAR_DEBUGGING_MODE //Enables the ability to cache datum vars and retrieve later for debugging which vars changed.

// Comment this out if you are debugging problems that might be obscured by custom error handling in world/Error
#ifdef DEBUG
#define USE_CUSTOM_ERROR_HANDLER
#endif

#ifdef TESTING
#define DATUMVAR_DEBUGGING_MODE

// Рефтрекер компилируется всегда (code/modules/admin/view_variables/reference_tracking.dm).
// Авто-сканы при GC-фейлах гейтятся рантаймом: SSgarbage.reftrack_mode (панель GC / конфиг gc_reftrack_mode).

/*
* Enables debug messages for every single reaction step. This is 1 message per 0.5s for a SINGLE reaction. Useful for tracking down bugs/asking me for help in the main reaction handiler (equilibrium.dm).
*
* * Requires TESTING to be defined to work.
*/
//#define REAGENTS_TESTING

// #define VISUALIZE_ACTIVE_TURFS //Highlights atmos active turfs in green
// #define TRACK_MAX_SHARE //Allows max share tracking, for use in the atmos debugging ui
#endif //ifdef TESTING

//#define UNIT_TESTS //If this is uncommented, we do a single run though of the game setup and tear down process with unit tests in between

// If this is uncommented, will attempt to load and initialize prof.dll/libprof.so.
// We do not ship byond-tracy. Build it yourself here: https://github.com/mafemergency/byond-tracy/
//#define USE_BYOND_TRACY

#ifndef PRELOAD_RSC //set to:
#define PRELOAD_RSC 0 // 0 to allow using external resources or on-demand behaviour;
#endif // 1 to use the default behaviour;
								// 2 for preloading absolutely everything;

#ifdef LOWMEMORYMODE
#ifdef ABSOLUTE_MINIMUM_MODE
#define FORCE_MAP "_maps/runtimestation_minimal.json"
#else
#define FORCE_MAP "_maps/runtimestation.json"
#endif
#endif

//Additional code for the above flags.
#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif

#if defined(UNIT_TESTS)
// Хуки записи found_refs/should_save_refs для тестов рефтрекера (find_reference_sanity и др.).
#define REFERENCE_TRACKING_DEBUG
#endif

#ifdef TGS
// TGS performs its own build of dm.exe, but includes a prepended TGS define.
#define CBT
#endif

#if !defined(CBT) && !defined(SPACEMAN_DMM)
#warn Building with Dream Maker is no longer supported and will result in errors.
#warn In order to build, run BUILD.bat in the root directory.
#warn Consider switching to VSCode editor instead, where you can press Ctrl+Shift+B to build.
#endif

// Uncomment this to enable profiling via Tracy.
// You will need to compile your own copy of prof.dll in order to use it.
// Find the source code and build instructions here: https://github.com/mafemergency/byond-tracy/
// #define TRACY_PROFILING

// Enables GC per-fire CSV profiler. Writes to data/logs/gc_profiler.csv and gc_profiler_types.csv.
// Use to diagnose GC performance bottlenecks. No runtime overhead when commented out.
// #define GC_PROFILER
