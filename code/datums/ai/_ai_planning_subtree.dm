///A subtree is attached to a controller and is occasionally called by /ai_controller/SelectBehaviors(), this mainly exists to act as a way to subtype and modify SelectBehaviors() without needing to subtype the ai controller itself
/datum/ai_planning_subtree
	///Решает по таймеру самого моба, а не блэкборда: готовность таймера входит в сводку плана hostile_adapter
	var/gated_by_pawn_timer = FALSE

///Для gated_by_pawn_timer: TRUE, когда таймер моба, по которому решает сабтри, истёк
/datum/ai_planning_subtree/proc/pawn_timer_ready(datum/ai_controller/controller)
	return TRUE

///Determines what behaviors should the controller try processing; if this returns SUBTREE_RETURN_FINISH_PLANNING then the controller won't go through the other subtrees should multiple exist in controller.planning_subtrees
/datum/ai_planning_subtree/proc/SelectBehaviors(datum/ai_controller/controller, delta_time)
	return
