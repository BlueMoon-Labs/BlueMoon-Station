GLOBAL_LIST_EMPTY(cable_list)					    //Index for all cables, so that powernets don't have to look through the entire world all the time
GLOBAL_LIST_EMPTY(portals)					        //list of all /obj/effect/portal
GLOBAL_LIST_EMPTY(airlocks)					        //list of all airlocks
GLOBAL_LIST_EMPTY(PDAs)							    //list of all PDAs (modular_computer/pda)

// Associative list of ringtone name -> sound file
GLOBAL_LIST_INIT(pda_ringtones, list(\
	"Beep" = 'sound/machines/twobeep.ogg',\
	"Boom" = 'sound/effects/explosion1.ogg',\
	"Honk" = 'sound/items/bikehorn.ogg',\
	"SKREE" = 'sound/voice/shriek1.ogg',\
	"Xeno" = 'sound/voice/hiss2.ogg',\
	"Clown" = 'sound/items/AirHorn2.ogg',\
	"Bzzt" = 'sound/machines/buzz-sigh.ogg',\
	"Ding" = 'sound/machines/ding.ogg',\
	"Chirp" = 'sound/machines/chime.ogg',\
	"Pew" = 'sound/weapons/laser.ogg',\
	"Boop" = 'sound/machines/terminal_select.ogg',\
	"Ping" = 'sound/machines/ping.ogg',\
	"Synth" = 'sound/misc/interference.ogg',\
	"Stalker" = 'sound/items/PDA/stalk1.ogg',\
	"NewQuest" = 'sound/items/PDA/stalk2.ogg',\
))
// List of available ringtone names for UI picking
GLOBAL_LIST_INIT(pda_ringtone_list, list(\
	"Beep", "Boom", "Honk", "SKREE", "Xeno", "Clown",\
	"Bzzt", "Ding", "Chirp", "Pew", "Boop", "Ping",\
	"Synth", "Stalker", "NewQuest",\
))

//PDA themes
GLOBAL_LIST_INIT(default_pda_themes, list(\
	PDA_THEME_NTOS_NAME = PDA_THEME_NTOS,\
	PDA_THEME_DARK_MODE_NAME = PDA_THEME_DARK_MODE,\
	PDA_THEME_RETRO_NAME = PDA_THEME_RETRO,\
	PDA_THEME_SYNTH_NAME = PDA_THEME_SYNTH,\
	PDA_THEME_TERMINAL_NAME = PDA_THEME_TERMINAL,\
))
GLOBAL_LIST_INIT(pda_name_to_theme, list(\
	PDA_THEME_NTOS_NAME = PDA_THEME_NTOS,\
	PDA_THEME_DARK_MODE_NAME = PDA_THEME_DARK_MODE,\
	PDA_THEME_RETRO_NAME = PDA_THEME_RETRO,\
	PDA_THEME_SYNTH_NAME = PDA_THEME_SYNTH,\
	PDA_THEME_TERMINAL_NAME = PDA_THEME_TERMINAL,\
	PDA_THEME_SYNDICATE_NAME = PDA_THEME_SYNDICATE,\
	PDA_THEME_CAT_NAME = PDA_THEME_CAT,\
	PDA_THEME_LIGHT_MODE_NAME = PDA_THEME_LIGHT_MODE,\
))

/// Associative list of all registered PDA messengers (ref -> messenger)
GLOBAL_LIST_EMPTY_TYPED(pda_messengers, /datum/computer_file/program/messenger)
/// All messengers sorted by job
GLOBAL_LIST_EMPTY_TYPED(pda_messengers_by_job, /datum/computer_file/program/messenger)
/// All messengers sorted by name
GLOBAL_LIST_EMPTY_TYPED(pda_messengers_by_name, /datum/computer_file/program/messenger)

/// Cached global list of all emoji icon state names
GLOBAL_LIST_EMPTY(cached_emoji_list)
/// Cached global dict of emoji name -> base64 PNG data
GLOBAL_LIST_EMPTY(cached_emoji_base64)

