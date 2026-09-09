/// Called from /mob/living/PushAM -- Called when this mob is about to push a movable, but before it moves
/// (aotm/movable/being_pushed)
#define COMSIG_LIVING_PUSHING_MOVABLE "living_pushing_movable"

/// Return to stop the door opening on bump.
#define STOP_BUMP (1<<0)

///called when the movable's glide size is updated: (new_glide_size)
#define COMSIG_MOVABLE_UPDATE_GLIDE_SIZE "movable_glide_size"
