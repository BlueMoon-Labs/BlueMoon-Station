// SSverb_manager (tg/Paradise port): defer expensive player verbs to the next
// tick when the current one is already overloaded, instead of stacking their
// cost on top of an over-budget tick.

///queue a verb to happen the next tick only if the server is overloaded. this is the default
#define VERB_DEFAULT_QUEUE_THRESHOLD 85
///verbs with a higher priority: only queue if the tick is nearly eaten whole
#define VERB_HIGH_PRIORITY_QUEUE_THRESHOLD 95
///only queue when the tick is in genuine overtime
#define VERB_OVERTIME_QUEUE_THRESHOLD 100

///try to queue the verb callback; evaluates to TRUE if queued, FALSE if the caller should execute it now
#define TRY_QUEUE_VERB(_verb_callback, _tick_check, _subsystem_to_use, _verification_args...) (_queue_verb(_verb_callback, _tick_check, _subsystem_to_use, _verification_args))

///queue the verb callback if the server is overloaded, otherwise execute it immediately.
///routed through a wrapper proc so the callback expression is evaluated exactly once
///(inlining it twice would allocate a second callback datum on every un-queued call)
#define QUEUE_OR_CALL_VERB(_verb_callback, _tick_check, _subsystem_to_use, _verification_args...) _queue_or_call_verb(_verb_callback, _tick_check, _subsystem_to_use, _verification_args)

#define DEFAULT_TRY_QUEUE_VERB(_verb_callback, _verification_args...) (TRY_QUEUE_VERB(_verb_callback, VERB_DEFAULT_QUEUE_THRESHOLD, null, _verification_args))
#define DEFAULT_QUEUE_OR_CALL_VERB(_verb_callback, _verification_args...) QUEUE_OR_CALL_VERB(_verb_callback, VERB_DEFAULT_QUEUE_THRESHOLD, null, _verification_args)
#define TRY_QUEUE_VERB_FOR(_verb_callback, _subsystem_to_use, _verification_args...) (TRY_QUEUE_VERB(_verb_callback, VERB_DEFAULT_QUEUE_THRESHOLD, _subsystem_to_use, _verification_args))
#define QUEUE_OR_CALL_VERB_FOR(_verb_callback, _subsystem_to_use, _verification_args...) QUEUE_OR_CALL_VERB(_verb_callback, VERB_DEFAULT_QUEUE_THRESHOLD, _subsystem_to_use, _verification_args)
