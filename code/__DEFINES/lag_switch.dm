// All of the possible Lag Switch lag mitigation measures (tg port).
// If you add more, do not forget to update MEASURES_AMOUNT accordingly.
// Measures marked "не подключено" are defined for slot compatibility but have
// no wired consumers in this codebase yet - see SSlag_switch.wired_measures.
/// Stops ghosts flying around freely, they can still jump and orbit (не подключено)
#define DISABLE_DEAD_KEYLOOP 1
/// Stops ghosts using zoom/t-ray verbs and resets their view if zoomed out (не подключено)
#define DISABLE_GHOST_ZOOM_TRAY 2
/// Disable runechat for living speakers, mobs with TRAIT_BYPASS_MEASURES exempted
#define DISABLE_RUNECHAT 3
/// Disable icon2html procs from verbs like examine, callers with TRAIT_BYPASS_MEASURES exempted
#define DISABLE_USR_ICON2HTML 4
/// Prevents anyone from joining the game as anything but observer (не подключено)
#define DISABLE_NON_OBSJOBS 5
/// Limit IC chat spam to one message every x seconds per client, TRAIT_BYPASS_MEASURES exempted
#define SLOWMODE_SAY 6
/// Disables parallax, as if everyone had disabled their preference, TRAIT_BYPASS_MEASURES exempted
#define DISABLE_PARALLAX 7
/// Disables footsteps, TRAIT_BYPASS_MEASURES exempted
#define DISABLE_FOOTSTEPS 8
/// Disables runechat rendering for dead viewers (each ghost otherwise generates its own message image)
#define DISABLE_DEAD_RUNECHAT 9

#define MEASURES_AMOUNT 9 // The total number of switches defined above