GLOBAL_LIST_EMPTY(mechas_list)				        //list of all mechs. Used by hostile mobs target tracking.
GLOBAL_LIST_EMPTY(shuttle_caller_list)  		    //list of all communication consoles and AIs, for automatic shuttle calls when there are none.
GLOBAL_LIST_EMPTY(machines)					        //NOTE: this is a list of ALL machines now. The processing machines list is SSmachine.processing !
GLOBAL_LIST_EMPTY(navigation_computers)				//list of all /obj/machinery/computer/camera_advanced/shuttle_docker
GLOBAL_LIST_EMPTY(syndicate_shuttle_boards)	        //important to keep track of for managing nukeops war declarations.
GLOBAL_LIST_EMPTY(real_syndicate_shuttle_boards)	        //important to keep track of for managing nukeops war declarations.
GLOBAL_LIST_EMPTY(navbeacons)					    //list of all bot nagivation beacons, used for patrolling.
GLOBAL_LIST_EMPTY(teleportbeacons)			        //list of all tracking beacons used by teleporters
GLOBAL_LIST_EMPTY(deliverybeacons)			        //list of all MULEbot delivery beacons.
GLOBAL_LIST_EMPTY(deliverybeacontags)			    //list of all tags associated with delivery beacons.
GLOBAL_LIST_EMPTY(nuke_list)
GLOBAL_LIST_EMPTY(alarmdisplay)				        //list of all machines or programs that can display station alerts
GLOBAL_LIST_EMPTY(singularities)				    //list of all singularities on the station (actually technically all engines)
GLOBAL_LIST_EMPTY(grounding_rods)					//list of all grounding rods on the station

GLOBAL_LIST_INIT(celltimers_list, list()) // list of all cell timers
GLOBAL_LIST_INIT(cell_logs, list())
GLOBAL_LIST_INIT(prisoncomputer_list, list())

GLOBAL_LIST(chemical_reactions_list)				//list of all /datum/chemical_reaction datums. Used during chemical reactions
GLOBAL_LIST(drink_reactions_list)				//list of all /datum/chemical_reaction datums where the output is of type /datum/reagent/consumable for bartender PDA
GLOBAL_LIST(normalized_chemical_reactions_list)			//list of all /datum/chemical_reaction datums with actual sane indexing for chemistry PDA
GLOBAL_LIST(chemical_reagents_list)				//list of all /datum/reagent datums indexed by reagent id. Used by chemistry stuff
GLOBAL_LIST_EMPTY(tech_list)					//list of all /datum/tech datums indexed by id.
GLOBAL_LIST_EMPTY(surgeries_list)				//list of all surgeries by name, associated with their path.
GLOBAL_LIST_EMPTY(uplink_categories)			//list of all uplink categories, listed by the order they are loaded in code. Be careful.
GLOBAL_LIST_EMPTY(crafting_recipes)				//list of all table craft recipes
GLOBAL_LIST_EMPTY(rcd_list)					//list of Rapid Construction Devices.
GLOBAL_LIST_EMPTY(apcs_list)					//list of all Area Power Controller machines, separate from machines for powernet speeeeeeed.
GLOBAL_LIST_EMPTY(tracked_implants)			//list of all current implants that are tracked to work out what sort of trek everyone is on. Sadly not on lavaworld not implemented...
GLOBAL_LIST_EMPTY(tracked_chem_implants)			//list of implants the prisoner console can track and send inject commands too
GLOBAL_LIST_EMPTY(poi_list)					//list of points of interest for observe/follow
GLOBAL_LIST_EMPTY(pinpointer_list)			//list of all pinpointers. Used to change stuff they are pointing to all at once.
GLOBAL_LIST_EMPTY(electrochromatic_window_lookup)	// associative id -> smart-tint atoms (windows, windoors, glass airlocks); toggled via electrochromatic button
GLOBAL_LIST_EMPTY(zombie_infection_list) 		// A list of all zombie_infection organs, for any mass "animation"
GLOBAL_LIST_EMPTY(meteor_list)				// List of all meteors.
GLOBAL_LIST_EMPTY(active_jammers)             // List of active radio jammers
GLOBAL_LIST_EMPTY(ladders)
GLOBAL_LIST_EMPTY(janitor_devices)
GLOBAL_LIST_EMPTY(trophy_cases)
GLOBAL_LIST_EMPTY(coin_values)
///This is a global list of all signs you can change an existing sign or new sign backing to, when using a pen on them.
GLOBAL_LIST_INIT(editable_sign_types, populate_editable_sign_types())

GLOBAL_LIST_EMPTY(wire_color_directory)
GLOBAL_LIST_EMPTY(wire_name_directory)

GLOBAL_LIST_EMPTY(ai_status_displays)

GLOBAL_LIST_EMPTY(mob_spawners) 		    // All mob_spawn objects
GLOBAL_LIST_EMPTY(alert_consoles)			// Station alert consoles, /obj/machinery/computer/station_alert

GLOBAL_LIST_EMPTY(rockpaperscissors_players) // List of everyone playing rock paper scissors

GLOBAL_LIST_EMPTY(cleanable_decals) // List of every /obj/effect/decal/cleanable, so persistence/event scans do not walk the entire world.

GLOBAL_LIST_EMPTY(all_areas) // List of every live /area, regardless of UNIQUE_AREA flag, so consumers do not walk every atom in world to find areas.
GLOBAL_LIST_EMPTY(maintenance_areas) // List of every live /area/maintenance, so maint access toggles do not filter all areas.
