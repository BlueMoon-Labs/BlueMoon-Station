#define GLOBAL_PROC	"some_magic_bullshit"
/// A shorthand for the callback datum, [documented here](datum/callback.html)
#define CALLBACK new /datum/callback
#define INVOKE_ASYNC(proc_owner, proc_path, proc_arguments...) \
	if ((proc_owner) == GLOBAL_PROC) { \
		ASYNC { \
			call(proc_path)(##proc_arguments); \
		}; \
	} \
	else { \
		ASYNC { \
			/* Written with `0 ||` to avoid the compiler seeing call("string"), and thinking it's a deprecated DLL */ \
			call(0 || proc_owner, proc_path)(##proc_arguments); \
		}; \
	}
#define CALLBACK_NEW(typepath, args) CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(___callbacknew), typepath, args)
/// A shorthand for the verb callback datum, used by the SSverb_manager queueing macros
#define VERB_CALLBACK new /datum/callback/verb_callback
///Per the DM reference, spawn(-1) will execute the spawned code immediately until a block is met.
#define MAKE_SPAWN_ACT_LIKE_WAITFOR -1
///Create a codeblock that will not block the callstack if a block is met.
#define ASYNC spawn(MAKE_SPAWN_ACT_LIKE_WAITFOR)
