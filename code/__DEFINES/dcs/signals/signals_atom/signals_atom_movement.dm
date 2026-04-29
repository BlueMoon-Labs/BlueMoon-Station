/// Called from /mob/living/PushAM -- Called when this mob is about to push a movable, but before it moves
/// (aotm/movable/being_pushed)
#define COMSIG_LIVING_PUSHING_MOVABLE "living_pushing_movable"

/// Return to stop the door opening on bump.
#define STOP_BUMP (1<<0)

///called when the movable's glide size is updated: (new_glide_size)
#define COMSIG_MOVABLE_UPDATE_GLIDE_SIZE "movable_glide_size"
/// before applying drift glide visuals: ()
#define COMSIG_MOVABLE_DRIFT_VISUAL_ATTEMPT "movable_drift_visual_attempt"
	#define DRIFT_VISUAL_FAILED (1<<0)
/// when checking input lock after drift: ()
#define COMSIG_MOVABLE_DRIFT_BLOCK_INPUT "movable_drift_block_input"
	#define DRIFT_ALLOW_INPUT (1<<0)
