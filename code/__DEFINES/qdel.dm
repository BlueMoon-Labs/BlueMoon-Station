//! Defines that give qdel hints.
//!
//! These can be given as a return in [/atom/proc/Destroy] or by calling [/proc/qdel].

/// `qdel` should queue the object for deletion.
#define QDEL_HINT_QUEUE 0
/// `qdel` should let the object live after calling [/atom/proc/Destroy].
#define QDEL_HINT_LETMELIVE 1
/// Functionally the same as the above. `qdel` should assume the object will gc on its own, and not check it.
#define QDEL_HINT_IWILLGC 2
/// Qdel should assume this object won't GC, and queue a hard delete using a hard reference.
#define QDEL_HINT_HARDDEL 3
// Qdel should assume this object won't gc, and hard delete it posthaste.
#define QDEL_HINT_HARDDEL_NOW 4


#ifdef REFERENCE_TRACKING
/** If REFERENCE_TRACKING is enabled, qdel will call this object's find_references() verb.
 *
 * Functionally identical to [QDEL_HINT_QUEUE] if [GC_FAILURE_HARD_LOOKUP] is not enabled in _compiler_options.dm.
*/
#define QDEL_HINT_FINDREFERENCE 5
/// Behavior as [QDEL_HINT_FINDREFERENCE], but only if the GC fails and a hard delete is forced.
#define QDEL_HINT_IFFAIL_FINDREFERENCE 6
#endif

/// Queue normally, but treat a softcheck miss as an operator-facing alert.
/// Prefer this canonical name over the deprecated QUICKDEL alias below.
#define QDEL_HINT_SOFTFAIL_ALERT 7
/// Deprecated alias kept for compatibility. This does not imply a sub-10s timeout.
#define QDEL_HINT_QUICKDEL QDEL_HINT_SOFTFAIL_ALERT
/// Known-slow cleanup (fires many sub-qdels, events). Suppresses the spurious softcheck warning.
#define QDEL_HINT_SLOWDESTROY 8
/// Try soft GC first (Q1 softcheck); on failure, skip warnfail logging and promote directly to hard-delete (Q3).
#define QDEL_HINT_QUEUE_THEN_HARDDEL 9

// ===== Queue levels =====
/// First pass: has the object GC'd yet? Most objects pass within 30 seconds.
#define GC_QUEUE_SOFTCHECK  1
/// Backward compatibility alias for GC_QUEUE_SOFTCHECK.
#define GC_QUEUE_CHECK      1
/// Warning level: object still alive after 30s. Log, notify admins, continue waiting.
#define GC_QUEUE_WARNFAIL   2
/// Hard delete: object survived ~2 minutes total. Force del().
#define GC_QUEUE_HARDDELETE 3
/// Total number of queue levels. Increase when adding more.
#define GC_QUEUE_COUNT      3

// ===== Queue timeouts =====
/// Time before softcheck failure is logged (30 seconds).
#define GC_SOFTCHECK_TIMEOUT  (30 SECONDS)
/// Time before warnfail escalates to hard delete (90 seconds).
#define GC_WARNFAIL_TIMEOUT   (90 SECONDS)
/// Time before hard delete fires (15 seconds).
#define GC_HARDDEL_TIMEOUT    (15 SECONDS)
/// Historical delayed-qdel threshold: timers above this use weakrefs instead of strong refs.
#define GC_FILTER_QUEUE (2 MINUTES)
/// Historical hard-delete grace window used outside the GC subsystem.
#define GC_DEL_QUEUE    (10 SECONDS)

