#define SEND_TRANSPORT_SIGNAL(sigtype, arguments...) ( SEND_SIGNAL(SStransport, sigtype, ##arguments) )

/// Sent from /obj/structure/transport/linear/tram when it hits someone: (hits_this_round)
#define COMSIG_TRAM_COLLISION "tram_collided"
/// Sent from a mob that just got hit by the tram: (obj/structure/transport/linear/tram)
#define COMSIG_LIVING_HIT_BY_TRAM "tram_hit_me"
/// Request messages to the transport controller from auxiliary devices (crossing signals, buttons, etc.)
#define COMSIG_TRANSPORT_REQUEST "!REQ"
/// Response messages from the transport controller to a COMSIG_TRANSPORT_REQUEST request signal
#define COMSIG_TRANSPORT_RESPONSE "!RESP"
/// Transport controller general status update: (controller, controller_active, controller_status, travel_direction, destination_platform)
#define COMSIG_TRANSPORT_UPDATED "!ACTV"
/// Sent from a linear transport controller when its vertical travel direction changes: (direction)
#define COMSIG_LIFT_SET_DIRECTION "lift_set_direction"
/// Sent to a turf a transport module is about to enter: (list/things_to_move)
#define COMSIG_TURF_INDUSTRIAL_LIFT_ENTER "turf_industrial_life_enter"

// Transport directions
#define INBOUND -1
#define OUTBOUND 1

// Status response codes
#define REQUEST_FAIL "!FAIL"
#define REQUEST_SUCCESS "!ACK"
#define NOT_IN_SERVICE "!NIS"
#define TRANSPORT_IN_USE "!BUSY"
#define INVALID_PLATFORM "!NDEST"
#define NO_CALL_REQUIRED "!NCR"
#define INTERNAL_ERROR "!ERR"
#define BROKEN_BEYOND_REPAIR "!DEAD"

// Tram lines
#define TRAMSTATION_LINE_1 "tram_1"

// Destinations/platforms
#define TRAMSTATION_WEST 1
#define TRAMSTATION_CENTRAL 2
#define TRAMSTATION_EAST 3

// Tram Navigation aids
#define TRAM_NAV_BEACONS "tram_nav"
#define IMMOVABLE_ROD_DESTINATIONS "immovable_rod"

// The lift's controls are currently locked from user input
#define LIFT_PLATFORM_LOCKED 1
// The lift's controls are currently unlocked so user's can direct it
#define LIFT_PLATFORM_UNLOCKED 0

// Flags for the Tram VOBC (vehicle on-board computer)
#define SYSTEM_FAULT (1<<0)
#define COMM_ERROR (1<<1)
#define EMERGENCY_STOP (1<<2)
#define PRE_DEPARTURE (1<<3)
#define DOORS_READY (1<<4)
#define CONTROLS_LOCKED (1<<5)
#define BYPASS_SENSORS (1<<6)
#define RAPID_MODE (1<<7)

#define TRANSPORT_FLAGS list( \
	"SYSTEM_FAULT", \
	"COMM_ERROR", \
	"EMERGENCY_STOP", \
	"PRE_DEPARTURE", \
	"DOORS_READY", \
	"CONTROLS_LOCKED", \
	"BYPASS_SENSORS", \
)

// Logging
#define SUB_TS_STATUS "TS-[english_list(bitfield2list(transport_controller.controller_status, TRANSPORT_FLAGS), nothing_text = "none", and_text = ", ")]"
#define TC_TS_STATUS "TS-[english_list(bitfield2list(controller_status, TRANSPORT_FLAGS), nothing_text = "none", and_text = ", ")]"
#define TC_TA_INFO "TA-[transport_controller.controller_active ? "PROCESSING" : "READY"]"

// Landmarks
#define TRANSPORT_TYPE_ELEVATOR "icts_elev"
#define TRANSPORT_TYPE_TRAM "icts_tram"
#define TRANSPORT_TYPE_DEBUG "icts_debug"

// Tram door cycles
#define CYCLE_OPEN "open"
#define CYCLE_CLOSED "close"

// Tram door close modes
#define DEFAULT_DOOR_CHECKS 0
#define BYPASS_DOOR_CHECKS 2

// Crossing signals
#define XING_STATE_GREEN 0
#define XING_STATE_AMBER 1
#define XING_STATE_RED 2
#define XING_STATE_MALF 3

#define XING_THRESHOLD_AMBER 45
#define XING_THRESHOLD_RED 27

#define DEFAULT_TRAM_LENGTH 10
#define DEFAULT_TRAM_MIDPOINT 5

// Tram machinery subtype
#define TRANSPORT_SYSTEM_NORMAL 0
#define TRANSPORT_REMOTE_WARNING 1
#define TRANSPORT_LOCAL_WARNING 2
#define TRANSPORT_REMOTE_FAULT 3
#define TRANSPORT_LOCAL_FAULT 4
#define TRANSPORT_BREAKDOWN_RATE 0.0175

// Tram structure construction states
#define TRAM_OUT_OF_FRAME 0
#define TRAM_IN_FRAME 1
#define TRAM_SCREWED_TO_FRAME 2

// Layers. Rails sit on FLOOR_PLANE, the rest on GAME_PLANE.
/// Above lattices and catwalks: the tram smashes FLOOR_PLANE structures layered above the rails.
#define TRAM_RAIL_LAYER 2.466
#define TRAM_STRUCTURE_LAYER 2.57
#define TRAM_FLOOR_LAYER 2.58
#define TRAM_WALL_LAYER 2.59
#define TRAM_SIGNAL_LAYER 4.26

#define COLOR_TRAM_BLUE "#6160A8"
#define COLOR_TRAM_LIGHT_BLUE "#A8A7DA"
#define COLOR_DISPLAY_RED "#BE3455"
#define COLOR_DISPLAY_YELLOW "#FFF743"
#define COLOR_DISPLAY_GREEN "#3CF046"
#define COLOR_DISPLAY_BLUE "#22CCFF"
#define LIGHT_COLOR_BABY_BLUE "#00AADC"
#define LIGHT_COLOR_VIVID_GREEN "#3CF046"
#define LIGHT_COLOR_BRIGHT_YELLOW "#FFFF99"

#define istramwall(A) (istype(A, /obj/structure/tram))
