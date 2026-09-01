///Called when an item is dried by a drying rack
#define COMSIG_ITEM_DRIED "item_dried"
///from base of obj/item/on_grind(): ())
#define COMSIG_ITEM_ON_GRIND "on_grind"
///from base of obj/item/on_juice(): ()
#define COMSIG_ITEM_ON_JUICE "on_juice"
///from /obj/machinery/hydroponics/attackby() when an object is used as compost: (mob/user)
#define COMSIG_ITEM_ON_COMPOSTED "on_composted"

// Modular computer / tablet / PDA signals
///When a tablet's ID is changed (used for uplink ringtone)
#define COMSIG_TABLET_CHANGE_ID "comsig_tablet_change_id"
	#define COMPONENT_STOP_RINGTONE_CHANGE (1<<0)
///Sent before detonating a tablet bomb, to allow blocking the explosion
#define COMSIG_TABLET_CHECK_DETONATE "pda_check_detonate"
	#define COMPONENT_TABLET_NO_DETONATE (1<<0)
