// Manipulator task disk
/obj/item/disk/manipulator
	name = "manipulator task disk"
	desc = "A floppy disk containing manipulator tasks."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk0"
	w_class = WEIGHT_CLASS_TINY
	item_state = "card-id"
	lefthand_file = 'icons/mob/inhands/equipment/idcards_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/idcards_righthand.dmi'
	var/list/tasks_data = list()
	var/read_only = FALSE

/obj/item/disk/manipulator/proc/set_tasks(list/new_tasks_data)
	if(read_only)
		return FALSE
	tasks_data = islist(new_tasks_data) ? new_tasks_data : list()
	return TRUE

/obj/item/disk/manipulator/proc/get_tasks()
	return tasks_data?.Copy() || list()


#define MIN_SPEED_MULTIPLIER_TIER_1 0.5
#define MIN_SPEED_MULTIPLIER_TIER_2 0.4
#define MIN_SPEED_MULTIPLIER_TIER_3 0.3
#define MIN_SPEED_MULTIPLIER_TIER_4 0.1

#define MAX_SPEED_MULTIPLIER_TIER_1 2
#define MAX_SPEED_MULTIPLIER_TIER_2 3
#define MAX_SPEED_MULTIPLIER_TIER_3 5
#define MAX_SPEED_MULTIPLIER_TIER_4 6

#define MAX_TASKS_TIER_1 6
#define MAX_TASKS_TIER_2 12
#define MAX_TASKS_TIER_3 24
#define MAX_TASKS_TIER_4 32


#define BASE_POWER_USAGE 0.2
#define BASE_INTERACTION_TIME 0.3 SECONDS

/// How long will the manipulator wait if there's nothing to do
#define CYCLE_SKIP_TIMEOUT 1 SECONDS

// How should overflow be handled by drop tasks
#define POINT_OVERFLOW_ALLOWED "ALLOW"
#define POINT_OVERFLOW_HELD "TO HELD"
#define POINT_OVERFLOW_FORBIDDEN "FORBID"

#define PICKUP_EAGER "Always Pick Up"
#define PICKUP_CAN_WAIT "Wait For Suiting"

#define TASK_TYPE_PICKUP "pickup"
#define TASK_TYPE_DROP "drop"
#define TASK_TYPE_THROW "throw"
#define TASK_TYPE_WAIT "wait"

#define TASKING_SEQUENTIAL "Sequential"
#define TASKING_STRICT "Strict order"