/// Trim the dead prefix from a queue once this many tombstoned entries accumulate.
#define GC_COMPACT_THRESHOLD 5000
/// HOLD-mode millisecond budget for the harddelete pass per fire().
#define GC_HARDDEL_BUDGET_MIN_MS 18
/// RECOVER-mode millisecond budget for the harddelete pass per fire().
#define GC_HARDDEL_BUDGET_MAX_MS 30
/// Queue depth at which GC enters overflow mode and temporarily spends more time draining hard deletes.
#define GC_HARDDEL_OVERFLOW_THRESHOLD 4000
/// OVERFLOW-mode millisecond budget for the harddelete pass per fire().
#define GC_HARDDEL_OVERFLOW_BUDGET_MAX_MS 60
/// Queue depth at which the hard-delete budget starts scaling up from MIN toward MAX.
#define GC_HARDDEL_PRESSURE_THRESHOLD 50
/// HOLD-mode maximum number of del() calls per fire(), regardless of remaining budget.
#define GC_HARDDEL_HOLD_MAX_PER_FIRE 3
/// RECOVER-mode maximum number of del() calls per fire(), regardless of remaining budget.
#define GC_HARDDEL_MAX_PER_FIRE 5
/// Absolute maximum number of del() calls per fire() while overflow mode is active.
#define GC_HARDDEL_OVERFLOW_MAX_PER_FIRE 8
/// LOBBY-mode millisecond budget for the harddelete pass per fire().
#define GC_HARDDEL_LOBBY_BUDGET_MS 200
/// LOBBY-mode maximum number of del() calls per fire().
#define GC_HARDDEL_LOBBY_MAX_PER_FIRE 50
/// Queue depth below which GC may enter HOLD mode if the sampled trend is healthy.
#define GC_HARDDEL_RECOVER_THRESHOLD 1200
/// Target q3 growth rate needed before GC may settle into HOLD mode.
#define GC_HARDDEL_TARGET_Q3_DELTA_PER_SECOND -0.1
/// Consecutive healthy queue-health samples needed before returning to HOLD mode.
#define GC_HARDDEL_MODE_HYSTERESIS_SAMPLES 2

// ===== Ring buffer sizes =====
/// Max entries in the recent-failures ring buffer.
#define GC_FAILURE_RING_SIZE     30
/// Max entries in the recent-hard-deletes ring buffer.
#define GC_HARDDEL_RING_SIZE     20
/// Rolling harddelete yield history window, in GC fire() calls that reached the harddelete pass.
#define GC_HARDDEL_YIELD_HISTORY_SIZE 60
/// Sample queue depths every this many fire() calls (~seconds).
#define GC_DEPTH_SAMPLE_INTERVAL 30
/// Keep this many depth samples (GC_DEPTH_SAMPLE_INTERVAL * this = history window in seconds).
#define GC_DEPTH_HISTORY_SIZE    60
/// Maximum pending queue slots to inspect when rendering the admin queue sample.
#define GC_QUEUE_PREVIEW_SCAN_LIMIT 250

// ===== qdel_item flags =====
/// Set when admins are told about lag-causing qdels for this type.
#define QDEL_ITEM_ADMINS_WARNED      (1<<0)
/// Set when a type can no longer be hard deleted on failure because of lag.
#define QDEL_ITEM_SUSPENDED_FOR_LAG  (1<<1)
/// Admin-set: run fast reference scan immediately on softcheck failure.
#define QDEL_ITEM_FAST_REFTRACK      (1<<2)
/// Set when at least one instance of the type used QDEL_HINT_SOFTFAIL_ALERT this round.
#define QDEL_ITEM_SOFTFAIL_ALERT     (1<<3)
/// Deprecated alias kept for compatibility with older code and logs.
#define QDEL_ITEM_QUICKDEL           QDEL_ITEM_SOFTFAIL_ALERT
/// Set when at least one instance of the type used QDEL_HINT_SLOWDESTROY this round.
#define QDEL_ITEM_SLOWDESTROY        (1<<4)
/// Admin-set or default: skip reference scanning on GC failure for this type.
#define QDEL_ITEM_SKIP_REFSCAN       (1<<5)

// ===== gc_failure_viewer caps =====
/// Max entries in gc_failure_cache.failures before oldest is dropped.
#define GC_FAILURE_ENTRY_LIMIT        500
/// Max entries per gc_failure_source.failures before oldest is dropped.
#define GC_FAILURE_SOURCE_ENTRY_LIMIT  50

// ===== gc_destroyed variable states =====
/// Object has been marked for queuing (rarely used).
#define GC_QUEUED_FOR_QUEUING        -1
/// Object is currently inside its Destroy() proc.
#define GC_CURRENTLY_BEING_QDELETED  -2

// ===== Hard-delete controller modes =====
#define GC_HARDDEL_MODE_HOLD 1
#define GC_HARDDEL_MODE_RECOVER 2
#define GC_HARDDEL_MODE_OVERFLOW 3
#define GC_HARDDEL_MODE_LOBBY 4

// ===== Convenience macros =====
#define QDELING(X)    (X.gc_destroyed)
#define QDELETED(X)   (isnull(X) || QDELING(X))
#define QDESTROYING(X) (!X || X.gc_destroyed == GC_CURRENTLY_BEING_QDELETED)
